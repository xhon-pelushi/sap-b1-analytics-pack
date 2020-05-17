"""
ETL Pipeline Orchestration
===========================

Main ETL pipeline that orchestrates extract, transform, and load operations.
Supports full and incremental loads with error handling and logging.
"""

import logging
import sys
from pathlib import Path
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import yaml
import click
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress

from etl.db import DatabaseConnection, QueryRunner
from etl.extract import SAPExtractor
from etl.transform import DataTransformer
from etl.load import DataLoader

# Setup rich console for better CLI output
console = Console()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(rich_tracebacks=True, console=console)],
)

logger = logging.getLogger(__name__)


class ETLPipeline:
    """
    Main ETL pipeline orchestrator.
    """
    
    def __init__(self, config_path: str):
        """
        Initialize ETL pipeline.
        
        Args:
            config_path: Path to configuration YAML file
        """
        self.config = self._load_config(config_path)
        self.start_time = None
        self.end_time = None
        self.stats = {}
        
        # Initialize connections
        self.source_db = DatabaseConnection(self.config["source_database"])
        self.analytics_db = DatabaseConnection(self.config["analytics_database"])
        
        # Initialize ETL components
        self.extractor = SAPExtractor(self.source_db, self.config)
        self.transformer = DataTransformer(self.config)
        self.loader = DataLoader(self.analytics_db, self.config)
        
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from YAML file."""
        try:
            with open(config_path, "r") as f:
                config = yaml.safe_load(f)
            logger.info(f"Loaded configuration from {config_path}")
            return config
        except Exception as e:
            logger.error(f"Failed to load configuration: {e}")
            sys.exit(1)
    
    def run_full_load(self) -> Dict[str, Any]:
        """
        Run full ETL pipeline (all data).
        
        Returns:
            Pipeline execution statistics
        """
        logger.info("="* 60)
        logger.info("Starting FULL LOAD ETL Pipeline")
        logger.info("=" * 60)
        
        self.start_time = datetime.now()
        self.stats = {
            "start_time": self.start_time,
            "pipeline_type": "full_load",
            "dimensions": {},
            "facts": {},
            "errors": [],
        }
        
        try:
            with Progress(console=console) as progress:
                # Define tasks
                task = progress.add_task("[cyan]ETL Pipeline", total=100)
                
                # Step 1: Load Dimensions (40%)
                progress.update(task, description="[cyan]Loading Dimensions...")
                self._load_dimensions()
                progress.update(task, advance=40)
                
                # Step 2: Load Facts (50%)
                progress.update(task, description="[cyan]Loading Facts...")
                self._load_facts()
                progress.update(task, advance=50)
                
                # Step 3: Verify (10%)
                progress.update(task, description="[cyan]Verifying loads...")
                self._verify_loads()
                progress.update(task, advance=10)
            
            self.end_time = datetime.now()
            self.stats["end_time"] = self.end_time
            self.stats["duration_seconds"] = (self.end_time - self.start_time).total_seconds()
            self.stats["status"] = "success"
            
            logger.info("=" * 60)
            logger.info("ETL Pipeline completed successfully!")
            logger.info(f"Duration: {self.stats['duration_seconds']:.2f} seconds")
            logger.info("=" * 60)
            
            return self.stats
            
        except Exception as e:
            self.stats["status"] = "failed"
            self.stats["errors"].append(str(e))
            logger.error(f"Pipeline failed: {e}", exc_info=True)
            raise
        finally:
            # Cleanup
            self.source_db.close()
            self.analytics_db.close()
    
    def run_incremental_load(
        self,
        lookback_days: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Run incremental ETL pipeline (changed data only).
        
        Args:
            lookback_days: Number of days to look back for changes
            
        Returns:
            Pipeline execution statistics
        """
        if lookback_days is None:
            lookback_days = self.config.get("etl", {}).get("incremental", {}).get("lookback_days", 7)
        
        logger.info("=" * 60)
        logger.info(f"Starting INCREMENTAL LOAD ETL Pipeline (lookback: {lookback_days} days)")
        logger.info("=" * 60)
        
        self.start_time = datetime.now()
        self.stats = {
            "start_time": self.start_time,
            "pipeline_type": "incremental_load",
            "lookback_days": lookback_days,
            "dimensions": {},
            "facts": {},
            "errors": [],
        }
        
        try:
            with Progress(console=console) as progress:
                task = progress.add_task("[cyan]ETL Pipeline", total=100)
                
                # Step 1: Load Dimensions (40%)
                progress.update(task, description="[cyan]Loading Dimensions (incremental)...")
                self._load_dimensions(incremental=True, lookback_days=lookback_days)
                progress.update(task, advance=40)
                
                # Step 2: Load Facts (50%)
                progress.update(task, description="[cyan]Loading Facts (incremental)...")
                start_date = datetime.now() - timedelta(days=lookback_days)
                self._load_facts(start_date=start_date)
                progress.update(task, advance=50)
                
                # Step 3: Verify (10%)
                progress.update(task, description="[cyan]Verifying loads...")
                self._verify_loads()
                progress.update(task, advance=10)
            
            self.end_time = datetime.now()
            self.stats["end_time"] = self.end_time
            self.stats["duration_seconds"] = (self.end_time - self.start_time).total_seconds()
            self.stats["status"] = "success"
            
            logger.info("=" * 60)
            logger.info("Incremental ETL Pipeline completed successfully!")
            logger.info(f"Duration: {self.stats['duration_seconds']:.2f} seconds")
            logger.info("=" * 60)
            
            return self.stats
            
        except Exception as e:
            self.stats["status"] = "failed"
            self.stats["errors"].append(str(e))
            logger.error(f"Pipeline failed: {e}", exc_info=True)
            raise
        finally:
            # Cleanup
            self.source_db.close()
            self.analytics_db.close()
    
    def _load_dimensions(
        self,
        incremental: bool = False,
        lookback_days: int = 7,
    ):
        """Load dimension tables."""
        logger.info("Loading dimension tables...")
        
        # Extract and load customers
        try:
            customers = self.extractor.extract_customers(incremental, lookback_days)
            customers_transformed = self.transformer.transform_customers(customers)
            customers_transformed = self.transformer.cleanse_data(customers_transformed)
            
            stats = self.loader.load_customer_dimension(customers_transformed)
            self.stats["dimensions"]["customers"] = stats
            logger.info(f"Customer dimension loaded: {stats}")
        except Exception as e:
            logger.error(f"Failed to load customer dimension: {e}")
            self.stats["errors"].append(f"Customer dimension: {e}")
        
        # Extract and load items
        try:
            items = self.extractor.extract_items(incremental, lookback_days)
            items_transformed = self.transformer.transform_items(items)
            items_transformed = self.transformer.cleanse_data(items_transformed)
            
            stats = self.loader.load_item_dimension(items_transformed)
            self.stats["dimensions"]["items"] = stats
            logger.info(f"Item dimension loaded: {stats}")
        except Exception as e:
            logger.error(f"Failed to load item dimension: {e}")
            self.stats["errors"].append(f"Item dimension: {e}")
    
    def _load_facts(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ):
        """Load fact tables."""
        logger.info("Loading fact tables...")
        
        # Get dimension lookups
        try:
            customer_dim = self.loader.query_runner.execute_to_dataframe(
                "SELECT card_code, customer_key, customer_tier, customer_segment FROM analytics.dim_customer WHERE is_current = 1"
            )
            item_dim = self.loader.query_runner.execute_to_dataframe(
                "SELECT item_code, item_key, item_category, abc_class FROM analytics.dim_item WHERE is_current = 1"
            )
        except Exception as e:
            logger.error(f"Failed to retrieve dimension lookups: {e}")
            raise
        
        # Load sales fact
        try:
            invoices = self.extractor.extract_invoices(start_date, end_date)
            if len(invoices) > 0:
                sales_transformed = self.transformer.transform_sales(
                    invoices, customer_dim, item_dim
                )
                sales_transformed = self.transformer.cleanse_data(sales_transformed)
                
                row_count = self.loader.load_sales_fact(sales_transformed)
                self.stats["facts"]["sales"] = {"rows": row_count}
                logger.info(f"Sales fact loaded: {row_count} rows")
            else:
                logger.info("No sales data to load for date range")
                self.stats["facts"]["sales"] = {"rows": 0}
        except Exception as e:
            logger.error(f"Failed to load sales fact: {e}")
            self.stats["errors"].append(f"Sales fact: {e}")
        
        # Load delivery fact
        try:
            deliveries = self.extractor.extract_deliveries(start_date, end_date)
            if len(deliveries) > 0:
                deliveries_transformed = self.transformer.transform_deliveries(
                    deliveries, customer_dim, item_dim
                )
                deliveries_transformed = self.transformer.cleanse_data(deliveries_transformed)
                
                row_count = self.loader.load_delivery_fact(deliveries_transformed)
                self.stats["facts"]["deliveries"] = {"rows": row_count}
                logger.info(f"Delivery fact loaded: {row_count} rows")
            else:
                logger.info("No delivery data to load for date range")
                self.stats["facts"]["deliveries"] = {"rows": 0}
        except Exception as e:
            logger.error(f"Failed to load delivery fact: {e}")
            self.stats["errors"].append(f"Delivery fact: {e}")
    
    def _verify_loads(self):
        """Verify all loads completed successfully."""
        logger.info("Verifying data loads...")
        
        tables_to_verify = [
            "dim_customer",
            "dim_item",
            "fact_sales",
            "fact_delivery",
        ]
        
        for table in tables_to_verify:
            verified = self.loader.verify_load(table)
            if not verified:
                logger.warning(f"Verification failed for {table}")


