-- SAP Business One Sample Data
-- Realistic sample data for testing and demonstration
-- Includes customers, items, sales orders, invoices, deliveries, and production orders

-- =====================================================
-- OITM: Items Master Data
-- =====================================================
INSERT INTO OITM (ItemCode, ItemName, FrgnName, ItmsGrpCod, CstGrpCode, VatGourpSa, PrchseItem, SellItem, InvntItem, OnHand, IsCommited, OnOrder, AvgPrice, CreateDate, UpdateDate, validFor, ManBtchNum, ManSerNum) VALUES
('ITEM-001', 'Laptop Computer Pro 15"', 'Professional Laptop', 101, 1, 'S1', 'Y', 'Y', 'Y', 150.0, 25.0, 50.0, 1200.00, '2024-01-15', '2025-11-15', 'Y', 'N', 'Y'),
('ITEM-002', 'Wireless Mouse', 'Ergonomic Mouse', 102, 1, 'S1', 'Y', 'Y', 'Y', 500.0, 50.0, 100.0, 25.00, '2024-01-15', '2025-11-10', 'Y', 'N', 'N'),
('ITEM-003', 'Mechanical Keyboard RGB', 'Gaming Keyboard', 102, 1, 'S1', 'Y', 'Y', 'Y', 300.0, 40.0, 75.0, 85.00, '2024-01-20', '2025-10-20', 'Y', 'N', 'N'),
('ITEM-004', '27" 4K Monitor', 'Professional Display', 101, 1, 'S1', 'Y', 'Y', 'Y', 200.0, 30.0, 60.0, 450.00, '2024-02-01', '2025-11-01', 'Y', 'N', 'N'),
('ITEM-005', 'USB-C Docking Station', 'Universal Dock', 102, 1, 'S1', 'Y', 'Y', 'Y', 175.0, 20.0, 40.0, 120.00, '2024-02-10', '2025-09-15', 'Y', 'N', 'N'),
('ITEM-006', 'Office Chair Premium', 'Ergonomic Chair', 103, 2, 'S1', 'Y', 'Y', 'Y', 80.0, 10.0, 20.0, 380.00, '2024-03-01', '2025-08-01', 'Y', 'N', 'N'),
('ITEM-007', 'Standing Desk Electric', 'Adjustable Desk', 103, 2, 'S1', 'Y', 'Y', 'Y', 45.0, 5.0, 15.0, 650.00, '2024-03-15', '2025-07-15', 'Y', 'N', 'N'),
('ITEM-008', 'Webcam HD Pro', 'Professional Webcam', 102, 1, 'S1', 'Y', 'Y', 'Y', 250.0, 35.0, 50.0, 95.00, '2024-04-01', '2025-11-05', 'Y', 'N', 'N'),
('ITEM-009', 'Noise Cancelling Headphones', 'Premium Headphones', 102, 1, 'S1', 'Y', 'Y', 'Y', 180.0, 25.0, 45.0, 280.00, '2024-04-15', '2025-10-10', 'Y', 'N', 'N'),
('ITEM-010', 'Portable SSD 1TB', 'External Storage', 102, 1, 'S1', 'Y', 'Y', 'Y', 400.0, 60.0, 100.0, 110.00, '2024-05-01', '2025-11-20', 'Y', 'N', 'Y');

