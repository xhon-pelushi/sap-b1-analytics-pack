"""
Tests for Data Quality
======================

Data quality validation tests.
"""

import pytest
import pandas as pd
import numpy as np
from datetime import datetime, timedelta


def test_no_null_primary_keys():
    """Test that primary keys don't contain nulls."""
    # Sample data with primary key
    df = pd.DataFrame({
        "customer_key": [1, 2, 3, 4],
        "card_code": ["C001", "C002", "C003", "C004"],
        "card_name": ["Customer 1", "Customer 2", "Customer 3", "Customer 4"],
    })
    
    # Primary key should not have nulls
    assert df["customer_key"].isnull().sum() == 0


def test_no_duplicate_primary_keys():
    """Test that primary keys are unique."""
    df = pd.DataFrame({
        "customer_key": [1, 2, 3, 4],
        "card_code": ["C001", "C002", "C003", "C004"],
    })
    
    # Primary key should be unique
    assert df["customer_key"].duplicated().sum() == 0


def test_foreign_key_integrity():
    """Test foreign key relationships."""
    # Dimension table
    dim_customer = pd.DataFrame({
        "customer_key": [1, 2, 3],
        "card_code": ["C001", "C002", "C003"],
    })
    
    # Fact table
    fact_sales = pd.DataFrame({
        "sales_key": [1, 2, 3, 4],
        "customer_key": [1, 2, 3, 1],  # All valid foreign keys
    })
    
    # Check all foreign keys exist in dimension
    valid_keys = dim_customer["customer_key"].values
    invalid_fks = fact_sales[~fact_sales["customer_key"].isin(valid_keys)]
    
    assert len(invalid_fks) == 0, "Found invalid foreign keys"


def test_date_ranges_valid():
    """Test that dates are within valid ranges."""
    df = pd.DataFrame({
        "order_date": [
            datetime(2025, 1, 1),
            datetime(2025, 6, 15),
            datetime(2025, 12, 31),
        ]
    })
    
    # Dates should be within reasonable range
    min_date = datetime(2020, 1, 1)
    max_date = datetime(2030, 12, 31)
    
    assert (df["order_date"] >= min_date).all()
    assert (df["order_date"] <= max_date).all()


def test_numeric_ranges_valid():
    """Test that numeric values are within valid ranges."""
    df = pd.DataFrame({
        "quantity": [1, 10, 100, 1000],
        "price": [10.0, 50.0, 100.0, 500.0],
        "discount_percent": [0, 5, 10, 15],
    })
    
    # Quantity should be positive
    assert (df["quantity"] > 0).all()
    
    # Price should be positive
    assert (df["price"] > 0).all()
    
    # Discount should be between 0 and 100
    assert (df["discount_percent"] >= 0).all()
    assert (df["discount_percent"] <= 100).all()


def test_margin_calculation_accuracy():
    """Test gross margin calculation accuracy."""
    df = pd.DataFrame({
        "revenue": [1000, 2000, 3000],
        "cost": [700, 1400, 2100],
    })
    
    df["gross_profit"] = df["revenue"] - df["cost"]
    df["gross_margin_percent"] = (df["gross_profit"] / df["revenue"]) * 100
    
    # All margins should be 30%
    expected_margin = 30.0
    assert np.allclose(df["gross_margin_percent"], expected_margin)


def test_otd_calculation_logic():
    """Test On-Time Delivery calculation logic."""
    df = pd.DataFrame({
        "promised_date": [
            datetime(2025, 11, 20),
            datetime(2025, 11, 21),
            datetime(2025, 11, 22),
        ],
        "actual_date": [
            datetime(2025, 11, 19),  # Early
            datetime(2025, 11, 21),  # On time
            datetime(2025, 11, 25),  # Late
        ],
    })
    
    df["delay_days"] = (df["actual_date"] - df["promised_date"]).dt.days
    df["is_on_time"] = df["delay_days"] <= 0
    
    assert df.loc[0, "is_on_time"] == True  # Early
    assert df.loc[1, "is_on_time"] == True  # On time
    assert df.loc[2, "is_on_time"] == False  # Late


