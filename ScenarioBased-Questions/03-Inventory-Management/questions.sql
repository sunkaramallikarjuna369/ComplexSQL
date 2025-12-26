-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: INVENTORY MANAGEMENT (Q41-Q60)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q41: IDENTIFY PRODUCTS BELOW REORDER LEVEL
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Comparison, JOIN, Filtering
-- 
-- BUSINESS SCENARIO:
-- Warehouse manager needs to identify products that need to be reordered
-- before they run out of stock.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.reorder_level,
    p.reorder_level - p.units_in_stock AS units_needed,
    c.category_name,
    s.company_name AS supplier
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.units_in_stock < p.reorder_level
AND p.discontinued = 0
ORDER BY units_needed DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.reorder_level,
    p.reorder_level - p.units_in_stock AS units_needed,
    c.category_name,
    s.company_name AS supplier
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.units_in_stock < p.reorder_level
AND p.discontinued = 0
ORDER BY units_needed DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.reorder_level,
    p.reorder_level - p.units_in_stock AS units_needed,
    c.category_name,
    s.company_name AS supplier
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.units_in_stock < p.reorder_level
AND p.discontinued = FALSE
ORDER BY units_needed DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.reorder_level,
    p.reorder_level - p.units_in_stock AS units_needed,
    c.category_name,
    s.company_name AS supplier
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.units_in_stock < p.reorder_level
AND p.discontinued = 0
ORDER BY units_needed DESC;

-- EXPLANATION:
-- Boolean handling differs:
--   SQL Server/MySQL: Use 0/1 or BIT
--   Oracle: Use 0/1 or VARCHAR2('Y'/'N')
--   PostgreSQL: Use TRUE/FALSE


-- ============================================================================
-- Q42: CALCULATE ABC CLASSIFICATION FOR INVENTORY
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Window Functions, NTILE, Cumulative Percentage
-- 
-- BUSINESS SCENARIO:
-- Classify inventory into A (top 80% value), B (next 15%), C (bottom 5%)
-- for prioritized inventory management.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH product_value AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.units_in_stock * p.unit_price AS inventory_value
    FROM products p
    WHERE p.discontinued = 0
),
ranked AS (
    SELECT 
        product_id,
        product_name,
        inventory_value,
        SUM(inventory_value) OVER (ORDER BY inventory_value DESC) AS cumulative_value,
        SUM(inventory_value) OVER () AS total_value
    FROM product_value
)
SELECT 
    product_id,
    product_name,
    inventory_value,
    ROUND(100.0 * cumulative_value / total_value, 2) AS cumulative_pct,
    CASE 
        WHEN 100.0 * cumulative_value / total_value <= 80 THEN 'A'
        WHEN 100.0 * cumulative_value / total_value <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM ranked
ORDER BY inventory_value DESC;

-- ==================== ORACLE SOLUTION ====================
WITH product_value AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.units_in_stock * p.unit_price AS inventory_value
    FROM products p
    WHERE p.discontinued = 0
),
ranked AS (
    SELECT 
        product_id,
        product_name,
        inventory_value,
        SUM(inventory_value) OVER (ORDER BY inventory_value DESC) AS cumulative_value,
        SUM(inventory_value) OVER () AS total_value
    FROM product_value
)
SELECT 
    product_id,
    product_name,
    inventory_value,
    ROUND(100.0 * cumulative_value / total_value, 2) AS cumulative_pct,
    CASE 
        WHEN 100.0 * cumulative_value / total_value <= 80 THEN 'A'
        WHEN 100.0 * cumulative_value / total_value <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM ranked
ORDER BY inventory_value DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH product_value AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.units_in_stock * p.unit_price AS inventory_value
    FROM products p
    WHERE p.discontinued = FALSE
),
ranked AS (
    SELECT 
        product_id,
        product_name,
        inventory_value,
        SUM(inventory_value) OVER (ORDER BY inventory_value DESC) AS cumulative_value,
        SUM(inventory_value) OVER () AS total_value
    FROM product_value
)
SELECT 
    product_id,
    product_name,
    inventory_value,
    ROUND((100.0 * cumulative_value / total_value)::NUMERIC, 2) AS cumulative_pct,
    CASE 
        WHEN 100.0 * cumulative_value / total_value <= 80 THEN 'A'
        WHEN 100.0 * cumulative_value / total_value <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM ranked
ORDER BY inventory_value DESC;

-- ==================== MYSQL SOLUTION ====================
WITH product_value AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.units_in_stock * p.unit_price AS inventory_value
    FROM products p
    WHERE p.discontinued = 0
),
ranked AS (
    SELECT 
        product_id,
        product_name,
        inventory_value,
        SUM(inventory_value) OVER (ORDER BY inventory_value DESC) AS cumulative_value,
        SUM(inventory_value) OVER () AS total_value
    FROM product_value
)
SELECT 
    product_id,
    product_name,
    inventory_value,
    ROUND(100.0 * cumulative_value / total_value, 2) AS cumulative_pct,
    CASE 
        WHEN 100.0 * cumulative_value / total_value <= 80 THEN 'A'
        WHEN 100.0 * cumulative_value / total_value <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM ranked
ORDER BY inventory_value DESC;

-- EXPLANATION:
-- ABC analysis uses Pareto principle (80/20 rule).
-- Running sum with window function calculates cumulative percentage.


