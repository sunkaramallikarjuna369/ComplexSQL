-- ============================================
-- FULL OUTER JOIN Examples
-- SQL Server, Oracle, PostgreSQL
-- (MySQL doesn't support FULL OUTER JOIN directly)
-- ============================================

-- ============================================
-- Basic FULL OUTER JOIN
-- ============================================

-- All employees and all departments
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_id,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id;

-- Explicit OUTER keyword
SELECT 
    e.first_name,
    d.department_name
FROM employees e
FULL JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- MySQL: Simulating FULL OUTER JOIN
-- ============================================

-- MySQL doesn't have FULL OUTER JOIN, use UNION
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id

UNION

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- Finding All Unmatched Records
-- ============================================

-- Employees without department OR departments without employees
SELECT 
    e.employee_id,
    e.first_name,
    d.department_id,
    d.department_name,
    CASE 
        WHEN e.employee_id IS NULL THEN 'Department has no employees'
        WHEN d.department_id IS NULL THEN 'Employee has no department'
        ELSE 'Matched'
    END AS match_status
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id
WHERE e.employee_id IS NULL OR d.department_id IS NULL;

-- ============================================
-- FULL OUTER JOIN with Aggregation
-- ============================================

-- Complete picture of employees and departments
SELECT 
    COALESCE(d.department_name, 'No Department') AS department,
    COUNT(e.employee_id) AS employee_count,
    COALESCE(SUM(e.salary), 0) AS total_salary
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY employee_count DESC;

-- ============================================
-- Practical FULL OUTER JOIN Examples
-- ============================================

-- Data reconciliation: Compare two tables
SELECT 
    COALESCE(a.id, b.id) AS id,
    a.value AS table_a_value,
    b.value AS table_b_value,
    CASE 
        WHEN a.id IS NULL THEN 'Only in B'
        WHEN b.id IS NULL THEN 'Only in A'
        WHEN a.value <> b.value THEN 'Different values'
        ELSE 'Match'
    END AS comparison_result
FROM table_a a
FULL OUTER JOIN table_b b ON a.id = b.id
WHERE a.id IS NULL OR b.id IS NULL OR a.value <> b.value;

-- Budget vs Actual comparison
SELECT 
    COALESCE(b.department_id, a.department_id) AS department_id,
    COALESCE(b.budget_amount, 0) AS budget,
    COALESCE(a.actual_amount, 0) AS actual,
    COALESCE(b.budget_amount, 0) - COALESCE(a.actual_amount, 0) AS variance
FROM budget b
FULL OUTER JOIN actuals a ON b.department_id = a.department_id
ORDER BY department_id;

-- Customer orders from two systems
SELECT 
    COALESCE(s1.order_id, s2.order_id) AS order_id,
    s1.total AS system1_total,
    s2.total AS system2_total,
    CASE 
        WHEN s1.order_id IS NULL THEN 'Missing in System 1'
        WHEN s2.order_id IS NULL THEN 'Missing in System 2'
        WHEN s1.total <> s2.total THEN 'Amount mismatch'
        ELSE 'Reconciled'
    END AS status
FROM system1_orders s1
FULL OUTER JOIN system2_orders s2 ON s1.order_id = s2.order_id;

-- ============================================
-- Multiple FULL OUTER JOINs
-- ============================================

-- Three-way comparison
SELECT 
    COALESCE(a.id, b.id, c.id) AS id,
    a.value AS source_a,
    b.value AS source_b,
    c.value AS source_c
FROM source_a a
FULL OUTER JOIN source_b b ON a.id = b.id
FULL OUTER JOIN source_c c ON COALESCE(a.id, b.id) = c.id;

-- ============================================
-- FULL OUTER JOIN with Date Ranges
-- ============================================

-- All dates with sales and returns
SELECT 
    COALESCE(s.sale_date, r.return_date) AS date,
    COALESCE(s.total_sales, 0) AS sales,
    COALESCE(r.total_returns, 0) AS returns,
    COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net
FROM (
    SELECT sale_date, SUM(amount) AS total_sales
    FROM sales
    GROUP BY sale_date
) s
FULL OUTER JOIN (
    SELECT return_date, SUM(amount) AS total_returns
    FROM returns
    GROUP BY return_date
) r ON s.sale_date = r.return_date
ORDER BY date;

-- ============================================
-- Performance Considerations
-- ============================================

-- FULL OUTER JOIN can be expensive
-- Consider if you really need all unmatched from both sides
-- Sometimes two separate queries (LEFT JOIN + RIGHT JOIN) 
-- with UNION might perform better

-- Alternative approach for large datasets
SELECT 
    e.employee_id,
    e.first_name,
    d.department_name,
    'Left Only' AS source
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_id IS NULL

UNION ALL

SELECT 
    e.employee_id,
    e.first_name,
    d.department_name,
    'Right Only' AS source
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id
WHERE e.employee_id IS NULL

UNION ALL

SELECT 
    e.employee_id,
    e.first_name,
    d.department_name,
    'Matched' AS source
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
