-- Account Inactivity Alert--
-- THE SAVINGS ACCT WAS UNION ALL WITH INVESTMNET ACCT SO AS TO CONFIRM THE EACH TABLE ALSO CONFIRM THE
SELECT DISTINCT transaction_status FROM savings_savingsaccount;
SELECT DISTINCT status_id FROM plans_plan;
SELECT 
    p.id AS plan_id,
    p.owner_id,
    'Investment' AS type,
    MAX(p.last_charge_date) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(p.last_charge_date)) AS inactivity_days
FROM plans_plan p
WHERE p.status_id = '1'  -- assuming '1' is active/funded
GROUP BY p.id, p.owner_id
HAVING inactivity_days > 365;

SELECT 
    s.id AS plan_id,
    s.owner_id,
    'Savings' AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(s.transaction_date)) AS inactivity_days
FROM savings_savingsaccount s
WHERE s.transaction_status IN ('success', 'successful', 'monnify_success')
GROUP BY s.id, s.owner_id
HAVING inactivity_days > 365

UNION ALL

SELECT 
    p.id AS plan_id,
    p.owner_id,
    'Investment' AS type,
    MAX(p.last_charge_date) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(p.last_charge_date)) AS inactivity_days
FROM plans_plan p
WHERE p.status_id = '1'
GROUP BY p.id, p.owner_id
HAVING inactivity_days > 365;

--  High-Value Customers with Multiple Products
-- COMMENT CHALLENGE
-- THE TABLE WAS CREATED BUT UNABLE TO INSERT THE VALUES BUT THE QUERY IS RETURNING EMPTY DUE TO USER CUSTOMUSER EMPTY
SELECT
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    COUNT(DISTINCT s.id) AS savings_count,
    COUNT(DISTINCT p.id) AS investment_count,
    COALESCE(SUM(s.amount), 0) + COALESCE(SUM(p.amount), 0) AS total_deposits
FROM users_customuser u
JOIN savings_savingsaccount s
    ON u.id = s.owner_id
    AND s.transaction_status = 'funded'
JOIN plans_plan p
    ON u.id = p.owner_id
    AND p.status_id = 1  
    AND p.plan_type_id = 2 
GROUP BY u.id, u.first_name, u.last_name
HAVING savings_count > 0 AND investment_count > 0
ORDER BY total_deposits DESC
LIMIT 1000;

-- Transaction Frequency Analysis --
-- COMMENT CHALLENGE
-- THE TABLE WAS CREATED BUT UNABLE TO INSERT THE VALUES BUT THE QUERY IS RETURNING EMPTY DUE TO USER CUSTOMUSER EMPTY
WITH transactions_summary AS (
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        COUNT(s.id) AS total_transactions,
        TIMESTAMPDIFF(MONTH, MIN(s.transaction_date), MAX(s.transaction_date)) + 1 AS tenure_months
    FROM users_customuser u
    LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id
    GROUP BY u.id, u.first_name, u.last_name
),
frequency_calc AS (
    SELECT 
        customer_id,
        name,
        total_transactions,
        tenure_months,
        CASE 
            WHEN tenure_months = 0 THEN total_transactions
            ELSE total_transactions / tenure_months
        END AS avg_transactions_per_month
    FROM transactions_summary
),
frequency_category AS (
    SELECT 
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        customer_id,
        avg_transactions_per_month
    FROM frequency_calc
)
SELECT 
    frequency_category,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
FROM frequency_category
GROUP BY frequency_category
ORDER BY 
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
    

