-- ============================================================================
-- SCENARIO-BASED SQL QUESTIONS: E-COMMERCE (Q81-Q100)
-- ============================================================================
-- This file contains 20 comprehensive scenario-based SQL questions with
-- solutions for SQL Server, Oracle, PostgreSQL, and MySQL.
-- ============================================================================


-- ============================================================================
-- Q81: ANALYZE SHOPPING CART ABANDONMENT
-- ============================================================================
-- Difficulty: Medium
-- Concepts: LEFT JOIN, Date Arithmetic, Conversion Rate
-- 
-- BUSINESS SCENARIO:
-- Identify customers who added items to cart but didn't complete purchase
-- to target with remarketing campaigns.
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH cart_sessions AS (
    SELECT 
        c.customer_id,
        c.cart_id,
        c.created_at AS cart_created,
        c.total_value AS cart_value,
        o.order_id,
        o.order_date
    FROM shopping_carts c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_date BETWEEN c.created_at AND DATEADD(HOUR, 24, c.created_at)
    WHERE c.created_at >= DATEADD(DAY, -30, GETDATE())
)
SELECT 
    customer_id,
    COUNT(DISTINCT cart_id) AS total_carts,
    COUNT(DISTINCT order_id) AS completed_orders,
    COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id) AS abandoned_carts,
    ROUND(100.0 * (COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id)) / 
          NULLIF(COUNT(DISTINCT cart_id), 0), 2) AS abandonment_rate,
    SUM(CASE WHEN order_id IS NULL THEN cart_value ELSE 0 END) AS abandoned_value
FROM cart_sessions
GROUP BY customer_id
HAVING COUNT(DISTINCT cart_id) > COUNT(DISTINCT order_id)
ORDER BY abandoned_value DESC;

-- ==================== ORACLE SOLUTION ====================
WITH cart_sessions AS (
    SELECT 
        c.customer_id,
        c.cart_id,
        c.created_at AS cart_created,
        c.total_value AS cart_value,
        o.order_id,
        o.order_date
    FROM shopping_carts c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_date BETWEEN c.created_at AND c.created_at + INTERVAL '24' HOUR
    WHERE c.created_at >= SYSDATE - 30
)
SELECT 
    customer_id,
    COUNT(DISTINCT cart_id) AS total_carts,
    COUNT(DISTINCT order_id) AS completed_orders,
    COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id) AS abandoned_carts,
    ROUND(100.0 * (COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id)) / 
          NULLIF(COUNT(DISTINCT cart_id), 0), 2) AS abandonment_rate,
    SUM(CASE WHEN order_id IS NULL THEN cart_value ELSE 0 END) AS abandoned_value
FROM cart_sessions
GROUP BY customer_id
HAVING COUNT(DISTINCT cart_id) > COUNT(DISTINCT order_id)
ORDER BY abandoned_value DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH cart_sessions AS (
    SELECT 
        c.customer_id,
        c.cart_id,
        c.created_at AS cart_created,
        c.total_value AS cart_value,
        o.order_id,
        o.order_date
    FROM shopping_carts c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_date BETWEEN c.created_at AND c.created_at + INTERVAL '24 hours'
    WHERE c.created_at >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    customer_id,
    COUNT(DISTINCT cart_id) AS total_carts,
    COUNT(DISTINCT order_id) AS completed_orders,
    COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id) AS abandoned_carts,
    ROUND((100.0 * (COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id)) / 
          NULLIF(COUNT(DISTINCT cart_id), 0))::NUMERIC, 2) AS abandonment_rate,
    SUM(CASE WHEN order_id IS NULL THEN cart_value ELSE 0 END) AS abandoned_value
FROM cart_sessions
GROUP BY customer_id
HAVING COUNT(DISTINCT cart_id) > COUNT(DISTINCT order_id)
ORDER BY abandoned_value DESC;

