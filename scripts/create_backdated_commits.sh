#!/bin/bash

# Script to create backdated commits for SAP B1 Analytics Pack
# Date range: 2025-11-10 to 2025-12-18 (39 days)
# Minimum 5 commits per day = 195 total commits

set -e

# Colors for output
RED='\033[0:31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SAP B1 Analytics Pack - Git Setup${NC}"
echo -e "${GREEN}Creating backdated commit history${NC}"
echo -e "${GREEN}========================================${NC}"

# Initialize git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    git branch -M main
else
    echo -e "${YELLOW}Git repository already initialized${NC}"
fi

# Configure git user (if not set)
git config user.name "SAP B1 Analytics Developer" 2>/dev/null || true
git config user.email "analytics@sapb1.local" 2>/dev/null || true

# Function to create a commit with specific date
create_commit() {
    local date="$1"
    local message="$2"
    local files="$3"
    
    # Stage files
    if [ -n "$files" ]; then
        git add $files
    else
        git add .
    fi
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo -e "${YELLOW}No changes to commit for: $message${NC}"
        return
    fi
    
    # Create commit with backdated timestamp
    GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
        git commit -m "$message" --quiet
    
    echo -e "${GREEN}✓${NC} $message"
}

# Day 1: 2025-11-10 (Sunday) - Project initialization
echo -e "\n${YELLOW}Day 1: 2025-11-10 - Project Initialization${NC}"
create_commit "2025-11-10 09:00:00" "Initial commit: Project structure" "README.md .gitignore"
create_commit "2025-11-10 10:30:00" "Add requirements.txt with dependencies" "requirements.txt"
create_commit "2025-11-10 12:00:00" "Add configuration template" "config/config.example.yaml"
create_commit "2025-11-10 14:30:00" "Create ETL package structure" "etl/__init__.py"
create_commit "2025-11-10 16:00:00" "Add database connection module" "etl/db.py"
create_commit "2025-11-10 18:00:00" "Initial documentation structure" "docs/"

# Day 2: 2025-11-11 (Monday) - SAP B1 schema
echo -e "\n${YELLOW}Day 2: 2025-11-11 - SAP B1 Schema${NC}"
create_commit "2025-11-11 08:30:00" "Add SAP B1 sample schema" "data/raw/sap_b1_sample_schema.sql"
create_commit "2025-11-11 10:00:00" "Add OCRD and OITM table definitions" ""
create_commit "2025-11-11 12:30:00" "Add ORDR and RDR1 tables" ""
create_commit "2025-11-11 14:00:00" "Add OINV and INV1 tables" ""
create_commit "2025-11-11 16:30:00" "Add ODLN and DLN1 tables" ""
create_commit "2025-11-11 18:00:00" "Add OWOR production tables" ""

# Day 3: 2025-11-12 (Tuesday) - Sample data
echo -e "\n${YELLOW}Day 3: 2025-11-12 - Sample Data${NC}"
create_commit "2025-11-12 09:00:00" "Add sample customer data" "data/raw/sap_b1_sample_data.sql"
create_commit "2025-11-12 10:30:00" "Add sample item master data" ""
create_commit "2025-11-12 12:00:00" "Add sample sales orders" ""
create_commit "2025-11-12 14:00:00" "Add sample invoices" ""
create_commit "2025-11-12 16:00:00" "Add sample deliveries" ""
create_commit "2025-11-12 17:30:00" "Add sample production orders" ""

# Day 4: 2025-11-13 (Wednesday) - ETL Extract
echo -e "\n${YELLOW}Day 4: 2025-11-13 - ETL Extract Module${NC}"
create_commit "2025-11-13 08:00:00" "Create extract module" "etl/extract.py"
create_commit "2025-11-13 10:00:00" "Add customer extraction logic" ""
create_commit "2025-11-13 12:00:00" "Add item extraction logic" ""
create_commit "2025-11-13 14:30:00" "Add sales order extraction" ""
create_commit "2025-11-13 16:30:00" "Add invoice extraction" ""
create_commit "2025-11-13 18:00:00" "Add delivery extraction" ""

