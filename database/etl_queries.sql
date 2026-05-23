-- ==========================================
-- ETL TRANSFORMATIONS (EXTRACT-TRANSFORM-LOAD)
-- Sourced from Raw Salesforce Staging Tables into Star Schema
-- Database: SQLite/PostgreSQL Compatible
-- ==========================================

-- PRE-REQUISITE: 
-- Assume staging tables `stage_salesforce_opportunities` exist
-- loaded from raw CSV dumps.

-- 1. POPULATE Calendar Dimension (dim_calendar)
-- Typically generated programmatically. Here is an example recursive script:
WITH RECURSIVE dates(date) AS (
  VALUES('2024-01-01')
  UNION ALL
  SELECT date(date, '+1 day') 
  FROM dates 
  WHERE date < '2026-12-31'
)
INSERT INTO dim_calendar (date_key, day_of_month, month_name, month_number, quarter, year, is_weekend)
SELECT 
    date as date_key,
    strftime('%d', date) as day_of_month,
    CASE strftime('%m', date)
        WHEN '01' THEN 'January' WHEN '02' THEN 'February' WHEN '03' THEN 'March'
        WHEN '04' THEN 'April' WHEN '05' THEN 'May' WHEN '06' THEN 'June'
        WHEN '07' THEN 'July' WHEN '08' THEN 'August' WHEN '09' THEN 'September'
        WHEN '10' THEN 'October' WHEN '11' THEN 'November' WHEN '12' THEN 'December'
    END as month_name,
    CAST(strftime('%m', date) AS INT) as month_number,
    'Q' || ((CAST(strftime('%m', date) AS INT) - 1) / 3 + 1) as quarter,
    CAST(strftime('%Y', date) AS INT) as year,
    CASE strftime('%w', date) WHEN '0' THEN 1 WHEN '6' THEN 1 ELSE 0 END as is_weekend
FROM dates;

-- 2. POPULATE Sales Reps Dimension (dim_sales_reps)
-- Deduplicating sales reps from raw opportunity logs and assigning hunters vs farmers
INSERT INTO dim_sales_reps (rep_key, rep_name, rep_segment)
SELECT DISTINCT 
    LOWER(REPLACE(Owner_Name, ' ', '_')) as rep_key,
    Owner_Name as rep_name,
    Rep_Segment as rep_segment
FROM stage_salesforce_opportunities;

-- 3. POPULATE Accounts Dimension (dim_accounts)
INSERT INTO dim_accounts (account_key, account_name, industry_vertical, created_date)
SELECT DISTINCT 
    LOWER(REPLACE(Account_Name, ' ', '_')) as account_key,
    Account_Name as account_name,
    Vertical as industry_vertical,
    MIN(Created_Date) as created_date
FROM stage_salesforce_opportunities
GROUP BY Account_Name, Vertical;

-- 4. POPULATE Opportunities Fact (fact_opportunities)
INSERT INTO fact_opportunities (
    opportunity_key, opportunity_name, account_key, rep_key, 
    stage, amount_usd, created_date, close_date, lead_source, 
    days_to_close, is_closed, is_won
)
SELECT 
    Opportunity_ID as opportunity_key,
    Opportunity_Name as opportunity_name,
    LOWER(REPLACE(Account_Name, ' ', '_')) as account_key,
    LOWER(REPLACE(Owner_Name, ' ', '_')) as rep_key,
    Stage as stage,
    Amount_USD as amount_usd,
    Created_Date as created_date,
    Close_Date as close_date,
    Lead_Source as lead_source,
    -- Calculate days to close
    CAST(julianday(Close_Date) - julianday(Created_Date) AS INT) as days_to_close,
    -- Status indicators
    CASE WHEN Stage IN ('Closed Won', 'Closed Lost') THEN 1 ELSE 0 END as is_closed,
    CASE WHEN Stage = 'Closed Won' THEN 1 ELSE 0 END as is_won
FROM stage_salesforce_opportunities;

-- 5. POPULATE Activities Fact (fact_sales_activities)
-- Deconstruct aggregated activity counts from staging into transactional rows
-- Generating emails:
INSERT INTO fact_sales_activities (activity_key, opportunity_key, rep_key, activity_date, activity_type, activity_count)
SELECT 
    Opportunity_ID || '_email' as activity_key,
    Opportunity_ID as opportunity_key,
    LOWER(REPLACE(Owner_Name, ' ', '_')) as rep_key,
    Created_Date as activity_date, -- Assumed date
    'Email' as activity_type,
    Emails_Logged as activity_count
FROM stage_salesforce_opportunities
WHERE Emails_Logged > 0;

-- Generating calls:
INSERT INTO fact_sales_activities (activity_key, opportunity_key, rep_key, activity_date, activity_type, activity_count)
SELECT 
    Opportunity_ID || '_call' as activity_key,
    Opportunity_ID as opportunity_key,
    LOWER(REPLACE(Owner_Name, ' ', '_')) as rep_key,
    Created_Date as activity_date,
    'Call' as activity_type,
    Calls_Logged as activity_count
FROM stage_salesforce_opportunities
WHERE Calls_Logged > 0;
