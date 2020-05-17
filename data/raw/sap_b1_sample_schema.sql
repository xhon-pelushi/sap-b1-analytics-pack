-- SAP Business One Sample Schema
-- Core tables for analytics and reporting
-- This is a simplified schema for demonstration purposes

-- =====================================================
-- OITM: Items Master Data
-- =====================================================
CREATE TABLE OITM (
    ItemCode NVARCHAR(50) PRIMARY KEY,
    ItemName NVARCHAR(100) NOT NULL,
    FrgnName NVARCHAR(100),
    ItmsGrpCod INT,
    CstGrpCode INT,
    VatGourpSa NVARCHAR(20),
    CodeBars NVARCHAR(50),
    VATLiable NVARCHAR(1),
    PrchseItem NVARCHAR(1),
    SellItem NVARCHAR(1),
    InvntItem NVARCHAR(1),
    OnHand DECIMAL(19,6),
    IsCommited DECIMAL(19,6),
    OnOrder DECIMAL(19,6),
    AvgPrice DECIMAL(19,6),
    PurPackMsr NVARCHAR(20),
    SalPackMsr NVARCHAR(20),
    BuyUnitMsr NVARCHAR(20),
    NumInBuy DECIMAL(19,6),
    SalUnitMsr NVARCHAR(20),
    NumInSale DECIMAL(19,6),
    PurFactor1 DECIMAL(19,6),
    PurFactor2 DECIMAL(19,6),
    PurFactor3 DECIMAL(19,6),
    PurFactor4 DECIMAL(19,6),
    SalFactor1 DECIMAL(19,6),
    SalFactor2 DECIMAL(19,6),
    SalFactor3 DECIMAL(19,6),
    SalFactor4 DECIMAL(19,6),
    CreateDate DATETIME,
    UpdateDate DATETIME,
    FirmCode INT,
    validFor NVARCHAR(1),
    validFrom DATETIME,
    validTo DATETIME,
    ManBtchNum NVARCHAR(1),
    ManSerNum NVARCHAR(1),
    QryGroup1 NVARCHAR(1),
    QryGroup2 NVARCHAR(1),
    QryGroup3 NVARCHAR(1),
    QryGroup4 NVARCHAR(1)
);

-- =====================================================
-- OCRD: Business Partners Master Data
-- =====================================================
CREATE TABLE OCRD (
    CardCode NVARCHAR(50) PRIMARY KEY,
    CardName NVARCHAR(100) NOT NULL,
    CardType NVARCHAR(1) NOT NULL, -- C=Customer, S=Supplier, L=Lead
    GroupCode INT,
    CmpPrivate NVARCHAR(1),
    Address NVARCHAR(MAX),
    ZipCode NVARCHAR(20),
    MailAddres NVARCHAR(MAX),
    MailZipCod NVARCHAR(20),
    Phone1 NVARCHAR(20),
    Phone2 NVARCHAR(20),
    Fax NVARCHAR(20),
    CntctPrsn NVARCHAR(90),
    Notes NVARCHAR(MAX),
    Balance DECIMAL(19,6),
    ChecksBal DECIMAL(19,6),
    DNotesBal DECIMAL(19,6),
    OrdersBal DECIMAL(19,6),
    GroupNum INT,
    CreditLine DECIMAL(19,6),
    DebtLine DECIMAL(19,6),
    Discount DECIMAL(19,6),
    VatStatus NVARCHAR(1),
    Currency NVARCHAR(3),
    RateDifAct NVARCHAR(15),
    validFor NVARCHAR(1),
    validFrom DATETIME,
    validTo DATETIME,
    frozen NVARCHAR(1),
    CreateDate DATETIME,
    UpdateDate DATETIME,
    QryGroup1 NVARCHAR(1),
    QryGroup2 NVARCHAR(1),
    QryGroup3 NVARCHAR(1),
    QryGroup4 NVARCHAR(1)
);

