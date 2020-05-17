"""
Data Extraction from SAP B1
============================

Handles extraction of data from SAP Business One source database.
Supports full and incremental extracts.
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import pandas as pd

from etl.db import DatabaseConnection, QueryRunner

logger = logging.getLogger(__name__)


class SAPExtractor:
    """
    Extract data from SAP Business One source database.
    """
    
    def __init__(self, db_connection: DatabaseConnection, config: Dict[str, Any]):
        """
        Initialize SAP extractor.
        
        Args:
            db_connection: Database connection to SAP B1
            config: ETL configuration dictionary
        """
        self.db = db_connection
        self.query_runner = QueryRunner(db_connection)
        self.config = config
        self.batch_size = config.get("etl", {}).get("batch_size", 10000)
        
    def extract_customers(
        self,
        incremental: bool = False,
        lookback_days: int = 7,
    ) -> pd.DataFrame:
        """
        Extract customer master data from OCRD.
        
        Args:
            incremental: If True, extract only recently changed records
            lookback_days: Days to look back for incremental extract
            
        Returns:
            DataFrame with customer data
        """
        logger.info("Extracting customer data from SAP B1")
        
        query = """
            SELECT 
                CardCode,
                CardName,
                CardType,
                GroupCode,
                Address,
                ZipCode,
                Phone1,
                Phone2,
                Fax,
                CntctPrsn,
                Balance,
                ChecksBal,
                DNotesBal,
                OrdersBal,
                GroupNum,
                CreditLine,
                DebtLine,
                Discount,
                VatStatus,
                Currency,
                validFor,
                validFrom,
                validTo,
                frozen,
                CreateDate,
                UpdateDate,
                QryGroup1,
                QryGroup2,
                QryGroup3,
                QryGroup4
            FROM OCRD
            WHERE CardType = 'C'  -- Customers only
        """
        
        if incremental:
            cutoff_date = datetime.now() - timedelta(days=lookback_days)
            query += f" AND UpdateDate >= '{cutoff_date.strftime('%Y-%m-%d')}'"
            logger.info(f"Incremental extract from {cutoff_date}")
        
        df = self.query_runner.execute_to_dataframe(query)
        logger.info(f"Extracted {len(df)} customers")
        
        return df
    
    def extract_items(
        self,
        incremental: bool = False,
        lookback_days: int = 7,
    ) -> pd.DataFrame:
        """
        Extract item master data from OITM.
        
        Args:
            incremental: If True, extract only recently changed records
            lookback_days: Days to look back for incremental extract
            
        Returns:
            DataFrame with item data
        """
        logger.info("Extracting item data from SAP B1")
        
        query = """
            SELECT 
                ItemCode,
                ItemName,
                FrgnName,
                ItmsGrpCod,
                CstGrpCode,
                VatGourpSa,
                CodeBars,
                VATLiable,
                PrchseItem,
                SellItem,
                InvntItem,
                OnHand,
                IsCommited,
                OnOrder,
                AvgPrice,
                PurPackMsr,
                SalPackMsr,
                BuyUnitMsr,
                NumInBuy,
                SalUnitMsr,
                NumInSale,
                CreateDate,
                UpdateDate,
                FirmCode,
                validFor,
                validFrom,
                validTo,
                ManBtchNum,
                ManSerNum,
                QryGroup1,
                QryGroup2,
                QryGroup3,
                QryGroup4
            FROM OITM
        """
        
        if incremental:
            cutoff_date = datetime.now() - timedelta(days=lookback_days)
            query += f" WHERE UpdateDate >= '{cutoff_date.strftime('%Y-%m-%d')}'"
            logger.info(f"Incremental extract from {cutoff_date}")
        
        df = self.query_runner.execute_to_dataframe(query)
        logger.info(f"Extracted {len(df)} items")
        
        return df
    
    def extract_sales_orders(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> pd.DataFrame:
        """
        Extract sales orders from ORDR and RDR1.
        
        Args:
            start_date: Start date for extraction
            end_date: End date for extraction
            
        Returns:
            DataFrame with sales order data
        """
        logger.info("Extracting sales orders from SAP B1")
        
        query = """
            SELECT 
                h.DocEntry,
                h.DocNum,
                h.DocType,
                h.CANCELED,
                h.DocStatus,
                h.DocDate,
                h.DocDueDate,
                h.CardCode,
                h.CardName,
                h.NumAtCard,
                h.DocTotal,
                h.DocTotalFC,
                h.PaidToDate,
                h.DocCur,
                h.DocRate,
                h.Comments,
                h.SlpCode,
                h.CreateDate,
                h.UpdateDate,
                
                l.LineNum,
                l.ItemCode,
                l.Dscription,
                l.Quantity,
                l.OpenQty,
                l.Price,
                l.DiscPrcnt,
                l.LineTotal,
                l.WhsCode,
                l.ShipDate,
                l.DelivrdQty,
                l.OrderedQty,
                l.GrossBuyPr
            FROM ORDR h
            INNER JOIN RDR1 l ON h.DocEntry = l.DocEntry
        """
        
        conditions = []
        if start_date:
            conditions.append(f"h.DocDate >= '{start_date.strftime('%Y-%m-%d')}'")
        if end_date:
            conditions.append(f"h.DocDate <= '{end_date.strftime('%Y-%m-%d')}'")
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        df = self.query_runner.execute_to_dataframe(query, chunksize=self.batch_size)
        logger.info(f"Extracted {len(df)} sales order lines")
        
        return df
    
    def extract_invoices(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> pd.DataFrame:
        """
        Extract AR invoices from OINV and INV1.
        
        Args:
            start_date: Start date for extraction
            end_date: End date for extraction
            
        Returns:
            DataFrame with invoice data
        """
        logger.info("Extracting invoices from SAP B1")
        
        query = """
            SELECT 
                h.DocEntry,
                h.DocNum,
                h.DocType,
                h.CANCELED,
                h.DocStatus,
                h.DocDate,
                h.DocDueDate,
                h.CardCode,
                h.CardName,
                h.NumAtCard,
                h.DocTotal,
                h.DocTotalFC,
                h.PaidToDate,
                h.GrosProfit,
                h.DocCur,
                h.DocRate,
                h.SlpCode,
                h.CreateDate,
                h.UpdateDate,
                
                l.LineNum,
                l.ItemCode,
                l.Dscription,
                l.Quantity,
                l.Price,
                l.DiscPrcnt,
                l.LineTotal,
                l.WhsCode,
                l.ShipDate,
                l.GrossBuyPr,
                l.StockPrice,
                l.BaseEntry,
                l.BaseLine,
                l.BaseType
            FROM OINV h
            INNER JOIN INV1 l ON h.DocEntry = l.DocEntry
        """
        
        conditions = []
        if start_date:
            conditions.append(f"h.DocDate >= '{start_date.strftime('%Y-%m-%d')}'")
        if end_date:
            conditions.append(f"h.DocDate <= '{end_date.strftime('%Y-%m-%d')}'")
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        df = self.query_runner.execute_to_dataframe(query, chunksize=self.batch_size)
        logger.info(f"Extracted {len(df)} invoice lines")
        
        return df
    
    def extract_deliveries(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> pd.DataFrame:
        """
        Extract deliveries from ODLN and DLN1.
        
        Args:
            start_date: Start date for extraction
            end_date: End date for extraction
            
        Returns:
            DataFrame with delivery data
        """
        logger.info("Extracting deliveries from SAP B1")
        
        query = """
            SELECT 
                h.DocEntry,
                h.DocNum,
                h.DocType,
                h.CANCELED,
                h.DocStatus,
                h.DocDate,
                h.DocDueDate,
                h.CardCode,
                h.CardName,
                h.NumAtCard,
                h.DocTotal,
                h.DocCur,
                h.DocRate,
                h.SlpCode,
                h.CreateDate,
                h.UpdateDate,
                h.U_ActualDeliveryDate,
                h.U_PromisedDeliveryDate,
                
                l.LineNum,
                l.ItemCode,
                l.Dscription,
                l.Quantity,
                l.Price,
                l.DiscPrcnt,
                l.LineTotal,
                l.WhsCode,
                l.ShipDate,
                l.BaseEntry,
                l.BaseLine,
                l.BaseType
            FROM ODLN h
            INNER JOIN DLN1 l ON h.DocEntry = l.DocEntry
        """
        
        conditions = []
        if start_date:
            conditions.append(f"h.DocDate >= '{start_date.strftime('%Y-%m-%d')}'")
        if end_date:
            conditions.append(f"h.DocDate <= '{end_date.strftime('%Y-%m-%d')}'")
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        df = self.query_runner.execute_to_dataframe(query, chunksize=self.batch_size)
        logger.info(f"Extracted {len(df)} delivery lines")
        
        return df
    
    def extract_production_orders(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> pd.DataFrame:
        """
        Extract production orders from OWOR.
        
        Args:
            start_date: Start date for extraction
            end_date: End date for extraction
            
        Returns:
            DataFrame with production order data
        """
        logger.info("Extracting production orders from SAP B1")
        
        query = """
            SELECT 
                DocEntry,
                DocNum,
                Series,
                ItemCode,
                ProductCod,
                Warehouse,
                Status,
                PlannedQty,
                CmpltQty,
                RjctQty,
                PostDate,
                DueDate,
                CloseDate,
                RlsDate,
                Type,
                Priority,
                U_ProductionLine,
                U_Shift,
                U_PlannedStartTime,
                U_ActualStartTime,
                U_PlannedEndTime,
                U_ActualEndTime,
                U_DowntimeMinutes,
                U_ScrapQty,
                CreateDate,
                UpdateDate,
                UserSign,
                Comments
            FROM OWOR
        """
        
        conditions = []
        if start_date:
            conditions.append(f"PostDate >= '{start_date.strftime('%Y-%m-%d')}'")
        if end_date:
            conditions.append(f"PostDate <= '{end_date.strftime('%Y-%m-%d')}'")
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        df = self.query_runner.execute_to_dataframe(query)
        logger.info(f"Extracted {len(df)} production orders")
        
        return df
    
    def extract_inventory_snapshot(self) -> pd.DataFrame:
        """
        Extract current inventory levels from OITW.
        
        Returns:
            DataFrame with inventory data
        """
        logger.info("Extracting inventory snapshot from SAP B1")
        
        query = """
            SELECT 
                ItemCode,
                WhsCode,
                OnHand,
                IsCommited,
                OnOrder,
                Counted,
                WasCounted,
                MinStock,
                MaxStock,
                MinOrder,
                AvgPrice,
                Locked
            FROM OITW
            WHERE OnHand > 0
        """
        
        df = self.query_runner.execute_to_dataframe(query)
        logger.info(f"Extracted inventory for {len(df)} item-warehouse combinations")
        
        return df
    
    def get_max_date(
        self,
        table: str,
        date_field: str,
        where_clause: Optional[str] = None,
    ) -> Optional[datetime]:
        """
        Get maximum date from a table for incremental loading.
        
        Args:
            table: Table name
            date_field: Date field name
            where_clause: Optional WHERE clause
            
        Returns:
            Maximum date or None if no data
        """
        query = f"SELECT MAX({date_field}) as max_date FROM {table}"
        if where_clause:
            query += f" WHERE {where_clause}"
        
        result = self.query_runner.execute_query(query)
        max_date = result[0]["max_date"] if result and result[0]["max_date"] else None
        
        if max_date:
            logger.info(f"Max date from {table}.{date_field}: {max_date}")
        else:
            logger.info(f"No data found in {table}")
        
        return max_date


# Updated: 2025-11-10 10:43:00

# Updated: 2025-11-11 12:45:00

# Updated: 2025-11-15 14:05:00

# Updated: 2025-11-15 16:49:00

# Updated: 2025-11-15 20:39:00

# Updated: 2025-11-17 12:29:00

# Updated: 2025-11-18 12:35:00

# Updated: 2025-11-18 14:06:00

# Updated: 2025-11-18 20:47:00

# Updated: 2025-11-22 10:15:00

# Updated: 2025-11-24 08:06:00

# Updated: 2025-11-24 12:43:00

# Updated: 2025-11-26 12:05:00

# Updated: 2025-11-27 16:21:00

# Updated: 2025-11-28 14:02:00

# Updated: 2025-12-01 18:56:00

# Updated: 2025-12-02 16:24:00

# Updated: 2025-12-03 18:50:00

# Updated: 2025-12-04 14:48:00

# Updated: 2025-12-05 10:19:00

# Updated: 2025-12-06 18:50:00

# Updated: 2025-12-07 08:59:00

# Updated: 2025-12-07 12:44:00

# Updated: 2025-12-10 18:48:00

# Updated: 2025-12-11 18:21:00

# Updated: 2025-12-12 14:03:00

# Updated: 2025-12-13 12:21:00

# Updated: 2025-12-14 12:50:00

# Updated: 2025-12-18 14:18:00

<!-- Update 0 -->

<!-- Update 3 -->

<!-- Update 10 -->

<!-- Update 11 -->

<!-- Update 12 -->

<!-- Update 13 -->

<!-- Update 20 -->

<!-- Update 22 -->

<!-- Update 23 -->

<!-- Update 26 -->

<!-- Update 32 -->

<!-- Update 38 -->

<!-- Update 40 -->

<!-- Update 44 -->

<!-- Update 45 -->

<!-- Update 47 -->

<!-- Update 49 -->

<!-- Update 51 -->

<!-- Update 52 -->

<!-- Update 62 -->

<!-- Update 63 -->

<!-- Update 76 -->

<!-- Update 86 -->

<!-- Update 88 -->

<!-- Update 89 -->

<!-- Update 92 -->

<!-- Update 98 -->

<!-- Update 101 -->

<!-- Update 102 -->

<!-- Update 103 -->

<!-- Update 104 -->

<!-- Update 113 -->

<!-- Update 114 -->

<!-- Update 118 -->

<!-- Update 126 -->

<!-- Update 129 -->

<!-- Update 132 -->

<!-- Update 133 -->

<!-- Update 140 -->

<!-- Update 150 -->

<!-- Update 154 -->

<!-- Update 155 -->

<!-- Update 157 -->

<!-- Update 165 -->

<!-- Update 172 -->

<!-- Update 174 -->

<!-- Update 177 -->

<!-- Update 181 -->

<!-- Update 182 -->

<!-- Update 187 -->

<!-- Update 195 -->

<!-- Update 197 -->

<!-- Update 199 -->

<!-- Update 205 -->

<!-- Update 210 -->

<!-- Update 215 -->

<!-- Update 216 -->

<!-- Update 221 -->

<!-- Update 224 -->

<!-- Update 230 -->

<!-- Update 233 -->

<!-- Update 234 -->

<!-- Update 239 -->

<!-- Update 242 -->

<!-- Update 247 -->

<!-- Update 248 -->

<!-- Update 257 -->

<!-- Update 261 -->

<!-- Update 265 -->

<!-- Update 273 -->

<!-- Update 275 -->

<!-- Update 277 -->

<!-- Update 278 -->

<!-- Update 280 -->

<!-- Update 281 -->

<!-- Update 283 -->

<!-- Update 286 -->

<!-- Update 291 -->

<!-- Update 292 -->

<!-- Update 293 -->

<!-- Update 299 -->

<!-- Update 300 -->
