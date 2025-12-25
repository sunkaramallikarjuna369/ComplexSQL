-- ============================================
-- Filtering Data Examples
-- IN, BETWEEN, LIKE, IS NULL, Pattern Matching
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- IN Operator
-- ============================================

-- Basic IN with numbers
SELECT * FROM employees 
WHERE department_id IN (10, 20, 30);

-- IN with strings
SELECT * FROM employees 
WHERE job_id IN ('IT_PROG', 'SA_REP', 'FI_ACCOUNT', 'ST_CLERK');

-- NOT IN
SELECT * FROM employees 
WHERE department_id NOT IN (10, 20);

-- IN with subquery
SELECT * FROM employees 
WHERE department_id IN (
    SELECT department_id 
    FROM departments 
    WHERE location_id = 1700
);

-- NOT IN with subquery
SELECT * FROM employees 
WHERE department_id NOT IN (
    SELECT department_id 
    FROM departments 
    WHERE manager_id IS NULL
);

-- WARNING: NOT IN with NULL values
-- This returns no rows if subquery contains NULL!
SELECT * FROM employees 
WHERE manager_id NOT IN (
    SELECT manager_id FROM employees  -- Contains NULLs!
);

-- Safe NOT IN (exclude NULLs)
SELECT * FROM employees 
WHERE manager_id NOT IN (
    SELECT manager_id FROM employees WHERE manager_id IS NOT NULL
);

-- Better alternative: NOT EXISTS
SELECT * FROM employees e1
WHERE NOT EXISTS (
    SELECT 1 FROM employees e2 
    WHERE e2.manager_id = e1.employee_id
);

-- ============================================
-- BETWEEN Operator
-- ============================================

-- Numeric BETWEEN (inclusive)
SELECT * FROM employees 
WHERE salary BETWEEN 50000 AND 100000;

-- Equivalent to
SELECT * FROM employees 
WHERE salary >= 50000 AND salary <= 100000;

-- NOT BETWEEN
SELECT * FROM employees 
WHERE salary NOT BETWEEN 50000 AND 100000;

-- Date BETWEEN
SELECT * FROM orders 
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- SQL Server: Date BETWEEN with time consideration
SELECT * FROM orders 
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31 23:59:59.997';

-- Better for dates: Use >= and <
SELECT * FROM orders 
WHERE order_date >= '2024-01-01' 
AND order_date < '2025-01-01';

-- Text BETWEEN (alphabetical range)
SELECT * FROM employees 
WHERE last_name BETWEEN 'A' AND 'M';

-- BETWEEN with expressions
SELECT * FROM employees 
WHERE salary * 12 BETWEEN 600000 AND 1200000;

-- ============================================
-- LIKE Operator - Pattern Matching
-- ============================================

-- % wildcard: any sequence of characters

-- Starts with 'J'
SELECT * FROM employees WHERE first_name LIKE 'J%';

-- Ends with 'son'
SELECT * FROM employees WHERE last_name LIKE '%son';

-- Contains 'an'
SELECT * FROM employees WHERE first_name LIKE '%an%';

-- _ wildcard: exactly one character

-- Second character is 'o'
SELECT * FROM employees WHERE first_name LIKE '_o%';

-- Exactly 4 characters
SELECT * FROM employees WHERE first_name LIKE '____';

-- Phone pattern: 555-XXX-XXXX
SELECT * FROM employees WHERE phone LIKE '555-___-____';

-- Combining wildcards
SELECT * FROM employees WHERE email LIKE 'j%@%.com';
SELECT * FROM employees WHERE last_name LIKE '_a%son';

-- NOT LIKE
SELECT * FROM employees WHERE email NOT LIKE '%@test.com';

-- Multiple LIKE conditions
SELECT * FROM employees 
WHERE first_name LIKE 'J%' 
OR first_name LIKE 'M%' 
OR first_name LIKE 'S%';

-- ============================================
-- Case-Insensitive Pattern Matching
-- ============================================

-- PostgreSQL: ILIKE (case-insensitive)
SELECT * FROM employees WHERE first_name ILIKE 'john%';
SELECT * FROM employees WHERE last_name ILIKE '%SMITH%';

-- All RDBMS: Using LOWER/UPPER
SELECT * FROM employees WHERE LOWER(first_name) LIKE 'john%';
SELECT * FROM employees WHERE UPPER(last_name) LIKE '%SMITH%';

-- SQL Server: COLLATE for case-insensitive
SELECT * FROM employees 
WHERE first_name LIKE 'john%' COLLATE Latin1_General_CI_AS;

-- ============================================
-- Escaping Special Characters in LIKE
-- ============================================