-- =====================================================
-- ORDR: Sales Orders Header
-- =====================================================
CREATE TABLE ORDR (
    DocEntry INT PRIMARY KEY,
    DocNum INT NOT NULL,
    DocType NVARCHAR(1),
    CANCELED NVARCHAR(1),
    HandWrtten NVARCHAR(1),
    Printed NVARCHAR(1),
    DocStatus NVARCHAR(1), -- O=Open, C=Closed
    InvntSttus NVARCHAR(1),
    Transfered NVARCHAR(1),
    ObjType NVARCHAR(20),
    DocDate DATETIME NOT NULL,
    DocDueDate DATETIME,
    CardCode NVARCHAR(50),
    CardName NVARCHAR(100),
    Address NVARCHAR(MAX),
    NumAtCard NVARCHAR(100),
    DocTotal DECIMAL(19,6),
    DocTotalFC DECIMAL(19,6),
    PaidToDate DECIMAL(19,6),
    PaidFC DECIMAL(19,6),
    GrosProfit DECIMAL(19,6),
    DocCur NVARCHAR(3),
    DocRate DECIMAL(19,6),
    Comments NVARCHAR(MAX),
    SalesPerso INT,
    DocumentNo NVARCHAR(100),
    DocTotalSy DECIMAL(19,6),
    PaidSys DECIMAL(19,6),
    GrosProfSy DECIMAL(19,6),
    UpdateDate DATETIME,
    CreateDate DATETIME,
    TaxDate DATETIME,
    FinncPriod INT,
    UserSign INT,
    SlpCode INT,
    U_Priority NVARCHAR(10),
    U_Project NVARCHAR(50)
);

-- =====================================================
-- RDR1: Sales Orders Lines
-- =====================================================
CREATE TABLE RDR1 (
    DocEntry INT NOT NULL,
    LineNum INT NOT NULL,
    TargetType INT,
    TrgetEntry INT,
    BaseType INT,
    BaseEntry INT,
    BaseLine INT,
    LineStatus NVARCHAR(1), -- O=Open, C=Closed
    ItemCode NVARCHAR(50),
    Dscription NVARCHAR(200),
    Quantity DECIMAL(19,6),
    OpenQty DECIMAL(19,6),
    Price DECIMAL(19,6),
    Currency NVARCHAR(3),
    Rate DECIMAL(19,6),
    DiscPrcnt DECIMAL(19,6),
    LineTotal DECIMAL(19,6),
    TotalFrgn DECIMAL(19,6),
    OpenSum DECIMAL(19,6),
    OpenSumFC DECIMAL(19,6),
    VendorNum NVARCHAR(50),
    WhsCode NVARCHAR(8),
    SlpCode INT,
    Commission DECIMAL(19,6),
    TreeType NVARCHAR(1),
    AcctCode NVARCHAR(15),
    TaxCode NVARCHAR(8),
    TaxType NVARCHAR(1),
    TaxLiable NVARCHAR(1),
    ShipDate DATETIME,
    DelivrdQty DECIMAL(19,6),
    OrderedQty DECIMAL(19,6),
    CogsOcrCod NVARCHAR(8),
    CostCode NVARCHAR(8),
    GTotal DECIMAL(19,6),
    GrossBuyPr DECIMAL(19,6),
    unitMsr NVARCHAR(100),
    PRIMARY KEY (DocEntry, LineNum),
    FOREIGN KEY (DocEntry) REFERENCES ORDR(DocEntry)
);

-- =====================================================
-- OINV: A/R Invoices Header
-- =====================================================
CREATE TABLE OINV (
    DocEntry INT PRIMARY KEY,
    DocNum INT NOT NULL,
    DocType NVARCHAR(1),
    CANCELED NVARCHAR(1),
    HandWrtten NVARCHAR(1),
    Printed NVARCHAR(1),
    DocStatus NVARCHAR(1), -- O=Open, C=Closed
    InvntSttus NVARCHAR(1),
    Transfered NVARCHAR(1),
    ObjType NVARCHAR(20),
    DocDate DATETIME NOT NULL,
    DocDueDate DATETIME,
    CardCode NVARCHAR(50),
    CardName NVARCHAR(100),
    Address NVARCHAR(MAX),
    NumAtCard NVARCHAR(100),
    DocTotal DECIMAL(19,6),
    DocTotalFC DECIMAL(19,6),
    PaidToDate DECIMAL(19,6),
    PaidFC DECIMAL(19,6),
    GrosProfit DECIMAL(19,6),
    DocCur NVARCHAR(3),
    DocRate DECIMAL(19,6),
    Comments NVARCHAR(MAX),
    SalesPerso INT,
    DocumentNo NVARCHAR(100),
    DocTotalSy DECIMAL(19,6),
    PaidSys DECIMAL(19,6),
    GrosProfSy DECIMAL(19,6),
    UpdateDate DATETIME,
    CreateDate DATETIME,
    TaxDate DATETIME,
    FinncPriod INT,
    UserSign INT,
    SlpCode INT,
    U_PaymentTerms NVARCHAR(50),
    U_ShippingMethod NVARCHAR(50)
);

