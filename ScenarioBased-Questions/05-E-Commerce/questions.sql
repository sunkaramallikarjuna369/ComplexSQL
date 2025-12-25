-- ============================================
-- SCENARIO-BASED SQL QUESTIONS
-- Category: E-Commerce (Questions 81-100)
-- SQL Server, Oracle, PostgreSQL, MySQL
-- ============================================

-- ============================================
-- SAMPLE SCHEMA
-- ============================================
/*
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    last_login TIMESTAMP,
    user_type VARCHAR(20)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category_id INT,
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    stock_quantity INT,
    rating DECIMAL(3,2),
    review_count INT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date TIMESTAMP,
    status VARCHAR(20),
    total_amount DECIMAL(12,2),
    shipping_address_id INT,
    payment_method VARCHAR(30)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount DECIMAL(5,2)
);

CREATE TABLE cart (
    cart_id INT PRIMARY KEY,
    user_id INT,
    product_id INT,
    quantity INT,
    added_date TIMESTAMP
);

CREATE TABLE reviews (
    review_id INT PRIMARY KEY,
    product_id INT,
    user_id INT,
    rating INT,
    review_text TEXT,
    review_date TIMESTAMP,
    helpful_votes INT
);
*/

-- ============================================
-- QUESTION 81: Calculate cart abandonment rate
-- ============================================
-- Scenario: Identify users who added items but didn't purchase

WITH cart_users AS (
    SELECT DISTINCT user_id
    FROM cart
    WHERE added_date >= CURRENT_DATE - INTERVAL '30 days'
),
purchasers AS (
    SELECT DISTINCT user_id
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
    AND status NOT IN ('CANCELLED', 'REFUNDED')
)
SELECT 
    COUNT(DISTINCT cu.user_id) AS users_with_cart,
    COUNT(DISTINCT p.user_id) AS users_who_purchased,
    COUNT(DISTINCT cu.user_id) - COUNT(DISTINCT p.user_id) AS abandoned_carts,
    ROUND(100.0 * (COUNT(DISTINCT cu.user_id) - COUNT(DISTINCT p.user_id)) / 
          NULLIF(COUNT(DISTINCT cu.user_id), 0), 2) AS abandonment_rate_pct
FROM cart_users cu
LEFT JOIN purchasers p ON cu.user_id = p.user_id;

-- ============================================
-- QUESTION 82: Find best-selling products by category
-- ============================================
-- Scenario: Inventory planning and marketing focus

WITH product_sales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue,
        RANK() OVER (PARTITION BY p.category_id ORDER BY SUM(oi.quantity) DESC) AS rank
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'COMPLETED'
    AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT category_id, product_id, product_name, total_sold, total_revenue
FROM product_sales
WHERE rank <= 5
ORDER BY category_id, rank;

-- ============================================
-- QUESTION 83: Calculate customer acquisition cost by channel
-- ============================================
-- Scenario: Marketing ROI analysis

WITH first_orders AS (
    SELECT 
        user_id,
        MIN(order_date) AS first_order_date,
        (SELECT utm_source FROM user_sessions WHERE user_id = o.user_id ORDER BY session_date LIMIT 1) AS acquisition_channel
    FROM orders o
    WHERE status = 'COMPLETED'
    GROUP BY user_id
),
channel_metrics AS (
    SELECT 
        acquisition_channel,
        COUNT(*) AS new_customers,
        SUM(o.total_amount) AS first_order_revenue
    FROM first_orders fo
    JOIN orders o ON fo.user_id = o.user_id AND fo.first_order_date = o.order_date
    GROUP BY acquisition_channel
)
SELECT 
    cm.acquisition_channel,
    cm.new_customers,
    mc.spend AS marketing_spend,
    ROUND(mc.spend / NULLIF(cm.new_customers, 0), 2) AS cac,
    cm.first_order_revenue,
    ROUND(cm.first_order_revenue / NULLIF(mc.spend, 0), 2) AS roas
FROM channel_metrics cm
JOIN marketing_costs mc ON cm.acquisition_channel = mc.channel;

-- ============================================
-- QUESTION 84: Identify product recommendation opportunities
-- ============================================
-- Scenario: "Customers who bought X also bought Y"

