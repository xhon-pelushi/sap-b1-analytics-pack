-- =====================================================
-- Fact Table: Sales
-- Purpose: Sales transactions from invoices
-- Grain: One row per invoice line item
-- =====================================================

-- Drop table if exists (for development/testing)
-- DROP TABLE IF EXISTS analytics.fact_sales;

CREATE TABLE analytics.fact_sales (
    -- Surrogate key
    sales_fact_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign keys to dimensions
    customer_key INT NOT NULL,
    item_key INT NOT NULL,
    order_date_key INT NOT NULL,
    invoice_date_key INT NOT NULL,
    ship_date_key INT,
    due_date_key INT,
    
    -- Degenerate dimensions (transaction identifiers)
    invoice_doc_entry INT NOT NULL,
    invoice_doc_num INT NOT NULL,
    invoice_line_num INT NOT NULL,
    order_doc_entry INT,
    order_doc_num INT,
    delivery_doc_entry INT,
    
    -- Customer reference
    customer_po_number NVARCHAR(100),
    
    -- Sales person
    sales_person_code INT,
    
    -- Warehouse
    warehouse_code NVARCHAR(8),
    
    -- Quantities
    quantity DECIMAL(19,6) NOT NULL,
    unit_of_measure NVARCHAR(20),
    
    -- Prices and amounts (in document currency)
    unit_price DECIMAL(19,6),
    discount_percent DECIMAL(19,6),
    line_total DECIMAL(19,6),
    line_total_before_discount DECIMAL(19,6),
    discount_amount DECIMAL(19,6),
    
    -- Cost and margin
    unit_cost DECIMAL(19,6),
    total_cost DECIMAL(19,6),
    gross_profit DECIMAL(19,6),
    gross_margin_percent DECIMAL(19,6),
    
    -- Tax
    tax_code NVARCHAR(8),
    tax_amount DECIMAL(19,6),
    tax_percent DECIMAL(19,6),
    
    -- Currency
    document_currency NVARCHAR(3),
    currency_rate DECIMAL(19,6),
    
    -- Amounts in system currency (USD)
    line_total_sys DECIMAL(19,6),
    total_cost_sys DECIMAL(19,6),
    gross_profit_sys DECIMAL(19,6),
    tax_amount_sys DECIMAL(19,6),
    
    -- Document status
    document_status NVARCHAR(1), -- O=Open, C=Closed
    line_status NVARCHAR(1),
    is_canceled BIT DEFAULT 0,
    
    -- Payment status
    paid_to_date DECIMAL(19,6),
    outstanding_amount DECIMAL(19,6),
    is_fully_paid BIT DEFAULT 0,
    days_to_payment INT,
    
    -- Return/Credit memo flag
    is_return BIT DEFAULT 0,
    
    -- Base document information
    base_document_type INT,
    base_document_entry INT,
    base_document_line INT,
    
    -- Business metrics (pre-calculated for performance)
    is_first_time_customer BIT DEFAULT 0,
    customer_lifetime_order_number INT,
    days_from_order_to_invoice INT,
    days_from_invoice_to_ship INT,
    
    -- Item classification at time of sale
    item_category NVARCHAR(50),
    item_abc_class NVARCHAR(1),
    
    -- Audit fields
    source_system NVARCHAR(50) DEFAULT 'SAP_B1',
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    updated_date DATETIME NOT NULL DEFAULT GETDATE(),
    etl_batch_id BIGINT,
    
    -- Foreign key constraints
    CONSTRAINT fk_fact_sales_customer 
        FOREIGN KEY (customer_key) REFERENCES analytics.dim_customer(customer_key),
    CONSTRAINT fk_fact_sales_item 
        FOREIGN KEY (item_key) REFERENCES analytics.dim_item(item_key),
    CONSTRAINT fk_fact_sales_order_date 
        FOREIGN KEY (order_date_key) REFERENCES analytics.dim_calendar(date_key),
    CONSTRAINT fk_fact_sales_invoice_date 
        FOREIGN KEY (invoice_date_key) REFERENCES analytics.dim_calendar(date_key)
);

-- Create indexes for query performance
CREATE INDEX idx_fact_sales_customer_key 
    ON analytics.fact_sales(customer_key);

CREATE INDEX idx_fact_sales_item_key 
    ON analytics.fact_sales(item_key);

CREATE INDEX idx_fact_sales_invoice_date_key 
    ON analytics.fact_sales(invoice_date_key);

CREATE INDEX idx_fact_sales_order_date_key 
    ON analytics.fact_sales(order_date_key);

CREATE INDEX idx_fact_sales_invoice_doc 
    ON analytics.fact_sales(invoice_doc_entry, invoice_line_num);

CREATE INDEX idx_fact_sales_sales_person 
    ON analytics.fact_sales(sales_person_code);

CREATE INDEX idx_fact_sales_warehouse 
    ON analytics.fact_sales(warehouse_code);