-- =====================================================
-- INV1: A/R Invoices Lines
-- =====================================================
CREATE TABLE INV1 (
    DocEntry INT NOT NULL,
    LineNum INT NOT NULL,
    TargetType INT,
    TrgetEntry INT,
    BaseType INT,
    BaseEntry INT,
    BaseLine INT,
    LineStatus NVARCHAR(1),
    ItemCode NVARCHAR(50),
    Dscription NVARCHAR(200),
    Quantity DECIMAL(19,6),
    Price DECIMAL(19,6),
    Currency NVARCHAR(3),
    Rate DECIMAL(19,6),
    DiscPrcnt DECIMAL(19,6),
    LineTotal DECIMAL(19,6),
    TotalFrgn DECIMAL(19,6),
    OpenSum DECIMAL(19,6),
    OpenSumFC DECIMAL(19,6),
    VendorNum NVARCHAR(50),
    WhsCode NVARCHAR(8),
    SlpCode INT,
    Commission DECIMAL(19,6),
    TreeType NVARCHAR(1),
    AcctCode NVARCHAR(15),
    TaxCode NVARCHAR(8),
    TaxType NVARCHAR(1),
    TaxLiable NVARCHAR(1),
    ShipDate DATETIME,
    CogsOcrCod NVARCHAR(8),
    CostCode NVARCHAR(8),
    GTotal DECIMAL(19,6),
    GrossBuyPr DECIMAL(19,6),
    unitMsr NVARCHAR(100),
    StockPrice DECIMAL(19,6),
    StockSum DECIMAL(19,6),
    PRIMARY KEY (DocEntry, LineNum),
    FOREIGN KEY (DocEntry) REFERENCES OINV(DocEntry)
);

-- =====================================================
-- ODLN: Deliveries Header
-- =====================================================
CREATE TABLE ODLN (
    DocEntry INT PRIMARY KEY,
    DocNum INT NOT NULL,
    DocType NVARCHAR(1),
    CANCELED NVARCHAR(1),
    HandWrtten NVARCHAR(1),
    Printed NVARCHAR(1),
    DocStatus NVARCHAR(1),
    InvntSttus NVARCHAR(1),
    Transfered NVARCHAR(1),
    ObjType NVARCHAR(20),
    DocDate DATETIME NOT NULL,
    DocDueDate DATETIME,
    CardCode NVARCHAR(50),
    CardName NVARCHAR(100),
    Address NVARCHAR(MAX),
    NumAtCard NVARCHAR(100),
    DocTotal DECIMAL(19,6),
    DocTotalFC DECIMAL(19,6),
    DocCur NVARCHAR(3),
    DocRate DECIMAL(19,6),
    Comments NVARCHAR(MAX),
    SalesPerso INT,
    DocumentNo NVARCHAR(100),
    UpdateDate DATETIME,
    CreateDate DATETIME,
    TaxDate DATETIME,
    FinncPriod INT,
    UserSign INT,
    SlpCode INT,
    U_ActualDeliveryDate DATETIME,
    U_PromisedDeliveryDate DATETIME
);

-- =====================================================
-- DLN1: Deliveries Lines
-- =====================================================
CREATE TABLE DLN1 (
    DocEntry INT NOT NULL,
    LineNum INT NOT NULL,
    TargetType INT,
    TrgetEntry INT,
    BaseType INT,
    BaseEntry INT,
    BaseLine INT,
    LineStatus NVARCHAR(1),
    ItemCode NVARCHAR(50),
    Dscription NVARCHAR(200),
    Quantity DECIMAL(19,6),
    Price DECIMAL(19,6),
    Currency NVARCHAR(3),
    Rate DECIMAL(19,6),
    DiscPrcnt DECIMAL(19,6),
    LineTotal DECIMAL(19,6),
    TotalFrgn DECIMAL(19,6),
    WhsCode NVARCHAR(8),
    SlpCode INT,
    Commission DECIMAL(19,6),
    TreeType NVARCHAR(1),
    AcctCode NVARCHAR(15),
    TaxCode NVARCHAR(8),
    ShipDate DATETIME,
    unitMsr NVARCHAR(100),
    PRIMARY KEY (DocEntry, LineNum),
    FOREIGN KEY (DocEntry) REFERENCES ODLN(DocEntry)
);

