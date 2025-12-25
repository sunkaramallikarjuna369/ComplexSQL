-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: EMPLOYEE MANAGEMENT (Q1-Q20)
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
-- Q1: FIND EMPLOYEES HIRED IN THE LAST 90 DAYS
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Date Functions, Filtering, ORDER BY
-- 
-- BUSINESS SCENARIO:
-- The HR department needs to identify all employees hired within the last 90
-- days to schedule them for the mandatory new hire orientation program. The
-- report should show employee details sorted by most recent hire first.
--
-- REQUIREMENTS:
-- - Return employee_id, first_name, last_name, hire_date
-- - Filter for employees hired within the last 90 days from today
-- - Sort by hire_date descending (most recent first)
-- - Handle edge case: employees hired exactly 90 days ago should be included
--
-- EXPECTED OUTPUT (based on sample data, assuming today is 2025-12-25):
-- +-------------+------------+-----------+------------+
-- | employee_id | first_name | last_name | hire_date  |
-- +-------------+------------+-----------+------------+
-- | 307         | Christopher| Olsen     | 2025-11-15 |
-- | 207         | Sarah      | Bell      | 2025-10-01 |
-- +-------------+------------+-----------+------------+
-- ============================================================================

-- SQL Server Solution:
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date
FROM employees
WHERE hire_date >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE))
ORDER BY hire_date DESC;

-- Oracle Solution:
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date
FROM employees
WHERE hire_date >= TRUNC(SYSDATE) - 90
ORDER BY hire_date DESC;

-- PostgreSQL Solution:
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date
FROM employees
WHERE hire_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY hire_date DESC;

-- MySQL Solution:
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date
FROM employees
WHERE hire_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
ORDER BY hire_date DESC;

-- EXPLANATION:
-- Each RDBMS has different functions to get the current date and perform
-- date arithmetic:
--   SQL Server: GETDATE() returns datetime, CAST to DATE for date-only comparison
--               DATEADD(interval, number, date) adds/subtracts from a date
--   Oracle:     SYSDATE returns current date/time, TRUNC removes time portion
--               Simple arithmetic (SYSDATE - 90) subtracts days
--   PostgreSQL: CURRENT_DATE returns date, INTERVAL for date arithmetic
--   MySQL:      CURDATE() returns current date, DATE_SUB for subtraction
--
-- EDGE CASES:
-- - If no employees were hired in the last 90 days, returns empty result set
-- - Time portion is ignored (hire_date is DATE type)
--
-- COMMON MISTAKES:
-- - Using > instead of >= (excludes employees hired exactly 90 days ago)
-- - Not handling time portion in datetime columns
-- - Forgetting ORDER BY for consistent results

-- ============================================
-- QUESTION 2: Calculate years of service for each employee
-- ============================================
-- Scenario: Generate service anniversary report

-- SQL Server
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date,
    DATEDIFF(YEAR, hire_date, GETDATE()) AS years_of_service
FROM employees
ORDER BY years_of_service DESC;

-- Oracle
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date,
    TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date) / 12) AS years_of_service
FROM employees
ORDER BY years_of_service DESC;

-- PostgreSQL
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_of_service
FROM employees
ORDER BY years_of_service DESC;

-- MySQL
SELECT 
    employee_id,
    first_name,
    last_name,
    hire_date,
    TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS years_of_service
FROM employees
ORDER BY years_of_service DESC;

-- ============================================
-- QUESTION 3: Find employees earning above department average
-- ============================================
-- Scenario: Identify high performers for bonus consideration

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.salary,
    e.department_id,
    dept_avg.avg_salary,
    e.salary - dept_avg.avg_salary AS above_avg
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) dept_avg ON e.department_id = dept_avg.department_id
WHERE e.salary > dept_avg.avg_salary
ORDER BY above_avg DESC;

-- Alternative using window function
SELECT 
    employee_id,
    first_name,
    last_name,
    salary,
    department_id,
    avg_salary,
    salary - avg_salary AS above_avg
FROM (
    SELECT 
        employee_id,
        first_name,
        last_name,
        salary,
        department_id,
        AVG(salary) OVER (PARTITION BY department_id) AS avg_salary
    FROM employees
) t
WHERE salary > avg_salary
ORDER BY above_avg DESC;

-- ============================================
-- QUESTION 4: Find the reporting hierarchy for an employee
-- ============================================
-- Scenario: Display org chart path from employee to CEO

