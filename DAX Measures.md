# DAX Measures & Calculated Columns
This document details all DAX measures and calculated columns created in the Power BI report for the Telecom Customer Churn Analysis project.

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
-- Formatted to 0 decimal places for use on chart axes for compact display

Churn Rate = DIVIDE([Churned Customers], [Total Customers], 0)
```
```dax
-- Formatted to 2 decimal places for use on KPI cards

Churn Rate NUM = DIVIDE([Churned Customers], [Total Customers], 0)
```
```dax
Retention Rate = 1 - [Churn Rate NUM]
```

### Revenue Measures
```dax
Total Monthly Revenue = SUM(customers[MonthlyCharges])
```
```dax
Monthly Revenue Lost = 
CALCULATE
(
    SUM(customers[MonthlyCharges]),
    customers[Churn] = "Yes"
)
```
```dax
Total Revenue Lost = 
CALCULATE
(
    SUM(customers[TotalCharges]),
    customers[Churn] = "Yes"
)
```
```dax
Revenue at Risk % = DIVIDE([Monthly Revenue Lost], [Total Monthly Revenue], 0)
```
```dax
Average Monthly Charge Churned = 
CALCULATE
(
    AVERAGE(customers[MonthlyCharges]),
    customers[Churn] = "Yes"
)
```
```dax
Average Monthly Charge Retained = 
CALCULATE
(
    AVERAGE(customers[MonthlyCharges]),
    customers[Churn] = "No"
)
```
```dax
Average Charge Difference = [Average Monthly Charge Churned] - [Average Monthly Charge Retained]
```

### Segment-Specific Churn Rates
```dax
Senior Churn Rate = 
CALCULATE
(
    [Churn Rate NUM],
    customers[Senior Label] = "Senior"
)
```
```dax
Fiber Optic Churn Rate = 
CALCULATE
(
    [Churn Rate NUM],
    customers[InternetService] = "Fiber optic"
)
```

### Risk Measures
```dax
Critical Risk Customers = 
CALCULATE
(
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
CALCULATE
(
    [Churn Rate NUM],
    customers[Risk Score] >= 3
)
```

> **Note on segment-specific charts:** Churn rates for individual categories such as Online Security, Tech Support, and Payment Method are derived by placing the category field on the chart axis and using [Churn Rate] as the value. DAX evaluates the measure within each category's filter context automatically, without requiring separate explicit measures for each segment.

## Calculated Columns
Calculated columns are added directly to the customers table in Power BI's Table view via **New Column**.
``` dax
Senior Label = IF(customers[SeniorCitizen] = 1, "Senior", "Non-Senior")
```
``` dax
Tenure Group = 
SWITCH
(
    TRUE(),
    customers[tenure] = 0, "New (Not Billed yet)",
    customers[tenure] <= 12, "0-1 Year",
    customers[tenure] <= 24, "1-2 Years",
    customers[tenure] <= 48, "2-4 Years",
    customers[tenure] <= 72, "4-6 Years",
    "Unknown"
)
```
``` dax
-- Used to sort Tenure Group correctly (not alphabetically)
-- After creating: Select Tenure Group → Column Tools → Sort by Column → Tenure Group Sort

Tenure Group Sort = 
SWITCH
(
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
    VAR ContractRisk = IF(customers[Contract] = "Month-to-Month", 1, 0)
    VAR InternetRisk = IF(customers[InternetService] = "Fiber optic", 1, 0)
    VAR PaymentRisk = IF(customers[PaymentMethod] = "Electronic check", 1, 0)
    VAR TenureRisk = IF(customers[tenure] <= 12, 1, 0)
RETURN ContractRisk + InternetRisk + PaymentRisk + TenureRisk
```
``` dax
Risk Label = 
SWITCH
(
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

### Score Interpretation
| Score | Risk Label | Meaning                                             |
|-------|------------|-----------------------------------------------------|
| 4     | Critical   | Meets all four high-risk conditions; highest priority for retention outreach |
| 3     | High       | Meets three conditions; elevated churn probability  |
| 2     | Medium     | Meets two conditions; monitor closely               |
| 1     | Low        | Meets one condition; low immediate risk             |
| 0     | Minimal    | Meets no conditions; lowest churn probability       |

### Results
- **631 critical risk customers** (Score = 4): immediate retention priority
- **1,919 retention targets** (Score ≥ 3): 27.2% of total customer base (1,919 ÷ 7,043)
- Retention targets churn at **59.25%** vs the overall rate of **26.54%**

> Note: The current model assigns equal weights to all four risk factors. A machine-learning model could derive data-driven weights for more accurate scoring.