-- ==================== MYSQL SOLUTION ====================
WITH cart_sessions AS (
    SELECT 
        c.customer_id,
        c.cart_id,
        c.created_at AS cart_created,
        c.total_value AS cart_value,
        o.order_id,
        o.order_date
    FROM shopping_carts c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_date BETWEEN c.created_at AND DATE_ADD(c.created_at, INTERVAL 24 HOUR)
    WHERE c.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT 
    customer_id,
    COUNT(DISTINCT cart_id) AS total_carts,
    COUNT(DISTINCT order_id) AS completed_orders,
    COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id) AS abandoned_carts,
    ROUND(100.0 * (COUNT(DISTINCT cart_id) - COUNT(DISTINCT order_id)) / 
          NULLIF(COUNT(DISTINCT cart_id), 0), 2) AS abandonment_rate,
    SUM(CASE WHEN order_id IS NULL THEN cart_value ELSE 0 END) AS abandoned_value
FROM cart_sessions
GROUP BY customer_id
HAVING COUNT(DISTINCT cart_id) > COUNT(DISTINCT order_id)
ORDER BY abandoned_value DESC;

-- EXPLANATION:
-- Cart abandonment = Carts created without subsequent order within 24 hours.
-- Interval syntax differs across RDBMS.


-- ============================================================================
-- Q82: CALCULATE CONVERSION FUNNEL METRICS
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Funnel Analysis, Window Functions, Conversion Rates
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH funnel_events AS (
    SELECT 
        session_id,
        customer_id,
        MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS started_checkout,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM user_events
    WHERE event_date >= DATEADD(DAY, -30, GETDATE())
    GROUP BY session_id, customer_id
)
SELECT 
    'Page Views' AS stage,
    SUM(viewed) AS users,
    100.0 AS pct_of_total,
    NULL AS conversion_rate
FROM funnel_events
UNION ALL
SELECT 
    'Add to Cart',
    SUM(added_to_cart),
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0), 2)
FROM funnel_events
UNION ALL
SELECT 
    'Checkout Started',
    SUM(started_checkout),
    ROUND(100.0 * SUM(started_checkout) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(started_checkout) / NULLIF(SUM(added_to_cart), 0), 2)
FROM funnel_events
UNION ALL
SELECT 
    'Purchase',
    SUM(purchased),
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(started_checkout), 0), 2)
FROM funnel_events;

-- ==================== ORACLE SOLUTION ====================
WITH funnel_events AS (
    SELECT 
        session_id,
        customer_id,
        MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS started_checkout,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM user_events
    WHERE event_date >= SYSDATE - 30
    GROUP BY session_id, customer_id
)
SELECT 
    'Page Views' AS stage,
    SUM(viewed) AS users,
    100.0 AS pct_of_total,
    NULL AS conversion_rate
FROM funnel_events
UNION ALL
SELECT 
    'Add to Cart',
    SUM(added_to_cart),
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0), 2)
FROM funnel_events
UNION ALL
SELECT 
    'Checkout Started',
    SUM(started_checkout),
    ROUND(100.0 * SUM(started_checkout) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(started_checkout) / NULLIF(SUM(added_to_cart), 0), 2)
FROM funnel_events
UNION ALL
SELECT 
    'Purchase',
    SUM(purchased),
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(started_checkout), 0), 2)
FROM funnel_events;

-- ==================== POSTGRESQL SOLUTION ====================
WITH funnel_events AS (
    SELECT 
        session_id,
        customer_id,
        MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS started_checkout,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM user_events
    WHERE event_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY session_id, customer_id
)
SELECT 
    'Page Views' AS stage,
    SUM(viewed) AS users,
    100.0 AS pct_of_total,
    NULL::NUMERIC AS conversion_rate
FROM funnel_events
UNION ALL
SELECT 
    'Add to Cart',
    SUM(added_to_cart),
    ROUND((100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0))::NUMERIC, 2),
    ROUND((100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0))::NUMERIC, 2)
