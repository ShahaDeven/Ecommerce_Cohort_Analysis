-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- 04 - FUNNEL ANALYSIS
-- =====================================================
-- Purpose: Analyze conversion through order stages and identify drop-off points
-- =====================================================

-- =====================================================
-- SECTION 1: ORDER STATUS FUNNEL
-- =====================================================

-- 1.1 Overall funnel view
-- Maps order statuses to funnel stages and calculates conversion rates
WITH funnel_stages AS (
    SELECT 
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        CASE 
            WHEN order_status IN ('canceled', 'unavailable') THEN 'Lost'
            WHEN order_status = 'created' THEN '1_Created'
            WHEN order_status = 'approved' THEN '2_Approved'
            WHEN order_status = 'invoiced' THEN '3_Invoiced'
            WHEN order_status = 'processing' THEN '3_Processing'
            WHEN order_status = 'shipped' THEN '4_Shipped'
            WHEN order_status = 'delivered' THEN '5_Delivered'
            ELSE 'Other'
        END as funnel_stage
    FROM olist_orders
)
SELECT 
    funnel_stage,
    COUNT(*) as orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_total,
    ROUND(COUNT(*) * 100.0 / FIRST_VALUE(COUNT(*)) OVER (ORDER BY funnel_stage), 2) as conversion_from_start
FROM funnel_stages
WHERE funnel_stage != 'Other'
GROUP BY funnel_stage
ORDER BY funnel_stage;

-- 1.2 Simplified funnel (4 key stages)
WITH simplified_funnel AS (
    SELECT 
        order_id,
        CASE 
            WHEN order_purchase_timestamp IS NOT NULL THEN 1 ELSE 0 END as stage_1_placed,
        CASE 
            WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END as stage_2_approved,
        CASE 
            WHEN order_delivered_carrier_date IS NOT NULL THEN 1 ELSE 0 END as stage_3_shipped,
        CASE 
            WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END as stage_4_delivered
    FROM olist_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
)
SELECT 
    '1. Order Placed' as stage,
    SUM(stage_1_placed) as orders,
    100.00 as conversion_rate,
    0.00 as drop_off_rate
FROM simplified_funnel

UNION ALL

SELECT 
    '2. Order Approved',
    SUM(stage_2_approved),
    ROUND(SUM(stage_2_approved) * 100.0 / NULLIF(SUM(stage_1_placed), 0), 2),
    ROUND((SUM(stage_1_placed) - SUM(stage_2_approved)) * 100.0 / NULLIF(SUM(stage_1_placed), 0), 2)
FROM simplified_funnel

UNION ALL

SELECT 
    '3. Order Shipped',
    SUM(stage_3_shipped),
    ROUND(SUM(stage_3_shipped) * 100.0 / NULLIF(SUM(stage_2_approved), 0), 2),
    ROUND((SUM(stage_2_approved) - SUM(stage_3_shipped)) * 100.0 / NULLIF(SUM(stage_2_approved), 0), 2)
FROM simplified_funnel

UNION ALL

SELECT 
    '4. Order Delivered',
    SUM(stage_4_delivered),
    ROUND(SUM(stage_4_delivered) * 100.0 / NULLIF(SUM(stage_3_shipped), 0), 2),
    ROUND((SUM(stage_3_shipped) - SUM(stage_4_delivered)) * 100.0 / NULLIF(SUM(stage_3_shipped), 0), 2)
FROM simplified_funnel;

-- =====================================================
-- SECTION 2: TIME-BASED FUNNEL ANALYSIS
-- =====================================================

-- 2.1 Average time spent in each funnel stage
SELECT 
    'Placed → Approved' as stage_transition,
    COUNT(*) as order_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp)) / 3600)::numeric, 2) as avg_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp)) / 3600)::numeric, 2) as median_hours
FROM olist_orders
WHERE order_approved_at IS NOT NULL

UNION ALL

SELECT 
    'Approved → Shipped',
    COUNT(*),
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at)) / 3600)::numeric, 2),
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at)) / 3600)::numeric, 2)
FROM olist_orders
WHERE order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL

UNION ALL

SELECT 
    'Shipped → Delivered',
    COUNT(*),
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date)) / 3600)::numeric, 2),
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date)) / 3600)::numeric, 2)
FROM olist_orders
WHERE order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL

UNION ALL

SELECT 
    'Placed → Delivered (Total)',
    COUNT(*),
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 3600)::numeric, 2),
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 3600)::numeric, 2)
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL;

-- 2.2 Funnel conversion by month (to identify trends)
WITH monthly_funnel AS (
    SELECT 
        DATE_TRUNC('month', order_purchase_timestamp) as order_month,
        COUNT(*) as orders_placed,
        COUNT(CASE WHEN order_approved_at IS NOT NULL THEN 1 END) as orders_approved,
        COUNT(CASE WHEN order_delivered_carrier_date IS NOT NULL THEN 1 END) as orders_shipped,
        COUNT(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 END) as orders_delivered
    FROM olist_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
)
SELECT 
    order_month,
    orders_placed,
    orders_delivered,
    ROUND(orders_approved * 100.0 / NULLIF(orders_placed, 0), 2) as approval_rate,
    ROUND(orders_shipped * 100.0 / NULLIF(orders_approved, 0), 2) as shipping_rate,
    ROUND(orders_delivered * 100.0 / NULLIF(orders_shipped, 0), 2) as delivery_rate,
    ROUND(orders_delivered * 100.0 / NULLIF(orders_placed, 0), 2) as end_to_end_conversion
FROM monthly_funnel
ORDER BY order_month;

-- =====================================================
-- SECTION 3: DROP-OFF ANALYSIS
-- =====================================================