WITH product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS co_purchase_count
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
    HAVING COUNT(DISTINCT oi1.order_id) >= 10
)
SELECT 
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    pp.co_purchase_count,
    ROUND(100.0 * pp.co_purchase_count / 
          (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = pp.product_a), 2) AS confidence_pct
FROM product_pairs pp
JOIN products p1 ON pp.product_a = p1.product_id
JOIN products p2 ON pp.product_b = p2.product_id
ORDER BY co_purchase_count DESC
LIMIT 50;

-- ============================================
-- QUESTION 85: Calculate customer lifetime value (CLV)
-- ============================================
-- Scenario: Customer segmentation for marketing

WITH customer_metrics AS (
    SELECT 
        u.user_id,
        u.username,
        u.registration_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_spent,
        AVG(o.total_amount) AS avg_order_value,
        MAX(o.order_date) AS last_order_date,
        EXTRACT(DAYS FROM MAX(o.order_date) - MIN(o.order_date)) / NULLIF(COUNT(o.order_id) - 1, 0) AS avg_days_between_orders
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id AND o.status = 'COMPLETED'
    GROUP BY u.user_id, u.username, u.registration_date
)
SELECT 
    user_id,
    username,
    total_orders,
    total_spent,
    avg_order_value,
    -- Simple CLV = AOV * Purchase Frequency * Customer Lifespan
    ROUND(avg_order_value * (365.0 / NULLIF(avg_days_between_orders, 0)) * 3, 2) AS estimated_3yr_clv,
    NTILE(5) OVER (ORDER BY total_spent DESC) AS value_segment
FROM customer_metrics
WHERE total_orders > 0
ORDER BY total_spent DESC;

-- ============================================
-- QUESTION 86: Analyze conversion funnel
-- ============================================
-- Scenario: Identify drop-off points in purchase flow

WITH funnel_stages AS (
    SELECT 
        DATE(event_date) AS event_date,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN session_id END) AS page_views,
        COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN session_id END) AS product_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN session_id END) AS add_to_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END) AS checkout_start,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) AS purchases
    FROM user_events
    WHERE event_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(event_date)
)
SELECT 
    event_date,
    page_views,
    product_views,
    ROUND(100.0 * product_views / NULLIF(page_views, 0), 2) AS view_rate,
    add_to_cart,
    ROUND(100.0 * add_to_cart / NULLIF(product_views, 0), 2) AS cart_rate,
    checkout_start,
    ROUND(100.0 * checkout_start / NULLIF(add_to_cart, 0), 2) AS checkout_rate,
    purchases,
    ROUND(100.0 * purchases / NULLIF(checkout_start, 0), 2) AS purchase_rate,
    ROUND(100.0 * purchases / NULLIF(page_views, 0), 2) AS overall_conversion
FROM funnel_stages
ORDER BY event_date;

-- ============================================
-- QUESTION 87: Find products with declining sales
-- ============================================
-- Scenario: Identify products needing promotion or discontinuation

WITH monthly_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'COMPLETED'
    AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY p.product_id, p.product_name, DATE_TRUNC('month', o.order_date)
),
with_trend AS (
    SELECT 
        product_id,
        product_name,
        month,
        units_sold,
        revenue,
        LAG(units_sold, 1) OVER (PARTITION BY product_id ORDER BY month) AS prev_month_units,
        LAG(units_sold, 3) OVER (PARTITION BY product_id ORDER BY month) AS three_months_ago_units
    FROM monthly_sales
)
SELECT 
    product_id,
    product_name,
    month,
    units_sold,
    prev_month_units,
    ROUND(100.0 * (units_sold - prev_month_units) / NULLIF(prev_month_units, 0), 2) AS mom_change_pct,
    ROUND(100.0 * (units_sold - three_months_ago_units) / NULLIF(three_months_ago_units, 0), 2) AS three_month_change_pct
FROM with_trend
WHERE month = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
AND units_sold < prev_month_units
AND units_sold < three_months_ago_units
ORDER BY three_month_change_pct;

-- ============================================
-- QUESTION 88: Calculate product profit margins
-- ============================================
-- Scenario: Profitability analysis for pricing decisions

