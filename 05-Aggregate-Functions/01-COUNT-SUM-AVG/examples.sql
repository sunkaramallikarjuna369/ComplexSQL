-- ============================================
-- Aggregate Functions Examples
-- COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- COUNT Function
-- ============================================

-- Count all rows
SELECT COUNT(*) AS total_employees FROM employees;

-- Count non-NULL values in a column
SELECT COUNT(commission_pct) AS employees_with_commission FROM employees;

-- Count distinct values
SELECT COUNT(DISTINCT department_id) AS unique_departments FROM employees;

-- Count with condition
SELECT COUNT(*) AS high_earners FROM employees WHERE salary > 100000;

-- ============================================
-- SUM Function
-- ============================================

-- Sum of all salaries
SELECT SUM(salary) AS total_salary_expense FROM employees;

-- Sum with condition
SELECT SUM(salary) AS it_salary_expense 
FROM employees 
WHERE department_id = 60;

-- Sum distinct values (rare but possible)
SELECT SUM(DISTINCT salary) AS sum_unique_salaries FROM employees;

-- ============================================
-- AVG Function
-- ============================================

-- Average salary
SELECT AVG(salary) AS average_salary FROM employees;

-- Average with rounding
SELECT ROUND(AVG(salary), 2) AS average_salary FROM employees;

-- Average ignores NULLs
SELECT AVG(commission_pct) AS avg_commission FROM employees;
-- Only averages non-NULL values!

-- Include NULLs as zero
SELECT AVG(COALESCE(commission_pct, 0)) AS avg_commission_with_nulls FROM employees;

-- ============================================
-- MIN and MAX Functions
-- ============================================

-- Minimum and maximum salary
SELECT 
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employees;

-- Min/Max with dates
SELECT 
    MIN(hire_date) AS first_hire,
    MAX(hire_date) AS latest_hire
FROM employees;

-- Min/Max with strings (alphabetical)
SELECT 
    MIN(last_name) AS first_alphabetically,
    MAX(last_name) AS last_alphabetically
FROM employees;

-- ============================================
-- GROUP BY Clause
-- ============================================

-- Basic GROUP BY
SELECT 
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id;

-- GROUP BY with multiple aggregates
SELECT 
    department_id,
    COUNT(*) AS emp_count,
    SUM(salary) AS total_salary,
    AVG(salary) AS avg_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary
FROM employees
GROUP BY department_id
ORDER BY department_id;

-- GROUP BY multiple columns
SELECT 
    department_id,
    job_id,
    COUNT(*) AS emp_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id, job_id
ORDER BY department_id, job_id;

-- GROUP BY with JOIN
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS emp_count,
    AVG(e.salary) AS avg_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY emp_count DESC;

-- ============================================
-- HAVING Clause
-- ============================================

-- Filter groups with HAVING
SELECT 
    department_id,
    COUNT(*) AS emp_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5;

-- HAVING with multiple conditions
SELECT 
    department_id,
    COUNT(*) AS emp_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 3 AND AVG(salary) > 50000;

-- WHERE vs HAVING
-- WHERE filters rows BEFORE grouping
-- HAVING filters groups AFTER grouping
SELECT 
    department_id,
    COUNT(*) AS emp_count,
    AVG(salary) AS avg_salary
FROM employees
WHERE salary > 30000           -- Filter rows first
GROUP BY department_id
HAVING COUNT(*) > 2;           -- Then filter groups

-- ============================================
-- Conditional Aggregation
-- ============================================

-- Count by condition
SELECT 
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN salary > 100000 THEN 1 END) AS high_earners,
    COUNT(CASE WHEN salary BETWEEN 50000 AND 100000 THEN 1 END) AS mid_earners,
    COUNT(CASE WHEN salary < 50000 THEN 1 END) AS low_earners
FROM employees;

-- Sum by condition
SELECT 
    department_id,
    SUM(salary) AS total_salary,
    SUM(CASE WHEN job_id = 'IT_PROG' THEN salary ELSE 0 END) AS it_salary,
    SUM(CASE WHEN job_id = 'SA_REP' THEN salary ELSE 0 END) AS sales_salary
FROM employees
GROUP BY department_id;

-- Percentage calculation
SELECT 
    department_id,
    COUNT(*) AS total,
    COUNT(CASE WHEN commission_pct IS NOT NULL THEN 1 END) AS with_commission,
    ROUND(100.0 * COUNT(CASE WHEN commission_pct IS NOT NULL THEN 1 END) / COUNT(*), 2) AS pct_with_commission
FROM employees
GROUP BY department_id;

-- ============================================
-- Advanced Aggregation
-- ============================================

-- Running total (using window function)
SELECT 
    employee_id,
    first_name,
    salary,
    SUM(salary) OVER (ORDER BY employee_id) AS running_total
FROM employees;

-- Percentage of total
SELECT 
    department_id,
    SUM(salary) AS dept_salary,
    ROUND(100.0 * SUM(salary) / (SELECT SUM(salary) FROM employees), 2) AS pct_of_total
FROM employees
GROUP BY department_id
ORDER BY pct_of_total DESC;

-- ============================================
-- RDBMS-Specific Aggregates
-- ============================================

-- SQL Server: STRING_AGG
SELECT 
    department_id,
    STRING_AGG(first_name, ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- Oracle: LISTAGG
SELECT 
    department_id,
    LISTAGG(first_name, ', ') WITHIN GROUP (ORDER BY first_name) AS employee_names
FROM employees
GROUP BY department_id;

-- PostgreSQL: STRING_AGG
SELECT 
    department_id,
    STRING_AGG(first_name, ', ' ORDER BY first_name) AS employee_names
FROM employees
GROUP BY department_id;

-- MySQL: GROUP_CONCAT
SELECT 
    department_id,
    GROUP_CONCAT(first_name ORDER BY first_name SEPARATOR ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- ============================================
-- Statistical Aggregates
-- ============================================

-- Standard deviation and variance
-- SQL Server
SELECT 
    department_id,
    AVG(salary) AS avg_salary,
    STDEV(salary) AS std_dev,
    VAR(salary) AS variance
FROM employees
GROUP BY department_id;

-- PostgreSQL
SELECT 
    department_id,
    AVG(salary) AS avg_salary,
    STDDEV(salary) AS std_dev,
    VARIANCE(salary) AS variance
FROM employees
GROUP BY department_id;

-- ============================================
-- Practical Examples
-- ============================================

-- Monthly sales report
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY year, month;

-- Top 5 customers by total spending
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 5;

-- Product performance summary
SELECT 
    p.product_name,
    COUNT(oi.order_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    AVG(oi.quantity) AS avg_quantity_per_order
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(oi.order_id) > 0
ORDER BY total_revenue DESC;
