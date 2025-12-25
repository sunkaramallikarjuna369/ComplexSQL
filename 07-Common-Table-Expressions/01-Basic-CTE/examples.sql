-- ============================================
-- Common Table Expressions (CTE) Examples
-- Basic CTE and Recursive CTE
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic CTE Syntax
-- ============================================

-- Simple CTE
WITH employee_summary AS (
    SELECT 
        department_id,
        COUNT(*) AS emp_count,
        AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT * FROM employee_summary;

-- CTE with main query filter
WITH high_earners AS (
    SELECT employee_id, first_name, salary, department_id
    FROM employees
    WHERE salary > 80000
)
SELECT h.*, d.department_name
FROM high_earners h
JOIN departments d ON h.department_id = d.department_id;

-- ============================================
-- Multiple CTEs
-- ============================================

WITH 
dept_stats AS (
    SELECT 
        department_id,
        COUNT(*) AS emp_count,
        AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
),
high_performing_depts AS (
    SELECT department_id, emp_count, avg_salary
    FROM dept_stats
    WHERE avg_salary > 60000
)
SELECT 
    d.department_name,
    hp.emp_count,
    hp.avg_salary
FROM high_performing_depts hp
JOIN departments d ON hp.department_id = d.department_id;

-- CTEs referencing each other
WITH 
base_data AS (
    SELECT employee_id, first_name, salary, department_id
    FROM employees
),
with_dept AS (
    SELECT 
        b.*,
        d.department_name
    FROM base_data b
    JOIN departments d ON b.department_id = d.department_id
),
final_result AS (
    SELECT 
        department_name,
        COUNT(*) AS emp_count,
        SUM(salary) AS total_salary
    FROM with_dept
    GROUP BY department_name
)
SELECT * FROM final_result ORDER BY total_salary DESC;

-- ============================================
-- CTE vs Subquery Comparison
-- ============================================

-- Using subquery (harder to read)
SELECT 
    e.first_name,
    e.salary,
    dept_avg.avg_salary
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) dept_avg ON e.department_id = dept_avg.department_id
WHERE e.salary > dept_avg.avg_salary;

-- Using CTE (cleaner)
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT 
    e.first_name,
    e.salary,
    da.avg_salary
FROM employees e
JOIN dept_avg da ON e.department_id = da.department_id
WHERE e.salary > da.avg_salary;

-- ============================================
-- CTE with INSERT, UPDATE, DELETE
-- ============================================

-- CTE with INSERT
WITH new_employees AS (
    SELECT 
        first_name,
        last_name,
        salary * 1.1 AS adjusted_salary,
        department_id
    FROM temp_employees
    WHERE hire_date > '2024-01-01'
)
INSERT INTO employees (first_name, last_name, salary, department_id)
SELECT first_name, last_name, adjusted_salary, department_id
FROM new_employees;

-- CTE with UPDATE (SQL Server)
WITH low_performers AS (
    SELECT employee_id
    FROM employees
    WHERE salary < 30000
)
UPDATE employees
SET salary = salary * 1.05
WHERE employee_id IN (SELECT employee_id FROM low_performers);

-- CTE with DELETE
WITH inactive_customers AS (
    SELECT customer_id
    FROM customers c
    WHERE NOT EXISTS (
        SELECT 1 FROM orders o 
        WHERE o.customer_id = c.customer_id
        AND o.order_date > CURRENT_DATE - INTERVAL '2 years'
    )
)
DELETE FROM customers
WHERE customer_id IN (SELECT customer_id FROM inactive_customers);

-- ============================================
-- Practical CTE Examples
-- ============================================

-- Year-over-year comparison
WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(total_amount) AS total_sales
    FROM orders
    GROUP BY EXTRACT(YEAR FROM order_date)
)
SELECT 
    curr.year,
    curr.total_sales,
    prev.total_sales AS prev_year_sales,
    curr.total_sales - COALESCE(prev.total_sales, 0) AS yoy_change,
    ROUND(100.0 * (curr.total_sales - COALESCE(prev.total_sales, 0)) / NULLIF(prev.total_sales, 0), 2) AS yoy_pct
FROM yearly_sales curr
LEFT JOIN yearly_sales prev ON curr.year = prev.year + 1
ORDER BY curr.year;

-- Running totals with CTE
WITH daily_sales AS (
    SELECT 
        order_date,
        SUM(total_amount) AS daily_total
    FROM orders
    GROUP BY order_date
)
SELECT 
    order_date,
    daily_total,
    SUM(daily_total) OVER (ORDER BY order_date) AS running_total
FROM daily_sales
ORDER BY order_date;

-- Top N per group
WITH ranked_employees AS (
    SELECT 
        employee_id,
        first_name,
        department_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
    FROM employees
)
SELECT *
FROM ranked_employees
WHERE rank <= 3
ORDER BY department_id, rank;
