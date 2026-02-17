-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- 03 - DATA EXPLORATION
-- =====================================================
-- Purpose: Understand the dataset before building funnel & cohort analyses
-- =====================================================

-- =====================================================
-- SECTION 1: CUSTOMER OVERVIEW
-- =====================================================

-- 1.1 Total unique customers vs total orders
SELECT 
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    COUNT(DISTINCT c.customer_id) as customer_records,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(COUNT(DISTINCT o.order_id)::numeric / COUNT(DISTINCT c.customer_unique_id), 2) as orders_per_customer
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id;

-- 1.2 Customer geographic distribution (top 10 states)
SELECT 
    customer_state,
    COUNT(DISTINCT customer_unique_id) as customer_count,
    ROUND(COUNT(DISTINCT customer_unique_id) * 100.0 / SUM(COUNT(DISTINCT customer_unique_id)) OVER (), 2) as pct_of_total
FROM olist_customers
GROUP BY customer_state
ORDER BY customer_count DESC
LIMIT 10;

-- 1.3 Repeat customer analysis
WITH customer_order_counts AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) as order_count
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 - One-time'
        WHEN order_count = 2 THEN '2 - Two orders'
        WHEN order_count = 3 THEN '3 - Three orders'
        WHEN order_count >= 4 THEN '4+ - Four or more'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM customer_order_counts
GROUP BY 
    CASE 
        WHEN order_count = 1 THEN '1 - One-time'
        WHEN order_count = 2 THEN '2 - Two orders'
        WHEN order_count = 3 THEN '3 - Three orders'
        WHEN order_count >= 4 THEN '4+ - Four or more'
    END
ORDER BY customer_segment;

-- =====================================================
-- SECTION 2: ORDER TRENDS
-- =====================================================

-- 2.1 Monthly order volume trend
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp) as order_month,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100, 2) as delivery_rate_pct
FROM olist_orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY order_month;

-- 2.2 Day of week pattern
SELECT 
    TO_CHAR(order_purchase_timestamp, 'Day') as day_of_week,
    EXTRACT(ISODOW FROM order_purchase_timestamp) as day_number,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_orders
FROM olist_orders
GROUP BY day_of_week, day_number
ORDER BY day_number;

-- 2.3 Hour of day pattern
SELECT 
    EXTRACT(HOUR FROM order_purchase_timestamp) as hour_of_day,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_orders
FROM olist_orders
GROUP BY EXTRACT(HOUR FROM order_purchase_timestamp)
ORDER BY hour_of_day;

-- =====================================================
-- SECTION 3: REVENUE ANALYSIS
-- =====================================================

-- 3.1 Overall revenue metrics
SELECT 
    COUNT(DISTINCT op.order_id) as orders_with_payments,
    ROUND(SUM(op.payment_value)::numeric, 2) as total_revenue,
    ROUND(AVG(op.payment_value)::numeric, 2) as avg_payment_per_transaction,
    ROUND(MIN(op.payment_value)::numeric, 2) as min_payment,
    ROUND(MAX(op.payment_value)::numeric, 2) as max_payment,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY op.payment_value)::numeric, 2) as median_payment
FROM olist_order_payments op;

-- 3.2 Monthly revenue trend
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) as revenue_month,
    COUNT(DISTINCT o.order_id) as orders,
    ROUND(SUM(op.payment_value)::numeric, 2) as total_revenue,
    ROUND(AVG(op.payment_value)::numeric, 2) as avg_order_value
FROM olist_orders o
JOIN olist_order_payments op ON o.order_id = op.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY revenue_month;

-- 3.3 Payment type distribution
SELECT 
    payment_type,
    COUNT(*) as transaction_count,
    ROUND(SUM(payment_value)::numeric, 2) as total_value,
    ROUND(AVG(payment_value)::numeric, 2) as avg_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_transactions
FROM olist_order_payments
GROUP BY payment_type
ORDER BY total_value DESC;

-- 3.4 Revenue by order status
SELECT 
    o.order_status,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(SUM(op.payment_value)::numeric, 2) as total_revenue,
    ROUND(AVG(op.payment_value)::numeric, 2) as avg_order_value,
    ROUND(COUNT(DISTINCT o.order_id) * 100.0 / SUM(COUNT(DISTINCT o.order_id)) OVER (), 2) as pct_of_orders
FROM olist_orders o
LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
GROUP BY o.order_status
ORDER BY order_count DESC;

-- =====================================================
-- SECTION 4: PRODUCT ANALYSIS
-- =====================================================

-- 4.1 Top 15 product categories by revenue
SELECT 
    COALESCE(p.product_category_name, 'Unknown') as category,
    COUNT(DISTINCT oi.order_id) as orders,
    SUM(oi.price + oi.freight_value) as total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::numeric, 2) as avg_item_value,
    COUNT(*) as items_sold
FROM olist_order_items oi
LEFT JOIN olist_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 15;

-- 4.2 Average basket size (items per order)
SELECT 
    items_per_order,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM (
    SELECT 
        order_id,
        COUNT(*) as items_per_order
    FROM olist_order_items
    GROUP BY order_id
) basket_sizes
GROUP BY items_per_order
ORDER BY items_per_order;

-- =====================================================
-- SECTION 5: CUSTOMER SATISFACTION
-- =====================================================

-- 5.1 Review score distribution
SELECT 
    review_score,
    COUNT(*) as review_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM olist_order_reviews
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score DESC;

-- 5.2 Average review score by order status
SELECT 
    o.order_status,
    COUNT(DISTINCT r.review_id) as review_count,
    ROUND(AVG(r.review_score)::numeric, 2) as avg_review_score
FROM olist_orders o
JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE r.review_score IS NOT NULL
GROUP BY o.order_status
HAVING COUNT(DISTINCT r.review_id) > 100
ORDER BY avg_review_score DESC;

-- 5.3 Review score vs order value
SELECT 
    r.review_score,
    COUNT(*) as orders,
    ROUND(AVG(op.payment_value)::numeric, 2) as avg_order_value
FROM olist_order_reviews r
JOIN olist_order_payments op ON r.order_id = op.order_id
WHERE r.review_score IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score DESC;

-- =====================================================
-- SECTION 6: DELIVERY PERFORMANCE
-- =====================================================

-- 6.1 Average delivery times
SELECT 
    COUNT(*) as delivered_orders,
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1) as avg_delivery_days,
    ROUND(MIN(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1) as min_delivery_days,
    ROUND(MAX(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1) as max_delivery_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1) as median_delivery_days
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
    AND order_status = 'delivered';

-- 6.2 On-time vs late delivery
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
        ELSE 'Unknown'
    END as delivery_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(r.review_score)::numeric, 2) as avg_review_score
FROM olist_orders o
LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
        ELSE 'Unknown'
    END;

-- =====================================================
-- SECTION 7: KEY INSIGHTS SUMMARY
-- =====================================================

-- 7.1 Business health metrics snapshot
WITH metrics AS (
    SELECT 
        COUNT(DISTINCT c.customer_unique_id) as total_customers,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(op.payment_value) as total_revenue,
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) as delivered_orders,
        AVG(r.review_score) as avg_review_score
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
    LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
)
SELECT 
    total_customers,
    total_orders,
    ROUND(total_orders::numeric / total_customers, 2) as orders_per_customer,
    ROUND(total_revenue::numeric, 2) as total_revenue,
    ROUND(total_revenue::numeric / total_orders, 2) as revenue_per_order,
    ROUND(delivered_orders::numeric * 100.0 / total_orders, 2) as delivery_rate_pct,
    ROUND(avg_review_score::numeric, 2) as avg_review_score
FROM metrics;