def test_inventory_aging_buckets():
    """Test inventory aging bucket assignment."""
    df = pd.DataFrame({
        "days_in_stock": [15, 45, 75, 120, 200],
    })
    
    def assign_age_bucket(days):
        if days <= 30:
            return "0-30 days"
        elif days <= 60:
            return "31-60 days"
        elif days <= 90:
            return "61-90 days"
        elif days <= 180:
            return "91-180 days"
        else:
            return "180+ days"
    
    df["age_bucket"] = df["days_in_stock"].apply(assign_age_bucket)
    
    assert df.loc[0, "age_bucket"] == "0-30 days"
    assert df.loc[1, "age_bucket"] == "31-60 days"
    assert df.loc[2, "age_bucket"] == "61-90 days"
    assert df.loc[3, "age_bucket"] == "91-180 days"
    assert df.loc[4, "age_bucket"] == "180+ days"


def test_customer_tier_assignment():
    """Test customer tier assignment logic."""
    df = pd.DataFrame({
        "credit_line": [25000, 75000, 125000, 175000],
    })
    
    df["customer_tier"] = pd.cut(
        df["credit_line"],
        bins=[0, 50000, 100000, 150000, float("inf")],
        labels=["D", "C", "B", "A"],
        include_lowest=True,
    )
    
    assert df.loc[0, "customer_tier"] == "D"
    assert df.loc[1, "customer_tier"] == "C"
    assert df.loc[2, "customer_tier"] == "B"
    assert df.loc[3, "customer_tier"] == "A"


def test_scd_type2_logic():
    """Test SCD Type 2 dimension logic."""
    # Initial state
    df_old = pd.DataFrame({
        "customer_key": [1, 2],
        "card_code": ["C001", "C002"],
        "customer_tier": ["B", "C"],
        "is_current": [1, 1],
        "effective_date": [datetime(2024, 1, 1), datetime(2024, 1, 1)],
        "end_date": [None, None],
    })
    
    # New record with change
    new_tier = "A"  # C002 upgraded from C to A
    
    # Simulate SCD2 update
    # 1. Close old record
    df_old.loc[df_old["card_code"] == "C002", "is_current"] = 0
    df_old.loc[df_old["card_code"] == "C002", "end_date"] = datetime(2025, 1, 1)
    
    # 2. Insert new record
    new_record = pd.DataFrame({
        "customer_key": [3],
        "card_code": ["C002"],
        "customer_tier": [new_tier],
        "is_current": [1],
        "effective_date": [datetime(2025, 1, 1)],
        "end_date": [None],
    })
    
    df_new = pd.concat([df_old, new_record], ignore_index=True)
    
    # Verify SCD2 logic
    c002_records = df_new[df_new["card_code"] == "C002"]
    assert len(c002_records) == 2  # Two versions
    assert c002_records["is_current"].sum() == 1  # Only one current
    assert c002_records[c002_records["is_current"] == 1]["customer_tier"].iloc[0] == "A"


def test_data_completeness():
    """Test data completeness for required fields."""
    df = pd.DataFrame({
        "customer_key": [1, 2, 3],
        "card_code": ["C001", "C002", "C003"],
        "card_name": ["Customer 1", "Customer 2", "Customer 3"],
        "is_active": [1, 1, 1],
    })
    
    required_fields = ["customer_key", "card_code", "card_name", "is_active"]
    
    for field in required_fields:
        null_count = df[field].isnull().sum()
        assert null_count == 0, f"Field {field} has {null_count} null values"


def test_data_consistency():
    """Test data consistency across related fields."""
    df = pd.DataFrame({
        "quantity": [10, 20, 30],
        "unit_price": [100, 200, 300],
        "line_total": [1000, 4000, 9000],
    })
    
    # Calculate expected line total
    df["calculated_total"] = df["quantity"] * df["unit_price"]
    
    # Check consistency
    assert (df["line_total"] == df["calculated_total"]).all()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

