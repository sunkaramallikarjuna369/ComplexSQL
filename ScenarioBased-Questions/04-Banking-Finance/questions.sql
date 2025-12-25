-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Banking & Finance (Questions 61-80)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    account_type VARCHAR(20),
    balance DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    opened_date DATE,
    status VARCHAR(20)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_type VARCHAR(20),
    amount DECIMAL(15,2),
    transaction_date TIMESTAMP,
    description VARCHAR(200),
    reference_id VARCHAR(50)
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    credit_score INT,
    customer_since DATE
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    loan_type VARCHAR(30),
    principal DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    term_months INT,
    start_date DATE,
    status VARCHAR(20)
);
*/

-- ============================================
-- QUESTION 61: Calculate daily account balance
-- ============================================
-- Scenario: Generate account statement with running balance

SELECT 
    t.transaction_date,
    t.transaction_type,
    t.description,
    CASE WHEN t.transaction_type IN ('DEPOSIT', 'INTEREST') THEN t.amount ELSE 0 END AS credit,
    CASE WHEN t.transaction_type IN ('WITHDRAWAL', 'FEE', 'TRANSFER_OUT') THEN t.amount ELSE 0 END AS debit,
    SUM(CASE 
        WHEN t.transaction_type IN ('DEPOSIT', 'INTEREST', 'TRANSFER_IN') THEN t.amount 
        ELSE -t.amount 
    END) OVER (ORDER BY t.transaction_date, t.transaction_id) AS running_balance
FROM transactions t
WHERE t.account_id = 1001
AND t.transaction_date BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY t.transaction_date, t.transaction_id;

-- ============================================
-- QUESTION 62: Detect potential fraud - unusual transactions
-- ============================================
-- Scenario: Flag transactions significantly above customer's average

WITH customer_stats AS (
    SELECT 
        a.customer_id,
        AVG(t.amount) AS avg_transaction,
        STDDEV(t.amount) AS stddev_transaction
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY a.customer_id
)
SELECT 
    t.transaction_id,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    t.amount,
    cs.avg_transaction,
    ROUND((t.amount - cs.avg_transaction) / NULLIF(cs.stddev_transaction, 0), 2) AS z_score,
    t.transaction_date,
    t.description
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
JOIN customer_stats cs ON c.customer_id = cs.customer_id
WHERE (t.amount - cs.avg_transaction) / NULLIF(cs.stddev_transaction, 0) > 3
ORDER BY z_score DESC;

-- ============================================
-- QUESTION 63: Calculate loan amortization schedule
-- ============================================
-- Scenario: Generate monthly payment breakdown

WITH RECURSIVE amortization AS (
    SELECT 
        loan_id,
        1 AS payment_number,
        principal AS remaining_balance,
        ROUND(principal * (interest_rate/12) * POWER(1 + interest_rate/12, term_months) / 
              (POWER(1 + interest_rate/12, term_months) - 1), 2) AS monthly_payment,
        interest_rate,
        term_months
    FROM loans
    WHERE loan_id = 5001
    
    UNION ALL
    
    SELECT 
        loan_id,
        payment_number + 1,
        ROUND(remaining_balance * (1 + interest_rate/12) - monthly_payment, 2),
        monthly_payment,
        interest_rate,
        term_months
    FROM amortization
    WHERE payment_number < term_months AND remaining_balance > 0
)
SELECT 
    payment_number,
    monthly_payment,
    ROUND(remaining_balance * interest_rate / 12, 2) AS interest_portion,
    ROUND(monthly_payment - remaining_balance * interest_rate / 12, 2) AS principal_portion,
    GREATEST(remaining_balance - (monthly_payment - remaining_balance * interest_rate / 12), 0) AS ending_balance
FROM amortization
ORDER BY payment_number;

-- ============================================
-- QUESTION 64: Find dormant accounts
-- ============================================
-- Scenario: Identify accounts with no activity for compliance

SELECT 
    a.account_id,
    a.account_type,
    c.first_name || ' ' || c.last_name AS customer_name,
    a.balance,
    MAX(t.transaction_date) AS last_transaction,
    CURRENT_DATE - MAX(t.transaction_date) AS days_inactive
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE a.status = 'ACTIVE'
GROUP BY a.account_id, a.account_type, c.first_name, c.last_name, a.balance
HAVING MAX(t.transaction_date) < CURRENT_DATE - INTERVAL '180 days'
    OR MAX(t.transaction_date) IS NULL
ORDER BY days_inactive DESC;

-- ============================================
-- QUESTION 65: Calculate customer profitability
-- ============================================
-- Scenario: Segment customers by revenue contribution

WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        SUM(CASE WHEN t.transaction_type = 'FEE' THEN t.amount ELSE 0 END) AS fee_revenue,
        SUM(a.balance * a.interest_rate / 12) AS interest_spread,
        COUNT(DISTINCT a.account_id) AS num_accounts
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    customer_name,
    fee_revenue,
    ROUND(interest_spread, 2) AS interest_spread,
    ROUND(fee_revenue + interest_spread, 2) AS total_revenue,
    num_accounts,
    NTILE(5) OVER (ORDER BY fee_revenue + interest_spread DESC) AS profitability_quintile
FROM customer_revenue
ORDER BY total_revenue DESC;

-- ============================================
-- QUESTION 66: Detect money laundering patterns (structuring)
-- ============================================
-- Scenario: Find multiple deposits just under reporting threshold

SELECT 
    a.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    DATE(t.transaction_date) AS transaction_date,
    COUNT(*) AS num_deposits,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS avg_amount
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.transaction_type = 'DEPOSIT'
AND t.amount BETWEEN 8000 AND 9999  -- Just under $10K reporting threshold
GROUP BY a.customer_id, c.first_name, c.last_name, DATE(t.transaction_date)
HAVING COUNT(*) >= 3 OR SUM(t.amount) >= 25000
ORDER BY total_amount DESC;

-- ============================================
-- QUESTION 67: Calculate interest accrual
-- ============================================
-- Scenario: Month-end interest calculation for savings accounts

SELECT 
    a.account_id,
    a.account_type,
    a.balance,
    a.interest_rate,
    -- Simple daily interest calculation
    ROUND(a.balance * a.interest_rate / 365 * 
          EXTRACT(DAY FROM DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'), 2) AS monthly_interest,
    -- Compound interest (daily compounding)
    ROUND(a.balance * (POWER(1 + a.interest_rate/365, 30) - 1), 2) AS compound_interest
FROM accounts a
WHERE a.account_type IN ('SAVINGS', 'MONEY_MARKET')
AND a.status = 'ACTIVE'
ORDER BY monthly_interest DESC;

-- ============================================
-- QUESTION 68: Loan default risk analysis
-- ============================================
-- Scenario: Identify loans at risk of default

WITH payment_history AS (
    SELECT 
        l.loan_id,
        l.customer_id,
        COUNT(CASE WHEN t.amount < expected_payment THEN 1 END) AS missed_payments,
        COUNT(*) AS total_payments,
        MAX(t.transaction_date) AS last_payment_date
    FROM loans l
    LEFT JOIN transactions t ON l.loan_id = t.reference_id AND t.transaction_type = 'LOAN_PAYMENT'
    GROUP BY l.loan_id, l.customer_id
)
SELECT 
    l.loan_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.credit_score,
    l.principal,
    l.loan_type,
    ph.missed_payments,
    ph.total_payments,
    CURRENT_DATE - ph.last_payment_date AS days_since_payment,
    CASE 
        WHEN ph.missed_payments >= 3 OR CURRENT_DATE - ph.last_payment_date > 90 THEN 'HIGH'
        WHEN ph.missed_payments >= 1 OR CURRENT_DATE - ph.last_payment_date > 30 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_level
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
JOIN payment_history ph ON l.loan_id = ph.loan_id
WHERE l.status = 'ACTIVE'
ORDER BY risk_level DESC, days_since_payment DESC;

-- ============================================
-- QUESTION 69: Calculate net interest margin
-- ============================================
-- Scenario: Bank profitability analysis

WITH interest_income AS (
    SELECT SUM(balance * interest_rate) AS total_interest_income
    FROM loans WHERE status = 'ACTIVE'
),
interest_expense AS (
    SELECT SUM(balance * interest_rate) AS total_interest_expense
    FROM accounts WHERE account_type IN ('SAVINGS', 'CD', 'MONEY_MARKET')
),
total_assets AS (
    SELECT SUM(principal) AS earning_assets FROM loans WHERE status = 'ACTIVE'
)
SELECT 
    ii.total_interest_income,
    ie.total_interest_expense,
    ii.total_interest_income - ie.total_interest_expense AS net_interest_income,
    ta.earning_assets,
    ROUND(100.0 * (ii.total_interest_income - ie.total_interest_expense) / ta.earning_assets, 4) AS net_interest_margin_pct
FROM interest_income ii, interest_expense ie, total_assets ta;

-- ============================================
-- QUESTION 70: Find customers eligible for credit limit increase
-- ============================================
-- Scenario: Cross-sell opportunity identification

SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.credit_score,
    c.customer_since,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.customer_since)) AS years_as_customer,
    SUM(a.balance) AS total_balance,
    COUNT(DISTINCT a.account_id) AS num_accounts
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE c.credit_score >= 700
AND c.customer_since < CURRENT_DATE - INTERVAL '2 years'
AND NOT EXISTS (
    SELECT 1 FROM loans l 
    WHERE l.customer_id = c.customer_id 
    AND l.status IN ('DELINQUENT', 'DEFAULT')
)
GROUP BY c.customer_id, c.first_name, c.last_name, c.credit_score, c.customer_since
HAVING SUM(a.balance) > 10000
ORDER BY c.credit_score DESC, total_balance DESC;

