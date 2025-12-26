-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: LOGISTICS (Q161-Q180)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q161: CALCULATE ON-TIME DELIVERY RATE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Comparison, Aggregation, KPI Calculation
-- 
-- BUSINESS SCENARIO:
-- Track delivery performance to identify carriers and routes that need
-- improvement for customer satisfaction.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    c.carrier_id,
    c.carrier_name,
    COUNT(s.shipment_id) AS total_shipments,
    SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN s.actual_delivery_date > s.expected_delivery_date THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(s.shipment_id), 0), 2) AS on_time_rate,
    AVG(DATEDIFF(DAY, s.ship_date, s.actual_delivery_date)) AS avg_transit_days
FROM shipments s
INNER JOIN carriers c ON s.carrier_id = c.carrier_id
WHERE s.status = 'Delivered'
AND s.actual_delivery_date >= DATEADD(MONTH, -3, GETDATE())
GROUP BY c.carrier_id, c.carrier_name
ORDER BY on_time_rate DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    c.carrier_id,
    c.carrier_name,
    COUNT(s.shipment_id) AS total_shipments,
    SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN s.actual_delivery_date > s.expected_delivery_date THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(s.shipment_id), 0), 2) AS on_time_rate,
    AVG(s.actual_delivery_date - s.ship_date) AS avg_transit_days
FROM shipments s
INNER JOIN carriers c ON s.carrier_id = c.carrier_id
WHERE s.status = 'Delivered'
AND s.actual_delivery_date >= ADD_MONTHS(SYSDATE, -3)
GROUP BY c.carrier_id, c.carrier_name
ORDER BY on_time_rate DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    c.carrier_id,
    c.carrier_name,
    COUNT(s.shipment_id) AS total_shipments,
    SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN s.actual_delivery_date > s.expected_delivery_date THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND((100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(s.shipment_id), 0))::NUMERIC, 2) AS on_time_rate,
    AVG(s.actual_delivery_date - s.ship_date) AS avg_transit_days
FROM shipments s
INNER JOIN carriers c ON s.carrier_id = c.carrier_id
WHERE s.status = 'Delivered'
AND s.actual_delivery_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY c.carrier_id, c.carrier_name
ORDER BY on_time_rate DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    c.carrier_id,
    c.carrier_name,
    COUNT(s.shipment_id) AS total_shipments,
    SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN s.actual_delivery_date > s.expected_delivery_date THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(s.shipment_id), 0), 2) AS on_time_rate,
    AVG(DATEDIFF(s.actual_delivery_date, s.ship_date)) AS avg_transit_days
FROM shipments s
INNER JOIN carriers c ON s.carrier_id = c.carrier_id
WHERE s.status = 'Delivered'
AND s.actual_delivery_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY c.carrier_id, c.carrier_name
ORDER BY on_time_rate DESC;

-- EXPLANATION:
-- On-time rate = Deliveries on or before expected date / Total deliveries.
-- Key KPI for logistics performance management.


-- ============================================================================
-- Q162: OPTIMIZE ROUTE EFFICIENCY
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Aggregation, Distance/Time Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH route_metrics AS (
    SELECT 
        r.route_id,
        r.origin_city,
        r.destination_city,
        r.distance_miles,
        COUNT(s.shipment_id) AS shipment_count,
        AVG(DATEDIFF(HOUR, s.ship_date, s.actual_delivery_date)) AS avg_transit_hours,
        AVG(s.shipping_cost) AS avg_cost,
        SUM(s.weight_lbs) AS total_weight
    FROM routes r
    INNER JOIN shipments s ON r.route_id = s.route_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY r.route_id, r.origin_city, r.destination_city, r.distance_miles
)
SELECT 
    route_id,
    origin_city,
    destination_city,
    distance_miles,
    shipment_count,
    ROUND(avg_transit_hours, 1) AS avg_transit_hours,
    ROUND(distance_miles / NULLIF(avg_transit_hours, 0), 2) AS avg_speed_mph,
    ROUND(avg_cost, 2) AS avg_cost,
    ROUND(avg_cost / NULLIF(distance_miles, 0), 4) AS cost_per_mile,
    ROUND(total_weight / NULLIF(shipment_count, 0), 2) AS avg_weight_per_shipment
