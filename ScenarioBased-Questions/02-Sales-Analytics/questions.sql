-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: SALES ANALYTICS (Q21-Q40)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- 
-- Prerequisites: Run schema.sql first to create tables and sample data.
-- 
-- Supported Versions:
--   SQL Server: 2016+
--   Oracle: 12c+
--   PostgreSQL: 10+
--   MySQL: 8.0+
-- ============================================================================


-- ============================================================================
-- Q21: CALCULATE MONTHLY SALES GROWTH RATE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Truncation, LAG Window Function, Percentage Calculation
-- 
-- BUSINESS SCENARIO:
-- Management needs to track month-over-month sales performance to identify
-- trends and make data-driven decisions about marketing and inventory.
--
-- REQUIREMENTS:
-- - Group sales by month
-- - Calculate previous month's sales using LAG
-- - Calculate growth rate as percentage
-- - Handle first month (no previous data) and division by zero
--
-- EXPECTED OUTPUT:
-- +------------+-------------+------------------+-----------------+
-- | month      | total_sales | prev_month_sales | growth_rate_pct |
-- +------------+-------------+------------------+-----------------+
-- | 2024-01-01 | 125000.00   | NULL             | NULL            |
-- | 2024-02-01 | 142000.00   | 125000.00        | 13.60           |
-- +------------+-------------+------------------+-----------------+
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    CASE 
        WHEN LAG(total_sales) OVER (ORDER BY month) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (ORDER BY month) = 0 THEN NULL
        ELSE ROUND(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
             LAG(total_sales) OVER (ORDER BY month), 2)
    END AS growth_rate_pct
FROM monthly_sales
ORDER BY month;

-- ==================== ORACLE SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        TRUNC(order_date, 'MM') AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY TRUNC(order_date, 'MM')
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    CASE 
        WHEN LAG(total_sales) OVER (ORDER BY month) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (ORDER BY month) = 0 THEN NULL
        ELSE ROUND(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
             LAG(total_sales) OVER (ORDER BY month), 2)
    END AS growth_rate_pct
FROM monthly_sales
ORDER BY month;

-- ==================== POSTGRESQL SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date)::DATE AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)::DATE
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    CASE 
        WHEN LAG(total_sales) OVER (ORDER BY month) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (ORDER BY month) = 0 THEN NULL
        ELSE ROUND((100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
             LAG(total_sales) OVER (ORDER BY month))::NUMERIC, 2)
    END AS growth_rate_pct
FROM monthly_sales
ORDER BY month;

-- ==================== MYSQL SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m-01') AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    CASE 
        WHEN LAG(total_sales) OVER (ORDER BY month) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (ORDER BY month) = 0 THEN NULL
        ELSE ROUND(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
             LAG(total_sales) OVER (ORDER BY month), 2)
    END AS growth_rate_pct
FROM monthly_sales
ORDER BY month;

-- EXPLANATION:
-- Date truncation to month differs by RDBMS:
--   SQL Server: DATEFROMPARTS(YEAR, MONTH, 1)
--   Oracle: TRUNC(date, 'MM')
--   PostgreSQL: DATE_TRUNC('month', date)
--   MySQL: DATE_FORMAT(date, '%Y-%m-01')
-- LAG() gets value from previous row in the ordered result.
-- CASE handles NULL (first month) and division by zero.


-- ============================================================================
-- Q22: FIND TOP 10 CUSTOMERS BY LIFETIME VALUE
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Aggregation, JOIN, ORDER BY, LIMIT/TOP
-- 
-- BUSINESS SCENARIO:
-- Identify VIP customers for a loyalty program based on their total
-- spending history (lifetime value).
--
-- REQUIREMENTS:
-- - Calculate total orders, lifetime value, average order value
-- - Include first and last order dates
-- - Return only top 10 customers
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT TOP 10
    c.customer_id,
    c.company_name,
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.company_name, c.segment
ORDER BY lifetime_value DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT * FROM (
    SELECT 
        c.customer_id,
        c.company_name,
        c.segment,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS lifetime_value,
        AVG(o.total_amount) AS avg_order_value,
        MIN(o.order_date) AS first_order,
        MAX(o.order_date) AS last_order
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.company_name, c.segment
    ORDER BY lifetime_value DESC
) WHERE ROWNUM <= 10;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    c.customer_id,
    c.company_name,
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.company_name, c.segment
ORDER BY lifetime_value DESC
LIMIT 10;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    c.customer_id,
    c.company_name,
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.company_name, c.segment
ORDER BY lifetime_value DESC
LIMIT 10;

-- EXPLANATION:
-- Row limiting differs by RDBMS:
--   SQL Server: TOP n
--   Oracle: ROWNUM (subquery) or FETCH FIRST n ROWS ONLY (12c+)
--   PostgreSQL/MySQL: LIMIT n


-- ============================================================================
-- Q23: CALCULATE PRODUCT SALES RANKING BY CATEGORY
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Window Functions, RANK, Partitioning
-- 
-- BUSINESS SCENARIO:
-- Identify best-selling products within each category for inventory
-- planning and promotional decisions.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH product_sales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT 
    category_id,
    product_id,
    product_name,
    total_quantity,
    total_revenue,
    RANK() OVER (PARTITION BY category_id ORDER BY total_revenue DESC) AS category_rank
FROM product_sales
ORDER BY category_id, category_rank;

-- ==================== ORACLE SOLUTION ====================
WITH product_sales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT 
    category_id,
    product_id,
    product_name,
    total_quantity,
    total_revenue,
    RANK() OVER (PARTITION BY category_id ORDER BY total_revenue DESC) AS category_rank
FROM product_sales
ORDER BY category_id, category_rank;

-- ==================== POSTGRESQL SOLUTION ====================
WITH product_sales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT 
    category_id,
    product_id,
    product_name,
    total_quantity,
    total_revenue,
    RANK() OVER (PARTITION BY category_id ORDER BY total_revenue DESC) AS category_rank
FROM product_sales
ORDER BY category_id, category_rank;

-- ==================== MYSQL SOLUTION ====================
WITH product_sales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT 
    category_id,
    product_id,
    product_name,
    total_quantity,
    total_revenue,
    RANK() OVER (PARTITION BY category_id ORDER BY total_revenue DESC) AS category_rank
FROM product_sales
ORDER BY category_id, category_rank;

-- EXPLANATION:
-- RANK() OVER (PARTITION BY ... ORDER BY ...) assigns ranks within each partition.
-- Standard SQL that works identically across all modern RDBMS.


