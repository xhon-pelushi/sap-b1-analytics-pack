-- =====================================================
-- KPI: On-Time Delivery (OTD)
-- Purpose: Track percentage of deliveries made on or before promised date
-- Formula: (On-Time Deliveries / Total Deliveries) × 100
-- Business Impact: Customer satisfaction, logistics efficiency
-- =====================================================

-- =====================================================
-- View: Daily OTD Summary
-- =====================================================
CREATE VIEW analytics.vw_kpi_otd_daily AS
WITH delivery_metrics AS (
    SELECT 
        d.delivery_date_key,
        dc.date_value as delivery_date,
        dc.year_number,
        dc.quarter_name,
        dc.month_name,
        dc.week_of_year,
        
        -- Total deliveries
        COUNT(*) as total_deliveries,
        SUM(d.quantity) as total_quantity_delivered,
        SUM(d.line_total_sys) as total_value_delivered,
        
        -- On-time deliveries
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) as on_time_deliveries,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN d.quantity ELSE 0 END) as on_time_quantity,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN d.line_total_sys ELSE 0 END) as on_time_value,
        
        -- Late deliveries
        SUM(CASE WHEN d.is_late_delivery = 1 THEN 1 ELSE 0 END) as late_deliveries,
        SUM(CASE WHEN d.is_late_delivery = 1 THEN d.quantity ELSE 0 END) as late_quantity,
        SUM(CASE WHEN d.is_late_delivery = 1 THEN d.line_total_sys ELSE 0 END) as late_value,
        
        -- Early deliveries
        SUM(CASE WHEN d.is_early_delivery = 1 THEN 1 ELSE 0 END) as early_deliveries,
        
        -- Average delay
        AVG(CAST(d.delivery_delay_days AS FLOAT)) as avg_delay_days,
        MAX(d.delivery_delay_days) as max_delay_days,
        MIN(d.delivery_delay_days) as min_delay_days
        
    FROM analytics.fact_delivery d
    INNER JOIN analytics.dim_calendar dc ON d.delivery_date_key = dc.date_key
    WHERE d.is_canceled = 0
      AND d.promised_delivery_date IS NOT NULL
    GROUP BY 
        d.delivery_date_key,
        dc.date_value,
        dc.year_number,
        dc.quarter_name,
        dc.month_name,
        dc.week_of_year
)
SELECT 
    delivery_date_key,
    delivery_date,
    year_number,
    quarter_name,
    month_name,
    week_of_year,
    
    -- Delivery counts
    total_deliveries,
    on_time_deliveries,
    late_deliveries,
    early_deliveries,
    
    -- Quantities
    total_quantity_delivered,
    on_time_quantity,
    late_quantity,
    
    -- Values
    total_value_delivered,
    on_time_value,
    late_value,
    
    -- KPI Calculations
    CASE 
        WHEN total_deliveries > 0 
        THEN CAST(on_time_deliveries AS FLOAT) / total_deliveries * 100 
        ELSE NULL 
    END as otd_percentage,
    
    CASE 
        WHEN total_quantity_delivered > 0 
        THEN CAST(on_time_quantity AS FLOAT) / total_quantity_delivered * 100 
        ELSE NULL 
    END as otd_percentage_by_qty,
    
    CASE 
        WHEN total_value_delivered > 0 
        THEN CAST(on_time_value AS FLOAT) / total_value_delivered * 100 
        ELSE NULL 
    END as otd_percentage_by_value,
    
    -- Delay metrics
    avg_delay_days,
    max_delay_days,
    min_delay_days
    
FROM delivery_metrics;