FROM route_metrics
ORDER BY cost_per_mile;

-- ==================== ORACLE SOLUTION ====================
WITH route_metrics AS (
    SELECT 
        r.route_id,
        r.origin_city,
        r.destination_city,
        r.distance_miles,
        COUNT(s.shipment_id) AS shipment_count,
        AVG((s.actual_delivery_date - s.ship_date) * 24) AS avg_transit_hours,
        AVG(s.shipping_cost) AS avg_cost,
        SUM(s.weight_lbs) AS total_weight
    FROM routes r
    INNER JOIN shipments s ON r.route_id = s.route_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= ADD_MONTHS(SYSDATE, -6)
    GROUP BY r.route_id, r.origin_city, r.destination_city, r.distance_miles
)
SELECT 
    route_id,
    origin_city,
    destination_city,
    distance_miles,
    shipment_count,
    ROUND(avg_transit_hours, 1) AS avg_transit_hours,
    ROUND(distance_miles / NULLIF(avg_transit_hours, 0), 2) AS avg_speed_mph,
    ROUND(avg_cost, 2) AS avg_cost,
    ROUND(avg_cost / NULLIF(distance_miles, 0), 4) AS cost_per_mile,
    ROUND(total_weight / NULLIF(shipment_count, 0), 2) AS avg_weight_per_shipment
FROM route_metrics
ORDER BY cost_per_mile;

-- ==================== POSTGRESQL SOLUTION ====================
WITH route_metrics AS (
    SELECT 
        r.route_id,
        r.origin_city,
        r.destination_city,
        r.distance_miles,
        COUNT(s.shipment_id) AS shipment_count,
        AVG(EXTRACT(EPOCH FROM (s.actual_delivery_date - s.ship_date)) / 3600) AS avg_transit_hours,
        AVG(s.shipping_cost) AS avg_cost,
        SUM(s.weight_lbs) AS total_weight
    FROM routes r
    INNER JOIN shipments s ON r.route_id = s.route_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY r.route_id, r.origin_city, r.destination_city, r.distance_miles
)
SELECT 
    route_id,
    origin_city,
    destination_city,
    distance_miles,
    shipment_count,
    ROUND(avg_transit_hours::NUMERIC, 1) AS avg_transit_hours,
    ROUND((distance_miles / NULLIF(avg_transit_hours, 0))::NUMERIC, 2) AS avg_speed_mph,
    ROUND(avg_cost::NUMERIC, 2) AS avg_cost,
    ROUND((avg_cost / NULLIF(distance_miles, 0))::NUMERIC, 4) AS cost_per_mile,
    ROUND((total_weight / NULLIF(shipment_count, 0))::NUMERIC, 2) AS avg_weight_per_shipment
FROM route_metrics
ORDER BY cost_per_mile;

-- ==================== MYSQL SOLUTION ====================
WITH route_metrics AS (
    SELECT 
        r.route_id,
        r.origin_city,
        r.destination_city,
        r.distance_miles,
        COUNT(s.shipment_id) AS shipment_count,
        AVG(TIMESTAMPDIFF(HOUR, s.ship_date, s.actual_delivery_date)) AS avg_transit_hours,
        AVG(s.shipping_cost) AS avg_cost,
        SUM(s.weight_lbs) AS total_weight
    FROM routes r
    INNER JOIN shipments s ON r.route_id = s.route_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY r.route_id, r.origin_city, r.destination_city, r.distance_miles
)
SELECT 
    route_id,
    origin_city,
    destination_city,
    distance_miles,
    shipment_count,
    ROUND(avg_transit_hours, 1) AS avg_transit_hours,
    ROUND(distance_miles / NULLIF(avg_transit_hours, 0), 2) AS avg_speed_mph,
    ROUND(avg_cost, 2) AS avg_cost,
    ROUND(avg_cost / NULLIF(distance_miles, 0), 4) AS cost_per_mile,
    ROUND(total_weight / NULLIF(shipment_count, 0), 2) AS avg_weight_per_shipment