-- ============================================================================
-- Q24: FIND CUSTOMERS WITH DECLINING PURCHASE FREQUENCY
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Date Truncation, LAG, Quarterly Analysis
-- 
-- BUSINESS SCENARIO:
-- Identify at-risk customers whose order frequency is declining
-- quarter-over-quarter for targeted retention campaigns.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH customer_quarters AS (
    SELECT 
        customer_id,
        DATEFROMPARTS(YEAR(order_date), ((DATEPART(QUARTER, order_date) - 1) * 3) + 1, 1) AS quarter,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id, DATEFROMPARTS(YEAR(order_date), ((DATEPART(QUARTER, order_date) - 1) * 3) + 1, 1)
),
with_prev AS (
    SELECT 
        customer_id,
        quarter,
        order_count,
        LAG(order_count) OVER (PARTITION BY customer_id ORDER BY quarter) AS prev_quarter_orders
    FROM customer_quarters
)
SELECT 
    c.customer_id,
    c.company_name,
    w.quarter,
    w.order_count,
    w.prev_quarter_orders,
    w.order_count - w.prev_quarter_orders AS change
FROM with_prev w
INNER JOIN customers c ON w.customer_id = c.customer_id
WHERE w.order_count < w.prev_quarter_orders
ORDER BY change;

-- ==================== ORACLE SOLUTION ====================
WITH customer_quarters AS (
    SELECT 
        customer_id,
        TRUNC(order_date, 'Q') AS quarter,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id, TRUNC(order_date, 'Q')
),
with_prev AS (
    SELECT 
        customer_id,
        quarter,
        order_count,
        LAG(order_count) OVER (PARTITION BY customer_id ORDER BY quarter) AS prev_quarter_orders
    FROM customer_quarters
)
SELECT 
    c.customer_id,
    c.company_name,
    w.quarter,
    w.order_count,
    w.prev_quarter_orders,
    w.order_count - w.prev_quarter_orders AS change
FROM with_prev w
INNER JOIN customers c ON w.customer_id = c.customer_id
WHERE w.order_count < w.prev_quarter_orders
ORDER BY change;

-- ==================== POSTGRESQL SOLUTION ====================
WITH customer_quarters AS (
    SELECT 
        customer_id,
        DATE_TRUNC('quarter', order_date)::DATE AS quarter,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id, DATE_TRUNC('quarter', order_date)::DATE
),
with_prev AS (
    SELECT 
        customer_id,
        quarter,
        order_count,
        LAG(order_count) OVER (PARTITION BY customer_id ORDER BY quarter) AS prev_quarter_orders
    FROM customer_quarters
)
SELECT 
    c.customer_id,
    c.company_name,
    w.quarter,
    w.order_count,
    w.prev_quarter_orders,
    w.order_count - w.prev_quarter_orders AS change
FROM with_prev w
INNER JOIN customers c ON w.customer_id = c.customer_id
WHERE w.order_count < w.prev_quarter_orders
ORDER BY change;

-- ==================== MYSQL SOLUTION ====================
WITH customer_quarters AS (
    SELECT 
        customer_id,
        MAKEDATE(YEAR(order_date), 1) + INTERVAL (QUARTER(order_date) - 1) * 3 MONTH AS quarter,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id, MAKEDATE(YEAR(order_date), 1) + INTERVAL (QUARTER(order_date) - 1) * 3 MONTH
),
with_prev AS (
    SELECT 
        customer_id,
        quarter,
        order_count,
        LAG(order_count) OVER (PARTITION BY customer_id ORDER BY quarter) AS prev_quarter_orders
    FROM customer_quarters
)
SELECT 
    c.customer_id,
    c.company_name,
    w.quarter,
    w.order_count,
    w.prev_quarter_orders,
    w.order_count - w.prev_quarter_orders AS change
FROM with_prev w
INNER JOIN customers c ON w.customer_id = c.customer_id
WHERE w.order_count < w.prev_quarter_orders
ORDER BY change;

-- EXPLANATION:
-- Quarter truncation differs by RDBMS:
--   SQL Server: Complex DATEFROMPARTS calculation
--   Oracle: TRUNC(date, 'Q')
--   PostgreSQL: DATE_TRUNC('quarter', date)
--   MySQL: MAKEDATE + INTERVAL calculation


-- ============================================================================
-- Q25: CALCULATE AVERAGE DAYS BETWEEN ORDERS PER CUSTOMER
-- ============================================================================
-- Difficulty: Medium
-- Concepts: LAG, Date Arithmetic, Aggregation
-- 
-- BUSINESS SCENARIO:
-- Understand customer purchase patterns to optimize marketing timing
-- and predict reorder cycles.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        DATEDIFF(DAY, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), order_date) AS days_between
    FROM orders
)
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(*) AS total_orders,
    ROUND(AVG(CAST(og.days_between AS FLOAT)), 1) AS avg_days_between_orders,
    MIN(og.days_between) AS min_gap,
    MAX(og.days_between) AS max_gap
FROM order_gaps og
INNER JOIN customers c ON og.customer_id = c.customer_id
WHERE og.days_between IS NOT NULL
GROUP BY c.customer_id, c.company_name
HAVING COUNT(*) > 3
ORDER BY avg_days_between_orders;

-- ==================== ORACLE SOLUTION ====================
WITH order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_between
    FROM orders
)
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(*) AS total_orders,
    ROUND(AVG(og.days_between), 1) AS avg_days_between_orders,
    MIN(og.days_between) AS min_gap,
    MAX(og.days_between) AS max_gap
FROM order_gaps og
INNER JOIN customers c ON og.customer_id = c.customer_id
WHERE og.days_between IS NOT NULL
GROUP BY c.customer_id, c.company_name
HAVING COUNT(*) > 3
ORDER BY avg_days_between_orders;

-- ==================== POSTGRESQL SOLUTION ====================
WITH order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_between
    FROM orders
)
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(*) AS total_orders,
    ROUND(AVG(og.days_between)::NUMERIC, 1) AS avg_days_between_orders,
    MIN(og.days_between) AS min_gap,
    MAX(og.days_between) AS max_gap
FROM order_gaps og
INNER JOIN customers c ON og.customer_id = c.customer_id
WHERE og.days_between IS NOT NULL
GROUP BY c.customer_id, c.company_name
HAVING COUNT(*) > 3
ORDER BY avg_days_between_orders;

