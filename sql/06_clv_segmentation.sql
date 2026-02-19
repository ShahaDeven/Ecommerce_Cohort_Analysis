-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- 06 - CUSTOMER LIFETIME VALUE (CLV) SEGMENTATION
-- =====================================================
-- Purpose: Segment customers by lifetime value and identify high-value characteristics
-- =====================================================

-- =====================================================
-- SECTION 1: CLV CALCULATION
-- =====================================================

-- 1.1 Calculate CLV for each customer
CREATE OR REPLACE VIEW customer_lifetime_value AS
SELECT 
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id) as total_orders,
    MIN(o.order_purchase_timestamp) as first_purchase_date,
    MAX(o.order_purchase_timestamp) as last_purchase_date,
    EXTRACT(DAY FROM (MAX(o.order_purchase_timestamp) - MIN(o.order_purchase_timestamp))) as customer_lifetime_days,
    SUM(op.payment_value) as total_revenue,
    AVG(op.payment_value) as avg_order_value,
    SUM(oi.price) as total_product_value,
    SUM(oi.freight_value) as total_shipping_paid,
    ROUND(AVG(COALESCE(r.review_score, 0))::numeric, 2) as avg_review_score,
    COUNT(DISTINCT r.review_id) as reviews_left
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_unique_id, c.customer_state;

-- Verify CLV view
SELECT 
    COUNT(*) as total_customers,
    ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
    ROUND(AVG(total_revenue)::numeric, 2) as avg_clv,
    ROUND(AVG(total_orders)::numeric, 2) as avg_orders
FROM customer_lifetime_value;

-- =====================================================
-- SECTION 2: CLV SEGMENTATION
-- =====================================================

-- 2.1 Define CLV segments using percentiles
WITH clv_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) as p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) as p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) as p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) as p90,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_revenue) as p95
    FROM customer_lifetime_value
)
SELECT 
    clv.customer_unique_id,
    clv.total_revenue,
    clv.total_orders,
    clv.avg_order_value,
    CASE 
        WHEN clv.total_revenue >= p.p95 THEN '1. VIP (Top 5%)'
        WHEN clv.total_revenue >= p.p90 THEN '2. High Value (Top 10%)'
        WHEN clv.total_revenue >= p.p75 THEN '3. Medium-High (Top 25%)'
        WHEN clv.total_revenue >= p.p50 THEN '4. Medium (Top 50%)'
        ELSE '5. Low Value (Bottom 50%)'
    END as clv_segment
FROM customer_lifetime_value clv
CROSS JOIN clv_percentiles p
ORDER BY clv.total_revenue DESC
LIMIT 100;  -- Preview top 100

-- 2.2 CLV segment distribution
WITH clv_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) as p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) as p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) as p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) as p90,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_revenue) as p95
    FROM customer_lifetime_value
),
segmented_customers AS (
    SELECT 
        clv.*,
        CASE 
            WHEN clv.total_revenue >= p.p95 THEN '1. VIP (Top 5%)'
            WHEN clv.total_revenue >= p.p90 THEN '2. High Value (Top 10%)'
            WHEN clv.total_revenue >= p.p75 THEN '3. Medium-High (Top 25%)'
            WHEN clv.total_revenue >= p.p50 THEN '4. Medium (Top 50%)'
            ELSE '5. Low Value (Bottom 50%)'
        END as clv_segment
    FROM customer_lifetime_value clv
    CROSS JOIN clv_percentiles p
)
SELECT 
    clv_segment,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_customers,
    ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
    ROUND(SUM(total_revenue) * 100.0 / SUM(SUM(total_revenue)) OVER (), 2) as pct_of_revenue,
    ROUND(AVG(total_revenue)::numeric, 2) as avg_clv,
    ROUND(AVG(total_orders)::numeric, 2) as avg_orders,
    ROUND(AVG(avg_order_value)::numeric, 2) as avg_order_value
FROM segmented_customers
GROUP BY clv_segment
ORDER BY clv_segment;

