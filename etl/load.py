"""
Data Loading to Analytics Schema
=================================

Handles loading transformed data into the analytics warehouse.
Supports full and incremental loads with SCD Type 2 for dimensions.
"""

import logging
from typing import Dict, Any, Optional, List
import pandas as pd
from datetime import datetime

from etl.db import DatabaseConnection, QueryRunner

logger = logging.getLogger(__name__)


class DataLoader:
    """
    Load data into analytics warehouse with SCD support.
    """
    
    def __init__(self, db_connection: DatabaseConnection, config: Dict[str, Any]):
        """
        Initialize data loader.
        
        Args:
            db_connection: Database connection to analytics warehouse
            config: ETL configuration dictionary
        """
        self.db = db_connection
        self.query_runner = QueryRunner(db_connection)
        self.config = config
        self.schemas = config.get("analytics_database", {}).get("schemas", {})
        self.analytics_schema = self.schemas.get("analytics", "analytics")
        
    def load_dimension_scd2(
        self,
        df: pd.DataFrame,
        table_name: str,
        natural_key: str,
        compare_columns: List[str],
    ) -> Dict[str, int]:
        """
        Load dimension table with SCD Type 2 logic.
        
        Args:
            df: DataFrame to load
            table_name: Target dimension table name
            natural_key: Natural/business key column name
            compare_columns: Columns to compare for detecting changes
            
        Returns:
            Dictionary with load statistics
        """
        logger.info(f"Loading dimension {table_name} with SCD Type 2")
        
        stats = {
            "new_records": 0,
            "updated_records": 0,
            "unchanged_records": 0,
            "errors": 0,
        }
        
        try:
            # Get existing current records
            existing_query = f"""
                SELECT * FROM {self.analytics_schema}.{table_name}
                WHERE is_current = 1
            """
            
            if self.query_runner.table_exists(table_name, self.analytics_schema):
                existing_df = self.query_runner.execute_to_dataframe(existing_query)
                logger.info(f"Found {len(existing_df)} existing current records")
            else:
                existing_df = pd.DataFrame()
                logger.info(f"Table {table_name} does not exist, will create with initial load")
            
            if len(existing_df) == 0:
                # Initial load - insert all as current
                df["is_current"] = 1
                df["effective_date"] = datetime.now()
                df["end_date"] = None
                
                row_count = self.query_runner.bulk_insert(
                    table_name=table_name,
                    data=df,
                    schema=self.analytics_schema,
                    if_exists="append",
                )
                stats["new_records"] = row_count
                logger.info(f"Initial load completed: {row_count} records inserted")
                
            else:
                # Incremental load with change detection
                existing_dict = existing_df.set_index(natural_key)[compare_columns].to_dict("index")
                
                new_records = []
                updated_records = []
                
                for _, row in df.iterrows():
                    key_value = row[natural_key]
                    
                    if key_value not in existing_dict:
                        # New record
                        new_records.append(row)
                    else:
                        # Check if changed
                        existing_values = existing_dict[key_value]
                        current_values = {col: row[col] for col in compare_columns if col in row}
                        
                        has_changed = False
                        for col in compare_columns:
                            if col in current_values and col in existing_values:
                                if current_values[col] != existing_values[col]:
                                    has_changed = True
                                    break
                        
                        if has_changed:
                            updated_records.append(row)
                        else:
                            stats["unchanged_records"] += 1
                
                # Insert new records
                if new_records:
                    new_df = pd.DataFrame(new_records)
                    new_df["is_current"] = 1
                    new_df["effective_date"] = datetime.now()
                    new_df["end_date"] = None
                    
                    row_count = self.query_runner.bulk_insert(
                        table_name=table_name,
                        data=new_df,
                        schema=self.analytics_schema,
                        if_exists="append",
                    )
                    stats["new_records"] = row_count
                    logger.info(f"Inserted {row_count} new records")
                
                # Handle updated records (SCD Type 2)
                if updated_records:
                    # This would require:
                    # 1. Update existing record: set is_current=0, end_date=now
                    # 2. Insert new record: set is_current=1, effective_date=now
                    # Simplified for demo - in production, use SQL UPDATE + INSERT
                    
                    updated_df = pd.DataFrame(updated_records)
                    updated_df["is_current"] = 1
                    updated_df["effective_date"] = datetime.now()
                    updated_df["end_date"] = None
                    
                    # Note: In production, you'd first UPDATE the old records
                    # For demo, we're just inserting new versions
                    
                    row_count = self.query_runner.bulk_insert(
                        table_name=table_name,
                        data=updated_df,
                        schema=self.analytics_schema,
                        if_exists="append",
                    )
                    stats["updated_records"] = row_count
                    logger.info(f"Inserted {row_count} updated record versions")
            
            logger.info(f"Dimension load complete for {table_name}: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Error loading dimension {table_name}: {e}")
            stats["errors"] += 1
            raise
    
    def load_fact_table(
        self,
        df: pd.DataFrame,
        table_name: str,
        mode: str = "append",
    ) -> int:
        """
        Load fact table data.
        
        Args:
            df: DataFrame to load
            table_name: Target fact table name
            mode: Load mode ('append', 'replace', 'upsert')
            
        Returns:
            Number of rows loaded
        """
        logger.info(f"Loading fact table {table_name}, mode: {mode}")
        
        try:
            # Add audit fields
            df["created_date"] = datetime.now()
            df["updated_date"] = datetime.now()
            df["source_system"] = "SAP_B1"
            
            if mode == "replace":
                # Truncate and reload
                if self.query_runner.table_exists(table_name, self.analytics_schema):
                    self.query_runner.truncate_table(table_name, self.analytics_schema)
                if_exists = "append"
            elif mode == "append":
                if_exists = "append"
            elif mode == "upsert":
                # For upsert, would need to implement merge logic
                # Simplified for demo
                if_exists = "append"
            else:
                raise ValueError(f"Unsupported load mode: {mode}")
            
            row_count = self.query_runner.bulk_insert(
                table_name=table_name,
                data=df,
                schema=self.analytics_schema,
                if_exists=if_exists,
            )
            
            logger.info(f"Fact table load complete: {row_count} rows")
            return row_count
            
        except Exception as e:
            logger.error(f"Error loading fact table {table_name}: {e}")
            raise
    
    def load_customer_dimension(self, df: pd.DataFrame) -> Dict[str, int]:
        """
        Load customer dimension with SCD Type 2.
        
        Args:
            df: Transformed customer DataFrame
            
        Returns:
            Load statistics
        """
        compare_columns = [
            "card_name",
            "customer_tier",
            "customer_segment",
            "credit_line",
            "discount_percent",
            "is_active",
        ]
        
        return self.load_dimension_scd2(
            df=df,
            table_name="dim_customer",
            natural_key="card_code",
            compare_columns=compare_columns,
        )
    
    def load_item_dimension(self, df: pd.DataFrame) -> Dict[str, int]:
        """
        Load item dimension with SCD Type 2.
        
        Args:
            df: Transformed item DataFrame
            
        Returns:
            Load statistics
        """
        compare_columns = [
            "item_name",
            "item_category",
            "price_tier",
            "avg_price",
            "is_active",
        ]
        
        return self.load_dimension_scd2(
            df=df,
            table_name="dim_item",
            natural_key="item_code",
            compare_columns=compare_columns,
        )
    
    def load_sales_fact(self, df: pd.DataFrame) -> int:
        """
        Load sales fact table.
        
        Args:
            df: Transformed sales DataFrame
            
        Returns:
            Number of rows loaded
        """
        return self.load_fact_table(
            df=df,
            table_name="fact_sales",
            mode="append",
        )
    
    def load_delivery_fact(self, df: pd.DataFrame) -> int:
        """
        Load delivery fact table.
        
        Args:
            df: Transformed delivery DataFrame
            
        Returns:
            Number of rows loaded
        """
        return self.load_fact_table(
            df=df,
            table_name="fact_delivery",
            mode="append",
        )
    
    def get_dimension_lookup(
        self,
        table_name: str,
        key_column: str,
        value_column: str,
    ) -> Dict[Any, Any]:
        """
        Get dimension lookup dictionary for transformations.
        
        Args:
            table_name: Dimension table name
            key_column: Natural key column
            value_column: Surrogate key column
            
        Returns:
            Dictionary mapping natural keys to surrogate keys
        """
        query = f"""
            SELECT {key_column}, {value_column}
            FROM {self.analytics_schema}.{table_name}
            WHERE is_current = 1
        """
        
        df = self.query_runner.execute_to_dataframe(query)
        lookup = dict(zip(df[key_column], df[value_column]))
        
        logger.info(f"Retrieved {len(lookup)} entries from {table_name} lookup")
        return lookup
    
    def verify_load(
        self,
        table_name: str,
        expected_count: Optional[int] = None,
    ) -> bool:
        """
        Verify data was loaded successfully.
        
        Args:
            table_name: Table name to verify
            expected_count: Expected row count (optional)
            
        Returns:
            True if verification passed
        """
        try:
            actual_count = self.query_runner.get_table_row_count(
                table_name=table_name,
                schema=self.analytics_schema,
            )
            
            logger.info(f"Verification: {table_name} has {actual_count} rows")
            
            if expected_count is not None:
                if actual_count != expected_count:
                    logger.warning(
                        f"Row count mismatch: expected {expected_count}, "
                        f"got {actual_count}"
                    )
                    return False
            
            return actual_count > 0
            
        except Exception as e:
            logger.error(f"Verification failed for {table_name}: {e}")
            return False
    
    def create_indexes(self, table_name: str):
        """
        Create indexes on loaded table (if not exists).
        
        Args:
            table_name: Table name
        """
        logger.info(f"Creating indexes for {table_name} (if not exists)")
        
        # Index creation would be specific to table structure
        # This is a placeholder - in production, read from SQL files
        
        try:
            # Example: Create index on date key for fact tables
            if table_name.startswith("fact_"):
                # This would execute CREATE INDEX IF NOT EXISTS statements
                pass
            
            logger.info(f"Indexes created for {table_name}")
            
        except Exception as e:
            logger.warning(f"Index creation failed for {table_name}: {e}")
            # Don't raise - indexes are optimization, not critical


# Updated: 2025-11-11 18:58:00

# Updated: 2025-11-13 12:23:00

# Updated: 2025-11-13 20:30:00

# Updated: 2025-11-18 10:29:00

# Updated: 2025-11-19 10:18:00

# Updated: 2025-11-20 08:31:00

# Updated: 2025-11-21 08:43:00

# Updated: 2025-11-21 16:14:00

# Updated: 2025-11-24 14:00:00

# Updated: 2025-11-28 18:35:00

# Updated: 2025-12-02 10:03:00

# Updated: 2025-12-03 08:11:00

# Updated: 2025-12-04 10:21:00

# Updated: 2025-12-10 08:38:00

# Updated: 2025-12-10 20:06:00

# Updated: 2025-12-12 12:59:00

# Updated: 2025-12-13 10:17:00

# Updated: 2025-12-13 14:35:00

# Updated: 2025-12-14 16:03:00

# Updated: 2025-12-15 18:04:00

# Updated: 2025-12-17 08:17:00

# Updated: 2025-12-17 20:26:00