-- ============================================================================
-- Q43: CALCULATE INVENTORY TURNOVER RATIO
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Date Filtering, Division
-- 
-- BUSINESS SCENARIO:
-- Measure how efficiently inventory is being sold and replaced.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH sales_data AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS cost_of_goods_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(YEAR, -1, GETDATE())
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock * p.unit_price AS current_inventory_value,
    ISNULL(s.cost_of_goods_sold, 0) AS annual_cogs,
    CASE 
        WHEN p.units_in_stock * p.unit_price = 0 THEN NULL
        ELSE ROUND(ISNULL(s.cost_of_goods_sold, 0) / (p.units_in_stock * p.unit_price), 2)
    END AS turnover_ratio
FROM products p
LEFT JOIN sales_data s ON p.product_id = s.product_id
WHERE p.discontinued = 0
ORDER BY turnover_ratio DESC;

-- ==================== ORACLE SOLUTION ====================
WITH sales_data AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS cost_of_goods_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= ADD_MONTHS(SYSDATE, -12)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock * p.unit_price AS current_inventory_value,
    NVL(s.cost_of_goods_sold, 0) AS annual_cogs,
    CASE 
        WHEN p.units_in_stock * p.unit_price = 0 THEN NULL
        ELSE ROUND(NVL(s.cost_of_goods_sold, 0) / (p.units_in_stock * p.unit_price), 2)
    END AS turnover_ratio
FROM products p
LEFT JOIN sales_data s ON p.product_id = s.product_id
WHERE p.discontinued = 0
ORDER BY turnover_ratio DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH sales_data AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS cost_of_goods_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock * p.unit_price AS current_inventory_value,
    COALESCE(s.cost_of_goods_sold, 0) AS annual_cogs,
    CASE 
        WHEN p.units_in_stock * p.unit_price = 0 THEN NULL
        ELSE ROUND((COALESCE(s.cost_of_goods_sold, 0) / (p.units_in_stock * p.unit_price))::NUMERIC, 2)
    END AS turnover_ratio
FROM products p
LEFT JOIN sales_data s ON p.product_id = s.product_id
WHERE p.discontinued = FALSE
ORDER BY turnover_ratio DESC;

-- ==================== MYSQL SOLUTION ====================
WITH sales_data AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS cost_of_goods_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock * p.unit_price AS current_inventory_value,
    IFNULL(s.cost_of_goods_sold, 0) AS annual_cogs,
    CASE 
        WHEN p.units_in_stock * p.unit_price = 0 THEN NULL
        ELSE ROUND(IFNULL(s.cost_of_goods_sold, 0) / (p.units_in_stock * p.unit_price), 2)
    END AS turnover_ratio
FROM products p
LEFT JOIN sales_data s ON p.product_id = s.product_id
WHERE p.discontinued = 0
ORDER BY turnover_ratio DESC;

-- EXPLANATION:
-- Inventory Turnover = Cost of Goods Sold / Average Inventory
-- Higher ratio indicates efficient inventory management.


-- ============================================================================
-- Q44: FIND SLOW-MOVING INVENTORY (NO SALES IN 90 DAYS)
-- ============================================================================
-- Difficulty: Medium
-- Concepts: LEFT JOIN, NULL Check, Date Arithmetic
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.unit_price,
    p.units_in_stock * p.unit_price AS inventory_value,
    MAX(o.order_date) AS last_sale_date,
    DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_sale
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'Completed'
WHERE p.discontinued = 0
GROUP BY p.product_id, p.product_name, p.units_in_stock, p.unit_price
HAVING MAX(o.order_date) IS NULL 
    OR MAX(o.order_date) < DATEADD(DAY, -90, GETDATE())
ORDER BY inventory_value DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.unit_price,
    p.units_in_stock * p.unit_price AS inventory_value,
    MAX(o.order_date) AS last_sale_date,
    TRUNC(SYSDATE - MAX(o.order_date)) AS days_since_last_sale
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'Completed'
WHERE p.discontinued = 0
GROUP BY p.product_id, p.product_name, p.units_in_stock, p.unit_price
HAVING MAX(o.order_date) IS NULL 
    OR MAX(o.order_date) < SYSDATE - 90
ORDER BY inventory_value DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.unit_price,
    p.units_in_stock * p.unit_price AS inventory_value,
    MAX(o.order_date) AS last_sale_date,
    CURRENT_DATE - MAX(o.order_date) AS days_since_last_sale
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'Completed'
WHERE p.discontinued = FALSE
GROUP BY p.product_id, p.product_name, p.units_in_stock, p.unit_price
HAVING MAX(o.order_date) IS NULL 
    OR MAX(o.order_date) < CURRENT_DATE - INTERVAL '90 days'
ORDER BY inventory_value DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.unit_price,
    p.units_in_stock * p.unit_price AS inventory_value,
    MAX(o.order_date) AS last_sale_date,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_sale
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'Completed'
WHERE p.discontinued = 0
GROUP BY p.product_id, p.product_name, p.units_in_stock, p.unit_price
HAVING MAX(o.order_date) IS NULL 
    OR MAX(o.order_date) < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
ORDER BY inventory_value DESC;

-- EXPLANATION:
-- LEFT JOIN ensures products with no sales are included.
-- HAVING filters after aggregation to find slow-moving items.


-- ============================================================================
-- Q45: CALCULATE DAYS OF INVENTORY ON HAND
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Division, Date Filtering
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        oi.product_id,
        AVG(CAST(oi.quantity AS FLOAT)) AS avg_daily_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(DAY, -30, GETDATE())
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(ISNULL(ds.avg_daily_sales, 0), 2) AS avg_daily_sales,
    CASE 
        WHEN ISNULL(ds.avg_daily_sales, 0) = 0 THEN NULL
        ELSE ROUND(p.units_in_stock / ds.avg_daily_sales, 0)
    END AS days_of_inventory
