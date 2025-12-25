-- ============================================
-- ORDER BY Clause Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic Sorting
-- ============================================

-- Ascending order (default)
SELECT * FROM employees ORDER BY last_name;
SELECT * FROM employees ORDER BY last_name ASC;

-- Descending order
SELECT * FROM employees ORDER BY salary DESC;

-- Sort by multiple columns
SELECT * FROM employees 
ORDER BY department_id ASC, salary DESC;

-- Sort by column position (not recommended)
SELECT first_name, last_name, salary 
FROM employees 
ORDER BY 3 DESC;  -- Sorts by salary (3rd column)

-- ============================================
-- Sorting with Expressions
-- ============================================

-- Sort by calculated column
SELECT 
    first_name, 
    last_name, 
    salary,
    salary * 12 AS annual_salary
FROM employees 
ORDER BY salary * 12 DESC;

-- Sort by alias
SELECT 
    first_name, 
    last_name, 
    salary * 12 AS annual_salary
FROM employees 
ORDER BY annual_salary DESC;

-- Sort by expression with functions
SELECT 
    first_name, 
    last_name,
    LENGTH(last_name) AS name_length
FROM employees 
ORDER BY LENGTH(last_name) DESC;

-- ============================================
-- NULL Handling in ORDER BY
-- ============================================

-- Default NULL behavior varies by RDBMS
SELECT first_name, commission_pct 
FROM employees 
ORDER BY commission_pct;

-- PostgreSQL/Oracle: NULLS FIRST
SELECT first_name, commission_pct 
FROM employees 
ORDER BY commission_pct NULLS FIRST;

-- PostgreSQL/Oracle: NULLS LAST
SELECT first_name, commission_pct 
FROM employees 
ORDER BY commission_pct DESC NULLS LAST;

-- SQL Server/MySQL: Use CASE to control NULL position
-- NULLs first
SELECT first_name, commission_pct 
FROM employees 
ORDER BY 
    CASE WHEN commission_pct IS NULL THEN 0 ELSE 1 END,
    commission_pct;

-- NULLs last
SELECT first_name, commission_pct 
FROM employees 
ORDER BY 
    CASE WHEN commission_pct IS NULL THEN 1 ELSE 0 END,
    commission_pct;

-- Using COALESCE for NULL handling
SELECT first_name, commission_pct 
FROM employees 
ORDER BY COALESCE(commission_pct, 0);

-- ============================================
-- Case-Insensitive Sorting
-- ============================================

-- Using LOWER function
SELECT * FROM employees 
ORDER BY LOWER(last_name);

-- Using UPPER function
SELECT * FROM employees 
ORDER BY UPPER(last_name);

-- SQL Server: Using COLLATE
SELECT * FROM employees 
ORDER BY last_name COLLATE Latin1_General_CI_AS;

-- PostgreSQL: Using COLLATE
SELECT * FROM employees 
ORDER BY last_name COLLATE "en_US.utf8";

-- ============================================
-- Custom Sort Order
-- ============================================

-- Using CASE for custom order
SELECT * FROM employees
ORDER BY 
    CASE job_id
        WHEN 'AD_PRES' THEN 1
        WHEN 'AD_VP' THEN 2
        WHEN 'IT_PROG' THEN 3
        WHEN 'SA_REP' THEN 4
        ELSE 5
    END;

-- Priority-based sorting
SELECT * FROM orders
ORDER BY 
    CASE status
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'normal' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END,
    order_date;

-- Boolean-like sorting (featured items first)
SELECT * FROM products
ORDER BY 
    CASE WHEN is_featured = 1 THEN 0 ELSE 1 END,
    product_name;

-- ============================================
-- Sorting with LIMIT/TOP/FETCH
-- ============================================

-- MySQL/PostgreSQL: LIMIT
SELECT * FROM employees 
ORDER BY salary DESC 
LIMIT 10;

-- MySQL/PostgreSQL: LIMIT with OFFSET
SELECT * FROM employees 
ORDER BY salary DESC 
LIMIT 10 OFFSET 20;

-- SQL Server: TOP
SELECT TOP 10 * FROM employees 
ORDER BY salary DESC;

-- SQL Server: TOP with PERCENT
SELECT TOP 10 PERCENT * FROM employees 
ORDER BY salary DESC;

-- SQL Server 2012+: OFFSET FETCH
SELECT * FROM employees 
ORDER BY salary DESC 
OFFSET 20 ROWS 
FETCH NEXT 10 ROWS ONLY;

-- Oracle 12c+: FETCH FIRST
SELECT * FROM employees 
ORDER BY salary DESC 
FETCH FIRST 10 ROWS ONLY;

-- Oracle 12c+: OFFSET FETCH
SELECT * FROM employees 
ORDER BY salary DESC 
OFFSET 20 ROWS 
FETCH NEXT 10 ROWS ONLY;

-- Oracle (older): ROWNUM
SELECT * FROM (
    SELECT * FROM employees ORDER BY salary DESC
) WHERE ROWNUM <= 10;

-- ============================================
-- Sorting in Subqueries
-- ============================================

-- Top N per group (using window function)
SELECT * FROM (
    SELECT 
        e.*,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees e
) ranked
WHERE rn <= 3
ORDER BY department_id, rn;

-- ============================================
-- Random Ordering
-- ============================================

-- SQL Server
SELECT * FROM employees ORDER BY NEWID();

-- Oracle
SELECT * FROM employees ORDER BY DBMS_RANDOM.VALUE;

-- PostgreSQL
SELECT * FROM employees ORDER BY RANDOM();

-- MySQL
SELECT * FROM employees ORDER BY RAND();

-- ============================================
-- Sorting with JOINs
-- ============================================

-- Sort by column from joined table
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.department_name, e.salary DESC;

-- Sort with table alias
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.department_name ASC, e.last_name ASC;

-- ============================================
-- Sorting Aggregated Results
-- ============================================

-- Sort by aggregate
SELECT 
    department_id,
    COUNT(*) AS emp_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY emp_count DESC;

-- Sort by multiple aggregates
SELECT 
    department_id,
    COUNT(*) AS emp_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY emp_count DESC, avg_salary DESC;

-- ============================================
-- Practical Examples
-- ============================================

-- Pagination (page 3, 10 items per page)
-- PostgreSQL/MySQL
SELECT * FROM employees 
ORDER BY employee_id 
LIMIT 10 OFFSET 20;

-- SQL Server
SELECT * FROM employees 
ORDER BY employee_id 
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

-- Get latest records
SELECT * FROM orders 
ORDER BY order_date DESC, order_id DESC 
LIMIT 100;

-- Alphabetical directory
SELECT 
    last_name,
    first_name,
    email,
    phone
FROM employees
ORDER BY last_name, first_name;

-- Salary ranking
SELECT 
    first_name,
    last_name,
    department_id,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees
ORDER BY salary_rank;