-- ==================== MYSQL SOLUTION ====================
WITH order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_between
    FROM orders
)
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(*) AS total_orders,
    ROUND(AVG(og.days_between), 1) AS avg_days_between_orders,
    MIN(og.days_between) AS min_gap,
    MAX(og.days_between) AS max_gap
FROM order_gaps og
INNER JOIN customers c ON og.customer_id = c.customer_id
WHERE og.days_between IS NOT NULL
GROUP BY c.customer_id, c.company_name
HAVING COUNT(*) > 3
ORDER BY avg_days_between_orders;

-- EXPLANATION:
-- Date difference calculation differs:
--   SQL Server: DATEDIFF(DAY, date1, date2)
--   Oracle: date2 - date1 (returns number)
--   PostgreSQL: date2 - date1 (returns integer)
--   MySQL: DATEDIFF(date2, date1)


-- ============================================================================
-- Q26: FIND PRODUCTS FREQUENTLY BOUGHT TOGETHER
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Self Join, Market Basket Analysis
-- 
-- BUSINESS SCENARIO:
-- Identify product pairs frequently purchased together for
-- bundling promotions and cross-selling recommendations.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT TOP 20
    oi1.product_id AS product1,
    p1.product_name AS product1_name,
    oi2.product_id AS product2,
    p2.product_name AS product2_name,
    COUNT(*) AS times_bought_together
FROM order_items oi1
INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
    AND oi1.product_id < oi2.product_id
INNER JOIN products p1 ON oi1.product_id = p1.product_id
INNER JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
HAVING COUNT(*) > 10
ORDER BY times_bought_together DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT * FROM (
    SELECT 
        oi1.product_id AS product1,
        p1.product_name AS product1_name,
        oi2.product_id AS product2,
        p2.product_name AS product2_name,
        COUNT(*) AS times_bought_together
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.product_id < oi2.product_id
    INNER JOIN products p1 ON oi1.product_id = p1.product_id
    INNER JOIN products p2 ON oi2.product_id = p2.product_id
    GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
    HAVING COUNT(*) > 10
    ORDER BY times_bought_together DESC
) WHERE ROWNUM <= 20;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    oi1.product_id AS product1,
    p1.product_name AS product1_name,
    oi2.product_id AS product2,
    p2.product_name AS product2_name,
    COUNT(*) AS times_bought_together
FROM order_items oi1
INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
    AND oi1.product_id < oi2.product_id
INNER JOIN products p1 ON oi1.product_id = p1.product_id
INNER JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
HAVING COUNT(*) > 10
ORDER BY times_bought_together DESC
LIMIT 20;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    oi1.product_id AS product1,
    p1.product_name AS product1_name,
    oi2.product_id AS product2,
    p2.product_name AS product2_name,
    COUNT(*) AS times_bought_together
FROM order_items oi1
INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
    AND oi1.product_id < oi2.product_id
INNER JOIN products p1 ON oi1.product_id = p1.product_id
INNER JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
HAVING COUNT(*) > 10
ORDER BY times_bought_together DESC
LIMIT 20;

-- EXPLANATION:
-- Self-join on order_items finds products in the same order.
-- Using < instead of <> avoids duplicate pairs (A,B) and (B,A).


-- ============================================================================
-- Q27: CALCULATE SALES REP PERFORMANCE METRICS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Multiple Metrics, Date Filtering
-- 
-- BUSINESS SCENARIO:
-- Evaluate sales team performance for quarterly reviews and
-- commission calculations.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    e.employee_id AS sales_rep_id,
    e.first_name + ' ' + e.last_name AS sales_rep_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_order_value,
    SUM(o.total_amount) / COUNT(DISTINCT o.customer_id) AS revenue_per_customer
FROM employees e
INNER JOIN orders o ON e.employee_id = o.sales_rep_id
WHERE o.status = 'Completed'
AND o.order_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_sales DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    e.employee_id AS sales_rep_id,
    e.first_name || ' ' || e.last_name AS sales_rep_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_order_value,
    SUM(o.total_amount) / COUNT(DISTINCT o.customer_id) AS revenue_per_customer
FROM employees e
INNER JOIN orders o ON e.employee_id = o.sales_rep_id
WHERE o.status = 'Completed'
AND o.order_date >= ADD_MONTHS(SYSDATE, -12)
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_sales DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    e.employee_id AS sales_rep_id,
    e.first_name || ' ' || e.last_name AS sales_rep_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_order_value,
    SUM(o.total_amount) / COUNT(DISTINCT o.customer_id) AS revenue_per_customer
FROM employees e
INNER JOIN orders o ON e.employee_id = o.sales_rep_id
WHERE o.status = 'Completed'
AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_sales DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    e.employee_id AS sales_rep_id,
    CONCAT(e.first_name, ' ', e.last_name) AS sales_rep_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_order_value,
    SUM(o.total_amount) / COUNT(DISTINCT o.customer_id) AS revenue_per_customer
FROM employees e
INNER JOIN orders o ON e.employee_id = o.sales_rep_id
WHERE o.status = 'Completed'
AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_sales DESC;

-- EXPLANATION:
-- String concatenation differs:
--   SQL Server: + operator
--   Oracle/PostgreSQL: || operator
--   MySQL: CONCAT() function
-- Date arithmetic differs:
--   SQL Server: DATEADD(YEAR, -1, GETDATE())
--   Oracle: ADD_MONTHS(SYSDATE, -12)
--   PostgreSQL: CURRENT_DATE - INTERVAL '1 year'
--   MySQL: DATE_SUB(CURDATE(), INTERVAL 1 YEAR)


-- ============================================================================
-- Q28: IDENTIFY SEASONAL SALES PATTERNS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Extraction, Aggregation, Percentage Calculation
-- 
-- BUSINESS SCENARIO:
-- Plan inventory and marketing campaigns based on historical
-- seasonal sales trends.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    MONTH(order_date) AS month_num,
    DATENAME(MONTH, order_date) AS month_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 2) AS pct_of_annual
FROM orders
WHERE status = 'Completed'
GROUP BY MONTH(order_date), DATENAME(MONTH, order_date)
ORDER BY month_num;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    EXTRACT(MONTH FROM order_date) AS month_num,
    TO_CHAR(order_date, 'Month') AS month_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 2) AS pct_of_annual
FROM orders
WHERE status = 'Completed'
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY month_num;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    EXTRACT(MONTH FROM order_date)::INT AS month_num,
    TO_CHAR(order_date, 'Month') AS month_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value,
    ROUND((100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER ())::NUMERIC, 2) AS pct_of_annual