-- =====================================================
-- OCRD: Business Partners Master Data
-- =====================================================
INSERT INTO OCRD (CardCode, CardName, CardType, GroupCode, Address, ZipCode, Phone1, CntctPrsn, Balance, ChecksBal, CreditLine, Discount, VatStatus, Currency, validFor, frozen, CreateDate, UpdateDate) VALUES
('CUST-001', 'TechVision Solutions Inc', 'C', 100, '123 Innovation Drive, San Francisco, CA', '94105', '+1-415-555-0101', 'John Smith', 45000.00, 0.00, 100000.00, 5.0, 'Y', 'USD', 'Y', 'N', '2023-06-01', '2025-11-15'),
('CUST-002', 'Global Enterprises Ltd', 'C', 100, '456 Market Street, New York, NY', '10001', '+1-212-555-0202', 'Sarah Johnson', 32000.00, 0.00, 150000.00, 8.0, 'Y', 'USD', 'Y', 'N', '2023-07-15', '2025-11-10'),
('CUST-003', 'Innovative Systems Corp', 'C', 101, '789 Tech Parkway, Austin, TX', '78701', '+1-512-555-0303', 'Michael Chen', 28500.00, 0.00, 80000.00, 3.0, 'Y', 'USD', 'Y', 'N', '2023-08-20', '2025-10-20'),
('CUST-004', 'Digital Dynamics LLC', 'C', 100, '321 Commerce Blvd, Seattle, WA', '98101', '+1-206-555-0404', 'Emily Rodriguez', 56000.00, 0.00, 120000.00, 7.0, 'Y', 'USD', 'Y', 'N', '2023-09-10', '2025-11-05'),
('CUST-005', 'NextGen Technologies', 'C', 101, '654 Silicon Avenue, San Jose, CA', '95110', '+1-408-555-0505', 'David Park', 18000.00, 0.00, 60000.00, 2.0, 'Y', 'USD', 'Y', 'N', '2024-01-15', '2025-09-15'),
('CUST-006', 'Enterprise Solutions Group', 'C', 100, '987 Business Center, Boston, MA', '02101', '+1-617-555-0606', 'Lisa Anderson', 72000.00, 0.00, 180000.00, 10.0, 'Y', 'USD', 'Y', 'N', '2024-02-20', '2025-11-20'),
('CUST-007', 'Smart Office Supplies', 'C', 102, '147 Retail Plaza, Chicago, IL', '60601', '+1-312-555-0707', 'Robert Taylor', 12500.00, 0.00, 50000.00, 4.0, 'Y', 'USD', 'Y', 'N', '2024-03-25', '2025-08-25'),
('CUST-008', 'ProTech Distribution', 'C', 101, '258 Warehouse Road, Denver, CO', '80201', '+1-303-555-0808', 'Jennifer White', 41000.00, 0.00, 90000.00, 6.0, 'Y', 'USD', 'Y', 'N', '2024-04-30', '2025-10-30'),
('SUPP-001', 'Component Suppliers International', 'S', 200, '369 Manufacturing St, Shenzhen', '518000', '+86-755-5555-0901', 'Wei Zhang', -35000.00, 0.00, 200000.00, 0.0, 'Y', 'USD', 'Y', 'N', '2023-05-01', '2025-11-01'),
('SUPP-002', 'Quality Parts Corp', 'S', 200, '741 Industrial Way, Detroit, MI', '48201', '+1-313-555-1001', 'Mark Thompson', -28000.00, 0.00, 150000.00, 0.0, 'Y', 'USD', 'Y', 'N', '2023-06-15', '2025-09-15');