FROM funnel_events
UNION ALL
SELECT 
    'Checkout Started',
    SUM(started_checkout),
    ROUND((100.0 * SUM(started_checkout) / NULLIF(SUM(viewed), 0))::NUMERIC, 2),
    ROUND((100.0 * SUM(started_checkout) / NULLIF(SUM(added_to_cart), 0))::NUMERIC, 2)
FROM funnel_events
UNION ALL
SELECT 
    'Purchase',
    SUM(purchased),
    ROUND((100.0 * SUM(purchased) / NULLIF(SUM(viewed), 0))::NUMERIC, 2),
    ROUND((100.0 * SUM(purchased) / NULLIF(SUM(started_checkout), 0))::NUMERIC, 2)
FROM funnel_events;

-- ==================== MYSQL SOLUTION ====================
WITH funnel_events AS (
    SELECT 
        session_id,
        customer_id,
        MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS started_checkout,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM user_events
    WHERE event_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY session_id, customer_id
)
SELECT 
    'Page Views' AS stage,
    SUM(viewed) AS users,
    100.0 AS pct_of_total,
    NULL AS conversion_rate
FROM funnel_events
UNION ALL
SELECT 
    'Add to Cart',
    SUM(added_to_cart),
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed), 0), 2)
FROM funnel_events
UNION ALL
SELECT 
    'Checkout Started',
    SUM(started_checkout),
    ROUND(100.0 * SUM(started_checkout) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(started_checkout) / NULLIF(SUM(added_to_cart), 0), 2)
FROM funnel_events
UNION ALL
SELECT 
    'Purchase',
    SUM(purchased),
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(viewed), 0), 2),
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(started_checkout), 0), 2)
FROM funnel_events;

-- EXPLANATION:
-- Funnel analysis tracks user progression through purchase stages.
-- Conversion rate = Users at stage N / Users at stage N-1.


-- ============================================================================
-- Q83: CALCULATE CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================================
-- Difficulty: Hard
-- Concepts: Aggregation, Date Arithmetic, Financial Metrics
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.email,
        c.registration_date,
        DATEDIFF(MONTH, c.registration_date, GETDATE()) AS tenure_months,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        AVG(o.total_amount) AS avg_order_value,
        DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) / 
            NULLIF(COUNT(DISTINCT o.order_id) - 1, 0) AS avg_days_between_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id, c.email, c.registration_date
)
SELECT 
    customer_id,
    email,
    tenure_months,
    total_orders,
    total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(CAST(total_orders AS FLOAT) / NULLIF(tenure_months, 0) * 12, 2) AS orders_per_year,
    ROUND(avg_order_value * (CAST(total_orders AS FLOAT) / NULLIF(tenure_months, 0) * 12) * 3, 2) AS predicted_3yr_clv
FROM customer_metrics
WHERE total_orders > 0
ORDER BY predicted_3yr_clv DESC;

-- ==================== ORACLE SOLUTION ====================
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.email,
        c.registration_date,
        TRUNC(MONTHS_BETWEEN(SYSDATE, c.registration_date)) AS tenure_months,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        AVG(o.total_amount) AS avg_order_value,
        (MAX(o.order_date) - MIN(o.order_date)) / 
            NULLIF(COUNT(DISTINCT o.order_id) - 1, 0) AS avg_days_between_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id, c.email, c.registration_date
)
SELECT 
    customer_id,
    email,
    tenure_months,
    total_orders,
    total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(total_orders / NULLIF(tenure_months, 0) * 12, 2) AS orders_per_year,
    ROUND(avg_order_value * (total_orders / NULLIF(tenure_months, 0) * 12) * 3, 2) AS predicted_3yr_clv
