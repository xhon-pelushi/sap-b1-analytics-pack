"""
Database Connection and Query Utilities
========================================

Provides database connection management and query execution
for both source (SAP B1) and target (Analytics) databases.
"""

import logging
from typing import Any, Dict, List, Optional, Union
from contextlib import contextmanager
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.pool import QueuePool
import pyodbc

logger = logging.getLogger(__name__)


class DatabaseConnection:
    """
    Database connection manager with connection pooling.
    
    Supports multiple database types: SQL Server, PostgreSQL, SAP HANA.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize database connection.
        
        Args:
            config: Database configuration dictionary containing:
                - type: Database type (mssql, postgres, hana)
                - host: Server hostname
                - port: Server port
                - database: Database name
                - username: Database username
                - password: Database password
                - driver: ODBC driver name (for SQL Server)
                - pool_size: Connection pool size
                - max_overflow: Maximum overflow connections
        """
        self.config = config
        self.db_type = config.get("type", "mssql")
        self.engine: Optional[Engine] = None
        self._connection_string = self._build_connection_string()
        
    def _build_connection_string(self) -> str:
        """Build database connection string based on database type."""
        db_type = self.config.get("type", "mssql")
        host = self.config["host"]
        port = self.config["port"]
        database = self.config["database"]
        username = self.config["username"]
        password = self.config["password"]
        
        if db_type == "mssql":
            driver = self.config.get("driver", "ODBC Driver 17 for SQL Server")
            # URL encode the driver name
            driver_encoded = driver.replace(" ", "+")
            conn_str = (
                f"mssql+pyodbc://{username}:{password}@{host}:{port}/"
                f"{database}?driver={driver_encoded}"
            )
        elif db_type == "postgres":
            conn_str = (
                f"postgresql://{username}:{password}@{host}:{port}/{database}"
            )
        elif db_type == "hana":
            conn_str = (
                f"hana://{username}:{password}@{host}:{port}"
            )
        else:
            raise ValueError(f"Unsupported database type: {db_type}")
            
        return conn_str
    
    def connect(self) -> Engine:
        """
        Create and return SQLAlchemy engine with connection pooling.
        
        Returns:
            SQLAlchemy Engine instance
        """
        if self.engine is None:
            pool_size = self.config.get("pool_size", 5)
            max_overflow = self.config.get("max_overflow", 10)
            pool_timeout = self.config.get("pool_timeout", 30)
            pool_recycle = self.config.get("pool_recycle", 3600)
            
            logger.info(f"Creating database engine for {self.config['host']}/{self.config['database']}")
            
            self.engine = create_engine(
                self._connection_string,
                poolclass=QueuePool,
                pool_size=pool_size,
                max_overflow=max_overflow,
                pool_timeout=pool_timeout,
                pool_recycle=pool_recycle,
                echo=False,
            )
            
            # Test connection
            try:
                with self.engine.connect() as conn:
                    conn.execute(text("SELECT 1"))
                logger.info("Database connection successful")
            except Exception as e:
                logger.error(f"Database connection failed: {e}")
                raise
                
        return self.engine
    
    @contextmanager
    def get_connection(self):
        """
        Context manager for database connections.
        
        Yields:
            SQLAlchemy connection
        """
        engine = self.connect()
        connection = engine.connect()
        try:
            yield connection
        finally:
            connection.close()
    
    def close(self):
        """Close database engine and all connections."""
        if self.engine:
            self.engine.dispose()
            self.engine = None
            logger.info("Database connection closed")