-- 2.3 Alternative segmentation: RFM (Recency, Frequency, Monetary)
WITH customer_rfm AS (
    SELECT 
        customer_unique_id,
        EXTRACT(DAY FROM (CURRENT_DATE - last_purchase_date)) as recency_days,
        total_orders as frequency,
        total_revenue as monetary
    FROM customer_lifetime_value
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,  -- Lower recency = better
        NTILE(5) OVER (ORDER BY frequency) as f_score,
        NTILE(5) OVER (ORDER BY monetary) as m_score
    FROM customer_rfm
)
SELECT 
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END as rfm_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(recency_days)::numeric, 1) as avg_recency_days,
    ROUND(AVG(frequency)::numeric, 2) as avg_frequency,
    ROUND(AVG(monetary)::numeric, 2) as avg_monetary
FROM rfm_scores
GROUP BY 
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END
ORDER BY customer_count DESC;

-- =====================================================
-- SECTION 3: HIGH-VALUE CUSTOMER CHARACTERISTICS
-- =====================================================

-- 3.1 Geographic distribution of high-value customers
WITH clv_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) as p90
    FROM customer_lifetime_value
)
SELECT 
    clv.customer_state,
    COUNT(*) as high_value_customers,
    ROUND(SUM(clv.total_revenue)::numeric, 2) as total_revenue,
    ROUND(AVG(clv.total_revenue)::numeric, 2) as avg_clv,
    ROUND(AVG(clv.total_orders)::numeric, 2) as avg_orders
FROM customer_lifetime_value clv
CROSS JOIN clv_percentiles p
WHERE clv.total_revenue >= p.p90
GROUP BY clv.customer_state
ORDER BY high_value_customers DESC
LIMIT 10;

-- 3.2 Product preferences of high-value customers
WITH clv_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) as p90
    FROM customer_lifetime_value
),
high_value_customers AS (
    SELECT customer_unique_id
    FROM customer_lifetime_value clv
    CROSS JOIN clv_percentiles p
    WHERE clv.total_revenue >= p.p90
)
SELECT 
    COALESCE(pr.product_category_name, 'Unknown') as category,
    COUNT(DISTINCT oi.order_id) as orders,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) as total_spent,
    ROUND(AVG(oi.price + oi.freight_value)::numeric, 2) as avg_item_value
FROM high_value_customers hvc
JOIN olist_customers c ON hvc.customer_unique_id = c.customer_unique_id
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN olist_order_items oi ON o.order_id = oi.order_id
LEFT JOIN olist_products pr ON oi.product_id = pr.product_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY pr.product_category_name
ORDER BY total_spent DESC
LIMIT 15;

-- 3.3 Satisfaction levels by CLV segment
WITH clv_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) as p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) as p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) as p90,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_revenue) as p95
    FROM customer_lifetime_value
),
segmented_satisfaction AS (
    SELECT 
        clv.customer_unique_id,
        clv.avg_review_score,
        clv.reviews_left,
        CASE 
            WHEN clv.total_revenue >= p.p95 THEN '1. VIP (Top 5%)'
            WHEN clv.total_revenue >= p.p90 THEN '2. High Value (Top 10%)'
            WHEN clv.total_revenue >= p.p75 THEN '3. Medium-High (Top 25%)'
            WHEN clv.total_revenue >= p.p50 THEN '4. Medium (Top 50%)'
            ELSE '5. Low Value (Bottom 50%)'
        END as clv_segment
    FROM customer_lifetime_value clv
    CROSS JOIN clv_percentiles p
)
SELECT 
    clv_segment,
    COUNT(*) as customers,
    ROUND(AVG(avg_review_score)::numeric, 2) as avg_satisfaction_score,
    ROUND(AVG(reviews_left)::numeric, 2) as avg_reviews_per_customer,
    COUNT(CASE WHEN avg_review_score >= 4 THEN 1 END) as satisfied_customers,
    ROUND(COUNT(CASE WHEN avg_review_score >= 4 THEN 1 END) * 100.0 / COUNT(*), 2) as pct_satisfied
