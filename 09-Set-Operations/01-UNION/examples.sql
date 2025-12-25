-- ============================================
-- Set Operations Examples
-- UNION, UNION ALL, INTERSECT, EXCEPT/MINUS
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- UNION (Removes duplicates)
-- ============================================

-- Basic UNION
SELECT first_name, last_name FROM employees
UNION
SELECT first_name, last_name FROM contractors;

-- UNION with different tables
SELECT customer_name AS name, 'Customer' AS type FROM customers
UNION
SELECT supplier_name AS name, 'Supplier' AS type FROM suppliers;

-- UNION multiple tables
SELECT product_name, price FROM products_us
UNION
SELECT product_name, price FROM products_eu
UNION
SELECT product_name, price FROM products_asia;

-- ============================================
-- UNION ALL (Keeps duplicates, faster)
-- ============================================

-- Basic UNION ALL
SELECT first_name, last_name FROM employees
UNION ALL
SELECT first_name, last_name FROM contractors;

-- UNION ALL for combining data
SELECT 'Q1' AS quarter, SUM(amount) AS total FROM sales WHERE quarter = 1
UNION ALL
SELECT 'Q2', SUM(amount) FROM sales WHERE quarter = 2
UNION ALL
SELECT 'Q3', SUM(amount) FROM sales WHERE quarter = 3
UNION ALL
SELECT 'Q4', SUM(amount) FROM sales WHERE quarter = 4;

-- UNION ALL with ORDER BY (at the end only)
SELECT first_name, last_name, 'Employee' AS source FROM employees
UNION ALL
SELECT first_name, last_name, 'Contractor' FROM contractors
ORDER BY last_name, first_name;

-- ============================================
-- INTERSECT (Common rows)
-- ============================================

-- Basic INTERSECT
SELECT customer_id FROM customers_2023
INTERSECT
SELECT customer_id FROM customers_2024;

-- Find customers who ordered in both years
SELECT customer_id FROM orders WHERE YEAR(order_date) = 2023
INTERSECT
SELECT customer_id FROM orders WHERE YEAR(order_date) = 2024;

-- Products in multiple categories
SELECT product_id FROM category_electronics
INTERSECT
SELECT product_id FROM category_sale_items;

-- MySQL: INTERSECT alternative (MySQL < 8.0.31)
SELECT DISTINCT a.customer_id
FROM customers_2023 a
INNER JOIN customers_2024 b ON a.customer_id = b.customer_id;

-- ============================================
-- EXCEPT / MINUS (Difference)
-- ============================================

-- SQL Server / PostgreSQL: EXCEPT
SELECT customer_id FROM customers_2023
EXCEPT
SELECT customer_id FROM customers_2024;

-- Oracle: MINUS
SELECT customer_id FROM customers_2023
MINUS
SELECT customer_id FROM customers_2024;

-- Find customers who didn't order this year
SELECT customer_id FROM customers
EXCEPT
SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date) = 2024;

-- Products not on sale
SELECT product_id FROM products
EXCEPT
SELECT product_id FROM sale_items;

-- MySQL: EXCEPT alternative
SELECT a.customer_id
FROM customers_2023 a
LEFT JOIN customers_2024 b ON a.customer_id = b.customer_id
WHERE b.customer_id IS NULL;

-- ============================================
-- Set Operations Rules
-- ============================================

-- 1. Same number of columns
-- 2. Compatible data types
-- 3. Column names from first query
-- 4. ORDER BY only at the end

-- Correct: Same columns, compatible types
SELECT employee_id, first_name, hire_date FROM employees
UNION
SELECT contractor_id, first_name, start_date FROM contractors;

-- Using NULL for missing columns
SELECT employee_id, first_name, salary, NULL AS hourly_rate FROM employees
UNION
SELECT contractor_id, first_name, NULL, hourly_rate FROM contractors;

-- ============================================
-- Practical Examples
-- ============================================

-- Combine all contact information
SELECT 
    'Customer' AS contact_type,
    customer_name AS name,
    email,
    phone
FROM customers
UNION ALL
SELECT 
    'Supplier',
    supplier_name,
    email,
    phone
FROM suppliers
UNION ALL
SELECT 
    'Employee',
    first_name || ' ' || last_name,
    email,
    phone
FROM employees
ORDER BY contact_type, name;

-- Find all unique cities
SELECT city FROM customers
UNION
SELECT city FROM suppliers
UNION
SELECT city FROM employees;

-- Data reconciliation
-- Records in source but not in target
SELECT id, name, 'Missing in Target' AS status
FROM source_table
EXCEPT
SELECT id, name, 'Missing in Target'
FROM target_table

UNION ALL

-- Records in target but not in source
SELECT id, name, 'Missing in Source'
FROM target_table
EXCEPT
SELECT id, name, 'Missing in Source'
FROM source_table;

-- Combine historical and current data
SELECT 
    order_id,
    order_date,
    total_amount,
    'Current' AS data_source
FROM orders
WHERE order_date >= '2024-01-01'

UNION ALL

SELECT 
    order_id,
    order_date,
    total_amount,
    'Archive'
FROM orders_archive
WHERE order_date < '2024-01-01';

-- ============================================
-- Performance Considerations
-- ============================================

-- UNION ALL is faster than UNION (no duplicate check)
-- Use UNION ALL when you know there are no duplicates

-- Add indexes on columns used in set operations
-- Filter data before set operations when possible

-- Efficient: Filter first
SELECT customer_id FROM orders WHERE order_date >= '2024-01-01'
EXCEPT
SELECT customer_id FROM returns WHERE return_date >= '2024-01-01';

-- Less efficient: Set operation on full tables
-- SELECT customer_id FROM orders
-- EXCEPT
-- SELECT customer_id FROM returns;