-- =====================================================
-- ORDR: Sales Orders Header
-- =====================================================
INSERT INTO ORDR (DocEntry, DocNum, DocType, CANCELED, DocStatus, DocDate, DocDueDate, CardCode, CardName, NumAtCard, DocTotal, DocTotalFC, DocCur, DocRate, SlpCode, CreateDate, UpdateDate, TaxDate) VALUES
(1001, 5001, 'I', 'N', 'C', '2025-11-15', '2025-11-22', 'CUST-001', 'TechVision Solutions Inc', 'PO-2025-001', 15600.00, 15600.00, 'USD', 1.0, 1, '2025-11-15', '2025-11-18', '2025-11-15'),
(1002, 5002, 'I', 'N', 'O', '2025-11-18', '2025-11-25', 'CUST-002', 'Global Enterprises Ltd', 'PO-2025-002', 32500.00, 32500.00, 'USD', 1.0, 2, '2025-11-18', '2025-11-18', '2025-11-18'),
(1003, 5003, 'I', 'N', 'O', '2025-11-20', '2025-11-27', 'CUST-003', 'Innovative Systems Corp', 'PO-2025-003', 8750.00, 8750.00, 'USD', 1.0, 1, '2025-11-20', '2025-11-20', '2025-11-20'),
(1004, 5004, 'I', 'N', 'C', '2025-11-22', '2025-11-29', 'CUST-004', 'Digital Dynamics LLC', 'PO-2025-004', 24800.00, 24800.00, 'USD', 1.0, 3, '2025-11-22', '2025-11-25', '2025-11-22'),
(1005, 5005, 'I', 'N', 'O', '2025-11-25', '2025-12-02', 'CUST-005', 'NextGen Technologies', 'PO-2025-005', 18900.00, 18900.00, 'USD', 1.0, 2, '2025-11-25', '2025-11-25', '2025-11-25'),
(1006, 5006, 'I', 'N', 'O', '2025-11-28', '2025-12-05', 'CUST-006', 'Enterprise Solutions Group', 'PO-2025-006', 42000.00, 42000.00, 'USD', 1.0, 1, '2025-11-28', '2025-11-28', '2025-11-28'),
(1007, 5007, 'I', 'N', 'O', '2025-12-01', '2025-12-08', 'CUST-007', 'Smart Office Supplies', 'PO-2025-007', 6500.00, 6500.00, 'USD', 1.0, 3, '2025-12-01', '2025-12-01', '2025-12-01'),
(1008, 5008, 'I', 'N', 'O', '2025-12-03', '2025-12-10', 'CUST-008', 'ProTech Distribution', 'PO-2025-008', 28750.00, 28750.00, 'USD', 1.0, 2, '2025-12-03', '2025-12-03', '2025-12-03');

-- =====================================================
-- RDR1: Sales Orders Lines
-- =====================================================
INSERT INTO RDR1 (DocEntry, LineNum, LineStatus, ItemCode, Dscription, Quantity, OpenQty, Price, Currency, Rate, DiscPrcnt, LineTotal, WhsCode, SlpCode, ShipDate, DelivrdQty, OrderedQty) VALUES
(1001, 0, 'C', 'ITEM-001', 'Laptop Computer Pro 15"', 10.0, 0.0, 1200.00, 'USD', 1.0, 5.0, 11400.00, 'WH01', 1, '2025-11-20', 10.0, 10.0),
(1001, 1, 'C', 'ITEM-002', 'Wireless Mouse', 10.0, 0.0, 25.00, 'USD', 1.0, 0.0, 250.00, 'WH01', 1, '2025-11-20', 10.0, 10.0),
(1001, 2, 'C', 'ITEM-003', 'Mechanical Keyboard RGB', 20.0, 0.0, 85.00, 'USD', 1.0, 5.0, 1615.00, 'WH01', 1, '2025-11-20', 20.0, 20.0),
(1002, 0, 'O', 'ITEM-004', '27" 4K Monitor', 25.0, 25.0, 450.00, 'USD', 1.0, 8.0, 10350.00, 'WH01', 2, '2025-11-26', 0.0, 25.0),
(1002, 1, 'O', 'ITEM-001', 'Laptop Computer Pro 15"', 15.0, 15.0, 1200.00, 'USD', 1.0, 8.0, 16560.00, 'WH01', 2, '2025-11-26', 0.0, 15.0),
(1003, 0, 'O', 'ITEM-008', 'Webcam HD Pro', 50.0, 50.0, 95.00, 'USD', 1.0, 3.0, 4607.50, 'WH01', 1, '2025-11-28', 0.0, 50.0),
(1003, 1, 'O', 'ITEM-002', 'Wireless Mouse', 100.0, 100.0, 25.00, 'USD', 1.0, 5.0, 2375.00, 'WH01', 1, '2025-11-28', 0.0, 100.0),
(1004, 0, 'C', 'ITEM-006', 'Office Chair Premium', 30.0, 0.0, 380.00, 'USD', 1.0, 7.0, 10602.00, 'WH02', 3, '2025-11-27', 30.0, 30.0),
(1004, 1, 'C', 'ITEM-007', 'Standing Desk Electric', 20.0, 0.0, 650.00, 'USD', 1.0, 7.0, 12090.00, 'WH02', 3, '2025-11-27', 20.0, 20.0),
(1005, 0, 'O', 'ITEM-009', 'Noise Cancelling Headphones', 40.0, 40.0, 280.00, 'USD', 1.0, 2.0, 10976.00, 'WH01', 2, '2025-12-04', 0.0, 40.0),
(1005, 1, 'O', 'ITEM-010', 'Portable SSD 1TB', 60.0, 60.0, 110.00, 'USD', 1.0, 0.0, 6600.00, 'WH01', 2, '2025-12-04', 0.0, 60.0),
(1006, 0, 'O', 'ITEM-001', 'Laptop Computer Pro 15"', 30.0, 30.0, 1200.00, 'USD', 1.0, 10.0, 32400.00, 'WH01', 1, '2025-12-07', 0.0, 30.0),
(1006, 1, 'O', 'ITEM-004', '27" 4K Monitor', 30.0, 30.0, 450.00, 'USD', 1.0, 10.0, 12150.00, 'WH01', 1, '2025-12-07', 0.0, 30.0),
(1007, 0, 'O', 'ITEM-002', 'Wireless Mouse', 150.0, 150.0, 25.00, 'USD', 1.0, 4.0, 3600.00, 'WH01', 3, '2025-12-09', 0.0, 150.0),
(1007, 1, 'O', 'ITEM-003', 'Mechanical Keyboard RGB', 50.0, 50.0, 85.00, 'USD', 1.0, 4.0, 4080.00, 'WH01', 3, '2025-12-09', 0.0, 50.0),
(1008, 0, 'O', 'ITEM-005', 'USB-C Docking Station', 80.0, 80.0, 120.00, 'USD', 1.0, 6.0, 9024.00, 'WH01', 2, '2025-12-12', 0.0, 80.0),
(1008, 1, 'O', 'ITEM-008', 'Webcam HD Pro', 100.0, 100.0, 95.00, 'USD', 1.0, 6.0, 8930.00, 'WH01', 2, '2025-12-12', 0.0, 100.0);

