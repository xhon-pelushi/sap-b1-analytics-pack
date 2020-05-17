"""
Data Transformation and Business Logic
=======================================

Applies business rules, data cleansing, and transformations
to prepare data for the analytics layer.
"""

import logging
from typing import Dict, Any, Optional
import pandas as pd
import numpy as np
from datetime import datetime

logger = logging.getLogger(__name__)


class DataTransformer:
    """
    Transform and cleanse data according to business rules.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize data transformer.
        
        Args:
            config: ETL configuration dictionary
        """
        self.config = config
        self.transformations = config.get("etl", {}).get("transformations", {})
        
    def transform_customers(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Transform customer data for dimension table.
        
        Args:
            df: Raw customer DataFrame from OCRD
            
        Returns:
            Transformed DataFrame ready for dim_customer
        """
        logger.info(f"Transforming {len(df)} customers")
        
        # Create a copy to avoid modifying original
        transformed = df.copy()
        
        # Card type description
        transformed["card_type_desc"] = transformed["CardType"].map({
            "C": "Customer",
            "S": "Supplier",
            "L": "Lead",
        })
        
        # Customer tier based on credit line
        transformed["customer_tier"] = pd.cut(
            transformed["CreditLine"],
            bins=[0, 50000, 100000, 150000, float("inf")],
            labels=["D", "C", "B", "A"],
            include_lowest=True,
        )
        
        # Customer segment
        conditions = [
            transformed["CreditLine"] >= 150000,
            transformed["CreditLine"] >= 75000,
            transformed["CreditLine"] < 75000,
        ]
        choices = ["Enterprise", "Mid-Market", "SMB"]
        transformed["customer_segment"] = np.select(conditions, choices, default="SMB")
        
        # Active status
        transformed["is_active"] = (
            (transformed["validFor"] == "Y") & (transformed["frozen"] == "N")
        ).astype(int)
        
        # Extract geographic information from address (simplified)
        # In production, you'd use more sophisticated parsing
        transformed["region"] = "North America"  # Default
        transformed["country"] = "USA"  # Default
        transformed["state_province"] = None
        transformed["city"] = None
        
        # Rename columns to match target schema
        column_mapping = {
            "CardCode": "card_code",
            "CardName": "card_name",
            "CardType": "card_type",
            "GroupCode": "group_code",
            "Address": "address",
            "ZipCode": "zip_code",
            "Phone1": "phone_1",
            "Phone2": "phone_2",
            "Fax": "fax",
            "CntctPrsn": "contact_person",
            "CreditLine": "credit_line",
            "DebtLine": "debt_line",
            "Discount": "discount_percent",
            "Currency": "currency",
            "VatStatus": "vat_status",
            "validFor": "valid_for",
            "frozen": "frozen",
            "CreateDate": "source_created_date",
            "UpdateDate": "source_updated_date",
        }
        
        transformed = transformed.rename(columns=column_mapping)
        
        # Add SCD Type 2 fields
        transformed["effective_date"] = datetime.now()
        transformed["end_date"] = None
        transformed["is_current"] = 1
        
        logger.info(f"Customer transformation complete: {len(transformed)} records")
        
        return transformed
    
    def transform_items(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Transform item data for dimension table.
        
        Args:
            df: Raw item DataFrame from OITM
            
        Returns:
            Transformed DataFrame ready for dim_item
        """
        logger.info(f"Transforming {len(df)} items")
        
        transformed = df.copy()
        
        # Price tier classification
        transformed["price_tier"] = pd.cut(
            transformed["AvgPrice"],
            bins=[0, 50, 200, 500, float("inf")],
            labels=["Budget", "Standard", "Premium", "Luxury"],
            include_lowest=True,
        )
        
        # Item category based on item group (customize for your groups)
        category_map = {
            101: "Electronics",
            102: "Electronics",
            103: "Furniture",
        }
        transformed["item_category"] = transformed["ItmsGrpCod"].map(category_map).fillna("Other")
        
        # Product status
        transformed["product_status"] = np.where(
            transformed["validFor"] == "Y",
            "Active",
            "Discontinued",
        )
        
        # Active flag
        transformed["is_active"] = (transformed["validFor"] == "Y").astype(int)
        
        # Binary flags
        transformed["purchase_item"] = (transformed["PrchseItem"] == "Y").astype(int)
        transformed["sell_item"] = (transformed["SellItem"] == "Y").astype(int)
        transformed["inventory_item"] = (transformed["InvntItem"] == "Y").astype(int)
        transformed["manage_batch_numbers"] = (transformed["ManBtchNum"] == "Y").astype(int)
        transformed["manage_serial_numbers"] = (transformed["ManSerNum"] == "Y").astype(int)
        
        # Rename columns
        column_mapping = {
            "ItemCode": "item_code",
            "ItemName": "item_name",
            "FrgnName": "foreign_name",
            "ItmsGrpCod": "item_group_code",
            "AvgPrice": "avg_price",
            "PurPackMsr": "purchase_unit",
            "SalPackMsr": "sales_unit",
            "CreateDate": "source_created_date",
            "UpdateDate": "source_updated_date",
        }
        
        transformed = transformed.rename(columns=column_mapping)
        
        # Add SCD Type 2 fields
        transformed["effective_date"] = datetime.now()
        transformed["end_date"] = None
        transformed["is_current"] = 1
        
        logger.info(f"Item transformation complete: {len(transformed)} records")
        
        return transformed
    
    def transform_sales(
        self,
        invoices: pd.DataFrame,
        customer_dim: pd.DataFrame,
        item_dim: pd.DataFrame,
    ) -> pd.DataFrame:
        """
        Transform invoice data for fact_sales table.
        
        Args:
            invoices: Raw invoice DataFrame from OINV/INV1
            customer_dim: Customer dimension DataFrame
            item_dim: Item dimension DataFrame
            
        Returns:
            Transformed DataFrame ready for fact_sales
        """
        logger.info(f"Transforming {len(invoices)} invoice lines")
        
        transformed = invoices.copy()
        
        # Join with dimension tables to get surrogate keys
        transformed = transformed.merge(
            customer_dim[["card_code", "customer_key"]],
            left_on="CardCode",
            right_on="card_code",
            how="left",
        )
        
        transformed = transformed.merge(
            item_dim[["item_code", "item_key"]],
            left_on="ItemCode",
            right_on="item_code",
            how="left",
        )
        
        # Calculate date keys (YYYYMMDD format)
        transformed["invoice_date_key"] = pd.to_datetime(
            transformed["DocDate"]
        ).dt.strftime("%Y%m%d").astype(int)
        
        transformed["order_date_key"] = transformed["invoice_date_key"]  # Same for invoices
        
        # Calculate margins
        transformed["total_cost"] = transformed["Quantity"] * transformed["GrossBuyPr"]
        transformed["gross_profit"] = transformed["LineTotal"] - transformed["total_cost"]
        transformed["gross_margin_percent"] = np.where(
            transformed["LineTotal"] > 0,
            (transformed["gross_profit"] / transformed["LineTotal"]) * 100,
            0,
        )
        
        # Status flags
        transformed["is_canceled"] = (transformed["CANCELED"] == "Y").astype(int)
        transformed["is_return"] = 0  # Would check document type for credit memos
        
        # Rename columns
        column_mapping = {
            "DocEntry": "invoice_doc_entry",
            "DocNum": "invoice_doc_num",
            "LineNum": "invoice_line_num",
            "BaseEntry": "order_doc_entry",
            "NumAtCard": "customer_po_number",
            "SlpCode": "sales_person_code",
            "WhsCode": "warehouse_code",
            "Quantity": "quantity",
            "Price": "unit_price",
            "DiscPrcnt": "discount_percent",
            "LineTotal": "line_total",
            "GrossBuyPr": "unit_cost",
            "DocCur": "document_currency",
            "DocRate": "currency_rate",
            "DocStatus": "document_status",
            "ShipDate": "ship_date",
        }
        
        transformed = transformed.rename(columns=column_mapping)
        
        # System currency amounts (assuming USD as system currency)
        transformed["line_total_sys"] = transformed["line_total"] * transformed["currency_rate"]
        transformed["total_cost_sys"] = transformed["total_cost"] * transformed["currency_rate"]
        transformed["gross_profit_sys"] = transformed["gross_profit"] * transformed["currency_rate"]
        
        logger.info(f"Sales transformation complete: {len(transformed)} records")
        
        return transformed
    
    def transform_deliveries(
        self,
        deliveries: pd.DataFrame,
        customer_dim: pd.DataFrame,
        item_dim: pd.DataFrame,
    ) -> pd.DataFrame:
        """
        Transform delivery data for fact_delivery table.
        
        Args:
            deliveries: Raw delivery DataFrame from ODLN/DLN1
            customer_dim: Customer dimension DataFrame
            item_dim: Item dimension DataFrame
            
        Returns:
            Transformed DataFrame ready for fact_delivery
        """
        logger.info(f"Transforming {len(deliveries)} delivery lines")
        
        transformed = deliveries.copy()
        
        # Join with dimension tables
        transformed = transformed.merge(
            customer_dim[["card_code", "customer_key", "customer_tier", "customer_segment"]],
            left_on="CardCode",
            right_on="card_code",
            how="left",
        )
        
        transformed = transformed.merge(
            item_dim[["item_code", "item_key", "item_category", "abc_class"]],
            left_on="ItemCode",
            right_on="item_code",
            how="left",
        )
        
        # Calculate date keys
        transformed["delivery_date_key"] = pd.to_datetime(
            transformed["DocDate"]
        ).dt.strftime("%Y%m%d").astype(int)
        
        transformed["promised_date_key"] = pd.to_datetime(
            transformed["U_PromisedDeliveryDate"]
        ).dt.strftime("%Y%m%d").astype(int)
        
        # On-Time Delivery calculations
        transformed["delivery_delay_days"] = (
            pd.to_datetime(transformed["U_ActualDeliveryDate"]) -
            pd.to_datetime(transformed["U_PromisedDeliveryDate"])
        ).dt.days
        
        transformed["is_on_time_delivery"] = (transformed["delivery_delay_days"] <= 0).astype(int)
        transformed["is_early_delivery"] = (transformed["delivery_delay_days"] < 0).astype(int)
        transformed["is_late_delivery"] = (transformed["delivery_delay_days"] > 0).astype(int)
        
        # Performance categories
        conditions = [
            transformed["delivery_delay_days"] <= 0,
            transformed["delivery_delay_days"].between(1, 3),
            transformed["delivery_delay_days"] > 3,
        ]
        choices = ["On-Time", "Late", "Very Late"]
        transformed["delivery_performance_category"] = np.select(
            conditions, choices, default="Unknown"
        )
        
        # Status flags
        transformed["is_canceled"] = (transformed["CANCELED"] == "Y").astype(int)
        
        # Rename columns
        column_mapping = {
            "DocEntry": "delivery_doc_entry",
            "DocNum": "delivery_doc_num",
            "LineNum": "delivery_line_num",
            "BaseEntry": "order_doc_entry",
            "NumAtCard": "customer_po_number",
            "SlpCode": "sales_person_code",
            "WhsCode": "warehouse_code",
            "Quantity": "quantity",
            "Price": "unit_price",
            "DiscPrcnt": "discount_percent",
            "LineTotal": "line_total",
            "DocCur": "document_currency",
            "DocRate": "currency_rate",
            "DocStatus": "document_status",
            "U_ActualDeliveryDate": "actual_delivery_date",
            "U_PromisedDeliveryDate": "promised_delivery_date",
        }
        
        transformed = transformed.rename(columns=column_mapping)
        
        # System currency amount
        transformed["line_total_sys"] = transformed["line_total"] * transformed["currency_rate"]
        
        logger.info(f"Delivery transformation complete: {len(transformed)} records")
        
        return transformed
    
    def cleanse_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Apply general data cleansing rules.
        
        Args:
            df: DataFrame to cleanse
            
        Returns:
            Cleansed DataFrame
        """
        logger.info(f"Cleansing data: {len(df)} records")
        
        # Remove duplicates
        initial_count = len(df)
        df = df.drop_duplicates()
        if len(df) < initial_count:
            logger.warning(f"Removed {initial_count - len(df)} duplicate records")
        
        # Handle missing values (strategy depends on column type)
        # For numeric columns, fill with 0
        numeric_columns = df.select_dtypes(include=[np.number]).columns
        df[numeric_columns] = df[numeric_columns].fillna(0)
        
        # For string columns, fill with empty string
        string_columns = df.select_dtypes(include=[object]).columns
        df[string_columns] = df[string_columns].fillna("")
        
        # Trim whitespace from string columns
        for col in string_columns:
            df[col] = df[col].str.strip()
        
        # Remove records with invalid keys (if specified in config)
        # This is a placeholder for business-specific validation
        
        logger.info(f"Data cleansing complete: {len(df)} records")
        
        return df
    
    def validate_data_quality(
        self,
        df: pd.DataFrame,
        required_columns: list,
        max_error_rate: float = 0.05,
    ) -> tuple[pd.DataFrame, bool]:
        """
        Validate data quality and flag errors.
        
        Args:
            df: DataFrame to validate
            required_columns: List of required column names
            max_error_rate: Maximum acceptable error rate
            
        Returns:
            Tuple of (validated DataFrame, quality_passed boolean)
        """
        logger.info(f"Validating data quality for {len(df)} records")
        
        # Check required columns exist
        missing_columns = set(required_columns) - set(df.columns)
        if missing_columns:
            logger.error(f"Missing required columns: {missing_columns}")
            return df, False
        
        # Check for null values in required columns
        null_counts = df[required_columns].isnull().sum()
        error_count = null_counts.sum()
        error_rate = error_count / (len(df) * len(required_columns))
        
        logger.info(f"Data quality error rate: {error_rate:.2%}")
        
        quality_passed = error_rate <= max_error_rate
        
        if not quality_passed:
            logger.warning(
                f"Data quality check failed: error rate {error_rate:.2%} "
                f"exceeds threshold {max_error_rate:.2%}"
            )
        
        return df, quality_passed


# Updated: 2025-11-11 16:30:00

# Updated: 2025-11-13 16:16:00

# Updated: 2025-11-13 22:59:00

# Updated: 2025-11-14 16:15:00

# Updated: 2025-11-15 10:31:00

# Updated: 2025-11-17 18:34:00

# Updated: 2025-11-18 18:14:00

# Updated: 2025-11-22 22:38:00

# Updated: 2025-11-24 10:58:00

# Updated: 2025-11-24 16:00:00

# Updated: 2025-11-25 08:17:00

# Updated: 2025-11-26 10:05:00

# Updated: 2025-11-26 20:33:00

# Updated: 2025-11-29 14:31:00

# Updated: 2025-11-29 20:28:00

# Updated: 2025-11-29 22:12:00

# Updated: 2025-11-30 18:48:00

# Updated: 2025-12-01 16:40:00

# Updated: 2025-12-14 18:19:00

# Updated: 2025-12-15 16:58:00
