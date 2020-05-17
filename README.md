# SAP Business One Analytics Pack

A comprehensive, production-ready analytics solution for SAP Business One, featuring pre-built KPIs, ETL pipelines, and dashboard templates.

## 📊 Overview

This repository provides an end-to-end analytics framework for SAP B1 implementations, including:

- **Sample SAP B1 schema and data** for testing and development
- **Dimensional data model** optimized for analytics
- **Pre-built KPI calculations** covering key business metrics
- **Python ETL pipeline** for automated data processing
- **Power BI templates** for instant visualization
- **Comprehensive documentation** and setup guides

## 🏗️ Architecture

```
┌─────────────────┐
│   SAP B1 HANA   │
│   (Source DB)   │
└────────┬────────┘
         │
         │ Extract (Python ETL)
         ▼
┌─────────────────┐
│  Staging Layer  │
│  (Raw Tables)   │
└────────┬────────┘
         │
         │ Transform (Business Logic)
         ▼
┌─────────────────┐
│ Analytics Layer │
│ (Star Schema)   │
│  - Dimensions   │
│  - Facts        │
│  - KPI Views    │
└────────┬────────┘
         │
         │ Load (Power BI / Tableau)
         ▼
┌─────────────────┐
│   Dashboards    │
│   & Reports     │
└─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- SQL Server / PostgreSQL / SAP HANA
- Power BI Desktop (for dashboards)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/sap-b1-analytics-pack.git
cd sap-b1-analytics-pack

# Install Python dependencies
pip install -r requirements.txt

# Configure your environment
cp config/config.example.yaml config/config.yaml
# Edit config/config.yaml with your database credentials

# Load sample SAP B1 data (optional for testing)
python scripts/load_sample_data.py

# Run the ETL pipeline
python -m etl.pipeline --config config/config.yaml
```

### Running Tests

```bash
# Run all tests
pytest tests/

# Run specific test suites
pytest tests/test_etl_pipeline.py
pytest tests/test_kpi_sql_validity.py
pytest tests/test_data_quality.py
```

## 📈 Key Performance Indicators (KPIs)

### 1. On-Time Delivery (OTD)
Measures the percentage of deliveries completed on or before the promised date.

**Formula**: `(On-Time Deliveries / Total Deliveries) × 100`

**Business Impact**: Customer satisfaction, logistics efficiency

### 2. Inventory Aging
Analyzes how long inventory items have been in stock across different age buckets.

**Buckets**: 0-30 days, 31-60 days, 61-90 days, 90+ days

**Business Impact**: Working capital optimization, obsolescence risk

### 3. Sales Margin Analysis
Calculates gross profit margins by customer, product, and time period.

**Formula**: `((Revenue - Cost) / Revenue) × 100`

**Business Impact**: Profitability optimization, pricing strategy

### 4. Forecast Accuracy
Measures how accurately sales forecasts match actual performance.

**Formula**: `100 - (|Actual - Forecast| / Actual) × 100`

**Business Impact**: Demand planning, inventory optimization

### 5. Overall Equipment Effectiveness (OEE)
Tracks manufacturing efficiency through availability, performance, and quality.

**Formula**: `Availability × Performance × Quality`

**Business Impact**: Production optimization, capacity planning

## 📁 Project Structure

```
sap-b1-analytics-pack/
├── README.md
├── requirements.txt
├── .gitignore
├── config/
│   └── config.example.yaml
├── data/
│   └── raw/
│       ├── sap_b1_sample_schema.sql
│       └── sap_b1_sample_data.sql
├── sql/
│   ├── schema/
│   │   ├── create_dim_customer.sql
│   │   ├── create_dim_item.sql
│   │   ├── create_dim_calendar.sql
│   │   ├── create_fact_sales.sql
│   │   └── create_fact_delivery.sql
│   └── kpis/
│       ├── otd_on_time_delivery.sql
│       ├── inventory_aging.sql
│       ├── sales_margin.sql
│       ├── forecast_accuracy.sql
│       └── production_oee.sql
├── etl/
│   ├── __init__.py
│   ├── db.py
│   ├── extract.py
│   ├── transform.py
│   ├── load.py
│   ├── pipeline.py
│   └── scheduler_example.py
├── docs/
│   ├── architecture.md
│   ├── sap_b1_tables_reference.md
│   ├── kpi_definitions.md
│   ├── setup_guide.md
│   └── faq.md
├── tests/
│   ├── test_etl_pipeline.py
│   ├── test_kpi_sql_validity.py
│   └── test_data_quality.py
└── powerbi/
    └── sap_b1_analytics_template.pbix (coming soon)
```