-- SQL Server / PostgreSQL / Oracle
WITH RECURSIVE hierarchy AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        manager_id,
        1 AS level,
        CAST(first_name || ' ' || last_name AS VARCHAR(1000)) AS path
    FROM employees
    WHERE employee_id = 110  -- Starting employee
    
    UNION ALL
    
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        h.level + 1,
        CAST(e.first_name || ' ' || e.last_name || ' -> ' || h.path AS VARCHAR(1000))
    FROM employees e
    JOIN hierarchy h ON e.employee_id = h.manager_id
)
SELECT * FROM hierarchy ORDER BY level DESC;

-- ============================================
-- QUESTION 5: Find employees with same job title in different departments
-- ============================================
-- Scenario: Identify potential internal transfer candidates

SELECT 
    e1.employee_id AS emp1_id,
    e1.first_name AS emp1_name,
    e1.department_id AS emp1_dept,
    e2.employee_id AS emp2_id,
    e2.first_name AS emp2_name,
    e2.department_id AS emp2_dept,
    e1.job_id
FROM employees e1
JOIN employees e2 ON e1.job_id = e2.job_id 
    AND e1.department_id < e2.department_id
ORDER BY e1.job_id, e1.department_id;

-- ============================================
-- QUESTION 6: Calculate salary percentile for each employee
-- ============================================
-- Scenario: Compensation analysis for salary bands

SELECT 
    employee_id,
    first_name,
    last_name,
    salary,
    PERCENT_RANK() OVER (ORDER BY salary) * 100 AS salary_percentile,
    NTILE(4) OVER (ORDER BY salary) AS salary_quartile
FROM employees
ORDER BY salary DESC;

-- ============================================
-- QUESTION 7: Find departments with no employees
-- ============================================
-- Scenario: Identify inactive departments for restructuring

SELECT d.department_id, d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.employee_id IS NULL;

-- Alternative using NOT EXISTS
SELECT department_id, department_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.department_id = d.department_id
);

-- ============================================
-- QUESTION 8: Find employees who changed jobs more than twice
-- ============================================
-- Scenario: Identify employees with diverse experience

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    COUNT(jh.job_id) AS job_changes
FROM employees e
JOIN job_history jh ON e.employee_id = jh.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING COUNT(jh.job_id) > 2
ORDER BY job_changes DESC;

-- ============================================
-- QUESTION 9: Calculate the salary gap between employee and manager
-- ============================================
-- Scenario: Analyze compensation equity

SELECT 
    e.employee_id,
    e.first_name AS employee_name,
    e.salary AS employee_salary,
    m.first_name AS manager_name,
    m.salary AS manager_salary,
    m.salary - e.salary AS salary_gap,
    ROUND(100.0 * e.salary / m.salary, 2) AS pct_of_manager_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
ORDER BY salary_gap DESC;

-- ============================================
-- QUESTION 10: Find the second highest salary in each department
-- ============================================
-- Scenario: Identify backup candidates for leadership roles

WITH ranked AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department_id,
        salary,
        DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
    FROM employees
)
SELECT employee_id, first_name, last_name, department_id, salary
FROM ranked
WHERE rank = 2;

-- ============================================
-- QUESTION 11: Find employees hired on weekends
-- ============================================
-- Scenario: Audit unusual hiring patterns

-- SQL Server
SELECT employee_id, first_name, last_name, hire_date,
       DATENAME(WEEKDAY, hire_date) AS day_name
FROM employees
WHERE DATEPART(WEEKDAY, hire_date) IN (1, 7);

-- PostgreSQL
SELECT employee_id, first_name, last_name, hire_date,
       TO_CHAR(hire_date, 'Day') AS day_name
FROM employees
WHERE EXTRACT(DOW FROM hire_date) IN (0, 6);

-- Oracle
SELECT employee_id, first_name, last_name, hire_date,
       TO_CHAR(hire_date, 'Day') AS day_name
FROM employees
WHERE TO_CHAR(hire_date, 'D') IN ('1', '7');

-- MySQL
SELECT employee_id, first_name, last_name, hire_date,
       DAYNAME(hire_date) AS day_name
FROM employees
WHERE DAYOFWEEK(hire_date) IN (1, 7);

-- ============================================
-- QUESTION 12: Calculate cumulative salary by hire date
-- ============================================
-- Scenario: Track salary expense growth over time

SELECT 
    hire_date,
    first_name,
    last_name,
    salary,
    SUM(salary) OVER (ORDER BY hire_date) AS cumulative_salary
