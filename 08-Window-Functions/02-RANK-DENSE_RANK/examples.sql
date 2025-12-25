-- ============================================
-- Window Functions - LAG, LEAD, FIRST_VALUE, LAST_VALUE
-- SQL Server, Oracle, PostgreSQL, MySQL 8.0+
-- ============================================

-- ============================================
-- LAG Function
-- ============================================

-- Basic LAG (previous row value)
SELECT 
    employee_id,
    first_name,
    salary,
    LAG(salary) OVER (ORDER BY employee_id) AS prev_salary
FROM employees;

-- LAG with offset and default
SELECT 
    employee_id,
    first_name,
    salary,
    LAG(salary, 1, 0) OVER (ORDER BY employee_id) AS prev_salary,
    LAG(salary, 2, 0) OVER (ORDER BY employee_id) AS prev_2_salary
FROM employees;

-- LAG with PARTITION BY
SELECT 
    employee_id,
    first_name,
    department_id,
    hire_date,
    LAG(hire_date) OVER (PARTITION BY department_id ORDER BY hire_date) AS prev_hire_date
FROM employees;

-- Calculate change from previous
SELECT 
    order_date,
    total_sales,
    LAG(total_sales) OVER (ORDER BY order_date) AS prev_day_sales,
    total_sales - LAG(total_sales) OVER (ORDER BY order_date) AS daily_change,
    ROUND(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY order_date)) / 
          NULLIF(LAG(total_sales) OVER (ORDER BY order_date), 0), 2) AS pct_change
FROM daily_sales;

-- ============================================
-- LEAD Function
-- ============================================

-- Basic LEAD (next row value)
SELECT 
    employee_id,
    first_name,
    salary,
    LEAD(salary) OVER (ORDER BY employee_id) AS next_salary
FROM employees;

-- LEAD with offset and default
SELECT 
    employee_id,
    first_name,
    salary,
    LEAD(salary, 1, 0) OVER (ORDER BY employee_id) AS next_salary,
    LEAD(salary, 2, 0) OVER (ORDER BY employee_id) AS next_2_salary
FROM employees;

-- Days until next order
SELECT 
    order_id,
    customer_id,
    order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) - order_date AS days_between
FROM orders;

-- ============================================
-- FIRST_VALUE and LAST_VALUE
-- ============================================

-- FIRST_VALUE
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    FIRST_VALUE(first_name) OVER (PARTITION BY department_id ORDER BY salary DESC) AS highest_paid
FROM employees;

-- LAST_VALUE (requires frame specification)
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    LAST_VALUE(first_name) OVER (
        PARTITION BY department_id 
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_paid
FROM employees;

-- Compare to first and last in group
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) AS max_salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department_id 
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS min_salary,
    salary - FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) AS diff_from_max
FROM employees;

-- ============================================
-- NTH_VALUE
-- ============================================

-- Get 2nd highest salary in department
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    NTH_VALUE(salary, 2) OVER (
        PARTITION BY department_id 
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_highest
FROM employees;

-- ============================================
-- Practical Examples
-- ============================================

-- Month-over-month comparison
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month) AS mom_change,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / 
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS mom_pct
FROM monthly_revenue;

-- Year-over-year comparison
SELECT 
    year,
    month,
    revenue,
    LAG(revenue, 12) OVER (ORDER BY year, month) AS same_month_last_year,
    revenue - LAG(revenue, 12) OVER (ORDER BY year, month) AS yoy_change
FROM monthly_revenue;

-- Identify consecutive increases
WITH sales_with_prev AS (
    SELECT 
        order_date,
        total_sales,
        LAG(total_sales) OVER (ORDER BY order_date) AS prev_sales
    FROM daily_sales
)
SELECT 
    order_date,
    total_sales,
    prev_sales,
    CASE WHEN total_sales > prev_sales THEN 'Increase' ELSE 'Decrease' END AS trend
FROM sales_with_prev;

-- Gap analysis
SELECT 
    employee_id,
    first_name,
    hire_date,
    LAG(hire_date) OVER (ORDER BY hire_date) AS prev_hire,
    hire_date - LAG(hire_date) OVER (ORDER BY hire_date) AS days_gap
FROM employees
ORDER BY hire_date;

-- Running comparison to first value
SELECT 
    order_date,
    total_sales,
    FIRST_VALUE(total_sales) OVER (ORDER BY order_date) AS first_day_sales,
    total_sales - FIRST_VALUE(total_sales) OVER (ORDER BY order_date) AS growth_from_start,
    ROUND(100.0 * total_sales / FIRST_VALUE(total_sales) OVER (ORDER BY order_date), 2) AS pct_of_first
FROM daily_sales;
