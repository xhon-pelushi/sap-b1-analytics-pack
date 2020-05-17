-- =====================================================
-- Dimension: Calendar (Date)
-- Purpose: Comprehensive date dimension for time-series analytics
-- Type: Static dimension (pre-populated with date range)
-- =====================================================

-- Drop table if exists (for development/testing)
-- DROP TABLE IF EXISTS analytics.dim_calendar;

CREATE TABLE analytics.dim_calendar (
    -- Surrogate key
    date_key INT PRIMARY KEY, -- Format: YYYYMMDD (e.g., 20250101)
    
    -- Date value
    date_value DATE NOT NULL UNIQUE,
    
    -- Day attributes
    day_of_month INT NOT NULL,
    day_of_week INT NOT NULL, -- 1=Sunday, 7=Saturday
    day_of_week_name NVARCHAR(10) NOT NULL,
    day_of_week_abbr NVARCHAR(3) NOT NULL,
    day_of_year INT NOT NULL,
    day_of_quarter INT NOT NULL,
    
    -- Week attributes
    week_of_year INT NOT NULL,
    week_of_month INT NOT NULL,
    iso_week INT NOT NULL,
    
    -- Month attributes
    month_number INT NOT NULL,
    month_name NVARCHAR(10) NOT NULL,
    month_abbr NVARCHAR(3) NOT NULL,
    month_year NVARCHAR(7) NOT NULL, -- Format: YYYY-MM
    
    -- Quarter attributes
    quarter_number INT NOT NULL,
    quarter_name NVARCHAR(2) NOT NULL, -- Q1, Q2, Q3, Q4
    quarter_year NVARCHAR(7) NOT NULL, -- Format: YYYY-QN
    
    -- Year attributes
    year_number INT NOT NULL,
    
    -- Fiscal period (customize based on your fiscal calendar)
    fiscal_year INT NOT NULL,
    fiscal_quarter INT NOT NULL,
    fiscal_month INT NOT NULL,
    fiscal_week INT NOT NULL,
    
    -- Business day flags
    is_weekday BIT NOT NULL,
    is_weekend BIT NOT NULL,
    is_holiday BIT DEFAULT 0,
    is_business_day BIT NOT NULL,
    
    -- Holiday information
    holiday_name NVARCHAR(100),
    holiday_type NVARCHAR(50), -- Federal, State, Company, etc.
    
    -- Relative date flags
    is_current_day BIT DEFAULT 0,
    is_current_week BIT DEFAULT 0,
    is_current_month BIT DEFAULT 0,
    is_current_quarter BIT DEFAULT 0,
    is_current_year BIT DEFAULT 0,
    
    -- Offset fields for period calculations
    days_from_today INT, -- Negative for past, positive for future
    weeks_from_today INT,
    months_from_today INT,
    quarters_from_today INT,
    years_from_today INT,
    
    -- First/Last day flags
    is_first_day_of_month BIT DEFAULT 0,
    is_last_day_of_month BIT DEFAULT 0,
    is_first_day_of_quarter BIT DEFAULT 0,
    is_last_day_of_quarter BIT DEFAULT 0,
    is_first_day_of_year BIT DEFAULT 0,
    is_last_day_of_year BIT DEFAULT 0,
    
    -- Display formats
    date_display_short NVARCHAR(10), -- MM/DD/YYYY
    date_display_medium NVARCHAR(15), -- Mon DD, YYYY
    date_display_long NVARCHAR(30), -- Monday, January 01, 2025
    date_display_iso NVARCHAR(10), -- YYYY-MM-DD
    
    -- Audit fields
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    updated_date DATETIME NOT NULL DEFAULT GETDATE()
);

-- Create indexes
CREATE INDEX idx_dim_calendar_date_value 
    ON analytics.dim_calendar(date_value);

CREATE INDEX idx_dim_calendar_year_month 
    ON analytics.dim_calendar(year_number, month_number);

CREATE INDEX idx_dim_calendar_quarter 
    ON analytics.dim_calendar(year_number, quarter_number);

CREATE INDEX idx_dim_calendar_fiscal_year 
    ON analytics.dim_calendar(fiscal_year);

CREATE INDEX idx_dim_calendar_is_business_day 
    ON analytics.dim_calendar(is_business_day);

-- Add comments
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Calendar/Date dimension table for time-series analytics', 
    @level0type = N'SCHEMA', @level0name = 'analytics',
    @level1type = N'TABLE',  @level1name = 'dim_calendar';

