-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: Logistics (Questions 161-180)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY,
    order_id INT,
    origin_warehouse_id INT,
    destination_address_id INT,
    carrier_id INT,
    ship_date TIMESTAMP,
    expected_delivery DATE,
    actual_delivery TIMESTAMP,
    status VARCHAR(30),
    tracking_number VARCHAR(50),
    weight DECIMAL(10,2),
    dimensions VARCHAR(50)
);

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    capacity_sqft INT,
    current_utilization DECIMAL(5,2)
);

CREATE TABLE carriers (
    carrier_id INT PRIMARY KEY,
    carrier_name VARCHAR(100),
    service_type VARCHAR(50),
    base_rate DECIMAL(10,2),
    per_mile_rate DECIMAL(6,4)
);

CREATE TABLE routes (
    route_id INT PRIMARY KEY,
    origin_id INT,
    destination_id INT,
    distance_miles DECIMAL(10,2),
    estimated_hours DECIMAL(6,2),
    toll_cost DECIMAL(8,2)
);

CREATE TABLE vehicles (
    vehicle_id INT PRIMARY KEY,
    vehicle_type VARCHAR(50),
    capacity_weight DECIMAL(10,2),
    capacity_volume DECIMAL(10,2),
    fuel_efficiency DECIMAL(5,2),
    status VARCHAR(20)
);

CREATE TABLE drivers (
    driver_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    license_type VARCHAR(20),
    hire_date DATE,
    status VARCHAR(20)
);
*/

-- ============================================
-- QUESTION 161: Calculate on-time delivery rate
-- ============================================
-- Scenario: Carrier performance evaluation

SELECT 
    c.carrier_id,
    c.carrier_name,
    COUNT(*) AS total_deliveries,
    COUNT(CASE WHEN s.actual_delivery <= s.expected_delivery THEN 1 END) AS on_time,
    COUNT(CASE WHEN s.actual_delivery > s.expected_delivery THEN 1 END) AS late,
    ROUND(100.0 * COUNT(CASE WHEN s.actual_delivery <= s.expected_delivery THEN 1 END) / COUNT(*), 2) AS on_time_pct,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.actual_delivery - s.ship_date)) / 3600), 2) AS avg_delivery_hours
FROM carriers c
JOIN shipments s ON c.carrier_id = s.carrier_id
WHERE s.actual_delivery IS NOT NULL
AND s.ship_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c.carrier_id, c.carrier_name
ORDER BY on_time_pct DESC;

-- ============================================
-- QUESTION 162: Optimize warehouse allocation
-- ============================================
-- Scenario: Inventory distribution planning

WITH warehouse_demand AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        w.city,
        COUNT(DISTINCT s.shipment_id) AS shipments_originated,
        SUM(s.weight) AS total_weight_shipped,
        w.capacity_sqft,
        w.current_utilization
    FROM warehouses w
    LEFT JOIN shipments s ON w.warehouse_id = s.origin_warehouse_id
    WHERE s.ship_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY w.warehouse_id, w.warehouse_name, w.city, w.capacity_sqft, w.current_utilization
)
SELECT 
    warehouse_id,
    warehouse_name,
    city,
    shipments_originated,
    total_weight_shipped,
    capacity_sqft,
    current_utilization,
    CASE 
        WHEN current_utilization > 90 THEN 'CRITICAL - EXPAND'
        WHEN current_utilization > 75 THEN 'HIGH - MONITOR'
        WHEN current_utilization < 40 THEN 'LOW - CONSOLIDATE'
        ELSE 'OPTIMAL'
    END AS utilization_status
FROM warehouse_demand
ORDER BY current_utilization DESC;

-- ============================================
-- QUESTION 163: Calculate shipping cost analysis
-- ============================================
-- Scenario: Cost optimization

