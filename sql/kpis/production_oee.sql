-- =====================================================
-- KPI: Overall Equipment Effectiveness (OEE)
-- Purpose: Track manufacturing efficiency through availability, performance, and quality
-- Formula: OEE = Availability × Performance × Quality
-- Business Impact: Production optimization, capacity planning
-- =====================================================

-- OEE Components:
-- 1. Availability = (Operating Time / Planned Production Time) × 100
-- 2. Performance = (Actual Output / Maximum Possible Output) × 100
-- 3. Quality = (Good Units / Total Units Produced) × 100

-- =====================================================
-- View: OEE by Production Order
-- =====================================================
CREATE VIEW analytics.vw_kpi_oee_by_order AS
WITH production_metrics AS (
    SELECT 
        wo.DocEntry,
        wo.DocNum,
        wo.ItemCode,
        wo.ProductCod,
        wo.U_ProductionLine as production_line,
        wo.U_Shift as shift,
        wo.Status,
        
        -- Dates
        wo.PostDate,
        wo.DueDate,
        wo.RlsDate,
        wo.CloseDate,
        wo.U_PlannedStartTime as planned_start_time,
        wo.U_ActualStartTime as actual_start_time,
        wo.U_PlannedEndTime as planned_end_time,
        wo.U_ActualEndTime as actual_end_time,
        
        -- Quantities
        wo.PlannedQty as planned_quantity,
        wo.CmpltQty as completed_quantity,
        wo.RjctQty as rejected_quantity,
        wo.U_ScrapQty as scrap_quantity,
        
        -- Good units
        wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0) as good_units,
        
        -- Time calculations (in minutes)
        DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) as planned_time_minutes,
        DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) as actual_production_time_minutes,
        ISNULL(wo.U_DowntimeMinutes, 0) as downtime_minutes,
        
        -- Operating time (actual time - downtime)
        DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0) as operating_time_minutes,
        
        -- Ideal cycle time (would typically come from item master or routing)
        -- For demo, assuming 1 unit per minute - customize based on your standards
        1.0 as ideal_cycle_time_minutes
        
    FROM OWOR wo
    WHERE wo.Status IN ('C') -- Closed/Completed orders only
      AND wo.U_ActualStartTime IS NOT NULL
      AND wo.U_ActualEndTime IS NOT NULL
)
SELECT 
    DocEntry,
    DocNum,
    ItemCode,
    production_line,
    shift,
    PostDate,
    CloseDate,
    
    planned_quantity,
    completed_quantity,
    rejected_quantity,
    scrap_quantity,
    good_units,
    
    planned_time_minutes,
    actual_production_time_minutes,
    downtime_minutes,
    operating_time_minutes,
    
    -- 1. AVAILABILITY (Operating Time / Planned Production Time)
    CASE 
        WHEN planned_time_minutes > 0 
        THEN (CAST(operating_time_minutes AS FLOAT) / planned_time_minutes) * 100 
        ELSE NULL 
    END as availability_percent,
    
    -- 2. PERFORMANCE (Actual Output / Maximum Possible Output)
    -- Maximum possible = Operating Time / Ideal Cycle Time
    CASE 
        WHEN operating_time_minutes > 0 AND ideal_cycle_time_minutes > 0
        THEN (CAST(completed_quantity AS FLOAT) / (operating_time_minutes / ideal_cycle_time_minutes)) * 100 
        ELSE NULL 
    END as performance_percent,
    
    -- 3. QUALITY (Good Units / Total Units Produced)
    CASE 
        WHEN completed_quantity > 0 
        THEN (CAST(good_units AS FLOAT) / completed_quantity) * 100 
        ELSE NULL 
    END as quality_percent,
    
    -- OEE (Product of all three)
    CASE 
        WHEN planned_time_minutes > 0 
             AND operating_time_minutes > 0 
             AND completed_quantity > 0
             AND ideal_cycle_time_minutes > 0
        THEN (
            (CAST(operating_time_minutes AS FLOAT) / planned_time_minutes) *
            (CAST(completed_quantity AS FLOAT) / (operating_time_minutes / ideal_cycle_time_minutes)) *
            (CAST(good_units AS FLOAT) / completed_quantity)
        ) * 100
        ELSE NULL 
    END as oee_percent,
    
    -- OEE Classification
    CASE 
        WHEN (
            (CAST(operating_time_minutes AS FLOAT) / NULLIF(planned_time_minutes, 0)) *
            (CAST(completed_quantity AS FLOAT) / NULLIF((operating_time_minutes / NULLIF(ideal_cycle_time_minutes, 0)), 0)) *
            (CAST(good_units AS FLOAT) / NULLIF(completed_quantity, 0))
        ) * 100 >= 85 THEN 'World Class'
        WHEN (
            (CAST(operating_time_minutes AS FLOAT) / NULLIF(planned_time_minutes, 0)) *
            (CAST(completed_quantity AS FLOAT) / NULLIF((operating_time_minutes / NULLIF(ideal_cycle_time_minutes, 0)), 0)) *
            (CAST(good_units AS FLOAT) / NULLIF(completed_quantity, 0))
        ) * 100 >= 70 THEN 'Good'
        WHEN (
            (CAST(operating_time_minutes AS FLOAT) / NULLIF(planned_time_minutes, 0)) *
            (CAST(completed_quantity AS FLOAT) / NULLIF((operating_time_minutes / NULLIF(ideal_cycle_time_minutes, 0)), 0)) *
            (CAST(good_units AS FLOAT) / NULLIF(completed_quantity, 0))
        ) * 100 >= 60 THEN 'Fair'
        ELSE 'Poor'
    END as oee_classification
    