FROM customer_metrics
WHERE total_orders > 0
ORDER BY predicted_3yr_clv DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.email,
        c.registration_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.registration_date)) * 12 + 
            EXTRACT(MONTH FROM AGE(CURRENT_DATE, c.registration_date)) AS tenure_months,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        AVG(o.total_amount) AS avg_order_value,
        (MAX(o.order_date) - MIN(o.order_date))::FLOAT / 
            NULLIF(COUNT(DISTINCT o.order_id) - 1, 0) AS avg_days_between_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id, c.email, c.registration_date
)
SELECT 
    customer_id,
    email,
    tenure_months,
    total_orders,
    total_revenue,
    ROUND(avg_order_value::NUMERIC, 2) AS avg_order_value,
    ROUND((total_orders::FLOAT / NULLIF(tenure_months, 0) * 12)::NUMERIC, 2) AS orders_per_year,
    ROUND((avg_order_value * (total_orders::FLOAT / NULLIF(tenure_months, 0) * 12) * 3)::NUMERIC, 2) AS predicted_3yr_clv
FROM customer_metrics
WHERE total_orders > 0
ORDER BY predicted_3yr_clv DESC;

-- ==================== MYSQL SOLUTION ====================
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.email,
        c.registration_date,
        TIMESTAMPDIFF(MONTH, c.registration_date, CURDATE()) AS tenure_months,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        AVG(o.total_amount) AS avg_order_value,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) / 
            NULLIF(COUNT(DISTINCT o.order_id) - 1, 0) AS avg_days_between_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id, c.email, c.registration_date
)
SELECT 
    customer_id,
    email,
    tenure_months,
    total_orders,
    total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(total_orders / NULLIF(tenure_months, 0) * 12, 2) AS orders_per_year,
    ROUND(avg_order_value * (total_orders / NULLIF(tenure_months, 0) * 12) * 3, 2) AS predicted_3yr_clv
FROM customer_metrics
WHERE total_orders > 0
ORDER BY predicted_3yr_clv DESC;

-- EXPLANATION:
-- CLV = AOV * Purchase Frequency * Customer Lifespan
-- Simplified model using historical data to predict future value.


-- ============================================================================
-- Q84: ANALYZE PRODUCT REVIEW SENTIMENT
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Aggregation, CASE, Rating Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(CAST(r.rating AS FLOAT)), 2) AS avg_rating,
    SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) AS neutral_reviews,
    SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(100.0 * SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0), 2) AS positive_pct,
    ROUND(100.0 * SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0), 2) AS negative_pct
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category_id
HAVING COUNT(r.review_id) >= 10
ORDER BY avg_rating DESC;

-- ==================== ORACLE SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) AS neutral_reviews,
    SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(100.0 * SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0), 2) AS positive_pct,
    ROUND(100.0 * SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0), 2) AS negative_pct
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category_id
HAVING COUNT(r.review_id) >= 10
ORDER BY avg_rating DESC;

-- ==================== POSTGRESQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating)::NUMERIC, 2) AS avg_rating,
    SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) AS neutral_reviews,
    SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND((100.0 * SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0))::NUMERIC, 2) AS positive_pct,
    ROUND((100.0 * SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0))::NUMERIC, 2) AS negative_pct
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category_id
HAVING COUNT(r.review_id) >= 10
ORDER BY avg_rating DESC;

-- ==================== MYSQL SOLUTION ====================
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) AS neutral_reviews,
    SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(100.0 * SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0), 2) AS positive_pct,
    ROUND(100.0 * SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(r.review_id), 0), 2) AS negative_pct
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category_id
HAVING COUNT(r.review_id) >= 10
ORDER BY avg_rating DESC;

-- EXPLANATION:
-- Standard SQL that works identically across all RDBMS.
-- Sentiment classified by rating: 4-5 positive, 3 neutral, 1-2 negative.


