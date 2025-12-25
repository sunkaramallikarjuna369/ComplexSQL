-- ============================================
-- Recursive CTE Examples
-- SQL Server, Oracle, PostgreSQL, MySQL 8.0+
-- ============================================

-- ============================================
-- Basic Recursive CTE Structure
-- ============================================

-- Generate numbers 1 to 10
WITH RECURSIVE numbers AS (
    -- Anchor member (base case)
    SELECT 1 AS n
    
    UNION ALL
    
    -- Recursive member
    SELECT n + 1
    FROM numbers
    WHERE n < 10
)
SELECT * FROM numbers;

-- SQL Server syntax (no RECURSIVE keyword)
WITH numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT * FROM numbers;

-- ============================================
-- Employee Hierarchy (Org Chart)
-- ============================================

-- Full organizational hierarchy
WITH RECURSIVE org_hierarchy AS (
    -- Anchor: Top-level employees (CEO, no manager)
    SELECT 
        employee_id,
        first_name,
        last_name,
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
        e.last_name,
        e.manager_id,
        h.level + 1,
        CAST(h.path || ' -> ' || e.first_name AS VARCHAR(1000))
    FROM employees e
    INNER JOIN org_hierarchy h ON e.manager_id = h.employee_id
)
SELECT 
    employee_id,
    REPEAT('  ', level - 1) || first_name AS indented_name,
    level,
    path
FROM org_hierarchy
ORDER BY path;

-- Find all subordinates of a specific manager
WITH RECURSIVE subordinates AS (
    SELECT employee_id, first_name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id = 100  -- Starting manager ID
    
    UNION ALL
    
    SELECT e.employee_id, e.first_name, e.manager_id, s.level + 1
    FROM employees e
    INNER JOIN subordinates s ON e.manager_id = s.employee_id
)
SELECT * FROM subordinates ORDER BY level, first_name;

-- Count subordinates at each level
WITH RECURSIVE org_tree AS (
    SELECT employee_id, first_name, manager_id, 0 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.employee_id, e.first_name, e.manager_id, t.level + 1
    FROM employees e
    INNER JOIN org_tree t ON e.manager_id = t.employee_id
)
SELECT level, COUNT(*) AS employee_count
FROM org_tree
GROUP BY level
ORDER BY level;

-- ============================================
-- Category Hierarchy
-- ============================================

-- Product category tree
WITH RECURSIVE category_tree AS (
    SELECT 
        category_id,
        category_name,
        parent_category_id,
        1 AS level,
        CAST(category_name AS VARCHAR(500)) AS full_path
    FROM categories
    WHERE parent_category_id IS NULL
    
    UNION ALL
    
    SELECT 
        c.category_id,
        c.category_name,
        c.parent_category_id,
        ct.level + 1,
        CAST(ct.full_path || ' > ' || c.category_name AS VARCHAR(500))
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_category_id = ct.category_id
)
SELECT * FROM category_tree ORDER BY full_path;

-- ============================================
-- Bill of Materials (BOM)
-- ============================================

-- Explode BOM to all components
WITH RECURSIVE bom_explosion AS (
    -- Top-level product
    SELECT 
        product_id,
        component_id,
        quantity,
        1 AS level
    FROM bill_of_materials
    WHERE product_id = 1000  -- Starting product
    
    UNION ALL
    
    -- Sub-components
    SELECT 
        b.product_id,
        b.component_id,
        b.quantity * be.quantity AS quantity,
        be.level + 1
    FROM bill_of_materials b
    INNER JOIN bom_explosion be ON b.product_id = be.component_id
)
SELECT 
    be.component_id,
    p.product_name,
    SUM(be.quantity) AS total_quantity
FROM bom_explosion be
JOIN products p ON be.component_id = p.product_id
GROUP BY be.component_id, p.product_name;

-- ============================================
-- Graph Traversal
-- ============================================

-- Find all paths between two nodes
WITH RECURSIVE paths AS (
    SELECT 
        from_node,
        to_node,
        CAST(from_node || '->' || to_node AS VARCHAR(1000)) AS path,
        1 AS hops
    FROM edges
    WHERE from_node = 'A'
    
    UNION ALL
    
    SELECT 
        p.from_node,
        e.to_node,
        CAST(p.path || '->' || e.to_node AS VARCHAR(1000)),
        p.hops + 1
    FROM paths p
    INNER JOIN edges e ON p.to_node = e.from_node
    WHERE p.path NOT LIKE '%' || e.to_node || '%'  -- Prevent cycles
    AND p.hops < 10  -- Limit depth
)
SELECT * FROM paths WHERE to_node = 'Z';

-- ============================================
-- Date Series Generation
-- ============================================

-- Generate date range
WITH RECURSIVE date_series AS (
    SELECT DATE '2024-01-01' AS date_value
    
    UNION ALL
    
    SELECT date_value + INTERVAL '1 day'
    FROM date_series
    WHERE date_value < DATE '2024-12-31'
)
SELECT date_value FROM date_series;

-- Calendar with sales data
WITH RECURSIVE calendar AS (
    SELECT DATE '2024-01-01' AS date_value
    UNION ALL
    SELECT date_value + INTERVAL '1 day'
    FROM calendar
    WHERE date_value < DATE '2024-12-31'
)
SELECT 
    c.date_value,
    COALESCE(SUM(o.total_amount), 0) AS daily_sales
FROM calendar c
LEFT JOIN orders o ON DATE(o.order_date) = c.date_value
GROUP BY c.date_value
ORDER BY c.date_value;

-- ============================================
-- Fibonacci Sequence
-- ============================================

WITH RECURSIVE fibonacci AS (
    SELECT 1 AS n, 0 AS fib, 1 AS next_fib
    
    UNION ALL
    
    SELECT n + 1, next_fib, fib + next_fib
    FROM fibonacci
    WHERE n < 20
)
SELECT n, fib FROM fibonacci;

-- ============================================
-- String Manipulation
-- ============================================

-- Split comma-separated values
WITH RECURSIVE split_string AS (
    SELECT 
        1 AS id,
        'apple,banana,cherry,date' AS remaining,
        CAST('' AS VARCHAR(100)) AS item
    
    UNION ALL
    
    SELECT 
        id + 1,
        CASE 
            WHEN POSITION(',' IN remaining) > 0 
            THEN SUBSTRING(remaining FROM POSITION(',' IN remaining) + 1)
            ELSE ''
        END,
        CASE 
            WHEN POSITION(',' IN remaining) > 0 
            THEN SUBSTRING(remaining FROM 1 FOR POSITION(',' IN remaining) - 1)
            ELSE remaining
        END
    FROM split_string
    WHERE remaining <> ''
)
SELECT item FROM split_string WHERE item <> '';

-- ============================================
-- Recursive CTE Performance Tips
-- ============================================

-- Always include a termination condition
-- Use MAXRECURSION option in SQL Server
WITH numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 1000
)
SELECT * FROM numbers
OPTION (MAXRECURSION 1000);  -- SQL Server

-- PostgreSQL: Set work_mem for large recursions
-- SET work_mem = '256MB';

-- Avoid expensive operations in recursive member
-- Index columns used in JOIN conditions
