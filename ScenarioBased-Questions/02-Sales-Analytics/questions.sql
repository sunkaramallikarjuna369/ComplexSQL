-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Sales Analytics (Questions 21-40)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    ship_date DATE,
    status VARCHAR(20),
    total_amount DECIMAL(12,2),
    discount DECIMAL(5,2),
    sales_rep_id INT
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount DECIMAL(5,2)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_id INT,
    unit_price DECIMAL(10,2),
    units_in_stock INT,
    discontinued BIT
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    company_name VARCHAR(100),
    contact_name VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    segment VARCHAR(20)
);
*/

-- ============================================
-- QUESTION 21: Calculate monthly sales growth rate
-- ============================================
-- Scenario: Management needs to track month-over-month sales performance

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    ROUND(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
          NULLIF(LAG(total_sales) OVER (ORDER BY month), 0), 2) AS growth_rate_pct
FROM monthly_sales
ORDER BY month;

-- ============================================
-- QUESTION 22: Find top 10 customers by lifetime value
-- ============================================
-- Scenario: Identify VIP customers for loyalty program

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
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.company_name, c.segment
ORDER BY lifetime_value DESC
LIMIT 10;

-- ============================================
-- QUESTION 23: Calculate product sales ranking by category
-- ============================================
-- Scenario: Identify best-selling products within each category

WITH product_sales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
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

-- ============================================
-- QUESTION 24: Find customers with declining purchase frequency
-- ============================================
-- Scenario: Identify at-risk customers for retention campaign

WITH customer_quarters AS (
    SELECT 
        customer_id,
        DATE_TRUNC('quarter', order_date) AS quarter,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id, DATE_TRUNC('quarter', order_date)
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
JOIN customers c ON w.customer_id = c.customer_id
WHERE w.order_count < w.prev_quarter_orders
ORDER BY change;

-- ============================================
-- QUESTION 25: Calculate average days between orders per customer
-- ============================================
-- Scenario: Understand customer purchase patterns

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
JOIN customers c ON og.customer_id = c.customer_id
WHERE og.days_between IS NOT NULL
GROUP BY c.customer_id, c.company_name
HAVING COUNT(*) > 3
ORDER BY avg_days_between_orders;

-- ============================================
-- QUESTION 26: Find products frequently bought together
-- ============================================
-- Scenario: Product bundling recommendations

SELECT 
    oi1.product_id AS product1,
    p1.product_name AS product1_name,
    oi2.product_id AS product2,
    p2.product_name AS product2_name,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
    AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
HAVING COUNT(*) > 10
ORDER BY times_bought_together DESC
LIMIT 20;

-- ============================================
-- QUESTION 27: Calculate sales rep performance metrics
-- ============================================
-- Scenario: Sales team performance review

SELECT 
    e.employee_id AS sales_rep_id,
    e.first_name || ' ' || e.last_name AS sales_rep_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.total_amount) AS total_sales,
    AVG(o.total_amount) AS avg_order_value,
    SUM(o.total_amount) / COUNT(DISTINCT o.customer_id) AS revenue_per_customer
FROM employees e
JOIN orders o ON e.employee_id = o.sales_rep_id
WHERE o.status = 'Completed'
AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_sales DESC;

-- ============================================
-- QUESTION 28: Identify seasonal sales patterns
-- ============================================
-- Scenario: Plan inventory and marketing for seasonal trends

SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    TO_CHAR(order_date, 'Month') AS month_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 2) AS pct_of_annual
FROM orders
WHERE status = 'Completed'
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY month;

-- ============================================
-- QUESTION 29: Calculate customer retention rate
-- ============================================
-- Scenario: Measure customer loyalty over time

WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT 
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date) AS activity_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM first_purchase fp
    JOIN orders o ON fp.customer_id = o.customer_id
    GROUP BY fp.cohort_month, DATE_TRUNC('month', o.order_date)
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

-- ============================================
-- QUESTION 30: Find orders with unusual discount patterns
-- ============================================
-- Scenario: Fraud detection - identify suspicious discounts

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
JOIN customers c ON o.customer_id = c.customer_id
CROSS JOIN discount_stats ds
WHERE o.discount > ds.avg_discount + 2 * ds.stddev_discount
ORDER BY z_score DESC;

-- ============================================
-- QUESTION 31: Calculate running total of sales by region
-- ============================================
-- Scenario: Track regional sales progress toward goals

SELECT 
    c.country,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY c.country ORDER BY o.order_date) AS running_total,
    SUM(o.total_amount) OVER (PARTITION BY c.country) AS region_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY c.country, o.order_date;

-- ============================================
-- QUESTION 32: Find the best day of week for sales
-- ============================================
-- Scenario: Optimize marketing campaign timing