SELECT 
    p.product_id,
    p.product_name,
    p.price,
    p.cost,
    p.price - p.cost AS gross_profit,
    ROUND(100.0 * (p.price - p.cost) / p.price, 2) AS margin_pct,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * (oi.unit_price - p.cost)) AS total_profit,
    RANK() OVER (ORDER BY SUM(oi.quantity * (oi.unit_price - p.cost)) DESC) AS profit_rank
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'COMPLETED'
AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY p.product_id, p.product_name, p.price, p.cost
ORDER BY total_profit DESC;

-- ============================================
-- QUESTION 89: Identify repeat customers vs one-time buyers
-- ============================================
-- Scenario: Customer retention analysis

WITH customer_orders AS (
    SELECT 
        user_id,
        COUNT(*) AS order_count,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE status = 'COMPLETED'
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional'
        WHEN order_count BETWEEN 4 AND 10 THEN 'Regular'
        ELSE 'Loyal'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
    SUM(total_spent) AS segment_revenue,
    ROUND(100.0 * SUM(total_spent) / SUM(SUM(total_spent)) OVER (), 2) AS pct_of_revenue,
    ROUND(AVG(total_spent), 2) AS avg_customer_value
FROM customer_orders
GROUP BY CASE 
    WHEN order_count = 1 THEN 'One-time'
    WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional'
    WHEN order_count BETWEEN 4 AND 10 THEN 'Regular'
    ELSE 'Loyal'
END
ORDER BY customer_count DESC;

-- ============================================
-- QUESTION 90: Analyze review sentiment impact on sales
-- ============================================
-- Scenario: Understand correlation between ratings and sales

WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.rating,
        p.review_count,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'COMPLETED'
    GROUP BY p.product_id, p.product_name, p.rating, p.review_count
)
SELECT 
    CASE 
        WHEN rating >= 4.5 THEN '4.5-5.0 (Excellent)'
        WHEN rating >= 4.0 THEN '4.0-4.4 (Good)'
        WHEN rating >= 3.0 THEN '3.0-3.9 (Average)'
        ELSE 'Below 3.0 (Poor)'
    END AS rating_band,
    COUNT(*) AS product_count,
    ROUND(AVG(units_sold), 0) AS avg_units_sold,
    ROUND(AVG(revenue), 2) AS avg_revenue,
    ROUND(AVG(review_count), 0) AS avg_reviews
FROM product_metrics
WHERE units_sold > 0
GROUP BY CASE 
    WHEN rating >= 4.5 THEN '4.5-5.0 (Excellent)'
    WHEN rating >= 4.0 THEN '4.0-4.4 (Good)'
    WHEN rating >= 3.0 THEN '3.0-3.9 (Average)'
    ELSE 'Below 3.0 (Poor)'
END
ORDER BY avg_revenue DESC;

-- ============================================
-- QUESTION 91: Calculate return rate by product
-- ============================================
-- Scenario: Quality control and supplier evaluation

WITH order_returns AS (
    SELECT 
        oi.product_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(DISTINCT CASE WHEN r.return_id IS NOT NULL THEN oi.order_id END) AS returned_orders,
        SUM(oi.quantity) AS total_units,
        SUM(CASE WHEN r.return_id IS NOT NULL THEN r.quantity ELSE 0 END) AS returned_units
    FROM order_items oi
    LEFT JOIN returns r ON oi.order_id = r.order_id AND oi.product_id = r.product_id
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    orr.total_orders,
    orr.returned_orders,
    ROUND(100.0 * orr.returned_orders / NULLIF(orr.total_orders, 0), 2) AS return_rate_pct,
    orr.total_units,
    orr.returned_units
FROM order_returns orr
JOIN products p ON orr.product_id = p.product_id
WHERE orr.total_orders >= 10
ORDER BY return_rate_pct DESC;

-- ============================================
-- QUESTION 92: Find peak shopping hours
-- ============================================
-- Scenario: Optimize server capacity and staffing

SELECT 
    EXTRACT(HOUR FROM order_date) AS hour_of_day,
    EXTRACT(DOW FROM order_date) AS day_of_week,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'COMPLETED'
AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY EXTRACT(HOUR FROM order_date), EXTRACT(DOW FROM order_date)
ORDER BY order_count DESC;

-- ============================================
-- QUESTION 93: Calculate discount effectiveness
-- ============================================
-- Scenario: Evaluate promotional campaign ROI

WITH discount_analysis AS (
    SELECT 
        CASE 
            WHEN oi.discount = 0 THEN 'No Discount'
            WHEN oi.discount <= 10 THEN '1-10%'
            WHEN oi.discount <= 20 THEN '11-20%'
            WHEN oi.discount <= 30 THEN '21-30%'
            ELSE '30%+'
        END AS discount_band,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.quantity * oi.unit_price) AS gross_revenue,
        SUM(oi.quantity * oi.unit_price * oi.discount / 100) AS discount_given,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount / 100)) AS net_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'COMPLETED'
    GROUP BY CASE 
        WHEN oi.discount = 0 THEN 'No Discount'
        WHEN oi.discount <= 10 THEN '1-10%'
        WHEN oi.discount <= 20 THEN '11-20%'
        WHEN oi.discount <= 30 THEN '21-30%'
        ELSE '30%+'
    END
)
SELECT 
    discount_band,
    order_count,
    units_sold,
    gross_revenue,
    discount_given,
    net_revenue,
    ROUND(units_sold::DECIMAL / order_count, 2) AS avg_units_per_order