FROM orders
WHERE status = 'Completed'
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY month_num;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    MONTH(order_date) AS month_num,
    MONTHNAME(order_date) AS month_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 2) AS pct_of_annual
FROM orders
WHERE status = 'Completed'
GROUP BY MONTH(order_date), MONTHNAME(order_date)
ORDER BY month_num;

-- EXPLANATION:
-- Month extraction and name formatting differs:
--   SQL Server: MONTH(), DATENAME(MONTH, date)
--   Oracle: EXTRACT(MONTH FROM date), TO_CHAR(date, 'Month')
--   PostgreSQL: EXTRACT(MONTH FROM date), TO_CHAR(date, 'Month')
--   MySQL: MONTH(), MONTHNAME()


-- ============================================================================
-- Q29: CALCULATE CUSTOMER RETENTION RATE (COHORT ANALYSIS)
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Cohort Analysis, DATE_TRUNC, FIRST_VALUE
-- 
-- BUSINESS SCENARIO:
-- Measure customer loyalty by tracking how many customers from each
-- acquisition cohort continue to make purchases over time.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH first_purchase AS (
    SELECT 
        customer_id,
        DATEFROMPARTS(YEAR(MIN(order_date)), MONTH(MIN(order_date)), 1) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT 
        fp.cohort_month,
        DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS activity_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM first_purchase fp
    INNER JOIN orders o ON fp.customer_id = o.customer_id
    GROUP BY fp.cohort_month, DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1)
)
SELECT 
    cohort_month,
    activity_month,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,
    ROUND(100.0 * active_customers / 
          FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month), 2) AS retention_rate
FROM monthly_activity
ORDER BY cohort_month, activity_month;

-- ==================== ORACLE SOLUTION ====================
WITH first_purchase AS (
    SELECT 
        customer_id,
        TRUNC(MIN(order_date), 'MM') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT 
        fp.cohort_month,
        TRUNC(o.order_date, 'MM') AS activity_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM first_purchase fp
    INNER JOIN orders o ON fp.customer_id = o.customer_id
    GROUP BY fp.cohort_month, TRUNC(o.order_date, 'MM')
)
SELECT 
    cohort_month,
    activity_month,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,
    ROUND(100.0 * active_customers / 
          FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month), 2) AS retention_rate
FROM monthly_activity
ORDER BY cohort_month, activity_month;

-- ==================== POSTGRESQL SOLUTION ====================
WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::DATE AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT 
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date)::DATE AS activity_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM first_purchase fp
    INNER JOIN orders o ON fp.customer_id = o.customer_id
    GROUP BY fp.cohort_month, DATE_TRUNC('month', o.order_date)::DATE
)
SELECT 
    cohort_month,
    activity_month,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,
    ROUND((100.0 * active_customers / 
          FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month))::NUMERIC, 2) AS retention_rate
FROM monthly_activity
ORDER BY cohort_month, activity_month;

-- ==================== MYSQL SOLUTION ====================
WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT 
        fp.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS activity_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM first_purchase fp
    INNER JOIN orders o ON fp.customer_id = o.customer_id
    GROUP BY fp.cohort_month, DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT 
    cohort_month,
    activity_month,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,
    ROUND(100.0 * active_customers / 
          FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month), 2) AS retention_rate
FROM monthly_activity
ORDER BY cohort_month, activity_month;

-- EXPLANATION:
-- Cohort analysis tracks customer behavior over time from their first purchase.
-- FIRST_VALUE() gets the initial cohort size for retention calculation.


-- ============================================================================
-- Q30: FIND ORDERS WITH UNUSUAL DISCOUNT PATTERNS (FRAUD DETECTION)
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Statistical Analysis, Z-Score, CROSS JOIN
-- 
-- BUSINESS SCENARIO:
-- Identify potentially fraudulent orders with unusually high discounts
-- using statistical outlier detection (z-score > 2).
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH discount_stats AS (
    SELECT 
        AVG(discount) AS avg_discount,
        STDEV(discount) AS stddev_discount
    FROM orders
    WHERE discount > 0
)
SELECT 
    o.order_id,
    o.customer_id,
    c.company_name,
    o.order_date,
    o.total_amount,
    o.discount,
    o.sales_rep_id,
    ROUND((o.discount - ds.avg_discount) / ds.stddev_discount, 2) AS z_score
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
CROSS JOIN discount_stats ds
WHERE o.discount > ds.avg_discount + 2 * ds.stddev_discount
ORDER BY z_score DESC;

-- ==================== ORACLE SOLUTION ====================
WITH discount_stats AS (
    SELECT 
        AVG(discount) AS avg_discount,
        STDDEV(discount) AS stddev_discount
    FROM orders
    WHERE discount > 0
)
SELECT 
    o.order_id,
    o.customer_id,
    c.company_name,
    o.order_date,
    o.total_amount,
    o.discount,
    o.sales_rep_id,
    ROUND((o.discount - ds.avg_discount) / ds.stddev_discount, 2) AS z_score
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
CROSS JOIN discount_stats ds
WHERE o.discount > ds.avg_discount + 2 * ds.stddev_discount
ORDER BY z_score DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH discount_stats AS (
    SELECT 
        AVG(discount) AS avg_discount,
        STDDEV(discount) AS stddev_discount
    FROM orders
    WHERE discount > 0
)
SELECT 
    o.order_id,
    o.customer_id,
    c.company_name,
    o.order_date,
    o.total_amount,
    o.discount,
    o.sales_rep_id,
    ROUND(((o.discount - ds.avg_discount) / ds.stddev_discount)::NUMERIC, 2) AS z_score
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
CROSS JOIN discount_stats ds
WHERE o.discount > ds.avg_discount + 2 * ds.stddev_discount
ORDER BY z_score DESC;

-- ==================== MYSQL SOLUTION ====================
WITH discount_stats AS (
    SELECT 
        AVG(discount) AS avg_discount,
        STDDEV(discount) AS stddev_discount
    FROM orders
    WHERE discount > 0
)
SELECT 
    o.order_id,
    o.customer_id,
    c.company_name,
    o.order_date,
    o.total_amount,
    o.discount,
    o.sales_rep_id,
    ROUND((o.discount - ds.avg_discount) / ds.stddev_discount, 2) AS z_score
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
CROSS JOIN discount_stats ds
WHERE o.discount > ds.avg_discount + 2 * ds.stddev_discount
ORDER BY z_score DESC;