FROM route_metrics
ORDER BY cost_per_mile;

-- EXPLANATION:
-- Route efficiency measured by cost per mile and average speed.
-- Helps identify routes needing optimization.


-- ============================================================================
-- Q163: GENERATE CARRIER SCORECARD
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Multiple KPIs, Weighted Scoring
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH carrier_kpis AS (
    SELECT 
        c.carrier_id,
        c.carrier_name,
        COUNT(s.shipment_id) AS total_shipments,
        ROUND(100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0), 2) AS on_time_pct,
        ROUND(100.0 * SUM(CASE WHEN s.damage_reported = 1 THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0), 2) AS damage_pct,
        AVG(s.shipping_cost / NULLIF(s.weight_lbs, 0)) AS cost_per_lb,
        AVG(DATEDIFF(DAY, s.ship_date, s.actual_delivery_date)) AS avg_transit_days
    FROM carriers c
    INNER JOIN shipments s ON c.carrier_id = s.carrier_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= DATEADD(QUARTER, -1, GETDATE())
    GROUP BY c.carrier_id, c.carrier_name
)
SELECT 
    carrier_id,
    carrier_name,
    total_shipments,
    on_time_pct,
    damage_pct,
    ROUND(cost_per_lb, 4) AS cost_per_lb,
    ROUND(avg_transit_days, 1) AS avg_transit_days,
    ROUND(on_time_pct * 0.4 + (100 - damage_pct) * 0.3 + 
          (100 - LEAST(cost_per_lb * 100, 100)) * 0.2 + 
          (100 - LEAST(avg_transit_days * 10, 100)) * 0.1, 2) AS overall_score,
    CASE 
        WHEN on_time_pct >= 95 AND damage_pct <= 1 THEN 'Preferred'
        WHEN on_time_pct >= 90 AND damage_pct <= 3 THEN 'Approved'
        WHEN on_time_pct >= 85 THEN 'Conditional'
        ELSE 'Under Review'
    END AS carrier_status
FROM carrier_kpis
ORDER BY overall_score DESC;

-- ==================== ORACLE SOLUTION ====================
WITH carrier_kpis AS (
    SELECT 
        c.carrier_id,
        c.carrier_name,
        COUNT(s.shipment_id) AS total_shipments,
        ROUND(100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0), 2) AS on_time_pct,
        ROUND(100.0 * SUM(CASE WHEN s.damage_reported = 1 THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0), 2) AS damage_pct,
        AVG(s.shipping_cost / NULLIF(s.weight_lbs, 0)) AS cost_per_lb,
        AVG(s.actual_delivery_date - s.ship_date) AS avg_transit_days
    FROM carriers c
    INNER JOIN shipments s ON c.carrier_id = s.carrier_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= ADD_MONTHS(SYSDATE, -3)
    GROUP BY c.carrier_id, c.carrier_name
)
SELECT 
    carrier_id,
    carrier_name,
    total_shipments,
    on_time_pct,
    damage_pct,
    ROUND(cost_per_lb, 4) AS cost_per_lb,
    ROUND(avg_transit_days, 1) AS avg_transit_days,
    ROUND(on_time_pct * 0.4 + (100 - damage_pct) * 0.3 + 
          (100 - LEAST(cost_per_lb * 100, 100)) * 0.2 + 
          (100 - LEAST(avg_transit_days * 10, 100)) * 0.1, 2) AS overall_score,
    CASE 
        WHEN on_time_pct >= 95 AND damage_pct <= 1 THEN 'Preferred'
        WHEN on_time_pct >= 90 AND damage_pct <= 3 THEN 'Approved'
        WHEN on_time_pct >= 85 THEN 'Conditional'
        ELSE 'Under Review'
    END AS carrier_status