-- Find literal % character
SELECT * FROM products WHERE discount LIKE '%10\%%' ESCAPE '\';

-- Find literal _ character
SELECT * FROM codes WHERE code LIKE '%\_ABC%' ESCAPE '\';

-- Custom escape character
SELECT * FROM products WHERE name LIKE '%50#%%' ESCAPE '#';

-- SQL Server: Using square brackets
SELECT * FROM products WHERE discount LIKE '%10[%]%';
SELECT * FROM codes WHERE code LIKE '%[_]ABC%';

-- ============================================
-- Regular Expression Matching
-- ============================================

-- PostgreSQL: ~ operator (case-sensitive)
SELECT * FROM employees WHERE first_name ~ '^J.*n$';

-- PostgreSQL: ~* operator (case-insensitive)
SELECT * FROM employees WHERE first_name ~* '^j.*n$';

-- PostgreSQL: SIMILAR TO
SELECT * FROM employees WHERE first_name SIMILAR TO 'J(oh|a)n';

-- Oracle: REGEXP_LIKE
SELECT * FROM employees WHERE REGEXP_LIKE(first_name, '^J.*n$');
SELECT * FROM employees WHERE REGEXP_LIKE(first_name, '^j.*n$', 'i');  -- case-insensitive

-- MySQL: REGEXP
SELECT * FROM employees WHERE first_name REGEXP '^J.*n$';
SELECT * FROM employees WHERE first_name REGEXP '^[Jj].*n$';

-- SQL Server: Limited regex with LIKE
-- Use PATINDEX for more complex patterns
SELECT * FROM employees WHERE PATINDEX('%[0-9]%', phone) > 0;

-- ============================================
-- IS NULL / IS NOT NULL
-- ============================================

-- Find NULL values
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE commission_pct IS NULL;

-- Find non-NULL values
SELECT * FROM employees WHERE manager_id IS NOT NULL;
SELECT * FROM employees WHERE commission_pct IS NOT NULL;

-- Combine with other conditions
SELECT * FROM employees 
WHERE department_id = 80 
AND commission_pct IS NOT NULL;

-- Multiple NULL checks
SELECT * FROM employees 
WHERE manager_id IS NULL 
OR commission_pct IS NULL;

-- ============================================
-- COALESCE and NULL Functions
-- ============================================

-- COALESCE: Return first non-NULL value
SELECT 
    first_name,
    COALESCE(commission_pct, 0) AS commission,
    COALESCE(phone, email, 'No contact') AS contact_info
FROM employees;

-- SQL Server: ISNULL
SELECT first_name, ISNULL(commission_pct, 0) AS commission FROM employees;

-- Oracle: NVL
SELECT first_name, NVL(commission_pct, 0) AS commission FROM employees;

-- Oracle: NVL2 (if not null, then X, else Y)
SELECT first_name, NVL2(commission_pct, 'Has Commission', 'No Commission') FROM employees;

-- MySQL: IFNULL
SELECT first_name, IFNULL(commission_pct, 0) AS commission FROM employees;

-- NULLIF: Return NULL if values are equal
SELECT NULLIF(department_id, 0) FROM employees;  -- Returns NULL if dept_id is 0

-- ============================================
-- Combining Multiple Filters
-- ============================================

-- Complex filter with multiple operators
SELECT * FROM employees 
WHERE department_id IN (10, 20, 30)
AND salary BETWEEN 50000 AND 100000
AND last_name LIKE 'S%'
AND commission_pct IS NOT NULL;

-- Search across multiple columns
SELECT * FROM employees 
WHERE first_name LIKE '%john%' 
OR last_name LIKE '%john%' 
OR email LIKE '%john%';

-- Filter with date range and status
SELECT * FROM orders 
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
AND status IN ('completed', 'shipped')
AND total_amount > 100;

-- ============================================
-- Performance Considerations
-- ============================================

-- Avoid functions on indexed columns (prevents index use)
-- BAD:
SELECT * FROM employees WHERE YEAR(hire_date) = 2024;

-- GOOD:
SELECT * FROM employees 
WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01';

-- BAD:
SELECT * FROM employees WHERE UPPER(last_name) = 'SMITH';

-- GOOD (if you have a functional index):
-- CREATE INDEX idx_last_name_upper ON employees(UPPER(last_name));
SELECT * FROM employees WHERE UPPER(last_name) = 'SMITH';

-- Leading wildcard prevents index use
-- BAD (full table scan):
SELECT * FROM employees WHERE last_name LIKE '%son';

-- GOOD (can use index):
SELECT * FROM employees WHERE last_name LIKE 'John%';