FROM segmented_satisfaction
WHERE reviews_left > 0
GROUP BY clv_segment
ORDER BY clv_segment;

-- =====================================================
-- SECTION 4: CLV PREDICTIVE INDICATORS
-- =====================================================

-- 4.1 First order value vs eventual CLV
WITH first_order_value AS (
    SELECT 
        c.customer_unique_id,
        FIRST_VALUE(op.payment_value) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) as first_order_amount
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_payments op ON o.order_id = op.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
first_order_unique AS (
    SELECT DISTINCT 
        customer_unique_id,
        first_order_amount
    FROM first_order_value
)
SELECT 
    CASE 
        WHEN fou.first_order_amount < 50 THEN '1. <$50'
        WHEN fou.first_order_amount < 100 THEN '2. $50-$100'
        WHEN fou.first_order_amount < 200 THEN '3. $100-$200'
        ELSE '4. $200+'
    END as first_order_segment,
    COUNT(*) as customers,
    ROUND(AVG(clv.total_revenue)::numeric, 2) as avg_lifetime_value,
    ROUND(AVG(clv.total_orders)::numeric, 2) as avg_total_orders,
    COUNT(CASE WHEN clv.total_orders >= 2 THEN 1 END) as repeat_customers,
    ROUND(COUNT(CASE WHEN clv.total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) as repeat_rate
FROM first_order_unique fou
JOIN customer_lifetime_value clv ON fou.customer_unique_id = clv.customer_unique_id
GROUP BY 
    CASE 
        WHEN fou.first_order_amount < 50 THEN '1. <$50'
        WHEN fou.first_order_amount < 100 THEN '2. $50-$100'
        WHEN fou.first_order_amount < 200 THEN '3. $100-$200'
        ELSE '4. $200+'
    END
ORDER BY first_order_segment;

-- 4.2 Time to second purchase as CLV indicator
WITH customer_order_sequence AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) as order_number
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
second_purchase_timing AS (
    SELECT 
        first.customer_unique_id,
        EXTRACT(DAY FROM (second.order_purchase_timestamp - first.order_purchase_timestamp)) as days_to_second_purchase
    FROM customer_order_sequence first
    JOIN customer_order_sequence second 
        ON first.customer_unique_id = second.customer_unique_id 
        AND first.order_number = 1 
        AND second.order_number = 2
)
SELECT 
    CASE 
        WHEN spt.days_to_second_purchase <= 30 THEN '1. Within 30 days'
        WHEN spt.days_to_second_purchase <= 60 THEN '2. 31-60 days'
        WHEN spt.days_to_second_purchase <= 90 THEN '3. 61-90 days'
        ELSE '4. 90+ days'
    END as time_to_repeat_segment,
    COUNT(*) as customers,
    ROUND(AVG(clv.total_revenue)::numeric, 2) as avg_lifetime_value,
    ROUND(AVG(clv.total_orders)::numeric, 2) as avg_total_orders
FROM second_purchase_timing spt
JOIN customer_lifetime_value clv ON spt.customer_unique_id = clv.customer_unique_id
GROUP BY 
    CASE 
        WHEN spt.days_to_second_purchase <= 30 THEN '1. Within 30 days'
        WHEN spt.days_to_second_purchase <= 60 THEN '2. 31-60 days'
        WHEN spt.days_to_second_purchase <= 90 THEN '3. 61-90 days'
        ELSE '4. 90+ days'
    END
ORDER BY time_to_repeat_segment;

-- =====================================================
-- SECTION 5: CLV OPTIMIZATION OPPORTUNITIES
-- =====================================================

-- 5.1 One-time customers with high first order value (upsell opportunity)
SELECT 
    clv.customer_unique_id,
    clv.customer_state,
    clv.total_revenue as first_order_value,
    clv.first_purchase_date,
    EXTRACT(DAY FROM (CURRENT_DATE - clv.first_purchase_date)) as days_since_purchase,
    clv.avg_review_score
