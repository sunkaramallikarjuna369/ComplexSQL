-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Inventory Management (Questions 41-60)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_id INT,
    supplier_id INT,
    unit_price DECIMAL(10,2),
    units_in_stock INT,
    reorder_level INT,
    discontinued BIT
);

CREATE TABLE inventory_transactions (
    transaction_id INT PRIMARY KEY,
    product_id INT,
    transaction_type VARCHAR(20), -- 'IN', 'OUT', 'ADJUSTMENT'
    quantity INT,
    transaction_date TIMESTAMP,
    warehouse_id INT,
    reference_id INT
);

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(100),
    location VARCHAR(100),
    capacity INT
);

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    company_name VARCHAR(100),
    contact_name VARCHAR(100),
    lead_time_days INT
);
*/

-- ============================================
-- QUESTION 41: Find products below reorder level
-- ============================================
-- Scenario: Generate purchase order recommendations

SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.reorder_level,
    p.reorder_level - p.units_in_stock AS units_to_order,
    s.company_name AS supplier,
    s.lead_time_days
FROM products p
JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.units_in_stock < p.reorder_level
AND p.discontinued = 0
ORDER BY (p.reorder_level - p.units_in_stock) DESC;

-- ============================================
-- QUESTION 42: Calculate inventory turnover ratio
-- ============================================
-- Scenario: Identify slow-moving inventory