-- EXPLANATION:
-- Standard deviation function name differs:
--   SQL Server: STDEV()
--   Oracle/PostgreSQL/MySQL: STDDEV()
-- Z-score measures how many standard deviations from the mean.


-- ============================================================================
-- Q31: CALCULATE RUNNING TOTAL OF SALES BY REGION
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Window Functions, Running Totals, Frame Clause
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    c.country,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY c.country ORDER BY o.order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    SUM(o.total_amount) OVER (PARTITION BY c.country) AS region_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY c.country, o.order_date;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    c.country,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY c.country ORDER BY o.order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    SUM(o.total_amount) OVER (PARTITION BY c.country) AS region_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY c.country, o.order_date;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    c.country,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY c.country ORDER BY o.order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    SUM(o.total_amount) OVER (PARTITION BY c.country) AS region_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY c.country, o.order_date;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    c.country,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY c.country ORDER BY o.order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    SUM(o.total_amount) OVER (PARTITION BY c.country) AS region_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY c.country, o.order_date;

-- EXPLANATION:
-- Window frame clause is standard SQL and works identically across all RDBMS.
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW creates running total.


-- ============================================================================
-- Q32: FIND THE BEST DAY OF WEEK FOR SALES
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Date Part Extraction, Aggregation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    DATEPART(WEEKDAY, order_date) AS day_of_week,
    DATENAME(WEEKDAY, order_date) AS day_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'Completed'
GROUP BY DATEPART(WEEKDAY, order_date), DATENAME(WEEKDAY, order_date)
ORDER BY total_sales DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    TO_NUMBER(TO_CHAR(order_date, 'D')) AS day_of_week,
    TO_CHAR(order_date, 'Day') AS day_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'Completed'
GROUP BY TO_NUMBER(TO_CHAR(order_date, 'D')), TO_CHAR(order_date, 'Day')
ORDER BY total_sales DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    EXTRACT(DOW FROM order_date)::INT AS day_of_week,
    TO_CHAR(order_date, 'Day') AS day_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'Completed'
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day')
ORDER BY total_sales DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    DAYOFWEEK(order_date) AS day_of_week,
    DAYNAME(order_date) AS day_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'Completed'
GROUP BY DAYOFWEEK(order_date), DAYNAME(order_date)
ORDER BY total_sales DESC;

-- EXPLANATION:
-- Day of week extraction differs:
--   SQL Server: DATEPART(WEEKDAY, date), DATENAME(WEEKDAY, date)
--   Oracle: TO_CHAR(date, 'D'), TO_CHAR(date, 'Day')
--   PostgreSQL: EXTRACT(DOW FROM date), TO_CHAR(date, 'Day')
--   MySQL: DAYOFWEEK(), DAYNAME()


-- ============================================================================
-- Q33: CALCULATE YEAR-OVER-YEAR GROWTH BY PRODUCT CATEGORY
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Year Extraction, LAG, Percentage Calculation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH category_yearly AS (
    SELECT 
        p.category_id,
        YEAR(o.order_date) AS year,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category_id, YEAR(o.order_date)
)
SELECT 
    category_id,
    year,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) AS prev_year_sales,
    CASE 
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) = 0 THEN NULL
        ELSE ROUND(100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year)) / 
             LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year), 2)
    END AS yoy_growth
FROM category_yearly
ORDER BY category_id, year;

-- ==================== ORACLE SOLUTION ====================
WITH category_yearly AS (
    SELECT 
        p.category_id,
        EXTRACT(YEAR FROM o.order_date) AS year,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category_id, EXTRACT(YEAR FROM o.order_date)
)
SELECT 
    category_id,
    year,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) AS prev_year_sales,
    CASE 
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) = 0 THEN NULL
        ELSE ROUND(100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year)) / 
             LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year), 2)
    END AS yoy_growth
FROM category_yearly
ORDER BY category_id, year;

-- ==================== POSTGRESQL SOLUTION ====================
WITH category_yearly AS (
    SELECT 
        p.category_id,
        EXTRACT(YEAR FROM o.order_date)::INT AS year,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category_id, EXTRACT(YEAR FROM o.order_date)
)
SELECT 
    category_id,
    year,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) AS prev_year_sales,
    CASE 
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) = 0 THEN NULL
        ELSE ROUND((100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year)) / 
             LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year))::NUMERIC, 2)
    END AS yoy_growth
FROM category_yearly
ORDER BY category_id, year;

-- ==================== MYSQL SOLUTION ====================
WITH category_yearly AS (
    SELECT 
        p.category_id,
        YEAR(o.order_date) AS year,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category_id, YEAR(o.order_date)
)
SELECT 
    category_id,
    year,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) AS prev_year_sales,
    CASE 
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) IS NULL THEN NULL
        WHEN LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) = 0 THEN NULL
        ELSE ROUND(100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year)) / 
             LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year), 2)
    END AS yoy_growth
FROM category_yearly
ORDER BY category_id, year;

-- EXPLANATION:
-- Year extraction differs:
--   SQL Server: YEAR()
--   Oracle/PostgreSQL: EXTRACT(YEAR FROM date)
--   MySQL: YEAR()


-- ============================================================================
-- Q34: FIND CUSTOMERS WHO HAVEN'T ORDERED IN 6 MONTHS
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Date Arithmetic, HAVING, Aggregation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name,
    c.segment,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_order,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.contact_name, c.segment
HAVING MAX(o.order_date) < DATEADD(MONTH, -6, GETDATE())
ORDER BY lifetime_value DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name,
    c.segment,
    MAX(o.order_date) AS last_order_date,
    TRUNC(SYSDATE - MAX(o.order_date)) AS days_since_last_order,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.contact_name, c.segment
HAVING MAX(o.order_date) < ADD_MONTHS(SYSDATE, -6)
ORDER BY lifetime_value DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name,
    c.segment,
    MAX(o.order_date) AS last_order_date,
    CURRENT_DATE - MAX(o.order_date) AS days_since_last_order,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.contact_name, c.segment
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '6 months'
ORDER BY lifetime_value DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name,
    c.segment,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.contact_name, c.segment
HAVING MAX(o.order_date) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY lifetime_value DESC;

-- EXPLANATION:
-- Date subtraction for "6 months ago" differs:
--   SQL Server: DATEADD(MONTH, -6, GETDATE())
--   Oracle: ADD_MONTHS(SYSDATE, -6)
--   PostgreSQL: CURRENT_DATE - INTERVAL '6 months'
--   MySQL: DATE_SUB(CURDATE(), INTERVAL 6 MONTH)