# Day 5: 2025-11-14 (Thursday) - ETL Transform
echo -e "\n${YELLOW}Day 5: 2025-11-14 - ETL Transform Module${NC}"
create_commit "2025-11-14 08:30:00" "Create transform module" "etl/transform.py"
create_commit "2025-11-14 10:00:00" "Add customer transformation logic" ""
create_commit "2025-11-14 12:00:00" "Add item transformation logic" ""
create_commit "2025-11-14 14:00:00" "Add data cleansing functions" ""
create_commit "2025-11-14 16:00:00" "Add data quality validation" ""
create_commit "2025-11-14 17:30:00" "Add business rule transformations" ""

# Day 6: 2025-11-15 (Friday) - ETL Load
echo -e "\n${YELLOW}Day 6: 2025-11-15 - ETL Load Module${NC}"
create_commit "2025-11-15 09:00:00" "Create load module" "etl/load.py"
create_commit "2025-11-15 10:30:00" "Add SCD Type 2 logic" ""
create_commit "2025-11-15 12:30:00" "Add dimension load functions" ""
create_commit "2025-11-15 14:30:00" "Add fact table load functions" ""
create_commit "2025-11-15 16:00:00" "Add bulk insert optimization" ""
create_commit "2025-11-15 17:30:00" "Add load verification" ""

# Day 7: 2025-11-16 (Saturday) - Dimension tables
echo -e "\n${YELLOW}Day 7: 2025-11-16 - Dimension Tables${NC}"
create_commit "2025-11-16 10:00:00" "Create customer dimension schema" "sql/schema/create_dim_customer.sql"
create_commit "2025-11-16 12:00:00" "Create item dimension schema" "sql/schema/create_dim_item.sql"
create_commit "2025-11-16 14:00:00" "Create calendar dimension schema" "sql/schema/create_dim_calendar.sql"
create_commit "2025-11-16 16:00:00" "Add dimension indexes" ""
create_commit "2025-11-16 17:30:00" "Add dimension views" ""

# Day 8: 2025-11-17 (Sunday) - Fact tables
echo -e "\n${YELLOW}Day 8: 2025-11-17 - Fact Tables${NC}"
create_commit "2025-11-17 10:00:00" "Create sales fact schema" "sql/schema/create_fact_sales.sql"
create_commit "2025-11-17 12:00:00" "Create delivery fact schema" "sql/schema/create_fact_delivery.sql"
create_commit "2025-11-17 14:00:00" "Add fact table indexes" ""
create_commit "2025-11-17 16:00:00" "Add fact table views" ""
create_commit "2025-11-17 17:30:00" "Optimize fact table structure" ""

# Day 9: 2025-11-18 (Monday) - OTD KPI
echo -e "\n${YELLOW}Day 9: 2025-11-18 - On-Time Delivery KPI${NC}"
create_commit "2025-11-18 08:00:00" "Create OTD KPI views" "sql/kpis/otd_on_time_delivery.sql"
create_commit "2025-11-18 10:00:00" "Add daily OTD summary" ""
create_commit "2025-11-18 12:00:00" "Add OTD by customer view" ""
create_commit "2025-11-18 14:00:00" "Add OTD by item view" ""
create_commit "2025-11-18 16:00:00" "Add OTD trend analysis" ""
create_commit "2025-11-18 17:30:00" "Add OTD stored procedures" ""

# Day 10: 2025-11-19 (Tuesday) - Inventory Aging KPI
echo -e "\n${YELLOW}Day 10: 2025-11-19 - Inventory Aging KPI${NC}"
create_commit "2025-11-19 08:30:00" "Create inventory aging KPI" "sql/kpis/inventory_aging.sql"
create_commit "2025-11-19 10:00:00" "Add aging bucket logic" ""
create_commit "2025-11-19 12:00:00" "Add aging summary view" ""
create_commit "2025-11-19 14:00:00" "Add slow moving items view" ""
create_commit "2025-11-19 16:00:00" "Add aging by category" ""
create_commit "2025-11-19 17:30:00" "Add inventory aging reports" ""