@click.command()
@click.option(
    "--config",
    "-c",
    default="config/config.yaml",
    help="Path to configuration file",
)
@click.option(
    "--mode",
    "-m",
    type=click.Choice(["full", "incremental"]),
    default="incremental",
    help="ETL mode: full or incremental",
)
@click.option(
    "--lookback-days",
    "-l",
    type=int,
    default=None,
    help="Days to look back for incremental load",
)
def main(config: str, mode: str, lookback_days: Optional[int]):
    """
    SAP B1 Analytics ETL Pipeline
    
    Run ETL pipeline to extract data from SAP Business One and load into
    analytics warehouse.
    """
    try:
        pipeline = ETLPipeline(config)
        
        if mode == "full":
            stats = pipeline.run_full_load()
        else:
            stats = pipeline.run_incremental_load(lookback_days)
        
        console.print("\n[bold green]✓ Pipeline completed successfully![/bold green]")
        console.print(f"\nExecution time: {stats['duration_seconds']:.2f} seconds")
        
        if stats.get("errors"):
            console.print("\n[yellow]⚠ Errors encountered:[/yellow]")
            for error in stats["errors"]:
                console.print(f"  • {error}")
        
    except Exception as e:
        console.print(f"\n[bold red]✗ Pipeline failed: {e}[/bold red]")
        sys.exit(1)