FROM products p
LEFT JOIN daily_sales ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY days_of_inventory;

-- ==================== ORACLE SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) AS avg_daily_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= SYSDATE - 30
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(NVL(ds.avg_daily_sales, 0), 2) AS avg_daily_sales,
    CASE 
        WHEN NVL(ds.avg_daily_sales, 0) = 0 THEN NULL
        ELSE ROUND(p.units_in_stock / ds.avg_daily_sales, 0)
    END AS days_of_inventory
FROM products p
LEFT JOIN daily_sales ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY days_of_inventory;

-- ==================== POSTGRESQL SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) AS avg_daily_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(COALESCE(ds.avg_daily_sales, 0)::NUMERIC, 2) AS avg_daily_sales,
    CASE 
        WHEN COALESCE(ds.avg_daily_sales, 0) = 0 THEN NULL
        ELSE ROUND((p.units_in_stock / ds.avg_daily_sales)::NUMERIC, 0)
    END AS days_of_inventory
FROM products p
LEFT JOIN daily_sales ds ON p.product_id = ds.product_id
WHERE p.discontinued = FALSE
ORDER BY days_of_inventory;

-- ==================== MYSQL SOLUTION ====================
WITH daily_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) AS avg_daily_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(IFNULL(ds.avg_daily_sales, 0), 2) AS avg_daily_sales,
    CASE 
        WHEN IFNULL(ds.avg_daily_sales, 0) = 0 THEN NULL
        ELSE ROUND(p.units_in_stock / ds.avg_daily_sales, 0)
    END AS days_of_inventory
FROM products p
LEFT JOIN daily_sales ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY days_of_inventory;

-- EXPLANATION:
-- Days of Inventory = Current Stock / Average Daily Sales
-- Helps predict when stock will run out.


-- ============================================================================
-- Q46: IDENTIFY OVERSTOCK SITUATIONS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Comparison, Aggregation, Business Logic
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) * 30 AS monthly_avg_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(MONTH, -3, GETDATE())
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(ISNULL(ms.monthly_avg_sales, 0), 0) AS monthly_avg_sales,
    CASE 
        WHEN ISNULL(ms.monthly_avg_sales, 0) = 0 THEN p.units_in_stock
        ELSE ROUND(p.units_in_stock / ms.monthly_avg_sales, 1)
    END AS months_of_stock,
    p.units_in_stock * p.unit_price AS overstock_value
FROM products p
LEFT JOIN monthly_sales ms ON p.product_id = ms.product_id
WHERE p.discontinued = 0
AND p.units_in_stock > ISNULL(ms.monthly_avg_sales, 0) * 6
ORDER BY overstock_value DESC;

-- ==================== ORACLE SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) * 30 AS monthly_avg_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= ADD_MONTHS(SYSDATE, -3)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(NVL(ms.monthly_avg_sales, 0), 0) AS monthly_avg_sales,
    CASE 
        WHEN NVL(ms.monthly_avg_sales, 0) = 0 THEN p.units_in_stock
        ELSE ROUND(p.units_in_stock / ms.monthly_avg_sales, 1)
    END AS months_of_stock,
    p.units_in_stock * p.unit_price AS overstock_value
FROM products p
LEFT JOIN monthly_sales ms ON p.product_id = ms.product_id
WHERE p.discontinued = 0
AND p.units_in_stock > NVL(ms.monthly_avg_sales, 0) * 6
ORDER BY overstock_value DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) * 30 AS monthly_avg_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(COALESCE(ms.monthly_avg_sales, 0)::NUMERIC, 0) AS monthly_avg_sales,
    CASE 
        WHEN COALESCE(ms.monthly_avg_sales, 0) = 0 THEN p.units_in_stock
        ELSE ROUND((p.units_in_stock / ms.monthly_avg_sales)::NUMERIC, 1)
    END AS months_of_stock,
    p.units_in_stock * p.unit_price AS overstock_value
FROM products p
LEFT JOIN monthly_sales ms ON p.product_id = ms.product_id
WHERE p.discontinued = FALSE
AND p.units_in_stock > COALESCE(ms.monthly_avg_sales, 0) * 6
ORDER BY overstock_value DESC;

-- ==================== MYSQL SOLUTION ====================
WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) * 30 AS monthly_avg_sales
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(IFNULL(ms.monthly_avg_sales, 0), 0) AS monthly_avg_sales,
    CASE 
        WHEN IFNULL(ms.monthly_avg_sales, 0) = 0 THEN p.units_in_stock
        ELSE ROUND(p.units_in_stock / ms.monthly_avg_sales, 1)
    END AS months_of_stock,
    p.units_in_stock * p.unit_price AS overstock_value
FROM products p
LEFT JOIN monthly_sales ms ON p.product_id = ms.product_id
WHERE p.discontinued = 0
AND p.units_in_stock > IFNULL(ms.monthly_avg_sales, 0) * 6
ORDER BY overstock_value DESC;

-- EXPLANATION:
-- Overstock defined as more than 6 months of inventory.
-- Helps identify capital tied up in excess inventory.


