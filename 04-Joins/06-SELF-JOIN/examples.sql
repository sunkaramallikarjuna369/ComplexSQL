-- ============================================
-- SELF JOIN Examples
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- Basic SELF JOIN - Employee-Manager
-- ============================================

-- Find employees and their managers
SELECT 
    e.employee_id,
    e.first_name AS employee_first_name,
    e.last_name AS employee_last_name,
    m.first_name AS manager_first_name,
    m.last_name AS manager_last_name
FROM employees e
INNER JOIN employees m ON e.manager_id = m.employee_id;

-- Include employees without managers (CEO)
SELECT 
    e.employee_id,
    e.first_name AS employee_name,
    COALESCE(m.first_name, 'No Manager') AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- ============================================
-- Hierarchical Queries with SELF JOIN
-- ============================================

-- Three-level hierarchy (Employee -> Manager -> Director)
SELECT 
    e.first_name AS employee,
    m.first_name AS manager,
    d.first_name AS director
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
LEFT JOIN employees d ON m.manager_id = d.employee_id;

-- Full reporting chain
SELECT 
    e.first_name AS employee,
    m1.first_name AS level1_manager,
    m2.first_name AS level2_manager,
    m3.first_name AS level3_manager,
    m4.first_name AS level4_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id = m1.employee_id
LEFT JOIN employees m2 ON m1.manager_id = m2.employee_id
LEFT JOIN employees m3 ON m2.manager_id = m3.employee_id
LEFT JOIN employees m4 ON m3.manager_id = m4.employee_id;

-- ============================================
-- Comparing Rows in Same Table
-- ============================================

-- Find employees earning more than their manager
SELECT 
    e.first_name AS employee,
    e.salary AS employee_salary,
    m.first_name AS manager,
    m.salary AS manager_salary,
    e.salary - m.salary AS salary_difference
FROM employees e
INNER JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- Find employees in same department with similar salary
SELECT 
    e1.first_name AS employee1,
    e2.first_name AS employee2,
    e1.department_id,
    e1.salary AS salary1,
    e2.salary AS salary2,
    ABS(e1.salary - e2.salary) AS salary_diff
FROM employees e1
INNER JOIN employees e2 
    ON e1.department_id = e2.department_id
    AND e1.employee_id < e2.employee_id  -- Avoid duplicates
WHERE ABS(e1.salary - e2.salary) < 5000;

-- ============================================
-- Finding Duplicates with SELF JOIN
-- ============================================

-- Find duplicate emails
SELECT DISTINCT
    e1.employee_id AS id1,
    e2.employee_id AS id2,
    e1.email
FROM employees e1
INNER JOIN employees e2 
    ON e1.email = e2.email 
    AND e1.employee_id < e2.employee_id;

-- Find potential duplicate customers (same name, different ID)
SELECT 
    c1.customer_id AS id1,
    c2.customer_id AS id2,
    c1.first_name,
    c1.last_name,
    c1.phone AS phone1,
    c2.phone AS phone2
FROM customers c1
INNER JOIN customers c2 
    ON c1.first_name = c2.first_name 
    AND c1.last_name = c2.last_name
    AND c1.customer_id < c2.customer_id;

-- ============================================
-- Sequential Data Analysis
-- ============================================

-- Compare consecutive orders
SELECT 
    o1.order_id AS current_order,
    o1.order_date AS current_date,
    o1.total_amount AS current_amount,
    o2.order_id AS previous_order,
    o2.order_date AS previous_date,
    o2.total_amount AS previous_amount,
    o1.total_amount - o2.total_amount AS amount_change
FROM orders o1
INNER JOIN orders o2 
    ON o1.customer_id = o2.customer_id
    AND o1.order_date > o2.order_date
WHERE NOT EXISTS (
    SELECT 1 FROM orders o3
    WHERE o3.customer_id = o1.customer_id
    AND o3.order_date > o2.order_date
    AND o3.order_date < o1.order_date
);

-- Find gaps in sequence
SELECT 
    t1.id + 1 AS gap_start,
    MIN(t2.id) - 1 AS gap_end
FROM sequence_table t1
INNER JOIN sequence_table t2 ON t1.id < t2.id
WHERE t1.id + 1 < t2.id
GROUP BY t1.id;

-- ============================================
-- Category/Product Hierarchy
-- ============================================

-- Categories with parent categories
SELECT 
    c.category_id,
    c.category_name,
    p.category_name AS parent_category
FROM categories c
LEFT JOIN categories p ON c.parent_category_id = p.category_id;

-- Full category path
SELECT 
    c1.category_name AS level1,
    c2.category_name AS level2,
    c3.category_name AS level3
FROM categories c1
LEFT JOIN categories c2 ON c2.parent_category_id = c1.category_id
LEFT JOIN categories c3 ON c3.parent_category_id = c2.category_id
WHERE c1.parent_category_id IS NULL;

-- ============================================
-- Flight Connections
-- ============================================

-- Find connecting flights
SELECT 
    f1.flight_id AS first_flight,
    f1.departure_city,
    f1.arrival_city AS connection_city,
    f2.flight_id AS second_flight,
    f2.arrival_city AS final_destination,
    f1.departure_time,
    f1.arrival_time AS connection_arrival,
    f2.departure_time AS connection_departure,
    f2.arrival_time AS final_arrival
FROM flights f1
INNER JOIN flights f2 
    ON f1.arrival_city = f2.departure_city
    AND f2.departure_time > f1.arrival_time
    AND f2.departure_time < f1.arrival_time + INTERVAL '4 hours'
WHERE f1.departure_city = 'New York'
AND f2.arrival_city = 'Los Angeles';

-- ============================================
-- Recursive CTE Alternative (Better for Deep Hierarchies)
-- ============================================

-- SQL Server / PostgreSQL / Oracle
WITH RECURSIVE org_hierarchy AS (
    -- Anchor: Top-level employees (no manager)
    SELECT 
        employee_id,
        first_name,
        manager_id,
        1 AS level,
        CAST(first_name AS VARCHAR(1000)) AS path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Employees with managers
    SELECT 
        e.employee_id,
        e.first_name,
        e.manager_id,
        h.level + 1,
        CAST(h.path || ' -> ' || e.first_name AS VARCHAR(1000))
    FROM employees e
    INNER JOIN org_hierarchy h ON e.manager_id = h.employee_id
)
SELECT * FROM org_hierarchy
ORDER BY level, first_name;

-- ============================================
-- Practical Examples
-- ============================================

-- Find all pairs of products bought together
SELECT 
    oi1.product_id AS product1,
    oi2.product_id AS product2,
    COUNT(*) AS times_bought_together
FROM order_items oi1
INNER JOIN order_items oi2 
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id
GROUP BY oi1.product_id, oi2.product_id
HAVING COUNT(*) > 10
ORDER BY times_bought_together DESC;

-- Find employees hired on same day
SELECT 
    e1.first_name AS employee1,
    e2.first_name AS employee2,
    e1.hire_date
FROM employees e1
INNER JOIN employees e2 
    ON e1.hire_date = e2.hire_date
    AND e1.employee_id < e2.employee_id
ORDER BY e1.hire_date;
