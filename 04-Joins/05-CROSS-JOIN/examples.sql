-- ============================================
-- CROSS JOIN (Cartesian Product) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic CROSS JOIN
-- ============================================

-- Explicit CROSS JOIN syntax
SELECT 
    e.first_name,
    d.department_name
FROM employees e
CROSS JOIN departments d;

-- Implicit CROSS JOIN (comma syntax)
SELECT 
    e.first_name,
    d.department_name
FROM employees e, departments d;

-- ============================================
-- CROSS JOIN for Combinations
-- ============================================

-- All color-size combinations
SELECT 
    c.color_name,
    s.size_name
FROM colors c
CROSS JOIN sizes s
ORDER BY c.color_name, s.size_name;

-- Product variants (color x size x material)
SELECT 
    p.product_name,
    c.color_name,
    s.size_name,
    m.material_name,
    CONCAT(p.product_name, ' - ', c.color_name, ' - ', s.size_name, ' - ', m.material_name) AS variant_name
FROM products p
CROSS JOIN colors c
CROSS JOIN sizes s
CROSS JOIN materials m
WHERE p.has_variants = 1;

-- ============================================
-- CROSS JOIN for Date/Time Generation
-- ============================================

-- Generate all date-hour combinations
SELECT 
    d.date_value,
    h.hour_value,
    CONCAT(d.date_value, ' ', LPAD(h.hour_value, 2, '0'), ':00:00') AS datetime_slot
FROM (
    SELECT '2024-01-01' AS date_value UNION ALL
    SELECT '2024-01-02' UNION ALL
    SELECT '2024-01-03'
) d
CROSS JOIN (
    SELECT 0 AS hour_value UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
    SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
    SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL
    SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL
    SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL
    SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL
    SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
) h
ORDER BY d.date_value, h.hour_value;

-- Calendar with all months and years
SELECT 
    y.year_value,
    m.month_value,
    m.month_name
FROM (
    SELECT 2022 AS year_value UNION ALL
    SELECT 2023 UNION ALL
    SELECT 2024
) y
CROSS JOIN (
    SELECT 1 AS month_value, 'January' AS month_name UNION ALL
    SELECT 2, 'February' UNION ALL
    SELECT 3, 'March' UNION ALL
    SELECT 4, 'April' UNION ALL
    SELECT 5, 'May' UNION ALL
    SELECT 6, 'June' UNION ALL
    SELECT 7, 'July' UNION ALL
    SELECT 8, 'August' UNION ALL
    SELECT 9, 'September' UNION ALL
    SELECT 10, 'October' UNION ALL
    SELECT 11, 'November' UNION ALL
    SELECT 12, 'December'
) m
ORDER BY y.year_value, m.month_value;

-- ============================================
-- CROSS JOIN for Test Data
-- ============================================

-- Generate test employee data
SELECT 
    ROW_NUMBER() OVER (ORDER BY fn.first_name, ln.last_name) AS employee_id,
    fn.first_name,
    ln.last_name,
    CONCAT(LOWER(fn.first_name), '.', LOWER(ln.last_name), '@company.com') AS email
FROM (
    SELECT 'John' AS first_name UNION ALL
    SELECT 'Jane' UNION ALL
    SELECT 'Bob' UNION ALL
    SELECT 'Alice' UNION ALL
    SELECT 'Charlie'
) fn
CROSS JOIN (
    SELECT 'Smith' AS last_name UNION ALL
    SELECT 'Johnson' UNION ALL
    SELECT 'Williams' UNION ALL
    SELECT 'Brown'
) ln;

-- ============================================
-- CROSS JOIN for Matrix Reports
-- ============================================

-- Sales matrix: All products x All regions
SELECT 
    p.product_name,
    r.region_name,
    COALESCE(s.total_sales, 0) AS total_sales
FROM products p
CROSS JOIN regions r
LEFT JOIN (
    SELECT product_id, region_id, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, region_id
) s ON p.product_id = s.product_id AND r.region_id = s.region_id
ORDER BY p.product_name, r.region_name;

-- Employee-Skill matrix
SELECT 
    e.employee_name,
    s.skill_name,
    CASE WHEN es.employee_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_skill
FROM employees e
CROSS JOIN skills s
LEFT JOIN employee_skills es 
    ON e.employee_id = es.employee_id 
    AND s.skill_id = es.skill_id
ORDER BY e.employee_name, s.skill_name;

-- ============================================
-- CROSS JOIN with Filtering
-- ============================================

-- Pairs of employees (for team assignments)
SELECT 
    e1.first_name AS employee1,
    e2.first_name AS employee2
FROM employees e1
CROSS JOIN employees e2
WHERE e1.employee_id < e2.employee_id  -- Avoid duplicates and self-pairs
ORDER BY e1.first_name, e2.first_name;

-- All possible matches (tournament bracket)
SELECT 
    t1.team_name AS home_team,
    t2.team_name AS away_team
FROM teams t1
CROSS JOIN teams t2
WHERE t1.team_id <> t2.team_id  -- Teams don't play themselves
ORDER BY t1.team_name, t2.team_name;

-- ============================================
-- CROSS JOIN LATERAL / CROSS APPLY
-- ============================================

-- SQL Server: CROSS APPLY (like CROSS JOIN with correlated subquery)
SELECT 
    e.first_name,
    e.last_name,
    recent_orders.order_id,
    recent_orders.order_date
FROM employees e
CROSS APPLY (
    SELECT TOP 3 order_id, order_date
    FROM orders o
    WHERE o.employee_id = e.employee_id
    ORDER BY order_date DESC
) recent_orders;

-- PostgreSQL: CROSS JOIN LATERAL
SELECT 
    e.first_name,
    e.last_name,
    recent_orders.order_id,
    recent_orders.order_date
FROM employees e
CROSS JOIN LATERAL (
    SELECT order_id, order_date
    FROM orders o
    WHERE o.employee_id = e.employee_id
    ORDER BY order_date DESC
    LIMIT 3
) recent_orders;

-- ============================================
-- Performance Warning
-- ============================================

-- CROSS JOIN creates M x N rows!
-- 1000 x 1000 = 1,000,000 rows
-- Always filter or limit when possible

-- BAD: Huge result set
-- SELECT * FROM large_table1 CROSS JOIN large_table2;

-- BETTER: Filter first, then cross join
SELECT 
    t1.id,
    t2.id
FROM (SELECT id FROM large_table1 WHERE active = 1 LIMIT 100) t1
CROSS JOIN (SELECT id FROM large_table2 WHERE active = 1 LIMIT 100) t2;
