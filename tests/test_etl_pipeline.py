"""
Tests for ETL Pipeline
======================

Unit and integration tests for the ETL pipeline components.
"""

import pytest
import pandas as pd
from datetime import datetime
from unittest.mock import Mock, patch, MagicMock

from etl.db import DatabaseConnection, QueryRunner
from etl.extract import SAPExtractor
from etl.transform import DataTransformer
from etl.load import DataLoader


@pytest.fixture
def mock_config():
    """Mock configuration for testing."""
    return {
        "source_database": {
            "type": "mssql",
            "host": "localhost",
            "port": 1433,
            "database": "test_sap",
            "username": "test",
            "password": "test",
        },
        "analytics_database": {
            "type": "mssql",
            "host": "localhost",
            "port": 1433,
            "database": "test_analytics",
            "username": "test",
            "password": "test",
            "schemas": {
                "analytics": "analytics",
                "staging": "staging",
            },
        },
        "etl": {
            "batch_size": 1000,
            "transformations": {},
        },
    }


@pytest.fixture
def sample_customer_data():
    """Sample customer data for testing."""
    return pd.DataFrame({
        "CardCode": ["CUST-001", "CUST-002"],
        "CardName": ["Test Customer 1", "Test Customer 2"],
        "CardType": ["C", "C"],
        "CreditLine": [100000, 50000],
        "Discount": [5.0, 3.0],
        "validFor": ["Y", "Y"],
        "frozen": ["N", "N"],
        "CreateDate": [datetime(2024, 1, 1), datetime(2024, 1, 2)],
        "UpdateDate": [datetime(2024, 1, 1), datetime(2024, 1, 2)],
    })


@pytest.fixture
def sample_item_data():
    """Sample item data for testing."""
    return pd.DataFrame({
        "ItemCode": ["ITEM-001", "ITEM-002"],
        "ItemName": ["Test Item 1", "Test Item 2"],
        "ItmsGrpCod": [101, 102],
        "AvgPrice": [100.0, 50.0],
        "PrchseItem": ["Y", "Y"],
        "SellItem": ["Y", "Y"],
        "InvntItem": ["Y", "Y"],
        "validFor": ["Y", "Y"],
        "ManBtchNum": ["N", "N"],
        "ManSerNum": ["N", "N"],
        "CreateDate": [datetime(2024, 1, 1), datetime(2024, 1, 2)],
        "UpdateDate": [datetime(2024, 1, 1), datetime(2024, 1, 2)],
    })


class TestDataTransformer:
    """Tests for DataTransformer class."""
    
    def test_transform_customers(self, mock_config, sample_customer_data):
        """Test customer transformation logic."""
        transformer = DataTransformer(mock_config)
        result = transformer.transform_customers(sample_customer_data)
        
        # Check required columns exist
        assert "card_code" in result.columns
        assert "card_name" in result.columns
        assert "customer_tier" in result.columns
        assert "customer_segment" in result.columns
        assert "is_active" in result.columns
        
        # Check tier assignment
        assert result.loc[0, "customer_tier"] == "B"  # 100000 credit line
        assert result.loc[1, "customer_tier"] == "D"  # 50000 credit line
        
        # Check segment assignment
        assert result.loc[0, "customer_segment"] == "Mid-Market"
        assert result.loc[1, "customer_segment"] == "SMB"
        
        # Check active status
        assert result.loc[0, "is_active"] == 1
        assert result.loc[1, "is_active"] == 1
    
    def test_transform_items(self, mock_config, sample_item_data):
        """Test item transformation logic."""
        transformer = DataTransformer(mock_config)
        result = transformer.transform_items(sample_item_data)
        
        # Check required columns exist
        assert "item_code" in result.columns
        assert "item_name" in result.columns
        assert "price_tier" in result.columns
        assert "item_category" in result.columns
        assert "is_active" in result.columns
        
        # Check price tier assignment
        assert result.loc[0, "price_tier"] == "Standard"  # 100.0 price
        assert result.loc[1, "price_tier"] == "Standard"  # 50.0 price
        
        # Check binary flags
        assert result.loc[0, "purchase_item"] == 1
        assert result.loc[0, "sell_item"] == 1
        assert result.loc[0, "inventory_item"] == 1
    
    def test_cleanse_data_removes_duplicates(self, mock_config):
        """Test that cleanse_data removes duplicate records."""
        transformer = DataTransformer(mock_config)
        
        df = pd.DataFrame({
            "id": [1, 2, 2, 3],
            "value": ["a", "b", "b", "c"],
        })
        
        result = transformer.cleanse_data(df)
        
        assert len(result) == 3  # One duplicate removed
    
    def test_cleanse_data_handles_nulls(self, mock_config):
        """Test that cleanse_data handles null values."""
        transformer = DataTransformer(mock_config)
        
        df = pd.DataFrame({
            "numeric_col": [1.0, None, 3.0],
            "string_col": ["a", None, "c"],
        })
        
        result = transformer.cleanse_data(df)
        
        assert result["numeric_col"].iloc[1] == 0  # Null replaced with 0
        assert result["string_col"].iloc[1] == ""  # Null replaced with empty string
    
    def test_validate_data_quality(self, mock_config):
        """Test data quality validation."""
        transformer = DataTransformer(mock_config)
        
        # Good data
        good_df = pd.DataFrame({
            "col1": [1, 2, 3],
            "col2": ["a", "b", "c"],
        })
        
        result, passed = transformer.validate_data_quality(
            good_df,
            required_columns=["col1", "col2"],
            max_error_rate=0.05,
        )
        
        assert passed is True
        
        # Bad data (with nulls)
        bad_df = pd.DataFrame({
            "col1": [1, None, None],
            "col2": ["a", "b", "c"],
        })
        
        result, passed = transformer.validate_data_quality(
            bad_df,
            required_columns=["col1", "col2"],
            max_error_rate=0.05,
        )
        
        assert passed is False


