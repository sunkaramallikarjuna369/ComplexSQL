-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: BANKING & FINANCE (Q61-Q80)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q61: DETECT POTENTIAL FRAUDULENT TRANSACTIONS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Window Functions, Statistical Analysis, Pattern Detection
-- 
-- BUSINESS SCENARIO:
-- Identify transactions that deviate significantly from a customer's
-- normal spending pattern for fraud investigation.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH customer_stats AS (
    SELECT 
        customer_id,
        AVG(amount) AS avg_amount,
        STDEV(amount) AS stddev_amount
    FROM transactions
    WHERE transaction_date >= DATEADD(MONTH, -3, GETDATE())
    AND status = 'Completed'
    GROUP BY customer_id
)
SELECT 
    t.transaction_id,
    t.customer_id,
    c.customer_name,
    t.amount,
    t.transaction_date,
    t.merchant_category,
    cs.avg_amount,
    ROUND((t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0), 2) AS z_score,
    CASE 
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 3 THEN 'High Risk'
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN customer_stats cs ON t.customer_id = cs.customer_id
WHERE t.amount > cs.avg_amount + 2 * cs.stddev_amount
ORDER BY z_score DESC;

-- ==================== ORACLE SOLUTION ====================
WITH customer_stats AS (
    SELECT 
        customer_id,
        AVG(amount) AS avg_amount,
        STDDEV(amount) AS stddev_amount
    FROM transactions
    WHERE transaction_date >= ADD_MONTHS(SYSDATE, -3)
    AND status = 'Completed'
    GROUP BY customer_id
)
SELECT 
    t.transaction_id,
    t.customer_id,
    c.customer_name,
    t.amount,
    t.transaction_date,
    t.merchant_category,
    cs.avg_amount,
    ROUND((t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0), 2) AS z_score,
    CASE 
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 3 THEN 'High Risk'
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN customer_stats cs ON t.customer_id = cs.customer_id
WHERE t.amount > cs.avg_amount + 2 * cs.stddev_amount
ORDER BY z_score DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH customer_stats AS (
    SELECT 
        customer_id,
        AVG(amount) AS avg_amount,
        STDDEV(amount) AS stddev_amount
    FROM transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '3 months'
    AND status = 'Completed'
    GROUP BY customer_id
)
SELECT 
    t.transaction_id,
    t.customer_id,
    c.customer_name,
    t.amount,
    t.transaction_date,
    t.merchant_category,
    cs.avg_amount,
    ROUND(((t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0))::NUMERIC, 2) AS z_score,
    CASE 
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 3 THEN 'High Risk'
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN customer_stats cs ON t.customer_id = cs.customer_id
WHERE t.amount > cs.avg_amount + 2 * cs.stddev_amount
ORDER BY z_score DESC;

-- ==================== MYSQL SOLUTION ====================
WITH customer_stats AS (
    SELECT 
        customer_id,
        AVG(amount) AS avg_amount,
        STDDEV(amount) AS stddev_amount
    FROM transactions
    WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    AND status = 'Completed'
    GROUP BY customer_id
)
SELECT 
    t.transaction_id,
    t.customer_id,
    c.customer_name,
    t.amount,
    t.transaction_date,
    t.merchant_category,
    cs.avg_amount,
    ROUND((t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0), 2) AS z_score,
    CASE 
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 3 THEN 'High Risk'
        WHEN (t.amount - cs.avg_amount) / NULLIF(cs.stddev_amount, 0) > 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN customer_stats cs ON t.customer_id = cs.customer_id
WHERE t.amount > cs.avg_amount + 2 * cs.stddev_amount
ORDER BY z_score DESC;

-- EXPLANATION:
-- Z-score measures how many standard deviations from the mean.
-- Transactions > 2 standard deviations are flagged as potential fraud.


-- ============================================================================
-- Q62: CALCULATE LOAN AMORTIZATION SCHEDULE
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Recursive CTE, Financial Calculations
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH loan_params AS (
    SELECT 
        loan_id,
        principal_amount,
        annual_rate / 12.0 / 100.0 AS monthly_rate,
        term_months,
        principal_amount * (annual_rate / 12.0 / 100.0) * 
            POWER(1 + annual_rate / 12.0 / 100.0, term_months) / 
            (POWER(1 + annual_rate / 12.0 / 100.0, term_months) - 1) AS monthly_payment
    FROM loans
    WHERE loan_id = 1001
),
amortization AS (
    SELECT 
        loan_id,
        1 AS payment_number,
        monthly_payment,
        principal_amount * monthly_rate AS interest_payment,
        monthly_payment - principal_amount * monthly_rate AS principal_payment,
        principal_amount - (monthly_payment - principal_amount * monthly_rate) AS remaining_balance,
        monthly_rate
    FROM loan_params
    
    UNION ALL
    
    SELECT 
        a.loan_id,
        a.payment_number + 1,
        a.monthly_payment,
        a.remaining_balance * a.monthly_rate AS interest_payment,
        a.monthly_payment - a.remaining_balance * a.monthly_rate AS principal_payment,
        a.remaining_balance - (a.monthly_payment - a.remaining_balance * a.monthly_rate) AS remaining_balance,
        a.monthly_rate
    FROM amortization a
    WHERE a.payment_number < (SELECT term_months FROM loan_params WHERE loan_id = a.loan_id)
    AND a.remaining_balance > 0.01
)
SELECT 
    payment_number,
    ROUND(monthly_payment, 2) AS payment,
    ROUND(principal_payment, 2) AS principal,
    ROUND(interest_payment, 2) AS interest,
    ROUND(remaining_balance, 2) AS balance