SELECT 
    c.carrier_name,
    c.service_type,
    COUNT(*) AS shipment_count,
    SUM(s.weight) AS total_weight,
    SUM(r.distance_miles) AS total_miles,
    SUM(c.base_rate + (r.distance_miles * c.per_mile_rate) + r.toll_cost) AS total_cost,
    ROUND(AVG(c.base_rate + (r.distance_miles * c.per_mile_rate) + r.toll_cost), 2) AS avg_cost_per_shipment,
    ROUND(SUM(c.base_rate + (r.distance_miles * c.per_mile_rate) + r.toll_cost) / SUM(s.weight), 4) AS cost_per_lb
FROM shipments s
JOIN carriers c ON s.carrier_id = c.carrier_id
JOIN routes r ON s.origin_warehouse_id = r.origin_id AND s.destination_address_id = r.destination_id
WHERE s.ship_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.carrier_name, c.service_type
ORDER BY cost_per_lb;

-- ============================================
-- QUESTION 164: Track shipment status distribution
-- ============================================
-- Scenario: Operations dashboard

SELECT 
    status,
    COUNT(*) AS shipment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ship_date)) / 3600) AS avg_hours_in_status
FROM shipments
WHERE ship_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY status
ORDER BY shipment_count DESC;

-- ============================================
-- QUESTION 165: Find optimal route selection
-- ============================================
-- Scenario: Route planning optimization

WITH route_performance AS (
    SELECT 
        r.route_id,
        r.origin_id,
        r.destination_id,
        r.distance_miles,
        r.estimated_hours,
        r.toll_cost,
        COUNT(s.shipment_id) AS times_used,
        AVG(EXTRACT(EPOCH FROM (s.actual_delivery - s.ship_date)) / 3600) AS actual_avg_hours,
        AVG(EXTRACT(EPOCH FROM (s.actual_delivery - s.ship_date)) / 3600) - r.estimated_hours AS variance_hours
    FROM routes r
    LEFT JOIN shipments s ON r.origin_id = s.origin_warehouse_id 
        AND r.destination_id = s.destination_address_id
        AND s.actual_delivery IS NOT NULL
    GROUP BY r.route_id, r.origin_id, r.destination_id, r.distance_miles, r.estimated_hours, r.toll_cost
)
SELECT 
    route_id,
    w1.warehouse_name AS origin,
    w2.warehouse_name AS destination,
    distance_miles,
    estimated_hours,
    actual_avg_hours,
    variance_hours,
    toll_cost,
    times_used,
    CASE 
        WHEN variance_hours > 2 THEN 'UNDERPERFORMING'
        WHEN variance_hours < -1 THEN 'OVERPERFORMING'
        ELSE 'ON TARGET'
    END AS route_status
FROM route_performance rp
JOIN warehouses w1 ON rp.origin_id = w1.warehouse_id
JOIN warehouses w2 ON rp.destination_id = w2.warehouse_id
ORDER BY times_used DESC;

-- ============================================
-- QUESTION 166: Calculate vehicle utilization
-- ============================================
-- Scenario: Fleet management

WITH vehicle_trips AS (
    SELECT 
        v.vehicle_id,
        v.vehicle_type,
        v.capacity_weight,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.actual_weight) AS total_weight_carried,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.fuel_used) AS total_fuel
    FROM vehicles v
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
    WHERE t.trip_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY v.vehicle_id, v.vehicle_type, v.capacity_weight
)
SELECT 
    vehicle_id,
    vehicle_type,
    capacity_weight,
    total_trips,
    total_weight_carried,
    ROUND(100.0 * total_weight_carried / (capacity_weight * total_trips), 2) AS avg_capacity_utilization,
    total_miles,
    total_fuel,
    ROUND(total_miles / NULLIF(total_fuel, 0), 2) AS actual_mpg
FROM vehicle_trips
ORDER BY avg_capacity_utilization DESC;

-- ============================================
-- QUESTION 167: Identify delivery exceptions
-- ============================================
-- Scenario: Exception management

SELECT 
    s.shipment_id,
    s.tracking_number,
    s.status,
    s.ship_date,
    s.expected_delivery,
    s.actual_delivery,
    CASE 
        WHEN s.status = 'LOST' THEN 'CRITICAL'
        WHEN s.status = 'DAMAGED' THEN 'HIGH'
        WHEN s.actual_delivery > s.expected_delivery + INTERVAL '3 days' THEN 'HIGH'
        WHEN s.actual_delivery > s.expected_delivery THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity,
    c.carrier_name,
    EXTRACT(DAYS FROM (COALESCE(s.actual_delivery, CURRENT_TIMESTAMP) - s.expected_delivery)) AS days_delayed
