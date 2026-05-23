-- ==========================================
-- STAR SCHEMA DATABASE SCHEMA DESIGN FOR POWER BI
-- Target: Model Salesforce Opportunities for BI Analytics
-- Database: ANSI SQL (SQLite / PostgreSQL Compatible)
-- ==========================================

-- 1. DIMENSION: DATE (Calendar Dimension for Time Intelligence)
CREATE TABLE dim_calendar (
    date_key DATE PRIMARY KEY,
    day_of_month INT,
    month_name VARCHAR(10),
    month_number INT,
    quarter VARCHAR(2),
    year INT,
    is_weekend BOOLEAN
);

-- 2. DIMENSION: SALES REPS (Sourced from Salesforce User Table)
CREATE TABLE dim_sales_reps (
    rep_key VARCHAR(50) PRIMARY KEY,
    rep_name VARCHAR(100) NOT NULL,
    rep_segment VARCHAR(20) CHECK (rep_segment IN ('Hunter', 'Farmer')), -- Hunter = Inside/New Logo, Farmer = Account Mgr
    rep_region VARCHAR(50) DEFAULT 'North America'
);

-- 3. DIMENSION: ACCOUNTS (Sourced from Salesforce Account Table)
CREATE TABLE dim_accounts (
    account_key VARCHAR(50) PRIMARY KEY,
    account_name VARCHAR(150) NOT NULL,
    industry_vertical VARCHAR(100),
    annual_revenue DECIMAL(18, 2),
    created_date DATE
);

-- 4. FACT TABLE: OPPORTUNITIES (Sourced from Salesforce Opportunity Table)
CREATE TABLE fact_opportunities (
    opportunity_key VARCHAR(50) PRIMARY KEY,
    opportunity_name VARCHAR(150),
    account_key VARCHAR(50) REFERENCES dim_accounts(account_key),
    rep_key VARCHAR(50) REFERENCES dim_sales_reps(rep_key),
    stage VARCHAR(50) CHECK (stage IN ('Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost')),
    amount_usd DECIMAL(18, 2),
    created_date DATE REFERENCES dim_calendar(date_key),
    close_date DATE REFERENCES dim_calendar(date_key),
    lead_source VARCHAR(100),
    
    -- Calculated ETL fields (denormalized for performance)
    days_to_close INT, -- Velocity metric
    is_closed BOOLEAN,
    is_won BOOLEAN
);

-- 5. FACT TABLE: ACTIVITIES (Sourced from Salesforce Task/Event Tables)
-- Tracks sales rep productivity and engagement levels
CREATE TABLE fact_sales_activities (
    activity_key VARCHAR(50) PRIMARY KEY,
    opportunity_key VARCHAR(50) REFERENCES fact_opportunities(opportunity_key),
    rep_key VARCHAR(50) REFERENCES dim_sales_reps(rep_key),
    activity_date DATE REFERENCES dim_calendar(date_key),
    activity_type VARCHAR(20) CHECK (activity_type IN ('Call', 'Meeting', 'Email')),
    activity_count INT DEFAULT 1
);