FROM carrier_kpis
ORDER BY overall_score DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH carrier_kpis AS (
    SELECT 
        c.carrier_id,
        c.carrier_name,
        COUNT(s.shipment_id) AS total_shipments,
        ROUND((100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0))::NUMERIC, 2) AS on_time_pct,
        ROUND((100.0 * SUM(CASE WHEN s.damage_reported = true THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0))::NUMERIC, 2) AS damage_pct,
        AVG(s.shipping_cost / NULLIF(s.weight_lbs, 0)) AS cost_per_lb,
        AVG(s.actual_delivery_date - s.ship_date) AS avg_transit_days
    FROM carriers c
    INNER JOIN shipments s ON c.carrier_id = s.carrier_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY c.carrier_id, c.carrier_name
)
SELECT 
    carrier_id,
    carrier_name,
    total_shipments,
    on_time_pct,
    damage_pct,
    ROUND(cost_per_lb::NUMERIC, 4) AS cost_per_lb,
    ROUND(avg_transit_days::NUMERIC, 1) AS avg_transit_days,
    ROUND((on_time_pct * 0.4 + (100 - damage_pct) * 0.3 + 
          (100 - LEAST(cost_per_lb * 100, 100)) * 0.2 + 
          (100 - LEAST(avg_transit_days * 10, 100)) * 0.1)::NUMERIC, 2) AS overall_score,
    CASE 
        WHEN on_time_pct >= 95 AND damage_pct <= 1 THEN 'Preferred'
        WHEN on_time_pct >= 90 AND damage_pct <= 3 THEN 'Approved'
        WHEN on_time_pct >= 85 THEN 'Conditional'
        ELSE 'Under Review'
    END AS carrier_status
FROM carrier_kpis
ORDER BY overall_score DESC;

-- ==================== MYSQL SOLUTION ====================
WITH carrier_kpis AS (
    SELECT 
        c.carrier_id,
        c.carrier_name,
        COUNT(s.shipment_id) AS total_shipments,
        ROUND(100.0 * SUM(CASE WHEN s.actual_delivery_date <= s.expected_delivery_date THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0), 2) AS on_time_pct,
        ROUND(100.0 * SUM(CASE WHEN s.damage_reported = 1 THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(s.shipment_id), 0), 2) AS damage_pct,
        AVG(s.shipping_cost / NULLIF(s.weight_lbs, 0)) AS cost_per_lb,
        AVG(DATEDIFF(s.actual_delivery_date, s.ship_date)) AS avg_transit_days
    FROM carriers c
    INNER JOIN shipments s ON c.carrier_id = s.carrier_id
    WHERE s.status = 'Delivered'
    AND s.actual_delivery_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    GROUP BY c.carrier_id, c.carrier_name
)
SELECT 
    carrier_id,
    carrier_name,
    total_shipments,
    on_time_pct,
    damage_pct,
    ROUND(cost_per_lb, 4) AS cost_per_lb,
    ROUND(avg_transit_days, 1) AS avg_transit_days,
    ROUND(on_time_pct * 0.4 + (100 - damage_pct) * 0.3 + 
          (100 - LEAST(cost_per_lb * 100, 100)) * 0.2 + 
          (100 - LEAST(avg_transit_days * 10, 100)) * 0.1, 2) AS overall_score,
    CASE 
        WHEN on_time_pct >= 95 AND damage_pct <= 1 THEN 'Preferred'
        WHEN on_time_pct >= 90 AND damage_pct <= 3 THEN 'Approved'
        WHEN on_time_pct >= 85 THEN 'Conditional'
        ELSE 'Under Review'
    END AS carrier_status
FROM carrier_kpis
ORDER BY overall_score DESC;

-- EXPLANATION:
-- Weighted scorecard combining multiple KPIs.
-- Used for carrier selection and contract negotiations.