class QueryRunner:
    """
    Query execution utility with error handling and logging.
    """
    
    def __init__(self, db_connection: DatabaseConnection):
        """
        Initialize query runner.
        
        Args:
            db_connection: DatabaseConnection instance
        """
        self.db = db_connection
        self.engine = db_connection.connect()
        
    def execute_query(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None,
        fetch: bool = True,
    ) -> Optional[List[Dict[str, Any]]]:
        """
        Execute SQL query and optionally fetch results.
        
        Args:
            query: SQL query string
            params: Query parameters dictionary
            fetch: Whether to fetch results
            
        Returns:
            List of result rows as dictionaries if fetch=True, else None
        """
        try:
            with self.db.get_connection() as conn:
                result = conn.execute(text(query), params or {})
                
                if fetch:
                    columns = result.keys()
                    rows = result.fetchall()
                    return [dict(zip(columns, row)) for row in rows]
                else:
                    conn.commit()
                    return None
                    
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            logger.error(f"Query: {query[:200]}...")
            raise
    
    def execute_to_dataframe(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None,
        chunksize: Optional[int] = None,
    ) -> pd.DataFrame:
        """
        Execute query and return results as pandas DataFrame.
        
        Args:
            query: SQL query string
            params: Query parameters dictionary
            chunksize: Number of rows to fetch per iteration (for large results)
            
        Returns:
            pandas DataFrame with query results
        """
        try:
            logger.debug(f"Executing query to DataFrame: {query[:100]}...")
            
            if chunksize:
                # For large datasets, read in chunks
                chunks = []
                for chunk in pd.read_sql(
                    text(query),
                    self.engine,
                    params=params,
                    chunksize=chunksize,
                ):
                    chunks.append(chunk)
                df = pd.concat(chunks, ignore_index=True)
            else:
                df = pd.read_sql(text(query), self.engine, params=params)
            
            logger.info(f"Query returned {len(df)} rows")
            return df
            
        except Exception as e:
            logger.error(f"Query to DataFrame failed: {e}")
            logger.error(f"Query: {query[:200]}...")
            raise
    
    def execute_from_file(
        self,
        file_path: str,
        params: Optional[Dict[str, Any]] = None,
        fetch: bool = True,
    ) -> Optional[Union[List[Dict[str, Any]], pd.DataFrame]]:
        """
        Execute SQL query from file.
        
        Args:
            file_path: Path to SQL file
            params: Query parameters dictionary
            fetch: Whether to fetch results
            
        Returns:
            Query results if fetch=True, else None
        """
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                query = f.read()
            
            logger.info(f"Executing query from file: {file_path}")
            return self.execute_query(query, params, fetch)
            
        except Exception as e:
            logger.error(f"Failed to execute query from file {file_path}: {e}")
            raise
    
    def bulk_insert(
        self,
        table_name: str,
        data: pd.DataFrame,
        schema: Optional[str] = None,
        if_exists: str = "append",
        chunksize: int = 10000,
    ) -> int:
        """
        Bulk insert DataFrame into database table.
        
        Args:
            table_name: Target table name
            data: DataFrame to insert
            schema: Database schema name
            if_exists: What to do if table exists ('append', 'replace', 'fail')
            chunksize: Number of rows to insert per batch
            
        Returns:
            Number of rows inserted
        """
        try:
            row_count = len(data)
            logger.info(f"Bulk inserting {row_count} rows into {schema}.{table_name}")
            
            data.to_sql(
                name=table_name,
                con=self.engine,
                schema=schema,
                if_exists=if_exists,
                index=False,
                chunksize=chunksize,
                method="multi",
            )
            
            logger.info(f"Successfully inserted {row_count} rows")
            return row_count
            
        except Exception as e:
            logger.error(f"Bulk insert failed: {e}")
            raise
    
    def truncate_table(self, table_name: str, schema: Optional[str] = None):
        """
        Truncate database table.
        
        Args:
            table_name: Table name to truncate
            schema: Database schema name
        """
        full_table = f"{schema}.{table_name}" if schema else table_name
        query = f"TRUNCATE TABLE {full_table}"
        
        logger.warning(f"Truncating table: {full_table}")
        self.execute_query(query, fetch=False)
        logger.info(f"Table truncated: {full_table}")
    
    def get_table_row_count(
        self,
        table_name: str,
        schema: Optional[str] = None,
        where_clause: Optional[str] = None,
    ) -> int:
        """
        Get row count from table.
        
        Args:
            table_name: Table name
            schema: Database schema name
            where_clause: Optional WHERE clause filter
            
        Returns:
            Number of rows in table
        """
        full_table = f"{schema}.{table_name}" if schema else table_name
        query = f"SELECT COUNT(*) as row_count FROM {full_table}"
        
        if where_clause:
            query += f" WHERE {where_clause}"
        
        result = self.execute_query(query)
        return result[0]["row_count"] if result else 0
    
    def table_exists(self, table_name: str, schema: Optional[str] = None) -> bool:
        """
        Check if table exists in database.
        
        Args:
            table_name: Table name
            schema: Database schema name
            
        Returns:
            True if table exists, False otherwise
        """
        if self.db.db_type == "mssql":
            query = """
                SELECT COUNT(*) as count
                FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_NAME = :table_name
            """
            if schema:
                query += " AND TABLE_SCHEMA = :schema"
                params = {"table_name": table_name, "schema": schema}
            else:
                params = {"table_name": table_name}
        elif self.db.db_type == "postgres":
            query = """
                SELECT COUNT(*) as count
                FROM information_schema.tables
                WHERE table_name = :table_name
            """
            if schema:
                query += " AND table_schema = :schema"
                params = {"table_name": table_name, "schema": schema}
            else:
                params = {"table_name": table_name}
        else:
            raise NotImplementedError(f"table_exists not implemented for {self.db.db_type}")
        
        result = self.execute_query(query, params)
        return result[0]["count"] > 0 if result else False