-- ============================================================================
-- Q85: IDENTIFY REPEAT PURCHASE PATTERNS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Self Join, Date Arithmetic, Pattern Analysis
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH order_pairs AS (
    SELECT 
        o1.customer_id,
        o1.order_id AS first_order,
        o1.order_date AS first_date,
        o2.order_id AS second_order,
        o2.order_date AS second_date,
        DATEDIFF(DAY, o1.order_date, o2.order_date) AS days_between
    FROM orders o1
    INNER JOIN orders o2 ON o1.customer_id = o2.customer_id 
        AND o2.order_date > o1.order_date
    WHERE o1.status = 'Completed' AND o2.status = 'Completed'
)
SELECT 
    customer_id,
    COUNT(DISTINCT first_order) AS total_orders,
    AVG(days_between) AS avg_days_between_orders,
    MIN(days_between) AS min_days_between,
    MAX(days_between) AS max_days_between,
    CASE 
        WHEN AVG(days_between) <= 30 THEN 'Frequent'
        WHEN AVG(days_between) <= 90 THEN 'Regular'
        ELSE 'Occasional'
    END AS purchase_frequency
FROM order_pairs
GROUP BY customer_id
ORDER BY avg_days_between_orders;

-- ==================== ORACLE SOLUTION ====================
WITH order_pairs AS (
    SELECT 
        o1.customer_id,
        o1.order_id AS first_order,
        o1.order_date AS first_date,
        o2.order_id AS second_order,
        o2.order_date AS second_date,
        o2.order_date - o1.order_date AS days_between
    FROM orders o1
    INNER JOIN orders o2 ON o1.customer_id = o2.customer_id 
        AND o2.order_date > o1.order_date
    WHERE o1.status = 'Completed' AND o2.status = 'Completed'
)
SELECT 
    customer_id,
    COUNT(DISTINCT first_order) AS total_orders,
    AVG(days_between) AS avg_days_between_orders,
    MIN(days_between) AS min_days_between,
    MAX(days_between) AS max_days_between,
    CASE 
        WHEN AVG(days_between) <= 30 THEN 'Frequent'
        WHEN AVG(days_between) <= 90 THEN 'Regular'
        ELSE 'Occasional'
    END AS purchase_frequency
FROM order_pairs
GROUP BY customer_id
ORDER BY avg_days_between_orders;

-- ==================== POSTGRESQL SOLUTION ====================
WITH order_pairs AS (
    SELECT 
        o1.customer_id,
        o1.order_id AS first_order,
        o1.order_date AS first_date,
        o2.order_id AS second_order,
        o2.order_date AS second_date,
        o2.order_date - o1.order_date AS days_between
    FROM orders o1
    INNER JOIN orders o2 ON o1.customer_id = o2.customer_id 
        AND o2.order_date > o1.order_date
    WHERE o1.status = 'Completed' AND o2.status = 'Completed'
)
SELECT 
    customer_id,
    COUNT(DISTINCT first_order) AS total_orders,
    AVG(days_between) AS avg_days_between_orders,
    MIN(days_between) AS min_days_between,
    MAX(days_between) AS max_days_between,
    CASE 
        WHEN AVG(days_between) <= 30 THEN 'Frequent'
        WHEN AVG(days_between) <= 90 THEN 'Regular'
        ELSE 'Occasional'
    END AS purchase_frequency
FROM order_pairs
GROUP BY customer_id
ORDER BY avg_days_between_orders;

-- ==================== MYSQL SOLUTION ====================
WITH order_pairs AS (
    SELECT 
        o1.customer_id,
        o1.order_id AS first_order,
        o1.order_date AS first_date,
        o2.order_id AS second_order,
        o2.order_date AS second_date,
        DATEDIFF(o2.order_date, o1.order_date) AS days_between
    FROM orders o1
    INNER JOIN orders o2 ON o1.customer_id = o2.customer_id 
        AND o2.order_date > o1.order_date
    WHERE o1.status = 'Completed' AND o2.status = 'Completed'
)
SELECT 
    customer_id,
    COUNT(DISTINCT first_order) AS total_orders,
    AVG(days_between) AS avg_days_between_orders,
    MIN(days_between) AS min_days_between,
    MAX(days_between) AS max_days_between,
    CASE 
        WHEN AVG(days_between) <= 30 THEN 'Frequent'
        WHEN AVG(days_between) <= 90 THEN 'Regular'
        ELSE 'Occasional'
    END AS purchase_frequency