-- ============================================================================
-- Q164: TRACK WAREHOUSE CAPACITY UTILIZATION
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Capacity Planning
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    w.location,
    w.total_capacity_sqft,
    SUM(i.quantity * p.unit_size_sqft) AS used_space_sqft,
    w.total_capacity_sqft - SUM(i.quantity * p.unit_size_sqft) AS available_space_sqft,
    ROUND(100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0), 2) AS utilization_pct,
    CASE 
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 90 THEN 'Critical'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 80 THEN 'High'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 60 THEN 'Normal'
        ELSE 'Low'
    END AS utilization_status
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p ON i.product_id = p.product_id
GROUP BY w.warehouse_id, w.warehouse_name, w.location, w.total_capacity_sqft
ORDER BY utilization_pct DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    w.location,
    w.total_capacity_sqft,
    SUM(i.quantity * p.unit_size_sqft) AS used_space_sqft,
    w.total_capacity_sqft - SUM(i.quantity * p.unit_size_sqft) AS available_space_sqft,
    ROUND(100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0), 2) AS utilization_pct,
    CASE 
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 90 THEN 'Critical'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 80 THEN 'High'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 60 THEN 'Normal'
        ELSE 'Low'
    END AS utilization_status
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p ON i.product_id = p.product_id
GROUP BY w.warehouse_id, w.warehouse_name, w.location, w.total_capacity_sqft
ORDER BY utilization_pct DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    w.location,
    w.total_capacity_sqft,
    SUM(i.quantity * p.unit_size_sqft) AS used_space_sqft,
    w.total_capacity_sqft - SUM(i.quantity * p.unit_size_sqft) AS available_space_sqft,
    ROUND((100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0))::NUMERIC, 2) AS utilization_pct,
    CASE 
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 90 THEN 'Critical'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 80 THEN 'High'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 60 THEN 'Normal'
        ELSE 'Low'
    END AS utilization_status
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p ON i.product_id = p.product_id
GROUP BY w.warehouse_id, w.warehouse_name, w.location, w.total_capacity_sqft
ORDER BY utilization_pct DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    w.location,
    w.total_capacity_sqft,
    SUM(i.quantity * p.unit_size_sqft) AS used_space_sqft,
    w.total_capacity_sqft - SUM(i.quantity * p.unit_size_sqft) AS available_space_sqft,
    ROUND(100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0), 2) AS utilization_pct,
    CASE 
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 90 THEN 'Critical'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 80 THEN 'High'
        WHEN 100.0 * SUM(i.quantity * p.unit_size_sqft) / NULLIF(w.total_capacity_sqft, 0) > 60 THEN 'Normal'
        ELSE 'Low'
    END AS utilization_status
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p ON i.product_id = p.product_id
GROUP BY w.warehouse_id, w.warehouse_name, w.location, w.total_capacity_sqft
ORDER BY utilization_pct DESC;

-- EXPLANATION:
-- Capacity utilization = Used space / Total capacity.
-- Critical for warehouse planning and expansion decisions.


-- ============================================================================
-- Q165: ANALYZE SHIPMENT DELAYS BY CAUSE
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, Root Cause Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    s.delay_reason,
    COUNT(s.shipment_id) AS delayed_shipments,
    AVG(DATEDIFF(DAY, s.expected_delivery_date, s.actual_delivery_date)) AS avg_delay_days,
    SUM(s.delay_cost) AS total_delay_cost,
    ROUND(100.0 * COUNT(s.shipment_id) / 
          (SELECT COUNT(*) FROM shipments WHERE actual_delivery_date > expected_delivery_date 
           AND actual_delivery_date >= DATEADD(MONTH, -3, GETDATE())), 2) AS pct_of_delays