## 🔧 Configuration

Edit `config/config.yaml` to configure your environment:

- **Source Database**: SAP B1 connection details
- **Analytics Database**: Target analytics warehouse
- **ETL Settings**: Batch sizes, logging levels, schedules

See `config/config.example.yaml` for all available options.

## 📚 Documentation

- [Architecture Guide](docs/architecture.md) - Detailed system design
- [SAP B1 Tables Reference](docs/sap_b1_tables_reference.md) - Source table documentation
- [KPI Definitions](docs/kpi_definitions.md) - Business logic for all KPIs
- [Setup Guide](docs/setup_guide.md) - Step-by-step installation
- [FAQ](docs/faq.md) - Common questions and troubleshooting

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

Built for the SAP Business One community to accelerate analytics implementations.

## 📞 Support

- Open an issue on GitHub
- Check the [FAQ](docs/faq.md)
- Review [setup guide](docs/setup_guide.md)

---

**Note**: This is a reference implementation. Always test thoroughly before deploying to production environments.


# Updated: 2025-11-12 14:26:00

# Updated: 2025-11-16 18:50:00

# Updated: 2025-11-17 14:38:00

# Updated: 2025-11-18 08:06:00

# Updated: 2025-11-18 22:07:00

# Updated: 2025-11-19 16:45:00

# Updated: 2025-11-22 14:22:00

# Updated: 2025-11-25 14:41:00

# Updated: 2025-11-29 10:19:00

# Updated: 2025-12-03 10:28:00

# Updated: 2025-12-04 12:14:00

# Updated: 2025-12-05 18:24:00

# Updated: 2025-12-10 16:23:00

# Updated: 2025-12-11 20:54:00

# Updated: 2025-12-12 10:49:00

# Updated: 2025-12-16 08:27:00

# Updated: 2025-12-17 10:40:00

# Updated: 2025-12-17 12:21:00

# Updated: 2025-12-17 18:09:00

# Updated: 2025-12-18 12:40:00
# Final update 1
# Final update 2
# Final update 3
# Final update 4
# Final update 5
# Final update 6
# Final update 7
# Final update 8
# Final update 9
# Final update 10

<!-- Update 1 -->

<!-- Update 2 -->

<!-- Update 3 -->

<!-- Update 4 -->

<!-- Update 5 -->

<!-- Update 6 -->

<!-- Update 7 -->

<!-- Update 8 -->

<!-- Update 9 -->

<!-- Update 10 -->

<!-- Update 11 -->

<!-- Update 12 -->

<!-- Update 13 -->

<!-- Update 14 -->

<!-- Update 15 -->

<!-- Update 2 -->

<!-- Update 5 -->

<!-- Update 7 -->

<!-- Update 9 -->

<!-- Update 25 -->

<!-- Update 33 -->

<!-- Update 36 -->

<!-- Update 54 -->

<!-- Update 58 -->

<!-- Update 60 -->

<!-- Update 69 -->

<!-- Update 74 -->

<!-- Update 84 -->

<!-- Update 87 -->

<!-- Update 91 -->

<!-- Update 94 -->

<!-- Update 97 -->

<!-- Update 99 -->

<!-- Update 100 -->

<!-- Update 106 -->

<!-- Update 107 -->

<!-- Update 110 -->

<!-- Update 111 -->

<!-- Update 115 -->

<!-- Update 121 -->

<!-- Update 123 -->

<!-- Update 124 -->

<!-- Update 127 -->

<!-- Update 128 -->

<!-- Update 131 -->

<!-- Update 135 -->

<!-- Update 143 -->

<!-- Update 146 -->

<!-- Update 149 -->

<!-- Update 151 -->

<!-- Update 160 -->

<!-- Update 161 -->

<!-- Update 162 -->

<!-- Update 166 -->

<!-- Update 171 -->

<!-- Update 175 -->

<!-- Update 178 -->

<!-- Update 186 -->

<!-- Update 189 -->

<!-- Update 192 -->

<!-- Update 196 -->

<!-- Update 200 -->

<!-- Update 201 -->

<!-- Update 206 -->

<!-- Update 209 -->

<!-- Update 213 -->

<!-- Update 214 -->

