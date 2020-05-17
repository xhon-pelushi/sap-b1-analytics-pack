-- =====================================================
-- KPI: Forecast Accuracy
-- Purpose: Measure how accurately sales forecasts match actual performance
-- Formula: 100 - (|Actual - Forecast| / Actual) × 100
-- Alternative: MAPE (Mean Absolute Percentage Error)
-- Business Impact: Demand planning, inventory optimization
-- =====================================================

-- Note: This requires a forecast table. For demonstration, we'll create a sample structure
-- In production, this would integrate with your forecasting system

-- =====================================================
-- Sample Forecast Table Structure
-- =====================================================
-- CREATE TABLE analytics.fact_forecast (
--     forecast_key BIGINT IDENTITY(1,1) PRIMARY KEY,
--     item_key INT NOT NULL,
--     customer_key INT,
--     forecast_date_key INT NOT NULL,
--     forecast_period NVARCHAR(20), -- Month, Quarter, Year
--     forecast_quantity DECIMAL(19,6),
--     forecast_revenue DECIMAL(19,6),
--     forecast_version NVARCHAR(50),
--     forecast_created_date DATETIME,
--     forecast_created_by NVARCHAR(50)
-- );

-- =====================================================
-- View: Monthly Forecast vs Actual
-- =====================================================
CREATE VIEW analytics.vw_kpi_forecast_accuracy_monthly AS
WITH actual_sales AS (
    SELECT 
        f.item_key,
        dc.year_number,
        dc.month_number,
        dc.month_year,
        
        SUM(f.quantity) as actual_quantity,
        SUM(f.line_total_sys) as actual_revenue
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
    GROUP BY 
        f.item_key,
        dc.year_number,
        dc.month_number,
        dc.month_year
),
forecast_sales AS (
    -- This would come from your forecast table
    -- For demo purposes, we'll simulate using prior month actuals + variance
    SELECT 
        f.item_key,
        dc.year_number,
        dc.month_number,
        dc.month_year,
        
        -- Simulated forecast (in production, use actual forecast table)
        SUM(f.quantity) * 1.1 as forecast_quantity, -- Example: 10% growth assumption
        SUM(f.line_total_sys) * 1.1 as forecast_revenue
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
    GROUP BY 
        f.item_key,
        dc.year_number,
        dc.month_number,
        dc.month_year
)
SELECT 
    a.item_key,
    i.item_code,
    i.item_name,
    i.item_category,
    i.product_line,
    
    a.year_number,
    a.month_number,
    a.month_year,
    
    -- Actual values
    a.actual_quantity,
    a.actual_revenue,
    
    -- Forecast values
    f.forecast_quantity,
    f.forecast_revenue,
    
    -- Variance (Actual - Forecast)
    a.actual_quantity - f.forecast_quantity as quantity_variance,
    a.actual_revenue - f.forecast_revenue as revenue_variance,
    
    -- Variance percentage
    CASE 
        WHEN f.forecast_quantity > 0 
        THEN ((a.actual_quantity - f.forecast_quantity) / f.forecast_quantity) * 100 
        ELSE NULL 
    END as quantity_variance_percent,
    
    CASE 
        WHEN f.forecast_revenue > 0 
        THEN ((a.actual_revenue - f.forecast_revenue) / f.forecast_revenue) * 100 
        ELSE NULL 
    END as revenue_variance_percent,
    
    -- Absolute percentage error (for MAPE calculation)
    ABS(
        CASE 
            WHEN a.actual_quantity > 0 
            THEN ((f.forecast_quantity - a.actual_quantity) / a.actual_quantity) * 100 
            ELSE NULL 
        END
    ) as absolute_percent_error_qty,
    
    ABS(
        CASE 
            WHEN a.actual_revenue > 0 
            THEN ((f.forecast_revenue - a.actual_revenue) / a.actual_revenue) * 100 
            ELSE NULL 
        END
    ) as absolute_percent_error_revenue,
    
    -- Forecast accuracy (100 - APE)
    100 - ABS(
        CASE 
            WHEN a.actual_quantity > 0 
            THEN ((f.forecast_quantity - a.actual_quantity) / a.actual_quantity) * 100 
            ELSE 0 
        END
    ) as forecast_accuracy_qty_percent,
    
    100 - ABS(
        CASE 
            WHEN a.actual_revenue > 0 
            THEN ((f.forecast_revenue - a.actual_revenue) / a.actual_revenue) * 100 
            ELSE 0 
        END
    ) as forecast_accuracy_revenue_percent,
    
    -- Bias indicator
    CASE 
        WHEN a.actual_quantity > f.forecast_quantity THEN 'Under-Forecast'
        WHEN a.actual_quantity < f.forecast_quantity THEN 'Over-Forecast'
        ELSE 'On-Target'
    END as forecast_bias
    
