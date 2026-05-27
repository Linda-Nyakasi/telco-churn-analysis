# Telecom Customer Churn Analysis

## Overview
This project analyses customer churn behaviour for a fictional telecom company 
using the IBM Telco Customer Churn dataset (7,043 customers, 21 features). 
The goal is to identify the key drivers of churn and quantify the impact on revenue 
using SQL.

## Dataset
- **Source:** [IBM Telco Customer Churn — Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
- **Rows:** 7,043 customers
- **Columns:** 21 features including demographics, services, contract type, 
  payment method, and churn status

## Tools Used
- MySQL 8.0
- MySQL Workbench
- Power BI

## Project Structure
```
telco-churn-analysis/
- telco_churn_analysis.sql   # Full SQL script: setup, cleaning, analysis, views
- README.md                  # Project documentation
```
## Data Cleaning
- Identified 11 rows silently skipped during import due to a space character 
  in the `TotalCharges` column. The skipped records were not a true empty string. 
  This was confirmed via `HEX()` and `LENGTH()` functions
- Replaced space characters on the `TotalCharges` column with `0` for customers with `tenure = 0` (new customers with no completed billing cycle)
- Converted `TotalCharges` from `VARCHAR` to `DECIMAL(10,2)` after cleaning
- Full null audit confirmed zero missing values across all 21 columns

## Key Findings

### Churn Rate
- Overall churn rate: **26.58%** (1,869 out of 7,043 customers)

### Contract Type
- Month-to-month customers churn at **43%**, nearly 4x higher than 
  one year (11%) and 14x higher than two year contracts (3%)
- Over half of all customers (55%) are on month-to-month contracts

### Tenure
- Customers in their first year churn at **48%**
- Churn drops to **10%** for customers of 4–6 years
- Surviving the first year is the strongest indicator of long-term retention

### Internet Service
- Fiber optic customers churn at **41.89%**, which is more than double the DSL rate (18.96%)
- Customers with no internet service are the most loyal at **7.40%**

### Payment Method
- Electronic check customers churn at **45.29%**, nearly 3x higher than 
  automatic payment methods (bank transfer: 16.71%, credit card: 15.24%)

### Senior Citizens
- Senior customers churn at **41.68%** vs 23.61% for non-seniors

### Revenue Impact
- Monthly recurring revenue lost to churn: **$139,130.85**
- Total historical revenue lost: **$2,862,926.90**

## Business Recommendations
1. **Convert month-to-month customers** to longer contracts through incentives. This single factor has the highest impact on churn
2. **Invest in first-year retention programs**: Nearly half of new customers 
   churn within 12 months
3. **Investigate fiber optic service quality**. Premium customers are leaving 
   at a disproportionate rate
4. **Incentivise automatic payments**: Customers on auto-pay churn at 3x 
   lower rates than electronic check users
5. **Design targeted retention offers for senior customers**: Senior customers churn at 
   nearly twice the rate of non-seniors

## SQL Concepts Demonstrated
- Database and table creation with appropriate data types
- Data loading via MySQL Workbench Table Data Import Wizard
- Data cleaning: `UPDATE`, `ALTER TABLE`, `TRIM()`, `HEX()`, `LENGTH()`
- Exploratory analysis: `GROUP BY`, `COUNT`, `SUM`, `AVG`, `ROUND`
- Conditional aggregation: `CASE WHEN`
- Subqueries
- Window functions: `SUM() OVER()`, `LAG()`
- Views: `CREATE VIEW`

## Author
**Linda Nyakasi**  
Certified Data Analyst | Pursuing Data Science & Machine Learning  
[LinkedIn](www.linkedin.com/in/linda-nyakasi) | [GitHub](https://github.com/Linda-Nyakasi)