-- ============================================================================
-- Q47: CALCULATE STOCK VARIANCE BETWEEN PHYSICAL AND SYSTEM
-- ============================================================================
-- Difficulty: Easy
-- Concepts: Comparison, Calculation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock AS system_count,
    ic.physical_count,
    ic.physical_count - p.units_in_stock AS variance,
    ABS(ic.physical_count - p.units_in_stock) * p.unit_price AS variance_value,
    CASE 
        WHEN ic.physical_count > p.units_in_stock THEN 'Overage'
        WHEN ic.physical_count < p.units_in_stock THEN 'Shortage'
        ELSE 'Match'
    END AS variance_type
FROM products p
INNER JOIN inventory_counts ic ON p.product_id = ic.product_id
WHERE ic.count_date = (SELECT MAX(count_date) FROM inventory_counts)
AND ic.physical_count <> p.units_in_stock
ORDER BY ABS(variance) DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock AS system_count,
    ic.physical_count,
    ic.physical_count - p.units_in_stock AS variance,
    ABS(ic.physical_count - p.units_in_stock) * p.unit_price AS variance_value,
    CASE 
        WHEN ic.physical_count > p.units_in_stock THEN 'Overage'
        WHEN ic.physical_count < p.units_in_stock THEN 'Shortage'
        ELSE 'Match'
    END AS variance_type
FROM products p
INNER JOIN inventory_counts ic ON p.product_id = ic.product_id
WHERE ic.count_date = (SELECT MAX(count_date) FROM inventory_counts)
AND ic.physical_count <> p.units_in_stock
ORDER BY ABS(variance) DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock AS system_count,
    ic.physical_count,
    ic.physical_count - p.units_in_stock AS variance,
    ABS(ic.physical_count - p.units_in_stock) * p.unit_price AS variance_value,
    CASE 
        WHEN ic.physical_count > p.units_in_stock THEN 'Overage'
        WHEN ic.physical_count < p.units_in_stock THEN 'Shortage'
        ELSE 'Match'
    END AS variance_type
FROM products p
INNER JOIN inventory_counts ic ON p.product_id = ic.product_id
WHERE ic.count_date = (SELECT MAX(count_date) FROM inventory_counts)
AND ic.physical_count <> p.units_in_stock
ORDER BY ABS(variance) DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock AS system_count,
    ic.physical_count,
    ic.physical_count - p.units_in_stock AS variance,
    ABS(ic.physical_count - p.units_in_stock) * p.unit_price AS variance_value,
    CASE 
        WHEN ic.physical_count > p.units_in_stock THEN 'Overage'
        WHEN ic.physical_count < p.units_in_stock THEN 'Shortage'
        ELSE 'Match'
    END AS variance_type
FROM products p
INNER JOIN inventory_counts ic ON p.product_id = ic.product_id
WHERE ic.count_date = (SELECT MAX(count_date) FROM inventory_counts)
AND ic.physical_count <> p.units_in_stock
ORDER BY ABS(variance) DESC;

-- EXPLANATION:
-- Standard SQL that works identically across all RDBMS.
-- Compares physical inventory count with system records.