FROM discount_analysis
ORDER BY discount_band;

-- ============================================
-- QUESTION 94: Identify high-value abandoned carts
-- ============================================
-- Scenario: Targeted recovery email campaign

SELECT 
    u.user_id,
    u.email,
    u.username,
    COUNT(c.product_id) AS items_in_cart,
    SUM(c.quantity * p.price) AS cart_value,
    MAX(c.added_date) AS last_cart_activity,
    STRING_AGG(p.product_name, ', ') AS products
FROM cart c
JOIN users u ON c.user_id = u.user_id
JOIN products p ON c.product_id = p.product_id
WHERE c.added_date >= CURRENT_DATE - INTERVAL '7 days'
AND NOT EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.user_id = c.user_id 
    AND o.order_date > c.added_date
)
GROUP BY u.user_id, u.email, u.username
HAVING SUM(c.quantity * p.price) > 100
ORDER BY cart_value DESC;

-- ============================================
-- QUESTION 95: Calculate shipping performance metrics
-- ============================================
-- Scenario: Logistics optimization

SELECT 
    shipping_carrier,
    COUNT(*) AS total_shipments,
    AVG(EXTRACT(DAYS FROM delivered_date - shipped_date)) AS avg_delivery_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(DAYS FROM delivered_date - shipped_date)) AS median_delivery_days,
    COUNT(CASE WHEN delivered_date <= expected_delivery_date THEN 1 END) AS on_time_deliveries,
    ROUND(100.0 * COUNT(CASE WHEN delivered_date <= expected_delivery_date THEN 1 END) / COUNT(*), 2) AS on_time_pct
FROM shipments
WHERE delivered_date IS NOT NULL
AND shipped_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY shipping_carrier
ORDER BY on_time_pct DESC;

-- ============================================
-- QUESTION 96: Find products frequently viewed but not purchased
-- ============================================
-- Scenario: Identify pricing or description issues

WITH product_views AS (
    SELECT 
        product_id,
        COUNT(*) AS view_count,
        COUNT(DISTINCT user_id) AS unique_viewers
    FROM user_events
    WHERE event_type = 'product_view'
    AND event_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY product_id
),
product_purchases AS (
    SELECT 
        oi.product_id,
        COUNT(DISTINCT o.order_id) AS purchase_count
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'COMPLETED'
    AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.price,
    pv.view_count,
    pv.unique_viewers,
    COALESCE(pp.purchase_count, 0) AS purchase_count,
    ROUND(100.0 * COALESCE(pp.purchase_count, 0) / NULLIF(pv.unique_viewers, 0), 2) AS conversion_rate
FROM products p
JOIN product_views pv ON p.product_id = pv.product_id
LEFT JOIN product_purchases pp ON p.product_id = pp.product_id
WHERE pv.view_count >= 100
AND COALESCE(pp.purchase_count, 0) / NULLIF(pv.unique_viewers, 0) < 0.02
ORDER BY pv.view_count DESC;

-- ============================================
-- QUESTION 97: Calculate customer cohort retention
-- ============================================
-- Scenario: Measure long-term customer engagement

WITH first_purchase AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE status = 'COMPLETED'
    GROUP BY user_id
),
cohort_activity AS (
    SELECT 
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date) AS activity_month,
        COUNT(DISTINCT o.user_id) AS active_users
    FROM first_purchase fp
    JOIN orders o ON fp.user_id = o.user_id AND o.status = 'COMPLETED'
    GROUP BY fp.cohort_month, DATE_TRUNC('month', o.order_date)
)
SELECT 
    cohort_month,
    activity_month,
    EXTRACT(MONTH FROM AGE(activity_month, cohort_month)) AS months_since_first,
    active_users,
    FIRST_VALUE(active_users) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,
    ROUND(100.0 * active_users / FIRST_VALUE(active_users) OVER (PARTITION BY cohort_month ORDER BY activity_month), 2) AS retention_pct