FROM shipments s
JOIN carriers c ON s.carrier_id = c.carrier_id
WHERE s.status IN ('DELAYED', 'LOST', 'DAMAGED', 'RETURNED')
   OR s.actual_delivery > s.expected_delivery
ORDER BY severity, days_delayed DESC;

-- ============================================
-- QUESTION 168: Calculate driver performance
-- ============================================
-- Scenario: Driver evaluation and incentives

SELECT 
    d.driver_id,
    d.first_name || ' ' || d.last_name AS driver_name,
    COUNT(DISTINCT t.trip_id) AS total_trips,
    SUM(t.distance_miles) AS total_miles,
    COUNT(CASE WHEN t.on_time_delivery = TRUE THEN 1 END) AS on_time_deliveries,
    ROUND(100.0 * COUNT(CASE WHEN t.on_time_delivery = TRUE THEN 1 END) / COUNT(*), 2) AS on_time_pct,
    COUNT(CASE WHEN t.incidents > 0 THEN 1 END) AS trips_with_incidents,
    ROUND(AVG(t.fuel_efficiency), 2) AS avg_fuel_efficiency,
    ROUND(AVG(t.customer_rating), 2) AS avg_customer_rating
FROM drivers d
JOIN trips t ON d.driver_id = t.driver_id
WHERE t.trip_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY d.driver_id, d.first_name, d.last_name
ORDER BY on_time_pct DESC, avg_customer_rating DESC;

-- ============================================
-- QUESTION 169: Forecast shipping demand
-- ============================================
-- Scenario: Capacity planning

WITH daily_shipments AS (
    SELECT 
        DATE(ship_date) AS ship_date,
        COUNT(*) AS shipment_count,
        SUM(weight) AS total_weight
    FROM shipments
    WHERE ship_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(ship_date)
),
with_trends AS (
    SELECT 
        ship_date,
        shipment_count,
        total_weight,
        AVG(shipment_count) OVER (ORDER BY ship_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        AVG(shipment_count) OVER (ORDER BY ship_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS moving_avg_30d
    FROM daily_shipments
)
SELECT 
    ship_date,
    shipment_count,
    ROUND(moving_avg_7d, 0) AS weekly_trend,
    ROUND(moving_avg_30d, 0) AS monthly_trend,
    CASE 
        WHEN shipment_count > moving_avg_30d * 1.2 THEN 'ABOVE TREND'
        WHEN shipment_count < moving_avg_30d * 0.8 THEN 'BELOW TREND'
        ELSE 'NORMAL'
    END AS trend_status
FROM with_trends
ORDER BY ship_date DESC;

-- ============================================
-- QUESTION 170: Calculate last-mile delivery metrics
-- ============================================
-- Scenario: Last-mile optimization

SELECT 
    da.city,
    da.zip_code,
    COUNT(*) AS deliveries,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.actual_delivery - s.out_for_delivery_time)) / 60), 2) AS avg_last_mile_minutes,
    COUNT(CASE WHEN s.delivery_attempt > 1 THEN 1 END) AS redelivery_attempts,
    ROUND(100.0 * COUNT(CASE WHEN s.delivery_attempt > 1 THEN 1 END) / COUNT(*), 2) AS redelivery_rate,
    COUNT(CASE WHEN s.signature_required AND s.signature_obtained THEN 1 END) AS successful_signatures
FROM shipments s
JOIN delivery_addresses da ON s.destination_address_id = da.address_id
WHERE s.actual_delivery IS NOT NULL
AND s.ship_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY da.city, da.zip_code
ORDER BY deliveries DESC;

-- ============================================
-- QUESTION 171: Analyze return shipments
-- ============================================
-- Scenario: Reverse logistics optimization