-- 3.1 Orders that got stuck at each stage
SELECT 
    'Placed but Not Approved' as stuck_stage,
    COUNT(*) as order_count,
    ROUND(SUM(op.payment_value)::numeric, 2) as potential_revenue_lost
FROM olist_orders o
LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
WHERE order_purchase_timestamp IS NOT NULL 
    AND order_approved_at IS NULL
    AND order_status NOT IN ('canceled', 'unavailable')

UNION ALL

SELECT 
    'Approved but Not Shipped',
    COUNT(*),
    ROUND(SUM(op.payment_value)::numeric, 2)
FROM olist_orders o
LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
WHERE order_approved_at IS NOT NULL 
    AND order_delivered_carrier_date IS NULL
    AND order_status NOT IN ('canceled', 'unavailable')

UNION ALL

SELECT 
    'Shipped but Not Delivered',
    COUNT(*),
    ROUND(SUM(op.payment_value)::numeric, 2)
FROM olist_orders o
LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
WHERE order_delivered_carrier_date IS NOT NULL 
    AND order_delivered_customer_date IS NULL
    AND order_status NOT IN ('canceled', 'unavailable');

-- 3.2 Canceled orders analysis
WITH monthly_orders AS (
    SELECT 
        DATE_TRUNC('month', order_purchase_timestamp) as order_month,
        COUNT(*) as total_orders
    FROM olist_orders
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
),
monthly_cancels AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) as cancel_month,
        COUNT(*) as canceled_orders,
        ROUND(SUM(op.payment_value)::numeric, 2) as revenue_lost
    FROM olist_orders o
    LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
    WHERE o.order_status IN ('canceled', 'unavailable')
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT 
    mc.cancel_month,
    mc.canceled_orders,
    mc.revenue_lost,
    mo.total_orders,
    ROUND(mc.canceled_orders * 100.0 / NULLIF(mo.total_orders, 0), 2) as cancel_rate
FROM monthly_cancels mc
LEFT JOIN monthly_orders mo ON mc.cancel_month = mo.order_month
ORDER BY mc.cancel_month;

-- =====================================================
-- SECTION 4: FUNNEL BY SEGMENTS
-- =====================================================

-- 4.1 Funnel conversion by customer state (top 10 states)
WITH state_funnel AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT o.order_id) as orders_placed,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date IS NOT NULL THEN o.order_id END) as orders_delivered
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_state
)
SELECT 
    customer_state,
    orders_placed,
    orders_delivered,
    ROUND(orders_delivered * 100.0 / NULLIF(orders_placed, 0), 2) as delivery_rate
FROM state_funnel
WHERE orders_placed >= 1000  -- Only states with significant volume
ORDER BY orders_placed DESC
LIMIT 10;

-- 4.2 Funnel conversion by order value segment
WITH order_value_funnel AS (
    SELECT 
        o.order_id,
        o.order_status,
        o.order_delivered_customer_date,
        SUM(op.payment_value) as order_value,
        CASE 
            WHEN SUM(op.payment_value) < 50 THEN '1. Low (<$50)'
            WHEN SUM(op.payment_value) < 100 THEN '2. Medium ($50-$100)'
            WHEN SUM(op.payment_value) < 200 THEN '3. High ($100-$200)'
            ELSE '4. Very High ($200+)'
        END as value_segment
    FROM olist_orders o
    JOIN olist_order_payments op ON o.order_id = op.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY o.order_id, o.order_status, o.order_delivered_customer_date
)
SELECT 
    value_segment,
    COUNT(*) as orders,
    COUNT(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 END) as delivered,
    ROUND(COUNT(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as delivery_rate,
    ROUND(AVG(order_value)::numeric, 2) as avg_order_value
FROM order_value_funnel
GROUP BY value_segment
ORDER BY value_segment;

-- 4.3 Funnel conversion by product category (top 10)
WITH category_funnel AS (
    SELECT 
        COALESCE(p.product_category_name, 'Unknown') as category,
        COUNT(DISTINCT o.order_id) as orders,
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) as delivered
    FROM olist_order_items oi
    JOIN olist_orders o ON oi.order_id = o.order_id
    LEFT JOIN olist_products p ON oi.product_id = p.product_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY p.product_category_name
)
SELECT 
    category,
    orders,
    delivered,
    ROUND(delivered * 100.0 / NULLIF(orders, 0), 2) as delivery_rate
FROM category_funnel
ORDER BY orders DESC
LIMIT 10;

-- =====================================================
-- SECTION 5: KEY FUNNEL INSIGHTS
-- =====================================================

-- 5.1 Overall funnel summary for dashboard
WITH funnel_metrics AS (
    SELECT 
        COUNT(*) as total_orders,
        COUNT(CASE WHEN order_approved_at IS NOT NULL THEN 1 END) as approved_orders,
        COUNT(CASE WHEN order_delivered_carrier_date IS NOT NULL THEN 1 END) as shipped_orders,
        COUNT(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 END) as delivered_orders,
        COUNT(CASE WHEN order_status IN ('canceled', 'unavailable') THEN 1 END) as canceled_orders
    FROM olist_orders
)
SELECT 
    total_orders,
    approved_orders,
    ROUND(approved_orders * 100.0 / total_orders, 2) as approval_rate,
    shipped_orders,
    ROUND(shipped_orders * 100.0 / approved_orders, 2) as shipping_rate,
    delivered_orders,
    ROUND(delivered_orders * 100.0 / shipped_orders, 2) as delivery_rate,
    canceled_orders,
    ROUND(canceled_orders * 100.0 / total_orders, 2) as cancellation_rate,
    ROUND(delivered_orders * 100.0 / total_orders, 2) as overall_success_rate
FROM funnel_metrics;