-- ============================================================================
-- Q35: CALCULATE AVERAGE ORDER FULFILLMENT TIME
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Arithmetic, Percentile, Aggregation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    MONTH(order_date) AS month,
    COUNT(*) AS total_orders,
    AVG(DATEDIFF(DAY, order_date, ship_date)) AS avg_fulfillment_days,
    MIN(DATEDIFF(DAY, order_date, ship_date)) AS min_fulfillment_days,
    MAX(DATEDIFF(DAY, order_date, ship_date)) AS max_fulfillment_days
FROM orders
WHERE status = 'Completed' AND ship_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY month;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(*) AS total_orders,
    AVG(ship_date - order_date) AS avg_fulfillment_days,
    MIN(ship_date - order_date) AS min_fulfillment_days,
    MAX(ship_date - order_date) AS max_fulfillment_days
FROM orders
WHERE status = 'Completed' AND ship_date IS NOT NULL
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    EXTRACT(MONTH FROM order_date)::INT AS month,
    COUNT(*) AS total_orders,
    AVG(ship_date - order_date) AS avg_fulfillment_days,
    MIN(ship_date - order_date) AS min_fulfillment_days,
    MAX(ship_date - order_date) AS max_fulfillment_days
FROM orders
WHERE status = 'Completed' AND ship_date IS NOT NULL
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    MONTH(order_date) AS month,
    COUNT(*) AS total_orders,
    AVG(DATEDIFF(ship_date, order_date)) AS avg_fulfillment_days,
    MIN(DATEDIFF(ship_date, order_date)) AS min_fulfillment_days,
    MAX(DATEDIFF(ship_date, order_date)) AS max_fulfillment_days
FROM orders
WHERE status = 'Completed' AND ship_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY month;

-- EXPLANATION:
-- Date difference syntax varies across RDBMS.


-- ============================================================================
-- Q36: IDENTIFY CROSS-SELLING OPPORTUNITIES
-- ============================================================================
-- Difficulty: Medium
-- Concepts: NOT IN, Subqueries, CTEs
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH bought_laptops AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_name LIKE '%Laptop%'
),
bought_accessories AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.category_id = 5
)
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name
FROM bought_laptops bl
INNER JOIN customers c ON bl.customer_id = c.customer_id
WHERE bl.customer_id NOT IN (SELECT customer_id FROM bought_accessories);

-- ==================== ORACLE SOLUTION ====================
WITH bought_laptops AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_name LIKE '%Laptop%'
),
bought_accessories AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.category_id = 5
)
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name
FROM bought_laptops bl
INNER JOIN customers c ON bl.customer_id = c.customer_id
WHERE bl.customer_id NOT IN (SELECT customer_id FROM bought_accessories);

-- ==================== POSTGRESQL SOLUTION ====================
WITH bought_laptops AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_name LIKE '%Laptop%'
),
bought_accessories AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.category_id = 5
)
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name
FROM bought_laptops bl
INNER JOIN customers c ON bl.customer_id = c.customer_id
WHERE bl.customer_id NOT IN (SELECT customer_id FROM bought_accessories);

-- ==================== MYSQL SOLUTION ====================
WITH bought_laptops AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_name LIKE '%Laptop%'
),
bought_accessories AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE p.category_id = 5
)
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name
FROM bought_laptops bl
INNER JOIN customers c ON bl.customer_id = c.customer_id
WHERE bl.customer_id NOT IN (SELECT customer_id FROM bought_accessories);

-- EXPLANATION:
-- Standard SQL that works identically across all RDBMS.
-- Identifies customers who bought laptops but not accessories.


-- ============================================================================
-- Q37: CALCULATE MARKET BASKET ANALYSIS METRICS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Self Join, Confidence Calculation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH product_orders AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS order_count
    FROM order_items
    GROUP BY product_id
),
product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS pair_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
)
SELECT 
    pp.product_a,
    pp.product_b,
    pp.pair_count,
    po_a.order_count AS product_a_orders,
    po_b.order_count AS product_b_orders,
    ROUND(100.0 * pp.pair_count / po_a.order_count, 2) AS confidence_a_to_b,
    ROUND(100.0 * pp.pair_count / po_b.order_count, 2) AS confidence_b_to_a
FROM product_pairs pp
INNER JOIN product_orders po_a ON pp.product_a = po_a.product_id
INNER JOIN product_orders po_b ON pp.product_b = po_b.product_id
WHERE pp.pair_count > 5
ORDER BY pp.pair_count DESC;

-- ==================== ORACLE SOLUTION ====================
WITH product_orders AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS order_count
    FROM order_items
    GROUP BY product_id
),
product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS pair_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
)
SELECT 
    pp.product_a,
    pp.product_b,
    pp.pair_count,
    po_a.order_count AS product_a_orders,
    po_b.order_count AS product_b_orders,
    ROUND(100.0 * pp.pair_count / po_a.order_count, 2) AS confidence_a_to_b,
    ROUND(100.0 * pp.pair_count / po_b.order_count, 2) AS confidence_b_to_a
FROM product_pairs pp
INNER JOIN product_orders po_a ON pp.product_a = po_a.product_id
INNER JOIN product_orders po_b ON pp.product_b = po_b.product_id
WHERE pp.pair_count > 5
ORDER BY pp.pair_count DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH product_orders AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS order_count
    FROM order_items
    GROUP BY product_id
),
product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS pair_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
)
SELECT 
    pp.product_a,
    pp.product_b,
    pp.pair_count,
    po_a.order_count AS product_a_orders,
    po_b.order_count AS product_b_orders,
    ROUND((100.0 * pp.pair_count / po_a.order_count)::NUMERIC, 2) AS confidence_a_to_b,
    ROUND((100.0 * pp.pair_count / po_b.order_count)::NUMERIC, 2) AS confidence_b_to_a
FROM product_pairs pp
INNER JOIN product_orders po_a ON pp.product_a = po_a.product_id
INNER JOIN product_orders po_b ON pp.product_b = po_b.product_id
WHERE pp.pair_count > 5
ORDER BY pp.pair_count DESC;

-- ==================== MYSQL SOLUTION ====================
WITH product_orders AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS order_count
    FROM order_items
    GROUP BY product_id
),
product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS pair_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
)
SELECT 
    pp.product_a,
    pp.product_b,
    pp.pair_count,
    po_a.order_count AS product_a_orders,
    po_b.order_count AS product_b_orders,
    ROUND(100.0 * pp.pair_count / po_a.order_count, 2) AS confidence_a_to_b,
    ROUND(100.0 * pp.pair_count / po_b.order_count, 2) AS confidence_b_to_a
