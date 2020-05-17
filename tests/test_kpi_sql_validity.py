"""
Tests for KPI SQL Validity
===========================

Tests to validate SQL syntax and logic for KPI views.
"""

import pytest
import re
from pathlib import Path


def get_sql_files():
    """Get all SQL files from the kpis directory."""
    kpi_dir = Path("sql/kpis")
    if kpi_dir.exists():
        return list(kpi_dir.glob("*.sql"))
    return []


def test_sql_files_exist():
    """Test that KPI SQL files exist."""
    sql_files = get_sql_files()
    assert len(sql_files) > 0, "No SQL files found in sql/kpis directory"


@pytest.mark.parametrize("sql_file", get_sql_files())
def test_sql_file_not_empty(sql_file):
    """Test that SQL files are not empty."""
    content = sql_file.read_text()
    assert len(content.strip()) > 0, f"{sql_file.name} is empty"


@pytest.mark.parametrize("sql_file", get_sql_files())
def test_sql_has_create_view(sql_file):
    """Test that SQL files contain CREATE VIEW statements."""
    content = sql_file.read_text()
    assert "CREATE VIEW" in content.upper(), f"{sql_file.name} missing CREATE VIEW"


@pytest.mark.parametrize("sql_file", get_sql_files())
def test_sql_has_proper_comments(sql_file):
    """Test that SQL files have header comments."""
    content = sql_file.read_text()
    assert content.strip().startswith("--"), f"{sql_file.name} missing header comments"


@pytest.mark.parametrize("sql_file", get_sql_files())
def test_sql_no_syntax_errors(sql_file):
    """Basic SQL syntax validation."""
    content = sql_file.read_text()
    
    # Check for balanced parentheses
    open_parens = content.count("(")
    close_parens = content.count(")")
    assert open_parens == close_parens, f"{sql_file.name} has unbalanced parentheses"
    
    # Check for common SQL keywords
    content_upper = content.upper()
    if "CREATE VIEW" in content_upper:
        assert "SELECT" in content_upper, f"{sql_file.name} CREATE VIEW missing SELECT"


def test_otd_kpi_structure():
    """Test OTD KPI SQL structure."""
    otd_file = Path("sql/kpis/otd_on_time_delivery.sql")
    if not otd_file.exists():
        pytest.skip("OTD SQL file not found")
    
    content = otd_file.read_text()
    
    # Check for required views
    assert "vw_kpi_otd_daily" in content
    assert "vw_kpi_otd_by_customer" in content
    assert "vw_kpi_otd_by_item" in content
    
    # Check for key calculations
    assert "is_on_time_delivery" in content
    assert "delivery_delay_days" in content


def test_inventory_aging_kpi_structure():
    """Test Inventory Aging KPI SQL structure."""
    inv_file = Path("sql/kpis/inventory_aging.sql")
    if not inv_file.exists():
        pytest.skip("Inventory Aging SQL file not found")
    
    content = inv_file.read_text()
    
    # Check for age buckets
    assert "0-30 days" in content or "0-30" in content
    assert "180+" in content or "180 days" in content


def test_sales_margin_kpi_structure():
    """Test Sales Margin KPI SQL structure."""
    margin_file = Path("sql/kpis/sales_margin.sql")
    if not margin_file.exists():
        pytest.skip("Sales Margin SQL file not found")
    
    content = margin_file.read_text()
    
    # Check for margin calculations
    assert "gross_margin_percent" in content or "margin" in content.lower()
    assert "revenue" in content.lower() or "sales" in content.lower()
    assert "cost" in content.lower()


def test_forecast_accuracy_kpi_structure():
    """Test Forecast Accuracy KPI SQL structure."""
    forecast_file = Path("sql/kpis/forecast_accuracy.sql")
    if not forecast_file.exists():
        pytest.skip("Forecast Accuracy SQL file not found")
    
    content = forecast_file.read_text()
    
    # Check for forecast vs actual comparison
    assert "forecast" in content.lower()
    assert "actual" in content.lower()


def test_oee_kpi_structure():
    """Test OEE KPI SQL structure."""
    oee_file = Path("sql/kpis/production_oee.sql")
    if not oee_file.exists():
        pytest.skip("OEE SQL file not found")
    
    content = oee_file.read_text()
    
    # Check for OEE components
    assert "availability" in content.lower()
    assert "performance" in content.lower()
    assert "quality" in content.lower()


def test_kpi_views_use_analytics_schema():
    """Test that KPI views reference analytics schema."""
    sql_files = get_sql_files()
    
    for sql_file in sql_files:
        content = sql_file.read_text()
        
        # Check if analytics schema is referenced
        if "FROM" in content.upper():
            # Should reference analytics schema for dimensions/facts
            assert (
                "analytics." in content.lower() or
                "fact_" in content.lower() or
                "dim_" in content.lower()
            ), f"{sql_file.name} should reference analytics schema"


def test_kpi_calculations_avoid_division_by_zero():
    """Test that KPI calculations handle division by zero."""
    sql_files = get_sql_files()
    
    for sql_file in sql_files:
        content = sql_file.read_text()
        
        # Find division operations
        if "/" in content:
            # Check for NULLIF or CASE statements to handle zero division
            # This is a basic check - more sophisticated parsing would be better
            divisions = re.findall(r'/\s*\w+', content)
            if divisions:
                # Should have some protection mechanism
                has_protection = (
                    "NULLIF" in content.upper() or
                    "CASE" in content.upper() or
                    "> 0" in content
                )
                assert has_protection, f"{sql_file.name} may have unprotected division"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