FROM production_metrics;

-- =====================================================
-- View: OEE Summary by Production Line
-- =====================================================
CREATE VIEW analytics.vw_kpi_oee_by_production_line AS
WITH oee_data AS (
    SELECT 
        wo.U_ProductionLine as production_line,
        wo.U_Shift as shift,
        wo.DocEntry,
        
        wo.PlannedQty,
        wo.CmpltQty,
        wo.RjctQty,
        wo.U_ScrapQty,
        wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0) as good_units,
        
        DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) as planned_time_minutes,
        DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) as actual_time_minutes,
        ISNULL(wo.U_DowntimeMinutes, 0) as downtime_minutes,
        DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0) as operating_time_minutes,
        
        1.0 as ideal_cycle_time_minutes
        
    FROM OWOR wo
    WHERE wo.Status = 'C'
      AND wo.U_ActualStartTime IS NOT NULL
      AND wo.U_ActualEndTime IS NOT NULL
      AND wo.U_ProductionLine IS NOT NULL
)
SELECT 
    production_line,
    
    -- Production volume
    COUNT(*) as order_count,
    SUM(PlannedQty) as total_planned_quantity,
    SUM(CmpltQty) as total_completed_quantity,
    SUM(good_units) as total_good_units,
    SUM(RjctQty) as total_rejected_quantity,
    
    -- Time metrics
    SUM(planned_time_minutes) as total_planned_time_minutes,
    SUM(operating_time_minutes) as total_operating_time_minutes,
    SUM(downtime_minutes) as total_downtime_minutes,
    
    -- Average OEE components
    AVG(
        CASE 
            WHEN planned_time_minutes > 0 
            THEN (CAST(operating_time_minutes AS FLOAT) / planned_time_minutes) * 100 
            ELSE NULL 
        END
    ) as avg_availability_percent,
    
    AVG(
        CASE 
            WHEN operating_time_minutes > 0
            THEN (CAST(CmpltQty AS FLOAT) / (operating_time_minutes / ideal_cycle_time_minutes)) * 100 
            ELSE NULL 
        END
    ) as avg_performance_percent,
    
    AVG(
        CASE 
            WHEN CmpltQty > 0 
            THEN (CAST(good_units AS FLOAT) / CmpltQty) * 100 
            ELSE NULL 
        END
    ) as avg_quality_percent,
    
    -- Overall OEE for the line
    CASE 
        WHEN SUM(planned_time_minutes) > 0 
             AND SUM(operating_time_minutes) > 0 
             AND SUM(CmpltQty) > 0
        THEN (
            (CAST(SUM(operating_time_minutes) AS FLOAT) / SUM(planned_time_minutes)) *
            (CAST(SUM(CmpltQty) AS FLOAT) / (SUM(operating_time_minutes) / AVG(ideal_cycle_time_minutes))) *
            (CAST(SUM(good_units) AS FLOAT) / SUM(CmpltQty))
        ) * 100
        ELSE NULL 
    END as overall_oee_percent,
    
    -- Targets (customize based on your standards)
    90.0 as target_availability_percent,
    85.0 as target_performance_percent,
    99.0 as target_quality_percent,
    75.0 as target_oee_percent
    
FROM oee_data
GROUP BY production_line;

