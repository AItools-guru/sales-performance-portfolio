# Power BI DAX Measures Documentation

This file documents the core **DAX (Data Analysis Expressions)** formulas modeled for the ODP Sales Performance dashboard in Power BI. These formulas translate business questions regarding pipeline health and sales productivity into measurable insights.

---

## 📈 1. Financial & Growth Measures

### Total Revenue (Closed Won Sales)
Sums the monetary value of all successfully closed opportunities.
```dax
Total Revenue = 
CALCULATE(
    SUM(fact_opportunities[amount_usd]),
    fact_opportunities[stage] = "Closed Won"
)
```

### Prior Year (PY) Revenue
Calculates Closed Won sales for the exact same period in the previous year. Essential for year-over-year growth benchmarking.
```dax
PY Revenue = 
CALCULATE(
    [Total Revenue],
    SAMEPERIODLASTYEAR(dim_calendar[date_key])
)
```

### YoY Revenue Growth %
Measures the percentage increase or decrease in closed won revenue compared to the previous year.
```dax
YoY Revenue Growth % = 
VAR CurrentRev = [Total Revenue]
VAR PriorRev = [PY Revenue]
RETURN
    DIVIDE(CurrentRev - PriorRev, PriorRev, 0)
```

---

## 🎯 2. Pipeline & Conversion Metrics

### Win Rate % (Opportunity Conversion)
Percentage of closed opportunities that resulted in a win. Highlights salesperson effectiveness.
```dax
Win Rate % = 
VAR ClosedOpps = 
    CALCULATE(
        COUNT(fact_opportunities[opportunity_key]),
        fact_opportunities[is_closed] = TRUE
    )
VAR WonOpps = 
    CALCULATE(
        COUNT(fact_opportunities[opportunity_key]),
        fact_opportunities[stage] = "Closed Won"
    )
RETURN
    DIVIDE(WonOpps, ClosedOpps, 0)
```

### Pipeline Velocity (Average Days to Close)
Measures the average duration (in days) it takes to move an opportunity from creation to a closed state (Won or Lost).
```dax
Pipeline Velocity (Days) = 
AVERAGE(fact_opportunities[days_to_close])
```

### Funnel Leakage (Conversion by Stage)
Calculates the progression rate from one sales stage to the next. High values indicate a healthy funnel, low values highlight "leakage points".
```dax
Conversion Rate to Proposal = 
VAR OppsInProposalOrLater = 
    CALCULATE(
        COUNT(fact_opportunities[opportunity_key]),
        fact_opportunities[stage] IN {"Proposal", "Negotiation", "Closed Won"}
    )
VAR TotalOpps = COUNT(fact_opportunities[opportunity_key])
RETURN
    DIVIDE(OppsInProposalOrLater, TotalOpps, 0)
```

---

## 🛡️ 3. Segment & Stakeholder Specific Measures

### Hunter (New Logo) vs. Farmer (Expansion) Revenue Mix
Determines the percentage of total revenue driven by net-new logo acquisitions compared to expansion of existing accounts.
```dax
Hunter Revenue Mix % = 
DIVIDE(
    CALCULATE([Total Revenue], dim_sales_reps[rep_segment] = "Hunter"),
    [Total Revenue],
    0
)
```

```dax
Farmer Revenue Mix % = 
DIVIDE(
    CALCULATE([Total Revenue], dim_sales_reps[rep_segment] = "Farmer"),
    [Total Revenue],
    0
)
```

---

## 🎯 4. Target Gap Indicator (7% YoY Growth Target)

### Target Gap (Deficit)
Calculates the dollar difference between current year revenue and the required target of **7% growth over last year's revenue**.
```dax
Growth Target (7%) = [PY Revenue] * 1.07
```

```dax
Growth Gap to Target = 
VAR CurrentRev = [Total Revenue]
VAR Target = [Growth Target (7%)]
RETURN
    IF(CurrentRev < Target, Target - CurrentRev, 0)
```