FROM cohort_activity
ORDER BY cohort_month, activity_month;

-- ============================================
-- QUESTION 98: Identify cross-category buyers
-- ============================================
-- Scenario: Understand shopping behavior patterns

WITH user_categories AS (
    SELECT 
        o.user_id,
        COUNT(DISTINCT p.category_id) AS categories_purchased,
        ARRAY_AGG(DISTINCT p.category_id) AS category_list,
        SUM(o.total_amount) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'COMPLETED'
    GROUP BY o.user_id
)
SELECT 
    categories_purchased,
    COUNT(*) AS user_count,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_users
FROM user_categories
GROUP BY categories_purchased
ORDER BY categories_purchased;

-- ============================================
-- QUESTION 99: Calculate inventory velocity
-- ============================================
-- Scenario: Optimize stock levels

WITH daily_sales AS (
    SELECT 
        oi.product_id,
        DATE(o.order_date) AS sale_date,
        SUM(oi.quantity) AS daily_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'COMPLETED'
    AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY oi.product_id, DATE(o.order_date)
)
SELECT 
    p.product_id,
    p.product_name,
    p.stock_quantity,
    COALESCE(AVG(ds.daily_quantity), 0) AS avg_daily_sales,
    CASE 
        WHEN COALESCE(AVG(ds.daily_quantity), 0) > 0 
        THEN ROUND(p.stock_quantity / AVG(ds.daily_quantity), 1)
        ELSE NULL 
    END AS days_of_stock,
    CASE 
        WHEN p.stock_quantity / NULLIF(AVG(ds.daily_quantity), 0) < 7 THEN 'CRITICAL'
        WHEN p.stock_quantity / NULLIF(AVG(ds.daily_quantity), 0) < 14 THEN 'LOW'
        WHEN p.stock_quantity / NULLIF(AVG(ds.daily_quantity), 0) > 90 THEN 'OVERSTOCK'
        ELSE 'OK'
    END AS stock_status
FROM products p
LEFT JOIN daily_sales ds ON p.product_id = ds.product_id
GROUP BY p.product_id, p.product_name, p.stock_quantity
ORDER BY days_of_stock NULLS LAST;

-- ============================================
-- QUESTION 100: Generate product performance dashboard
-- ============================================
-- Scenario: Executive summary of product metrics

SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.price,
    p.stock_quantity,
    p.rating,
    p.review_count,
    COALESCE(SUM(oi.quantity), 0) AS units_sold_30d,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue_30d,
    COALESCE(SUM(oi.quantity * (oi.unit_price - p.cost)), 0) AS profit_30d,
    ROUND(100.0 * COALESCE(SUM(oi.quantity * (oi.unit_price - p.cost)), 0) / 
          NULLIF(SUM(oi.quantity * oi.unit_price), 0), 2) AS margin_pct,
    RANK() OVER (PARTITION BY p.category_id ORDER BY COALESCE(SUM(oi.quantity), 0) DESC) AS category_rank
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id 
    AND o.status = 'COMPLETED' 
    AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.product_id, p.product_name, c.category_name, p.price, p.stock_quantity, p.rating, p.review_count, p.cost, p.category_id
ORDER BY revenue_30d DESC;