-- =====================================================
-- View: OEE Trend by Week
-- =====================================================
CREATE VIEW analytics.vw_kpi_oee_trend_weekly AS
WITH weekly_oee AS (
    SELECT 
        DATEPART(YEAR, wo.CloseDate) as year_number,
        DATEPART(WEEK, wo.CloseDate) as week_number,
        
        COUNT(*) as order_count,
        SUM(wo.PlannedQty) as total_planned_quantity,
        SUM(wo.CmpltQty) as total_completed_quantity,
        SUM(wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0)) as total_good_units,
        
        SUM(DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime)) as planned_time_minutes,
        SUM(DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) as operating_time_minutes,
        SUM(ISNULL(wo.U_DowntimeMinutes, 0)) as downtime_minutes,
        
        AVG(1.0) as ideal_cycle_time_minutes
        
    FROM OWOR wo
    WHERE wo.Status = 'C'
      AND wo.CloseDate IS NOT NULL
      AND wo.U_ActualStartTime IS NOT NULL
      AND wo.U_ActualEndTime IS NOT NULL
      AND wo.CloseDate >= DATEADD(WEEK, -12, CAST(GETDATE() AS DATE))
    GROUP BY 
        DATEPART(YEAR, wo.CloseDate),
        DATEPART(WEEK, wo.CloseDate)
)
SELECT 
    year_number,
    week_number,
    
    order_count,
    total_planned_quantity,
    total_completed_quantity,
    total_good_units,
    
    planned_time_minutes,
    operating_time_minutes,
    downtime_minutes,
    
    -- Availability
    CASE 
        WHEN planned_time_minutes > 0 
        THEN (CAST(operating_time_minutes AS FLOAT) / planned_time_minutes) * 100 
        ELSE NULL 
    END as availability_percent,
    
    -- Performance
    CASE 
        WHEN operating_time_minutes > 0
        THEN (CAST(total_completed_quantity AS FLOAT) / (operating_time_minutes / ideal_cycle_time_minutes)) * 100 
        ELSE NULL 
    END as performance_percent,
    
    -- Quality
    CASE 
        WHEN total_completed_quantity > 0 
        THEN (CAST(total_good_units AS FLOAT) / total_completed_quantity) * 100 
        ELSE NULL 
    END as quality_percent,
    
    -- OEE
    CASE 
        WHEN planned_time_minutes > 0 
             AND operating_time_minutes > 0 
             AND total_completed_quantity > 0
        THEN (
            (CAST(operating_time_minutes AS FLOAT) / planned_time_minutes) *
            (CAST(total_completed_quantity AS FLOAT) / (operating_time_minutes / ideal_cycle_time_minutes)) *
            (CAST(total_good_units AS FLOAT) / total_completed_quantity)
        ) * 100
        ELSE NULL 
    END as oee_percent,
    
    -- Week over week change
    LAG(
        CASE 
            WHEN planned_time_minutes > 0 
                 AND operating_time_minutes > 0 
                 AND total_completed_quantity > 0
            THEN (
                (CAST(operating_time_minutes AS FLOAT) / planned_time_minutes) *
                (CAST(total_completed_quantity AS FLOAT) / (operating_time_minutes / ideal_cycle_time_minutes)) *
                (CAST(total_good_units AS FLOAT) / total_completed_quantity)
            ) * 100
            ELSE NULL 
        END
    ) OVER (ORDER BY year_number, week_number) as prev_week_oee_percent
    
FROM weekly_oee
ORDER BY year_number, week_number;

-- =====================================================
-- View: OEE Loss Analysis
-- =====================================================
CREATE VIEW analytics.vw_kpi_oee_loss_analysis AS
WITH loss_data AS (
    SELECT 
        wo.DocEntry,
        wo.DocNum,
        wo.U_ProductionLine as production_line,
        wo.ItemCode,
        
        -- Time losses
        DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) as planned_time_minutes,
        DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) as actual_time_minutes,
        ISNULL(wo.U_DowntimeMinutes, 0) as downtime_minutes,
        
        -- Availability loss (downtime)
        DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) * 
            (ISNULL(wo.U_DowntimeMinutes, 0) / NULLIF(DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime), 0)) as availability_loss_minutes,
        
        -- Performance loss (speed loss)
        (DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) - 
            (wo.CmpltQty * 1.0) as performance_loss_minutes, -- Using 1 min cycle time
        
        -- Quality loss (defect time)
        (ISNULL(wo.RjctQty, 0) + ISNULL(wo.U_ScrapQty, 0)) * 1.0 as quality_loss_minutes,
        
        wo.PlannedQty,
        wo.CmpltQty,
        wo.RjctQty,
        wo.U_ScrapQty
        
    FROM OWOR wo
    WHERE wo.Status = 'C'
      AND wo.U_ActualStartTime IS NOT NULL
      AND wo.U_ActualEndTime IS NOT NULL
)
SELECT 
    production_line,
    
    COUNT(*) as order_count,
    SUM(planned_time_minutes) as total_planned_time_minutes,
    
    -- Time losses
    SUM(downtime_minutes) as total_downtime_minutes,
    SUM(availability_loss_minutes) as total_availability_loss_minutes,
    SUM(performance_loss_minutes) as total_performance_loss_minutes,
    SUM(quality_loss_minutes) as total_quality_loss_minutes,
    
    -- Loss percentages
    CASE 
        WHEN SUM(planned_time_minutes) > 0 
        THEN (SUM(downtime_minutes) / SUM(planned_time_minutes)) * 100 
        ELSE NULL 
    END as availability_loss_percent,
    
    CASE 
        WHEN SUM(planned_time_minutes) > 0 
        THEN (SUM(performance_loss_minutes) / SUM(planned_time_minutes)) * 100 
        ELSE NULL 
    END as performance_loss_percent,
    
    CASE 
        WHEN SUM(planned_time_minutes) > 0 
        THEN (SUM(quality_loss_minutes) / SUM(planned_time_minutes)) * 100 
        ELSE NULL 
    END as quality_loss_percent
    
