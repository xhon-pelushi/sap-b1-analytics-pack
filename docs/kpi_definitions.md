# KPI Definitions

## Overview

This document provides detailed definitions, formulas, and business context for all KPIs included in the SAP B1 Analytics Pack.

## 1. On-Time Delivery (OTD)

### Definition
Percentage of deliveries completed on or before the promised delivery date.

### Formula
```
OTD % = (On-Time Deliveries / Total Deliveries) × 100

Where:
- On-Time Delivery = Actual Delivery Date ≤ Promised Delivery Date
- Total Deliveries = All completed deliveries with promised dates
```

### Business Impact
- **Customer Satisfaction**: Directly impacts customer experience
- **Competitive Advantage**: Reliable delivery is a key differentiator
- **Operational Efficiency**: Indicates supply chain effectiveness

### Target Benchmarks
- **World Class**: ≥ 95%
- **Good**: 90-94%
- **Fair**: 85-89%
- **Poor**: < 85%

### Dimensions
- By Customer (identify problematic accounts)
- By Item (identify difficult-to-deliver products)
- By Time Period (trend analysis)
- By Warehouse (location performance)

### SQL View
`vw_kpi_otd_daily`, `vw_kpi_otd_by_customer`, `vw_kpi_otd_by_item`

---

## 2. Inventory Aging

### Definition
Analysis of how long inventory has been in stock, categorized into age buckets.

### Age Buckets
- 0-30 days: Fresh inventory
- 31-60 days: Normal aging
- 61-90 days: Attention needed
- 91-180 days: Slow moving
- 180+ days: Obsolescence risk

### Formula
```
Days in Stock = Current Date - Last Receipt Date
Inventory Value = Quantity On Hand × Average Cost
```

### Business Impact
- **Working Capital**: Tied-up cash in inventory
- **Obsolescence Risk**: Older inventory may become unsellable
- **Storage Costs**: Carrying costs increase with age
- **Cash Flow**: Impacts liquidity

### Target Benchmarks
- **Ideal**: 80% of value in 0-60 days
- **Acceptable**: 90% of value in 0-90 days
- **Risk**: > 20% of value in 180+ days

### Actions by Risk Level
- **Low Risk** (0-60 days): Normal operations
- **Medium Risk** (61-120 days): Monitor closely
- **High Risk** (121-180 days): Consider promotions
- **Critical** (180+ days): Liquidate or write-off

### SQL View
`vw_kpi_inventory_aging`, `vw_kpi_inventory_aging_summary`, `vw_kpi_slow_moving_items`

---

## 3. Sales Margin Analysis

### Definition
Gross profit margin percentage across various dimensions.

### Formula
```
Gross Margin % = ((Revenue - Cost) / Revenue) × 100

Where:
- Revenue = Sales price × Quantity
- Cost = Unit cost × Quantity
- Gross Profit = Revenue - Cost
```

### Related Metrics
```
Markup % = ((Revenue - Cost) / Cost) × 100
Profit per Unit = (Revenue - Cost) / Quantity
```

### Business Impact
- **Profitability**: Direct impact on bottom line
- **Pricing Strategy**: Informs pricing decisions
- **Product Mix**: Identifies high/low margin products
- **Customer Profitability**: Shows which customers are most valuable

### Target Benchmarks (Industry Dependent)
- **High Margin**: ≥ 40%
- **Good Margin**: 25-39%
- **Fair Margin**: 15-24%
- **Low Margin**: 5-14%
- **Negative Margin**: < 5% (review immediately)

### Analysis Dimensions
- By Customer (customer profitability)
- By Item (product profitability)
- By Product Line (category performance)
- By Sales Person (rep effectiveness)
- By Time Period (trend analysis)

### SQL View
`vw_kpi_sales_margin_by_customer`, `vw_kpi_sales_margin_by_item`, `vw_kpi_low_margin_alert`

---

## 4. Forecast Accuracy

### Definition
Measures how accurately sales forecasts match actual performance.

### Formula (MAPE - Mean Absolute Percentage Error)
```
MAPE = (1/n) × Σ |Actual - Forecast| / Actual × 100
Forecast Accuracy % = 100 - MAPE

Where:
- n = number of forecast periods
- Actual = actual sales quantity/revenue
- Forecast = forecasted quantity/revenue
```