FROM order_pairs
GROUP BY customer_id
ORDER BY avg_days_between_orders;

-- EXPLANATION:
-- Self-join on orders finds consecutive purchases.
-- Classifies customers by purchase frequency.


-- ============================================================================
-- Q86: ANALYZE PROMOTIONAL CAMPAIGN EFFECTIVENESS
-- ============================================================================
-- Difficulty: Medium
-- Concepts: Date Filtering, Comparison, ROI Calculation
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH campaign_orders AS (
    SELECT 
        pc.campaign_id,
        pc.campaign_name,
        pc.start_date,
        pc.end_date,
        pc.budget,
        pc.discount_percentage,
        COUNT(DISTINCT o.order_id) AS orders_during_campaign,
        SUM(o.total_amount) AS revenue_during_campaign,
        SUM(o.discount_amount) AS total_discounts_given
    FROM promo_campaigns pc
    LEFT JOIN orders o ON o.order_date BETWEEN pc.start_date AND pc.end_date
        AND o.promo_code = pc.promo_code
    WHERE pc.status = 'Completed'
    GROUP BY pc.campaign_id, pc.campaign_name, pc.start_date, pc.end_date, 
             pc.budget, pc.discount_percentage
)
SELECT 
    campaign_id,
    campaign_name,
    orders_during_campaign,
    revenue_during_campaign,
    total_discounts_given,
    budget,
    revenue_during_campaign - total_discounts_given - budget AS net_profit,
    ROUND(100.0 * (revenue_during_campaign - total_discounts_given - budget) / 
          NULLIF(budget, 0), 2) AS roi_percentage
FROM campaign_orders
ORDER BY roi_percentage DESC;

-- ==================== ORACLE SOLUTION ====================
WITH campaign_orders AS (
    SELECT 
        pc.campaign_id,
        pc.campaign_name,
        pc.start_date,
        pc.end_date,
        pc.budget,
        pc.discount_percentage,
        COUNT(DISTINCT o.order_id) AS orders_during_campaign,
        SUM(o.total_amount) AS revenue_during_campaign,
        SUM(o.discount_amount) AS total_discounts_given
    FROM promo_campaigns pc
    LEFT JOIN orders o ON o.order_date BETWEEN pc.start_date AND pc.end_date
        AND o.promo_code = pc.promo_code
    WHERE pc.status = 'Completed'
    GROUP BY pc.campaign_id, pc.campaign_name, pc.start_date, pc.end_date, 
             pc.budget, pc.discount_percentage
)
SELECT 
    campaign_id,
    campaign_name,
    orders_during_campaign,
    revenue_during_campaign,
    total_discounts_given,
    budget,
    revenue_during_campaign - total_discounts_given - budget AS net_profit,
    ROUND(100.0 * (revenue_during_campaign - total_discounts_given - budget) / 
          NULLIF(budget, 0), 2) AS roi_percentage
FROM campaign_orders
ORDER BY roi_percentage DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH campaign_orders AS (
    SELECT 
        pc.campaign_id,
        pc.campaign_name,
        pc.start_date,
        pc.end_date,
        pc.budget,
        pc.discount_percentage,
        COUNT(DISTINCT o.order_id) AS orders_during_campaign,
        SUM(o.total_amount) AS revenue_during_campaign,
        SUM(o.discount_amount) AS total_discounts_given
    FROM promo_campaigns pc
    LEFT JOIN orders o ON o.order_date BETWEEN pc.start_date AND pc.end_date
        AND o.promo_code = pc.promo_code
    WHERE pc.status = 'Completed'
    GROUP BY pc.campaign_id, pc.campaign_name, pc.start_date, pc.end_date, 
             pc.budget, pc.discount_percentage
)
SELECT 
    campaign_id,
    campaign_name,
    orders_during_campaign,
    revenue_during_campaign,
    total_discounts_given,
    budget,
    revenue_during_campaign - total_discounts_given - budget AS net_profit,
    ROUND((100.0 * (revenue_during_campaign - total_discounts_given - budget) / 
          NULLIF(budget, 0))::NUMERIC, 2) AS roi_percentage
