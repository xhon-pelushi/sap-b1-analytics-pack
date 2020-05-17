"""
ETL Scheduler Example
=====================

Examples of how to schedule ETL pipeline execution using APScheduler.
Suitable for production deployments.
"""

import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional
import yaml

from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import EVENT_JOB_ERROR, EVENT_JOB_EXECUTED
import coloredlogs

from etl.pipeline import ETLPipeline

# Configure logging
coloredlogs.install(
    level=logging.INFO,
    fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)


class ETLScheduler:
    """
    ETL Pipeline Scheduler with job management and monitoring.
    """
    
    def __init__(self, config_path: str = "config/config.yaml"):
        """
        Initialize scheduler.
        
        Args:
            config_path: Path to configuration file
        """
        self.config_path = config_path
        self.config = self._load_config()
        self.scheduler = BlockingScheduler()
        self.pipeline = None
        
        # Register event listeners
        self.scheduler.add_listener(
            self._job_executed_listener,
            EVENT_JOB_EXECUTED,
        )
        self.scheduler.add_listener(
            self._job_error_listener,
            EVENT_JOB_ERROR,
        )
    
    def _load_config(self) -> dict:
        """Load configuration from file."""
        try:
            with open(self.config_path, "r") as f:
                return yaml.safe_load(f)
        except Exception as e:
            logger.error(f"Failed to load configuration: {e}")
            sys.exit(1)
    
    def _job_executed_listener(self, event):
        """Handle successful job execution."""
        logger.info(f"Job {event.job_id} executed successfully")
    
    def _job_error_listener(self, event):
        """Handle job execution errors."""
        logger.error(f"Job {event.job_id} failed with exception: {event.exception}")
        # Here you could send notifications, alerts, etc.
    
    def run_full_load_job(self):
        """Job function for full load."""
        logger.info("="* 60)
        logger.info("SCHEDULED JOB: Full Load")
        logger.info("=" * 60)
        
        try:
            pipeline = ETLPipeline(self.config_path)
            stats = pipeline.run_full_load()
            
            logger.info(f"Full load completed successfully")
            logger.info(f"Duration: {stats['duration_seconds']:.2f} seconds")
            
            if stats.get("errors"):
                logger.warning(f"Completed with {len(stats['errors'])} errors")
                
        except Exception as e:
            logger.error(f"Full load job failed: {e}", exc_info=True)
            raise
    
    def run_incremental_load_job(self, lookback_days: Optional[int] = None):
        """Job function for incremental load."""
        logger.info("=" * 60)
        logger.info("SCHEDULED JOB: Incremental Load")
        logger.info("=" * 60)
        
        try:
            pipeline = ETLPipeline(self.config_path)
            stats = pipeline.run_incremental_load(lookback_days)
            
            logger.info(f"Incremental load completed successfully")
            logger.info(f"Duration: {stats['duration_seconds']:.2f} seconds")
            
            if stats.get("errors"):
                logger.warning(f"Completed with {len(stats['errors'])} errors")
                
        except Exception as e:
            logger.error(f"Incremental load job failed: {e}", exc_info=True)
            raise
    
    def run_data_quality_job(self):
        """Job function for data quality checks."""
        logger.info("=" * 60)
        logger.info("SCHEDULED JOB: Data Quality Check")
        logger.info("=" * 60)
        
        try:
            pipeline = ETLPipeline(self.config_path)
            
            # Run data quality checks
            # This is a placeholder - implement your specific checks
            logger.info("Running data quality checks...")
            
            # Example checks:
            # 1. Check for null values in critical fields
            # 2. Check for duplicate records
            # 3. Validate foreign key relationships
            # 4. Check data ranges and constraints
            
            logger.info("Data quality checks completed")
            
        except Exception as e:
            logger.error(f"Data quality job failed: {e}", exc_info=True)
            raise
    
    def add_jobs_from_config(self):
        """Add scheduled jobs based on configuration."""
        scheduling_config = self.config.get("scheduling", {})
        
        if not scheduling_config.get("enabled", False):
            logger.warning("Scheduling is disabled in configuration")
            return
        
        jobs = scheduling_config.get("jobs", [])
        
        for job_config in jobs:
            name = job_config.get("name")
            schedule = job_config.get("schedule")  # Cron expression
            pipeline_type = job_config.get("pipeline")
            
            if pipeline_type == "full":
                job_func = self.run_full_load_job
            elif pipeline_type == "incremental":
                job_func = lambda: self.run_incremental_load_job()
            elif pipeline_type == "data_quality":
                job_func = self.run_data_quality_job
            else:
                logger.warning(f"Unknown pipeline type: {pipeline_type}")
                continue
            
            self.scheduler.add_job(
                job_func,
                trigger=CronTrigger.from_crontab(schedule),
                id=name,
                name=name,
                replace_existing=True,
            )
            
            logger.info(f"Added scheduled job: {name} ({schedule})")
    
    def add_manual_schedules(self):
        """
        Add manual schedule examples.
        
        Use this method to define schedules programmatically
        instead of via configuration file.
        """
        # Example 1: Daily full refresh at 2 AM
        self.scheduler.add_job(
            self.run_full_load_job,
            trigger=CronTrigger(hour=2, minute=0),
            id="daily_full_refresh",
            name="Daily Full Refresh at 2 AM",
            replace_existing=True,
        )
        logger.info("Added job: Daily Full Refresh at 2 AM")
        
        # Example 2: Hourly incremental load
        self.scheduler.add_job(
            lambda: self.run_incremental_load_job(lookback_days=1),
            trigger=CronTrigger(minute=0),
            id="hourly_incremental",
            name="Hourly Incremental Load",
            replace_existing=True,
        )
        logger.info("Added job: Hourly Incremental Load")
        
        # Example 3: Weekly data quality check on Sunday at 3 AM
        self.scheduler.add_job(
            self.run_data_quality_job,
            trigger=CronTrigger(day_of_week="sun", hour=3, minute=0),
            id="weekly_data_quality",
            name="Weekly Data Quality Check",
            replace_existing=True,
        )
        logger.info("Added job: Weekly Data Quality Check")
        
        # Example 4: Business hours incremental (every hour, 8 AM - 6 PM, Mon-Fri)
        self.scheduler.add_job(
            lambda: self.run_incremental_load_job(lookback_days=1),
            trigger=CronTrigger(
                day_of_week="mon-fri",
                hour="8-18",
                minute=0,
            ),
            id="business_hours_incremental",
            name="Business Hours Incremental (Hourly)",
            replace_existing=True,
        )
        logger.info("Added job: Business Hours Incremental")
    
    def start(self, use_config: bool = True):
        """
        Start the scheduler.
        
        Args:
            use_config: If True, use jobs from config file; otherwise use manual schedules
        """
        logger.info("Starting ETL Scheduler...")
        logger.info(f"Configuration: {self.config_path}")
        
        try:
            if use_config:
                self.add_jobs_from_config()
            else:
                self.add_manual_schedules()
            
            # Print scheduled jobs
            logger.info("\nScheduled Jobs:")
            logger.info("-" * 60)
            for job in self.scheduler.get_jobs():
                logger.info(f"  • {job.name}")
                logger.info(f"    ID: {job.id}")
                logger.info(f"    Next run: {job.next_run_time}")
            logger.info("-" * 60)
            
            # Start scheduler
            logger.info("\nScheduler started. Press Ctrl+C to exit.")
            self.scheduler.start()
            
        except (KeyboardInterrupt, SystemExit):
            logger.info("\nShutting down scheduler...")
            self.scheduler.shutdown()
            logger.info("Scheduler stopped")
        except Exception as e:
            logger.error(f"Scheduler error: {e}", exc_info=True)
            sys.exit(1)


