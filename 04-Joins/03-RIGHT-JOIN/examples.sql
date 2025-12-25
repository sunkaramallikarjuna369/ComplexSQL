-- ============================================
-- RIGHT JOIN (RIGHT OUTER JOIN) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic RIGHT JOIN
-- ============================================

-- All departments, with employee info if available
SELECT 
    e.first_name,
    e.last_name,
    d.department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id;

-- Explicit OUTER keyword
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
RIGHT OUTER JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- RIGHT JOIN vs LEFT JOIN
-- ============================================

-- These two queries produce the same result:

-- Using RIGHT JOIN
SELECT 
    e.first_name,
    d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id;

-- Equivalent LEFT JOIN (just swap table order)
SELECT 
    e.first_name,
    d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id;

-- ============================================
-- Finding Unmatched Records
-- ============================================

-- Departments without any employees
SELECT 
    d.department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;

-- Products without any orders
SELECT 
    p.product_id,
    p.product_name
FROM order_items oi
RIGHT JOIN products p ON oi.product_id = p.product_id
WHERE oi.order_id IS NULL;

-- ============================================
-- RIGHT JOIN with Aggregation
-- ============================================

-- All departments with employee count
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    COALESCE(AVG(e.salary), 0) AS avg_salary
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY employee_count DESC;

-- All products with sales statistics
SELECT 
    p.product_name,
    COUNT(oi.order_id) AS times_ordered,
    COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM order_items oi
RIGHT JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- ============================================
-- Multiple RIGHT JOINs
-- ============================================

-- All locations with department and employee info
SELECT 
    l.city,
    d.department_name,
    e.first_name,
    e.last_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id
RIGHT JOIN locations l ON d.location_id = l.location_id;

-- ============================================
-- RIGHT JOIN with Conditions
-- ============================================

-- All departments, show only high-salary employees
SELECT 
    d.department_name,
    e.first_name,
    e.salary
FROM employees e
RIGHT JOIN departments d 
    ON e.department_id = d.department_id 
    AND e.salary > 80000;

-- ============================================
-- Oracle Legacy Syntax
-- ============================================

-- Oracle old-style RIGHT JOIN (not recommended)
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id(+) = d.department_id;

-- ============================================
-- Practical RIGHT JOIN Examples
-- ============================================

-- All categories with product count
SELECT 
    c.category_name,
    COUNT(p.product_id) AS product_count
FROM products p
RIGHT JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;

-- All time slots with booking info
SELECT 
    ts.slot_time,
    ts.slot_date,
    COALESCE(b.customer_name, 'Available') AS booking_status
FROM bookings b
RIGHT JOIN time_slots ts ON b.slot_id = ts.slot_id
WHERE ts.slot_date = '2024-12-25'
ORDER BY ts.slot_time;

-- ============================================
-- When to Use RIGHT JOIN
-- ============================================

-- RIGHT JOIN is less common because:
-- 1. LEFT JOIN is more intuitive (primary table on left)
-- 2. You can always rewrite RIGHT JOIN as LEFT JOIN
-- 3. Some developers find LEFT JOIN easier to read

-- However, RIGHT JOIN can be useful when:
-- 1. Adding to an existing query without restructuring
-- 2. When the "all records" table is naturally on the right
-- 3. Personal/team preference

-- Example: Existing query, need to include all departments
-- Original query
SELECT e.first_name, e.salary
FROM employees e
WHERE e.salary > 50000;

-- Adding RIGHT JOIN to include all departments
SELECT e.first_name, e.salary, d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 50000 OR e.employee_id IS NULL;