### Alternative Metrics
```
Bias = Average(Forecast - Actual)
  - Positive bias = Over-forecasting
  - Negative bias = Under-forecasting

Variance % = (Actual - Forecast) / Forecast × 100
```

### Business Impact
- **Inventory Planning**: Accurate forecasts prevent stockouts/overstock
- **Production Planning**: Enables efficient capacity utilization
- **Financial Planning**: Improves budget accuracy
- **Supply Chain**: Optimizes procurement

### Target Benchmarks
- **Excellent**: ≤ 10% MAPE (≥ 90% accuracy)
- **Good**: 11-20% MAPE (80-89% accuracy)
- **Fair**: 21-30% MAPE (70-79% accuracy)
- **Poor**: > 30% MAPE (< 70% accuracy)

### SQL View
`vw_kpi_forecast_accuracy_monthly`, `vw_kpi_forecast_accuracy_by_item`, `vw_kpi_forecast_bias`

---

## 5. Overall Equipment Effectiveness (OEE)

### Definition
Comprehensive measure of manufacturing productivity.

### Formula
```
OEE = Availability × Performance × Quality

Where:
Availability = (Operating Time / Planned Production Time) × 100
Performance = (Actual Output / Maximum Possible Output) × 100
Quality = (Good Units / Total Units Produced) × 100
```

### Component Definitions

**Availability**
- Planned Production Time: Scheduled production time
- Operating Time: Planned time - Downtime
- Downtime: Breakdowns, changeovers, maintenance

**Performance**
- Maximum Possible Output = Operating Time / Ideal Cycle Time
- Actual Output = Units produced
- Considers speed losses and minor stops

**Quality**
- Good Units = Total produced - Defects - Scrap
- Total Units = All units produced
- Measures first-pass yield

### Business Impact
- **Productivity**: Overall manufacturing efficiency
- **Capacity Planning**: Identifies bottlenecks
- **Cost Reduction**: Highlights improvement opportunities
- **Competitive Advantage**: World-class OEE enables lower costs

### Target Benchmarks
- **World Class**: ≥ 85%
- **Good**: 70-84%
- **Fair**: 60-69%
- **Poor**: < 60%

### Six Big Losses
1. **Availability Losses**:
   - Equipment failures (breakdowns)
   - Setup and adjustments

2. **Performance Losses**:
   - Idling and minor stops
   - Reduced speed

3. **Quality Losses**:
   - Process defects
   - Reduced yield

### SQL View
`vw_kpi_oee_by_order`, `vw_kpi_oee_by_production_line`, `vw_kpi_oee_trend_weekly`, `vw_kpi_oee_loss_analysis`

---

## KPI Dashboard Recommendations

### Executive Dashboard
- OTD % (current month vs. target)
- Sales Margin % (trend)
- Inventory Value by Age Bucket
- OEE % (manufacturing sites)

### Operations Dashboard
- Daily OTD performance
- Late deliveries by customer
- Production OEE by line
- Inventory aging alerts

### Sales Dashboard
- Sales margin by customer
- Sales margin by product
- Forecast vs. actual
- Customer profitability ranking

### Supply Chain Dashboard
- Inventory aging analysis
- Slow-moving items
- Forecast accuracy trend
- Stock availability

## Data Refresh Requirements

| KPI | Refresh Frequency | Latency Tolerance |
|-----|-------------------|-------------------|
| OTD | Daily | 24 hours |
| Inventory Aging | Daily | 24 hours |
| Sales Margin | Hourly | 2 hours |
| Forecast Accuracy | Weekly | 1 week |
| OEE | Hourly | 1 hour |

## Calculation Notes

1. **Currency**: All monetary KPIs use system currency (USD) for consistency
2. **Cancelled Documents**: Excluded from all calculations
3. **Returns**: Handled separately or excluded based on KPI
4. **Date Ranges**: Configurable via parameters
5. **Null Handling**: Records with missing required fields are excluded

## Additional Resources

- [KPI Best Practices](https://www.klipfolio.com/resources/kpi-examples)
- [Manufacturing Metrics](https://www.oee.com)
- [Supply Chain KPIs](https://www.apics.org)