-- =====================================================
-- View: OTD by Customer
-- =====================================================
CREATE VIEW analytics.vw_kpi_otd_by_customer AS
WITH customer_metrics AS (
    SELECT 
        d.customer_key,
        c.card_code,
        c.card_name,
        c.customer_tier,
        c.customer_segment,
        c.region,
        
        COUNT(*) as total_deliveries,
        SUM(d.quantity) as total_quantity,
        SUM(d.line_total_sys) as total_value,
        
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) as on_time_deliveries,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN d.quantity ELSE 0 END) as on_time_quantity,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN d.line_total_sys ELSE 0 END) as on_time_value,
        
        AVG(CAST(d.delivery_delay_days AS FLOAT)) as avg_delay_days
        
    FROM analytics.fact_delivery d
    INNER JOIN analytics.dim_customer c ON d.customer_key = c.customer_key
    WHERE d.is_canceled = 0
      AND d.promised_delivery_date IS NOT NULL
      AND c.is_current = 1
    GROUP BY 
        d.customer_key,
        c.card_code,
        c.card_name,
        c.customer_tier,
        c.customer_segment,
        c.region
)
SELECT 
    customer_key,
    card_code,
    card_name,
    customer_tier,
    customer_segment,
    region,
    
    total_deliveries,
    on_time_deliveries,
    total_quantity,
    on_time_quantity,
    total_value,
    on_time_value,
    
    CASE 
        WHEN total_deliveries > 0 
        THEN CAST(on_time_deliveries AS FLOAT) / total_deliveries * 100 
        ELSE NULL 
    END as otd_percentage,
    
    avg_delay_days,
    
    -- Performance rating
    CASE 
        WHEN CAST(on_time_deliveries AS FLOAT) / NULLIF(total_deliveries, 0) * 100 >= 95 THEN 'Excellent'
        WHEN CAST(on_time_deliveries AS FLOAT) / NULLIF(total_deliveries, 0) * 100 >= 90 THEN 'Good'
        WHEN CAST(on_time_deliveries AS FLOAT) / NULLIF(total_deliveries, 0) * 100 >= 80 THEN 'Fair'
        ELSE 'Poor'
    END as performance_rating
    
FROM customer_metrics
WHERE total_deliveries >= 5; -- Minimum deliveries for meaningful metric

-- =====================================================
-- View: OTD by Item
-- =====================================================
CREATE VIEW analytics.vw_kpi_otd_by_item AS
WITH item_metrics AS (
    SELECT 
        d.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        i.product_line,
        i.abc_class,
        
        COUNT(*) as total_deliveries,
        SUM(d.quantity) as total_quantity,
        SUM(d.line_total_sys) as total_value,
        
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) as on_time_deliveries,
        
        AVG(CAST(d.delivery_delay_days AS FLOAT)) as avg_delay_days,
        AVG(CAST(d.days_order_to_delivery AS FLOAT)) as avg_lead_time_days
        
    FROM analytics.fact_delivery d
    INNER JOIN analytics.dim_item i ON d.item_key = i.item_key
    WHERE d.is_canceled = 0
      AND d.promised_delivery_date IS NOT NULL
      AND i.is_current = 1
    GROUP BY 
        d.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        i.product_line,
        i.abc_class
)
SELECT 
    item_key,
    item_code,
    item_name,
    item_category,
    product_line,
    abc_class,
    
    total_deliveries,
    on_time_deliveries,
    total_quantity,
    total_value,
    
    CASE 
        WHEN total_deliveries > 0 
        THEN CAST(on_time_deliveries AS FLOAT) / total_deliveries * 100 
        ELSE NULL 
    END as otd_percentage,
    
    avg_delay_days,
    avg_lead_time_days
    
FROM item_metrics
WHERE total_deliveries >= 3; -- Minimum deliveries for meaningful metric

-- =====================================================
-- View: OTD Trend (Last 12 Months)
-- =====================================================
CREATE VIEW analytics.vw_kpi_otd_trend_12m AS
WITH monthly_metrics AS (
    SELECT 
        dc.year_number,
        dc.month_number,
        dc.month_name,
        dc.month_year,
        
        COUNT(*) as total_deliveries,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) as on_time_deliveries,
        
        CASE 
            WHEN COUNT(*) > 0 
            THEN CAST(SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 
            ELSE NULL 
        END as otd_percentage,
        
        AVG(CAST(d.delivery_delay_days AS FLOAT)) as avg_delay_days
        
    FROM analytics.fact_delivery d
    INNER JOIN analytics.dim_calendar dc ON d.delivery_date_key = dc.date_key
    WHERE d.is_canceled = 0
      AND d.promised_delivery_date IS NOT NULL
      AND dc.date_value >= DATEADD(MONTH, -12, CAST(GETDATE() AS DATE))
    GROUP BY 
        dc.year_number,
        dc.month_number,
        dc.month_name,
        dc.month_year
)
SELECT 
    *,
    -- Target line (can be configured)
    95.0 as target_otd_percentage,
    
    -- Variance from target
    otd_percentage - 95.0 as variance_from_target,
    
    -- Month over month change
    otd_percentage - LAG(otd_percentage) OVER (ORDER BY year_number, month_number) as mom_change
    