-- =====================================================
-- OINV: A/R Invoices Header
-- =====================================================
INSERT INTO OINV (DocEntry, DocNum, DocType, CANCELED, DocStatus, DocDate, DocDueDate, CardCode, CardName, NumAtCard, DocTotal, DocTotalFC, PaidToDate, DocCur, DocRate, SlpCode, CreateDate, UpdateDate, TaxDate) VALUES
(2001, 6001, 'I', 'N', 'O', '2025-11-20', '2025-12-20', 'CUST-001', 'TechVision Solutions Inc', 'PO-2025-001', 15600.00, 15600.00, 0.00, 'USD', 1.0, 1, '2025-11-20', '2025-11-20', '2025-11-20'),
(2002, 6002, 'I', 'N', 'O', '2025-11-27', '2025-12-27', 'CUST-004', 'Digital Dynamics LLC', 'PO-2025-004', 24800.00, 24800.00, 0.00, 'USD', 1.0, 3, '2025-11-27', '2025-11-27', '2025-11-27'),
(2003, 6003, 'I', 'N', 'O', '2025-12-05', '2026-01-04', 'CUST-003', 'Innovative Systems Corp', 'PO-2025-003A', 12450.00, 12450.00, 0.00, 'USD', 1.0, 1, '2025-12-05', '2025-12-05', '2025-12-05'),
(2004, 6004, 'I', 'N', 'O', '2025-12-10', '2026-01-09', 'CUST-006', 'Enterprise Solutions Group', 'PO-2025-006A', 28900.00, 28900.00, 5000.00, 'USD', 1.0, 1, '2025-12-10', '2025-12-12', '2025-12-10');