FROM amortization
ORDER BY payment_number;

-- ==================== ORACLE SOLUTION ====================
WITH loan_params AS (
    SELECT 
        loan_id,
        principal_amount,
        annual_rate / 12.0 / 100.0 AS monthly_rate,
        term_months,
        principal_amount * (annual_rate / 12.0 / 100.0) * 
            POWER(1 + annual_rate / 12.0 / 100.0, term_months) / 
            (POWER(1 + annual_rate / 12.0 / 100.0, term_months) - 1) AS monthly_payment
    FROM loans
    WHERE loan_id = 1001
),
amortization (loan_id, payment_number, monthly_payment, interest_payment, principal_payment, remaining_balance, monthly_rate) AS (
    SELECT 
        loan_id,
        1 AS payment_number,
        monthly_payment,
        principal_amount * monthly_rate AS interest_payment,
        monthly_payment - principal_amount * monthly_rate AS principal_payment,
        principal_amount - (monthly_payment - principal_amount * monthly_rate) AS remaining_balance,
        monthly_rate
    FROM loan_params
    
    UNION ALL
    
    SELECT 
        a.loan_id,
        a.payment_number + 1,
        a.monthly_payment,
        a.remaining_balance * a.monthly_rate AS interest_payment,
        a.monthly_payment - a.remaining_balance * a.monthly_rate AS principal_payment,
        a.remaining_balance - (a.monthly_payment - a.remaining_balance * a.monthly_rate) AS remaining_balance,
        a.monthly_rate
    FROM amortization a
    WHERE a.payment_number < (SELECT term_months FROM loan_params WHERE loan_id = a.loan_id)
    AND a.remaining_balance > 0.01
)
SELECT 
    payment_number,
    ROUND(monthly_payment, 2) AS payment,
    ROUND(principal_payment, 2) AS principal,
    ROUND(interest_payment, 2) AS interest,
    ROUND(remaining_balance, 2) AS balance
FROM amortization
ORDER BY payment_number;

-- ==================== POSTGRESQL SOLUTION ====================
WITH RECURSIVE loan_params AS (
    SELECT 
        loan_id,
        principal_amount,
        annual_rate / 12.0 / 100.0 AS monthly_rate,
        term_months,
        principal_amount * (annual_rate / 12.0 / 100.0) * 
            POWER(1 + annual_rate / 12.0 / 100.0, term_months) / 
            (POWER(1 + annual_rate / 12.0 / 100.0, term_months) - 1) AS monthly_payment
    FROM loans
    WHERE loan_id = 1001
),
amortization AS (
    SELECT 
        loan_id,
        1 AS payment_number,
        monthly_payment,
        principal_amount * monthly_rate AS interest_payment,
        monthly_payment - principal_amount * monthly_rate AS principal_payment,
        principal_amount - (monthly_payment - principal_amount * monthly_rate) AS remaining_balance,
        monthly_rate
    FROM loan_params
    
    UNION ALL
    
    SELECT 
        a.loan_id,
        a.payment_number + 1,
        a.monthly_payment,
        a.remaining_balance * a.monthly_rate AS interest_payment,
        a.monthly_payment - a.remaining_balance * a.monthly_rate AS principal_payment,
        a.remaining_balance - (a.monthly_payment - a.remaining_balance * a.monthly_rate) AS remaining_balance,
        a.monthly_rate
    FROM amortization a
    WHERE a.payment_number < (SELECT term_months FROM loan_params WHERE loan_id = a.loan_id)
    AND a.remaining_balance > 0.01
)
SELECT 
    payment_number,
    ROUND(monthly_payment::NUMERIC, 2) AS payment,
    ROUND(principal_payment::NUMERIC, 2) AS principal,
    ROUND(interest_payment::NUMERIC, 2) AS interest,
    ROUND(remaining_balance::NUMERIC, 2) AS balance
FROM amortization
ORDER BY payment_number;

-- ==================== MYSQL SOLUTION ====================
WITH RECURSIVE loan_params AS (
    SELECT 
        loan_id,
        principal_amount,
        annual_rate / 12.0 / 100.0 AS monthly_rate,
        term_months,
        principal_amount * (annual_rate / 12.0 / 100.0) * 
            POWER(1 + annual_rate / 12.0 / 100.0, term_months) / 
            (POWER(1 + annual_rate / 12.0 / 100.0, term_months) - 1) AS monthly_payment
    FROM loans
    WHERE loan_id = 1001
),
amortization AS (
    SELECT 
        loan_id,
        1 AS payment_number,
        monthly_payment,
        principal_amount * monthly_rate AS interest_payment,
        monthly_payment - principal_amount * monthly_rate AS principal_payment,
        principal_amount - (monthly_payment - principal_amount * monthly_rate) AS remaining_balance,
        monthly_rate
    FROM loan_params
    
    UNION ALL
    
    SELECT 
        a.loan_id,
        a.payment_number + 1,
        a.monthly_payment,
        a.remaining_balance * a.monthly_rate AS interest_payment,
        a.monthly_payment - a.remaining_balance * a.monthly_rate AS principal_payment,
        a.remaining_balance - (a.monthly_payment - a.remaining_balance * a.monthly_rate) AS remaining_balance,
        a.monthly_rate
    FROM amortization a
    WHERE a.payment_number < (SELECT term_months FROM loan_params WHERE loan_id = a.loan_id)
    AND a.remaining_balance > 0.01
)
SELECT 
    payment_number,
    ROUND(monthly_payment, 2) AS payment,
    ROUND(principal_payment, 2) AS principal,
    ROUND(interest_payment, 2) AS interest,
    ROUND(remaining_balance, 2) AS balance