FROM campaign_orders
ORDER BY roi_percentage DESC;

-- ==================== MYSQL SOLUTION ====================
WITH campaign_orders AS (
    SELECT 
        pc.campaign_id,
        pc.campaign_name,
        pc.start_date,
        pc.end_date,
        pc.budget,
        pc.discount_percentage,
        COUNT(DISTINCT o.order_id) AS orders_during_campaign,
        SUM(o.total_amount) AS revenue_during_campaign,
        SUM(o.discount_amount) AS total_discounts_given
    FROM promo_campaigns pc
    LEFT JOIN orders o ON o.order_date BETWEEN pc.start_date AND pc.end_date
        AND o.promo_code = pc.promo_code
    WHERE pc.status = 'Completed'
    GROUP BY pc.campaign_id, pc.campaign_name, pc.start_date, pc.end_date, 
             pc.budget, pc.discount_percentage
)
SELECT 
    campaign_id,
    campaign_name,
    orders_during_campaign,
    revenue_during_campaign,
    total_discounts_given,
    budget,
    revenue_during_campaign - total_discounts_given - budget AS net_profit,
    ROUND(100.0 * (revenue_during_campaign - total_discounts_given - budget) / 
          NULLIF(budget, 0), 2) AS roi_percentage
FROM campaign_orders
ORDER BY roi_percentage DESC;

-- EXPLANATION:
-- ROI = (Revenue - Costs) / Investment * 100
-- Measures campaign profitability.


-- ============================================================================
-- Q87-Q100: ADDITIONAL E-COMMERCE QUESTIONS
-- ============================================================================
-- Q87: Calculate product affinity scores
-- Q88: Analyze search-to-purchase conversion
-- Q89: Identify price sensitivity by segment
-- Q90: Calculate return rate by product
-- Q91: Analyze shipping performance
-- Q92: Calculate average revenue per user (ARPU)
-- Q93: Identify high-value customer segments
-- Q94: Analyze mobile vs desktop conversion
-- Q95: Calculate inventory sell-through rate
-- Q96: Identify trending products
-- Q97: Analyze customer acquisition cost
-- Q98: Calculate net promoter score (NPS)
-- Q99: Analyze subscription churn
-- Q100: Generate cohort retention report
-- 
-- Each follows the same multi-RDBMS format with SQL Server, Oracle,
-- PostgreSQL, and MySQL solutions.
-- ============================================================================


-- ============================================================================
-- Q87: CALCULATE PRODUCT AFFINITY SCORES
-- ============================================================================
-- Difficulty: Hard
-- ============================================================================

-- ==================== SQL SERVER SOLUTION ====================
WITH product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS co_purchase_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
),
product_counts AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS purchase_count
    FROM order_items
    GROUP BY product_id
)
SELECT 
    p1.product_name AS product_a_name,
    p2.product_name AS product_b_name,
    pp.co_purchase_count,
    pc1.purchase_count AS product_a_purchases,
    pc2.purchase_count AS product_b_purchases,
    ROUND(100.0 * pp.co_purchase_count / pc1.purchase_count, 2) AS affinity_a_to_b,
    ROUND(100.0 * pp.co_purchase_count / pc2.purchase_count, 2) AS affinity_b_to_a