-- ============================================
-- QUESTION 71: Transaction velocity analysis
-- ============================================
-- Scenario: Detect unusual transaction patterns

WITH hourly_transactions AS (
    SELECT 
        a.customer_id,
        DATE(t.transaction_date) AS trans_date,
        EXTRACT(HOUR FROM t.transaction_date) AS trans_hour,
        COUNT(*) AS transaction_count,
        SUM(t.amount) AS total_amount
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    GROUP BY a.customer_id, DATE(t.transaction_date), EXTRACT(HOUR FROM t.transaction_date)
)
SELECT 
    customer_id,
    trans_date,
    trans_hour,
    transaction_count,
    total_amount,
    AVG(transaction_count) OVER (PARTITION BY customer_id) AS avg_hourly_count,
    CASE 
        WHEN transaction_count > 3 * AVG(transaction_count) OVER (PARTITION BY customer_id) THEN 'SUSPICIOUS'
        ELSE 'NORMAL'
    END AS flag
FROM hourly_transactions
WHERE transaction_count > 10
ORDER BY transaction_count DESC;

-- ============================================
-- QUESTION 72: Calculate portfolio concentration risk
-- ============================================
-- Scenario: Risk management - loan portfolio analysis

WITH loan_concentration AS (
    SELECT 
        loan_type,
        COUNT(*) AS num_loans,
        SUM(principal) AS total_principal,
        AVG(interest_rate) AS avg_rate
    FROM loans
    WHERE status = 'ACTIVE'
    GROUP BY loan_type
)
SELECT 
    loan_type,
    num_loans,
    total_principal,
    ROUND(100.0 * total_principal / SUM(total_principal) OVER (), 2) AS portfolio_pct,
    ROUND(avg_rate * 100, 2) AS avg_rate_pct,
    CASE 
        WHEN 100.0 * total_principal / SUM(total_principal) OVER () > 30 THEN 'HIGH CONCENTRATION'
        WHEN 100.0 * total_principal / SUM(total_principal) OVER () > 20 THEN 'MODERATE'
        ELSE 'DIVERSIFIED'
    END AS concentration_risk
FROM loan_concentration
ORDER BY total_principal DESC;

-- ============================================
-- QUESTION 73: Identify cross-sell opportunities
-- ============================================
-- Scenario: Customers with checking but no savings

SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    SUM(CASE WHEN a.account_type = 'CHECKING' THEN a.balance ELSE 0 END) AS checking_balance,
    MAX(CASE WHEN a.account_type = 'SAVINGS' THEN 1 ELSE 0 END) AS has_savings,
    MAX(CASE WHEN a.account_type = 'CREDIT_CARD' THEN 1 ELSE 0 END) AS has_credit_card
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.status = 'ACTIVE'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING MAX(CASE WHEN a.account_type = 'SAVINGS' THEN 1 ELSE 0 END) = 0
AND SUM(CASE WHEN a.account_type = 'CHECKING' THEN a.balance ELSE 0 END) > 5000
ORDER BY checking_balance DESC;

-- ============================================
-- QUESTION 74: Calculate customer lifetime value
-- ============================================
-- Scenario: Strategic customer segmentation

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.customer_since)) AS tenure_years,
        SUM(a.balance) AS total_balance,
        SUM(CASE WHEN t.transaction_type = 'FEE' THEN t.amount ELSE 0 END) AS total_fees,
        COUNT(DISTINCT a.account_id) AS num_products
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_since
)
SELECT 
    customer_id,
    customer_name,
    tenure_years,
    total_balance,
    total_fees,
    num_products,
    -- Simple CLV = (Annual Revenue * Avg Lifespan) - Acquisition Cost
    ROUND((total_fees / NULLIF(tenure_years, 0)) * 10 + total_balance * 0.02, 2) AS estimated_clv
FROM customer_metrics
ORDER BY estimated_clv DESC;

-- ============================================
-- QUESTION 75: Regulatory reporting - large transactions
-- ============================================
-- Scenario: CTR (Currency Transaction Report) generation

SELECT 
    t.transaction_id,
    t.transaction_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    a.account_id,
    a.account_type,
    t.transaction_type,
    t.amount,
    t.description
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.amount >= 10000
AND t.transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')
AND t.transaction_date >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY t.amount DESC;

