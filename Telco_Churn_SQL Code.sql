-- ============================================================
-- PHASE 1: CHOOSE YOUR SQL TOOL & LOAD THE DATA
-- ============================================================

-- Create database for the project
CREATE DATABASE telco_churn;
USE telco_churn;

-- Create a table and load data into it
-- Note: TotalCharges is VARCHAR(20) not DECIMAL — reason documented below
CREATE TABLE customers
(
	customerID VARCHAR(20),
	gender VARCHAR(10), -- Whether the customer is a male or a female
	SeniorCitizen INT, -- Whether the customer is a senior citizen or not (1, 0)
	Partner VARCHAR(5), -- Whether the customer has a partner or not (Yes, No)
	Dependents VARCHAR(5), -- Whether the customer has dependents or not (Yes, No)
	tenure INT, -- Number of months the customer has stayed with the company
	PhoneService VARCHAR(5), -- Whether the customer has a phone service or not (Yes, No)
	MultipleLines VARCHAR(20), -- Whether the customer has multiple lines or not (Yes, No, No phone service)
	InternetService VARCHAR(20), -- Customer’s internet service provider (DSL, Fiber optic, No)
	OnlineSecurity VARCHAR(20), -- Whether the customer has online security or not (Yes, No, No internet service)
	OnlineBackup VARCHAR(20), -- Whether the customer has online backup or not (Yes, No, No internet service)
	DeviceProtection VARCHAR(20), -- Whether the customer has device protection or not (Yes, No, No internet service)
	TechSupport VARCHAR(20), -- Whether the customer has tech support or not (Yes, No, No internet service)
	StreamingTV VARCHAR(20), -- Whether the customer has streaming TV or not (Yes, No, No internet service)
	StreamingMovies VARCHAR(20), -- Whether the customer has streaming movies or not (Yes, No, No internet service)
	Contract VARCHAR(20), -- The contract term of the customer (Month-to-month, One year, Two year)
	PaperlessBilling VARCHAR(5), -- Whether the customer has paperless billing or not (Yes, No)
	PaymentMethod VARCHAR(30), -- The customer’s payment method (Electronic check, Mailed check, Bank transfer (automatic), Credit card)
	MonthlyCharges DECIMAL(10,2), -- The amount charged to the customer monthly
	TotalCharges VARCHAR(20), -- The total amount charged to the customer
	Churn VARCHAR(5) -- Whether the customer churned or not (Yes or No)
);

-- Load the data from CSV
/*
-On the left panel, expand telco_churn. Tables >> right-click customers >> Tabe Data Import Wizard
-Browse the downloaded CSV and select it
-Click through the wizard and select Use existing table: telco_churn.customers
-Click next until it finishes importing
*/
-- If the data did'nt load correctly, delete the rows from the table customers using:
TRUNCATE TABLE customers; 

-- Verify all rows were loaded into the table:
SELECT COUNT(*) FROM customers;
-- Expected: 7043 | Actual: 7032 → 11 rows missing

-- ============================================================
-- DEBUGGING: 11 rows missing after import
-- ============================================================

/*
DISCOVERY:
The table was initially created with TotalCharges as DECIMAL(10,2).
MySQL silently skipped 11 rows during import where TotalCharges could not be converted to a decimal number.

This was confirmed by recreating the table with TotalCharges as VARCHAR(20). All 7,043 rows loaded successfully, 
proving TotalCharges was the problem column.
*/

-- Step 1: Identify the affected rows
SELECT customerID, tenure, MonthlyCharges, TotalCharges
FROM customers
WHERE TRIM(TotalCharges) = '';

/*
FINDING:
All 11 affected rows have tenure = 0.
These are brand new customers who joined but haven't completed a billing cycle yet. 
TotalCharges is blank in the source data because the new customers have not been billed anything in total yet, 
even though a MonthlyCharges rate is already assigned.
*/