WITH return_analysis AS (
    SELECT 
        rs.return_reason,
        COUNT(*) AS return_count,
        AVG(EXTRACT(DAYS FROM (rs.received_date - rs.initiated_date))) AS avg_return_days,
        SUM(rs.refund_amount) AS total_refunds
    FROM return_shipments rs
    WHERE rs.initiated_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY rs.return_reason
)
SELECT 
    return_reason,
    return_count,
    ROUND(100.0 * return_count / SUM(return_count) OVER (), 2) AS pct_of_returns,
    ROUND(avg_return_days, 1) AS avg_return_days,
    total_refunds,
    ROUND(total_refunds / return_count, 2) AS avg_refund_per_return
FROM return_analysis
ORDER BY return_count DESC;

-- ============================================
-- QUESTION 172: Calculate cross-dock efficiency
-- ============================================
-- Scenario: Distribution center operations

SELECT 
    w.warehouse_id,
    w.warehouse_name,
    COUNT(DISTINCT cd.inbound_shipment_id) AS inbound_shipments,
    COUNT(DISTINCT cd.outbound_shipment_id) AS outbound_shipments,
    AVG(EXTRACT(EPOCH FROM (cd.outbound_time - cd.inbound_time)) / 60) AS avg_dwell_minutes,
    COUNT(CASE WHEN EXTRACT(EPOCH FROM (cd.outbound_time - cd.inbound_time)) / 60 < 120 THEN 1 END) AS quick_turns,
    ROUND(100.0 * COUNT(CASE WHEN EXTRACT(EPOCH FROM (cd.outbound_time - cd.inbound_time)) / 60 < 120 THEN 1 END) / COUNT(*), 2) AS quick_turn_pct
FROM warehouses w
JOIN cross_dock_operations cd ON w.warehouse_id = cd.warehouse_id
WHERE cd.inbound_time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY w.warehouse_id, w.warehouse_name
ORDER BY avg_dwell_minutes;

-- ============================================
-- QUESTION 173: Track package dimensions and weight accuracy
-- ============================================
-- Scenario: Billing accuracy and carrier disputes

SELECT 
    c.carrier_name,
    COUNT(*) AS total_shipments,
    AVG(ABS(s.actual_weight - s.declared_weight)) AS avg_weight_variance,
    COUNT(CASE WHEN ABS(s.actual_weight - s.declared_weight) > s.declared_weight * 0.1 THEN 1 END) AS weight_discrepancies,
    SUM(CASE WHEN s.actual_weight > s.declared_weight THEN 
        (s.actual_weight - s.declared_weight) * c.per_lb_rate ELSE 0 END) AS undercharge_amount,
    SUM(CASE WHEN s.actual_weight < s.declared_weight THEN 
        (s.declared_weight - s.actual_weight) * c.per_lb_rate ELSE 0 END) AS overcharge_amount
FROM shipments s
JOIN carriers c ON s.carrier_id = c.carrier_id
WHERE s.ship_date >= CURRENT_DATE - INTERVAL '30 days'
AND s.actual_weight IS NOT NULL
GROUP BY c.carrier_name
ORDER BY avg_weight_variance DESC;

-- ============================================
-- QUESTION 174: Identify bottleneck locations
-- ============================================
-- Scenario: Network flow optimization

WITH location_throughput AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        w.city,
        COUNT(CASE WHEN s.origin_warehouse_id = w.warehouse_id THEN 1 END) AS outbound_count,
        COUNT(CASE WHEN s.destination_warehouse_id = w.warehouse_id THEN 1 END) AS inbound_count,
        AVG(CASE WHEN s.origin_warehouse_id = w.warehouse_id 
            THEN EXTRACT(EPOCH FROM (s.ship_date - s.order_received_date)) / 3600 END) AS avg_processing_hours
    FROM warehouses w
    LEFT JOIN shipments s ON w.warehouse_id IN (s.origin_warehouse_id, s.destination_warehouse_id)
    WHERE s.ship_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY w.warehouse_id, w.warehouse_name, w.city
)
SELECT 
    warehouse_id,
    warehouse_name,
    city,
    outbound_count,
    inbound_count,
    outbound_count + inbound_count AS total_throughput,
    ROUND(avg_processing_hours, 2) AS avg_processing_hours,
    CASE 
        WHEN avg_processing_hours > 48 THEN 'BOTTLENECK'
        WHEN avg_processing_hours > 24 THEN 'SLOW'
        ELSE 'EFFICIENT'
    END AS efficiency_status
