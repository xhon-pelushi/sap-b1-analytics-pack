-- =====================================================
-- KPI: Inventory Aging
-- Purpose: Analyze how long inventory items have been in stock
-- Buckets: 0-30, 31-60, 61-90, 91-180, 180+ days
-- Business Impact: Working capital optimization, obsolescence risk
-- =====================================================

-- =====================================================
-- View: Current Inventory Aging Summary
-- =====================================================
CREATE VIEW analytics.vw_kpi_inventory_aging AS
WITH inventory_age AS (
    SELECT 
        i.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        i.item_subcategory,
        i.product_line,
        i.abc_class,
        
        -- Current inventory
        itw.OnHand as current_stock,
        itw.IsCommited as committed_stock,
        itw.OnHand - itw.IsCommited as available_stock,
        
        -- Valuation
        i.avg_price,
        itw.OnHand * i.avg_price as inventory_value,
        (itw.OnHand - itw.IsCommited) * i.avg_price as available_value,
        
        -- Last transaction dates (would come from stock transactions)
        -- For this example, we'll use item update date as proxy
        i.updated_date as last_transaction_date,
        DATEDIFF(DAY, i.updated_date, GETDATE()) as days_in_stock,
        
        -- Age bucket classification
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 30 THEN '0-30 days'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 60 THEN '31-60 days'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 90 THEN '61-90 days'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 180 THEN '91-180 days'
            ELSE '180+ days'
        END as age_bucket,
        
        -- Risk classification
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 60 THEN 'Low'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 120 THEN 'Medium'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 180 THEN 'High'
            ELSE 'Critical'
        END as obsolescence_risk,
        
        -- Turnover metrics (would require sales data)
        itw.WhsCode as warehouse_code
        
    FROM analytics.dim_item i
    INNER JOIN OITW itw ON i.item_code = itw.ItemCode
    WHERE i.is_current = 1
      AND i.inventory_item = 1
      AND itw.OnHand > 0
)
SELECT 
    item_key,
    item_code,
    item_name,
    item_category,
    item_subcategory,
    product_line,
    abc_class,
    warehouse_code,
    
    current_stock,
    committed_stock,
    available_stock,
    
    avg_price,
    inventory_value,
    available_value,
    
    last_transaction_date,
    days_in_stock,
    age_bucket,
    obsolescence_risk
    
FROM inventory_age;

-- =====================================================
-- View: Inventory Aging Summary by Age Bucket
-- =====================================================
CREATE VIEW analytics.vw_kpi_inventory_aging_summary AS
WITH aging_data AS (
    SELECT 
        i.item_code,
        i.item_name,
        i.item_category,
        i.abc_class,
        i.avg_price,
        itw.OnHand,
        itw.OnHand * i.avg_price as inventory_value,
        DATEDIFF(DAY, i.updated_date, GETDATE()) as days_in_stock,
        
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 30 THEN 1 ELSE 0 
        END as bucket_0_30,
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) BETWEEN 31 AND 60 THEN 1 ELSE 0 
        END as bucket_31_60,
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) BETWEEN 61 AND 90 THEN 1 ELSE 0 
        END as bucket_61_90,
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) BETWEEN 91 AND 180 THEN 1 ELSE 0 
        END as bucket_91_180,
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) > 180 THEN 1 ELSE 0 
        END as bucket_180_plus
        
    FROM analytics.dim_item i
    INNER JOIN OITW itw ON i.item_code = itw.ItemCode
    WHERE i.is_current = 1
      AND i.inventory_item = 1
      AND itw.OnHand > 0
)
SELECT 
    -- Total metrics
    COUNT(*) as total_sku_count,
    SUM(OnHand) as total_quantity,
    SUM(inventory_value) as total_value,
    
    -- 0-30 days
    SUM(bucket_0_30) as sku_count_0_30,
    SUM(CASE WHEN bucket_0_30 = 1 THEN OnHand ELSE 0 END) as qty_0_30,
    SUM(CASE WHEN bucket_0_30 = 1 THEN inventory_value ELSE 0 END) as value_0_30,
    CASE 
        WHEN SUM(inventory_value) > 0 
        THEN SUM(CASE WHEN bucket_0_30 = 1 THEN inventory_value ELSE 0 END) / SUM(inventory_value) * 100 
        ELSE 0 
    END as pct_value_0_30,
    
    -- 31-60 days
    SUM(bucket_31_60) as sku_count_31_60,
    SUM(CASE WHEN bucket_31_60 = 1 THEN OnHand ELSE 0 END) as qty_31_60,
    SUM(CASE WHEN bucket_31_60 = 1 THEN inventory_value ELSE 0 END) as value_31_60,
    CASE 
        WHEN SUM(inventory_value) > 0 
        THEN SUM(CASE WHEN bucket_31_60 = 1 THEN inventory_value ELSE 0 END) / SUM(inventory_value) * 100 
        ELSE 0 
    END as pct_value_31_60,
    
    -- 61-90 days
    SUM(bucket_61_90) as sku_count_61_90,
    SUM(CASE WHEN bucket_61_90 = 1 THEN OnHand ELSE 0 END) as qty_61_90,
    SUM(CASE WHEN bucket_61_90 = 1 THEN inventory_value ELSE 0 END) as value_61_90,
    CASE 
        WHEN SUM(inventory_value) > 0 
        THEN SUM(CASE WHEN bucket_61_90 = 1 THEN inventory_value ELSE 0 END) / SUM(inventory_value) * 100 
        ELSE 0 
    END as pct_value_61_90,
    
    -- 91-180 days
    SUM(bucket_91_180) as sku_count_91_180,
    SUM(CASE WHEN bucket_91_180 = 1 THEN OnHand ELSE 0 END) as qty_91_180,
    SUM(CASE WHEN bucket_91_180 = 1 THEN inventory_value ELSE 0 END) as value_91_180,
    CASE 
        WHEN SUM(inventory_value) > 0 
        THEN SUM(CASE WHEN bucket_91_180 = 1 THEN inventory_value ELSE 0 END) / SUM(inventory_value) * 100 
        ELSE 0 
    END as pct_value_91_180,
    
    -- 180+ days
    SUM(bucket_180_plus) as sku_count_180_plus,
    SUM(CASE WHEN bucket_180_plus = 1 THEN OnHand ELSE 0 END) as qty_180_plus,
    SUM(CASE WHEN bucket_180_plus = 1 THEN inventory_value ELSE 0 END) as value_180_plus,
    CASE 
        WHEN SUM(inventory_value) > 0 
        THEN SUM(CASE WHEN bucket_180_plus = 1 THEN inventory_value ELSE 0 END) / SUM(inventory_value) * 100 
        ELSE 0 
    END as pct_value_180_plus
    