# Updated: 2025-11-10 08:05:00

# Updated: 2025-11-10 12:23:00

# Updated: 2025-11-11 20:48:00

# Updated: 2025-11-11 22:19:00

# Updated: 2025-11-13 08:39:00

# Updated: 2025-11-13 14:33:00

# Updated: 2025-11-14 10:21:00

# Updated: 2025-11-14 18:02:00

# Updated: 2025-11-16 14:33:00

# Updated: 2025-11-16 20:50:00

# Updated: 2025-11-17 16:48:00

# Updated: 2025-11-18 16:17:00

# Updated: 2025-11-28 10:31:00

# Updated: 2025-12-01 08:17:00

# Updated: 2025-12-05 12:01:00

# Updated: 2025-12-05 14:52:00

# Updated: 2025-12-06 12:32:00

# Updated: 2025-12-06 16:40:00

# Updated: 2025-12-07 18:25:00

# Updated: 2025-12-11 10:55:00

# Updated: 2025-12-15 10:36:00

# Updated: 2025-12-15 14:58:00

<!-- Update 4 -->

<!-- Update 8 -->

<!-- Update 14 -->

<!-- Update 16 -->

<!-- Update 17 -->

<!-- Update 18 -->

<!-- Update 24 -->

<!-- Update 34 -->

<!-- Update 39 -->

<!-- Update 41 -->

<!-- Update 43 -->

<!-- Update 56 -->

<!-- Update 57 -->

<!-- Update 59 -->

<!-- Update 61 -->

<!-- Update 68 -->

<!-- Update 70 -->

<!-- Update 73 -->

<!-- Update 77 -->

<!-- Update 78 -->

<!-- Update 81 -->

<!-- Update 85 -->

<!-- Update 93 -->

<!-- Update 95 -->

<!-- Update 105 -->

<!-- Update 108 -->

<!-- Update 117 -->

<!-- Update 119 -->

<!-- Update 134 -->

<!-- Update 138 -->

<!-- Update 141 -->

<!-- Update 144 -->

<!-- Update 145 -->

<!-- Update 147 -->

<!-- Update 152 -->

<!-- Update 158 -->

<!-- Update 168 -->

<!-- Update 169 -->

<!-- Update 170 -->

<!-- Update 173 -->

<!-- Update 180 -->

<!-- Update 183 -->

<!-- Update 188 -->

<!-- Update 190 -->

<!-- Update 193 -->

<!-- Update 202 -->

<!-- Update 204 -->

<!-- Update 207 -->

<!-- Update 212 -->

<!-- Update 220 -->

<!-- Update 222 -->

<!-- Update 226 -->

<!-- Update 237 -->

<!-- Update 238 -->

<!-- Update 250 -->

<!-- Update 253 -->

<!-- Update 255 -->

<!-- Update 259 -->

<!-- Update 266 -->

<!-- Update 268 -->

<!-- Update 272 -->

<!-- Update 279 -->

