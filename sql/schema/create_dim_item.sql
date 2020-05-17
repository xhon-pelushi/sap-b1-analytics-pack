-- =====================================================
-- Dimension: Item (Product)
-- Purpose: Item/Product master dimension for analytics
-- Type: SCD Type 2 (Slowly Changing Dimension)
-- =====================================================

-- Drop table if exists (for development/testing)
-- DROP TABLE IF EXISTS analytics.dim_item;

CREATE TABLE analytics.dim_item (
    -- Surrogate key
    item_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Natural/Business key
    item_code NVARCHAR(50) NOT NULL,
    
    -- Item attributes
    item_name NVARCHAR(100) NOT NULL,
    foreign_name NVARCHAR(100),
    
    -- Item classification
    item_group_code INT,
    item_group_name NVARCHAR(100),
    cost_group_code INT,
    vat_group_sale NVARCHAR(20),
    
    -- Item type flags
    purchase_item BIT DEFAULT 0,
    sell_item BIT DEFAULT 0,
    inventory_item BIT DEFAULT 0,
    
    -- Inventory management
    manage_batch_numbers BIT DEFAULT 0,
    manage_serial_numbers BIT DEFAULT 0,
    
    -- Unit of measure
    purchase_unit NVARCHAR(20),
    sales_unit NVARCHAR(20),
    inventory_unit NVARCHAR(20),
    
    -- Pricing
    avg_price DECIMAL(19,6),
    price_tier NVARCHAR(20), -- Budget, Standard, Premium, Luxury
    
    -- Item categorization for analytics
    item_category NVARCHAR(50), -- Electronics, Furniture, etc.
    item_subcategory NVARCHAR(50),
    product_line NVARCHAR(50),
    brand NVARCHAR(50),
    
    -- ABC classification
    abc_class NVARCHAR(1), -- A (80% value), B (15% value), C (5% value)
    xyz_class NVARCHAR(1), -- X (consistent demand), Y (variable), Z (sporadic)
    
    -- Product lifecycle
    product_status NVARCHAR(20), -- New, Active, Mature, Declining, Discontinued
    launch_date DATETIME,
    discontinue_date DATETIME,
    
    -- Attributes for analytics
    is_active BIT DEFAULT 1,
    is_manufactured BIT DEFAULT 0,
    is_purchased BIT DEFAULT 0,
    lead_time_days INT DEFAULT 0,
    
    -- Volume/Weight (for logistics)
    weight_kg DECIMAL(19,6),
    volume_m3 DECIMAL(19,6),
    
    -- Custom fields for business logic
    reorder_point INT,
    safety_stock INT,
    economic_order_qty INT,
    
    -- SCD Type 2 fields
    effective_date DATETIME NOT NULL DEFAULT GETDATE(),
    end_date DATETIME,
    is_current BIT NOT NULL DEFAULT 1,
    
    -- Audit fields
    source_system NVARCHAR(50) DEFAULT 'SAP_B1',
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    updated_date DATETIME NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(50) DEFAULT 'ETL_SYSTEM',
    updated_by NVARCHAR(50) DEFAULT 'ETL_SYSTEM'
);

-- Create indexes for query performance
CREATE INDEX idx_dim_item_item_code 
    ON analytics.dim_item(item_code);

CREATE INDEX idx_dim_item_item_name 
    ON analytics.dim_item(item_name);

CREATE INDEX idx_dim_item_is_current 
    ON analytics.dim_item(is_current);

CREATE INDEX idx_dim_item_item_code_current 
    ON analytics.dim_item(item_code, is_current);

CREATE INDEX idx_dim_item_group 
    ON analytics.dim_item(item_group_code);

CREATE INDEX idx_dim_item_category 
    ON analytics.dim_item(item_category);

CREATE INDEX idx_dim_item_abc_class 
    ON analytics.dim_item(abc_class);

CREATE INDEX idx_dim_item_product_line 
    ON analytics.dim_item(product_line);

-- Create unique constraint for current records
CREATE UNIQUE INDEX idx_dim_item_item_code_current_unique 
    ON analytics.dim_item(item_code) 
    WHERE is_current = 1;

-- Add comments (if using SQL Server Extended Properties)
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Item/Product dimension table with SCD Type 2 implementation', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_item';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Surrogate key for item dimension', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_item',
    @level2type = N'COLUMN', @level2name = 'item_key';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Natural key from SAP B1 OITM.ItemCode', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_item',
    @level2type = N'COLUMN', @level2name = 'item_code';

-- View for current items only (commonly used)
CREATE VIEW analytics.vw_dim_item_current AS
SELECT 
    item_key,
    item_code,
    item_name,
    foreign_name,
    item_group_code,
    item_group_name,
    purchase_item,
    sell_item,
    inventory_item,
    purchase_unit,
    sales_unit,
    avg_price,
    price_tier,
    item_category,
    item_subcategory,
    product_line,
    brand,
    abc_class,
    xyz_class,
    product_status,
    is_active,
    lead_time_days,
    created_date,
    updated_date
FROM analytics.dim_item
WHERE is_current = 1;

-- Sample initial load with derived attributes
/*
INSERT INTO analytics.dim_item (
    item_code,
    item_name,
    foreign_name,
    item_group_code,
    purchase_item,
    sell_item,
    inventory_item,
    manage_batch_numbers,
    manage_serial_numbers,
    purchase_unit,
    sales_unit,
    avg_price,
    price_tier,
    item_category,
    product_status,
    is_active,
    effective_date,
    is_current
)
SELECT 
    ItemCode,
    ItemName,
    FrgnName,
    ItmsGrpCod,
    CASE WHEN PrchseItem = 'Y' THEN 1 ELSE 0 END,
    CASE WHEN SellItem = 'Y' THEN 1 ELSE 0 END,
    CASE WHEN InvntItem = 'Y' THEN 1 ELSE 0 END,
    CASE WHEN ManBtchNum = 'Y' THEN 1 ELSE 0 END,
    CASE WHEN ManSerNum = 'Y' THEN 1 ELSE 0 END,
    PurPackMsr,
    SalPackMsr,
    AvgPrice,
    -- Price tier classification
    CASE 
        WHEN AvgPrice >= 500 THEN 'Luxury'
        WHEN AvgPrice >= 200 THEN 'Premium'
        WHEN AvgPrice >= 50 THEN 'Standard'
        ELSE 'Budget'
    END as price_tier,
    -- Derive category from item group (customize based on your groups)
    CASE 
        WHEN ItmsGrpCod IN (101, 102) THEN 'Electronics'
        WHEN ItmsGrpCod = 103 THEN 'Furniture'
        ELSE 'Other'
    END as item_category,
    -- Product status
    CASE 
        WHEN validFor = 'Y' THEN 'Active'
        ELSE 'Discontinued'
    END as product_status,
    CASE WHEN validFor = 'Y' THEN 1 ELSE 0 END as is_active,
    GETDATE() as effective_date,
    1 as is_current
FROM OITM;
*/