-- Step 2: Investigate why null audit returned 0 for TotalCharges yet 11 rows were still missing
SELECT 
    COUNT(CASE WHEN TotalCharges IS NULL OR TotalCharges = '' THEN 1 ELSE 0 END) AS count_total,
    SUM(CASE WHEN TotalCharges IS NULL OR TotalCharges = '' THEN 1 ELSE 0 END) AS sum_total
FROM customers
WHERE TRIM(TotalCharges) = '';

/*
EXPLANATION:
Both queries are pre-filtered to the 11 affected rows by the WHERE clause.
The CASE condition checks for NULL or empty string ('').

- COUNT counts all rows regardless of value (1s and 0s alike) -- returns 11
- SUM adds up the actual values → if CASE evaluates to 0 for every row, SUM = 0

The CASE was returning 0 (ELSE branch) for all 11 rows, meaning TotalCharges = '' was NOT matching. 
This means the values are not true empty strings. Something else is stored in those cells.
*/

-- Step 3: Inspect the raw content using LENGTH() and HEX()
SELECT 
    customerID,
    LENGTH(TotalCharges) AS char_length,
    HEX(TotalCharges) AS hex_value
FROM customers
WHERE tenure = 0;

/*
FINDING:
- char_length = 1 (not 0, confirming it is not a true empty string)
- hex_value = 20 (hex code for a space character in ASCII)

The 11 cells contain a single space ' ' not an empty string ''.
This is why TRIM(TotalCharges) = '' matched them (because TRIM strips spaces) but TotalCharges = '' did not.
*/

-- Step 4: Confirm the correct condition matches all 11 rows
SELECT 
    SUM(CASE WHEN TotalCharges IS NULL OR TotalCharges = ' ' THEN 1 ELSE 0 END) AS null_total
FROM customers
WHERE TRIM(TotalCharges) = '';
-- Result: 11 

-- ============================================================
-- FIX
-- ============================================================

-- Step 5: Replace space characters with 0
SET SQL_SAFE_UPDATES = 0;

UPDATE customers
SET TotalCharges = '0'
WHERE TRIM(TotalCharges) = '';

SET SQL_SAFE_UPDATES = 1;

-- Step 6: Convert TotalCharges from VARCHAR to DECIMAL. This is Safe to do now since all blank values have been replaced
ALTER TABLE customers MODIFY COLUMN TotalCharges DECIMAL(10,2);

-- Step 7: Verify the fix
SELECT customerID, tenure, MonthlyCharges, TotalCharges
FROM customers
WHERE tenure = 0;
-- All 11 rows should now show TotalCharges = 0.00

-- Step 8: Confirm final row count
SELECT COUNT(*) FROM customers;
-- Expected: 7043 

-- ============================================================
-- PHASE 2: CLEANING AND EXPLORING THE DATA
-- ============================================================

-- Preview the data
SELECT * 
FROM customers
LIMIT 10;

-- Check for NULLs accross key columns
SELECT
    SUM(CASE WHEN customerID IS NULL OR customerID = '' THEN 1 ELSE 0 END) AS null_customerID,
    SUM(CASE WHEN gender IS NULL OR gender = '' THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN SeniorCitizen IS NULL THEN 1 ELSE 0 END) AS null_senior,
    SUM(CASE WHEN Partner IS NULL OR Partner = '' THEN 1 ELSE 0 END) AS null_partner,
    SUM(CASE WHEN Dependents IS NULL OR Dependents = '' THEN 1 ELSE 0 END) AS null_dependents,
    SUM(CASE WHEN tenure IS NULL THEN 1 ELSE 0 END) AS null_tenure,
    SUM(CASE WHEN Contract IS NULL OR Contract = '' THEN 1 ELSE 0 END) AS null_contract,
    SUM(CASE WHEN MonthlyCharges IS NULL THEN 1 ELSE 0 END) AS null_monthly,
    SUM(CASE WHEN TotalCharges IS NULL THEN 1 ELSE 0 END) AS null_total,
    SUM(CASE WHEN Churn IS NULL OR Churn = '' THEN 1 ELSE 0 END) AS null_churn