<!-- Update 282 -->

<!-- Update 288 -->

<!-- Update 294 -->

<!-- Activity 7 -->

<!-- Activity 8 -->

<!-- Activity 16 -->

<!-- Activity 24 -->

<!-- Activity 25 -->

<!-- Activity 28 -->

<!-- Activity 35 -->

<!-- Activity 38 -->

<!-- Activity 40 -->

<!-- Activity 41 -->

<!-- Activity 51 -->

<!-- Activity 53 -->

<!-- Activity 54 -->

<!-- Activity 56 -->

<!-- Activity 59 -->

<!-- Activity 60 -->

<!-- Activity 61 -->

<!-- Activity 63 -->

<!-- Activity 78 -->

<!-- Activity 82 -->

<!-- Activity 85 -->

<!-- Activity 91 -->

<!-- Activity 94 -->

<!-- Activity 95 -->

<!-- Activity 96 -->

<!-- Activity 99 -->

<!-- Activity 100 -->

<!-- Activity 104 -->

<!-- Activity 106 -->

<!-- Activity 111 -->

<!-- Activity 112 -->

<!-- Activity 116 -->

<!-- Activity 117 -->

<!-- Activity 118 -->

<!-- Activity 121 -->

<!-- Activity 130 -->

<!-- Activity 131 -->

<!-- Activity 134 -->

<!-- Activity 137 -->

<!-- Activity 139 -->

<!-- Activity 145 -->

<!-- Activity 151 -->

<!-- Activity 152 -->

<!-- Activity 153 -->

<!-- Activity 157 -->

<!-- Activity 158 -->

<!-- Activity 160 -->

<!-- Activity 164 -->

<!-- Activity 165 -->

<!-- Activity 167 -->

<!-- Activity 169 -->

<!-- Activity 171 -->

<!-- Activity 173 -->

<!-- Activity 175 -->

<!-- Activity 176 -->

<!-- Activity 181 -->

<!-- Activity 182 -->

<!-- Activity 186 -->

<!-- Activity 198 -->

<!-- Activity 201 -->

<!-- Activity 203 -->

<!-- Activity 204 -->

<!-- Activity 206 -->

<!-- Activity 208 -->

<!-- Activity 209 -->

<!-- Activity 218 -->

<!-- Activity 220 -->

<!-- Activity 225 -->

<!-- Activity 227 -->

<!-- Activity 231 -->

<!-- Activity 252 -->

<!-- Activity 253 -->

<!-- Activity 255 -->

<!-- Activity 258 -->

<!-- Activity 266 -->

<!-- Activity 268 -->

<!-- Activity 271 -->

<!-- Activity 272 -->

<!-- Activity 274 -->

<!-- Activity 281 -->

<!-- Activity 282 -->

<!-- Activity 283 -->

<!-- Activity 285 -->

<!-- Activity 286 -->

<!-- Activity 290 -->

<!-- Activity 292 -->

<!-- Activity 293 -->

<!-- Activity 300 -->

<!-- Activity 309 -->

<!-- Activity 316 -->

<!-- Activity 320 -->

<!-- Activity 322 -->

<!-- Activity 324 -->

<!-- Activity 325 -->

<!-- Activity 327 -->

<!-- Activity 328 -->

<!-- Activity 330 -->

<!-- Activity 332 -->

<!-- Activity 333 -->

<!-- Activity 334 -->

<!-- Activity 335 -->

<!-- Activity 337 -->

<!-- Activity 342 -->

<!-- Activity 345 -->

<!-- Activity 349 -->

<!-- Activity 353 -->

<!-- Activity 354 -->

<!-- Activity 356 -->

<!-- Activity 357 -->

<!-- Activity 368 -->

<!-- Activity 370 -->

<!-- Activity 372 -->

<!-- Activity 375 -->

<!-- Activity 377 -->

<!-- Activity 389 -->

<!-- Activity 392 -->

<!-- Activity 393 -->

<!-- Activity 396 -->

<!-- Activity 398 -->

<!-- Activity 405 -->

<!-- Activity 407 -->

<!-- Activity 408 -->

<!-- Activity 410 -->