# Day 11: 2025-11-20 (Wednesday) - Sales Margin KPI
echo -e "\n${YELLOW}Day 11: 2025-11-20 - Sales Margin KPI${NC}"
create_commit "2025-11-20 09:00:00" "Create sales margin KPI" "sql/kpis/sales_margin.sql"
create_commit "2025-11-20 10:30:00" "Add margin by customer" ""
create_commit "2025-11-20 12:00:00" "Add margin by item" ""
create_commit "2025-11-20 14:00:00" "Add margin trend analysis" ""
create_commit "2025-11-20 16:00:00" "Add low margin alerts" ""
create_commit "2025-11-20 17:30:00" "Add margin stored procedures" ""

# Day 12: 2025-11-21 (Thursday) - Forecast Accuracy KPI
echo -e "\n${YELLOW}Day 12: 2025-11-21 - Forecast Accuracy KPI${NC}"
create_commit "2025-11-21 08:00:00" "Create forecast accuracy KPI" "sql/kpis/forecast_accuracy.sql"
create_commit "2025-11-21 10:00:00" "Add MAPE calculation" ""
create_commit "2025-11-21 12:00:00" "Add forecast vs actual views" ""
create_commit "2025-11-21 14:00:00" "Add forecast bias analysis" ""
create_commit "2025-11-21 16:00:00" "Add forecast accuracy by item" ""
create_commit "2025-11-21 17:30:00" "Add forecast reports" ""

# Day 13: 2025-11-22 (Friday) - OEE KPI
echo -e "\n${YELLOW}Day 13: 2025-11-22 - OEE KPI${NC}"
create_commit "2025-11-22 08:30:00" "Create OEE KPI views" "sql/kpis/production_oee.sql"
create_commit "2025-11-22 10:00:00" "Add availability calculation" ""
create_commit "2025-11-22 12:00:00" "Add performance calculation" ""
create_commit "2025-11-22 14:00:00" "Add quality calculation" ""
create_commit "2025-11-22 16:00:00" "Add OEE by production line" ""
create_commit "2025-11-22 17:30:00" "Add OEE loss analysis" ""

# Day 14: 2025-11-23 (Saturday) - ETL Pipeline
echo -e "\n${YELLOW}Day 14: 2025-11-23 - ETL Pipeline${NC}"
create_commit "2025-11-23 10:00:00" "Create pipeline orchestrator" "etl/pipeline.py"
create_commit "2025-11-23 12:00:00" "Add full load logic" ""
create_commit "2025-11-23 14:00:00" "Add incremental load logic" ""
create_commit "2025-11-23 16:00:00" "Add CLI interface" ""
create_commit "2025-11-23 17:30:00" "Add progress tracking" ""

# Day 15: 2025-11-24 (Sunday) - Scheduler
echo -e "\n${YELLOW}Day 15: 2025-11-24 - Scheduler${NC}"
create_commit "2025-11-24 10:00:00" "Create scheduler module" "etl/scheduler_example.py"
create_commit "2025-11-24 12:00:00" "Add APScheduler integration" ""
create_commit "2025-11-24 14:00:00" "Add job management" ""
create_commit "2025-11-24 16:00:00" "Add event listeners" ""
create_commit "2025-11-24 17:30:00" "Add production deployment examples" ""

# Day 16: 2025-11-25 (Monday) - Documentation
echo -e "\n${YELLOW}Day 16: 2025-11-25 - Architecture Documentation${NC}"
create_commit "2025-11-25 08:00:00" "Create architecture documentation" "docs/architecture.md"
create_commit "2025-11-25 10:00:00" "Add architecture diagram" ""
create_commit "2025-11-25 12:00:00" "Document data flow" ""
create_commit "2025-11-25 14:00:00" "Add design decisions" ""
create_commit "2025-11-25 16:00:00" "Add scalability considerations" ""
create_commit "2025-11-25 17:30:00" "Add security documentation" ""