FROM customers;

/*
NOTE ON DATA TYPES AND NULL CHECKS:
VARCHAR columns are checked with IS NULL OR TRIM(col) = '' to catch both true NULLs and whitespace-only strings.

DECIMAL/INT columns are checked with IS NULL only. 
Numeric columns (like TotalCharges) cannot store empty strings or spaces. So a simple NULL check is sufficient.
*/

--  Churn split (how many churned vs stayed)
SELECT
	Churn,
    COUNT(*) AS Total,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM customers), 2) AS Percentage
FROM customers
GROUP BY Churn
ORDER BY percentage DESC;

-- Gender Split
SELECT
	gender,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM customers), 2) AS percentage
FROM customers
GROUP BY gender
ORDER BY percentage DESC;

-- Contract Types
SELECT
	Contract,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM customers), 2) AS percentage
FROM customers
GROUP BY Contract
ORDER BY percentage DESC;

-- ============================================================
-- PHASE 3: ANALYSIS QUERIES
-- ============================================================

-- Churn Rate by Contract Type
SELECT 
	Contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*)) AS churn_rate
FROM customers
GROUP BY Contract
ORDER BY churn_rate DESC;
/*
FINDINGS:
Month-to-month customers churn at 43%, nearly 4x higher than one year contracts (11%) and 14x higher than two year contracts (3%).
Customers without long-term commitment leave at an alarming rate  
The business should prioritize converting month-to-month customers to longer contracts as a retention strategy.
*/

-- Churn rate by tenure group
-- First, identify the max and min values so you can correctly map tenure into in bins
SELECT MAX(tenure), MIN(tenure) FROM customers;
SELECT
	CASE 
		WHEN tenure = 0 THEN 'New (No Billing Yet)'
        WHEN tenure BETWEEN 1 AND 12 THEN '0-1 Year'
		WHEN tenure BETWEEN 13 AND 24 THEN '1-2 Years'
		WHEN tenure BETWEEN 25 AND 48 THEN '2-4 Years'
		WHEN tenure BETWEEN 49 AND 72 THEN '4-6 Years'
    END AS tenure_group,
	COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*)) AS churn_rate
FROM customers
GROUP BY tenure_group
ORDER BY churn_rate DESC;
/*
FINDINGS:
Churn drops sharply the longer a customer stays:
- 0-1 Year:  48% churn rate — highest risk group
- 1-2 Years: 29% churn rate
- 2-4 Years: 20% churn rate
- 4-6 Years: 10% churn rate — most loyal group

- Nearly half of all customers in their first year churn.
- If a customer survives the first year, they are significantly more likely to stay long term.
- The business should focus retention efforts heavily on new customers  
*/

-- Average monthly charges: churned vs retained
SELECT 
	Churn,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(MIN(MonthlyCharges), 2) AS min_monthly_charges,
    ROUND(MAX(MonthlyCharges), 2) AS max_monthly_charges
FROM customers
GROUP BY Churn;
/*
FINDINGS:
- Churned customers paid on average $74.44/month compared to  $61.27 for retained customers, a difference of $13.17/month.
- Min and max charges are comparable across both groups, meaning the gap is not driven by outliers but is a consistent pattern 
across the churned segment.
- Higher-paying customers are leaving at a disproportionate rate, suggesting pricing pressure or unmet expectations at the premium tier.
*/

--  Revenue at risk (lost from churned customers)
SELECT
	ROUND(SUM(MonthlyCharges), 2) AS monthly_revenue_lost,
    ROUND(SUM(TotalCharges), 2) AS Total_revenue_lost
FROM customers
WHERE Churn = 'Yes';
/*
FINDINGS:
- Monthly recurring revenue lost to churn: $139,130.85
- Total historical revenue lost from churned customers: $2,862,926.90

- This represents the direct financial impact of churn on the business.
- The gap between monthly and total revenue lost also reflects that many churned customers were relatively new (high churn in year 1),
meaning they didn't generate much total revenue before leaving.
*/