FROM monthly_metrics
ORDER BY year_number, month_number;

-- =====================================================
-- Stored Procedure: Calculate OTD for Date Range
-- =====================================================
CREATE PROCEDURE analytics.sp_calculate_otd
    @StartDate DATE,
    @EndDate DATE,
    @CustomerCode NVARCHAR(50) = NULL,
    @ItemCode NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(*) as total_deliveries,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) as on_time_deliveries,
        SUM(CASE WHEN d.is_late_delivery = 1 THEN 1 ELSE 0 END) as late_deliveries,
        
        CASE 
            WHEN COUNT(*) > 0 
            THEN CAST(SUM(CASE WHEN d.is_on_time_delivery = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 
            ELSE 0 
        END as otd_percentage,
        
        AVG(CAST(d.delivery_delay_days AS FLOAT)) as avg_delay_days,
        MAX(d.delivery_delay_days) as max_delay_days,
        
        SUM(d.line_total_sys) as total_value,
        SUM(CASE WHEN d.is_on_time_delivery = 1 THEN d.line_total_sys ELSE 0 END) as on_time_value
        
    FROM analytics.fact_delivery d
    INNER JOIN analytics.dim_calendar dc ON d.delivery_date_key = dc.date_key
    INNER JOIN analytics.dim_customer c ON d.customer_key = c.customer_key
    INNER JOIN analytics.dim_item i ON d.item_key = i.item_key
    WHERE d.is_canceled = 0
      AND d.promised_delivery_date IS NOT NULL
      AND dc.date_value BETWEEN @StartDate AND @EndDate
      AND (@CustomerCode IS NULL OR c.card_code = @CustomerCode)
      AND (@ItemCode IS NULL OR i.item_code = @ItemCode)
      AND c.is_current = 1
      AND i.is_current = 1;
END;
GO

-- Sample usage:
-- EXEC analytics.sp_calculate_otd @StartDate = '2025-11-01', @EndDate = '2025-11-30';
-- EXEC analytics.sp_calculate_otd @StartDate = '2025-11-01', @EndDate = '2025-11-30', @CustomerCode = 'CUST-001';


# Updated: 2025-11-12 10:24:00

# Updated: 2025-11-15 12:44:00

# Updated: 2025-11-15 18:00:00

# Updated: 2025-11-16 16:35:00

# Updated: 2025-11-17 08:31:00

# Updated: 2025-11-17 10:31:00

# Updated: 2025-11-19 12:16:00

# Updated: 2025-11-20 16:06:00

# Updated: 2025-11-21 14:23:00

# Updated: 2025-11-22 16:28:00

# Updated: 2025-11-23 08:58:00

# Updated: 2025-11-23 10:47:00

# Updated: 2025-11-23 16:54:00

# Updated: 2025-11-25 16:10:00

# Updated: 2025-11-26 22:57:00

# Updated: 2025-11-27 10:38:00

# Updated: 2025-11-27 20:23:00

# Updated: 2025-11-29 08:53:00

# Updated: 2025-11-30 10:23:00

# Updated: 2025-11-30 12:35:00

# Updated: 2025-11-30 14:54:00

# Updated: 2025-12-01 14:47:00

# Updated: 2025-12-04 16:15:00

# Updated: 2025-12-06 14:39:00

# Updated: 2025-12-06 20:55:00

# Updated: 2025-12-08 10:14:00

# Updated: 2025-12-08 18:55:00

# Updated: 2025-12-09 08:20:00

# Updated: 2025-12-10 10:04:00

# Updated: 2025-12-12 20:55:00

# Updated: 2025-12-16 10:21:00

# Updated: 2025-12-16 14:01:00

# Updated: 2025-12-16 16:34:00

# Updated: 2025-12-18 10:07:00