FROM product_pairs pp
INNER JOIN product_orders po_a ON pp.product_a = po_a.product_id
INNER JOIN product_orders po_b ON pp.product_b = po_b.product_id
WHERE pp.pair_count > 5
ORDER BY pp.pair_count DESC;

-- EXPLANATION:
-- Confidence = P(B|A) = Support(A,B) / Support(A)
-- Measures likelihood of buying B given purchase of A.


-- ============================================================================
-- Q38: FIND SALES ANOMALIES USING MOVING AVERAGE
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Window Functions, Moving Average, Z-Score
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        order_date,
        SUM(total_amount) AS daily_total
    FROM orders
    WHERE status = 'Completed'
    GROUP BY order_date
),
with_moving_avg AS (
    SELECT 
        order_date,
        daily_total,
        AVG(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        STDEV(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS stddev_7d
    FROM daily_sales
)
SELECT 
    order_date,
    daily_total,
    ROUND(moving_avg_7d, 2) AS moving_avg_7d,
    CASE WHEN stddev_7d = 0 THEN NULL 
         ELSE ROUND((daily_total - moving_avg_7d) / stddev_7d, 2) END AS z_score,
    CASE 
        WHEN stddev_7d > 0 AND daily_total > moving_avg_7d + 2 * stddev_7d THEN 'Spike'
        WHEN stddev_7d > 0 AND daily_total < moving_avg_7d - 2 * stddev_7d THEN 'Drop'
        ELSE 'Normal'
    END AS anomaly_type
FROM with_moving_avg
WHERE stddev_7d > 0 AND ABS((daily_total - moving_avg_7d) / stddev_7d) > 2
ORDER BY order_date;

-- ==================== ORACLE SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        order_date,
        SUM(total_amount) AS daily_total
    FROM orders
    WHERE status = 'Completed'
    GROUP BY order_date
),
with_moving_avg AS (
    SELECT 
        order_date,
        daily_total,
        AVG(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        STDDEV(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS stddev_7d
    FROM daily_sales
)
SELECT 
    order_date,
    daily_total,
    ROUND(moving_avg_7d, 2) AS moving_avg_7d,
    CASE WHEN stddev_7d = 0 THEN NULL 
         ELSE ROUND((daily_total - moving_avg_7d) / stddev_7d, 2) END AS z_score,
    CASE 
        WHEN stddev_7d > 0 AND daily_total > moving_avg_7d + 2 * stddev_7d THEN 'Spike'
        WHEN stddev_7d > 0 AND daily_total < moving_avg_7d - 2 * stddev_7d THEN 'Drop'
        ELSE 'Normal'
    END AS anomaly_type
FROM with_moving_avg
WHERE stddev_7d > 0 AND ABS((daily_total - moving_avg_7d) / stddev_7d) > 2
ORDER BY order_date;

-- ==================== POSTGRESQL SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        order_date,
        SUM(total_amount) AS daily_total
    FROM orders
    WHERE status = 'Completed'
    GROUP BY order_date
),
with_moving_avg AS (
    SELECT 
        order_date,
        daily_total,
        AVG(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        STDDEV(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS stddev_7d
    FROM daily_sales
)
SELECT 
    order_date,
    daily_total,
    ROUND(moving_avg_7d::NUMERIC, 2) AS moving_avg_7d,
    CASE WHEN stddev_7d = 0 THEN NULL 
         ELSE ROUND(((daily_total - moving_avg_7d) / stddev_7d)::NUMERIC, 2) END AS z_score,
    CASE 
        WHEN stddev_7d > 0 AND daily_total > moving_avg_7d + 2 * stddev_7d THEN 'Spike'
        WHEN stddev_7d > 0 AND daily_total < moving_avg_7d - 2 * stddev_7d THEN 'Drop'
        ELSE 'Normal'
    END AS anomaly_type
FROM with_moving_avg
WHERE stddev_7d > 0 AND ABS((daily_total - moving_avg_7d) / stddev_7d) > 2
ORDER BY order_date;

-- ==================== MYSQL SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        order_date,
        SUM(total_amount) AS daily_total
    FROM orders
    WHERE status = 'Completed'
    GROUP BY order_date
),
with_moving_avg AS (
    SELECT 
        order_date,
        daily_total,
        AVG(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        STDDEV(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS stddev_7d
    FROM daily_sales
)
SELECT 
    order_date,
    daily_total,
    ROUND(moving_avg_7d, 2) AS moving_avg_7d,
    CASE WHEN stddev_7d = 0 THEN NULL 
         ELSE ROUND((daily_total - moving_avg_7d) / stddev_7d, 2) END AS z_score,
    CASE 
        WHEN stddev_7d > 0 AND daily_total > moving_avg_7d + 2 * stddev_7d THEN 'Spike'
        WHEN stddev_7d > 0 AND daily_total < moving_avg_7d - 2 * stddev_7d THEN 'Drop'
        ELSE 'Normal'
    END AS anomaly_type
FROM with_moving_avg
WHERE stddev_7d > 0 AND ABS((daily_total - moving_avg_7d) / stddev_7d) > 2
ORDER BY order_date;

-- EXPLANATION:
-- 7-day moving average smooths daily fluctuations.
-- Z-score > 2 or < -2 indicates statistical anomaly.


-- ============================================================================
-- Q39: CALCULATE CUSTOMER SEGMENT PROFITABILITY
-- ============================================================================
-- Difficulty: Medium
-- Concepts: LEFT JOIN, NULL Handling, Aggregation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ISNULL(SUM(o.total_amount), 0) AS total_revenue,
    ISNULL(SUM(o.total_amount - ISNULL(o.discount, 0)), 0) AS net_revenue,
    ISNULL(AVG(o.total_amount), 0) AS avg_order_value,
    CASE WHEN COUNT(DISTINCT c.customer_id) > 0 
         THEN ISNULL(SUM(o.total_amount), 0) / COUNT(DISTINCT c.customer_id) 
         ELSE 0 END AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.segment
ORDER BY net_revenue DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    NVL(SUM(o.total_amount), 0) AS total_revenue,
    NVL(SUM(o.total_amount - NVL(o.discount, 0)), 0) AS net_revenue,
    NVL(AVG(o.total_amount), 0) AS avg_order_value,
    CASE WHEN COUNT(DISTINCT c.customer_id) > 0 
         THEN NVL(SUM(o.total_amount), 0) / COUNT(DISTINCT c.customer_id) 
         ELSE 0 END AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.segment
ORDER BY net_revenue DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    COALESCE(SUM(o.total_amount - COALESCE(o.discount, 0)), 0) AS net_revenue,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    CASE WHEN COUNT(DISTINCT c.customer_id) > 0 
         THEN COALESCE(SUM(o.total_amount), 0) / COUNT(DISTINCT c.customer_id) 
         ELSE 0 END AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.segment
ORDER BY net_revenue DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    IFNULL(SUM(o.total_amount), 0) AS total_revenue,
    IFNULL(SUM(o.total_amount - IFNULL(o.discount, 0)), 0) AS net_revenue,
    IFNULL(AVG(o.total_amount), 0) AS avg_order_value,
    CASE WHEN COUNT(DISTINCT c.customer_id) > 0 
         THEN IFNULL(SUM(o.total_amount), 0) / COUNT(DISTINCT c.customer_id) 
         ELSE 0 END AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.segment
ORDER BY net_revenue DESC;

-- EXPLANATION:
-- NULL handling function differs:
--   SQL Server: ISNULL()
--   Oracle: NVL()
--   PostgreSQL: COALESCE()
--   MySQL: IFNULL() or COALESCE()


-- ============================================================================
-- Q40: GENERATE SALES FORECAST BASED ON TREND
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Linear Regression, Window Functions
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month,
        ROW_NUMBER() OVER (ORDER BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)) AS month_num,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
),
stats AS (
    SELECT 
        AVG(CAST(month_num AS FLOAT)) AS avg_x,
        AVG(total_sales) AS avg_y,
        COUNT(*) AS n
    FROM monthly_sales
),
regression AS (
    SELECT 
        s.avg_x,
        s.avg_y,
        SUM((ms.month_num - s.avg_x) * (ms.total_sales - s.avg_y)) / 
            NULLIF(SUM(POWER(ms.month_num - s.avg_x, 2)), 0) AS slope
    FROM monthly_sales ms
    CROSS JOIN stats s
    GROUP BY s.avg_x, s.avg_y
)
SELECT 
    ms.month,
    ms.total_sales AS actual_sales,
    ROUND(r.avg_y + r.slope * (ms.month_num - r.avg_x), 2) AS trend_value,
    ROUND(r.avg_y + r.slope * (ms.month_num + 3 - r.avg_x), 2) AS forecast_3_months
FROM monthly_sales ms
CROSS JOIN regression r
ORDER BY ms.month;

-- ==================== ORACLE SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        TRUNC(order_date, 'MM') AS month,
        ROW_NUMBER() OVER (ORDER BY TRUNC(order_date, 'MM')) AS month_num,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY TRUNC(order_date, 'MM')
),
stats AS (
    SELECT 
        AVG(month_num) AS avg_x,
        AVG(total_sales) AS avg_y,
        COUNT(*) AS n
    FROM monthly_sales
),
regression AS (
    SELECT 
        s.avg_x,
        s.avg_y,
        SUM((ms.month_num - s.avg_x) * (ms.total_sales - s.avg_y)) / 
            NULLIF(SUM(POWER(ms.month_num - s.avg_x, 2)), 0) AS slope
    FROM monthly_sales ms
    CROSS JOIN stats s
    GROUP BY s.avg_x, s.avg_y
)
SELECT 
    ms.month,
    ms.total_sales AS actual_sales,
    ROUND(r.avg_y + r.slope * (ms.month_num - r.avg_x), 2) AS trend_value,
    ROUND(r.avg_y + r.slope * (ms.month_num + 3 - r.avg_x), 2) AS forecast_3_months
FROM monthly_sales ms
CROSS JOIN regression r
ORDER BY ms.month;

-- ==================== POSTGRESQL SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date)::DATE AS month,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', order_date)) AS month_num,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)::DATE
),
stats AS (
    SELECT 
        AVG(month_num) AS avg_x,
        AVG(total_sales) AS avg_y,
        COUNT(*) AS n
    FROM monthly_sales
),
regression AS (
    SELECT 
        s.avg_x,
        s.avg_y,
        SUM((ms.month_num - s.avg_x) * (ms.total_sales - s.avg_y)) / 
            NULLIF(SUM(POWER(ms.month_num - s.avg_x, 2)), 0) AS slope
    FROM monthly_sales ms
    CROSS JOIN stats s
    GROUP BY s.avg_x, s.avg_y
)
SELECT 
    ms.month,
    ms.total_sales AS actual_sales,
    ROUND((r.avg_y + r.slope * (ms.month_num - r.avg_x))::NUMERIC, 2) AS trend_value,
    ROUND((r.avg_y + r.slope * (ms.month_num + 3 - r.avg_x))::NUMERIC, 2) AS forecast_3_months