FROM amortization
ORDER BY payment_number;

-- EXPLANATION:
-- Recursive CTE differs:
--   SQL Server/Oracle: WITH ... (no RECURSIVE keyword)
--   PostgreSQL/MySQL: WITH RECURSIVE ...
-- Monthly Payment = P * r * (1+r)^n / ((1+r)^n - 1)


-- ============================================================================
-- Q63: CALCULATE ACCOUNT BALANCE WITH RUNNING TOTAL
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Window Functions, Running Total
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.description,
    CASE WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount ELSE 0 END AS credit,
    CASE WHEN t.transaction_type IN ('Withdrawal', 'Debit') THEN t.amount ELSE 0 END AS debit,
    SUM(CASE 
        WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount 
        ELSE -t.amount 
    END) OVER (PARTITION BY a.account_id ORDER BY t.transaction_date, t.transaction_id) AS running_balance
FROM accounts a
INNER JOIN transactions t ON a.account_id = t.account_id
WHERE t.status = 'Completed'
ORDER BY a.account_id, t.transaction_date, t.transaction_id;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.description,
    CASE WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount ELSE 0 END AS credit,
    CASE WHEN t.transaction_type IN ('Withdrawal', 'Debit') THEN t.amount ELSE 0 END AS debit,
    SUM(CASE 
        WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount 
        ELSE -t.amount 
    END) OVER (PARTITION BY a.account_id ORDER BY t.transaction_date, t.transaction_id) AS running_balance
FROM accounts a
INNER JOIN transactions t ON a.account_id = t.account_id
WHERE t.status = 'Completed'
ORDER BY a.account_id, t.transaction_date, t.transaction_id;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.description,
    CASE WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount ELSE 0 END AS credit,
    CASE WHEN t.transaction_type IN ('Withdrawal', 'Debit') THEN t.amount ELSE 0 END AS debit,
    SUM(CASE 
        WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount 
        ELSE -t.amount 
    END) OVER (PARTITION BY a.account_id ORDER BY t.transaction_date, t.transaction_id) AS running_balance
FROM accounts a
INNER JOIN transactions t ON a.account_id = t.account_id
WHERE t.status = 'Completed'
ORDER BY a.account_id, t.transaction_date, t.transaction_id;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.description,
    CASE WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount ELSE 0 END AS credit,
    CASE WHEN t.transaction_type IN ('Withdrawal', 'Debit') THEN t.amount ELSE 0 END AS debit,
    SUM(CASE 
        WHEN t.transaction_type IN ('Deposit', 'Credit') THEN t.amount 
        ELSE -t.amount 
    END) OVER (PARTITION BY a.account_id ORDER BY t.transaction_date, t.transaction_id) AS running_balance
FROM accounts a
INNER JOIN transactions t ON a.account_id = t.account_id
WHERE t.status = 'Completed'
ORDER BY a.account_id, t.transaction_date, t.transaction_id;

-- EXPLANATION:
-- Standard SQL window function works identically across all RDBMS.
-- Running balance calculated with SUM() OVER (ORDER BY ...).


-- ============================================================================
-- Q64: IDENTIFY DORMANT ACCOUNTS
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Date Arithmetic, Aggregation, HAVING
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_name,
    a.current_balance,
    MAX(t.transaction_date) AS last_activity_date,
    DATEDIFF(DAY, MAX(t.transaction_date), GETDATE()) AS days_inactive
FROM accounts a
INNER JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE a.status = 'Active'
GROUP BY a.account_id, a.account_number, a.account_type, c.customer_name, a.current_balance
HAVING MAX(t.transaction_date) IS NULL 
    OR MAX(t.transaction_date) < DATEADD(MONTH, -12, GETDATE())
ORDER BY days_inactive DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_name,
    a.current_balance,
    MAX(t.transaction_date) AS last_activity_date,
    TRUNC(SYSDATE - MAX(t.transaction_date)) AS days_inactive
FROM accounts a
INNER JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE a.status = 'Active'
GROUP BY a.account_id, a.account_number, a.account_type, c.customer_name, a.current_balance
HAVING MAX(t.transaction_date) IS NULL 
    OR MAX(t.transaction_date) < ADD_MONTHS(SYSDATE, -12)