FROM location_throughput
ORDER BY avg_processing_hours DESC;

-- ============================================
-- QUESTION 175: Calculate fuel cost analysis
-- ============================================
-- Scenario: Fleet fuel management

SELECT 
    v.vehicle_type,
    COUNT(DISTINCT t.trip_id) AS total_trips,
    SUM(t.distance_miles) AS total_miles,
    SUM(t.fuel_used) AS total_gallons,
    SUM(t.fuel_cost) AS total_fuel_cost,
    ROUND(SUM(t.distance_miles) / NULLIF(SUM(t.fuel_used), 0), 2) AS fleet_mpg,
    ROUND(SUM(t.fuel_cost) / SUM(t.distance_miles), 4) AS cost_per_mile,
    ROUND(AVG(t.fuel_price_per_gallon), 2) AS avg_fuel_price
FROM vehicles v
JOIN trips t ON v.vehicle_id = t.vehicle_id
WHERE t.trip_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY v.vehicle_type
ORDER BY cost_per_mile;

-- ============================================
-- QUESTION 176: Analyze delivery time windows
-- ============================================
-- Scenario: Customer service optimization

SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM actual_delivery) BETWEEN 8 AND 11 THEN 'Morning (8-12)'
        WHEN EXTRACT(HOUR FROM actual_delivery) BETWEEN 12 AND 16 THEN 'Afternoon (12-5)'
        WHEN EXTRACT(HOUR FROM actual_delivery) BETWEEN 17 AND 20 THEN 'Evening (5-9)'
        ELSE 'Off-hours'
    END AS delivery_window,
    COUNT(*) AS delivery_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_deliveries,
    COUNT(CASE WHEN first_attempt_success = TRUE THEN 1 END) AS successful_first_attempts,
    ROUND(100.0 * COUNT(CASE WHEN first_attempt_success = TRUE THEN 1 END) / COUNT(*), 2) AS first_attempt_success_rate
FROM shipments
WHERE actual_delivery IS NOT NULL
AND ship_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY CASE 
    WHEN EXTRACT(HOUR FROM actual_delivery) BETWEEN 8 AND 11 THEN 'Morning (8-12)'
    WHEN EXTRACT(HOUR FROM actual_delivery) BETWEEN 12 AND 16 THEN 'Afternoon (12-5)'
    WHEN EXTRACT(HOUR FROM actual_delivery) BETWEEN 17 AND 20 THEN 'Evening (5-9)'
    ELSE 'Off-hours'
END
ORDER BY delivery_count DESC;

-- ============================================
-- QUESTION 177: Calculate carrier rate comparison
-- ============================================
-- Scenario: Carrier selection optimization

