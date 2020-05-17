# Frequently Asked Questions (FAQ)

## General Questions

### Q: What is the SAP B1 Analytics Pack?
**A:** It's a complete analytics solution for SAP Business One that includes dimensional data models, ETL pipelines, pre-built KPIs, and dashboard templates. It transforms operational SAP B1 data into an analytics-optimized structure for reporting and business intelligence.

### Q: Do I need to modify my SAP B1 system?
**A:** No. The analytics pack reads from SAP B1 in read-only mode. It doesn't modify your operational system. However, some KPIs use User-Defined Fields (UDFs) which you may want to add to your SAP B1 system.

### Q: What SAP B1 versions are supported?
**A:** SAP Business One 9.3 and higher. Works with both SQL Server and HANA databases.

### Q: Is this an official SAP product?
**A:** No, this is an open-source community project. It's not affiliated with or endorsed by SAP SE.

## Technical Questions

### Q: What databases are supported for the analytics warehouse?
**A:** 
- Microsoft SQL Server 2016+
- PostgreSQL 12+
- Can be extended to support other databases

### Q: How long does the initial load take?
**A:** Depends on data volume:
- Small (< 100K transactions): 10-30 minutes
- Medium (100K - 1M transactions): 30 minutes - 2 hours
- Large (> 1M transactions): 2-8 hours

### Q: Can I run this on the same server as SAP B1?
**A:** Yes, but it's recommended to use a separate analytics server to avoid impacting operational performance.

### Q: What are the hardware requirements?
**A:**
- **Minimum**: 4 CPU cores, 8GB RAM, 50GB storage
- **Recommended**: 8 CPU cores, 16GB RAM, 200GB SSD storage
- **Large deployments**: 16+ CPU cores, 32GB+ RAM, 500GB+ SSD

### Q: Does it support multiple SAP B1 companies?
**A:** Yes, you can configure multiple source databases. Each company can load into the same or separate analytics warehouses.

## ETL Questions

### Q: How often should I run the ETL?
**A:**
- **Dimensions**: Daily (low change frequency)
- **Facts**: Hourly to daily (depending on business needs)
- **Recommended**: Incremental loads every 2-4 hours

### Q: What happens if the ETL fails?
**A:** The ETL has built-in error handling:
- Errors are logged
- Failed batches can be retried
- Data integrity is maintained (transactions)
- Alerts can be configured

### Q: Can I customize the ETL logic?
**A:** Yes! The Python code is fully customizable. You can:
- Add custom transformations
- Create new dimensions/facts
- Modify business rules
- Add data quality checks

### Q: How do I handle historical data?
**A:** Use the initial load with custom date ranges:
```bash
python -m etl.pipeline --mode full --start-date 2020-01-01
```

## Data Model Questions

### Q: What is SCD Type 2?
**A:** Slowly Changing Dimension Type 2 tracks historical changes. When a customer's tier changes, the old record is closed (end_date set) and a new record is created. This preserves history for point-in-time analysis.

### Q: Why use surrogate keys instead of natural keys?
**A:**
- Performance: Integer keys are faster to join
- Flexibility: Handles changes in source systems
- SCD Support: Enables historical tracking
- Consistency: Uniform key structure

### Q: Can I add custom dimensions?
**A:** Yes! Follow these steps:
1. Create dimension table SQL script
2. Add extraction logic in `extract.py`
3. Add transformation logic in `transform.py`
4. Add load logic in `load.py`
5. Update pipeline to include new dimension

### Q: How is data security handled?
**A:**
- Database-level security (row-level, column-level)
- Encrypted connections (SSL/TLS)
- Audit logging
- Role-based access control

## KPI Questions

### Q: Can I modify KPI calculations?
**A:** Yes, all KPIs are defined in SQL views that you can modify. They're in the `sql/kpis/` directory.

### Q: How do I add a new KPI?
**A:**
1. Create SQL view in `sql/kpis/`
2. Document formula and business logic
3. Test with sample data
4. Add to Power BI dashboard

### Q: Why are some KPI values NULL?
**A:** Common reasons:
- Insufficient data (e.g., no deliveries with promised dates)
- Division by zero protection
- Missing required fields
- Date range filters excluding all data

