-- ============================================
-- WHERE Clause Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Comparison Operators
-- ============================================

-- Equal to
SELECT * FROM employees WHERE department_id = 10;
SELECT * FROM employees WHERE first_name = 'John';

-- Not equal to
SELECT * FROM employees WHERE department_id <> 10;
SELECT * FROM employees WHERE department_id != 10;  -- Also valid

-- Greater than
SELECT * FROM employees WHERE salary > 50000;

-- Less than
SELECT * FROM employees WHERE salary < 30000;

-- Greater than or equal
SELECT * FROM employees WHERE salary >= 50000;

-- Less than or equal
SELECT * FROM employees WHERE salary <= 30000;

-- ============================================
-- Logical Operators
-- ============================================

-- AND: Both conditions must be true
SELECT * FROM employees 
WHERE department_id = 10 
AND salary > 50000;

-- OR: Either condition can be true
SELECT * FROM employees 
WHERE department_id = 10 
OR department_id = 20;

-- NOT: Negates the condition
SELECT * FROM employees 
WHERE NOT department_id = 10;

-- Combining AND and OR (use parentheses!)
SELECT * FROM employees 
WHERE (department_id = 10 OR department_id = 20)
AND salary > 50000;

-- Complex conditions
SELECT * FROM employees 
WHERE (department_id = 10 AND salary > 60000)
OR (department_id = 20 AND salary > 50000)
OR (department_id = 30 AND salary > 40000);

-- ============================================
-- IN Operator
-- ============================================

-- IN with list of values
SELECT * FROM employees 
WHERE department_id IN (10, 20, 30);

-- Equivalent to multiple OR
SELECT * FROM employees 
WHERE department_id = 10 
OR department_id = 20 
OR department_id = 30;

-- NOT IN
SELECT * FROM employees 
WHERE department_id NOT IN (10, 20);

-- IN with strings
SELECT * FROM employees 
WHERE job_id IN ('IT_PROG', 'SA_REP', 'FI_ACCOUNT');

-- IN with subquery
SELECT * FROM employees 
WHERE department_id IN (
    SELECT department_id 
    FROM departments 
    WHERE location_id = 1700
);

-- ============================================
-- BETWEEN Operator
-- ============================================

-- Numeric range (inclusive)
SELECT * FROM employees 
WHERE salary BETWEEN 50000 AND 100000;

-- Equivalent to >= AND <=
SELECT * FROM employees 
WHERE salary >= 50000 AND salary <= 100000;

-- NOT BETWEEN
SELECT * FROM employees 
WHERE salary NOT BETWEEN 50000 AND 100000;

-- Date range
SELECT * FROM employees 
WHERE hire_date BETWEEN '2020-01-01' AND '2020-12-31';

-- Text range (alphabetical)
SELECT * FROM employees 
WHERE last_name BETWEEN 'A' AND 'M';

-- ============================================
-- LIKE Operator (Pattern Matching)
-- ============================================

-- Starts with
SELECT * FROM employees WHERE first_name LIKE 'J%';

-- Ends with
SELECT * FROM employees WHERE last_name LIKE '%son';

-- Contains
SELECT * FROM employees WHERE email LIKE '%@gmail%';

-- Single character wildcard
SELECT * FROM employees WHERE first_name LIKE 'J_hn';  -- John, Jahn, etc.

-- Multiple single character wildcards
SELECT * FROM employees WHERE phone LIKE '555-___-____';

-- Combine wildcards
SELECT * FROM employees WHERE email LIKE 'j%@%.com';

-- NOT LIKE
SELECT * FROM employees WHERE email NOT LIKE '%@test.com';

-- Case-insensitive search
-- PostgreSQL: ILIKE
SELECT * FROM employees WHERE first_name ILIKE 'john%';

-- Other RDBMS: Use LOWER/UPPER
SELECT * FROM employees WHERE LOWER(first_name) LIKE 'john%';
SELECT * FROM employees WHERE UPPER(first_name) LIKE 'JOHN%';