FROM actual_sales a
INNER JOIN forecast_sales f ON a.item_key = f.item_key 
    AND a.year_number = f.year_number 
    AND a.month_number = f.month_number
INNER JOIN analytics.dim_item i ON a.item_key = i.item_key
WHERE i.is_current = 1;

-- =====================================================
-- View: Forecast Accuracy Summary by Item
-- =====================================================
CREATE VIEW analytics.vw_kpi_forecast_accuracy_by_item AS
WITH forecast_comparison AS (
    SELECT 
        f.item_key,
        dc.year_number,
        dc.month_number,
        
        SUM(f.quantity) as actual_quantity,
        SUM(f.quantity) * 1.1 as forecast_quantity, -- Simulated forecast
        
        -- Calculate APE for each month
        ABS(
            CASE 
                WHEN SUM(f.quantity) > 0 
                THEN ((SUM(f.quantity) * 1.1 - SUM(f.quantity)) / SUM(f.quantity)) * 100 
                ELSE NULL 
            END
        ) as absolute_percent_error
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND dc.date_value >= DATEADD(MONTH, -12, CAST(GETDATE() AS DATE))
    GROUP BY 
        f.item_key,
        dc.year_number,
        dc.month_number
)
SELECT 
    fc.item_key,
    i.item_code,
    i.item_name,
    i.item_category,
    i.product_line,
    i.abc_class,
    
    -- Number of forecast periods
    COUNT(*) as forecast_period_count,
    
    -- Total actuals and forecasts
    SUM(fc.actual_quantity) as total_actual_quantity,
    SUM(fc.forecast_quantity) as total_forecast_quantity,
    
    -- MAPE (Mean Absolute Percentage Error)
    AVG(fc.absolute_percent_error) as mape,
    
    -- Forecast accuracy percentage (100 - MAPE)
    100 - AVG(fc.absolute_percent_error) as forecast_accuracy_percent,
    
    -- Standard deviation of errors (forecast consistency)
    STDEV(fc.absolute_percent_error) as forecast_error_std_dev,
    
    -- Min and max errors
    MIN(fc.absolute_percent_error) as min_error,
    MAX(fc.absolute_percent_error) as max_error,
    
    -- Bias
    AVG(fc.forecast_quantity - fc.actual_quantity) as avg_bias_quantity,
    
    -- Performance rating
    CASE 
        WHEN AVG(fc.absolute_percent_error) <= 10 THEN 'Excellent'
        WHEN AVG(fc.absolute_percent_error) <= 20 THEN 'Good'
        WHEN AVG(fc.absolute_percent_error) <= 30 THEN 'Fair'
        ELSE 'Poor'
    END as accuracy_rating
    
FROM forecast_comparison fc
INNER JOIN analytics.dim_item i ON fc.item_key = i.item_key
WHERE i.is_current = 1
GROUP BY 
    fc.item_key,
    i.item_code,
    i.item_name,
    i.item_category,
    i.product_line,
    i.abc_class
HAVING COUNT(*) >= 3; -- Minimum periods for meaningful analysis

-- =====================================================
-- View: Forecast Accuracy Trend
-- =====================================================
CREATE VIEW analytics.vw_kpi_forecast_accuracy_trend AS
WITH monthly_accuracy AS (
    SELECT 
        dc.year_number,
        dc.month_number,
        dc.month_name,
        dc.month_year,
        
        -- Total actuals
        SUM(f.quantity) as total_actual_quantity,
        SUM(f.line_total_sys) as total_actual_revenue,
        
        -- Simulated forecasts
        SUM(f.quantity) * 1.1 as total_forecast_quantity,
        SUM(f.line_total_sys) * 1.1 as total_forecast_revenue,
        
        -- Calculate MAPE components
        SUM(ABS(f.quantity - (f.quantity * 1.1))) / NULLIF(SUM(f.quantity), 0) * 100 as mape_quantity
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND dc.date_value >= DATEADD(MONTH, -24, CAST(GETDATE() AS DATE))
    GROUP BY 
        dc.year_number,
        dc.month_number,
        dc.month_name,
        dc.month_year
)
SELECT 
    year_number,
    month_number,
    month_name,
    month_year,
    
    total_actual_quantity,
    total_forecast_quantity,
    total_actual_revenue,
    total_forecast_revenue,
    
    -- Forecast accuracy
    100 - mape_quantity as forecast_accuracy_percent,
    mape_quantity,
    
    -- Variance
    total_actual_quantity - total_forecast_quantity as quantity_variance,
    total_actual_revenue - total_forecast_revenue as revenue_variance,
    
    -- Target accuracy (example: 85%)
    85.0 as target_accuracy_percent,
    (100 - mape_quantity) - 85.0 as variance_from_target,
    
    -- Trend
    (100 - mape_quantity) - LAG(100 - mape_quantity) OVER (ORDER BY year_number, month_number) as mom_accuracy_change
    
