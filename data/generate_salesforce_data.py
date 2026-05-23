import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

# Seed for reproducibility
np.random.seed(42)

# Generate mock data
num_opportunities = 800

stages = ['Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost']

reps = {
    'Hunter': ['Alice Smith', 'Bob Jones', 'Charlie Brown', 'Diana Prince'],
    'Farmer': ['Evan Wright', 'Fiona Gallagher', 'George Costanza', 'Helen Mirren']
}

verticals = ['Healthcare', 'Financial Services', 'Technology', 'Manufacturing', 'Retail']

data = []
start_date = datetime(2024, 1, 1)

for i in range(num_opportunities):
    opp_id = f"006{np.random.randint(100000000, 999999999)}"
    
    # Assign rep type (Hunter vs Farmer)
    rep_type = np.random.choice(['Hunter', 'Farmer'], p=[0.40, 0.60])
    rep_name = np.random.choice(reps[rep_type])
    
    # Generate close date spread across 2024 and 2025
    days_to_add = np.random.randint(0, 730) # 2 years
    close_date = start_date + timedelta(days=days_to_add)
    
    # Growth trend simulation: slightly higher amounts in 2025 but stagnant overall
    is_2025 = close_date.year == 2025
    base_amount = np.random.exponential(scale=25000) + 5000
    if rep_type == 'Farmer':
        amount = base_amount * 1.5 # Farmers manage larger account expansions
    else:
        amount = base_amount * 0.8 # Hunters pursue net-new logos (initially smaller)
        
    if is_2025:
        amount *= 1.015 # 1.5% stagnant growth trend (Case Study premise)
        
    vertical = np.random.choice(verticals)
    
    # Determine stage and win/loss behavior
    # Farmers have high win rates, Hunters have lower win rates (new logos are harder)
    if rep_type == 'Farmer':
        stage = np.random.choice(stages, p=[0.05, 0.05, 0.10, 0.10, 0.55, 0.15]) # 55% closed won
    else:
        stage = np.random.choice(stages, p=[0.15, 0.20, 0.25, 0.15, 0.10, 0.15]) # 10% closed won
        
    # Generate activity metrics (calls, meetings, emails)
    # Stagnant growth is driven by low Hunter activity. We will reflect that in the data.
    if rep_type == 'Hunter':
        calls = np.random.randint(5, 20)
        meetings = np.random.randint(1, 5)
        emails = np.random.randint(10, 40)
    else:
        calls = np.random.randint(2, 10)
        meetings = np.random.randint(2, 8)
        emails = np.random.randint(15, 60)
        
    # Age of opportunity (velocity)
    lead_created_days_before = np.random.randint(30, 180)
    created_date = close_date - timedelta(days=lead_created_days_before)
    
    data.append({
        'Opportunity_ID': opp_id,
        'Opportunity_Name': f"{vertical} - {rep_type} Opp {i}",
        'Account_Name': f"{vertical} Corp {np.random.randint(100, 999)}",
        'Owner_Name': rep_name,
        'Rep_Segment': rep_type,
        'Stage': stage,
        'Amount_USD': round(amount, 2),
        'Created_Date': created_date.strftime('%Y-%m-%d'),
        'Close_Date': close_date.strftime('%Y-%m-%d'),
        'Vertical': vertical,
        'Calls_Logged': calls,
        'Meetings_Logged': meetings,
        'Emails_Logged': emails,
        'Lead_Source': np.random.choice(['Outbound Cold Call', 'Inbound Web', 'Event/Conference', 'Partner Referral'], p=[0.4, 0.3, 0.2, 0.1])
    })

df = pd.DataFrame(data)

# Ensure the output directory exists
os.makedirs('data', exist_ok=True)
df.to_csv('data/salesforce_opportunities.csv', index=False)
print("Successfully generated data/salesforce_opportunities.csv")