FROM monthly_sales ms
CROSS JOIN regression r
ORDER BY ms.month;

-- ==================== MYSQL SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m-01') AS month,
        ROW_NUMBER() OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m-01')) AS month_num,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
),
stats AS (
    SELECT 
        AVG(month_num) AS avg_x,
        AVG(total_sales) AS avg_y,
        COUNT(*) AS n
    FROM monthly_sales
),
regression AS (
    SELECT 
        s.avg_x,
        s.avg_y,
        SUM((ms.month_num - s.avg_x) * (ms.total_sales - s.avg_y)) / 
            NULLIF(SUM(POWER(ms.month_num - s.avg_x, 2)), 0) AS slope
    FROM monthly_sales ms
    CROSS JOIN stats s
    GROUP BY s.avg_x, s.avg_y
)
SELECT 
    ms.month,
    ms.total_sales AS actual_sales,
    ROUND(r.avg_y + r.slope * (ms.month_num - r.avg_x), 2) AS trend_value,
    ROUND(r.avg_y + r.slope * (ms.month_num + 3 - r.avg_x), 2) AS forecast_3_months
FROM monthly_sales ms
CROSS JOIN regression r
ORDER BY ms.month;

-- EXPLANATION:
-- Simple linear regression: y = avg_y + slope * (x - avg_x)
-- slope = SUM((x - avg_x)(y - avg_y)) / SUM((x - avg_x)^2)
-- Forecast extends the trend line into future months.


-- ============================================================================
-- END OF SALES ANALYTICS QUESTIONS (Q21-Q40)
-- ============================================================================
