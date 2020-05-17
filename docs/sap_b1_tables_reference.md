# SAP Business One Tables Reference

## Overview

This document provides a reference for the key SAP Business One tables used in the analytics pack.

## Master Data Tables

### OCRD - Business Partners

Customer and supplier master data.

| Column | Type | Description |
|--------|------|-------------|
| CardCode | NVARCHAR(50) | Unique business partner code (PK) |
| CardName | NVARCHAR(100) | Business partner name |
| CardType | NVARCHAR(1) | C=Customer, S=Supplier, L=Lead |
| GroupCode | INT | Business partner group |
| CreditLine | DECIMAL | Credit limit |
| Balance | DECIMAL | Current balance |
| Currency | NVARCHAR(3) | Default currency |
| validFor | NVARCHAR(1) | Active status (Y/N) |

**Usage**: Customer dimension source

### OITM - Items Master Data

Product and item master data.

| Column | Type | Description |
|--------|------|-------------|
| ItemCode | NVARCHAR(50) | Unique item code (PK) |
| ItemName | NVARCHAR(100) | Item description |
| ItmsGrpCod | INT | Item group code |
| OnHand | DECIMAL | Quantity on hand |
| AvgPrice | DECIMAL | Average cost price |
| PrchseItem | NVARCHAR(1) | Purchasable (Y/N) |
| SellItem | NVARCHAR(1) | Saleable (Y/N) |
| InvntItem | NVARCHAR(1) | Inventory item (Y/N) |

**Usage**: Item dimension source

## Transaction Tables

### ORDR/RDR1 - Sales Orders

Sales order header and line items.

**ORDR (Header)**:
| Column | Type | Description |
|--------|------|-------------|
| DocEntry | INT | Document entry (PK) |
| DocNum | INT | Document number |
| DocDate | DATETIME | Document date |
| CardCode | NVARCHAR(50) | Customer code (FK to OCRD) |
| DocTotal | DECIMAL | Total amount |
| DocStatus | NVARCHAR(1) | O=Open, C=Closed |

**RDR1 (Lines)**:
| Column | Type | Description |
|--------|------|-------------|
| DocEntry | INT | Header reference (FK to ORDR) |
| LineNum | INT | Line number |
| ItemCode | NVARCHAR(50) | Item code (FK to OITM) |
| Quantity | DECIMAL | Ordered quantity |
| Price | DECIMAL | Unit price |
| LineTotal | DECIMAL | Line total amount |

### OINV/INV1 - AR Invoices

Accounts receivable invoices.

Similar structure to ORDR/RDR1 with additional fields:
- GrosProfit: Gross profit amount
- PaidToDate: Amount paid
- GrossBuyPr: Unit cost

**Usage**: Sales fact table source

### ODLN/DLN1 - Deliveries

Delivery/shipment documents.

| Column | Type | Description |
|--------|------|-------------|
| DocEntry | INT | Document entry (PK) |
| DocDate | DATETIME | Delivery date |
| U_ActualDeliveryDate | DATETIME | Actual delivery date (UDF) |
| U_PromisedDeliveryDate | DATETIME | Promised date (UDF) |

**Usage**: Delivery fact table, OTD KPI

### OWOR/WOR1 - Production Orders

Manufacturing production orders.

**OWOR (Header)**:
| Column | Type | Description |
|--------|------|-------------|
| DocEntry | INT | Document entry (PK) |
| ItemCode | NVARCHAR(50) | Finished good item |
| PlannedQty | DECIMAL | Planned quantity |
| CmpltQty | DECIMAL | Completed quantity |
| RjctQty | DECIMAL | Rejected quantity |
| Status | NVARCHAR(1) | P=Planned, R=Released, C=Closed |
| U_PlannedStartTime | DATETIME | Planned start (UDF) |
| U_ActualStartTime | DATETIME | Actual start (UDF) |
| U_DowntimeMinutes | INT | Downtime in minutes (UDF) |

**Usage**: OEE KPI calculations

## Inventory Tables

### OITW - Item Warehouse Data

Inventory levels by item and warehouse.

| Column | Type | Description |
|--------|------|-------------|
| ItemCode | NVARCHAR(50) | Item code (PK) |
| WhsCode | NVARCHAR(8) | Warehouse code (PK) |
| OnHand | DECIMAL | Quantity on hand |
| IsCommited | DECIMAL | Committed quantity |
| OnOrder | DECIMAL | On order quantity |
| AvgPrice | DECIMAL | Average cost |

**Usage**: Inventory aging KPI

## User-Defined Fields (UDF)

The analytics pack uses several UDFs for enhanced functionality:

### Delivery UDFs
- `U_ActualDeliveryDate`: Actual delivery date
- `U_PromisedDeliveryDate`: Promised delivery date

### Production UDFs
- `U_ProductionLine`: Production line identifier
- `U_Shift`: Shift (Day/Night)
- `U_PlannedStartTime`: Planned start time
- `U_ActualStartTime`: Actual start time
- `U_PlannedEndTime`: Planned end time
- `U_ActualEndTime`: Actual end time
- `U_DowntimeMinutes`: Downtime in minutes
- `U_ScrapQty`: Scrap quantity

## Table Relationships

```
OCRD (Customers)
  ├── ORDR (Sales Orders)
  │   └── RDR1 (Order Lines) ──> OITM (Items)
  ├── OINV (Invoices)
  │   └── INV1 (Invoice Lines) ──> OITM (Items)
  └── ODLN (Deliveries)
      └── DLN1 (Delivery Lines) ──> OITM (Items)

OITM (Items)
  ├── OITW (Warehouse Stock)
  └── OWOR (Production Orders)
      └── WOR1 (Components)
```

## Query Examples

### Get Customer Sales
```sql
SELECT 
    c.CardCode,
    c.CardName,
    SUM(i.DocTotal) as TotalSales
FROM OCRD c
INNER JOIN OINV i ON c.CardCode = i.CardCode
WHERE i.DocDate >= '2025-01-01'
GROUP BY c.CardCode, c.CardName
ORDER BY TotalSales DESC
```

### Get Inventory Value
```sql
SELECT 
    i.ItemCode,
    i.ItemName,
    w.OnHand,
    i.AvgPrice,
    w.OnHand * i.AvgPrice as InventoryValue
FROM OITM i
INNER JOIN OITW w ON i.ItemCode = w.ItemCode
WHERE w.OnHand > 0
ORDER BY InventoryValue DESC
```

## Best Practices

1. **Always filter by date** to limit result sets
2. **Use DocEntry for joins** (not DocNum) as it's the true primary key
3. **Check CANCELED field** to exclude cancelled documents
4. **Use DocStatus** to filter open/closed documents
5. **Join header and lines** using DocEntry and LineNum
6. **Consider performance** - SAP B1 tables can be large

## Additional Resources

- [SAP Business One SDK Help](https://help.sap.com/docs/SAP_BUSINESS_ONE)
- [SAP B1 Data Dictionary](https://help.sap.com/docs/SAP_BUSINESS_ONE/68a2e87fb29941b5bf959a184d9c6727)