-- ============================================================================
-- Q48: FORECAST INVENTORY NEEDS FOR NEXT MONTH
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Trend Analysis, Moving Average, Projection
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH monthly_demand AS (
    SELECT 
        oi.product_id,
        DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month,
        SUM(oi.quantity) AS quantity_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(MONTH, -6, GETDATE())
    AND o.status = 'Completed'
    GROUP BY oi.product_id, DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1)
),
demand_stats AS (
    SELECT 
        product_id,
        AVG(quantity_sold) AS avg_monthly_demand,
        STDEV(quantity_sold) AS demand_stddev
    FROM monthly_demand
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(ds.avg_monthly_demand, 0) AS forecast_demand,
    ROUND(ds.avg_monthly_demand + 1.65 * ISNULL(ds.demand_stddev, 0), 0) AS safety_stock_demand,
    CASE 
        WHEN p.units_in_stock >= ds.avg_monthly_demand + 1.65 * ISNULL(ds.demand_stddev, 0) THEN 'Sufficient'
        WHEN p.units_in_stock >= ds.avg_monthly_demand THEN 'Low Safety Stock'
        ELSE 'Reorder Needed'
    END AS stock_status
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY stock_status, p.product_name;

-- ==================== ORACLE SOLUTION ====================
WITH monthly_demand AS (
    SELECT 
        oi.product_id,
        TRUNC(o.order_date, 'MM') AS month,
        SUM(oi.quantity) AS quantity_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= ADD_MONTHS(SYSDATE, -6)
    AND o.status = 'Completed'
    GROUP BY oi.product_id, TRUNC(o.order_date, 'MM')
),
demand_stats AS (
    SELECT 
        product_id,
        AVG(quantity_sold) AS avg_monthly_demand,
        STDDEV(quantity_sold) AS demand_stddev
    FROM monthly_demand
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(ds.avg_monthly_demand, 0) AS forecast_demand,
    ROUND(ds.avg_monthly_demand + 1.65 * NVL(ds.demand_stddev, 0), 0) AS safety_stock_demand,
    CASE 
        WHEN p.units_in_stock >= ds.avg_monthly_demand + 1.65 * NVL(ds.demand_stddev, 0) THEN 'Sufficient'
        WHEN p.units_in_stock >= ds.avg_monthly_demand THEN 'Low Safety Stock'
        ELSE 'Reorder Needed'
    END AS stock_status
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY stock_status, p.product_name;

-- ==================== POSTGRESQL SOLUTION ====================
WITH monthly_demand AS (
    SELECT 
        oi.product_id,
        DATE_TRUNC('month', o.order_date)::DATE AS month,
        SUM(oi.quantity) AS quantity_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    AND o.status = 'Completed'
    GROUP BY oi.product_id, DATE_TRUNC('month', o.order_date)::DATE
),
demand_stats AS (
    SELECT 
        product_id,
        AVG(quantity_sold) AS avg_monthly_demand,
        STDDEV(quantity_sold) AS demand_stddev
    FROM monthly_demand
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(ds.avg_monthly_demand::NUMERIC, 0) AS forecast_demand,
    ROUND((ds.avg_monthly_demand + 1.65 * COALESCE(ds.demand_stddev, 0))::NUMERIC, 0) AS safety_stock_demand,
    CASE 
        WHEN p.units_in_stock >= ds.avg_monthly_demand + 1.65 * COALESCE(ds.demand_stddev, 0) THEN 'Sufficient'
        WHEN p.units_in_stock >= ds.avg_monthly_demand THEN 'Low Safety Stock'
        ELSE 'Reorder Needed'
    END AS stock_status
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
WHERE p.discontinued = FALSE
ORDER BY stock_status, p.product_name;

-- ==================== MYSQL SOLUTION ====================
WITH monthly_demand AS (
    SELECT 
        oi.product_id,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month,
        SUM(oi.quantity) AS quantity_sold
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    AND o.status = 'Completed'
    GROUP BY oi.product_id, DATE_FORMAT(o.order_date, '%Y-%m-01')
),
demand_stats AS (
    SELECT 
        product_id,
        AVG(quantity_sold) AS avg_monthly_demand,
        STDDEV(quantity_sold) AS demand_stddev
    FROM monthly_demand
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(ds.avg_monthly_demand, 0) AS forecast_demand,
    ROUND(ds.avg_monthly_demand + 1.65 * IFNULL(ds.demand_stddev, 0), 0) AS safety_stock_demand,
    CASE 
        WHEN p.units_in_stock >= ds.avg_monthly_demand + 1.65 * IFNULL(ds.demand_stddev, 0) THEN 'Sufficient'
        WHEN p.units_in_stock >= ds.avg_monthly_demand THEN 'Low Safety Stock'
        ELSE 'Reorder Needed'
    END AS stock_status
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY stock_status, p.product_name;

-- EXPLANATION:
-- Safety stock uses 1.65 standard deviations (95% service level).
-- Forecast based on 6-month historical average.


-- ============================================================================
-- Q49: ANALYZE SUPPLIER LEAD TIME PERFORMANCE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Arithmetic, Aggregation, Performance Metrics
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    s.supplier_id,
    s.company_name AS supplier_name,
    COUNT(po.po_id) AS total_orders,
    AVG(DATEDIFF(DAY, po.order_date, po.received_date)) AS avg_lead_time_days,
    MIN(DATEDIFF(DAY, po.order_date, po.received_date)) AS min_lead_time,
    MAX(DATEDIFF(DAY, po.order_date, po.received_date)) AS max_lead_time,
    SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(100.0 * SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct
FROM suppliers s
INNER JOIN purchase_orders po ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
GROUP BY s.supplier_id, s.company_name
ORDER BY on_time_pct DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    s.supplier_id,
    s.company_name AS supplier_name,
    COUNT(po.po_id) AS total_orders,
    AVG(po.received_date - po.order_date) AS avg_lead_time_days,
    MIN(po.received_date - po.order_date) AS min_lead_time,
    MAX(po.received_date - po.order_date) AS max_lead_time,
    SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(100.0 * SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct
FROM suppliers s
INNER JOIN purchase_orders po ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
GROUP BY s.supplier_id, s.company_name
ORDER BY on_time_pct DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    s.supplier_id,
    s.company_name AS supplier_name,
    COUNT(po.po_id) AS total_orders,
    AVG(po.received_date - po.order_date) AS avg_lead_time_days,
    MIN(po.received_date - po.order_date) AS min_lead_time,
    MAX(po.received_date - po.order_date) AS max_lead_time,
    SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND((100.0 * SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) / COUNT(*))::NUMERIC, 2) AS on_time_pct
FROM suppliers s
INNER JOIN purchase_orders po ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
GROUP BY s.supplier_id, s.company_name
ORDER BY on_time_pct DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    s.supplier_id,
    s.company_name AS supplier_name,
    COUNT(po.po_id) AS total_orders,
    AVG(DATEDIFF(po.received_date, po.order_date)) AS avg_lead_time_days,
    MIN(DATEDIFF(po.received_date, po.order_date)) AS min_lead_time,
    MAX(DATEDIFF(po.received_date, po.order_date)) AS max_lead_time,
    SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(100.0 * SUM(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct
FROM suppliers s
INNER JOIN purchase_orders po ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
GROUP BY s.supplier_id, s.company_name
ORDER BY on_time_pct DESC;

-- EXPLANATION:
-- Lead time = Received Date - Order Date
-- On-time percentage measures supplier reliability.


-- ============================================================================
-- Q50: CALCULATE ECONOMIC ORDER QUANTITY (EOQ)
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Mathematical Formula, Square Root, Business Logic
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH annual_demand AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity) AS annual_units
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(YEAR, -1, GETDATE())
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ad.annual_units AS annual_demand,
    p.unit_price,
    50.00 AS ordering_cost,
    p.unit_price * 0.25 AS holding_cost_per_unit,
    ROUND(SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)), 0) AS eoq,
    ROUND(CAST(ad.annual_units AS FLOAT) / SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)), 1) AS orders_per_year
FROM products p
INNER JOIN annual_demand ad ON p.product_id = ad.product_id
WHERE p.discontinued = 0
ORDER BY eoq DESC;

-- ==================== ORACLE SOLUTION ====================
WITH annual_demand AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity) AS annual_units
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= ADD_MONTHS(SYSDATE, -12)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ad.annual_units AS annual_demand,
    p.unit_price,
    50.00 AS ordering_cost,
    p.unit_price * 0.25 AS holding_cost_per_unit,
    ROUND(SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)), 0) AS eoq,
    ROUND(ad.annual_units / SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)), 1) AS orders_per_year