def main():
    """Main entry point for scheduler."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="SAP B1 Analytics ETL Scheduler"
    )
    parser.add_argument(
        "--config",
        "-c",
        default="config/config.yaml",
        help="Path to configuration file",
    )
    parser.add_argument(
        "--use-config",
        action="store_true",
        help="Use job schedules from config file (otherwise use manual schedules)",
    )
    
    args = parser.parse_args()
    
    # Create and start scheduler
    scheduler = ETLScheduler(args.config)
    scheduler.start(use_config=args.use_config)


if __name__ == "__main__":
    main()


# =====================================================
# Alternative: Simple Schedule Library Example
# =====================================================
"""
For simpler scheduling needs, you can use the 'schedule' library:

import schedule
import time

def job():
    pipeline = ETLPipeline("config/config.yaml")
    pipeline.run_incremental_load()

# Schedule jobs
schedule.every().day.at("02:00").do(job)  # Daily at 2 AM
schedule.every().hour.do(job)             # Every hour
schedule.every().monday.at("03:00").do(job)  # Monday at 3 AM

# Run scheduler
while True:
    schedule.run_pending()
    time.sleep(60)
"""

# =====================================================
# Production Deployment Notes
# =====================================================
"""
For production deployment, consider:

1. **Systemd Service** (Linux):
   Create a systemd service file to run the scheduler as a daemon.
   
   Example: /etc/systemd/system/sap-b1-etl.service
   
   [Unit]
   Description=SAP B1 Analytics ETL Scheduler
   After=network.target
   
   [Service]
   Type=simple
   User=analytics
   WorkingDirectory=/opt/sap-b1-analytics
   ExecStart=/opt/sap-b1-analytics/venv/bin/python -m etl.scheduler_example
   Restart=always
   RestartSec=10
   
   [Install]
   WantedBy=multi-user.target

2. **Docker Container**:
   Run scheduler in a Docker container for easy deployment.

3. **Cloud Services**:
   - AWS: Use AWS Batch or ECS with CloudWatch Events
   - Azure: Use Azure Data Factory or Logic Apps
   - GCP: Use Cloud Scheduler with Cloud Run

4. **Monitoring**:
   - Integrate with monitoring tools (Prometheus, Datadog, etc.)
   - Set up alerts for job failures
   - Track execution times and resource usage

5. **Logging**:
   - Configure centralized logging (ELK Stack, CloudWatch, etc.)
   - Rotate log files to prevent disk space issues
   - Include job correlation IDs for troubleshooting
"""