FROM aging_data;

-- =====================================================
-- View: Inventory Aging by Category
-- =====================================================
CREATE VIEW analytics.vw_kpi_inventory_aging_by_category AS
WITH aging_data AS (
    SELECT 
        i.item_category,
        i.item_code,
        i.avg_price,
        itw.OnHand,
        itw.OnHand * i.avg_price as inventory_value,
        DATEDIFF(DAY, i.updated_date, GETDATE()) as days_in_stock,
        
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 30 THEN '0-30 days'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 60 THEN '31-60 days'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 90 THEN '61-90 days'
            WHEN DATEDIFF(DAY, i.updated_date, GETDATE()) <= 180 THEN '91-180 days'
            ELSE '180+ days'
        END as age_bucket
        
    FROM analytics.dim_item i
    INNER JOIN OITW itw ON i.item_code = itw.ItemCode
    WHERE i.is_current = 1
      AND i.inventory_item = 1
      AND itw.OnHand > 0
)
SELECT 
    item_category,
    age_bucket,
    
    COUNT(*) as sku_count,
    SUM(OnHand) as total_quantity,
    SUM(inventory_value) as total_value,
    AVG(days_in_stock) as avg_days_in_stock,
    
    -- Percentage of category value in this bucket
    SUM(inventory_value) / SUM(SUM(inventory_value)) OVER (PARTITION BY item_category) * 100 as pct_of_category_value
    
FROM aging_data
GROUP BY item_category, age_bucket;