<!-- Activity 411 -->

<!-- Activity 413 -->

<!-- Activity 415 -->

<!-- Activity 423 -->

<!-- Activity 424 -->

<!-- Activity 427 -->

<!-- Activity 430 -->

<!-- Activity 432 -->

<!-- Activity 434 -->

<!-- Activity 437 -->

<!-- Activity 439 -->

<!-- Activity 445 -->

<!-- Activity 446 -->

<!-- Activity 448 -->

<!-- Activity 451 -->

<!-- Activity 455 -->

<!-- Activity 457 -->

<!-- Activity 461 -->

<!-- Activity 464 -->

<!-- Activity 465 -->

<!-- Activity 468 -->

<!-- Activity 470 -->

<!-- Activity 474 -->

<!-- Activity 475 -->

<!-- Activity 478 -->

<!-- Activity 482 -->

<!-- Activity 485 -->

<!-- Activity 487 -->

<!-- Activity 493 -->

<!-- Activity 496 -->

<!-- Activity 497 -->

<!-- Activity 500 -->

<!-- Activity 503 -->

<!-- Activity 505 -->

<!-- Activity 508 -->

<!-- Activity 509 -->

<!-- Activity 511 -->

<!-- Activity 513 -->

<!-- Activity 516 -->

<!-- Activity 517 -->

<!-- Activity 523 -->

<!-- Activity 524 -->

<!-- Activity 527 -->

<!-- Activity 530 -->

<!-- Activity 536 -->

<!-- Activity 539 -->

<!-- Activity 541 -->

<!-- Activity 543 -->

<!-- Activity 550 -->

<!-- Activity 553 -->

<!-- Activity 555 -->

<!-- Activity 559 -->

<!-- Activity 560 -->

<!-- Activity 562 -->

<!-- Activity 563 -->

<!-- Activity 564 -->

<!-- Activity 565 -->

<!-- Activity 566 -->

<!-- Activity 569 -->

<!-- Activity 570 -->

<!-- Activity 575 -->

<!-- Activity 576 -->

<!-- Activity 579 -->

<!-- Activity 580 -->

<!-- Activity 581 -->

<!-- Activity 586 -->

<!-- Activity 587 -->

<!-- Activity 590 -->

<!-- Activity 593 -->

<!-- Activity 596 -->

<!-- Activity 597 -->

<!-- Activity 599 -->

<!-- Activity 600 -->

<!-- Activity 602 -->

<!-- Activity 603 -->

<!-- Activity 604 -->

<!-- Activity 605 -->

<!-- Activity 606 -->

<!-- Activity 607 -->

<!-- Activity 610 -->

<!-- Activity 611 -->

<!-- Activity 613 -->

<!-- Activity 614 -->

<!-- Activity 616 -->

<!-- Activity 620 -->

<!-- Activity 621 -->

<!-- Activity 626 -->

<!-- Activity 627 -->

<!-- Activity 633 -->

<!-- Activity 641 -->

<!-- Activity 643 -->

<!-- Activity 645 -->

<!-- Activity 651 -->

<!-- Activity 652 -->

<!-- Activity 658 -->

<!-- Activity 659 -->

<!-- Activity 661 -->

<!-- Activity 662 -->

<!-- Activity 664 -->

<!-- Activity 668 -->

<!-- Activity 670 -->

<!-- Activity 673 -->

<!-- Activity 675 -->

<!-- Activity 680 -->

<!-- Activity 681 -->

<!-- Activity 682 -->

<!-- Activity 685 -->

<!-- Activity 690 -->

<!-- Activity 691 -->

<!-- Activity 693 -->

<!-- Activity 694 -->

<!-- Activity 703 -->

<!-- Activity 705 -->

<!-- Activity 711 -->

<!-- Activity 712 -->

<!-- Activity 717 -->

<!-- Activity 725 -->

<!-- Activity 726 -->

<!-- Activity 728 -->

<!-- Activity 730 -->

<!-- Activity 735 -->

<!-- Activity 736 -->

<!-- Activity 738 -->

<!-- Activity 740 -->

<!-- Activity 743 -->

<!-- Activity 744 -->