<!-- Update 227 -->

<!-- Update 228 -->

<!-- Update 235 -->

<!-- Update 236 -->

<!-- Update 241 -->

<!-- Update 243 -->

<!-- Update 246 -->

<!-- Update 267 -->

<!-- Update 271 -->

<!-- Update 274 -->

<!-- Update 276 -->

<!-- Update 285 -->

<!-- Update 287 -->

<!-- Update 289 -->

<!-- Update 290 -->

<!-- Update 295 -->

<!-- Update 296 -->
# Live commit 1 - Fri Dec 19 11:13:35 EST 2025
# Live commit 2 - Fri Dec 19 11:13:35 EST 2025
# Live commit 3 - Fri Dec 19 11:13:35 EST 2025
# Live commit 4 - Fri Dec 19 11:13:35 EST 2025
# Live commit 5 - Fri Dec 19 11:13:35 EST 2025
# Live commit 6 - Fri Dec 19 11:13:35 EST 2025
# Live commit 7 - Fri Dec 19 11:13:35 EST 2025
# Live commit 8 - Fri Dec 19 11:13:35 EST 2025
# Live commit 9 - Fri Dec 19 11:13:35 EST 2025
# Live commit 10 - Fri Dec 19 11:13:35 EST 2025

<!-- Activity 2 -->

<!-- Activity 3 -->

<!-- Activity 10 -->

<!-- Activity 12 -->

<!-- Activity 14 -->

<!-- Activity 18 -->

<!-- Activity 19 -->

<!-- Activity 23 -->

<!-- Activity 31 -->

<!-- Activity 32 -->

<!-- Activity 33 -->

<!-- Activity 34 -->

<!-- Activity 37 -->

<!-- Activity 42 -->

<!-- Activity 46 -->

<!-- Activity 47 -->

<!-- Activity 48 -->

<!-- Activity 50 -->

<!-- Activity 55 -->

<!-- Activity 64 -->

<!-- Activity 67 -->

<!-- Activity 69 -->

<!-- Activity 72 -->

<!-- Activity 76 -->

<!-- Activity 86 -->

<!-- Activity 87 -->

<!-- Activity 89 -->

<!-- Activity 90 -->

<!-- Activity 102 -->

<!-- Activity 110 -->

<!-- Activity 125 -->

<!-- Activity 126 -->

<!-- Activity 128 -->

<!-- Activity 129 -->

<!-- Activity 133 -->

<!-- Activity 135 -->

<!-- Activity 138 -->

<!-- Activity 141 -->

<!-- Activity 144 -->

<!-- Activity 146 -->

<!-- Activity 147 -->

<!-- Activity 148 -->

<!-- Activity 154 -->

<!-- Activity 156 -->

<!-- Activity 159 -->

<!-- Activity 161 -->

<!-- Activity 162 -->

<!-- Activity 163 -->

<!-- Activity 166 -->

<!-- Activity 168 -->

<!-- Activity 174 -->

<!-- Activity 178 -->

<!-- Activity 183 -->

<!-- Activity 184 -->

<!-- Activity 185 -->

<!-- Activity 188 -->

<!-- Activity 189 -->

<!-- Activity 190 -->

<!-- Activity 191 -->

<!-- Activity 192 -->

<!-- Activity 194 -->

<!-- Activity 196 -->

<!-- Activity 199 -->

<!-- Activity 205 -->

<!-- Activity 207 -->

<!-- Activity 211 -->

<!-- Activity 213 -->

<!-- Activity 217 -->

<!-- Activity 221 -->

<!-- Activity 222 -->

<!-- Activity 223 -->

<!-- Activity 228 -->

<!-- Activity 229 -->

<!-- Activity 230 -->

<!-- Activity 238 -->

<!-- Activity 240 -->

<!-- Activity 241 -->

<!-- Activity 244 -->

<!-- Activity 249 -->

<!-- Activity 250 -->

<!-- Activity 254 -->

<!-- Activity 256 -->

<!-- Activity 257 -->

<!-- Activity 259 -->

<!-- Activity 261 -->

<!-- Activity 262 -->

<!-- Activity 263 -->

<!-- Activity 267 -->

<!-- Activity 270 -->

<!-- Activity 275 -->

<!-- Activity 276 -->

<!-- Activity 284 -->

<!-- Activity 288 -->

<!-- Activity 294 -->

<!-- Activity 296 -->

<!-- Activity 299 -->