-- =====================================================
-- OWOR: Production Orders Header
-- =====================================================
CREATE TABLE OWOR (
    DocEntry INT PRIMARY KEY,
    DocNum INT NOT NULL,
    Series INT,
    ItemCode NVARCHAR(50),
    ProductCod NVARCHAR(50),
    Warehouse NVARCHAR(8),
    CardCode NVARCHAR(50),
    Status NVARCHAR(1), -- P=Planned, R=Released, C=Closed
    PlannedQty DECIMAL(19,6),
    CmpltQty DECIMAL(19,6),
    RjctQty DECIMAL(19,6),
    PostDate DATETIME,
    DueDate DATETIME,
    CloseDate DATETIME,
    RlsDate DATETIME,
    Type NVARCHAR(1), -- S=Standard, P=Production, D=Disassembly
    Priority INT,
    U_ProductionLine NVARCHAR(50),
    U_Shift NVARCHAR(20),
    U_PlannedStartTime DATETIME,
    U_ActualStartTime DATETIME,
    U_PlannedEndTime DATETIME,
    U_ActualEndTime DATETIME,
    U_DowntimeMinutes INT,
    U_ScrapQty DECIMAL(19,6),
    CreateDate DATETIME,
    UpdateDate DATETIME,
    UserSign INT,
    Comments NVARCHAR(MAX)
);

-- =====================================================
-- WOR1: Production Orders Lines (Components)
-- =====================================================
CREATE TABLE WOR1 (
    DocEntry INT NOT NULL,
    LineNum INT NOT NULL,
    ItemCode NVARCHAR(50),
    ItemType INT, -- 4=Items
    BaseQty DECIMAL(19,6),
    PlannedQty DECIMAL(19,6),
    IssuedQty DECIMAL(19,6),
    Warehouse NVARCHAR(8),
    IssueType NVARCHAR(1), -- M=Manual, B=Backflush
    LineText NVARCHAR(MAX),
    CreateDate DATETIME,
    UpdateDate DATETIME,
    PRIMARY KEY (DocEntry, LineNum),
    FOREIGN KEY (DocEntry) REFERENCES OWOR(DocEntry)
);

-- =====================================================
-- OITW: Items Warehouse Data
-- =====================================================
CREATE TABLE OITW (
    ItemCode NVARCHAR(50) NOT NULL,
    WhsCode NVARCHAR(8) NOT NULL,
    OnHand DECIMAL(19,6),
    IsCommited DECIMAL(19,6),
    OnOrder DECIMAL(19,6),
    Counted DECIMAL(19,6),
    WasCounted NVARCHAR(1),
    MinStock DECIMAL(19,6),
    MaxStock DECIMAL(19,6),
    MinOrder DECIMAL(19,6),
    AvgPrice DECIMAL(19,6),
    Locked NVARCHAR(1),
    BalInvntAc NVARCHAR(15),
    SalCostAc NVARCHAR(15),
    TransInvAc NVARCHAR(15),
    PRIMARY KEY (ItemCode, WhsCode)
);

-- Create indexes for common queries
CREATE INDEX IDX_ORDR_CardCode ON ORDR(CardCode);
CREATE INDEX IDX_ORDR_DocDate ON ORDR(DocDate);
CREATE INDEX IDX_ORDR_DocStatus ON ORDR(DocStatus);

CREATE INDEX IDX_RDR1_ItemCode ON RDR1(ItemCode);
CREATE INDEX IDX_RDR1_BaseEntry ON RDR1(BaseEntry);

CREATE INDEX IDX_OINV_CardCode ON OINV(CardCode);
CREATE INDEX IDX_OINV_DocDate ON OINV(DocDate);
CREATE INDEX IDX_OINV_DocStatus ON OINV(DocStatus);

CREATE INDEX IDX_INV1_ItemCode ON INV1(ItemCode);
CREATE INDEX IDX_INV1_BaseEntry ON INV1(BaseEntry);

CREATE INDEX IDX_ODLN_CardCode ON ODLN(CardCode);
CREATE INDEX IDX_ODLN_DocDate ON ODLN(DocDate);

CREATE INDEX IDX_DLN1_ItemCode ON DLN1(ItemCode);
CREATE INDEX IDX_DLN1_BaseEntry ON DLN1(BaseEntry);

CREATE INDEX IDX_OWOR_ItemCode ON OWOR(ItemCode);
CREATE INDEX IDX_OWOR_Status ON OWOR(Status);
CREATE INDEX IDX_OWOR_PostDate ON OWOR(PostDate);

CREATE INDEX IDX_OCRD_CardType ON OCRD(CardType);
CREATE INDEX IDX_OCRD_validFor ON OCRD(validFor);

CREATE INDEX IDX_OITM_ItmsGrpCod ON OITM(ItmsGrpCod);
CREATE INDEX IDX_OITM_validFor ON OITM(validFor);

