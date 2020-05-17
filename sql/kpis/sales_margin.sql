-- =====================================================
-- KPI: Sales Margin Analysis
-- Purpose: Calculate gross profit margins by various dimensions
-- Formula: ((Revenue - Cost) / Revenue) × 100
-- Business Impact: Profitability optimization, pricing strategy
-- =====================================================

-- =====================================================
-- View: Sales Margin by Customer
-- =====================================================
CREATE VIEW analytics.vw_kpi_sales_margin_by_customer AS
WITH customer_margins AS (
    SELECT 
        f.customer_key,
        c.card_code,
        c.card_name,
        c.customer_tier,
        c.customer_segment,
        c.region,
        
        -- Sales metrics
        COUNT(DISTINCT f.invoice_doc_entry) as invoice_count,
        COUNT(*) as line_item_count,
        SUM(f.quantity) as total_quantity,
        
        -- Revenue
        SUM(f.line_total_sys) as total_revenue,
        
        -- Cost
        SUM(f.total_cost_sys) as total_cost,
        
        -- Profit
        SUM(f.gross_profit_sys) as total_gross_profit,
        
        -- Average metrics
        AVG(f.unit_price) as avg_unit_price,
        AVG(f.discount_percent) as avg_discount_percent,
        AVG(f.gross_margin_percent) as avg_gross_margin_percent
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_customer c ON f.customer_key = c.customer_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND c.is_current = 1
    GROUP BY 
        f.customer_key,
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
    
    invoice_count,
    line_item_count,
    total_quantity,
    
    total_revenue,
    total_cost,
    total_gross_profit,
    
    -- Margin percentage
    CASE 
        WHEN total_revenue > 0 
        THEN (total_gross_profit / total_revenue) * 100 
        ELSE NULL 
    END as gross_margin_percent,
    
    -- Average revenue per invoice
    total_revenue / NULLIF(invoice_count, 0) as avg_revenue_per_invoice,
    
    avg_unit_price,
    avg_discount_percent,
    avg_gross_margin_percent,
    
    -- Margin classification
    CASE 
        WHEN (total_gross_profit / NULLIF(total_revenue, 0)) * 100 >= 40 THEN 'High Margin'
        WHEN (total_gross_profit / NULLIF(total_revenue, 0)) * 100 >= 25 THEN 'Good Margin'
        WHEN (total_gross_profit / NULLIF(total_revenue, 0)) * 100 >= 15 THEN 'Fair Margin'
        WHEN (total_gross_profit / NULLIF(total_revenue, 0)) * 100 >= 5 THEN 'Low Margin'
        ELSE 'Negative Margin'
    END as margin_category
    
FROM customer_margins
WHERE invoice_count >= 3; -- Minimum invoices for meaningful analysis

-- =====================================================
-- View: Sales Margin by Item
-- =====================================================
CREATE VIEW analytics.vw_kpi_sales_margin_by_item AS
WITH item_margins AS (
    SELECT 
        f.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        i.item_subcategory,
        i.product_line,
        i.abc_class,
        i.price_tier,
        
        -- Sales metrics
        COUNT(DISTINCT f.invoice_doc_entry) as invoice_count,
        COUNT(*) as line_item_count,
        SUM(f.quantity) as total_quantity_sold,
        
        -- Revenue
        SUM(f.line_total_sys) as total_revenue,
        
        -- Cost
        SUM(f.total_cost_sys) as total_cost,
        
        -- Profit
        SUM(f.gross_profit_sys) as total_gross_profit,
        
        -- Average metrics
        AVG(f.unit_price) as avg_selling_price,
        AVG(f.unit_cost) as avg_unit_cost,
        AVG(f.discount_percent) as avg_discount_percent
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND i.is_current = 1
    GROUP BY 
        f.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        i.item_subcategory,
        i.product_line,
        i.abc_class,
        i.price_tier
)
SELECT 
    item_key,
    item_code,
    item_name,
    item_category,
    item_subcategory,
    product_line,
    abc_class,
    price_tier,
    
    invoice_count,
    line_item_count,
    total_quantity_sold,
    
    total_revenue,
    total_cost,
    total_gross_profit,
    
    -- Margin percentage
    CASE 
        WHEN total_revenue > 0 
        THEN (total_gross_profit / total_revenue) * 100 
        ELSE NULL 
    END as gross_margin_percent,
    
    -- Unit economics
    total_revenue / NULLIF(total_quantity_sold, 0) as revenue_per_unit,
    total_cost / NULLIF(total_quantity_sold, 0) as cost_per_unit,
    total_gross_profit / NULLIF(total_quantity_sold, 0) as profit_per_unit,
    
    avg_selling_price,
    avg_unit_cost,
    avg_discount_percent,
    
    -- Markup percentage
    CASE 
        WHEN total_cost > 0 
        THEN ((total_revenue - total_cost) / total_cost) * 100 
        ELSE NULL 
    END as markup_percent
    
FROM item_margins
WHERE line_item_count >= 5; -- Minimum lines for meaningful analysis

-- =====================================================
-- View: Sales Margin Trend by Month
-- =====================================================
CREATE VIEW analytics.vw_kpi_sales_margin_trend AS
WITH monthly_margins AS (
    SELECT 
        dc.year_number,
        dc.month_number,
        dc.month_name,
        dc.month_year,
        
        COUNT(DISTINCT f.invoice_doc_entry) as invoice_count,
        SUM(f.quantity) as total_quantity,
        
        SUM(f.line_total_sys) as total_revenue,
        SUM(f.total_cost_sys) as total_cost,
        SUM(f.gross_profit_sys) as total_gross_profit,
        
        AVG(f.gross_margin_percent) as avg_margin_percent,
        AVG(f.discount_percent) as avg_discount_percent
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
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
    
    invoice_count,
    total_quantity,
    total_revenue,
    total_cost,
    total_gross_profit,
    
    -- Calculated margin
    CASE 
        WHEN total_revenue > 0 
        THEN (total_gross_profit / total_revenue) * 100 
        ELSE NULL 
    END as gross_margin_percent,
    
    avg_margin_percent,
    avg_discount_percent,
    
    -- Month over month comparison
    total_revenue - LAG(total_revenue) OVER (ORDER BY year_number, month_number) as mom_revenue_change,
    (total_gross_profit / NULLIF(total_revenue, 0)) * 100 - 
        LAG((total_gross_profit / NULLIF(total_revenue, 0)) * 100) OVER (ORDER BY year_number, month_number) as mom_margin_change,
    
    -- Target comparison (example: 30% target margin)
    30.0 as target_margin_percent,
    (total_gross_profit / NULLIF(total_revenue, 0)) * 100 - 30.0 as variance_from_target
    
FROM monthly_margins
ORDER BY year_number, month_number;

-- =====================================================
-- View: Sales Margin by Product Line and Customer Tier
-- =====================================================
CREATE VIEW analytics.vw_kpi_sales_margin_matrix AS
SELECT 
    i.product_line,
    c.customer_tier,
    
    COUNT(DISTINCT f.invoice_doc_entry) as invoice_count,
    COUNT(DISTINCT f.customer_key) as customer_count,
    SUM(f.quantity) as total_quantity,
    
    SUM(f.line_total_sys) as total_revenue,
    SUM(f.total_cost_sys) as total_cost,
    SUM(f.gross_profit_sys) as total_gross_profit,
    
    CASE 
        WHEN SUM(f.line_total_sys) > 0 
        THEN (SUM(f.gross_profit_sys) / SUM(f.line_total_sys)) * 100 
        ELSE NULL 
    END as gross_margin_percent,
    
    AVG(f.discount_percent) as avg_discount_percent
    
FROM analytics.fact_sales f
INNER JOIN analytics.dim_customer c ON f.customer_key = c.customer_key
INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
WHERE f.is_canceled = 0
  AND f.is_return = 0
  AND c.is_current = 1
  AND i.is_current = 1
GROUP BY 
    i.product_line,
    c.customer_tier;

-- =====================================================
-- View: Low Margin Alert
-- =====================================================
CREATE VIEW analytics.vw_kpi_low_margin_alert AS
WITH recent_sales AS (
    SELECT 
        f.sales_fact_key,
        f.invoice_doc_num,
        f.invoice_line_num,
        
        dc.date_value as invoice_date,
        c.card_code,
        c.card_name,
        i.item_code,
        i.item_name,
        i.item_category,
        
        f.quantity,
        f.unit_price,
        f.unit_cost,
        f.line_total_sys as revenue,
        f.total_cost_sys as cost,
        f.gross_profit_sys as profit,
        f.gross_margin_percent,
        f.discount_percent
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_customer c ON f.customer_key = c.customer_key
    INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND c.is_current = 1
      AND i.is_current = 1
      AND dc.date_value >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
      AND f.gross_margin_percent < 10 -- Low margin threshold
)
SELECT 
    *,
    -- Alert severity
    CASE 
        WHEN gross_margin_percent < 0 THEN 'Critical - Negative Margin'
        WHEN gross_margin_percent < 5 THEN 'High - Very Low Margin'
        WHEN gross_margin_percent < 10 THEN 'Medium - Low Margin'
        ELSE 'Low'
    END as alert_severity,
    
    -- Recommended action
    CASE 
        WHEN gross_margin_percent < 0 THEN 'Immediate review: Selling below cost'
        WHEN discount_percent > 20 THEN 'Review discount policy'
        WHEN gross_margin_percent < 5 THEN 'Consider price increase or cost reduction'
        ELSE 'Monitor closely'
    END as recommended_action
    
FROM recent_sales
ORDER BY gross_margin_percent ASC, revenue DESC;

-- =====================================================
-- Stored Procedure: Sales Margin Report
-- =====================================================
CREATE PROCEDURE analytics.sp_sales_margin_report
    @StartDate DATE,
    @EndDate DATE,
    @CustomerCode NVARCHAR(50) = NULL,
    @ItemCode NVARCHAR(50) = NULL,
    @MinMarginPercent DECIMAL(19,6) = NULL,
    @MaxMarginPercent DECIMAL(19,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dc.date_value as invoice_date,
        c.card_code,
        c.card_name,
        c.customer_tier,
        i.item_code,
        i.item_name,
        i.item_category,
        
        f.invoice_doc_num,
        f.quantity,
        f.unit_price,
        f.unit_cost,
        f.discount_percent,
        
        f.line_total_sys as revenue,
        f.total_cost_sys as cost,
        f.gross_profit_sys as profit,
        f.gross_margin_percent,
        
        -- Markup
        CASE 
            WHEN f.total_cost_sys > 0 
            THEN ((f.line_total_sys - f.total_cost_sys) / f.total_cost_sys) * 100 
            ELSE NULL 
        END as markup_percent
        
    FROM analytics.fact_sales f
    INNER JOIN analytics.dim_customer c ON f.customer_key = c.customer_key
    INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
    INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
    WHERE f.is_canceled = 0
      AND f.is_return = 0
      AND c.is_current = 1
      AND i.is_current = 1
      AND dc.date_value BETWEEN @StartDate AND @EndDate
      AND (@CustomerCode IS NULL OR c.card_code = @CustomerCode)
      AND (@ItemCode IS NULL OR i.item_code = @ItemCode)
      AND (@MinMarginPercent IS NULL OR f.gross_margin_percent >= @MinMarginPercent)
      AND (@MaxMarginPercent IS NULL OR f.gross_margin_percent <= @MaxMarginPercent)
    ORDER BY 
        dc.date_value DESC,
        f.gross_margin_percent ASC;
END;
GO

-- Sample usage:
-- EXEC analytics.sp_sales_margin_report @StartDate = '2025-11-01', @EndDate = '2025-11-30';
-- EXEC analytics.sp_sales_margin_report @StartDate = '2025-11-01', @EndDate = '2025-11-30', @MinMarginPercent = 0, @MaxMarginPercent = 15;