FROM employees
ORDER BY hire_date;

-- ============================================
-- QUESTION 13: Find employees with duplicate email domains
-- ============================================
-- Scenario: Identify potential data quality issues

SELECT 
    SUBSTRING(email FROM POSITION('@' IN email) + 1) AS domain,
    COUNT(*) AS employee_count,
    STRING_AGG(first_name || ' ' || last_name, ', ') AS employees
FROM employees
GROUP BY SUBSTRING(email FROM POSITION('@' IN email) + 1)
HAVING COUNT(*) > 1;

-- SQL Server version
SELECT 
    SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email)) AS domain,
    COUNT(*) AS employee_count,
    STRING_AGG(first_name + ' ' + last_name, ', ') AS employees
FROM employees
GROUP BY SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email))
HAVING COUNT(*) > 1;

-- ============================================
-- QUESTION 14: Find the longest tenure employee in each department
-- ============================================
-- Scenario: Identify department veterans for mentorship program

WITH ranked AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department_id,
        hire_date,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY hire_date) AS rn
    FROM employees
)
SELECT r.*, d.department_name
FROM ranked r
JOIN departments d ON r.department_id = d.department_id
WHERE rn = 1;

-- ============================================
-- QUESTION 15: Calculate month-over-month hiring trend
-- ============================================
-- Scenario: Analyze recruitment patterns

WITH monthly_hires AS (
    SELECT 
        DATE_TRUNC('month', hire_date) AS hire_month,
        COUNT(*) AS hires
    FROM employees
    GROUP BY DATE_TRUNC('month', hire_date)
)
SELECT 
    hire_month,
    hires,
    LAG(hires) OVER (ORDER BY hire_month) AS prev_month_hires,
    hires - LAG(hires) OVER (ORDER BY hire_month) AS change,
    ROUND(100.0 * (hires - LAG(hires) OVER (ORDER BY hire_month)) / 
          NULLIF(LAG(hires) OVER (ORDER BY hire_month), 0), 2) AS pct_change
FROM monthly_hires
ORDER BY hire_month;

-- ============================================
-- QUESTION 16: Find employees whose salary is outside job salary range
-- ============================================
-- Scenario: Compensation compliance audit

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.salary,
    j.job_title,
    j.min_salary,
    j.max_salary,
    CASE 
        WHEN e.salary < j.min_salary THEN 'Below Range'
        WHEN e.salary > j.max_salary THEN 'Above Range'
        ELSE 'Within Range'
    END AS salary_status
FROM employees e
JOIN jobs j ON e.job_id = j.job_id
WHERE e.salary < j.min_salary OR e.salary > j.max_salary;

-- ============================================
-- QUESTION 17: Find managers with more than 5 direct reports
-- ============================================
-- Scenario: Identify managers who may need additional support

SELECT 
    m.employee_id AS manager_id,
    m.first_name AS manager_name,
    COUNT(e.employee_id) AS direct_reports
FROM employees m
JOIN employees e ON m.employee_id = e.manager_id
GROUP BY m.employee_id, m.first_name
HAVING COUNT(e.employee_id) > 5
ORDER BY direct_reports DESC;

-- ============================================
-- QUESTION 18: Calculate average tenure by department
-- ============================================
-- Scenario: Analyze employee retention by department

SELECT 
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date))), 2) AS avg_tenure_years
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY avg_tenure_years DESC;

-- ============================================
-- QUESTION 19: Find employees with no commission who should have one
-- ============================================
-- Scenario: Identify sales employees missing commission setup

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    j.job_title,
    e.commission_pct
FROM employees e
JOIN jobs j ON e.job_id = j.job_id
WHERE j.job_title LIKE '%Sales%'
AND (e.commission_pct IS NULL OR e.commission_pct = 0);

-- ============================================
-- QUESTION 20: Generate employee directory with full details
-- ============================================
-- Scenario: Create comprehensive employee report

SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.email,
    e.phone,
    j.job_title,
    d.department_name,
    m.first_name || ' ' || m.last_name AS manager_name,
    e.hire_date,
    e.salary,
    COALESCE(e.commission_pct, 0) AS commission_pct,
    e.salary * (1 + COALESCE(e.commission_pct, 0)) AS total_compensation
FROM employees e
LEFT JOIN jobs j ON e.job_id = j.job_id
LEFT JOIN departments d ON e.department_id = d.department_id
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY d.department_name, e.last_name;