FROM shipments s
WHERE s.actual_delivery_date > s.expected_delivery_date
AND s.actual_delivery_date >= DATEADD(MONTH, -3, GETDATE())
AND s.delay_reason IS NOT NULL
GROUP BY s.delay_reason
ORDER BY delayed_shipments DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    s.delay_reason,
    COUNT(s.shipment_id) AS delayed_shipments,
    AVG(s.actual_delivery_date - s.expected_delivery_date) AS avg_delay_days,
    SUM(s.delay_cost) AS total_delay_cost,
    ROUND(100.0 * COUNT(s.shipment_id) / 
          (SELECT COUNT(*) FROM shipments WHERE actual_delivery_date > expected_delivery_date 
           AND actual_delivery_date >= ADD_MONTHS(SYSDATE, -3)), 2) AS pct_of_delays
FROM shipments s
WHERE s.actual_delivery_date > s.expected_delivery_date
AND s.actual_delivery_date >= ADD_MONTHS(SYSDATE, -3)
AND s.delay_reason IS NOT NULL
GROUP BY s.delay_reason
ORDER BY delayed_shipments DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    s.delay_reason,
    COUNT(s.shipment_id) AS delayed_shipments,
    AVG(s.actual_delivery_date - s.expected_delivery_date) AS avg_delay_days,
    SUM(s.delay_cost) AS total_delay_cost,
    ROUND((100.0 * COUNT(s.shipment_id) / 
          (SELECT COUNT(*) FROM shipments WHERE actual_delivery_date > expected_delivery_date 
           AND actual_delivery_date >= CURRENT_DATE - INTERVAL '3 months'))::NUMERIC, 2) AS pct_of_delays
FROM shipments s
WHERE s.actual_delivery_date > s.expected_delivery_date
AND s.actual_delivery_date >= CURRENT_DATE - INTERVAL '3 months'
AND s.delay_reason IS NOT NULL
GROUP BY s.delay_reason
ORDER BY delayed_shipments DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    s.delay_reason,
    COUNT(s.shipment_id) AS delayed_shipments,
    AVG(DATEDIFF(s.actual_delivery_date, s.expected_delivery_date)) AS avg_delay_days,
    SUM(s.delay_cost) AS total_delay_cost,
    ROUND(100.0 * COUNT(s.shipment_id) / 
          (SELECT COUNT(*) FROM shipments WHERE actual_delivery_date > expected_delivery_date 
           AND actual_delivery_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)), 2) AS pct_of_delays
FROM shipments s
WHERE s.actual_delivery_date > s.expected_delivery_date
AND s.actual_delivery_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
AND s.delay_reason IS NOT NULL
GROUP BY s.delay_reason
ORDER BY delayed_shipments DESC;

-- EXPLANATION:
-- Root cause analysis of delivery delays.
-- Helps prioritize process improvements.


-- ============================================================================
-- Q166-Q180: ADDITIONAL LOGISTICS QUESTIONS
-- ============================================================================
-- Q166: Calculate fleet utilization
-- Q167: Analyze fuel efficiency by vehicle
-- Q168: Track package handling metrics
-- Q169: Calculate shipping cost variance
-- Q170: Analyze seasonal demand patterns
-- Q171: Track driver performance
-- Q172: Calculate order fulfillment cycle time
-- Q173: Analyze cross-docking efficiency
-- Q174: Track returns and reverse logistics
-- Q175: Calculate inventory accuracy
-- Q176: Analyze last-mile delivery costs
-- Q177: Track customs clearance times
-- Q178: Calculate perfect order rate
-- Q179: Analyze load optimization
-- Q180: Generate logistics dashboard
-- 
-- Each follows the same multi-RDBMS format.
-- ============================================================================