--  Churn by internet service type
SELECT 
    InternetService,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY InternetService
ORDER BY churn_rate DESC;
/*
FINDINGS:
- Fiber optic: 41.89% churn rate (3,096 customers)
- DSL:         18.96% churn rate (2,421 customers)
- No internet: 7.40%  churn rate (1,526 customers)

- Fiber optic customers churn at more than twice the rate of DSL customers despite being a premium service. 
- This may indicate service quality issues, higher pricing sensitivity, or stronger competition in the fiber optic segment.
- Customers with no internet service are the most loyal group, likely due to lower costs and fewer alternatives.
*/

-- Churn by senior citizen status
SELECT 
    CASE WHEN SeniorCitizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS customer_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY SeniorCitizen
ORDER BY churn_rate DESC;
/*
FINDINGS:
- Senior customers:     41.68% churn rate (1,142 customers)
- Non-senior customers: 23.61% churn rate (5,901 customers)

- Senior citizens churn at nearly twice the rate of non-seniors.
- This is a significant finding. Seniors may face challenges with service complexity, pricing on fixed incomes, or may be more 
susceptible to competitor offers. 
- Targeted retention programs for senior customers could have a meaningful impact.
*/

-- Churn by payment method
SELECT 
    PaymentMethod,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY PaymentMethod
ORDER BY churn_rate DESC;
/*
FINDINGS:
- Electronic check:        45.29% churn rate (2,365 customers)
- Mailed check:            19.11% churn rate (1,612 customers)
- Bank transfer (auto):    16.71% churn rate (1,544 customers)
- Credit card (auto):      15.24% churn rate (1,522 customers)

- Electronic check customers churn at nearly 3x the rate of automatic payment customers (bank transfer and credit card).
- Automatic payment methods correlate strongly with retention. Customers on auto-pay are less likely to actively think about 
cancelling, and switching friction may also play a role.
- This suggests the business should incentivise customers to switch from manual to automatic payment methods.
*/

-- Cumulative churn by tenure 
SELECT
	tenure,
    total_customers,
    churned,
    ROUND(churned * 100.0 / total_customers, 2) AS churn_rate,
	-- Month-over-Month change in churn rate
	ROUND((churned * 100.0 / total_customers) - LAG(churned * 100.0 / total_customers) OVER(ORDER BY tenure), 2) AS mom_churn_rate_change,
    -- Cumulative churned count
    SUM(churned) OVER(ORDER BY tenure) AS cumulative_churned,
    -- Cumulative churn as % of all churned customers, i.e., Of those who churned, how many had churned by month X?
    ROUND(SUM(churned) OVER (ORDER BY tenure) * 100.0 / SUM(churned) OVER (), 2) AS cumulative_churn_pct_of_churned,
    -- Cumulative churn as % of total customer base, i.e., 'How much of our total base has churned by month X?'
    ROUND(SUM(churned) OVER(ORDER BY tenure) * 100 / SUM(total_customers) OVER (), 2) AS cumulative_churn_pct_of_base
FROM
	(
	SELECT 
		tenure,
		COUNT(*) AS total_customers,
		SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned
	FROM customers
	GROUP BY tenure
	) AS tenure_summary
;
/*
FINDINGS:
- The MoM churn rate change column shows churn is most volatile in early tenure months, fluctuating significantly in year 1.
- Churn rate stabilises and trends downward from year 2 onwards.
- cumulative_churn_pct_of_churned reaches 100% at tenure = 72, confirming all 1,869 churned customers are accounted for.
- cumulative_churn_pct_of_base reaches 26.54% at tenure = 72, matching the overall churn rate calculated in Phase 2 (Churn split fo Churn = 'Yes'). 

WINDOW FUNCTIONS USED:
- SUM() OVER (ORDER BY tenure): running total of churned customers
- SUM() OVER (): grand total across all rows (no ORDER BY)
- LAG(): accesses the previous row's churn rate for MoM comparison
*/

