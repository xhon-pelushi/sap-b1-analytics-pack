-- =====================================================
-- Dimension: Customer
-- Purpose: Customer master dimension for analytics
-- Type: SCD Type 2 (Slowly Changing Dimension)
-- =====================================================

-- Drop table if exists (for development/testing)
-- DROP TABLE IF EXISTS analytics.dim_customer;

CREATE TABLE analytics.dim_customer (
    -- Surrogate key
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Natural/Business key
    card_code NVARCHAR(50) NOT NULL,
    
    -- Customer attributes
    card_name NVARCHAR(100) NOT NULL,
    card_type NVARCHAR(1) NOT NULL,
    card_type_desc NVARCHAR(50),
    
    -- Contact information
    address NVARCHAR(MAX),
    zip_code NVARCHAR(20),
    phone_1 NVARCHAR(20),
    phone_2 NVARCHAR(20),
    fax NVARCHAR(20),
    contact_person NVARCHAR(90),
    
    -- Financial information
    group_code INT,
    group_num INT,
    credit_line DECIMAL(19,6),
    debt_line DECIMAL(19,6),
    discount_percent DECIMAL(19,6),
    currency NVARCHAR(3),
    
    -- Status
    vat_status NVARCHAR(1),
    valid_for NVARCHAR(1),
    frozen NVARCHAR(1),
    
    -- Customer classification
    customer_tier NVARCHAR(1), -- A, B, C, D
    customer_segment NVARCHAR(50), -- Enterprise, Mid-Market, SMB
    is_active BIT DEFAULT 1,
    
    -- Customer lifecycle
    first_order_date DATETIME,
    last_order_date DATETIME,
    total_order_count INT DEFAULT 0,
    lifetime_value DECIMAL(19,6) DEFAULT 0,
    
    -- Geographic classification
    region NVARCHAR(50),
    country NVARCHAR(50),
    state_province NVARCHAR(50),
    city NVARCHAR(50),
    
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
CREATE INDEX idx_dim_customer_card_code 
    ON analytics.dim_customer(card_code);

CREATE INDEX idx_dim_customer_card_name 
    ON analytics.dim_customer(card_name);

CREATE INDEX idx_dim_customer_is_current 
    ON analytics.dim_customer(is_current);

CREATE INDEX idx_dim_customer_card_code_current 
    ON analytics.dim_customer(card_code, is_current);

CREATE INDEX idx_dim_customer_tier 
    ON analytics.dim_customer(customer_tier);

CREATE INDEX idx_dim_customer_segment 
    ON analytics.dim_customer(customer_segment);

CREATE INDEX idx_dim_customer_effective_date 
    ON analytics.dim_customer(effective_date);

-- Create unique constraint for current records
CREATE UNIQUE INDEX idx_dim_customer_card_code_current_unique 
    ON analytics.dim_customer(card_code) 
    WHERE is_current = 1;

-- Add comments (if using SQL Server Extended Properties)
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Customer dimension table with SCD Type 2 implementation', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_customer';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Surrogate key for customer dimension', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_customer',
    @level2type = N'COLUMN', @level2name = 'customer_key';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Natural key from SAP B1 OCRD.CardCode', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_customer',
    @level2type = N'COLUMN', @level2name = 'card_code';

-- View for current customers only (commonly used)
CREATE VIEW analytics.vw_dim_customer_current AS
SELECT 
    customer_key,
    card_code,
    card_name,
    card_type,
    card_type_desc,
    address,
    zip_code,
    phone_1,
    contact_person,
    group_code,
    credit_line,
    discount_percent,
    currency,
    customer_tier,
    customer_segment,
    is_active,
    first_order_date,
    last_order_date,
    total_order_count,
    lifetime_value,
    region,
    country,
    created_date,
    updated_date
FROM analytics.dim_customer
WHERE is_current = 1;

-- Sample initial load with derived attributes
-- This shows how to populate the dimension with business logic
/*
INSERT INTO analytics.dim_customer (
    card_code,
    card_name,
    card_type,
    card_type_desc,
    address,
    zip_code,
    phone_1,
    contact_person,
    credit_line,
    discount_percent,
    currency,
    customer_tier,
    customer_segment,
    is_active,
    effective_date,
    is_current
)
SELECT 
    CardCode,
    CardName,
    CardType,
    CASE CardType 
        WHEN 'C' THEN 'Customer'
        WHEN 'S' THEN 'Supplier'
        WHEN 'L' THEN 'Lead'
    END as card_type_desc,
    Address,
    ZipCode,
    Phone1,
    CntctPrsn,
    CreditLine,
    Discount,
    Currency,
    -- Customer tier based on credit line
    CASE 
        WHEN CreditLine >= 150000 THEN 'A'
        WHEN CreditLine >= 100000 THEN 'B'
        WHEN CreditLine >= 50000 THEN 'C'
        ELSE 'D'
    END as customer_tier,
    -- Customer segment based on credit line
    CASE 
        WHEN CreditLine >= 150000 THEN 'Enterprise'
        WHEN CreditLine >= 75000 THEN 'Mid-Market'
        ELSE 'SMB'
    END as customer_segment,
    CASE WHEN validFor = 'Y' AND frozen = 'N' THEN 1 ELSE 0 END as is_active,
    GETDATE() as effective_date,
    1 as is_current
FROM OCRD
WHERE CardType = 'C'; -- Customers only
*/