if __name__ == "__main__":
    main()


# Updated: 2025-11-10 16:14:00

# Updated: 2025-11-11 10:07:00

# Updated: 2025-11-12 16:01:00

# Updated: 2025-11-13 10:35:00

# Updated: 2025-11-14 12:03:00

# Updated: 2025-11-15 08:11:00

# Updated: 2025-11-20 10:48:00

# Updated: 2025-11-20 12:57:00

# Updated: 2025-11-20 14:45:00

# Updated: 2025-11-22 12:14:00

# Updated: 2025-11-22 18:28:00

# Updated: 2025-11-25 12:11:00

# Updated: 2025-11-25 18:04:00

# Updated: 2025-11-26 14:40:00

# Updated: 2025-11-27 08:50:00

# Updated: 2025-11-28 08:30:00

# Updated: 2025-11-29 16:42:00

# Updated: 2025-11-30 16:04:00

# Updated: 2025-12-01 10:03:00

# Updated: 2025-12-01 12:53:00

# Updated: 2025-12-02 08:35:00

# Updated: 2025-12-02 14:37:00

# Updated: 2025-12-02 18:30:00

# Updated: 2025-12-04 08:07:00

# Updated: 2025-12-07 14:01:00

# Updated: 2025-12-07 20:28:00

# Updated: 2025-12-09 16:42:00

# Updated: 2025-12-13 16:27:00

# Updated: 2025-12-15 12:23:00