-- ============================================================
-- PHASE 4: VIEWS 
-- ============================================================

/*
- Views are virtual tables built from saved queries.
- They don't store data themselves. They simply store the query logic and return fresh results every time they are called.
- This makes your analysis reusable and keeps the main tables clean.
*/

-- View 1: Overall Churn Summary
CREATE VIEW vw_churn_summary AS
SELECT 
    Churn,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS percentage
FROM customers
GROUP BY Churn;
-- Usage: SELECT * FROM vw_churn_summary;

-- View 2: Churn by Contract Type
CREATE VIEW vw_churn_by_contract AS
SELECT 
    Contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY Contract
ORDER BY churn_rate DESC;
-- Usage: SELECT * FROM vw_churn_by_contract;

-- View 3: Churn by Tenure Group
CREATE VIEW vw_churn_by_tenure AS
SELECT 
    CASE 
        WHEN tenure = 0 THEN 'New (No Billing Yet)'
        WHEN tenure BETWEEN 1 AND 12 THEN '0-1 Year'
        WHEN tenure BETWEEN 13 AND 24 THEN '1-2 Years'
        WHEN tenure BETWEEN 25 AND 48 THEN '2-4 Years'
        WHEN tenure BETWEEN 49 AND 72 THEN '4-6 Years'
    END AS tenure_group,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY tenure_group
ORDER BY churn_rate DESC;
-- Usage: SELECT * FROM vw_churn_by_tenure;

-- View 4: Churn by Internet Service
CREATE VIEW vw_churn_by_internet AS
SELECT 
    InternetService,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY InternetService
ORDER BY churn_rate DESC;
-- Usage: SELECT * FROM vw_churn_by_internet;

-- View 5: Churn by Payment Method
CREATE VIEW vw_churn_by_payment AS
SELECT 
    PaymentMethod,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY PaymentMethod
ORDER BY churn_rate DESC;
-- Usage: SELECT * FROM vw_churn_by_payment;

-- View 6: Revenue at Risk
CREATE VIEW vw_revenue_at_risk AS
SELECT 
    ROUND(SUM(MonthlyCharges), 2) AS monthly_revenue_lost,
    ROUND(SUM(TotalCharges), 2) AS total_revenue_lost,
    COUNT(*) AS churned_customers,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges_churned
FROM customers
WHERE Churn = 'Yes';
-- Usage: SELECT * FROM vw_revenue_at_risk;

-- View 7: High Risk Customer Profile
/*
Combines the strongest churn predictors identified in Phase 3:
- Month-to-month contract
- Fiber optic internet
- Electronic check payment
- Tenure under 12 months
This view identifies customers who match multiple high-risk signals.
*/
CREATE VIEW vw_high_risk_customers AS
SELECT 
    customerID,
    tenure,
    Contract,
    InternetService,
    PaymentMethod,
    MonthlyCharges,
    Churn,
    -- Risk score: 1 point per high-risk signal
	-- We are using the + operator instead of wrapping CASE in SUM because we are performing row-level addition. 
    (CASE WHEN Contract = 'Month-to-month' THEN 1 ELSE 0 END +
     CASE WHEN InternetService = 'Fiber optic' THEN 1 ELSE 0 END +
     CASE WHEN PaymentMethod = 'Electronic check' THEN 1 ELSE 0 END +
     CASE WHEN tenure <= 12 THEN 1 ELSE 0 END) AS risk_score
FROM customers
ORDER BY risk_score DESC;
-- Usage: 
-- SELECT * FROM vw_high_risk_customers WHERE risk_score = 4;  -- highest risk only
-- SELECT * FROM vw_high_risk_customers WHERE risk_score >= 3; -- broad high risk segment

-- Verify all views were created
SHOW FULL TABLES IN telco_churn WHERE TABLE_TYPE = 'VIEW';