-- =====================================================
-- INV1: A/R Invoices Lines
-- =====================================================
INSERT INTO INV1 (DocEntry, LineNum, LineStatus, ItemCode, Dscription, Quantity, Price, Currency, Rate, DiscPrcnt, LineTotal, WhsCode, SlpCode, ShipDate, StockPrice, StockSum, GrossBuyPr) VALUES
(2001, 0, 'O', 'ITEM-001', 'Laptop Computer Pro 15"', 10.0, 1200.00, 'USD', 1.0, 5.0, 11400.00, 'WH01', 1, '2025-11-20', 950.00, 9500.00, 950.00),
(2001, 1, 'O', 'ITEM-002', 'Wireless Mouse', 10.0, 25.00, 'USD', 1.0, 0.0, 250.00, 'WH01', 1, '2025-11-20', 15.00, 150.00, 15.00),
(2001, 2, 'O', 'ITEM-003', 'Mechanical Keyboard RGB', 20.0, 85.00, 'USD', 1.0, 5.0, 1615.00, 'WH01', 1, '2025-11-20', 55.00, 1100.00, 55.00),
(2002, 0, 'O', 'ITEM-006', 'Office Chair Premium', 30.0, 380.00, 'USD', 1.0, 7.0, 10602.00, 'WH02', 3, '2025-11-27', 280.00, 8400.00, 280.00),
(2002, 1, 'O', 'ITEM-007', 'Standing Desk Electric', 20.0, 650.00, 'USD', 1.0, 7.0, 12090.00, 'WH02', 3, '2025-11-27', 480.00, 9600.00, 480.00),
(2003, 0, 'O', 'ITEM-005', 'USB-C Docking Station', 50.0, 120.00, 'USD', 1.0, 6.0, 5640.00, 'WH01', 1, '2025-12-05', 85.00, 4250.00, 85.00),
(2003, 1, 'O', 'ITEM-010', 'Portable SSD 1TB', 80.0, 110.00, 'USD', 1.0, 3.0, 8536.00, 'WH01', 1, '2025-12-05', 75.00, 6000.00, 75.00),
(2004, 0, 'O', 'ITEM-001', 'Laptop Computer Pro 15"', 20.0, 1200.00, 'USD', 1.0, 10.0, 21600.00, 'WH01', 1, '2025-12-10', 950.00, 19000.00, 950.00),
(2004, 1, 'O', 'ITEM-004', '27" 4K Monitor', 20.0, 450.00, 'USD', 1.0, 10.0, 8100.00, 'WH01', 1, '2025-12-10', 320.00, 6400.00, 320.00);

-- =====================================================
-- ODLN: Deliveries Header
-- =====================================================
INSERT INTO ODLN (DocEntry, DocNum, DocType, CANCELED, DocStatus, DocDate, DocDueDate, CardCode, CardName, NumAtCard, DocTotal, DocTotalFC, DocCur, DocRate, SlpCode, CreateDate, UpdateDate, TaxDate, U_ActualDeliveryDate, U_PromisedDeliveryDate) VALUES
(3001, 7001, 'I', 'N', 'C', '2025-11-20', '2025-11-20', 'CUST-001', 'TechVision Solutions Inc', 'PO-2025-001', 15600.00, 15600.00, 'USD', 1.0, 1, '2025-11-20', '2025-11-20', '2025-11-20', '2025-11-20', '2025-11-22'),
(3002, 7002, 'I', 'N', 'C', '2025-11-27', '2025-11-27', 'CUST-004', 'Digital Dynamics LLC', 'PO-2025-004', 24800.00, 24800.00, 'USD', 1.0, 3, '2025-11-27', '2025-11-27', '2025-11-27', '2025-11-27', '2025-11-29'),
(3003, 7003, 'I', 'N', 'C', '2025-12-05', '2025-12-05', 'CUST-003', 'Innovative Systems Corp', 'PO-2025-003A', 12450.00, 12450.00, 'USD', 1.0, 1, '2025-12-05', '2025-12-05', '2025-12-05', '2025-12-05', '2025-12-08'),
(3004, 7004, 'I', 'N', 'C', '2025-12-11', '2025-12-11', 'CUST-006', 'Enterprise Solutions Group', 'PO-2025-006A', 28900.00, 28900.00, 'USD', 1.0, 1, '2025-12-11', '2025-12-11', '2025-12-11', '2025-12-11', '2025-12-13');