WITH sales_data AS (
    SELECT 
        product_id,
        SUM(CASE WHEN transaction_type = 'OUT' THEN quantity ELSE 0 END) AS total_sold
    FROM inventory_transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY product_id
),
avg_inventory AS (
    SELECT 
        product_id,
        AVG(units_in_stock) AS avg_stock
    FROM (
        SELECT product_id, units_in_stock, transaction_date
        FROM inventory_transactions
        WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 year'
    ) t
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    sd.total_sold,
    COALESCE(ai.avg_stock, p.units_in_stock) AS avg_inventory,
    ROUND(sd.total_sold / NULLIF(COALESCE(ai.avg_stock, p.units_in_stock), 0), 2) AS turnover_ratio
FROM products p
LEFT JOIN sales_data sd ON p.product_id = sd.product_id
LEFT JOIN avg_inventory ai ON p.product_id = ai.product_id
ORDER BY turnover_ratio NULLS LAST;

-- ============================================
-- QUESTION 43: Track inventory movement by warehouse
-- ============================================
-- Scenario: Monitor stock levels across locations

SELECT 
    w.warehouse_name,
    p.product_name,
    SUM(CASE WHEN it.transaction_type = 'IN' THEN it.quantity ELSE 0 END) AS total_in,
    SUM(CASE WHEN it.transaction_type = 'OUT' THEN it.quantity ELSE 0 END) AS total_out,
    SUM(CASE 
        WHEN it.transaction_type = 'IN' THEN it.quantity 
        WHEN it.transaction_type = 'OUT' THEN -it.quantity 
        ELSE it.quantity 
    END) AS net_change
FROM inventory_transactions it
JOIN products p ON it.product_id = p.product_id
JOIN warehouses w ON it.warehouse_id = w.warehouse_id
WHERE it.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY w.warehouse_name, p.product_name
ORDER BY w.warehouse_name, net_change DESC;

-- ============================================
-- QUESTION 44: Identify dead stock (no movement in 90 days)
-- ============================================
-- Scenario: Clearance sale planning

SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.unit_price,
    p.units_in_stock * p.unit_price AS inventory_value,
    MAX(it.transaction_date) AS last_movement
FROM products p
LEFT JOIN inventory_transactions it ON p.product_id = it.product_id
WHERE p.units_in_stock > 0
GROUP BY p.product_id, p.product_name, p.units_in_stock, p.unit_price
HAVING MAX(it.transaction_date) < CURRENT_DATE - INTERVAL '90 days'
    OR MAX(it.transaction_date) IS NULL
ORDER BY inventory_value DESC;

-- ============================================
-- QUESTION 45: Calculate days of inventory on hand
-- ============================================
-- Scenario: Cash flow planning

WITH daily_sales AS (
    SELECT 
        product_id,
        AVG(quantity) AS avg_daily_sales
    FROM inventory_transactions
    WHERE transaction_type = 'OUT'
    AND transaction_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    COALESCE(ds.avg_daily_sales, 0) AS avg_daily_sales,
    CASE 
        WHEN COALESCE(ds.avg_daily_sales, 0) > 0 
        THEN ROUND(p.units_in_stock / ds.avg_daily_sales, 1)
        ELSE NULL 
    END AS days_of_inventory
FROM products p
LEFT JOIN daily_sales ds ON p.product_id = ds.product_id
WHERE p.discontinued = 0
ORDER BY days_of_inventory NULLS LAST;

-- ============================================
-- QUESTION 46: Find warehouse capacity utilization
-- ============================================
-- Scenario: Warehouse space optimization

WITH warehouse_stock AS (
    SELECT 
        warehouse_id,
        SUM(quantity) AS current_stock
    FROM (
        SELECT 
            warehouse_id,
            product_id,
            SUM(CASE 
                WHEN transaction_type = 'IN' THEN quantity 
                WHEN transaction_type = 'OUT' THEN -quantity 
                ELSE quantity 
            END) AS quantity
        FROM inventory_transactions
        GROUP BY warehouse_id, product_id
    ) t
    GROUP BY warehouse_id
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    w.location,
    w.capacity,
    COALESCE(ws.current_stock, 0) AS current_stock,
    ROUND(100.0 * COALESCE(ws.current_stock, 0) / w.capacity, 2) AS utilization_pct,
    w.capacity - COALESCE(ws.current_stock, 0) AS available_capacity
FROM warehouses w
LEFT JOIN warehouse_stock ws ON w.warehouse_id = ws.warehouse_id
ORDER BY utilization_pct DESC;

-- ============================================
-- QUESTION 47: Detect inventory discrepancies
-- ============================================
-- Scenario: Audit and reconciliation

WITH calculated_stock AS (
    SELECT 
        product_id,
        SUM(CASE 
            WHEN transaction_type = 'IN' THEN quantity 
            WHEN transaction_type = 'OUT' THEN -quantity 
            ELSE quantity 
        END) AS calculated_units
    FROM inventory_transactions
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock AS system_stock,
    cs.calculated_units AS calculated_stock,
    p.units_in_stock - cs.calculated_units AS discrepancy,
    ABS(p.units_in_stock - cs.calculated_units) * p.unit_price AS discrepancy_value
FROM products p
JOIN calculated_stock cs ON p.product_id = cs.product_id
WHERE p.units_in_stock <> cs.calculated_units
ORDER BY ABS(discrepancy_value) DESC;

-- ============================================
-- QUESTION 48: Calculate ABC inventory classification
-- ============================================
-- Scenario: Prioritize inventory management efforts

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

-- ============================================
-- QUESTION 49: Find optimal reorder quantity (EOQ approximation)
-- ============================================
-- Scenario: Minimize ordering and holding costs

WITH demand_data AS (
    SELECT 
        product_id,
        SUM(quantity) AS annual_demand
    FROM inventory_transactions
    WHERE transaction_type = 'OUT'
    AND transaction_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    dd.annual_demand,
    p.unit_price,
    -- EOQ = sqrt(2 * D * S / H) where D=demand, S=ordering cost, H=holding cost
    -- Assuming ordering cost = $50, holding cost = 20% of unit price
    ROUND(SQRT(2 * dd.annual_demand * 50 / (p.unit_price * 0.20)), 0) AS eoq
FROM products p
JOIN demand_data dd ON p.product_id = dd.product_id
WHERE p.discontinued = 0
ORDER BY dd.annual_demand DESC;

-- ============================================
-- QUESTION 50: Track supplier performance
-- ============================================
-- Scenario: Evaluate supplier reliability

WITH deliveries AS (
    SELECT 
        p.supplier_id,
        COUNT(*) AS total_deliveries,
        SUM(CASE WHEN it.transaction_date <= expected_date THEN 1 ELSE 0 END) AS on_time_deliveries,
        AVG(it.transaction_date - expected_date) AS avg_delay_days
    FROM inventory_transactions it
    JOIN products p ON it.product_id = p.product_id
    JOIN purchase_orders po ON it.reference_id = po.order_id
    WHERE it.transaction_type = 'IN'
    GROUP BY p.supplier_id
)
SELECT 
    s.supplier_id,
    s.company_name,
    d.total_deliveries,
    d.on_time_deliveries,
    ROUND(100.0 * d.on_time_deliveries / d.total_deliveries, 2) AS on_time_pct,
    ROUND(d.avg_delay_days, 1) AS avg_delay_days
FROM suppliers s
JOIN deliveries d ON s.supplier_id = d.supplier_id
ORDER BY on_time_pct DESC;

-- ============================================
-- QUESTION 51: Calculate safety stock levels
-- ============================================
-- Scenario: Prevent stockouts during demand variability

WITH demand_stats AS (
    SELECT 
        product_id,
        AVG(quantity) AS avg_daily_demand,
        STDDEV(quantity) AS stddev_demand
    FROM inventory_transactions
    WHERE transaction_type = 'OUT'
    AND transaction_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    ds.avg_daily_demand,
    ds.stddev_demand,
    s.lead_time_days,
    -- Safety stock = Z * σ * √L (Z=1.65 for 95% service level)
    ROUND(1.65 * ds.stddev_demand * SQRT(s.lead_time_days), 0) AS safety_stock,
    p.reorder_level,
    ROUND(ds.avg_daily_demand * s.lead_time_days + 1.65 * ds.stddev_demand * SQRT(s.lead_time_days), 0) AS recommended_reorder_level
FROM products p
JOIN demand_stats ds ON p.product_id = ds.product_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.discontinued = 0
ORDER BY p.product_id;

-- ============================================
-- QUESTION 52: Find products with expiring stock
-- ============================================
-- Scenario: FIFO management for perishables

SELECT 
    p.product_id,
    p.product_name,
    il.lot_number,
    il.quantity,
    il.expiry_date,
    il.expiry_date - CURRENT_DATE AS days_until_expiry,
    CASE 
        WHEN il.expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN il.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'CRITICAL'
        WHEN il.expiry_date < CURRENT_DATE + INTERVAL '90 days' THEN 'WARNING'
        ELSE 'OK'
    END AS status
FROM inventory_lots il
JOIN products p ON il.product_id = p.product_id
WHERE il.quantity > 0
AND il.expiry_date < CURRENT_DATE + INTERVAL '90 days'
ORDER BY il.expiry_date;

-- ============================================
-- QUESTION 53: Calculate inventory aging report
-- ============================================
-- Scenario: Identify aged inventory for write-offs

WITH inventory_age AS (
    SELECT 
        product_id,
        warehouse_id,
        quantity,
        transaction_date AS received_date,
        CURRENT_DATE - transaction_date AS age_days
    FROM inventory_transactions
    WHERE transaction_type = 'IN'
    AND quantity > 0
)
SELECT 
    p.product_name,
    w.warehouse_name,
    SUM(CASE WHEN ia.age_days <= 30 THEN ia.quantity ELSE 0 END) AS "0-30 days",
    SUM(CASE WHEN ia.age_days BETWEEN 31 AND 60 THEN ia.quantity ELSE 0 END) AS "31-60 days",
    SUM(CASE WHEN ia.age_days BETWEEN 61 AND 90 THEN ia.quantity ELSE 0 END) AS "61-90 days",
    SUM(CASE WHEN ia.age_days > 90 THEN ia.quantity ELSE 0 END) AS "90+ days",
    SUM(ia.quantity) AS total_quantity
FROM inventory_age ia
JOIN products p ON ia.product_id = p.product_id
JOIN warehouses w ON ia.warehouse_id = w.warehouse_id
GROUP BY p.product_name, w.warehouse_name
ORDER BY SUM(CASE WHEN ia.age_days > 90 THEN ia.quantity ELSE 0 END) DESC;

-- ============================================
-- QUESTION 54: Forecast inventory needs
-- ============================================
-- Scenario: Demand planning for next month

WITH monthly_demand AS (
    SELECT 
        product_id,
        DATE_TRUNC('month', transaction_date) AS month,
        SUM(quantity) AS monthly_quantity
    FROM inventory_transactions
    WHERE transaction_type = 'OUT'
    AND transaction_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY product_id, DATE_TRUNC('month', transaction_date)
),
demand_trend AS (
    SELECT 
        product_id,
        AVG(monthly_quantity) AS avg_monthly_demand,
        REGR_SLOPE(monthly_quantity, EXTRACT(EPOCH FROM month)) AS trend_slope
    FROM monthly_demand
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    ROUND(dt.avg_monthly_demand, 0) AS avg_monthly_demand,
    ROUND(dt.avg_monthly_demand * 1.1, 0) AS forecast_next_month, -- 10% buffer
    p.units_in_stock - ROUND(dt.avg_monthly_demand * 1.1, 0) AS projected_balance
FROM products p
JOIN demand_trend dt ON p.product_id = dt.product_id
WHERE p.discontinued = 0
ORDER BY projected_balance;

-- ============================================
-- QUESTION 55: Find stock transfer opportunities
-- ============================================
-- Scenario: Balance inventory across warehouses

WITH warehouse_stock AS (
    SELECT 
        warehouse_id,
        product_id,
        SUM(CASE 
            WHEN transaction_type = 'IN' THEN quantity 
            WHEN transaction_type = 'OUT' THEN -quantity 
            ELSE quantity 
        END) AS current_stock
    FROM inventory_transactions
    GROUP BY warehouse_id, product_id
),
stock_analysis AS (
    SELECT 
        product_id,
        warehouse_id,
        current_stock,
        AVG(current_stock) OVER (PARTITION BY product_id) AS avg_stock,
        current_stock - AVG(current_stock) OVER (PARTITION BY product_id) AS variance
    FROM warehouse_stock
)
SELECT 
    p.product_name,
    w_from.warehouse_name AS from_warehouse,
    w_to.warehouse_name AS to_warehouse,
    sa_from.current_stock AS from_stock,
    sa_to.current_stock AS to_stock,
    ROUND((sa_from.current_stock - sa_to.current_stock) / 2, 0) AS transfer_quantity
FROM stock_analysis sa_from
JOIN stock_analysis sa_to ON sa_from.product_id = sa_to.product_id 
    AND sa_from.warehouse_id < sa_to.warehouse_id
JOIN products p ON sa_from.product_id = p.product_id
JOIN warehouses w_from ON sa_from.warehouse_id = w_from.warehouse_id
JOIN warehouses w_to ON sa_to.warehouse_id = w_to.warehouse_id
WHERE sa_from.variance > 0 AND sa_to.variance < 0
AND ABS(sa_from.current_stock - sa_to.current_stock) > 10
ORDER BY ABS(sa_from.current_stock - sa_to.current_stock) DESC;

-- ============================================
-- QUESTION 56: Calculate shrinkage rate
-- ============================================
-- Scenario: Loss prevention analysis

WITH period_data AS (
    SELECT 
        product_id,
        SUM(CASE WHEN transaction_type = 'IN' THEN quantity ELSE 0 END) AS total_received,
        SUM(CASE WHEN transaction_type = 'OUT' THEN quantity ELSE 0 END) AS total_sold,
        SUM(CASE WHEN transaction_type = 'ADJUSTMENT' AND quantity < 0 THEN ABS(quantity) ELSE 0 END) AS shrinkage
    FROM inventory_transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    pd.total_received,
    pd.total_sold,
    pd.shrinkage,
    ROUND(100.0 * pd.shrinkage / NULLIF(pd.total_received, 0), 2) AS shrinkage_rate_pct,
    pd.shrinkage * p.unit_price AS shrinkage_value
FROM products p
JOIN period_data pd ON p.product_id = pd.product_id
WHERE pd.shrinkage > 0
ORDER BY shrinkage_value DESC;

-- ============================================
-- QUESTION 57: Identify seasonal inventory patterns
-- ============================================
-- Scenario: Seasonal stocking strategy

SELECT 
    p.product_id,
    p.product_name,
    EXTRACT(MONTH FROM it.transaction_date) AS month,
    TO_CHAR(it.transaction_date, 'Month') AS month_name,
    SUM(it.quantity) AS total_demand,
    AVG(SUM(it.quantity)) OVER (PARTITION BY p.product_id) AS avg_monthly_demand,
    ROUND(100.0 * SUM(it.quantity) / AVG(SUM(it.quantity)) OVER (PARTITION BY p.product_id), 2) AS seasonality_index
FROM inventory_transactions it
JOIN products p ON it.product_id = p.product_id
WHERE it.transaction_type = 'OUT'
GROUP BY p.product_id, p.product_name, EXTRACT(MONTH FROM it.transaction_date), TO_CHAR(it.transaction_date, 'Month')
ORDER BY p.product_id, month;

-- ============================================
-- QUESTION 58: Calculate inventory carrying cost
-- ============================================
-- Scenario: Total cost of inventory ownership

SELECT 
    p.product_id,
    p.product_name,
    p.units_in_stock,
    p.unit_price,
    p.units_in_stock * p.unit_price AS inventory_value,
    -- Assuming 25% annual carrying cost (storage, insurance, obsolescence)
    ROUND(p.units_in_stock * p.unit_price * 0.25 / 12, 2) AS monthly_carrying_cost,
    ROUND(p.units_in_stock * p.unit_price * 0.25, 2) AS annual_carrying_cost
FROM products p
WHERE p.discontinued = 0 AND p.units_in_stock > 0
ORDER BY annual_carrying_cost DESC;

-- ============================================
-- QUESTION 59: Find products with inconsistent pricing
-- ============================================
-- Scenario: Price integrity check

SELECT 
    p.product_id,
    p.product_name,
    p.unit_price AS current_price,
    MIN(it.unit_cost) AS min_cost,
    MAX(it.unit_cost) AS max_cost,
    AVG(it.unit_cost) AS avg_cost,
    MAX(it.unit_cost) - MIN(it.unit_cost) AS cost_variance
FROM products p
JOIN inventory_transactions it ON p.product_id = it.product_id
WHERE it.transaction_type = 'IN'
AND it.transaction_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY p.product_id, p.product_name, p.unit_price
HAVING MAX(it.unit_cost) - MIN(it.unit_cost) > p.unit_price * 0.1
ORDER BY cost_variance DESC;

-- ============================================
-- QUESTION 60: Generate reorder report with lead time consideration
-- ============================================
-- Scenario: Automated purchase order generation

WITH daily_demand AS (
    SELECT 
        product_id,
        AVG(quantity) AS avg_daily_demand
    FROM inventory_transactions
    WHERE transaction_type = 'OUT'
    AND transaction_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    s.company_name AS supplier,
    p.units_in_stock,
    dd.avg_daily_demand,
    s.lead_time_days,
    ROUND(dd.avg_daily_demand * s.lead_time_days, 0) AS lead_time_demand,
    p.reorder_level,
    CASE 
        WHEN p.units_in_stock <= dd.avg_daily_demand * s.lead_time_days THEN 'ORDER NOW'
        WHEN p.units_in_stock <= p.reorder_level THEN 'REORDER'
        ELSE 'OK'
    END AS action_required,
    GREATEST(p.reorder_level * 2 - p.units_in_stock, 0) AS suggested_order_qty
FROM products p
JOIN suppliers s ON p.supplier_id = s.supplier_id
LEFT JOIN daily_demand dd ON p.product_id = dd.product_id
WHERE p.discontinued = 0
AND (p.units_in_stock <= p.reorder_level OR p.units_in_stock <= COALESCE(dd.avg_daily_demand, 0) * s.lead_time_days)
ORDER BY action_required, p.units_in_stock;