SELECT 
    EXTRACT(DOW FROM order_date) AS day_of_week,
    TO_CHAR(order_date, 'Day') AS day_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'Completed'
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day')
ORDER BY total_sales DESC;

-- ============================================
-- QUESTION 33: Calculate year-over-year growth by product category
-- ============================================
-- Scenario: Strategic planning for product lines

WITH category_yearly AS (
    SELECT 
        p.category_id,
        EXTRACT(YEAR FROM o.order_date) AS year,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category_id, EXTRACT(YEAR FROM o.order_date)
)
SELECT 
    category_id,
    year,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year) AS prev_year_sales,
    ROUND(100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year)) / 
          NULLIF(LAG(total_sales) OVER (PARTITION BY category_id ORDER BY year), 0), 2) AS yoy_growth
FROM category_yearly
ORDER BY category_id, year;

-- ============================================
-- QUESTION 34: Find customers who haven't ordered in 6 months
-- ============================================
-- Scenario: Win-back campaign targeting

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
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.contact_name, c.segment
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '6 months'
ORDER BY lifetime_value DESC;

-- ============================================
-- QUESTION 35: Calculate average order fulfillment time
-- ============================================
-- Scenario: Operations efficiency analysis

SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(*) AS total_orders,
    AVG(ship_date - order_date) AS avg_fulfillment_days,
    MIN(ship_date - order_date) AS min_fulfillment_days,
    MAX(ship_date - order_date) AS max_fulfillment_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ship_date - order_date) AS median_fulfillment_days
FROM orders
WHERE status = 'Completed' AND ship_date IS NOT NULL
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;

-- ============================================
-- QUESTION 36: Identify cross-selling opportunities
-- ============================================
-- Scenario: Find customers who bought product A but not product B

WITH bought_laptops AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_name LIKE '%Laptop%'
),
bought_accessories AS (
    SELECT DISTINCT o.customer_id
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.category_id = 5  -- Accessories category
)
SELECT 
    c.customer_id,
    c.company_name,
    c.contact_name
FROM bought_laptops bl
JOIN customers c ON bl.customer_id = c.customer_id
WHERE bl.customer_id NOT IN (SELECT customer_id FROM bought_accessories);

-- ============================================
-- QUESTION 37: Calculate market basket analysis metrics
-- ============================================
-- Scenario: Analyze product affinity for recommendations

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
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
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
JOIN product_orders po_a ON pp.product_a = po_a.product_id
JOIN product_orders po_b ON pp.product_b = po_b.product_id
WHERE pp.pair_count > 5
ORDER BY pp.pair_count DESC;

-- ============================================
-- QUESTION 38: Find sales anomalies by comparing to moving average
-- ============================================
-- Scenario: Detect unusual sales spikes or drops

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
    ROUND((daily_total - moving_avg_7d) / NULLIF(stddev_7d, 0), 2) AS z_score,
    CASE 
        WHEN daily_total > moving_avg_7d + 2 * stddev_7d THEN 'Spike'
        WHEN daily_total < moving_avg_7d - 2 * stddev_7d THEN 'Drop'
        ELSE 'Normal'
    END AS anomaly_type
FROM with_moving_avg
WHERE ABS((daily_total - moving_avg_7d) / NULLIF(stddev_7d, 0)) > 2
ORDER BY order_date;

-- ============================================
-- QUESTION 39: Calculate customer segment profitability
-- ============================================
-- Scenario: Evaluate which customer segments are most profitable

SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_revenue,
    SUM(o.total_amount - o.discount) AS net_revenue,
    AVG(o.total_amount) AS avg_order_value,
    SUM(o.total_amount) / COUNT(DISTINCT c.customer_id) AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.segment
ORDER BY net_revenue DESC;

-- ============================================
-- QUESTION 40: Generate sales forecast based on trend
-- ============================================
-- Scenario: Simple linear trend projection for next quarter

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', order_date)) AS month_num,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
),
regression AS (
    SELECT 
        AVG(month_num) AS avg_x,
        AVG(total_sales) AS avg_y,
        SUM((month_num - AVG(month_num) OVER ()) * (total_sales - AVG(total_sales) OVER ())) / 
            NULLIF(SUM(POWER(month_num - AVG(month_num) OVER (), 2)), 0) AS slope
    FROM monthly_sales
)
SELECT 
    ms.month,
    ms.total_sales AS actual_sales,
    ROUND(r.avg_y + r.slope * (ms.month_num - r.avg_x), 2) AS trend_value,
    ROUND(r.avg_y + r.slope * (ms.month_num + 3 - r.avg_x), 2) AS forecast_3_months
FROM monthly_sales ms
CROSS JOIN (SELECT AVG(avg_x) AS avg_x, AVG(avg_y) AS avg_y, AVG(slope) AS slope FROM regression) r
ORDER BY ms.month;