CREATE INDEX idx_fact_sales_document_status 
    ON analytics.fact_sales(document_status);

CREATE INDEX idx_fact_sales_is_canceled 
    ON analytics.fact_sales(is_canceled);

-- Composite indexes for common queries
CREATE INDEX idx_fact_sales_customer_invoice_date 
    ON analytics.fact_sales(customer_key, invoice_date_key);

CREATE INDEX idx_fact_sales_item_invoice_date 
    ON analytics.fact_sales(item_key, invoice_date_key);

CREATE INDEX idx_fact_sales_date_customer_item 
    ON analytics.fact_sales(invoice_date_key, customer_key, item_key);

-- Columnstore index for analytical queries (SQL Server 2016+)
-- CREATE CLUSTERED COLUMNSTORE INDEX cci_fact_sales 
--     ON analytics.fact_sales;

-- Add comments
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Fact table containing sales transactions from AR invoices', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'fact_sales';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Surrogate key for sales fact', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'fact_sales',
    @level2type = N'COLUMN', @level2name = 'sales_fact_key';

-- View for common sales analysis
CREATE VIEW analytics.vw_sales_analysis AS
SELECT 
    f.sales_fact_key,
    f.invoice_doc_num,
    f.invoice_line_num,
    
    -- Date attributes
    d_inv.date_value as invoice_date,
    d_inv.year_number as invoice_year,
    d_inv.quarter_name as invoice_quarter,
    d_inv.month_name as invoice_month,
    d_inv.week_of_year as invoice_week,
    
    -- Customer attributes
    c.card_code,
    c.card_name,
    c.customer_tier,
    c.customer_segment,
    c.region as customer_region,
    c.country as customer_country,
    
    -- Item attributes
    i.item_code,
    i.item_name,
    i.item_category,
    i.item_subcategory,
    i.product_line,
    i.abc_class,
    
    -- Sales metrics
    f.quantity,
    f.unit_price,
    f.discount_percent,
    f.line_total,
    f.total_cost,
    f.gross_profit,
    f.gross_margin_percent,
    f.line_total_sys,
    f.gross_profit_sys,
    
    -- Flags
    f.is_canceled,
    f.is_return,
    f.is_first_time_customer
    
FROM analytics.fact_sales f
INNER JOIN analytics.dim_customer c ON f.customer_key = c.customer_key
INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
INNER JOIN analytics.dim_calendar d_inv ON f.invoice_date_key = d_inv.date_key
WHERE f.is_canceled = 0
  AND c.is_current = 1
  AND i.is_current = 1;

-- Sample ETL query to populate fact table
/*
INSERT INTO analytics.fact_sales (
    customer_key,
    item_key,
    order_date_key,
    invoice_date_key,
    invoice_doc_entry,
    invoice_doc_num,
    invoice_line_num,
    order_doc_entry,
    customer_po_number,
    sales_person_code,
    warehouse_code,
    quantity,
    unit_price,
    discount_percent,
    line_total,
    unit_cost,
    total_cost,
    gross_profit,
    gross_margin_percent,
    document_currency,
    currency_rate,
    line_total_sys,
    gross_profit_sys,
    document_status,
    is_canceled
)
SELECT 
    dc.customer_key,
    di.item_key,
    CAST(FORMAT(h.DocDate, 'yyyyMMdd') AS INT) as order_date_key,
    CAST(FORMAT(h.DocDate, 'yyyyMMdd') AS INT) as invoice_date_key,
    h.DocEntry,
    h.DocNum,
    l.LineNum,
    l.BaseEntry,
    h.NumAtCard,
    h.SlpCode,
    l.WhsCode,
    l.Quantity,
    l.Price,
    l.DiscPrcnt,
    l.LineTotal,
    l.GrossBuyPr,
    l.GrossBuyPr * l.Quantity as total_cost,
    l.LineTotal - (l.GrossBuyPr * l.Quantity) as gross_profit,
    CASE WHEN l.LineTotal > 0 
         THEN ((l.LineTotal - (l.GrossBuyPr * l.Quantity)) / l.LineTotal) * 100 
         ELSE 0 END as gross_margin_percent,
    h.DocCur,
    h.DocRate,
    l.LineTotal * h.DocRate as line_total_sys,
    (l.LineTotal - (l.GrossBuyPr * l.Quantity)) * h.DocRate as gross_profit_sys,
    h.DocStatus,
    CASE WHEN h.CANCELED = 'Y' THEN 1 ELSE 0 END
FROM OINV h
INNER JOIN INV1 l ON h.DocEntry = l.DocEntry
INNER JOIN analytics.dim_customer dc ON h.CardCode = dc.card_code AND dc.is_current = 1
INNER JOIN analytics.dim_item di ON l.ItemCode = di.item_code AND di.is_current = 1
WHERE NOT EXISTS (
    SELECT 1 FROM analytics.fact_sales f 
    WHERE f.invoice_doc_entry = h.DocEntry 
      AND f.invoice_line_num = l.LineNum
);
*/