-- =====================================================
-- DLN1: Deliveries Lines
-- =====================================================
INSERT INTO DLN1 (DocEntry, LineNum, TargetType, BaseType, BaseEntry, BaseLine, LineStatus, ItemCode, Dscription, Quantity, Price, Currency, Rate, DiscPrcnt, LineTotal, WhsCode, SlpCode, ShipDate) VALUES
(3001, 0, 13, 17, 1001, 0, 'C', 'ITEM-001', 'Laptop Computer Pro 15"', 10.0, 1200.00, 'USD', 1.0, 5.0, 11400.00, 'WH01', 1, '2025-11-20'),
(3001, 1, 13, 17, 1001, 1, 'C', 'ITEM-002', 'Wireless Mouse', 10.0, 25.00, 'USD', 1.0, 0.0, 250.00, 'WH01', 1, '2025-11-20'),
(3001, 2, 13, 17, 1001, 2, 'C', 'ITEM-003', 'Mechanical Keyboard RGB', 20.0, 85.00, 'USD', 1.0, 5.0, 1615.00, 'WH01', 1, '2025-11-20'),
(3002, 0, 13, 17, 1004, 0, 'C', 'ITEM-006', 'Office Chair Premium', 30.0, 380.00, 'USD', 1.0, 7.0, 10602.00, 'WH02', 3, '2025-11-27'),
(3002, 1, 13, 17, 1004, 1, 'C', 'ITEM-007', 'Standing Desk Electric', 20.0, 650.00, 'USD', 1.0, 7.0, 12090.00, 'WH02', 3, '2025-11-27'),
(3003, 0, 13, 17, 1003, 0, 'C', 'ITEM-005', 'USB-C Docking Station', 50.0, 120.00, 'USD', 1.0, 6.0, 5640.00, 'WH01', 1, '2025-12-05'),
(3003, 1, 13, 17, 1003, 1, 'C', 'ITEM-010', 'Portable SSD 1TB', 80.0, 110.00, 'USD', 1.0, 3.0, 8536.00, 'WH01', 1, '2025-12-05'),
(3004, 0, 13, 17, 1006, 0, 'C', 'ITEM-001', 'Laptop Computer Pro 15"', 20.0, 1200.00, 'USD', 1.0, 10.0, 21600.00, 'WH01', 1, '2025-12-11'),
(3004, 1, 13, 17, 1006, 1, 'C', 'ITEM-004', '27" 4K Monitor', 20.0, 450.00, 'USD', 1.0, 10.0, 8100.00, 'WH01', 1, '2025-12-11');

-- =====================================================
-- OWOR: Production Orders Header
-- =====================================================
INSERT INTO OWOR (DocEntry, DocNum, Series, ItemCode, ProductCod, Warehouse, Status, PlannedQty, CmpltQty, RjctQty, PostDate, DueDate, CloseDate, RlsDate, Type, Priority, U_ProductionLine, U_Shift, U_PlannedStartTime, U_ActualStartTime, U_PlannedEndTime, U_ActualEndTime, U_DowntimeMinutes, U_ScrapQty, CreateDate, UpdateDate) VALUES
(4001, 8001, 1, 'ITEM-001', 'ITEM-001', 'WH01', 'C', 50.0, 48.0, 2.0, '2025-11-10', '2025-11-15', '2025-11-16', '2025-11-10', 'S', 1, 'LINE-A', 'Day', '2025-11-10 08:00:00', '2025-11-10 08:15:00', '2025-11-15 17:00:00', '2025-11-16 14:30:00', 120, 2.0, '2025-11-09', '2025-11-16'),
(4002, 8002, 1, 'ITEM-004', 'ITEM-004', 'WH01', 'C', 75.0, 73.0, 2.0, '2025-11-12', '2025-11-18', '2025-11-19', '2025-11-12', 'S', 2, 'LINE-B', 'Day', '2025-11-12 08:00:00', '2025-11-12 08:05:00', '2025-11-18 17:00:00', '2025-11-19 16:00:00', 90, 2.0, '2025-11-11', '2025-11-19'),
(4003, 8003, 1, 'ITEM-006', 'ITEM-006', 'WH02', 'R', 40.0, 0.0, 0.0, '2025-11-20', '2025-11-28', NULL, '2025-11-20', 'S', 1, 'LINE-C', 'Day', '2025-11-20 08:00:00', NULL, '2025-11-28 17:00:00', NULL, NULL, NULL, '2025-11-19', '2025-11-20'),
(4004, 8004, 1, 'ITEM-001', 'ITEM-001', 'WH01', 'R', 60.0, 0.0, 0.0, '2025-11-25', '2025-12-02', NULL, '2025-11-25', 'S', 1, 'LINE-A', 'Day', '2025-11-25 08:00:00', NULL, '2025-12-02 17:00:00', NULL, NULL, NULL, '2025-11-24', '2025-11-25');

