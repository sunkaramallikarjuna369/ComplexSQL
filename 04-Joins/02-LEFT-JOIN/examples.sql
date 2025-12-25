-- ============================================
-- LEFT JOIN (LEFT OUTER JOIN) Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic LEFT JOIN
-- ============================================

-- All employees, with department info if available
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- Explicit OUTER keyword (same result)
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
LEFT OUTER JOIN departments d ON e.department_id = d.department_id;

-- ============================================
-- Finding Unmatched Records
-- ============================================

-- Employees without a department
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_id IS NULL;

-- Departments without employees
SELECT 
    d.department_id,
    d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.employee_id IS NULL;

-- Customers who never ordered
SELECT 
    c.customer_id,
    c.customer_name,
    c.email
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- ============================================
-- LEFT JOIN with Aggregation
-- ============================================

-- All departments with employee count (including 0)
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY employee_count DESC;

-- All customers with order statistics
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- ============================================
-- Multiple LEFT JOINs
-- ============================================

-- Employees with department and location (all optional)
SELECT 
    e.first_name,
    e.last_name,
    COALESCE(d.department_name, 'No Department') AS department,
    COALESCE(l.city, 'Unknown') AS city
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
LEFT JOIN locations l ON d.location_id = l.location_id;

-- Orders with customer and shipping info
SELECT 
    o.order_id,
    o.order_date,
    COALESCE(c.customer_name, 'Guest') AS customer,
    COALESCE(s.carrier_name, 'Not Shipped') AS carrier
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN shipments s ON o.order_id = s.order_id;

-- ============================================
-- LEFT JOIN with Conditions
-- ============================================

-- All employees, only show IT department info
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
LEFT JOIN departments d 
    ON e.department_id = d.department_id 
    AND d.department_name = 'IT';

-- Note: Condition in ON vs WHERE makes a difference!
-- This shows all employees, IT dept info only for IT employees

-- vs. This filters to only IT employees:
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT';  -- This becomes INNER JOIN behavior!

-- ============================================
-- LEFT JOIN with Subquery
-- ============================================

-- All employees with their latest order
SELECT 
    e.first_name,
    e.last_name,
    lo.order_date AS last_order_date,
    lo.total_amount AS last_order_amount
FROM employees e
LEFT JOIN (
    SELECT 
        customer_id,
        order_date,
        total_amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
) lo ON e.employee_id = lo.customer_id AND lo.rn = 1;

-- ============================================
-- Oracle Legacy Syntax
-- ============================================

-- Oracle old-style LEFT JOIN (not recommended)
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id(+);

-- ============================================
-- Practical LEFT JOIN Examples
-- ============================================

-- Product catalog with inventory status
SELECT 
    p.product_id,
    p.product_name,
    p.price,
    COALESCE(i.quantity, 0) AS stock_quantity,
    CASE 
        WHEN i.quantity IS NULL OR i.quantity = 0 THEN 'Out of Stock'
        WHEN i.quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id;

-- All months with sales (including months with no sales)
-- Using a calendar/numbers table
SELECT 
    cal.month_date,
    COALESCE(SUM(o.total_amount), 0) AS monthly_sales,
    COUNT(o.order_id) AS order_count
FROM calendar cal
LEFT JOIN orders o 
    ON EXTRACT(YEAR FROM o.order_date) = EXTRACT(YEAR FROM cal.month_date)
    AND EXTRACT(MONTH FROM o.order_date) = EXTRACT(MONTH FROM cal.month_date)
WHERE cal.month_date BETWEEN '2024-01-01' AND '2024-12-01'
GROUP BY cal.month_date
ORDER BY cal.month_date;

-- Employee hierarchy with optional manager
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    COALESCE(m.first_name || ' ' || m.last_name, 'No Manager') AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- ============================================
-- LEFT JOIN vs NOT EXISTS
-- ============================================

-- Find customers without orders using LEFT JOIN
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Same result using NOT EXISTS (often more efficient)
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- Same result using NOT IN (be careful with NULLs)
SELECT customer_id, customer_name
FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id FROM orders WHERE customer_id IS NOT NULL
);
