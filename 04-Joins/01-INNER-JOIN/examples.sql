-- ============================================
-- INNER JOIN Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Sample Tables
-- ============================================

-- employees: employee_id, first_name, last_name, department_id, manager_id, salary
-- departments: department_id, department_name, location_id
-- locations: location_id, city, country_id
-- orders: order_id, customer_id, order_date, total_amount
-- customers: customer_id, customer_name, email

-- ============================================
-- Basic INNER JOIN
-- ============================================

-- Join employees with departments
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- Explicit INNER keyword (same as above)
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- INNER JOIN with Multiple Conditions
-- ============================================

-- Join with additional condition
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
INNER JOIN departments d 
    ON e.department_id = d.department_id
    AND e.salary > 50000;

-- Using WHERE for filtering (preferred for readability)
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 50000;

-- ============================================
-- Multiple Table INNER JOINs
-- ============================================

-- Three table join
SELECT 
    e.first_name,
    e.last_name,
    d.department_name,
    l.city
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN locations l ON d.location_id = l.location_id;

-- Four table join
SELECT 
    e.first_name,
    e.last_name,
    d.department_name,
    l.city,
    c.country_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN locations l ON d.location_id = l.location_id
INNER JOIN countries c ON l.country_id = c.country_id;

-- ============================================
-- INNER JOIN with Aggregation
-- ============================================

-- Count employees per department
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM departments d
INNER JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- Average salary per department
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS emp_count,
    AVG(e.salary) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary
FROM departments d
INNER JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
HAVING COUNT(e.employee_id) > 5
ORDER BY avg_salary DESC;

-- ============================================
-- INNER JOIN with Subquery
-- ============================================

-- Join with derived table
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    dept_avg.avg_salary
FROM employees e
INNER JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) dept_avg ON e.department_id = dept_avg.department_id
WHERE e.salary > dept_avg.avg_salary;

-- ============================================
-- INNER JOIN Variations by RDBMS
-- ============================================

-- Traditional comma syntax (older style, not recommended)
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id;

-- USING clause (when column names match)
-- PostgreSQL, MySQL, Oracle
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d USING (department_id);

-- NATURAL JOIN (joins on all matching column names)
-- Use with caution - implicit and can be fragile
SELECT 
    first_name,
    last_name,
    department_name
FROM employees
NATURAL JOIN departments;

-- ============================================
-- Practical INNER JOIN Examples
-- ============================================

-- Orders with customer information
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    c.customer_name,
    c.email
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC;

-- Order details with product information
SELECT 
    o.order_id,
    o.order_date,
    oi.quantity,
    oi.unit_price,
    p.product_name,
    (oi.quantity * oi.unit_price) AS line_total
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_id, p.product_name;

-- Employee with manager name
SELECT 
    e.first_name AS employee_first_name,
    e.last_name AS employee_last_name,
    m.first_name AS manager_first_name,
    m.last_name AS manager_last_name
FROM employees e
INNER JOIN employees m ON e.manager_id = m.employee_id;

-- ============================================
-- INNER JOIN with Date Ranges
-- ============================================

-- Orders within date range with customer info
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 1000
ORDER BY total_spent DESC;

-- ============================================
-- INNER JOIN Performance Tips
-- ============================================

-- Ensure join columns are indexed
-- CREATE INDEX idx_emp_dept ON employees(department_id);
-- CREATE INDEX idx_dept_id ON departments(department_id);

-- Select only needed columns (avoid SELECT *)
SELECT 
    e.employee_id,
    e.first_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- Filter early when possible
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT';