WITH shipment_costs AS (
    SELECT 
        s.shipment_id,
        s.weight,
        r.distance_miles,
        c.carrier_id,
        c.carrier_name,
        c.base_rate + (r.distance_miles * c.per_mile_rate) + 
            (s.weight * c.per_lb_rate) AS calculated_cost
    FROM shipments s
    JOIN routes r ON s.origin_warehouse_id = r.origin_id 
        AND s.destination_address_id = r.destination_id
    CROSS JOIN carriers c
    WHERE s.ship_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    sc.shipment_id,
    sc.weight,
    sc.distance_miles,
    MIN(sc.calculated_cost) AS lowest_cost,
    MAX(sc.calculated_cost) AS highest_cost,
    MAX(sc.calculated_cost) - MIN(sc.calculated_cost) AS potential_savings,
    (SELECT carrier_name FROM shipment_costs WHERE shipment_id = sc.shipment_id ORDER BY calculated_cost LIMIT 1) AS cheapest_carrier
FROM shipment_costs sc
GROUP BY sc.shipment_id, sc.weight, sc.distance_miles
HAVING MAX(sc.calculated_cost) - MIN(sc.calculated_cost) > 10
ORDER BY potential_savings DESC;

-- ============================================
-- QUESTION 178: Track inventory in transit
-- ============================================
-- Scenario: Supply chain visibility

SELECT 
    p.product_id,
    p.product_name,
    SUM(CASE WHEN s.status = 'IN_TRANSIT' THEN si.quantity ELSE 0 END) AS in_transit_qty,
    SUM(CASE WHEN s.status = 'AT_WAREHOUSE' THEN si.quantity ELSE 0 END) AS at_warehouse_qty,
    SUM(CASE WHEN s.status = 'OUT_FOR_DELIVERY' THEN si.quantity ELSE 0 END) AS out_for_delivery_qty,
    MIN(CASE WHEN s.status = 'IN_TRANSIT' THEN s.expected_delivery END) AS earliest_arrival,
    SUM(si.quantity * p.unit_cost) AS total_value_in_transit
FROM products p
JOIN shipment_items si ON p.product_id = si.product_id
JOIN shipments s ON si.shipment_id = s.shipment_id
WHERE s.status NOT IN ('DELIVERED', 'CANCELLED')
GROUP BY p.product_id, p.product_name
HAVING SUM(CASE WHEN s.status = 'IN_TRANSIT' THEN si.quantity ELSE 0 END) > 0
ORDER BY total_value_in_transit DESC;

-- ============================================
-- QUESTION 179: Analyze seasonal shipping patterns
-- ============================================
-- Scenario: Capacity planning for peak seasons

SELECT 
    EXTRACT(MONTH FROM ship_date) AS month,
    EXTRACT(YEAR FROM ship_date) AS year,
    COUNT(*) AS shipment_count,
    SUM(weight) AS total_weight,
    AVG(EXTRACT(DAYS FROM (actual_delivery - ship_date))) AS avg_delivery_days,
    COUNT(CASE WHEN actual_delivery > expected_delivery THEN 1 END) AS late_deliveries,
    ROUND(100.0 * COUNT(CASE WHEN actual_delivery > expected_delivery THEN 1 END) / COUNT(*), 2) AS late_pct
FROM shipments
WHERE ship_date >= CURRENT_DATE - INTERVAL '2 years'
AND actual_delivery IS NOT NULL
GROUP BY EXTRACT(MONTH FROM ship_date), EXTRACT(YEAR FROM ship_date)
ORDER BY year, month;

-- ============================================
-- QUESTION 180: Generate carrier scorecard
-- ============================================
-- Scenario: Vendor performance management

SELECT 
    c.carrier_id,
    c.carrier_name,
    c.service_type,
    COUNT(*) AS total_shipments,
    ROUND(100.0 * COUNT(CASE WHEN s.actual_delivery <= s.expected_delivery THEN 1 END) / COUNT(*), 2) AS on_time_score,
    ROUND(100.0 * COUNT(CASE WHEN s.status NOT IN ('LOST', 'DAMAGED') THEN 1 END) / COUNT(*), 2) AS damage_free_score,
    ROUND(AVG(s.customer_rating) * 20, 2) AS customer_score,
    ROUND(100.0 - (AVG(ABS(s.actual_weight - s.declared_weight) / s.declared_weight) * 100), 2) AS billing_accuracy_score,
    ROUND((
        (100.0 * COUNT(CASE WHEN s.actual_delivery <= s.expected_delivery THEN 1 END) / COUNT(*)) * 0.4 +
        (100.0 * COUNT(CASE WHEN s.status NOT IN ('LOST', 'DAMAGED') THEN 1 END) / COUNT(*)) * 0.3 +
        (AVG(s.customer_rating) * 20) * 0.2 +
        (100.0 - (AVG(ABS(s.actual_weight - s.declared_weight) / s.declared_weight) * 100)) * 0.1
    ), 2) AS overall_score
FROM carriers c
JOIN shipments s ON c.carrier_id = s.carrier_id
WHERE s.ship_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c.carrier_id, c.carrier_name, c.service_type
ORDER BY overall_score DESC;
