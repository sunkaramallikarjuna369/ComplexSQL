-- ============================================
-- Window Functions - Aggregate Window Functions
-- SUM, AVG, COUNT, MIN, MAX with OVER clause
-- SQL Server, Oracle, PostgreSQL, MySQL 8.0+
-- ============================================

-- ============================================
-- Running Totals with SUM OVER
-- ============================================

-- Running total
SELECT 
    order_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY order_date) AS running_total
FROM orders;

-- Running total with PARTITION
SELECT 
    customer_id,
    order_date,
    total_amount,
    SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS customer_running_total
FROM orders;

-- Running total for last 7 days (sliding window)
SELECT 
    order_date,
    total_amount,
    SUM(total_amount) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7_day_total
FROM daily_sales;

-- ============================================
-- Moving Averages with AVG OVER
-- ============================================

-- Simple moving average
SELECT 
    order_date,
    total_amount,
    AVG(total_amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM daily_sales;

-- 7-day moving average
SELECT 
    order_date,
    total_amount,
    ROUND(AVG(total_amount) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7
FROM daily_sales;

-- Centered moving average
SELECT 
    order_date,
    total_amount,
    AVG(total_amount) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    ) AS centered_avg_7
FROM daily_sales;

-- ============================================
-- Running COUNT
-- ============================================

-- Cumulative count
SELECT 
    employee_id,
    hire_date,
    COUNT(*) OVER (ORDER BY hire_date) AS cumulative_hires
FROM employees;

-- Count within partition
SELECT 
    department_id,
    employee_id,
    hire_date,
    COUNT(*) OVER (PARTITION BY department_id ORDER BY hire_date) AS dept_cumulative_hires
FROM employees;

-- ============================================
-- Running MIN/MAX
-- ============================================

-- Running minimum and maximum
SELECT 
    order_date,
    stock_price,
    MIN(stock_price) OVER (ORDER BY order_date) AS running_min,
    MAX(stock_price) OVER (ORDER BY order_date) AS running_max
FROM stock_prices;

-- 52-week high/low
SELECT 
    trade_date,
    closing_price,
    MIN(closing_price) OVER (
        ORDER BY trade_date 
        ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
    ) AS week_52_low,
    MAX(closing_price) OVER (
        ORDER BY trade_date 
        ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
    ) AS week_52_high
FROM stock_prices;

-- ============================================
-- Window Frame Specifications
-- ============================================

-- ROWS vs RANGE
-- ROWS: Physical rows
SELECT 
    order_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rows_sum
FROM orders;

-- RANGE: Logical range (same values treated as group)
SELECT 
    order_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY order_date RANGE BETWEEN INTERVAL '2' DAY PRECEDING AND CURRENT ROW) AS range_sum
FROM orders;

-- Frame boundaries
-- UNBOUNDED PRECEDING: From start
-- n PRECEDING: n rows before
-- CURRENT ROW: Current row
-- n FOLLOWING: n rows after
-- UNBOUNDED FOLLOWING: To end

SELECT 
    employee_id,
    salary,
    SUM(salary) OVER (ORDER BY employee_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    SUM(salary) OVER (ORDER BY employee_id ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS remaining_total,
    SUM(salary) OVER (ORDER BY employee_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS grand_total
FROM employees;

-- ============================================
-- Percentage Calculations
-- ============================================

-- Percentage of total
SELECT 
    department_id,
    employee_id,
    salary,
    SUM(salary) OVER () AS total_salary,
    ROUND(100.0 * salary / SUM(salary) OVER (), 2) AS pct_of_total
FROM employees;

-- Percentage within partition
SELECT 
    department_id,
    employee_id,
    salary,
    SUM(salary) OVER (PARTITION BY department_id) AS dept_total,
    ROUND(100.0 * salary / SUM(salary) OVER (PARTITION BY department_id), 2) AS pct_of_dept
FROM employees;

-- Cumulative percentage
SELECT 
    employee_id,
    salary,
    SUM(salary) OVER (ORDER BY salary DESC) AS cumulative_salary,
    ROUND(100.0 * SUM(salary) OVER (ORDER BY salary DESC) / SUM(salary) OVER (), 2) AS cumulative_pct
FROM employees;

-- ============================================
-- Practical Examples
-- ============================================

-- Sales trend analysis
SELECT 
    order_date,
    daily_sales,
    AVG(daily_sales) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_7_day,
    AVG(daily_sales) OVER (ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS avg_30_day,
    daily_sales - AVG(daily_sales) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS diff_from_avg
FROM daily_sales;

-- Employee salary analysis
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    AVG(salary) OVER (PARTITION BY department_id) AS dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department_id) AS diff_from_dept_avg,
    MIN(salary) OVER (PARTITION BY department_id) AS dept_min,
    MAX(salary) OVER (PARTITION BY department_id) AS dept_max,
    ROUND(100.0 * (salary - MIN(salary) OVER (PARTITION BY department_id)) / 
          NULLIF(MAX(salary) OVER (PARTITION BY department_id) - MIN(salary) OVER (PARTITION BY department_id), 0), 2) AS salary_percentile
FROM employees;

-- Inventory analysis
SELECT 
    product_id,
    transaction_date,
    quantity_change,
    SUM(quantity_change) OVER (PARTITION BY product_id ORDER BY transaction_date) AS current_stock,
    AVG(quantity_change) OVER (PARTITION BY product_id ORDER BY transaction_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS avg_daily_movement
FROM inventory_transactions;