FROM customer_lifetime_value clv
WHERE clv.total_orders = 1
    AND clv.total_revenue >= 100  -- High value first order
    AND EXTRACT(DAY FROM (CURRENT_DATE - clv.first_purchase_date)) BETWEEN 30 AND 180  -- Recent but not too recent
ORDER BY clv.total_revenue DESC
LIMIT 100;

-- 5.2 Customers who stopped purchasing (win-back opportunity)
WITH customer_recency AS (
    SELECT 
        clv.customer_unique_id,
        clv.customer_state,
        clv.total_orders,
        clv.total_revenue,
        clv.last_purchase_date,
        EXTRACT(DAY FROM (CURRENT_DATE - clv.last_purchase_date)) as days_since_last_purchase,
        EXTRACT(DAY FROM (clv.last_purchase_date - clv.first_purchase_date)) / NULLIF(clv.total_orders - 1, 0) as avg_days_between_orders
    FROM customer_lifetime_value clv
    WHERE clv.total_orders >= 2  -- Had repeat purchases before
)
SELECT 
    customer_unique_id,
    customer_state,
    total_orders,
    ROUND(total_revenue::numeric, 2) as lifetime_value,
    last_purchase_date,
    days_since_last_purchase,
    ROUND(avg_days_between_orders::numeric, 1) as avg_days_between_orders,
    ROUND((days_since_last_purchase / NULLIF(avg_days_between_orders, 0))::numeric, 1) as recency_vs_avg_ratio
FROM customer_recency
WHERE days_since_last_purchase > (avg_days_between_orders * 2)  -- 2x their normal purchase cycle
    AND total_revenue >= 150  -- Had decent lifetime value
ORDER BY total_revenue DESC
LIMIT 100;

-- 5.3 High-frequency, low-value customers (opportunity to increase basket size)
SELECT 
    customer_unique_id,
    customer_state,
    total_orders,
    ROUND(total_revenue::numeric, 2) as lifetime_value,
    ROUND(avg_order_value::numeric, 2) as avg_order_value,
    ROUND(avg_review_score::numeric, 2) as satisfaction
FROM customer_lifetime_value
WHERE total_orders >= 3  -- Frequent
    AND avg_order_value < 50  -- But low value per order
ORDER BY total_orders DESC
LIMIT 100;

-- =====================================================
-- SECTION 6: CLV SUMMARY METRICS
-- =====================================================

-- 6.1 Overall CLV distribution summary
SELECT 
    COUNT(*) as total_customers,
    ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
    ROUND(AVG(total_revenue)::numeric, 2) as avg_clv,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue)::numeric, 2) as p25_clv,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue)::numeric, 2) as median_clv,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue)::numeric, 2) as p75_clv,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue)::numeric, 2) as p90_clv,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_revenue)::numeric, 2) as p95_clv,
    ROUND(MAX(total_revenue)::numeric, 2) as max_clv
FROM customer_lifetime_value;

-- 6.2 Pareto analysis (80/20 rule)
WITH ranked_customers AS (
    SELECT 
        customer_unique_id,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) as running_total,
        SUM(total_revenue) OVER () as total_revenue_all,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as customer_rank,
        COUNT(*) OVER () as total_customers
    FROM customer_lifetime_value
)
SELECT 
    MIN(customer_rank) as top_n_customers,
    ROUND(MIN(customer_rank) * 100.0 / MAX(total_customers), 2) as pct_of_customers,
    ROUND(MIN(running_total)::numeric, 2) as cumulative_revenue,
    ROUND(MIN(running_total) * 100.0 / MAX(total_revenue_all), 2) as pct_of_total_revenue
FROM ranked_customers
WHERE running_total <= total_revenue_all * 0.80  -- First 80% of revenue
GROUP BY total_revenue_all;