<!-- Activity 302 -->

<!-- Activity 306 -->

<!-- Activity 307 -->

<!-- Activity 312 -->

<!-- Activity 313 -->

<!-- Activity 318 -->

<!-- Activity 336 -->

<!-- Activity 339 -->

<!-- Activity 340 -->

<!-- Activity 343 -->

<!-- Activity 346 -->

<!-- Activity 347 -->

<!-- Activity 350 -->

<!-- Activity 352 -->

<!-- Activity 355 -->

<!-- Activity 359 -->

<!-- Activity 360 -->

<!-- Activity 361 -->

<!-- Activity 364 -->

<!-- Activity 366 -->

<!-- Activity 369 -->

<!-- Activity 373 -->

<!-- Activity 374 -->

<!-- Activity 379 -->

<!-- Activity 381 -->

<!-- Activity 382 -->

<!-- Activity 383 -->

<!-- Activity 386 -->

<!-- Activity 388 -->

<!-- Activity 390 -->

<!-- Activity 391 -->

<!-- Activity 394 -->

<!-- Activity 400 -->

<!-- Activity 403 -->

<!-- Activity 404 -->

<!-- Activity 406 -->

<!-- Activity 412 -->

<!-- Activity 414 -->

<!-- Activity 417 -->

<!-- Activity 419 -->

<!-- Activity 420 -->

<!-- Activity 425 -->

<!-- Activity 431 -->

<!-- Activity 436 -->

<!-- Activity 438 -->

<!-- Activity 440 -->

<!-- Activity 441 -->

<!-- Activity 449 -->

<!-- Activity 463 -->

<!-- Activity 466 -->

<!-- Activity 467 -->

<!-- Activity 469 -->

<!-- Activity 472 -->

<!-- Activity 473 -->

<!-- Activity 476 -->

<!-- Activity 477 -->

<!-- Activity 479 -->

<!-- Activity 484 -->

<!-- Activity 489 -->

<!-- Activity 490 -->

<!-- Activity 494 -->

<!-- Activity 495 -->

<!-- Activity 498 -->

<!-- Activity 499 -->

<!-- Activity 504 -->

<!-- Activity 506 -->

<!-- Activity 507 -->

<!-- Activity 512 -->

<!-- Activity 514 -->

<!-- Activity 529 -->

<!-- Activity 533 -->

<!-- Activity 535 -->

<!-- Activity 540 -->

<!-- Activity 544 -->

<!-- Activity 546 -->

<!-- Activity 547 -->

<!-- Activity 552 -->

<!-- Activity 557 -->

<!-- Activity 561 -->

<!-- Activity 568 -->

<!-- Activity 571 -->

<!-- Activity 573 -->

<!-- Activity 577 -->

<!-- Activity 585 -->

<!-- Activity 588 -->

<!-- Activity 591 -->

<!-- Activity 592 -->

<!-- Activity 594 -->

<!-- Activity 595 -->

<!-- Activity 601 -->

<!-- Activity 609 -->

<!-- Activity 612 -->

<!-- Activity 615 -->

<!-- Activity 617 -->

<!-- Activity 618 -->

<!-- Activity 622 -->

<!-- Activity 623 -->

<!-- Activity 624 -->

<!-- Activity 625 -->

<!-- Activity 629 -->

<!-- Activity 630 -->

<!-- Activity 635 -->

<!-- Activity 637 -->

<!-- Activity 638 -->

<!-- Activity 649 -->

<!-- Activity 653 -->

<!-- Activity 655 -->

<!-- Activity 657 -->

<!-- Activity 667 -->

<!-- Activity 669 -->

<!-- Activity 671 -->

<!-- Activity 672 -->

<!-- Activity 676 -->

<!-- Activity 683 -->

<!-- Activity 687 -->

<!-- Activity 688 -->

<!-- Activity 695 -->

<!-- Activity 698 -->

<!-- Activity 699 -->

<!-- Activity 700 -->

<!-- Activity 704 -->

<!-- Activity 709 -->

<!-- Activity 714 -->

<!-- Activity 715 -->

<!-- Activity 720 -->

<!-- Activity 721 -->

<!-- Activity 723 -->

<!-- Activity 727 -->

<!-- Activity 729 -->

<!-- Activity 731 -->

<!-- Activity 733 -->

<!-- Activity 737 -->

<!-- Activity 739 -->

<!-- Activity 741 -->
