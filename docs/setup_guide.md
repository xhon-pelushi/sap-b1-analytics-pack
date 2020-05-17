# Setup Guide

## Prerequisites

- Python 3.11 or higher
- SQL Server 2016+ or PostgreSQL 12+
- SAP Business One 9.3+ (with SQL Server or HANA)
- Power BI Desktop (optional, for dashboards)
- Git (for version control)

## Installation Steps

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/sap-b1-analytics-pack.git
cd sap-b1-analytics-pack
```

### 2. Create Virtual Environment

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Configure Database Connections

```bash
# Copy example configuration
cp config/config.example.yaml config/config.yaml

# Edit configuration with your database credentials
nano config/config.yaml  # or use your preferred editor
```

Update the following sections:
- `source_database`: SAP B1 connection details
- `analytics_database`: Analytics warehouse connection details

### 5. Create Analytics Schema

```bash
# Connect to your analytics database and run:
# 1. Create schemas
CREATE SCHEMA analytics;
CREATE SCHEMA staging;
CREATE SCHEMA kpis;

# 2. Create dimension tables
# Execute files in sql/schema/ directory
```

### 6. Load Sample Data (Optional)

For testing purposes, you can load sample SAP B1 data:

```bash
# Execute sample schema and data
# In your SAP B1 database:
sqlcmd -S your-server -d SBODemoUS -i data/raw/sap_b1_sample_schema.sql
sqlcmd -S your-server -d SBODemoUS -i data/raw/sap_b1_sample_data.sql
```

### 7. Run Initial ETL

```bash
# Full load
python -m etl.pipeline --config config/config.yaml --mode full

# Or incremental load
python -m etl.pipeline --config config/config.yaml --mode incremental --lookback-days 30
```

### 8. Verify Installation

```bash
# Run tests
pytest tests/

# Check data loaded
python -c "
from etl.db import DatabaseConnection, QueryRunner
import yaml

with open('config/config.yaml') as f:
    config = yaml.safe_load(f)

db = DatabaseConnection(config['analytics_database'])
qr = QueryRunner(db)

print('Customers:', qr.get_table_row_count('dim_customer', 'analytics'))
print('Items:', qr.get_table_row_count('dim_item', 'analytics'))
print('Sales:', qr.get_table_row_count('fact_sales', 'analytics'))
"
```

## Configuration Details

### Database Connection

```yaml
source_database:
  type: "mssql"  # or "postgres", "hana"
  host: "your-sap-server.company.com"
  port: 1433
  database: "SBODemoUS"
  username: "sa"
  password: "your-password"
  driver: "ODBC Driver 17 for SQL Server"
```

### ETL Settings

```yaml
etl:
  batch_size: 10000  # Records per batch
  parallel_workers: 4  # Parallel processing threads
  
  initial_load:
    start_date: "2023-01-01"
    end_date: null  # null = current date
  
  incremental:
    enabled: true
    lookback_days: 7
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to SAP B1 database

**Solutions**:
1. Verify server name and port
2. Check firewall rules
3. Ensure SQL Server allows remote connections
4. Verify credentials and permissions

### ODBC Driver Issues

**Problem**: ODBC Driver not found

**Solutions**:
```bash
# Linux
sudo apt-get install unixodbc unixodbc-dev
# Download and install Microsoft ODBC Driver 17

# Windows
# Download from: https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
```

### Permission Issues

**Problem**: Access denied errors

**Solutions**:
1. Grant SELECT on SAP B1 tables
2. Grant CREATE, INSERT, UPDATE on analytics schema
3. Verify service account has necessary permissions

### Memory Issues

**Problem**: Out of memory during ETL

**Solutions**:
1. Reduce `batch_size` in config
2. Increase system memory
3. Use incremental loads instead of full loads
4. Process tables separately

## Production Deployment

### Linux Service (systemd)

Create `/etc/systemd/system/sap-b1-etl.service`:

```ini
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
```

Enable and start:
```bash
sudo systemctl enable sap-b1-etl
sudo systemctl start sap-b1-etl
sudo systemctl status sap-b1-etl
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "-m", "etl.scheduler_example"]
```

Build and run:
```bash
docker build -t sap-b1-analytics .
docker run -d --name sap-b1-etl \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/logs:/app/logs \
  sap-b1-analytics
```

## Next Steps

1. Review [Architecture Documentation](architecture.md)
2. Explore [KPI Definitions](kpi_definitions.md)
3. Set up Power BI dashboards
4. Configure scheduled ETL jobs
5. Set up monitoring and alerts

## Support

- GitHub Issues: [Report issues](https://github.com/yourusername/sap-b1-analytics-pack/issues)
- Documentation: [Full docs](https://github.com/yourusername/sap-b1-analytics-pack/tree/main/docs)


# Updated: 2025-11-10 14:12:00

# Updated: 2025-11-11 08:44:00

# Updated: 2025-11-12 08:46:00

# Updated: 2025-11-12 12:34:00

# Updated: 2025-11-13 18:41:00

# Updated: 2025-11-14 14:41:00

# Updated: 2025-11-16 08:40:00

# Updated: 2025-11-19 14:55:00

# Updated: 2025-11-19 18:05:00

# Updated: 2025-11-21 10:40:00

# Updated: 2025-11-21 18:58:00

# Updated: 2025-11-22 08:36:00

# Updated: 2025-11-22 20:31:00

# Updated: 2025-11-23 12:54:00

# Updated: 2025-11-26 16:30:00

# Updated: 2025-11-27 12:00:00

# Updated: 2025-11-29 12:35:00

# Updated: 2025-11-29 18:52:00

# Updated: 2025-12-03 14:49:00

# Updated: 2025-12-05 16:07:00

# Updated: 2025-12-06 08:15:00

# Updated: 2025-12-06 10:05:00

# Updated: 2025-12-09 18:09:00

# Updated: 2025-12-11 08:40:00

# Updated: 2025-12-14 14:00:00

# Updated: 2025-12-16 12:46:00

# Updated: 2025-12-17 14:42:00

# Updated: 2025-12-17 16:19:00