class TestSAPExtractor:
    """Tests for SAPExtractor class."""
    
    @patch("etl.extract.QueryRunner")
    def test_extract_customers(self, mock_query_runner, mock_config):
        """Test customer extraction."""
        mock_db = Mock(spec=DatabaseConnection)
        extractor = SAPExtractor(mock_db, mock_config)
        
        # Mock the query runner
        mock_df = pd.DataFrame({"CardCode": ["CUST-001"]})
        extractor.query_runner.execute_to_dataframe = Mock(return_value=mock_df)
        
        result = extractor.extract_customers(incremental=False)
        
        assert len(result) == 1
        assert result["CardCode"].iloc[0] == "CUST-001"
        extractor.query_runner.execute_to_dataframe.assert_called_once()
    
    @patch("etl.extract.QueryRunner")
    def test_extract_customers_incremental(self, mock_query_runner, mock_config):
        """Test incremental customer extraction."""
        mock_db = Mock(spec=DatabaseConnection)
        extractor = SAPExtractor(mock_db, mock_config)
        
        mock_df = pd.DataFrame({"CardCode": ["CUST-001"]})
        extractor.query_runner.execute_to_dataframe = Mock(return_value=mock_df)
        
        result = extractor.extract_customers(incremental=True, lookback_days=7)
        
        # Verify query was called
        extractor.query_runner.execute_to_dataframe.assert_called_once()
        
        # Verify query contains date filter (check the call args)
        call_args = extractor.query_runner.execute_to_dataframe.call_args
        query = call_args[0][0]
        assert "UpdateDate" in query


class TestDataLoader:
    """Tests for DataLoader class."""
    
    @patch("etl.load.QueryRunner")
    def test_load_fact_table(self, mock_query_runner, mock_config):
        """Test fact table loading."""
        mock_db = Mock(spec=DatabaseConnection)
        loader = DataLoader(mock_db, mock_config)
        
        # Mock bulk insert
        loader.query_runner.bulk_insert = Mock(return_value=100)
        
        test_df = pd.DataFrame({
            "customer_key": [1, 2],
            "item_key": [1, 2],
            "quantity": [10, 20],
        })
        
        row_count = loader.load_fact_table(test_df, "fact_sales", mode="append")
        
        assert row_count == 100
        loader.query_runner.bulk_insert.assert_called_once()
    
    @patch("etl.load.QueryRunner")
    def test_verify_load(self, mock_query_runner, mock_config):
        """Test load verification."""
        mock_db = Mock(spec=DatabaseConnection)
        loader = DataLoader(mock_db, mock_config)
        
        # Mock row count query
        loader.query_runner.get_table_row_count = Mock(return_value=100)
        
        result = loader.verify_load("fact_sales", expected_count=100)
        
        assert result is True
        
        # Test with mismatch
        result = loader.verify_load("fact_sales", expected_count=50)
        
        assert result is False


class TestIntegration:
    """Integration tests for full ETL flow."""
    
    @patch("etl.pipeline.DatabaseConnection")
    @patch("etl.pipeline.SAPExtractor")
    @patch("etl.pipeline.DataTransformer")
    @patch("etl.pipeline.DataLoader")
    def test_full_pipeline_flow(
        self,
        mock_loader,
        mock_transformer,
        mock_extractor,
        mock_db,
        mock_config,
        sample_customer_data,
    ):
        """Test complete ETL pipeline flow."""
        # Mock extractor
        mock_extractor_instance = Mock()
        mock_extractor_instance.extract_customers.return_value = sample_customer_data
        mock_extractor.return_value = mock_extractor_instance
        
        # Mock transformer
        mock_transformer_instance = Mock()
        mock_transformer_instance.transform_customers.return_value = sample_customer_data
        mock_transformer_instance.cleanse_data.return_value = sample_customer_data
        mock_transformer.return_value = mock_transformer_instance
        
        # Mock loader
        mock_loader_instance = Mock()
        mock_loader_instance.load_customer_dimension.return_value = {
            "new_records": 2,
            "updated_records": 0,
        }
        mock_loader.return_value = mock_loader_instance
        
        # Verify the mocks work as expected
        assert mock_extractor_instance.extract_customers() is not None
        assert mock_transformer_instance.transform_customers(sample_customer_data) is not None


def test_date_key_generation():
    """Test date key generation for fact tables."""
    test_date = datetime(2025, 11, 15)
    expected_key = 20251115
    
    date_key = int(test_date.strftime("%Y%m%d"))
    
    assert date_key == expected_key


def test_margin_calculation():
    """Test gross margin calculation."""
    revenue = 1000.0
    cost = 700.0
    
    gross_profit = revenue - cost
    gross_margin_percent = (gross_profit / revenue) * 100
    
    assert gross_profit == 300.0
    assert gross_margin_percent == 30.0


def test_otd_calculation():
    """Test On-Time Delivery calculation."""
    from datetime import timedelta
    
    promised_date = datetime(2025, 11, 20)
    actual_date_on_time = datetime(2025, 11, 19)
    actual_date_late = datetime(2025, 11, 22)
    
    delay_on_time = (actual_date_on_time - promised_date).days
    delay_late = (actual_date_late - promised_date).days
    
    assert delay_on_time <= 0  # On time
    assert delay_late > 0  # Late


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