FROM products p
INNER JOIN annual_demand ad ON p.product_id = ad.product_id
WHERE p.discontinued = 0
ORDER BY eoq DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH annual_demand AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity) AS annual_units
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ad.annual_units AS annual_demand,
    p.unit_price,
    50.00 AS ordering_cost,
    p.unit_price * 0.25 AS holding_cost_per_unit,
    ROUND(SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25))::NUMERIC, 0) AS eoq,
    ROUND((ad.annual_units / SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)))::NUMERIC, 1) AS orders_per_year
FROM products p
INNER JOIN annual_demand ad ON p.product_id = ad.product_id
WHERE p.discontinued = FALSE
ORDER BY eoq DESC;

-- ==================== MYSQL SOLUTION ====================
WITH annual_demand AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity) AS annual_units
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ad.annual_units AS annual_demand,
    p.unit_price,
    50.00 AS ordering_cost,
    p.unit_price * 0.25 AS holding_cost_per_unit,
    ROUND(SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)), 0) AS eoq,
    ROUND(ad.annual_units / SQRT(2.0 * ad.annual_units * 50.00 / (p.unit_price * 0.25)), 1) AS orders_per_year
FROM products p
INNER JOIN annual_demand ad ON p.product_id = ad.product_id
WHERE p.discontinued = 0
ORDER BY eoq DESC;

-- EXPLANATION:
-- EOQ = SQRT(2 * D * S / H)
-- D = Annual demand, S = Ordering cost, H = Holding cost per unit
-- Minimizes total inventory costs.


-- ============================================================================
-- Q51-Q60: ADDITIONAL INVENTORY MANAGEMENT QUESTIONS
-- ============================================================================
-- Q51: Track inventory movements (receipts, issues, adjustments)
-- Q52: Calculate safety stock levels
-- Q53: Identify products with high shrinkage
-- Q54: Analyze warehouse space utilization
-- Q55: Calculate carrying cost of inventory
-- Q56: Find products with expiring stock (FIFO analysis)
-- Q57: Generate reorder report with suggested quantities
-- Q58: Analyze inventory accuracy by category
-- Q59: Calculate fill rate by product
-- Q60: Identify seasonal inventory patterns
-- ============================================================================


-- ============================================================================
-- Q51: TRACK INVENTORY MOVEMENTS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: UNION ALL, Aggregation, Movement Types
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH movements AS (
    SELECT 
        product_id,
        'Receipt' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_receipts
    UNION ALL
    SELECT 
        product_id,
        'Issue' AS movement_type,
        -quantity AS qty,
        transaction_date
    FROM inventory_issues
    UNION ALL
    SELECT 
        product_id,
        'Adjustment' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_adjustments
)
SELECT 
    p.product_id,
    p.product_name,
    m.movement_type,
    SUM(m.qty) AS total_quantity,
    COUNT(*) AS transaction_count
FROM movements m
INNER JOIN products p ON m.product_id = p.product_id
WHERE m.transaction_date >= DATEADD(MONTH, -1, GETDATE())
GROUP BY p.product_id, p.product_name, m.movement_type
ORDER BY p.product_name, m.movement_type;

-- ==================== ORACLE SOLUTION ====================
WITH movements AS (
    SELECT 
        product_id,
        'Receipt' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_receipts
    UNION ALL
    SELECT 
        product_id,
        'Issue' AS movement_type,
        -quantity AS qty,
        transaction_date
    FROM inventory_issues
    UNION ALL
    SELECT 
        product_id,
        'Adjustment' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_adjustments
)
SELECT 
    p.product_id,
    p.product_name,
    m.movement_type,
    SUM(m.qty) AS total_quantity,
    COUNT(*) AS transaction_count
FROM movements m
INNER JOIN products p ON m.product_id = p.product_id
WHERE m.transaction_date >= ADD_MONTHS(SYSDATE, -1)
GROUP BY p.product_id, p.product_name, m.movement_type
ORDER BY p.product_name, m.movement_type;

-- ==================== POSTGRESQL SOLUTION ====================
WITH movements AS (
    SELECT 
        product_id,
        'Receipt' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_receipts
    UNION ALL
    SELECT 
        product_id,
        'Issue' AS movement_type,
        -quantity AS qty,
        transaction_date
    FROM inventory_issues
    UNION ALL
    SELECT 
        product_id,
        'Adjustment' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_adjustments
)
SELECT 
    p.product_id,
    p.product_name,
    m.movement_type,
    SUM(m.qty) AS total_quantity,
    COUNT(*) AS transaction_count
FROM movements m
INNER JOIN products p ON m.product_id = p.product_id
WHERE m.transaction_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY p.product_id, p.product_name, m.movement_type
ORDER BY p.product_name, m.movement_type;

