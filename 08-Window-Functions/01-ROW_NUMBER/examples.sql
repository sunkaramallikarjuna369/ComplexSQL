-- ============================================
-- Window Functions Examples
-- ROW_NUMBER, RANK, DENSE_RANK, NTILE
-- SQL Server, Oracle, PostgreSQL, MySQL 8.0+
-- ============================================

-- ============================================
-- ROW_NUMBER
-- ============================================

-- Basic ROW_NUMBER
SELECT 
    employee_id,
    first_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num
FROM employees;

-- ROW_NUMBER with PARTITION BY
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;

-- Top N per group using ROW_NUMBER
WITH ranked AS (
    SELECT 
        employee_id,
        first_name,
        department_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT * FROM ranked WHERE rn <= 3;

-- Pagination using ROW_NUMBER
WITH numbered AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY employee_id) AS row_num
    FROM employees
)
SELECT * FROM numbered
WHERE row_num BETWEEN 21 AND 30;  -- Page 3, 10 per page

-- ============================================
-- RANK
-- ============================================

-- Basic RANK (gaps after ties)
SELECT 
    employee_id,
    first_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;

-- RANK with PARTITION BY
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;

-- ============================================
-- DENSE_RANK
-- ============================================

-- Basic DENSE_RANK (no gaps after ties)
SELECT 
    employee_id,
    first_name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Compare ROW_NUMBER, RANK, DENSE_RANK
SELECT 
    employee_id,
    first_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK() OVER (ORDER BY salary DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank
FROM employees
ORDER BY salary DESC;

-- ============================================
-- NTILE
-- ============================================

-- Divide into quartiles
SELECT 
    employee_id,
    first_name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;

-- Divide into deciles (10 groups)
SELECT 
    employee_id,
    first_name,
    salary,
    NTILE(10) OVER (ORDER BY salary DESC) AS decile
FROM employees;

-- Salary bands using NTILE
SELECT 
    quartile,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    COUNT(*) AS emp_count
FROM (
    SELECT salary, NTILE(4) OVER (ORDER BY salary) AS quartile
    FROM employees
) q
GROUP BY quartile
ORDER BY quartile;

-- ============================================
-- Practical Examples
-- ============================================

-- Find Nth highest salary
WITH ranked AS (
    SELECT DISTINCT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
    FROM employees
)
SELECT salary FROM ranked WHERE rank = 3;  -- 3rd highest

-- Remove duplicates keeping first occurrence
WITH numbered AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY employee_id) AS rn
    FROM employees
)
DELETE FROM employees
WHERE employee_id IN (SELECT employee_id FROM numbered WHERE rn > 1);

-- Identify salary percentile
SELECT 
    employee_id,
    first_name,
    salary,
    NTILE(100) OVER (ORDER BY salary) AS percentile
FROM employees;

-- Compare employee to department average
SELECT 
    employee_id,
    first_name,
    department_id,
    salary,
    AVG(salary) OVER (PARTITION BY department_id) AS dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department_id) AS diff_from_avg,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;
