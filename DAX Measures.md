# DAX Measures & Calculated Columns
This document details all DAX measures and calculated columns created in the Power BI dashboard for the Telecom Customer Churn Analysis project.

## Power Query Transformations

The following data transformations were applied in Power BI's Power Query Editor:

- Standardised contract type labels for consistency:
  - `Month-to-month` → `Month-to-Month`
  - `One year` → `One Year`  
  - `Two year` → `Two Year`

## Measures

### Core Counts
```dax
Total Customers = COUNTROWS(customers) 
```
```dax 
Churned Customers = COUNTROWS(FILTER(customers, customers[Churn] = "Yes"))  
```
```dax
Retained Customers = COUNTROWS(FILTER(customers, customers[Churn] = "No"))  
```

### Churn & Retention Rates
```dax
Churn Rate = DIVIDE([Churned Customers], [Total Customers], 0)
```
```dax
-- Used for card visuals to show the value in decimal/numeric precision

Churn Rate NUM = DIVIDE([Churned Customers], [Total Customers], 0)
```
```dax
Retention Rate = 1 - [Churn Rate]
```

### Revenue Measures
```dax
Total Monthly Revenue = SUM(customers[MonthlyCharges])
```
```dax
Monthly Revenue Lost = 
CALCULATE(
    SUM(customers[MonthlyCharges]),
    customers[Churn] = "Yes"
)
```
```dax
Total Revenue Lost = 
CALCULATE(
    SUM(customers[TotalCharges]),
    customers[Churn] = "Yes"
)
```
```dax
Revenue at Risk % = DIVIDE([Monthly Revenue Lost], [Total Monthly Revenue], 0)
```
```dax
Avg Monthly Charge Churned = 
CALCULATE(
    AVERAGE(customers[MonthlyCharges]),
    customers[Churn] = "Yes"
)
```
```dax
Avg Monthly Charge Retained = 
CALCULATE(
    AVERAGE(customers[MonthlyCharges]),
    customers[Churn] = "No"
)
```
```dax
Avg Charge Difference = [Avg Monthly Charge Churned] - [Avg Monthly Charge Retained]
```

### Segment-Specific Churn Rates
```dax
Senior Churn Rate = 
CALCULATE(
    [Churn Rate Measure],
    customers[Senior Label] = "Senior"
)
```
```dax
Fiber Optic Churn Rate = 
CALCULATE(
    [Churn Rate Measure],
    customers[InternetService] = "Fiber optic"
)
```

### Risk Measures
```dax
Critical Risk Customers = 
CALCULATE(
    [Total Customers],
    customers[Risk Score] = 4
)
```
```dax
Retention Targets = 
CALCULATE
(
    [Total Customers],
    customers[Risk Score] >= 3
)
```
```dax
Retention Targets Churn Rate = 
CALCULATE(
    [Churn Rate Measure],
    customers[Risk Score] >= 3
)
```

## Calculated Columns
Calculated columns are added directly to the customers table in Power BI's Table view via **New Column**.
``` dax
Senior Label = IF(customers[SeniorCitizen] = 1, "Senior", "Non-Senior")
```
``` dax
Tenure Group = 
SWITCH(
    TRUE(),
    customers[tenure] = 0,        "New (No Billing Yet)",
    customers[tenure] <= 12,      "0–1 Year",
    customers[tenure] <= 24,      "1–2 Years",
    customers[tenure] <= 48,      "2–4 Years",
    customers[tenure] <= 72,      "4–6 Years",
    "Unknown"
)
```
``` dax
-- Used to sort Tenure Group correctly (not alphabetically)
-- After creating: Select Tenure Group → Column Tools → Sort by Column → Tenure Group Sort

Tenure Group Sort = 
SWITCH(
    TRUE(),
    customers[tenure] = 0,    0,
    customers[tenure] <= 12,  1,
    customers[tenure] <= 24,  2,
    customers[tenure] <= 48,  3,
    customers[tenure] <= 72,  4,
    5
)
```
``` dax
Auto Pay = 
IF(
    customers[PaymentMethod] IN {"Bank transfer (automatic)", "Credit card (automatic)"},
    "Auto Pay",
    "Manual Pay"
)
```
``` dax
Risk Score = 
VAR ContractRisk = IF(customers[Contract] = "Month-to-month", 1, 0)
VAR InternetRisk = IF(customers[InternetService] = "Fiber optic", 1, 0)
VAR PaymentRisk  = IF(customers[PaymentMethod] = "Electronic check", 1, 0)
VAR TenureRisk   = IF(customers[tenure] <= 12, 1, 0)
RETURN
    ContractRisk + InternetRisk + PaymentRisk + TenureRisk
```
``` dax
Risk Label = 
SWITCH(
    customers[Risk Score],
    4, "Critical",
    3, "High",
    2, "Medium",
    1, "Low",
    "Minimal"
)
```
## Risk Scoring Model
Each customer receives a risk score from 0 to 4 based on four equally-weighted binary churn risk factors:
| Factor            | High-Risk Condition | Score |
|-------------------|---------------------|-------|
| Contract type     | Month-to-Month      | +1    |
| Internet service  | Fiber optic         | +1    |
| Payment method    | Electronic check    | +1    |
| Tenure            | ≤ 12 months         | +1    |

## Score Interpretation
| Score | Risk Label | Meaning                                             |
|-------|------------|-----------------------------------------------------|
| 4     | Critical   | Meets all four high-risk conditions; highest priority for retention outreach |
| 3     | High       | Meets three conditions; elevated churn probability  |
| 2     | Medium     | Meets two conditions; monitor closely               |
| 1     | Low        | Meets one condition; low immediate risk             |
| 0     | Minimal    | Meets no conditions; lowest churn probability       |

## Results
- **606 critical risk customers** (Score = 4): immediate retention priority
- **1,891 retention targets** (Score ≥ 3): 26.8% of total customer base (1,891 ÷ 7,043)
- Retention targets churn at **59.44%** vs the overall rate of **26.54%**

Note: 
> The current model assigns equal weights to all four risk factors.  
> A machine-learning model could derive data-driven weights for more accurate scoring.