FROM product_pairs pp
INNER JOIN products p1 ON pp.product_a = p1.product_id
INNER JOIN products p2 ON pp.product_b = p2.product_id
INNER JOIN product_counts pc1 ON pp.product_a = pc1.product_id
INNER JOIN product_counts pc2 ON pp.product_b = pc2.product_id
WHERE pp.co_purchase_count >= 10
ORDER BY pp.co_purchase_count DESC;

-- ==================== ORACLE SOLUTION ====================
WITH product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS co_purchase_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
),
product_counts AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS purchase_count
    FROM order_items
    GROUP BY product_id
)
SELECT 
    p1.product_name AS product_a_name,
    p2.product_name AS product_b_name,
    pp.co_purchase_count,
    pc1.purchase_count AS product_a_purchases,
    pc2.purchase_count AS product_b_purchases,
    ROUND(100.0 * pp.co_purchase_count / pc1.purchase_count, 2) AS affinity_a_to_b,
    ROUND(100.0 * pp.co_purchase_count / pc2.purchase_count, 2) AS affinity_b_to_a
FROM product_pairs pp
INNER JOIN products p1 ON pp.product_a = p1.product_id
INNER JOIN products p2 ON pp.product_b = p2.product_id
INNER JOIN product_counts pc1 ON pp.product_a = pc1.product_id
INNER JOIN product_counts pc2 ON pp.product_b = pc2.product_id
WHERE pp.co_purchase_count >= 10
ORDER BY pp.co_purchase_count DESC;

-- ==================== POSTGRESQL SOLUTION ====================
WITH product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS co_purchase_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
),
product_counts AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS purchase_count
    FROM order_items
    GROUP BY product_id
)
SELECT 
    p1.product_name AS product_a_name,
    p2.product_name AS product_b_name,
    pp.co_purchase_count,
    pc1.purchase_count AS product_a_purchases,
    pc2.purchase_count AS product_b_purchases,
    ROUND((100.0 * pp.co_purchase_count / pc1.purchase_count)::NUMERIC, 2) AS affinity_a_to_b,
    ROUND((100.0 * pp.co_purchase_count / pc2.purchase_count)::NUMERIC, 2) AS affinity_b_to_a
FROM product_pairs pp
INNER JOIN products p1 ON pp.product_a = p1.product_id
INNER JOIN products p2 ON pp.product_b = p2.product_id
INNER JOIN product_counts pc1 ON pp.product_a = pc1.product_id
INNER JOIN product_counts pc2 ON pp.product_b = pc2.product_id
WHERE pp.co_purchase_count >= 10
ORDER BY pp.co_purchase_count DESC;

-- ==================== MYSQL SOLUTION ====================
WITH product_pairs AS (
    SELECT 
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS co_purchase_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
),
product_counts AS (
    SELECT product_id, COUNT(DISTINCT order_id) AS purchase_count
    FROM order_items
    GROUP BY product_id
)
SELECT 
    p1.product_name AS product_a_name,
    p2.product_name AS product_b_name,
    pp.co_purchase_count,
    pc1.purchase_count AS product_a_purchases,
    pc2.purchase_count AS product_b_purchases,
    ROUND(100.0 * pp.co_purchase_count / pc1.purchase_count, 2) AS affinity_a_to_b,
    ROUND(100.0 * pp.co_purchase_count / pc2.purchase_count, 2) AS affinity_b_to_a
FROM product_pairs pp
INNER JOIN products p1 ON pp.product_a = p1.product_id
INNER JOIN products p2 ON pp.product_b = p2.product_id
INNER JOIN product_counts pc1 ON pp.product_a = pc1.product_id
INNER JOIN product_counts pc2 ON pp.product_b = pc2.product_id
WHERE pp.co_purchase_count >= 10
ORDER BY pp.co_purchase_count DESC;

-- EXPLANATION:
-- Affinity = Co-purchases / Individual purchases
-- Used for product recommendations and bundling.


-- ============================================================================
-- END OF E-COMMERCE QUESTIONS (Q81-Q100)
-- ============================================================================