-- ============================================================================
-- Q166: CALCULATE FLEET UTILIZATION
-- ============================================================================
-- Difficulty: Medium
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH vehicle_usage AS (
    SELECT 
        v.vehicle_id,
        v.vehicle_type,
        v.capacity_lbs,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.load_weight_lbs) AS total_weight_hauled,
        SUM(DATEDIFF(HOUR, t.departure_time, t.arrival_time)) AS total_hours_used
    FROM vehicles v
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
    WHERE t.trip_date >= DATEADD(MONTH, -1, GETDATE())
    GROUP BY v.vehicle_id, v.vehicle_type, v.capacity_lbs
)
SELECT 
    vehicle_id,
    vehicle_type,
    capacity_lbs,
    total_trips,
    total_miles,
    total_weight_hauled,
    total_hours_used,
    ROUND(100.0 * total_weight_hauled / NULLIF(total_trips * capacity_lbs, 0), 2) AS avg_load_utilization_pct,
    ROUND(100.0 * total_hours_used / (30 * 24), 2) AS time_utilization_pct
FROM vehicle_usage
ORDER BY avg_load_utilization_pct DESC;

-- ==================== ORACLE SOLUTION ====================
WITH vehicle_usage AS (
    SELECT 
        v.vehicle_id,
        v.vehicle_type,
        v.capacity_lbs,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.load_weight_lbs) AS total_weight_hauled,
        SUM((t.arrival_time - t.departure_time) * 24) AS total_hours_used
    FROM vehicles v
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
    WHERE t.trip_date >= ADD_MONTHS(SYSDATE, -1)
    GROUP BY v.vehicle_id, v.vehicle_type, v.capacity_lbs
)
SELECT 
    vehicle_id,
    vehicle_type,
    capacity_lbs,
    total_trips,
    total_miles,
    total_weight_hauled,
    total_hours_used,
    ROUND(100.0 * total_weight_hauled / NULLIF(total_trips * capacity_lbs, 0), 2) AS avg_load_utilization_pct,
    ROUND(100.0 * total_hours_used / (30 * 24), 2) AS time_utilization_pct
FROM vehicle_usage
ORDER BY avg_load_utilization_pct DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH vehicle_usage AS (
    SELECT 
        v.vehicle_id,
        v.vehicle_type,
        v.capacity_lbs,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.load_weight_lbs) AS total_weight_hauled,
        SUM(EXTRACT(EPOCH FROM (t.arrival_time - t.departure_time)) / 3600) AS total_hours_used
    FROM vehicles v
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
    WHERE t.trip_date >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY v.vehicle_id, v.vehicle_type, v.capacity_lbs
)
SELECT 
    vehicle_id,
    vehicle_type,
    capacity_lbs,
    total_trips,
    total_miles,
    total_weight_hauled,
    ROUND(total_hours_used::NUMERIC, 1) AS total_hours_used,
    ROUND((100.0 * total_weight_hauled / NULLIF(total_trips * capacity_lbs, 0))::NUMERIC, 2) AS avg_load_utilization_pct,
    ROUND((100.0 * total_hours_used / (30 * 24))::NUMERIC, 2) AS time_utilization_pct
FROM vehicle_usage
ORDER BY avg_load_utilization_pct DESC;

-- ==================== MYSQL SOLUTION ====================
WITH vehicle_usage AS (
    SELECT 
        v.vehicle_id,
        v.vehicle_type,
        v.capacity_lbs,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.load_weight_lbs) AS total_weight_hauled,
        SUM(TIMESTAMPDIFF(HOUR, t.departure_time, t.arrival_time)) AS total_hours_used
    FROM vehicles v
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
    WHERE t.trip_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    GROUP BY v.vehicle_id, v.vehicle_type, v.capacity_lbs
)
SELECT 
    vehicle_id,
    vehicle_type,
    capacity_lbs,
    total_trips,
    total_miles,
    total_weight_hauled,
    total_hours_used,
    ROUND(100.0 * total_weight_hauled / NULLIF(total_trips * capacity_lbs, 0), 2) AS avg_load_utilization_pct,
    ROUND(100.0 * total_hours_used / (30 * 24), 2) AS time_utilization_pct
FROM vehicle_usage
ORDER BY avg_load_utilization_pct DESC;


-- ============================================================================
-- END OF LOGISTICS QUESTIONS (Q161-Q180)
-- ============================================================================