-- =====================================================
-- View: Slow Moving Items (90+ Days)
-- =====================================================
CREATE VIEW analytics.vw_kpi_slow_moving_items AS
WITH slow_movers AS (
    SELECT 
        i.item_key,
        i.item_code,
        i.item_name,
        i.item_category,
        i.product_line,
        i.abc_class,
        
        itw.OnHand as current_stock,
        i.avg_price,
        itw.OnHand * i.avg_price as inventory_value,
        
        DATEDIFF(DAY, i.updated_date, GETDATE()) as days_in_stock,
        
        -- Last 90 days sales (would require sales fact table)
        ISNULL((
            SELECT SUM(f.quantity)
            FROM analytics.fact_sales f
            INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
            WHERE f.item_key = i.item_key
              AND dc.date_value >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE))
        ), 0) as qty_sold_last_90_days,
        
        -- Days of inventory on hand
        CASE 
            WHEN ISNULL((
                SELECT SUM(f.quantity)
                FROM analytics.fact_sales f
                INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
                WHERE f.item_key = i.item_key
                  AND dc.date_value >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE))
            ), 0) > 0
            THEN (itw.OnHand / (
                SELECT SUM(f.quantity)
                FROM analytics.fact_sales f
                INNER JOIN analytics.dim_calendar dc ON f.invoice_date_key = dc.date_key
                WHERE f.item_key = i.item_key
                  AND dc.date_value >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE))
            )) * 90
            ELSE 999
        END as days_of_supply
        
    FROM analytics.dim_item i
    INNER JOIN OITW itw ON i.item_code = itw.ItemCode
    WHERE i.is_current = 1
      AND i.inventory_item = 1
      AND itw.OnHand > 0
      AND DATEDIFF(DAY, i.updated_date, GETDATE()) >= 90
)
SELECT 
    *,
    -- Action recommendation
    CASE 
        WHEN days_of_supply > 180 AND inventory_value > 10000 THEN 'Urgent: Liquidate or Discount'
        WHEN days_of_supply > 120 THEN 'Consider Promotion'
        WHEN days_of_supply > 90 THEN 'Monitor Closely'
        ELSE 'No Action'
    END as recommended_action
    
FROM slow_movers
WHERE days_of_supply > 90
ORDER BY inventory_value DESC;

-- =====================================================
-- Stored Procedure: Inventory Aging Report
-- =====================================================
CREATE PROCEDURE analytics.sp_inventory_aging_report
    @AsOfDate DATE = NULL,
    @ItemCategory NVARCHAR(50) = NULL,
    @MinValue DECIMAL(19,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @AsOfDate IS NULL
        SET @AsOfDate = CAST(GETDATE() AS DATE);
    
    SELECT 
        i.item_code,
        i.item_name,
        i.item_category,
        i.abc_class,
        
        itw.OnHand as current_stock,
        i.avg_price,
        itw.OnHand * i.avg_price as inventory_value,
        
        DATEDIFF(DAY, i.updated_date, @AsOfDate) as days_in_stock,
        
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 30 THEN '0-30 days'
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 60 THEN '31-60 days'
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 90 THEN '61-90 days'
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 180 THEN '91-180 days'
            ELSE '180+ days'
        END as age_bucket,
        
        CASE 
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 60 THEN 'Low'
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 120 THEN 'Medium'
            WHEN DATEDIFF(DAY, i.updated_date, @AsOfDate) <= 180 THEN 'High'
            ELSE 'Critical'
        END as risk_level
        
    FROM analytics.dim_item i
    INNER JOIN OITW itw ON i.item_code = itw.ItemCode
    WHERE i.is_current = 1
      AND i.inventory_item = 1
      AND itw.OnHand > 0
      AND (@ItemCategory IS NULL OR i.item_category = @ItemCategory)
      AND (@MinValue IS NULL OR (itw.OnHand * i.avg_price) >= @MinValue)
    ORDER BY 
        DATEDIFF(DAY, i.updated_date, @AsOfDate) DESC,
        itw.OnHand * i.avg_price DESC;
END;
GO

-- Sample usage:
-- EXEC analytics.sp_inventory_aging_report;
-- EXEC analytics.sp_inventory_aging_report @ItemCategory = 'Electronics';
-- EXEC analytics.sp_inventory_aging_report @MinValue = 5000;


# Updated: 2025-11-14 08:21:00

# Updated: 2025-11-14 20:32:00

# Updated: 2025-11-17 20:40:00

# Updated: 2025-11-19 08:02:00

# Updated: 2025-11-21 12:19:00

# Updated: 2025-11-23 14:59:00

# Updated: 2025-11-26 08:08:00

# Updated: 2025-11-26 18:56:00

# Updated: 2025-11-28 12:48:00

# Updated: 2025-11-30 20:41:00

# Updated: 2025-11-30 22:04:00

# Updated: 2025-12-02 12:48:00

# Updated: 2025-12-05 08:04:00

# Updated: 2025-12-07 16:41:00

# Updated: 2025-12-08 08:16:00

# Updated: 2025-12-08 12:09:00

# Updated: 2025-12-09 12:12:00

# Updated: 2025-12-09 14:56:00

# Updated: 2025-12-10 12:18:00

# Updated: 2025-12-11 16:27:00

# Updated: 2025-12-12 18:25:00

# Updated: 2025-12-14 08:23:00

# Updated: 2025-12-14 10:16:00

# Updated: 2025-12-15 08:48:00

# Updated: 2025-12-17 22:47:00