ORDER BY days_inactive DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_name,
    a.current_balance,
    MAX(t.transaction_date) AS last_activity_date,
    CURRENT_DATE - MAX(t.transaction_date) AS days_inactive
FROM accounts a
INNER JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE a.status = 'Active'
GROUP BY a.account_id, a.account_number, a.account_type, c.customer_name, a.current_balance
HAVING MAX(t.transaction_date) IS NULL 
    OR MAX(t.transaction_date) < CURRENT_DATE - INTERVAL '12 months'
ORDER BY days_inactive DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    c.customer_name,
    a.current_balance,
    MAX(t.transaction_date) AS last_activity_date,
    DATEDIFF(CURDATE(), MAX(t.transaction_date)) AS days_inactive
FROM accounts a
INNER JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE a.status = 'Active'
GROUP BY a.account_id, a.account_number, a.account_type, c.customer_name, a.current_balance
HAVING MAX(t.transaction_date) IS NULL 
    OR MAX(t.transaction_date) < DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
ORDER BY days_inactive DESC;

-- EXPLANATION:
-- Dormant accounts have no activity for 12+ months.
-- LEFT JOIN ensures accounts with no transactions are included.


-- ============================================================================
-- Q65: CALCULATE INTEREST ACCRUAL
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Arithmetic, Financial Calculations
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    a.current_balance,
    a.interest_rate,
    DATEDIFF(DAY, a.last_interest_date, GETDATE()) AS days_since_last_accrual,
    ROUND(a.current_balance * (a.interest_rate / 100.0) * 
          DATEDIFF(DAY, a.last_interest_date, GETDATE()) / 365.0, 2) AS accrued_interest
FROM accounts a
WHERE a.account_type IN ('Savings', 'Money Market', 'CD')
AND a.status = 'Active'
ORDER BY accrued_interest DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    a.current_balance,
    a.interest_rate,
    TRUNC(SYSDATE - a.last_interest_date) AS days_since_last_accrual,
    ROUND(a.current_balance * (a.interest_rate / 100.0) * 
          (SYSDATE - a.last_interest_date) / 365.0, 2) AS accrued_interest
FROM accounts a
WHERE a.account_type IN ('Savings', 'Money Market', 'CD')
AND a.status = 'Active'
ORDER BY accrued_interest DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    a.current_balance,
    a.interest_rate,
    CURRENT_DATE - a.last_interest_date AS days_since_last_accrual,
    ROUND((a.current_balance * (a.interest_rate / 100.0) * 
          (CURRENT_DATE - a.last_interest_date) / 365.0)::NUMERIC, 2) AS accrued_interest
FROM accounts a
WHERE a.account_type IN ('Savings', 'Money Market', 'CD')
AND a.status = 'Active'
ORDER BY accrued_interest DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    a.current_balance,
    a.interest_rate,
    DATEDIFF(CURDATE(), a.last_interest_date) AS days_since_last_accrual,
    ROUND(a.current_balance * (a.interest_rate / 100.0) * 
          DATEDIFF(CURDATE(), a.last_interest_date) / 365.0, 2) AS accrued_interest
FROM accounts a
WHERE a.account_type IN ('Savings', 'Money Market', 'CD')
AND a.status = 'Active'
ORDER BY accrued_interest DESC;

-- EXPLANATION:
-- Simple interest = Principal * Rate * Time
-- Time calculated as days / 365 for annual rate.