-- Escape special characters
SELECT * FROM products WHERE name LIKE '%10\%%' ESCAPE '\';
SELECT * FROM products WHERE description LIKE '%50#%%' ESCAPE '#';

-- ============================================
-- IS NULL / IS NOT NULL
-- ============================================

-- Find NULL values
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE commission_pct IS NULL;

-- Find non-NULL values
SELECT * FROM employees WHERE commission_pct IS NOT NULL;

-- WRONG: This won't work!
SELECT * FROM employees WHERE manager_id = NULL;  -- Always returns empty!
SELECT * FROM employees WHERE manager_id <> NULL; -- Always returns empty!

-- Combine with other conditions
SELECT * FROM employees 
WHERE department_id = 10 
AND commission_pct IS NOT NULL;

-- ============================================
-- Date Comparisons
-- ============================================

-- Specific date
SELECT * FROM employees WHERE hire_date = '2020-01-15';

-- Date range
SELECT * FROM employees 
WHERE hire_date >= '2020-01-01' 
AND hire_date < '2021-01-01';

-- Using BETWEEN for dates
SELECT * FROM employees 
WHERE hire_date BETWEEN '2020-01-01' AND '2020-12-31';

-- SQL Server: Date functions in WHERE
SELECT * FROM employees WHERE YEAR(hire_date) = 2020;
SELECT * FROM employees WHERE MONTH(hire_date) = 6;

-- Oracle: Date functions
SELECT * FROM employees WHERE EXTRACT(YEAR FROM hire_date) = 2020;
SELECT * FROM employees WHERE TO_CHAR(hire_date, 'YYYY') = '2020';

-- PostgreSQL: Date functions
SELECT * FROM employees WHERE EXTRACT(YEAR FROM hire_date) = 2020;
SELECT * FROM employees WHERE DATE_PART('year', hire_date) = 2020;

-- MySQL: Date functions
SELECT * FROM employees WHERE YEAR(hire_date) = 2020;
SELECT * FROM employees WHERE DATE_FORMAT(hire_date, '%Y') = '2020';

-- ============================================
-- EXISTS / NOT EXISTS
-- ============================================

-- EXISTS: Check if subquery returns any rows
SELECT * FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e 
    WHERE e.department_id = d.department_id
);

-- NOT EXISTS: Check if subquery returns no rows
SELECT * FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e 
    WHERE e.department_id = d.department_id
);

-- EXISTS vs IN (EXISTS is often faster for large datasets)
-- Using IN
SELECT * FROM employees 
WHERE department_id IN (
    SELECT department_id FROM departments WHERE location_id = 1700
);

-- Using EXISTS (equivalent)
SELECT * FROM employees e
WHERE EXISTS (
    SELECT 1 FROM departments d 
    WHERE d.department_id = e.department_id 
    AND d.location_id = 1700
);

-- ============================================
-- ANY / ALL / SOME
-- ============================================

-- ANY: Compare to any value in list
SELECT * FROM employees 
WHERE salary > ANY (
    SELECT salary FROM employees WHERE department_id = 60
);

-- ALL: Compare to all values in list
SELECT * FROM employees 
WHERE salary > ALL (
    SELECT salary FROM employees WHERE department_id = 60
);

-- SOME is equivalent to ANY
SELECT * FROM employees 
WHERE salary > SOME (
    SELECT salary FROM employees WHERE department_id = 60
);

-- ============================================
-- Complex WHERE Examples
-- ============================================

-- Multiple conditions with proper grouping
SELECT * FROM employees 
WHERE (
    (department_id = 10 AND salary > 60000)
    OR (department_id = 20 AND salary > 50000)
)
AND hire_date >= '2019-01-01'
AND commission_pct IS NOT NULL;

-- Search across multiple columns
SELECT * FROM employees 
WHERE first_name LIKE '%john%' 
OR last_name LIKE '%john%' 
OR email LIKE '%john%';

-- Dynamic-like filtering
SELECT * FROM employees 
WHERE (10 IS NULL OR department_id = 10)
AND (50000 IS NULL OR salary >= 50000);