-- ============================================
-- QUESTION 76: Calculate overdraft fees impact
-- ============================================
-- Scenario: Customer fee analysis for retention

WITH overdraft_analysis AS (
    SELECT 
        a.customer_id,
        COUNT(CASE WHEN t.transaction_type = 'OVERDRAFT_FEE' THEN 1 END) AS overdraft_count,
        SUM(CASE WHEN t.transaction_type = 'OVERDRAFT_FEE' THEN t.amount ELSE 0 END) AS total_overdraft_fees
    FROM accounts a
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY a.customer_id
)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    oa.overdraft_count,
    oa.total_overdraft_fees,
    SUM(a.balance) AS current_balance,
    CASE 
        WHEN oa.overdraft_count > 10 THEN 'HIGH RISK - CONSIDER OUTREACH'
        WHEN oa.overdraft_count > 5 THEN 'MODERATE - OFFER OVERDRAFT PROTECTION'
        ELSE 'LOW'
    END AS recommendation
FROM overdraft_analysis oa
JOIN customers c ON oa.customer_id = c.customer_id
JOIN accounts a ON c.customer_id = a.customer_id
WHERE oa.overdraft_count > 0
GROUP BY c.customer_id, c.first_name, c.last_name, oa.overdraft_count, oa.total_overdraft_fees
ORDER BY oa.total_overdraft_fees DESC;

-- ============================================
-- QUESTION 77: Branch performance comparison
-- ============================================
-- Scenario: Compare branch metrics for resource allocation

SELECT 
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    SUM(a.balance) AS total_deposits,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    SUM(l.principal) AS total_loan_value,
    COUNT(DISTINCT a.customer_id) AS unique_customers,
    ROUND(SUM(a.balance) / COUNT(DISTINCT a.customer_id), 2) AS avg_balance_per_customer
FROM branches b
LEFT JOIN accounts a ON b.branch_id = a.branch_id
LEFT JOIN loans l ON b.branch_id = l.branch_id
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY total_deposits DESC;

-- ============================================
-- QUESTION 78: Detect account takeover attempts
-- ============================================
-- Scenario: Security - multiple failed login attempts

SELECT 
    al.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    DATE(al.attempt_time) AS attempt_date,
    COUNT(*) AS failed_attempts,
    COUNT(DISTINCT al.ip_address) AS unique_ips,
    ARRAY_AGG(DISTINCT al.ip_address) AS ip_addresses
FROM account_logins al
JOIN customers c ON al.customer_id = c.customer_id
WHERE al.success = FALSE
AND al.attempt_time >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY al.customer_id, c.first_name, c.last_name, c.email, DATE(al.attempt_time)
HAVING COUNT(*) >= 5
ORDER BY failed_attempts DESC;

-- ============================================
-- QUESTION 79: Calculate deposit growth rate
-- ============================================
-- Scenario: Track deposit trends for liquidity planning

WITH monthly_deposits AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) AS month,
        SUM(CASE WHEN transaction_type = 'DEPOSIT' THEN amount ELSE 0 END) AS deposits,
        SUM(CASE WHEN transaction_type = 'WITHDRAWAL' THEN amount ELSE 0 END) AS withdrawals
    FROM transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', transaction_date)
)
SELECT 
    month,
    deposits,
    withdrawals,
    deposits - withdrawals AS net_flow,
    SUM(deposits - withdrawals) OVER (ORDER BY month) AS cumulative_net_flow,
    ROUND(100.0 * (deposits - LAG(deposits) OVER (ORDER BY month)) / 
          NULLIF(LAG(deposits) OVER (ORDER BY month), 0), 2) AS deposit_growth_pct
FROM monthly_deposits
ORDER BY month;

-- ============================================
-- QUESTION 80: Identify high-value customer churn risk
-- ============================================
-- Scenario: Retention targeting for valuable customers

WITH customer_activity AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        SUM(a.balance) AS total_balance,
        MAX(t.transaction_date) AS last_activity,
        COUNT(t.transaction_id) FILTER (WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '30 days') AS recent_transactions,
        AVG(t.amount) AS avg_transaction_amount
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    customer_name,
    total_balance,
    last_activity,
    CURRENT_DATE - last_activity AS days_since_activity,
    recent_transactions,
    CASE 
        WHEN total_balance > 100000 AND recent_transactions < 2 THEN 'HIGH PRIORITY'
        WHEN total_balance > 50000 AND recent_transactions < 5 THEN 'MEDIUM PRIORITY'
        ELSE 'MONITOR'
    END AS churn_risk
FROM customer_activity
WHERE total_balance > 50000
AND (recent_transactions < 5 OR last_activity < CURRENT_DATE - INTERVAL '30 days')
ORDER BY total_balance DESC;
