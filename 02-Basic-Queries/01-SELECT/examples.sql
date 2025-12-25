-- ============================================
-- SELECT Statement Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Sample Data Setup
-- ============================================

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    hire_date DATE,
    job_id VARCHAR(20),
    salary DECIMAL(10,2),
    commission_pct DECIMAL(4,2),
    manager_id INT,
    department_id INT
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    manager_id INT,
    location_id INT
);

-- ============================================
-- Basic SELECT
-- ============================================

-- Select all columns
SELECT * FROM employees;

-- Select specific columns
SELECT first_name, last_name, salary FROM employees;

-- Select with column order
SELECT last_name, first_name, email FROM employees;

-- ============================================
-- Column Aliases
-- ============================================

-- Using AS keyword
SELECT 
    first_name AS "First Name",
    last_name AS "Last Name",
    salary AS "Annual Salary"
FROM employees;

-- Without AS keyword
SELECT 
    first_name "First Name",
    last_name "Last Name",
    salary "Annual Salary"
FROM employees;

-- Single word alias without quotes
SELECT 
    first_name AS FirstName,
    last_name AS LastName,
    salary AS Salary
FROM employees;

-- ============================================
-- Expressions and Calculations
-- ============================================

-- Arithmetic operations
SELECT 
    first_name,
    last_name,
    salary,
    salary * 12 AS annual_salary,
    salary * 12 * 1.1 AS annual_with_bonus
FROM employees;

-- Percentage calculation
SELECT 
    first_name,
    salary,
    salary * 0.10 AS tax,
    salary - (salary * 0.10) AS net_salary
FROM employees;

-- Using parentheses for order of operations
SELECT 
    first_name,
    salary,
    (salary + 1000) * 12 AS adjusted_annual
FROM employees;

-- ============================================
-- String Concatenation
-- ============================================

-- SQL Server: Using +
SELECT first_name + ' ' + last_name AS full_name FROM employees;

-- Oracle: Using ||
SELECT first_name || ' ' || last_name AS full_name FROM employees;

-- PostgreSQL: Using ||
SELECT first_name || ' ' || last_name AS full_name FROM employees;

-- MySQL: Using CONCAT()
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM employees;

-- All RDBMS: Using CONCAT() (standard)
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM employees;

-- Building formatted output
-- SQL Server
SELECT 
    first_name + ' ' + last_name + ' earns $' + CAST(salary AS VARCHAR) AS employee_info
FROM employees;

-- Oracle
SELECT 
    first_name || ' ' || last_name || ' earns $' || TO_CHAR(salary) AS employee_info
FROM employees;

-- PostgreSQL
SELECT 
    first_name || ' ' || last_name || ' earns $' || salary::TEXT AS employee_info
FROM employees;

-- MySQL
SELECT 
    CONCAT(first_name, ' ', last_name, ' earns $', salary) AS employee_info
FROM employees;

-- ============================================
-- DISTINCT - Unique Values
-- ============================================

-- Single column distinct
SELECT DISTINCT department_id FROM employees;

-- Multiple columns distinct
SELECT DISTINCT department_id, job_id FROM employees;

-- Count distinct values
SELECT COUNT(DISTINCT department_id) AS unique_departments FROM employees;

-- ============================================
-- NULL Handling in SELECT
-- ============================================

-- Columns with NULL
SELECT 
    first_name,
    commission_pct
FROM employees;

-- COALESCE - Replace NULL with default
SELECT 
    first_name,
    COALESCE(commission_pct, 0) AS commission
FROM employees;

-- SQL Server: ISNULL
SELECT 
    first_name,
    ISNULL(commission_pct, 0) AS commission
FROM employees;

-- Oracle: NVL
SELECT 
    first_name,
    NVL(commission_pct, 0) AS commission
FROM employees;

-- MySQL: IFNULL
SELECT 
    first_name,
    IFNULL(commission_pct, 0) AS commission
FROM employees;

-- Calculate with NULL handling
SELECT 
    first_name,
    salary,
    commission_pct,
    salary + (salary * COALESCE(commission_pct, 0)) AS total_compensation
FROM employees;

-- ============================================
-- CASE Expression
-- ============================================

-- Simple CASE
SELECT 
    first_name,
    department_id,
    CASE department_id
        WHEN 10 THEN 'Administration'
        WHEN 20 THEN 'Marketing'
        WHEN 30 THEN 'Purchasing'
        WHEN 40 THEN 'Human Resources'
        WHEN 50 THEN 'Shipping'
        WHEN 60 THEN 'IT'
        ELSE 'Other'
    END AS department_name
FROM employees;

-- Searched CASE
SELECT 
    first_name,
    salary,
    CASE
        WHEN salary >= 15000 THEN 'Executive'
        WHEN salary >= 10000 THEN 'Senior'
        WHEN salary >= 5000 THEN 'Mid-Level'
        ELSE 'Junior'
    END AS salary_grade
FROM employees;

-- CASE with multiple conditions
SELECT 
    first_name,
    salary,
    department_id,
    CASE
        WHEN department_id = 60 AND salary >= 10000 THEN 'Senior IT'
        WHEN department_id = 60 THEN 'IT Staff'
        WHEN salary >= 15000 THEN 'Executive'
        ELSE 'Staff'
    END AS classification
FROM employees;

-- ============================================
-- Table Aliases
-- ============================================

-- Short alias for table
SELECT 
    e.first_name,
    e.last_name,
    e.salary
FROM employees e;

-- Multiple table aliases
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- Literal Values
-- ============================================

-- Adding literal text
SELECT 
    first_name,
    'works in department' AS text,
    department_id
FROM employees;

-- Adding literal numbers
SELECT 
    first_name,
    salary,
    100 AS bonus_percentage
FROM employees;

-- ============================================
-- SELECT without FROM (Dual table)
-- ============================================

-- SQL Server
SELECT 1 + 1 AS result;
SELECT GETDATE() AS current_date;
SELECT 'Hello World' AS greeting;

-- Oracle (requires DUAL)
SELECT 1 + 1 AS result FROM dual;
SELECT SYSDATE AS current_date FROM dual;
SELECT 'Hello World' AS greeting FROM dual;

-- PostgreSQL
SELECT 1 + 1 AS result;
SELECT CURRENT_DATE AS current_date;
SELECT 'Hello World' AS greeting;

-- MySQL
SELECT 1 + 1 AS result;
SELECT NOW() AS current_date;
SELECT 'Hello World' AS greeting;

-- ============================================
-- SELECT INTO (Create table from query)
-- ============================================

-- SQL Server: SELECT INTO
SELECT employee_id, first_name, last_name, salary
INTO high_earners
FROM employees
WHERE salary > 10000;

-- Oracle/PostgreSQL/MySQL: CREATE TABLE AS
CREATE TABLE high_earners AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE salary > 10000;

-- ============================================
-- Subquery in SELECT
-- ============================================

-- Scalar subquery
SELECT 
    first_name,
    salary,
    (SELECT AVG(salary) FROM employees) AS avg_salary,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;

-- Correlated subquery
SELECT 
    e.first_name,
    e.salary,
    e.department_id,
    (SELECT AVG(e2.salary) 
     FROM employees e2 
     WHERE e2.department_id = e.department_id) AS dept_avg_salary
FROM employees e;
