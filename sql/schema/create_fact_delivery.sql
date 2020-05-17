-- =====================================================
-- Fact Table: Delivery
-- Purpose: Delivery/shipment transactions for OTD analysis
-- Grain: One row per delivery line item
-- =====================================================

-- Drop table if exists (for development/testing)
-- DROP TABLE IF EXISTS analytics.fact_delivery;

CREATE TABLE analytics.fact_delivery (
    -- Surrogate key
    delivery_fact_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign keys to dimensions
    customer_key INT NOT NULL,
    item_key INT NOT NULL,
    delivery_date_key INT NOT NULL,
    promised_date_key INT,
    order_date_key INT,
    
    -- Degenerate dimensions (transaction identifiers)
    delivery_doc_entry INT NOT NULL,
    delivery_doc_num INT NOT NULL,
    delivery_line_num INT NOT NULL,
    order_doc_entry INT,
    order_doc_num INT,
    invoice_doc_entry INT,
    
    -- Customer reference
    customer_po_number NVARCHAR(100),
    
    -- Sales person
    sales_person_code INT,
    
    -- Warehouse
    warehouse_code NVARCHAR(8),
    
    -- Quantities
    quantity DECIMAL(19,6) NOT NULL,
    unit_of_measure NVARCHAR(20),
    ordered_quantity DECIMAL(19,6),
    
    -- Prices and amounts
    unit_price DECIMAL(19,6),
    discount_percent DECIMAL(19,6),
    line_total DECIMAL(19,6),
    
    -- Currency
    document_currency NVARCHAR(3),
    currency_rate DECIMAL(19,6),
    line_total_sys DECIMAL(19,6),
    
    -- Document status
    document_status NVARCHAR(1), -- O=Open, C=Closed
    line_status NVARCHAR(1),
    is_canceled BIT DEFAULT 0,
    
    -- Delivery dates
    actual_delivery_date DATETIME,
    promised_delivery_date DATETIME,
    requested_delivery_date DATETIME,
    
    -- On-Time Delivery metrics
    delivery_delay_days INT, -- Negative = early, positive = late
    is_on_time_delivery BIT DEFAULT 0,
    is_early_delivery BIT DEFAULT 0,
    is_late_delivery BIT DEFAULT 0,
    
    -- Delivery performance categories
    delivery_performance_category NVARCHAR(20), -- On-Time, Early, Late, Very Late
    
    -- Order-to-delivery metrics
    days_order_to_delivery INT,
    
    -- Base document information
    base_document_type INT,
    base_document_entry INT,
    base_document_line INT,
    
    -- Shipment information
    shipment_method NVARCHAR(50),
    carrier NVARCHAR(50),
    tracking_number NVARCHAR(100),
    freight_cost DECIMAL(19,6),
    
    -- Business flags
    is_partial_delivery BIT DEFAULT 0,
    is_full_delivery BIT DEFAULT 0,
    is_over_delivery BIT DEFAULT 0,
    
    -- Priority
    order_priority NVARCHAR(20),
    is_rush_order BIT DEFAULT 0,
    
    -- Item classification at time of delivery
    item_category NVARCHAR(50),
    item_abc_class NVARCHAR(1),
    
    -- Customer classification at time of delivery
    customer_tier NVARCHAR(1),
    customer_segment NVARCHAR(50),
    
    -- Audit fields
    source_system NVARCHAR(50) DEFAULT 'SAP_B1',
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    updated_date DATETIME NOT NULL DEFAULT GETDATE(),
    etl_batch_id BIGINT,
    
    -- Foreign key constraints
    CONSTRAINT fk_fact_delivery_customer 
        FOREIGN KEY (customer_key) REFERENCES analytics.dim_customer(customer_key),
    CONSTRAINT fk_fact_delivery_item 
        FOREIGN KEY (item_key) REFERENCES analytics.dim_item(item_key),
    CONSTRAINT fk_fact_delivery_date 
        FOREIGN KEY (delivery_date_key) REFERENCES analytics.dim_calendar(date_key)
);

-- Create indexes for query performance
CREATE INDEX idx_fact_delivery_customer_key 
    ON analytics.fact_delivery(customer_key);

CREATE INDEX idx_fact_delivery_item_key 
    ON analytics.fact_delivery(item_key);

CREATE INDEX idx_fact_delivery_delivery_date_key 
    ON analytics.fact_delivery(delivery_date_key);

CREATE INDEX idx_fact_delivery_promised_date_key 
    ON analytics.fact_delivery(promised_date_key);

CREATE INDEX idx_fact_delivery_order_date_key 
    ON analytics.fact_delivery(order_date_key);

CREATE INDEX idx_fact_delivery_doc 
    ON analytics.fact_delivery(delivery_doc_entry, delivery_line_num);

CREATE INDEX idx_fact_delivery_order_doc 
    ON analytics.fact_delivery(order_doc_entry);

CREATE INDEX idx_fact_delivery_sales_person 
    ON analytics.fact_delivery(sales_person_code);

CREATE INDEX idx_fact_delivery_is_on_time 
    ON analytics.fact_delivery(is_on_time_delivery);

CREATE INDEX idx_fact_delivery_performance 
    ON analytics.fact_delivery(delivery_performance_category);

-- Composite indexes for common queries
CREATE INDEX idx_fact_delivery_customer_date 
    ON analytics.fact_delivery(customer_key, delivery_date_key);