-- Stored procedure to populate calendar dimension
CREATE PROCEDURE analytics.sp_populate_dim_calendar
    @StartDate DATE = '2020-01-01',
    @EndDate DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Clear existing data
    TRUNCATE TABLE analytics.dim_calendar;
    
    -- Declare variables
    DECLARE @CurrentDate DATE = @StartDate;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    
    -- Loop through dates
    WHILE @CurrentDate <= @EndDate
    BEGIN
        DECLARE @Year INT = YEAR(@CurrentDate);
        DECLARE @Month INT = MONTH(@CurrentDate);
        DECLARE @Day INT = DAY(@CurrentDate);
        DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @CurrentDate);
        DECLARE @DayOfYear INT = DATEPART(DAYOFYEAR, @CurrentDate);
        DECLARE @Quarter INT = DATEPART(QUARTER, @CurrentDate);
        
        INSERT INTO analytics.dim_calendar (
            date_key,
            date_value,
            day_of_month,
            day_of_week,
            day_of_week_name,
            day_of_week_abbr,
            day_of_year,
            day_of_quarter,
            week_of_year,
            week_of_month,
            iso_week,
            month_number,
            month_name,
            month_abbr,
            month_year,
            quarter_number,
            quarter_name,
            quarter_year,
            year_number,
            fiscal_year,
            fiscal_quarter,
            fiscal_month,
            fiscal_week,
            is_weekday,
            is_weekend,
            is_business_day,
            is_current_day,
            is_current_week,
            is_current_month,
            is_current_quarter,
            is_current_year,
            days_from_today,
            weeks_from_today,
            months_from_today,
            quarters_from_today,
            years_from_today,
            is_first_day_of_month,
            is_last_day_of_month,
            is_first_day_of_quarter,
            is_last_day_of_quarter,
            is_first_day_of_year,
            is_last_day_of_year,
            date_display_short,
            date_display_medium,
            date_display_long,
            date_display_iso
        )
        VALUES (
            CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT),
            @CurrentDate,
            @Day,
            @DayOfWeek,
            DATENAME(WEEKDAY, @CurrentDate),
            LEFT(DATENAME(WEEKDAY, @CurrentDate), 3),
            @DayOfYear,
            DATEDIFF(DAY, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @CurrentDate), 0), @CurrentDate) + 1,
            DATEPART(WEEK, @CurrentDate),
            CEILING(CAST(@Day AS FLOAT) / 7),
            DATEPART(ISO_WEEK, @CurrentDate),
            @Month,
            DATENAME(MONTH, @CurrentDate),
            LEFT(DATENAME(MONTH, @CurrentDate), 3),
            FORMAT(@CurrentDate, 'yyyy-MM'),
            @Quarter,
            'Q' + CAST(@Quarter AS NVARCHAR),
            CAST(@Year AS NVARCHAR) + '-Q' + CAST(@Quarter AS NVARCHAR),
            @Year,
            -- Fiscal year (assuming Jan start, customize if needed)
            @Year,
            @Quarter,
            @Month,
            DATEPART(WEEK, @CurrentDate),
            CASE WHEN @DayOfWeek IN (2,3,4,5,6) THEN 1 ELSE 0 END,
            CASE WHEN @DayOfWeek IN (1,7) THEN 1 ELSE 0 END,
            CASE WHEN @DayOfWeek IN (2,3,4,5,6) THEN 1 ELSE 0 END, -- Simplified, adjust for holidays
            CASE WHEN @CurrentDate = @Today THEN 1 ELSE 0 END,
            CASE WHEN DATEPART(WEEK, @CurrentDate) = DATEPART(WEEK, @Today) AND @Year = YEAR(@Today) THEN 1 ELSE 0 END,
            CASE WHEN @Month = MONTH(@Today) AND @Year = YEAR(@Today) THEN 1 ELSE 0 END,
            CASE WHEN @Quarter = DATEPART(QUARTER, @Today) AND @Year = YEAR(@Today) THEN 1 ELSE 0 END,
            CASE WHEN @Year = YEAR(@Today) THEN 1 ELSE 0 END,
            DATEDIFF(DAY, @Today, @CurrentDate),
            DATEDIFF(WEEK, @Today, @CurrentDate),
            DATEDIFF(MONTH, @Today, @CurrentDate),
            DATEDIFF(QUARTER, @Today, @CurrentDate),
            DATEDIFF(YEAR, @Today, @CurrentDate),
            CASE WHEN @Day = 1 THEN 1 ELSE 0 END,
            CASE WHEN @CurrentDate = EOMONTH(@CurrentDate) THEN 1 ELSE 0 END,
            CASE WHEN @CurrentDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @CurrentDate), 0) THEN 1 ELSE 0 END,
            CASE WHEN @CurrentDate = DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @CurrentDate) + 1, 0)) THEN 1 ELSE 0 END,
            CASE WHEN @Month = 1 AND @Day = 1 THEN 1 ELSE 0 END,
            CASE WHEN @Month = 12 AND @Day = 31 THEN 1 ELSE 0 END,
            FORMAT(@CurrentDate, 'MM/dd/yyyy'),
            FORMAT(@CurrentDate, 'MMM dd, yyyy'),
            FORMAT(@CurrentDate, 'dddd, MMMM dd, yyyy'),
            FORMAT(@CurrentDate, 'yyyy-MM-dd')
        );
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
END;
GO

-- Execute procedure to populate calendar
-- EXEC analytics.sp_populate_dim_calendar @StartDate = '2020-01-01', @EndDate = '2030-12-31';