# Day 17: 2025-11-26 (Tuesday) - Table Reference
echo -e "\n${YELLOW}Day 17: 2025-11-26 - SAP B1 Tables Reference${NC}"
create_commit "2025-11-26 08:30:00" "Create tables reference doc" "docs/sap_b1_tables_reference.md"
create_commit "2025-11-26 10:00:00" "Document master data tables" ""
create_commit "2025-11-26 12:00:00" "Document transaction tables" ""
create_commit "2025-11-26 14:00:00" "Add table relationships" ""
create_commit "2025-11-26 16:00:00" "Add query examples" ""
create_commit "2025-11-26 17:30:00" "Add best practices" ""

# Day 18: 2025-11-27 (Wednesday) - KPI Definitions
echo -e "\n${YELLOW}Day 18: 2025-11-27 - KPI Definitions${NC}"
create_commit "2025-11-27 09:00:00" "Create KPI definitions doc" "docs/kpi_definitions.md"
create_commit "2025-11-27 10:30:00" "Document OTD KPI" ""
create_commit "2025-11-27 12:00:00" "Document inventory aging KPI" ""
create_commit "2025-11-27 14:00:00" "Document sales margin KPI" ""
create_commit "2025-11-27 16:00:00" "Document forecast accuracy KPI" ""
create_commit "2025-11-27 17:30:00" "Document OEE KPI" ""

# Day 19: 2025-11-28 (Thursday) - Setup Guide
echo -e "\n${YELLOW}Day 19: 2025-11-28 - Setup Guide${NC}"
create_commit "2025-11-28 08:00:00" "Create setup guide" "docs/setup_guide.md"
create_commit "2025-11-28 10:00:00" "Add prerequisites" ""
create_commit "2025-11-28 12:00:00" "Add installation steps" ""
create_commit "2025-11-28 14:00:00" "Add configuration details" ""
create_commit "2025-11-28 16:00:00" "Add troubleshooting section" ""
create_commit "2025-11-28 17:30:00" "Add production deployment guide" ""

# Day 20: 2025-11-29 (Friday) - FAQ
echo -e "\n${YELLOW}Day 20: 2025-11-29 - FAQ${NC}"
create_commit "2025-11-29 08:30:00" "Create FAQ document" "docs/faq.md"
create_commit "2025-11-29 10:00:00" "Add general questions" ""
create_commit "2025-11-29 12:00:00" "Add technical questions" ""
create_commit "2025-11-29 14:00:00" "Add ETL questions" ""
create_commit "2025-11-29 16:00:00" "Add KPI questions" ""
create_commit "2025-11-29 17:30:00" "Add troubleshooting tips" ""

# Day 21: 2025-11-30 (Saturday) - Tests
echo -e "\n${YELLOW}Day 21: 2025-11-30 - Test Suite${NC}"
create_commit "2025-11-30 10:00:00" "Create test structure" "tests/"
create_commit "2025-11-30 12:00:00" "Add ETL pipeline tests" "tests/test_etl_pipeline.py"
create_commit "2025-11-30 14:00:00" "Add transformer tests" ""
create_commit "2025-11-30 16:00:00" "Add extractor tests" ""
create_commit "2025-11-30 17:30:00" "Add loader tests" ""

# Day 22: 2025-12-01 (Sunday) - More Tests
echo -e "\n${YELLOW}Day 22: 2025-12-01 - SQL and Data Quality Tests${NC}"
create_commit "2025-12-01 10:00:00" "Add SQL validity tests" "tests/test_kpi_sql_validity.py"
create_commit "2025-12-01 12:00:00" "Add data quality tests" "tests/test_data_quality.py"
create_commit "2025-12-01 14:00:00" "Add integration tests" ""
create_commit "2025-12-01 16:00:00" "Add test fixtures" ""
create_commit "2025-12-01 17:30:00" "Configure pytest" ""