CREATE INDEX idx_fact_delivery_item_date 
    ON analytics.fact_delivery(item_key, delivery_date_key);

CREATE INDEX idx_fact_delivery_date_performance 
    ON analytics.fact_delivery(delivery_date_key, is_on_time_delivery);

-- Add comments
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Fact table containing delivery transactions for OTD analysis', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'fact_delivery';

-- View for On-Time Delivery analysis
CREATE VIEW analytics.vw_otd_analysis AS
SELECT 
    f.delivery_fact_key,
    f.delivery_doc_num,
    f.delivery_line_num,
    
    -- Date attributes
    d_del.date_value as delivery_date,
    d_del.year_number as delivery_year,
    d_del.quarter_name as delivery_quarter,
    d_del.month_name as delivery_month,
    d_del.week_of_year as delivery_week,
    
    d_prom.date_value as promised_date,
    
    -- Customer attributes
    c.card_code,
    c.card_name,
    c.customer_tier,
    c.customer_segment,
    c.region as customer_region,
    
    -- Item attributes
    i.item_code,
    i.item_name,
    i.item_category,
    i.product_line,
    
    -- Delivery metrics
    f.quantity,
    f.ordered_quantity,
    f.line_total,
    f.delivery_delay_days,
    f.is_on_time_delivery,
    f.is_early_delivery,
    f.is_late_delivery,
    f.delivery_performance_category,
    f.days_order_to_delivery,
    
    -- Flags
    f.is_partial_delivery,
    f.is_rush_order,
    f.is_canceled
    
FROM analytics.fact_delivery f
INNER JOIN analytics.dim_customer c ON f.customer_key = c.customer_key
INNER JOIN analytics.dim_item i ON f.item_key = i.item_key
INNER JOIN analytics.dim_calendar d_del ON f.delivery_date_key = d_del.date_key
LEFT JOIN analytics.dim_calendar d_prom ON f.promised_date_key = d_prom.date_key
WHERE f.is_canceled = 0
  AND c.is_current = 1
  AND i.is_current = 1;

-- Sample ETL query to populate fact table
/*
INSERT INTO analytics.fact_delivery (
    customer_key,
    item_key,
    delivery_date_key,
    promised_date_key,
    order_date_key,
    delivery_doc_entry,
    delivery_doc_num,
    delivery_line_num,
    order_doc_entry,
    customer_po_number,
    sales_person_code,
    warehouse_code,
    quantity,
    unit_price,
    discount_percent,
    line_total,
    document_currency,
    currency_rate,
    line_total_sys,
    document_status,
    is_canceled,
    actual_delivery_date,
    promised_delivery_date,
    delivery_delay_days,
    is_on_time_delivery,
    is_early_delivery,
    is_late_delivery,
    delivery_performance_category
)
SELECT 
    dc.customer_key,
    di.item_key,
    CAST(FORMAT(h.DocDate, 'yyyyMMdd') AS INT) as delivery_date_key,
    CAST(FORMAT(h.U_PromisedDeliveryDate, 'yyyyMMdd') AS INT) as promised_date_key,
    CAST(FORMAT(ord.DocDate, 'yyyyMMdd') AS INT) as order_date_key,
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
    h.DocCur,
    h.DocRate,
    l.LineTotal * h.DocRate as line_total_sys,
    h.DocStatus,
    CASE WHEN h.CANCELED = 'Y' THEN 1 ELSE 0 END,
    h.U_ActualDeliveryDate,
    h.U_PromisedDeliveryDate,
    DATEDIFF(DAY, h.U_PromisedDeliveryDate, h.U_ActualDeliveryDate) as delivery_delay_days,
    CASE WHEN DATEDIFF(DAY, h.U_PromisedDeliveryDate, h.U_ActualDeliveryDate) <= 0 THEN 1 ELSE 0 END as is_on_time_delivery,
    CASE WHEN DATEDIFF(DAY, h.U_PromisedDeliveryDate, h.U_ActualDeliveryDate) < 0 THEN 1 ELSE 0 END as is_early_delivery,
    CASE WHEN DATEDIFF(DAY, h.U_PromisedDeliveryDate, h.U_ActualDeliveryDate) > 0 THEN 1 ELSE 0 END as is_late_delivery,
    CASE 
        WHEN DATEDIFF(DAY, h.U_PromisedDeliveryDate, h.U_ActualDeliveryDate) <= 0 THEN 'On-Time'
        WHEN DATEDIFF(DAY, h.U_PromisedDeliveryDate, h.U_ActualDeliveryDate) BETWEEN 1 AND 3 THEN 'Late'
        ELSE 'Very Late'
    END as delivery_performance_category
FROM ODLN h
INNER JOIN DLN1 l ON h.DocEntry = l.DocEntry
LEFT JOIN ORDR ord ON l.BaseEntry = ord.DocEntry AND l.BaseType = 17
INNER JOIN analytics.dim_customer dc ON h.CardCode = dc.card_code AND dc.is_current = 1
INNER JOIN analytics.dim_item di ON l.ItemCode = di.item_code AND di.is_current = 1
WHERE NOT EXISTS (
    SELECT 1 FROM analytics.fact_delivery f 
    WHERE f.delivery_doc_entry = h.DocEntry 
      AND f.delivery_line_num = l.LineNum
);
*/