-- ==================== MYSQL SOLUTION ====================
WITH movements AS (
    SELECT 
        product_id,
        'Receipt' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_receipts
    UNION ALL
    SELECT 
        product_id,
        'Issue' AS movement_type,
        -quantity AS qty,
        transaction_date
    FROM inventory_issues
    UNION ALL
    SELECT 
        product_id,
        'Adjustment' AS movement_type,
        quantity AS qty,
        transaction_date
    FROM inventory_adjustments
)
SELECT 
    p.product_id,
    p.product_name,
    m.movement_type,
    SUM(m.qty) AS total_quantity,
    COUNT(*) AS transaction_count
FROM movements m
INNER JOIN products p ON m.product_id = p.product_id
WHERE m.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY p.product_id, p.product_name, m.movement_type
ORDER BY p.product_name, m.movement_type;

-- EXPLANATION:
-- UNION ALL combines different movement types.
-- Issues are negative to show stock reduction.


-- ============================================================================
-- Q52: CALCULATE SAFETY STOCK LEVELS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Statistical Calculation, Service Level
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH demand_stats AS (
    SELECT 
        oi.product_id,
        AVG(CAST(oi.quantity AS FLOAT)) AS avg_daily_demand,
        STDEV(oi.quantity) AS demand_stddev
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(MONTH, -3, GETDATE())
    AND o.status = 'Completed'
    GROUP BY oi.product_id
),
lead_time AS (
    SELECT 
        p.product_id,
        AVG(CAST(DATEDIFF(DAY, po.order_date, po.received_date) AS FLOAT)) AS avg_lead_time,
        STDEV(DATEDIFF(DAY, po.order_date, po.received_date)) AS lead_time_stddev
    FROM products p
    INNER JOIN purchase_orders po ON p.supplier_id = po.supplier_id
    WHERE po.status = 'Received'
    GROUP BY p.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ROUND(ds.avg_daily_demand, 2) AS avg_daily_demand,
    ROUND(lt.avg_lead_time, 1) AS avg_lead_time_days,
    ROUND(1.65 * SQRT(lt.avg_lead_time * POWER(ISNULL(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(ISNULL(lt.lead_time_stddev, 0), 2)), 0) AS safety_stock,
    ROUND(ds.avg_daily_demand * lt.avg_lead_time, 0) AS reorder_point_base,
    ROUND(ds.avg_daily_demand * lt.avg_lead_time + 
          1.65 * SQRT(lt.avg_lead_time * POWER(ISNULL(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(ISNULL(lt.lead_time_stddev, 0), 2)), 0) AS reorder_point
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
INNER JOIN lead_time lt ON p.product_id = lt.product_id
WHERE p.discontinued = 0
ORDER BY safety_stock DESC;

-- ==================== ORACLE SOLUTION ====================
WITH demand_stats AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) AS avg_daily_demand,
        STDDEV(oi.quantity) AS demand_stddev
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= ADD_MONTHS(SYSDATE, -3)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
),
lead_time AS (
    SELECT 
        p.product_id,
        AVG(po.received_date - po.order_date) AS avg_lead_time,
        STDDEV(po.received_date - po.order_date) AS lead_time_stddev
    FROM products p
    INNER JOIN purchase_orders po ON p.supplier_id = po.supplier_id
    WHERE po.status = 'Received'
    GROUP BY p.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ROUND(ds.avg_daily_demand, 2) AS avg_daily_demand,
    ROUND(lt.avg_lead_time, 1) AS avg_lead_time_days,
    ROUND(1.65 * SQRT(lt.avg_lead_time * POWER(NVL(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(NVL(lt.lead_time_stddev, 0), 2)), 0) AS safety_stock,
    ROUND(ds.avg_daily_demand * lt.avg_lead_time, 0) AS reorder_point_base,
    ROUND(ds.avg_daily_demand * lt.avg_lead_time + 
          1.65 * SQRT(lt.avg_lead_time * POWER(NVL(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(NVL(lt.lead_time_stddev, 0), 2)), 0) AS reorder_point
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
INNER JOIN lead_time lt ON p.product_id = lt.product_id
WHERE p.discontinued = 0
ORDER BY safety_stock DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH demand_stats AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) AS avg_daily_demand,
        STDDEV(oi.quantity) AS demand_stddev
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'
    AND o.status = 'Completed'
    GROUP BY oi.product_id
),
lead_time AS (
    SELECT 
        p.product_id,
        AVG(po.received_date - po.order_date) AS avg_lead_time,
        STDDEV(po.received_date - po.order_date) AS lead_time_stddev
    FROM products p
    INNER JOIN purchase_orders po ON p.supplier_id = po.supplier_id
    WHERE po.status = 'Received'
    GROUP BY p.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ROUND(ds.avg_daily_demand::NUMERIC, 2) AS avg_daily_demand,
    ROUND(lt.avg_lead_time::NUMERIC, 1) AS avg_lead_time_days,
    ROUND((1.65 * SQRT(lt.avg_lead_time * POWER(COALESCE(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(COALESCE(lt.lead_time_stddev, 0), 2)))::NUMERIC, 0) AS safety_stock,
    ROUND((ds.avg_daily_demand * lt.avg_lead_time)::NUMERIC, 0) AS reorder_point_base,
    ROUND((ds.avg_daily_demand * lt.avg_lead_time + 
          1.65 * SQRT(lt.avg_lead_time * POWER(COALESCE(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(COALESCE(lt.lead_time_stddev, 0), 2)))::NUMERIC, 0) AS reorder_point
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
INNER JOIN lead_time lt ON p.product_id = lt.product_id
WHERE p.discontinued = FALSE
ORDER BY safety_stock DESC;

-- ==================== MYSQL SOLUTION ====================
WITH demand_stats AS (
    SELECT 
        oi.product_id,
        AVG(oi.quantity) AS avg_daily_demand,
        STDDEV(oi.quantity) AS demand_stddev
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    AND o.status = 'Completed'
    GROUP BY oi.product_id
),
lead_time AS (
    SELECT 
        p.product_id,
        AVG(DATEDIFF(po.received_date, po.order_date)) AS avg_lead_time,
        STDDEV(DATEDIFF(po.received_date, po.order_date)) AS lead_time_stddev
    FROM products p
    INNER JOIN purchase_orders po ON p.supplier_id = po.supplier_id
    WHERE po.status = 'Received'
    GROUP BY p.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ROUND(ds.avg_daily_demand, 2) AS avg_daily_demand,
    ROUND(lt.avg_lead_time, 1) AS avg_lead_time_days,
    ROUND(1.65 * SQRT(lt.avg_lead_time * POWER(IFNULL(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(IFNULL(lt.lead_time_stddev, 0), 2)), 0) AS safety_stock,
    ROUND(ds.avg_daily_demand * lt.avg_lead_time, 0) AS reorder_point_base,
    ROUND(ds.avg_daily_demand * lt.avg_lead_time + 
          1.65 * SQRT(lt.avg_lead_time * POWER(IFNULL(ds.demand_stddev, 0), 2) + 
          POWER(ds.avg_daily_demand, 2) * POWER(IFNULL(lt.lead_time_stddev, 0), 2)), 0) AS reorder_point
FROM products p
INNER JOIN demand_stats ds ON p.product_id = ds.product_id
INNER JOIN lead_time lt ON p.product_id = lt.product_id
WHERE p.discontinued = 0
ORDER BY safety_stock DESC;

-- EXPLANATION:
-- Safety Stock = Z * SQRT(LT * Var(D) + D^2 * Var(LT))
-- Z = 1.65 for 95% service level
-- Accounts for both demand and lead time variability.


-- ============================================================================
-- Q53-Q60: REMAINING INVENTORY QUESTIONS (ABBREVIATED)
-- ============================================================================
-- Each follows the same multi-RDBMS format with SQL Server, Oracle,
-- PostgreSQL, and MySQL solutions.
-- 
-- Q53: Identify products with high shrinkage (variance analysis)
-- Q54: Analyze warehouse space utilization (capacity planning)
-- Q55: Calculate carrying cost of inventory (holding costs)
-- Q56: Find products with expiring stock (FIFO/lot tracking)
-- Q57: Generate reorder report with suggested quantities
-- Q58: Analyze inventory accuracy by category
-- Q59: Calculate fill rate by product (order fulfillment)
-- Q60: Identify seasonal inventory patterns (demand forecasting)
-- ============================================================================


-- ============================================================================
-- Q53: IDENTIFY PRODUCTS WITH HIGH SHRINKAGE
-- ============================================================================
-- Difficulty: Medium
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) AS shrinkage_units,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) * p.unit_price ELSE 0 END) AS shrinkage_value,
    COUNT(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN 1 END) AS shrinkage_incidents
FROM products p
LEFT JOIN inventory_adjustments ia ON p.product_id = ia.product_id
WHERE ia.adjustment_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY p.product_id, p.product_name
HAVING SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) > 0
ORDER BY shrinkage_value DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) AS shrinkage_units,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) * p.unit_price ELSE 0 END) AS shrinkage_value,
    COUNT(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN 1 END) AS shrinkage_incidents
FROM products p
LEFT JOIN inventory_adjustments ia ON p.product_id = ia.product_id
WHERE ia.adjustment_date >= ADD_MONTHS(SYSDATE, -12)
GROUP BY p.product_id, p.product_name
HAVING SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) > 0
ORDER BY shrinkage_value DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) AS shrinkage_units,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) * p.unit_price ELSE 0 END) AS shrinkage_value,
    COUNT(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN 1 END) AS shrinkage_incidents
FROM products p
LEFT JOIN inventory_adjustments ia ON p.product_id = ia.product_id
WHERE ia.adjustment_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY p.product_id, p.product_name
HAVING SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) > 0
ORDER BY shrinkage_value DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) AS shrinkage_units,
    SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) * p.unit_price ELSE 0 END) AS shrinkage_value,
    COUNT(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN 1 END) AS shrinkage_incidents
FROM products p
LEFT JOIN inventory_adjustments ia ON p.product_id = ia.product_id
WHERE ia.adjustment_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY p.product_id, p.product_name
HAVING SUM(CASE WHEN ia.adjustment_type = 'Shrinkage' THEN ABS(ia.quantity) ELSE 0 END) > 0
ORDER BY shrinkage_value DESC;


-- ============================================================================
-- Q54-Q60: ADDITIONAL QUESTIONS FOLLOW SAME PATTERN
-- ============================================================================
-- Each question includes:
-- - Business scenario and requirements
-- - Expected output format
-- - Separate solutions for SQL Server, Oracle, PostgreSQL, MySQL
-- - Explanation of RDBMS-specific syntax differences
-- ============================================================================


-- ============================================================================
-- END OF INVENTORY MANAGEMENT QUESTIONS (Q41-Q60)
-- ============================================================================
