# Telecom Customer Churn Analysis

## Overview
This project analyses customer churn behavior for a fictional telecom company using the IBM Telco Customer Churn dataset (7,043 customers, 21 features). The goal is to identify the key drivers of churn, quantify the financial impact, and surface actionable retention insights through SQL analysis and an interactive Power BI dashboard.

The project covers end-to-end data analysis: MySQL setup, data cleaning, exploratory analysis, view creation, DAX modelling, risk scoring, and a four-page interactive Power BI dashboard with cross-page slicer synchronization, drill down, conditional formatting, and dynamic tooltips.

## Dataset
- **Source:** [IBM Telco Customer Churn — Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
- **Rows:** 7,043 customers
- **Columns:** 21 features including demographics, services, contract type, payment method, and churn status 

## Tools Used
- MySQL 8.0
- MySQL Workbench
- Power BI Desktop
- Looker Studio (Google Data Studio)
- DAX (Data Analysis Expressions)
- Git and GitHub

## Project Structure
```
telco-churn-analysis/
- telco_churn_analysis.sql             # Full SQL script: setup, cleaning, analysis, views
- Telco Customer Churn Dashboard.pbix  # Power BI dashboard file
- DAX Measures.md                      # DAX measures and calculated columns
- Looker Studio Dashboard              # Interactive dashboard
- README.md                            # Project documentation
```

## Data Cleaning
- Identified 11 rows silently skipped during import due to a space character in the `TotalCharges` column. The skipped records were not a true empty string. This was confirmed via `HEX()` and `LENGTH()` functions
- Replaced space characters on the `TotalCharges` column with `0` for customers with `tenure = 0` (new customers with no completed billing cycle)
- Converted `TotalCharges` from `VARCHAR` to `DECIMAL(10,2)` after cleaning
- Full null audit confirmed zero missing values across all 21 columns
- Additional data transformations applied in Power BI Power Query are documented
  in [DAX Measures.md](DAX%20Measures.md)

## SQL Analysis
### Views Created
|           View            | Description |
|---------------------------|----------|
| vw_churn_summary          | Overall churn counts and rate   | 
| vw_churn_by_contract      | Churn rate segmented by contract type  |
| vw_churn_by_tenure        | Churn rate segmented by tenure group |
| vw_churn_by_internet      | Churn rate segmented by internet service type |
| vw_churn_by_payment       | Churn rate segmented by payment method |
| vw_revenue_at_risk        | Monthly and total revenue lost to churn |
| vw_high_risk_customers    | Composite risk score (0–4) per customer based on four churn predictors |

### SQL Concepts Demonstrated
- Database and table creation with appropriate data types
- Data loading via MySQL Workbench Table Data Import Wizard
- Data cleaning: `UPDATE`, `ALTER TABLE`, `TRIM()`, `HEX()`, `LENGTH()`
- Exploratory analysis: `GROUP BY`, `COUNT`, `SUM`, `AVG`, `ROUND`
- Conditional aggregation: `CASE WHEN`
- Subqueries
- Window functions: `SUM() OVER()`, `LAG()`
- Views: `CREATE VIEW`

## Power BI Dashboard
The dashboard is structured across four pages, with slicers for Contract Type and Internet Service synchronized across all pages. All KPI cards are isolated from cross-filter interactions to preserve headline figures. Conditional formatting (red/amber/green) is applied consistently across all bar charts and matrix visuals.

### Page 1: Churn Overview
**KPI Cards:** Total Customers · Churned Customers · Churn Rate · Monthly Revenue Lost · Total Revenue Lost 

**Charts:**  
- Churn Rate by Contract Type *(drill down to Tenure Group)*  
- Churn Rate by Internet Service *(drill down to Tenure Group)*  
- Churn Rate by Payment Method  
- Churn Rate by Tenure Group  

**Slicers:** Filter by Contract Type · Filter by Internet Service *(synced across all pages)*

### Page 2: Revenue Impact
**KPI Cards:** Total Monthly Revenue · Monthly Revenue Lost · Total Revenue Lost · Revenue at Risk % · Avg Charge Difference

**Charts:**
- Monthly Revenue Lost by Contract Type
- Monthly Revenue Lost by Internet Service
- Avg Monthly Charge: Churned vs Retained by Contract Type
- Cumulative Churn Rate by Tenure *(line chart with overall churn rate reference line)*

**Slicers:** Filter by Contract Type · Filter by Internet Service

### Page 3: Customer Segments
**KPI Cards:** Total Customers · Churned Customers · Overall Churn Rate · Senior Citizen Churn Rate

**Charts:**
- Churn Rate by Dependents
- Churn Rate by Senior Status
- Churn Rate by Partner Status
- Churn Rate by Gender
- Churn Rate by Senior Status and Contract Type *(grouped column)*
- Risk Score Distribution *(donut chart)*

**Risk Summary Cards**: Critical Risk Customers · Retention Target · Retention Target Churn Rate

**Slicers:** Filter by Contract Type · Filter by Internet Service · Filter by Senior Status

### Page 4: Service Analysis
**KPI Cards:** Total Customers · Churned Customers · Overall Churn Rate · Fiber Optic Churn Rate

**Charts:**
- Churn Rate by Internet Service
- Churn Rate by Online Security
- Churn Rate by Tech Support
- Churn Rate by Internet Service and Contract Type *(matrix with heatmap conditional formatting)*

**Slicers:** Filter by Contract Type · Filter by Internet Service

## DAX Measures & Calculated Columns
Full documentation of all DAX measures, calculated columns, and the risk scoring model is available in the dedicated reference file:  
[DAX Measures.md](DAX%20Measures.md)

## Looker Studio Dashboard
To demonstrate cross-platform BI proficiency, the same churn analysis was rebuilt in **Looker Studio (Google Data Studio)**.  
[View Interactive Looker Studio Dashboard](https://datastudio.google.com/s/vWXOfoP3k3M)

### Looker Studio Implementation Highlights

- **Data Source:** Google Sheets connected to the dataset
- **Calculated Fields:** Custom churn rate, revenue lost, and cumulative churn metrics 
- **Charts:** Bar charts, line chart, pivot table, donut chart 
- **Pivot Table:** Churn rate matrix showing Internet Service vs Contract Type with heatmap conditional formatting
- **Reference Lines:** Overall churn rate (26.54%) as a constant line on cumulative churn chart
- **Interactive Filters:** Dropdown controls for Contract Type and Internet Service 
- **Conditional Formatting:** Red/amber/green heatmap applied consistently across bar charts and pivot tables

## Key Findings

### Churn Rate
- Overall churn rate: **26.54%** (1,869 out of 7,043 customers)

### Contract Type
- Month-to-month customers churn at **43%**, nearly 4x higher than 
  one year (11%) and 14x higher than two year contracts (3%)
- Over half of all customers (55%) are on month-to-month contracts
- Month-to-month customers account for **$121K** of **$139K** monthly revenue lost (87%) 
- Two year contracts reduce churn to single digits across all service types

### Tenure
- 0–1 Year: **48%** churn. Highest risk period in the customer lifecycle. Surviving the first year is the strongest indicator of long-term retention
- 1–2 Years: **29%** · 2–4 Years: **20%** · 4–6 Years: **10%** 
- Churn rate rebounds at months 65–70, suggesting contract renewal pressure at the loyalty stage

### Internet Service
- Fiber optic: **42%** churn · DSL: **19%** · No internet: **7%** 
- Fiber optic accounts for **$114K** of **$139K** monthly revenue lost (82%) 
- Fiber optic + Month-to-Month: **54.61%**. This is the highest risk combination in the dataset, more than double the overall churn rate

### Payment Method
- Electronic check: **45%** churn 
- Mailed check: **19%** · Bank transfer (automatic): **17%** · Credit card (automatic): **15%** 
- Auto-pay customers churn at approximately one third the rate of manual pay customers

### Demographics
- Senior citizens: **42%** churn vs Non-senior: **24%** 
- Seniors on month-to-month contracts: **55%**; highest demographic risk intersection 
- Gender has minimal impact: Female **27%** vs Male **26%**; not a meaningful predictor
- Customers without partners: **33%** vs with partners: **20%** 
- Customers without dependents: **31%** vs with dependents: **15%**

### Service Add-ons
- No online security: **42%** churn vs with online security: **15%**, a 27 percentage point gap
- No tech support: **42%** churn vs with tech support: **15%**, an identical pattern
- Online security and tech support are the strongest service-level churn predictors

### Revenue Impact
- Total Monthly Revenue: **$456,117** 
- Monthly Revenue Lost to Churn: **$139,131** 
- Cumulative Revenue Lost: **$2,862,927** 
- Percentage of Revenue at Risk: **30.5%** 
- Churned customers pay an average of **$13** more per month than retained customers, suggesting price sensitivity is a churn driver

### Risk Scoring
- **1,891 retention targets** (Risk Score ≥ 3), representing 26.8% of the total 
  customer base (1,891 ÷ 7,043)
- **606 critical risk customers** (Risk Score = 4), the highest priority segment 
  for retention intervention
- Retention targets churn at **59.44%**, more than double the overall rate of 26.54%

## Business Recommendations
1. **Prioritize Contract Conversion:** Converting month-to-month customers to annual contracts is the single highest-impact retention action, targeting the 43% churn rate and $121K monthly revenue exposure 
2. **Invest in First-Year Retention Programs:** 48% of customers churn within 12 months. Onboarding improvements, proactive check-ins at months 3 and 6, and early loyalty incentives could significantly reduce early-stage churn 
3. **Investigate Fiber Optic Service Quality:** 54.61% churn among fiber optic month-to-month customers suggests pricing or service quality issues. Targeted retention offers and service audits are warranted for this segment 
4. **Bundle Online Security and Tech Support.** The 27-percentage point churn reduction associated with these add-ons suggests they should be promoted aggressively, potentially as free trial add-ons for high-risk customers 
5. **Migrate Electronic Check Users to Auto-Pay:** Nudging customers toward automatic payment methods reduces churn from 45% to 15–17%, a low-cost, high-impact intervention 
6. **Design a Senior Citizen Retention Program.** At 42% overall and 55% on month-to-month contracts, senior customers are disproportionately at risk. Dedicated support channels, simplified plans, and contract conversion incentives are warranted 
7. **Immediate Outreach to 606 Critical Risk Customers:** These customers meet all four churn risk factors simultaneously. Proactive retention intervention on this segment could protect significant monthly recurring revenue

## Limitations & Future Work
### Limitations
- The dataset is static. Churn trends over time cannot be tracked without time-series data
- No customer satisfaction or NPS (Net Promoter Score) data is available to correlate with churn behavior
- The risk scoring model assigns equal weights to all four factors. A machine learning model could derive data-driven weights for more accurate scoring

### Future Work
Build a predictive churn model in Python using this dataset, deployable as a real-time customer risk scoring pipeline


## Author
**Linda Nyakasi**  
Certified Data Analyst | Pursuing Data Science & Machine Learning  
[LinkedIn](https://www.linkedin.com/in/linda-nyakasi) | [GitHub](https://github.com/Linda-Nyakasi)