FROM loss_data
GROUP BY production_line;

-- =====================================================
-- Stored Procedure: OEE Report
-- =====================================================
CREATE PROCEDURE analytics.sp_oee_report
    @StartDate DATE,
    @EndDate DATE,
    @ProductionLine NVARCHAR(50) = NULL,
    @MinOEE DECIMAL(19,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        wo.DocNum as production_order,
        wo.ItemCode,
        wo.U_ProductionLine as production_line,
        wo.U_Shift as shift,
        wo.PostDate as post_date,
        wo.CloseDate as close_date,
        
        wo.PlannedQty as planned_quantity,
        wo.CmpltQty as completed_quantity,
        wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0) as good_units,
        wo.RjctQty as rejected_quantity,
        
        -- OEE components
        CASE 
            WHEN DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) > 0 
            THEN ((DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) / 
                  CAST(DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) AS FLOAT)) * 100 
            ELSE NULL 
        END as availability_percent,
        
        CASE 
            WHEN (DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) > 0
            THEN (wo.CmpltQty / 
                  CAST((DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) AS FLOAT)) * 100 
            ELSE NULL 
        END as performance_percent,
        
        CASE 
            WHEN wo.CmpltQty > 0 
            THEN ((wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0)) / CAST(wo.CmpltQty AS FLOAT)) * 100 
            ELSE NULL 
        END as quality_percent,
        
        -- Overall OEE
        CASE 
            WHEN DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) > 0 
                 AND (DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) > 0
                 AND wo.CmpltQty > 0
            THEN (
                ((DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) / 
                  CAST(DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) AS FLOAT)) *
                (wo.CmpltQty / 
                  CAST((DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) AS FLOAT)) *
                ((wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0)) / CAST(wo.CmpltQty AS FLOAT))
            ) * 100
            ELSE NULL 
        END as oee_percent
        
    FROM OWOR wo
    WHERE wo.Status = 'C'
      AND wo.CloseDate BETWEEN @StartDate AND @EndDate
      AND wo.U_ActualStartTime IS NOT NULL
      AND wo.U_ActualEndTime IS NOT NULL
      AND (@ProductionLine IS NULL OR wo.U_ProductionLine = @ProductionLine)
      AND (@MinOEE IS NULL OR 
           (
                ((DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) / 
                  NULLIF(CAST(DATEDIFF(MINUTE, wo.U_PlannedStartTime, wo.U_PlannedEndTime) AS FLOAT), 0)) *
                (wo.CmpltQty / 
                  NULLIF(CAST((DATEDIFF(MINUTE, wo.U_ActualStartTime, wo.U_ActualEndTime) - ISNULL(wo.U_DowntimeMinutes, 0)) AS FLOAT), 0)) *
                ((wo.CmpltQty - ISNULL(wo.RjctQty, 0) - ISNULL(wo.U_ScrapQty, 0)) / NULLIF(CAST(wo.CmpltQty AS FLOAT), 0))
            ) * 100 >= @MinOEE
          )
    ORDER BY wo.CloseDate DESC;
END;
GO

-- Sample usage:
-- EXEC analytics.sp_oee_report @StartDate = '2025-11-01', @EndDate = '2025-11-30';
-- EXEC analytics.sp_oee_report @StartDate = '2025-11-01', @EndDate = '2025-11-30', @ProductionLine = 'LINE-A';
-- EXEC analytics.sp_oee_report @StartDate = '2025-11-01', @EndDate = '2025-11-30', @MinOEE = 70;