FROM monthly_accuracy
ORDER BY year_number, month_number;

-- =====================================================
-- View: Forecast Bias Analysis
-- =====================================================
CREATE VIEW analytics.vw_kpi_forecast_bias AS
WITH bias_analysis AS (
    SELECT 
        f.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        
        dc.year_number,
        dc.month_number,
        
        SUM(f.quantity) as actual_quantity,
        SUM(f.quantity) * 1.1 as forecast_quantity,
        
        -- Bias calculation (positive = over-forecast, negative = under-forecast)
        SUM(f.quantity) * 1.1 - SUM(f.quantity) as bias_quantity,
        
        CASE 
            WHEN SUM(f.quantity) > 0 
            THEN ((SUM(f.quantity) * 1.1 - SUM(f.quantity)) / SUM(f.quantity)) * 100 
            ELSE NULL 
        END as bias_percent
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND i.is_current = 1
      AND dc.date_value >= DATEADD(MONTH, -12, CAST(GETDATE() AS DATE))
    GROUP BY 
        f.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        dc.year_number,
        dc.month_number
)
SELECT 
    item_key,
    item_code,
    item_name,
    item_category,
    
    COUNT(*) as period_count,
    
    -- Average bias
    AVG(bias_quantity) as avg_bias_quantity,
    AVG(bias_percent) as avg_bias_percent,
    
    -- Bias consistency
    STDEV(bias_percent) as bias_std_dev,
    
    -- Over-forecast vs under-forecast count
    SUM(CASE WHEN bias_quantity > 0 THEN 1 ELSE 0 END) as over_forecast_count,
    SUM(CASE WHEN bias_quantity < 0 THEN 1 ELSE 0 END) as under_forecast_count,
    
    -- Bias classification
    CASE 
        WHEN AVG(bias_percent) > 10 THEN 'Consistent Over-Forecast'
        WHEN AVG(bias_percent) < -10 THEN 'Consistent Under-Forecast'
        WHEN STDEV(bias_percent) > 20 THEN 'Inconsistent/Volatile'
        ELSE 'Balanced'
    END as bias_classification
    
FROM bias_analysis
GROUP BY 
    item_key,
    item_code,
    item_name,
    item_category
HAVING COUNT(*) >= 3;

-- =====================================================
-- Stored Procedure: Forecast Accuracy Report
-- =====================================================
CREATE PROCEDURE analytics.sp_forecast_accuracy_report
    @StartDate DATE,
    @EndDate DATE,
    @ItemCode NVARCHAR(50) = NULL,
    @ItemCategory NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH forecast_data AS (
        SELECT 
            dc.date_value,
            dc.month_year,
            i.item_code,
            i.item_name,
            i.item_category,
            
            SUM(f.quantity) as actual_quantity,
            SUM(f.quantity) * 1.1 as forecast_quantity, -- Simulated
            
            ABS(
                CASE 
                    WHEN SUM(f.quantity) > 0 
                    THEN ((SUM(f.quantity) * 1.1 - SUM(f.quantity)) / SUM(f.quantity)) * 100 
                    ELSE NULL 
                END
            ) as absolute_percent_error
            
        FROM analytics.fact_sales f
        INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
        INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
        WHERE f.is_canceled = 0
          AND f.is_return = 0
          AND i.is_current = 1
          AND dc.date_value BETWEEN @StartDate AND @EndDate
          AND (@ItemCode IS NULL OR i.item_code = @ItemCode)
          AND (@ItemCategory IS NULL OR i.item_category = @ItemCategory)
        GROUP BY 
            dc.date_value,
            dc.month_year,
            i.item_code,
            i.item_name,
            i.item_category
    )
    SELECT 
        date_value,
        month_year,
        item_code,
        item_name,
        item_category,
        
        actual_quantity,
        forecast_quantity,
        forecast_quantity - actual_quantity as variance,
        
        CASE 
            WHEN forecast_quantity > 0 
            THEN ((forecast_quantity - actual_quantity) / forecast_quantity) * 100 
            ELSE NULL 
        END as variance_percent,
        
        absolute_percent_error as mape,
        100 - absolute_percent_error as accuracy_percent,
        
        CASE 
            WHEN actual_quantity > forecast_quantity THEN 'Under-Forecast'
            WHEN actual_quantity < forecast_quantity THEN 'Over-Forecast'
            ELSE 'On-Target'
        END as bias
        
    FROM forecast_data
    ORDER BY absolute_percent_error DESC;
END;
GO

-- Sample usage:
-- EXEC analytics.sp_forecast_accuracy_report @StartDate = '2025-01-01', @EndDate = '2025-11-30';
-- EXEC analytics.sp_forecast_accuracy_report @StartDate = '2025-01-01', @EndDate = '2025-11-30', @ItemCategory = 'Electronics';