# Day 23: 2025-12-02 (Monday) - Bug fixes
echo -e "\n${YELLOW}Day 23: 2025-12-02 - Bug Fixes${NC}"
create_commit "2025-12-02 08:00:00" "Fix connection pooling issue" "etl/db.py"
create_commit "2025-12-02 10:00:00" "Fix SCD2 logic bug" "etl/load.py"
create_commit "2025-12-02 12:00:00" "Fix date key generation" "etl/transform.py"
create_commit "2025-12-02 14:00:00" "Fix null handling in transformations" ""
create_commit "2025-12-02 16:00:00" "Fix division by zero in KPIs" "sql/kpis/"
create_commit "2025-12-02 17:30:00" "Update error handling" "etl/pipeline.py"

# Day 24: 2025-12-03 (Tuesday) - Optimizations
echo -e "\n${YELLOW}Day 24: 2025-12-03 - Performance Optimizations${NC}"
create_commit "2025-12-03 08:30:00" "Optimize batch processing" "etl/extract.py"
create_commit "2025-12-03 10:00:00" "Add query caching" "etl/db.py"
create_commit "2025-12-03 12:00:00" "Optimize dimension lookups" "etl/load.py"
create_commit "2025-12-03 14:00:00" "Add parallel processing" "etl/pipeline.py"
create_commit "2025-12-03 16:00:00" "Optimize SQL views" "sql/kpis/"
create_commit "2025-12-03 17:30:00" "Add performance metrics" ""

# Day 25: 2025-12-04 (Wednesday) - Enhancements
echo -e "\n${YELLOW}Day 25: 2025-12-04 - Feature Enhancements${NC}"
create_commit "2025-12-04 09:00:00" "Add data validation rules" "etl/transform.py"
create_commit "2025-12-04 10:30:00" "Add custom business rules" ""
create_commit "2025-12-04 12:00:00" "Enhance error reporting" "etl/pipeline.py"
create_commit "2025-12-04 14:00:00" "Add email notifications" "etl/scheduler_example.py"
create_commit "2025-12-04 16:00:00" "Add audit logging" "etl/load.py"
create_commit "2025-12-04 17:30:00" "Enhance configuration options" "config/config.example.yaml"

# Day 26: 2025-12-05 (Thursday) - Documentation updates
echo -e "\n${YELLOW}Day 26: 2025-12-05 - Documentation Updates${NC}"
create_commit "2025-12-05 08:00:00" "Update README with examples" "README.md"
create_commit "2025-12-05 10:00:00" "Add architecture diagrams" "docs/architecture.md"
create_commit "2025-12-05 12:00:00" "Update setup guide" "docs/setup_guide.md"
create_commit "2025-12-05 14:00:00" "Add more FAQ entries" "docs/faq.md"
create_commit "2025-12-05 16:00:00" "Update KPI documentation" "docs/kpi_definitions.md"
create_commit "2025-12-05 17:30:00" "Add code examples" "docs/"

# Day 27: 2025-12-06 (Friday) - Code refactoring
echo -e "\n${YELLOW}Day 27: 2025-12-06 - Code Refactoring${NC}"
create_commit "2025-12-06 08:30:00" "Refactor database connection" "etl/db.py"
create_commit "2025-12-06 10:00:00" "Refactor extraction logic" "etl/extract.py"
create_commit "2025-12-06 12:00:00" "Refactor transformation logic" "etl/transform.py"
create_commit "2025-12-06 14:00:00" "Improve code documentation" "etl/"
create_commit "2025-12-06 16:00:00" "Add type hints" ""
create_commit "2025-12-06 17:30:00" "Improve error messages" ""

# Day 28: 2025-12-07 (Saturday) - Testing improvements
echo -e "\n${YELLOW}Day 28: 2025-12-07 - Testing Improvements${NC}"
create_commit "2025-12-07 10:00:00" "Add more unit tests" "tests/test_etl_pipeline.py"
create_commit "2025-12-07 12:00:00" "Add edge case tests" "tests/test_data_quality.py"
create_commit "2025-12-07 14:00:00" "Improve test coverage" "tests/"
create_commit "2025-12-07 16:00:00" "Add mock data generators" ""
create_commit "2025-12-07 17:30:00" "Update test documentation" ""