-- =====================================================
-- WOR1: Production Orders Lines (Components)
-- =====================================================
INSERT INTO WOR1 (DocEntry, LineNum, ItemCode, ItemType, BaseQty, PlannedQty, IssuedQty, Warehouse, IssueType, CreateDate, UpdateDate) VALUES
(4001, 0, 'COMP-001', 4, 1.0, 50.0, 50.0, 'WH01', 'B', '2025-11-09', '2025-11-16'),
(4001, 1, 'COMP-002', 4, 2.0, 100.0, 100.0, 'WH01', 'B', '2025-11-09', '2025-11-16'),
(4001, 2, 'COMP-003', 4, 1.0, 50.0, 48.0, 'WH01', 'M', '2025-11-09', '2025-11-16'),
(4002, 0, 'COMP-004', 4, 1.0, 75.0, 75.0, 'WH01', 'B', '2025-11-11', '2025-11-19'),
(4002, 1, 'COMP-005', 4, 1.0, 75.0, 75.0, 'WH01', 'B', '2025-11-11', '2025-11-19'),
(4003, 0, 'COMP-006', 4, 1.0, 40.0, 0.0, 'WH02', 'B', '2025-11-19', '2025-11-20'),
(4003, 1, 'COMP-007', 4, 5.0, 200.0, 0.0, 'WH02', 'B', '2025-11-19', '2025-11-20'),
(4004, 0, 'COMP-001', 4, 1.0, 60.0, 0.0, 'WH01', 'B', '2025-11-24', '2025-11-25'),
(4004, 1, 'COMP-002', 4, 2.0, 120.0, 0.0, 'WH01', 'B', '2025-11-24', '2025-11-25');

-- =====================================================
-- OITW: Items Warehouse Data
-- =====================================================
INSERT INTO OITW (ItemCode, WhsCode, OnHand, IsCommited, OnOrder, MinStock, MaxStock, MinOrder, AvgPrice, Locked) VALUES
('ITEM-001', 'WH01', 150.0, 25.0, 50.0, 50.0, 300.0, 25.0, 1200.00, 'N'),
('ITEM-002', 'WH01', 500.0, 50.0, 100.0, 200.0, 800.0, 100.0, 25.00, 'N'),
('ITEM-003', 'WH01', 300.0, 40.0, 75.0, 100.0, 500.0, 50.0, 85.00, 'N'),
('ITEM-004', 'WH01', 200.0, 30.0, 60.0, 75.0, 400.0, 40.0, 450.00, 'N'),
('ITEM-005', 'WH01', 175.0, 20.0, 40.0, 50.0, 300.0, 30.0, 120.00, 'N'),
('ITEM-006', 'WH02', 80.0, 10.0, 20.0, 30.0, 150.0, 15.0, 380.00, 'N'),
('ITEM-007', 'WH02', 45.0, 5.0, 15.0, 20.0, 100.0, 10.0, 650.00, 'N'),
('ITEM-008', 'WH01', 250.0, 35.0, 50.0, 100.0, 400.0, 50.0, 95.00, 'N'),
('ITEM-009', 'WH01', 180.0, 25.0, 45.0, 75.0, 300.0, 40.0, 280.00, 'N'),
('ITEM-010', 'WH01', 400.0, 60.0, 100.0, 150.0, 600.0, 75.0, 110.00, 'N');