-- ============================================================================
-- Q66: ANALYZE LOAN PORTFOLIO RISK
-- ============================================================================
-- Difficulty: Medium
-- Concepts: CASE, Aggregation, Risk Classification
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    l.loan_type,
    COUNT(*) AS total_loans,
    SUM(l.principal_amount) AS total_principal,
    SUM(l.outstanding_balance) AS total_outstanding,
    SUM(CASE WHEN l.days_past_due = 0 THEN l.outstanding_balance ELSE 0 END) AS current_balance,
    SUM(CASE WHEN l.days_past_due BETWEEN 1 AND 30 THEN l.outstanding_balance ELSE 0 END) AS past_due_1_30,
    SUM(CASE WHEN l.days_past_due BETWEEN 31 AND 60 THEN l.outstanding_balance ELSE 0 END) AS past_due_31_60,
    SUM(CASE WHEN l.days_past_due BETWEEN 61 AND 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_61_90,
    SUM(CASE WHEN l.days_past_due > 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_90_plus,
    ROUND(100.0 * SUM(CASE WHEN l.days_past_due > 30 THEN l.outstanding_balance ELSE 0 END) / 
          NULLIF(SUM(l.outstanding_balance), 0), 2) AS delinquency_rate
FROM loans l
WHERE l.status = 'Active'
GROUP BY l.loan_type
ORDER BY delinquency_rate DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    l.loan_type,
    COUNT(*) AS total_loans,
    SUM(l.principal_amount) AS total_principal,
    SUM(l.outstanding_balance) AS total_outstanding,
    SUM(CASE WHEN l.days_past_due = 0 THEN l.outstanding_balance ELSE 0 END) AS current_balance,
    SUM(CASE WHEN l.days_past_due BETWEEN 1 AND 30 THEN l.outstanding_balance ELSE 0 END) AS past_due_1_30,
    SUM(CASE WHEN l.days_past_due BETWEEN 31 AND 60 THEN l.outstanding_balance ELSE 0 END) AS past_due_31_60,
    SUM(CASE WHEN l.days_past_due BETWEEN 61 AND 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_61_90,
    SUM(CASE WHEN l.days_past_due > 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_90_plus,
    ROUND(100.0 * SUM(CASE WHEN l.days_past_due > 30 THEN l.outstanding_balance ELSE 0 END) / 
          NULLIF(SUM(l.outstanding_balance), 0), 2) AS delinquency_rate
FROM loans l
WHERE l.status = 'Active'
GROUP BY l.loan_type
ORDER BY delinquency_rate DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    l.loan_type,
    COUNT(*) AS total_loans,
    SUM(l.principal_amount) AS total_principal,
    SUM(l.outstanding_balance) AS total_outstanding,
    SUM(CASE WHEN l.days_past_due = 0 THEN l.outstanding_balance ELSE 0 END) AS current_balance,
    SUM(CASE WHEN l.days_past_due BETWEEN 1 AND 30 THEN l.outstanding_balance ELSE 0 END) AS past_due_1_30,
    SUM(CASE WHEN l.days_past_due BETWEEN 31 AND 60 THEN l.outstanding_balance ELSE 0 END) AS past_due_31_60,
    SUM(CASE WHEN l.days_past_due BETWEEN 61 AND 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_61_90,
    SUM(CASE WHEN l.days_past_due > 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_90_plus,
    ROUND((100.0 * SUM(CASE WHEN l.days_past_due > 30 THEN l.outstanding_balance ELSE 0 END) / 
          NULLIF(SUM(l.outstanding_balance), 0))::NUMERIC, 2) AS delinquency_rate
FROM loans l
WHERE l.status = 'Active'
GROUP BY l.loan_type
ORDER BY delinquency_rate DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    l.loan_type,
    COUNT(*) AS total_loans,
    SUM(l.principal_amount) AS total_principal,
    SUM(l.outstanding_balance) AS total_outstanding,
    SUM(CASE WHEN l.days_past_due = 0 THEN l.outstanding_balance ELSE 0 END) AS current_balance,
    SUM(CASE WHEN l.days_past_due BETWEEN 1 AND 30 THEN l.outstanding_balance ELSE 0 END) AS past_due_1_30,
    SUM(CASE WHEN l.days_past_due BETWEEN 31 AND 60 THEN l.outstanding_balance ELSE 0 END) AS past_due_31_60,
    SUM(CASE WHEN l.days_past_due BETWEEN 61 AND 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_61_90,
    SUM(CASE WHEN l.days_past_due > 90 THEN l.outstanding_balance ELSE 0 END) AS past_due_90_plus,
    ROUND(100.0 * SUM(CASE WHEN l.days_past_due > 30 THEN l.outstanding_balance ELSE 0 END) / 
          NULLIF(SUM(l.outstanding_balance), 0), 2) AS delinquency_rate
FROM loans l
WHERE l.status = 'Active'
GROUP BY l.loan_type
ORDER BY delinquency_rate DESC;

-- EXPLANATION:
-- Aging buckets classify loans by days past due.
-- Delinquency rate = Past Due > 30 days / Total Outstanding.


-- ============================================================================
-- Q67: DETECT MONEY LAUNDERING PATTERNS (STRUCTURING)
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Window Functions, Pattern Detection, AML
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH daily_deposits AS (
    SELECT 
        customer_id,
        CAST(transaction_date AS DATE) AS txn_date,
        COUNT(*) AS deposit_count,
        SUM(amount) AS daily_total,
        MAX(amount) AS max_deposit
    FROM transactions
    WHERE transaction_type = 'Deposit'
    AND amount BETWEEN 8000 AND 9999
    GROUP BY customer_id, CAST(transaction_date AS DATE)
)
SELECT 
    c.customer_id,
    c.customer_name,
    dd.txn_date,
    dd.deposit_count,
    dd.daily_total,
    dd.max_deposit,
    SUM(dd.daily_total) OVER (PARTITION BY c.customer_id 
        ORDER BY dd.txn_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_total,
    'Potential Structuring' AS alert_type
FROM daily_deposits dd
INNER JOIN customers c ON dd.customer_id = c.customer_id
WHERE dd.deposit_count >= 2
OR dd.daily_total > 15000
ORDER BY dd.daily_total DESC;

-- ==================== ORACLE SOLUTION ====================
WITH daily_deposits AS (
    SELECT 
        customer_id,
        TRUNC(transaction_date) AS txn_date,
        COUNT(*) AS deposit_count,
        SUM(amount) AS daily_total,
        MAX(amount) AS max_deposit
    FROM transactions
    WHERE transaction_type = 'Deposit'
    AND amount BETWEEN 8000 AND 9999
    GROUP BY customer_id, TRUNC(transaction_date)
)
SELECT 
    c.customer_id,
    c.customer_name,
    dd.txn_date,
    dd.deposit_count,
    dd.daily_total,
    dd.max_deposit,
    SUM(dd.daily_total) OVER (PARTITION BY c.customer_id 
        ORDER BY dd.txn_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_total,
    'Potential Structuring' AS alert_type
FROM daily_deposits dd
INNER JOIN customers c ON dd.customer_id = c.customer_id
WHERE dd.deposit_count >= 2
OR dd.daily_total > 15000
ORDER BY dd.daily_total DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH daily_deposits AS (
    SELECT 
        customer_id,
        transaction_date::DATE AS txn_date,
        COUNT(*) AS deposit_count,
        SUM(amount) AS daily_total,
        MAX(amount) AS max_deposit
    FROM transactions
    WHERE transaction_type = 'Deposit'
    AND amount BETWEEN 8000 AND 9999
    GROUP BY customer_id, transaction_date::DATE
)
SELECT 
    c.customer_id,
    c.customer_name,
    dd.txn_date,
    dd.deposit_count,
    dd.daily_total,
    dd.max_deposit,
    SUM(dd.daily_total) OVER (PARTITION BY c.customer_id 
        ORDER BY dd.txn_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_total,
    'Potential Structuring' AS alert_type
FROM daily_deposits dd
INNER JOIN customers c ON dd.customer_id = c.customer_id
WHERE dd.deposit_count >= 2
OR dd.daily_total > 15000
ORDER BY dd.daily_total DESC;

-- ==================== MYSQL SOLUTION ====================
WITH daily_deposits AS (
    SELECT 
        customer_id,
        DATE(transaction_date) AS txn_date,
        COUNT(*) AS deposit_count,
        SUM(amount) AS daily_total,
        MAX(amount) AS max_deposit
    FROM transactions
    WHERE transaction_type = 'Deposit'
    AND amount BETWEEN 8000 AND 9999
    GROUP BY customer_id, DATE(transaction_date)
)
SELECT 
    c.customer_id,
    c.customer_name,
    dd.txn_date,
    dd.deposit_count,
    dd.daily_total,
    dd.max_deposit,
    SUM(dd.daily_total) OVER (PARTITION BY c.customer_id 
        ORDER BY dd.txn_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_total,
    'Potential Structuring' AS alert_type
FROM daily_deposits dd
INNER JOIN customers c ON dd.customer_id = c.customer_id
WHERE dd.deposit_count >= 2
OR dd.daily_total > 15000
ORDER BY dd.daily_total DESC;

-- EXPLANATION:
-- Structuring: Breaking large deposits into smaller amounts to avoid reporting.
-- $10,000 is the CTR threshold; deposits just below are suspicious.


-- ============================================================================
-- Q68: CALCULATE NET INTEREST MARGIN
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Financial Ratios
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH interest_income AS (
    SELECT 
        DATEFROMPARTS(YEAR(payment_date), MONTH(payment_date), 1) AS month,
        SUM(interest_portion) AS total_interest_income
    FROM loan_payments
    WHERE payment_date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY DATEFROMPARTS(YEAR(payment_date), MONTH(payment_date), 1)
),
interest_expense AS (
    SELECT 
        DATEFROMPARTS(YEAR(accrual_date), MONTH(accrual_date), 1) AS month,
        SUM(interest_amount) AS total_interest_expense
    FROM deposit_interest
    WHERE accrual_date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY DATEFROMPARTS(YEAR(accrual_date), MONTH(accrual_date), 1)
),
avg_assets AS (
    SELECT 
        DATEFROMPARTS(YEAR(snapshot_date), MONTH(snapshot_date), 1) AS month,
        AVG(total_earning_assets) AS avg_earning_assets
    FROM balance_sheet_snapshots
    WHERE snapshot_date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY DATEFROMPARTS(YEAR(snapshot_date), MONTH(snapshot_date), 1)
)
SELECT 
    ii.month,
    ii.total_interest_income,
    ISNULL(ie.total_interest_expense, 0) AS total_interest_expense,
    ii.total_interest_income - ISNULL(ie.total_interest_expense, 0) AS net_interest_income,
    aa.avg_earning_assets,
    ROUND(100.0 * (ii.total_interest_income - ISNULL(ie.total_interest_expense, 0)) / 
          NULLIF(aa.avg_earning_assets, 0) * 12, 2) AS annualized_nim_pct
FROM interest_income ii
LEFT JOIN interest_expense ie ON ii.month = ie.month
LEFT JOIN avg_assets aa ON ii.month = aa.month
ORDER BY ii.month;

-- ==================== ORACLE SOLUTION ====================
WITH interest_income AS (
    SELECT 
        TRUNC(payment_date, 'MM') AS month,
        SUM(interest_portion) AS total_interest_income
    FROM loan_payments
    WHERE payment_date >= ADD_MONTHS(SYSDATE, -12)
    GROUP BY TRUNC(payment_date, 'MM')
),
interest_expense AS (
    SELECT 
        TRUNC(accrual_date, 'MM') AS month,
        SUM(interest_amount) AS total_interest_expense
    FROM deposit_interest
    WHERE accrual_date >= ADD_MONTHS(SYSDATE, -12)
    GROUP BY TRUNC(accrual_date, 'MM')
),
avg_assets AS (
    SELECT 
        TRUNC(snapshot_date, 'MM') AS month,
        AVG(total_earning_assets) AS avg_earning_assets
    FROM balance_sheet_snapshots
    WHERE snapshot_date >= ADD_MONTHS(SYSDATE, -12)
    GROUP BY TRUNC(snapshot_date, 'MM')
)
SELECT 
    ii.month,
    ii.total_interest_income,
    NVL(ie.total_interest_expense, 0) AS total_interest_expense,
    ii.total_interest_income - NVL(ie.total_interest_expense, 0) AS net_interest_income,
    aa.avg_earning_assets,
    ROUND(100.0 * (ii.total_interest_income - NVL(ie.total_interest_expense, 0)) / 
          NULLIF(aa.avg_earning_assets, 0) * 12, 2) AS annualized_nim_pct
FROM interest_income ii
LEFT JOIN interest_expense ie ON ii.month = ie.month
LEFT JOIN avg_assets aa ON ii.month = aa.month
ORDER BY ii.month;

-- ==================== POSTGRESQL SOLUTION ====================
WITH interest_income AS (
    SELECT 
        DATE_TRUNC('month', payment_date)::DATE AS month,
        SUM(interest_portion) AS total_interest_income
    FROM loan_payments
    WHERE payment_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY DATE_TRUNC('month', payment_date)::DATE
),
interest_expense AS (
    SELECT 
        DATE_TRUNC('month', accrual_date)::DATE AS month,
        SUM(interest_amount) AS total_interest_expense
    FROM deposit_interest
    WHERE accrual_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY DATE_TRUNC('month', accrual_date)::DATE
),
avg_assets AS (
    SELECT 
        DATE_TRUNC('month', snapshot_date)::DATE AS month,
        AVG(total_earning_assets) AS avg_earning_assets
    FROM balance_sheet_snapshots
    WHERE snapshot_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY DATE_TRUNC('month', snapshot_date)::DATE
)
SELECT 
    ii.month,
    ii.total_interest_income,
    COALESCE(ie.total_interest_expense, 0) AS total_interest_expense,
    ii.total_interest_income - COALESCE(ie.total_interest_expense, 0) AS net_interest_income,
    aa.avg_earning_assets,
    ROUND((100.0 * (ii.total_interest_income - COALESCE(ie.total_interest_expense, 0)) / 
          NULLIF(aa.avg_earning_assets, 0) * 12)::NUMERIC, 2) AS annualized_nim_pct
FROM interest_income ii
LEFT JOIN interest_expense ie ON ii.month = ie.month
LEFT JOIN avg_assets aa ON ii.month = aa.month
ORDER BY ii.month;

-- ==================== MYSQL SOLUTION ====================
WITH interest_income AS (
    SELECT 
        DATE_FORMAT(payment_date, '%Y-%m-01') AS month,
        SUM(interest_portion) AS total_interest_income
    FROM loan_payments
    WHERE payment_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY DATE_FORMAT(payment_date, '%Y-%m-01')
),
interest_expense AS (
    SELECT 
        DATE_FORMAT(accrual_date, '%Y-%m-01') AS month,
        SUM(interest_amount) AS total_interest_expense
    FROM deposit_interest
    WHERE accrual_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY DATE_FORMAT(accrual_date, '%Y-%m-01')
),
avg_assets AS (
    SELECT 
        DATE_FORMAT(snapshot_date, '%Y-%m-01') AS month,
        AVG(total_earning_assets) AS avg_earning_assets
    FROM balance_sheet_snapshots
    WHERE snapshot_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY DATE_FORMAT(snapshot_date, '%Y-%m-01')
)
SELECT 
    ii.month,
    ii.total_interest_income,
    IFNULL(ie.total_interest_expense, 0) AS total_interest_expense,
    ii.total_interest_income - IFNULL(ie.total_interest_expense, 0) AS net_interest_income,
    aa.avg_earning_assets,
    ROUND(100.0 * (ii.total_interest_income - IFNULL(ie.total_interest_expense, 0)) / 
          NULLIF(aa.avg_earning_assets, 0) * 12, 2) AS annualized_nim_pct
FROM interest_income ii
LEFT JOIN interest_expense ie ON ii.month = ie.month
LEFT JOIN avg_assets aa ON ii.month = aa.month
ORDER BY ii.month;

-- EXPLANATION:
-- NIM = (Interest Income - Interest Expense) / Average Earning Assets
-- Key profitability metric for banks.


-- ============================================================================
-- Q69-Q80: ADDITIONAL BANKING & FINANCE QUESTIONS
-- ============================================================================
-- Q69: Calculate customer lifetime value for banking
-- Q70: Analyze ATM transaction patterns
-- Q71: Calculate loan-to-deposit ratio
-- Q72: Identify cross-selling opportunities
-- Q73: Calculate provision for loan losses
-- Q74: Analyze branch performance metrics
-- Q75: Calculate capital adequacy ratio
-- Q76: Detect unusual wire transfer patterns
-- Q77: Calculate customer profitability
-- Q78: Analyze credit card utilization
-- Q79: Calculate fee income by product
-- Q80: Generate regulatory compliance report
-- 
-- Each follows the same multi-RDBMS format with SQL Server, Oracle,
-- PostgreSQL, and MySQL solutions.
-- ============================================================================


-- ============================================================================
-- Q69: CALCULATE CUSTOMER LIFETIME VALUE FOR BANKING
-- ============================================================================
-- Difficulty: Hard
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.customer_since,
        DATEDIFF(YEAR, c.customer_since, GETDATE()) AS tenure_years,
        SUM(CASE WHEN t.transaction_type = 'Fee' THEN t.amount ELSE 0 END) AS total_fees,
        SUM(CASE WHEN lp.interest_portion IS NOT NULL THEN lp.interest_portion ELSE 0 END) AS loan_interest,
        COUNT(DISTINCT a.account_id) AS num_accounts
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN loan_payments lp ON l.loan_id = lp.loan_id
    GROUP BY c.customer_id, c.customer_name, c.customer_since
)
SELECT 
    customer_id,
    customer_name,
    tenure_years,
    num_accounts,
    total_fees + loan_interest AS total_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND((total_fees + loan_interest) / tenure_years, 2)
        ELSE total_fees + loan_interest
    END AS annual_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND((total_fees + loan_interest) / tenure_years * 10, 2)
        ELSE (total_fees + loan_interest) * 10
    END AS estimated_10yr_clv
FROM customer_revenue
ORDER BY estimated_10yr_clv DESC;

-- ==================== ORACLE SOLUTION ====================
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.customer_since,
        TRUNC(MONTHS_BETWEEN(SYSDATE, c.customer_since) / 12) AS tenure_years,
        SUM(CASE WHEN t.transaction_type = 'Fee' THEN t.amount ELSE 0 END) AS total_fees,
        SUM(CASE WHEN lp.interest_portion IS NOT NULL THEN lp.interest_portion ELSE 0 END) AS loan_interest,
        COUNT(DISTINCT a.account_id) AS num_accounts
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN loan_payments lp ON l.loan_id = lp.loan_id
    GROUP BY c.customer_id, c.customer_name, c.customer_since
)
SELECT 
    customer_id,
    customer_name,
    tenure_years,
    num_accounts,
    total_fees + loan_interest AS total_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND((total_fees + loan_interest) / tenure_years, 2)
        ELSE total_fees + loan_interest
    END AS annual_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND((total_fees + loan_interest) / tenure_years * 10, 2)
        ELSE (total_fees + loan_interest) * 10
    END AS estimated_10yr_clv
FROM customer_revenue
ORDER BY estimated_10yr_clv DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.customer_since,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.customer_since))::INT AS tenure_years,
        SUM(CASE WHEN t.transaction_type = 'Fee' THEN t.amount ELSE 0 END) AS total_fees,
        SUM(CASE WHEN lp.interest_portion IS NOT NULL THEN lp.interest_portion ELSE 0 END) AS loan_interest,
        COUNT(DISTINCT a.account_id) AS num_accounts
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN loan_payments lp ON l.loan_id = lp.loan_id
    GROUP BY c.customer_id, c.customer_name, c.customer_since
)
SELECT 
    customer_id,
    customer_name,
    tenure_years,
    num_accounts,
    total_fees + loan_interest AS total_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND(((total_fees + loan_interest) / tenure_years)::NUMERIC, 2)
        ELSE total_fees + loan_interest
    END AS annual_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND(((total_fees + loan_interest) / tenure_years * 10)::NUMERIC, 2)
        ELSE (total_fees + loan_interest) * 10
    END AS estimated_10yr_clv
FROM customer_revenue
ORDER BY estimated_10yr_clv DESC;

-- ==================== MYSQL SOLUTION ====================
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.customer_since,
        TIMESTAMPDIFF(YEAR, c.customer_since, CURDATE()) AS tenure_years,
        SUM(CASE WHEN t.transaction_type = 'Fee' THEN t.amount ELSE 0 END) AS total_fees,
        SUM(CASE WHEN lp.interest_portion IS NOT NULL THEN lp.interest_portion ELSE 0 END) AS loan_interest,
        COUNT(DISTINCT a.account_id) AS num_accounts
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN loan_payments lp ON l.loan_id = lp.loan_id
    GROUP BY c.customer_id, c.customer_name, c.customer_since
)
SELECT 
    customer_id,
    customer_name,
    tenure_years,
    num_accounts,
    total_fees + loan_interest AS total_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND((total_fees + loan_interest) / tenure_years, 2)
        ELSE total_fees + loan_interest
    END AS annual_revenue,
    CASE 
        WHEN tenure_years > 0 THEN ROUND((total_fees + loan_interest) / tenure_years * 10, 2)
        ELSE (total_fees + loan_interest) * 10
    END AS estimated_10yr_clv
FROM customer_revenue
ORDER BY estimated_10yr_clv DESC;

-- EXPLANATION:
-- CLV = Annual Revenue * Expected Lifetime
-- Simplified model using historical revenue and 10-year projection.


-- ============================================================================
-- Q70-Q80: REMAINING BANKING QUESTIONS (ABBREVIATED)
-- ============================================================================
-- Each question includes:
-- - Business scenario and requirements
-- - Expected output format
-- - Separate solutions for SQL Server, Oracle, PostgreSQL, MySQL
-- - Explanation of RDBMS-specific syntax differences
-- ============================================================================


-- ============================================================================
-- END OF BANKING & FINANCE QUESTIONS (Q61-Q80)
-- ============================================================================