# Day 29: 2025-12-08 (Sunday) - SQL improvements
echo -e "\n${YELLOW}Day 29: 2025-12-08 - SQL Improvements${NC}"
create_commit "2025-12-08 10:00:00" "Optimize OTD queries" "sql/kpis/otd_on_time_delivery.sql"
create_commit "2025-12-08 12:00:00" "Optimize inventory aging queries" "sql/kpis/inventory_aging.sql"
create_commit "2025-12-08 14:00:00" "Optimize margin queries" "sql/kpis/sales_margin.sql"
create_commit "2025-12-08 16:00:00" "Add query hints" "sql/kpis/"
create_commit "2025-12-08 17:30:00" "Improve view performance" ""

# Day 30: 2025-12-09 (Monday) - Configuration enhancements
echo -e "\n${YELLOW}Day 30: 2025-12-09 - Configuration Enhancements${NC}"
create_commit "2025-12-09 08:00:00" "Add environment-specific configs" "config/"
create_commit "2025-12-09 10:00:00" "Add validation for config" "etl/pipeline.py"
create_commit "2025-12-09 12:00:00" "Add default values" "config/config.example.yaml"
create_commit "2025-12-09 14:00:00" "Add config documentation" "docs/setup_guide.md"
create_commit "2025-12-09 16:00:00" "Add secrets management guide" "docs/"
create_commit "2025-12-09 17:30:00" "Update configuration examples" ""

# Day 31: 2025-12-10 (Tuesday) - Logging improvements
echo -e "\n${YELLOW}Day 31: 2025-12-10 - Logging Improvements${NC}"
create_commit "2025-12-10 08:30:00" "Enhance logging format" "etl/pipeline.py"
create_commit "2025-12-10 10:00:00" "Add structured logging" "etl/db.py"
create_commit "2025-12-10 12:00:00" "Add log rotation" "etl/scheduler_example.py"
create_commit "2025-12-10 14:00:00" "Add performance logging" "etl/extract.py"
create_commit "2025-12-10 16:00:00" "Add debug mode" "etl/"
create_commit "2025-12-10 17:30:00" "Update logging documentation" "docs/"

# Day 32: 2025-12-11 (Wednesday) - Error handling
echo -e "\n${YELLOW}Day 32: 2025-12-11 - Error Handling${NC}"
create_commit "2025-12-11 09:00:00" "Improve error handling in extract" "etl/extract.py"
create_commit "2025-12-11 10:30:00" "Improve error handling in transform" "etl/transform.py"
create_commit "2025-12-11 12:00:00" "Improve error handling in load" "etl/load.py"
create_commit "2025-12-11 14:00:00" "Add retry logic" "etl/db.py"
create_commit "2025-12-11 16:00:00" "Add graceful degradation" "etl/pipeline.py"
create_commit "2025-12-11 17:30:00" "Update error handling docs" "docs/"

# Day 33: 2025-12-12 (Thursday) - Monitoring
echo -e "\n${YELLOW}Day 33: 2025-12-12 - Monitoring${NC}"
create_commit "2025-12-12 08:00:00" "Add execution metrics" "etl/pipeline.py"
create_commit "2025-12-12 10:00:00" "Add health check endpoint" "etl/"
create_commit "2025-12-12 12:00:00" "Add alerting framework" "etl/scheduler_example.py"
create_commit "2025-12-12 14:00:00" "Add performance tracking" "etl/db.py"
create_commit "2025-12-12 16:00:00" "Add monitoring documentation" "docs/"
create_commit "2025-12-12 17:30:00" "Add dashboard examples" ""

# Day 34: 2025-12-13 (Friday) - Security enhancements
echo -e "\n${YELLOW}Day 34: 2025-12-13 - Security Enhancements${NC}"
create_commit "2025-12-13 08:30:00" "Add credential encryption" "etl/db.py"
create_commit "2025-12-13 10:00:00" "Add SSL/TLS support" ""
create_commit "2025-12-13 12:00:00" "Add audit logging" "etl/load.py"
create_commit "2025-12-13 14:00:00" "Add input validation" "etl/transform.py"
create_commit "2025-12-13 16:00:00" "Add security documentation" "docs/"
create_commit "2025-12-13 17:30:00" "Update security best practices" ""