### Q: How accurate are the KPIs?
**A:** KPIs are as accurate as your source data. Ensure:
- SAP B1 data is complete and accurate
- UDFs are populated correctly
- Master data is maintained
- Transactions are posted timely

## Performance Questions

### Q: Why are my queries slow?
**A:** Check these factors:
1. Missing indexes (run index creation scripts)
2. Outdated statistics (run UPDATE STATISTICS)
3. Large date ranges (add filters)
4. Complex joins (use pre-aggregated views)
5. Hardware resources (CPU, RAM, disk I/O)

### Q: How can I improve ETL performance?
**A:**
- Increase `batch_size` in config
- Use incremental loads
- Run during off-peak hours
- Add indexes on source tables
- Use parallel processing
- Optimize network bandwidth

### Q: How much storage do I need?
**A:** Rule of thumb:
- Analytics warehouse: 2-3x size of SAP B1 transactional data
- Includes dimensions, facts, indexes, and history
- Example: 10GB SAP B1 data → 20-30GB analytics warehouse

## Integration Questions

### Q: Can I use Tableau instead of Power BI?
**A:** Yes! The analytics warehouse is tool-agnostic. Connect Tableau (or any BI tool) directly to the SQL views.

### Q: How do I integrate with Excel?
**A:** Several options:
1. Power Query: Connect directly to database
2. ODBC connection: Use Excel's data connection wizard
3. Export: Create scheduled exports to CSV/Excel

### Q: Can I expose KPIs via API?
**A:** Yes, you can build a REST API layer:
- Use Flask/FastAPI to query the database
- Return JSON responses
- Implement authentication
- Cache frequently accessed metrics

### Q: Does it work with SAP Analytics Cloud?
**A:** Yes, SAC can connect to the analytics warehouse as a data source.

## Troubleshooting

### Q: ETL runs but no data appears
**A:** Check:
1. Source database has data in date range
2. Filters aren't excluding all records
3. Dimension lookups are successful
4. No errors in logs
5. Verify with row count queries

### Q: "Table does not exist" error
**A:** Ensure:
1. Analytics schema is created
2. Table creation scripts were run
3. Schema name in config matches actual schema
4. User has permissions to access schema

### Q: Memory errors during ETL
**A:** Solutions:
1. Reduce `batch_size` in config
2. Process smaller date ranges
3. Increase system memory
4. Use streaming/chunking for large tables

### Q: Duplicate records in fact tables
**A:** Causes:
1. ETL ran multiple times without deduplication
2. Source data has duplicates
3. Missing unique constraints

**Solution**: Implement upsert logic or add unique constraints.

## Licensing and Support

### Q: What is the license?
**A:** MIT License - free for commercial and personal use.

### Q: Is there commercial support available?
**A:** This is a community project. For commercial support, consider:
- Hiring a consultant familiar with the codebase
- SAP partners offering analytics services
- Contributing to the project and building expertise

### Q: How can I contribute?
**A:** Contributions welcome!
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. Follow coding standards

### Q: Where can I get help?
**A:**
- GitHub Issues: Bug reports and feature requests
- GitHub Discussions: Questions and community support
- Documentation: Comprehensive guides in `/docs`

## Best Practices

### Q: What's the recommended deployment architecture?
**A:**
- **Development**: Local machine or dev server
- **Testing**: Dedicated test environment with sample data
- **Production**: Separate analytics server with monitoring

### Q: How should I handle upgrades?
**A:**
1. Test in development environment
2. Backup analytics database
3. Review changelog for breaking changes
4. Run database migration scripts
5. Update Python dependencies
6. Test ETL and reports
7. Deploy to production

### Q: What monitoring should I implement?
**A:**
- ETL job success/failure alerts
- Data freshness monitoring
- Query performance tracking
- Disk space alerts
- Error rate thresholds

## Additional Resources

- [Setup Guide](setup_guide.md)
- [Architecture Documentation](architecture.md)
- [KPI Definitions](kpi_definitions.md)
- [SAP B1 Tables Reference](sap_b1_tables_reference.md)