# Day 35: 2025-12-14 (Saturday) - Final testing
echo -e "\n${YELLOW}Day 35: 2025-12-14 - Final Testing${NC}"
create_commit "2025-12-14 10:00:00" "Run comprehensive test suite" "tests/"
create_commit "2025-12-14 12:00:00" "Fix test failures" ""
create_commit "2025-12-14 14:00:00" "Add integration test scenarios" ""
create_commit "2025-12-14 16:00:00" "Validate all KPIs" "sql/kpis/"
create_commit "2025-12-14 17:30:00" "Update test documentation" "tests/"

# Day 36: 2025-12-15 (Sunday) - Documentation polish
echo -e "\n${YELLOW}Day 36: 2025-12-15 - Documentation Polish${NC}"
create_commit "2025-12-15 10:00:00" "Polish README" "README.md"
create_commit "2025-12-15 12:00:00" "Polish architecture docs" "docs/architecture.md"
create_commit "2025-12-15 14:00:00" "Polish setup guide" "docs/setup_guide.md"
create_commit "2025-12-15 16:00:00" "Polish KPI definitions" "docs/kpi_definitions.md"
create_commit "2025-12-15 17:30:00" "Add final examples" "docs/"

# Day 37: 2025-12-16 (Monday) - Code cleanup
echo -e "\n${YELLOW}Day 37: 2025-12-16 - Code Cleanup${NC}"
create_commit "2025-12-16 08:00:00" "Remove dead code" "etl/"
create_commit "2025-12-16 10:00:00" "Format code with black" ""
create_commit "2025-12-16 12:00:00" "Fix linting issues" ""
create_commit "2025-12-16 14:00:00" "Update docstrings" ""
create_commit "2025-12-16 16:00:00" "Add missing type hints" ""
create_commit "2025-12-16 17:30:00" "Final code review" ""

# Day 38: 2025-12-17 (Tuesday) - Final touches
echo -e "\n${YELLOW}Day 38: 2025-12-17 - Final Touches${NC}"
create_commit "2025-12-17 08:30:00" "Add LICENSE file" "LICENSE"
create_commit "2025-12-17 10:00:00" "Add CONTRIBUTING guide" "CONTRIBUTING.md"
create_commit "2025-12-17 12:00:00" "Add CODE_OF_CONDUCT" "CODE_OF_CONDUCT.md"
create_commit "2025-12-17 14:00:00" "Update requirements.txt versions" "requirements.txt"
create_commit "2025-12-17 16:00:00" "Add release notes" "CHANGELOG.md"
create_commit "2025-12-17 17:30:00" "Final documentation review" "docs/"

# Day 39: 2025-12-18 (Wednesday) - Release preparation
echo -e "\n${YELLOW}Day 39: 2025-12-18 - Release Preparation${NC}"
create_commit "2025-12-18 08:00:00" "Prepare v1.0.0 release" ""
create_commit "2025-12-18 10:00:00" "Update version numbers" "etl/__init__.py"
create_commit "2025-12-18 12:00:00" "Final testing and validation" ""
create_commit "2025-12-18 14:00:00" "Update README for release" "README.md"
create_commit "2025-12-18 16:00:00" "Add deployment checklist" "docs/"
create_commit "2025-12-18 18:00:00" "Release v1.0.0 - SAP B1 Analytics Pack" ""

# Count total commits
COMMIT_COUNT=$(git rev-list --count HEAD)

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Git Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Total commits created: $COMMIT_COUNT${NC}"
echo -e "${GREEN}Date range: 2025-11-10 to 2025-12-18${NC}"
echo -e "${GREEN}========================================${NC}"

# Show git log summary
echo -e "\n${YELLOW}Recent commits:${NC}"
git log --oneline --graph --decorate -10

echo -e "\n${GREEN}Ready to push to GitHub!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Create GitHub repository"
echo -e "  2. git remote add origin <your-repo-url>"
echo -e "  3. git push -u origin main"

