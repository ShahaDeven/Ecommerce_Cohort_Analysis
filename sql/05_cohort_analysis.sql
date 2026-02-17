-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- 05 - COHORT ANALYSIS
-- =====================================================
-- Purpose: Analyze customer retention and behavior by acquisition cohort
-- =====================================================

-- =====================================================
-- SECTION 1: COHORT DEFINITION & SETUP
-- =====================================================

-- 1.1 Define customer cohorts by first purchase month
CREATE OR REPLACE VIEW customer_cohorts AS
SELECT 
    c.customer_unique_id,
    MIN(o.order_purchase_timestamp) as first_purchase_date,
    DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) as cohort_month,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(op.payment_value) as lifetime_value
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_unique_id;

-- Verify cohort view
SELECT 
    cohort_month,
    COUNT(*) as customers_acquired,
    ROUND(AVG(total_orders)::numeric, 2) as avg_orders_per_customer,
    ROUND(AVG(lifetime_value)::numeric, 2) as avg_lifetime_value
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;

-- =====================================================
-- SECTION 2: RETENTION COHORT ANALYSIS
-- =====================================================

-- 2.1 Monthly retention cohort table (classic retention matrix)
WITH cohort_data AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        o.order_purchase_timestamp,
        DATE_TRUNC('month', o.order_purchase_timestamp) as purchase_month,
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) as months_since_cohort
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) as cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
),
retention_data AS (
    SELECT 
        cd.cohort_month,
        cd.months_since_cohort,
        COUNT(DISTINCT cd.customer_unique_id) as active_customers,
        cs.cohort_customers
    FROM cohort_data cd
    JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
    WHERE cd.months_since_cohort <= 12  -- First 12 months
    GROUP BY cd.cohort_month, cd.months_since_cohort, cs.cohort_customers
)
SELECT 
    cohort_month,
    cohort_customers,
    months_since_cohort,
    active_customers,
    ROUND(active_customers * 100.0 / cohort_customers, 2) as retention_rate
FROM retention_data
ORDER BY cohort_month, months_since_cohort;

-- 2.2 Retention rate by cohort (pivoted view for heatmap)
-- This query creates a retention matrix suitable for visualization
WITH cohort_data AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp) as purchase_month,
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) as months_since_cohort
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) as total_customers
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT 
    cd.cohort_month,
    cs.total_customers as cohort_size,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 0 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_0,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 1 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_1,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 2 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_2,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 3 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_3,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 4 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_4,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 5 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_5,
    ROUND(COUNT(DISTINCT CASE WHEN cd.months_since_cohort = 6 THEN cd.customer_unique_id END) * 100.0 / cs.total_customers, 2) as month_6
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
WHERE cd.months_since_cohort <= 6
GROUP BY cd.cohort_month, cs.total_customers
ORDER BY cd.cohort_month;

-- =====================================================
-- SECTION 3: REPEAT PURCHASE ANALYSIS
-- =====================================================

-- 3.1 Repeat purchase rate by cohort
WITH cohort_purchases AS (
    SELECT 
        cc.cohort_month,
        cc.customer_unique_id,
        cc.total_orders
    FROM customer_cohorts cc
)
SELECT 
    cohort_month,
    COUNT(*) as total_customers,
    COUNT(CASE WHEN total_orders >= 2 THEN 1 END) as repeat_customers,
    ROUND(COUNT(CASE WHEN total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) as repeat_purchase_rate,
    ROUND(AVG(total_orders)::numeric, 2) as avg_orders_per_customer
FROM cohort_purchases
GROUP BY cohort_month
ORDER BY cohort_month;

-- 3.2 Time to second purchase analysis
WITH customer_order_sequence AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (PARTITION BY cc.customer_unique_id ORDER BY o.order_purchase_timestamp) as order_number
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
second_purchase_timing AS (
    SELECT 
        first.customer_unique_id,
        first.cohort_month,
        first.order_purchase_timestamp as first_purchase,
        second.order_purchase_timestamp as second_purchase,
        EXTRACT(DAY FROM (second.order_purchase_timestamp - first.order_purchase_timestamp)) as days_to_second_purchase
    FROM customer_order_sequence first
    JOIN customer_order_sequence second 
        ON first.customer_unique_id = second.customer_unique_id 
        AND first.order_number = 1 
        AND second.order_number = 2
)
SELECT 
    cohort_month,
    COUNT(*) as repeat_customers,
    ROUND(AVG(days_to_second_purchase)::numeric, 1) as avg_days_to_repeat,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_to_second_purchase)::numeric, 1) as median_days_to_repeat,
    ROUND(MIN(days_to_second_purchase)::numeric, 1) as min_days,
    ROUND(MAX(days_to_second_purchase)::numeric, 1) as max_days
FROM second_purchase_timing
GROUP BY cohort_month
ORDER BY cohort_month;

-- 3.3 Distribution of days to second purchase
WITH customer_order_sequence AS (
    SELECT 
        cc.customer_unique_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (PARTITION BY cc.customer_unique_id ORDER BY o.order_purchase_timestamp) as order_number
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
second_purchase_timing AS (
    SELECT 
        EXTRACT(DAY FROM (second.order_purchase_timestamp - first.order_purchase_timestamp)) as days_to_second_purchase
    FROM customer_order_sequence first
    JOIN customer_order_sequence second 
        ON first.customer_unique_id = second.customer_unique_id 
        AND first.order_number = 1 
        AND second.order_number = 2
)
SELECT 
    CASE 
        WHEN days_to_second_purchase <= 7 THEN '1. Within 1 week'
        WHEN days_to_second_purchase <= 30 THEN '2. Within 1 month'
        WHEN days_to_second_purchase <= 60 THEN '3. Within 2 months'
        WHEN days_to_second_purchase <= 90 THEN '4. Within 3 months'
        WHEN days_to_second_purchase <= 180 THEN '5. Within 6 months'
        ELSE '6. After 6 months'
    END as timeframe,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM second_purchase_timing
GROUP BY 
    CASE 
        WHEN days_to_second_purchase <= 7 THEN '1. Within 1 week'
        WHEN days_to_second_purchase <= 30 THEN '2. Within 1 month'
        WHEN days_to_second_purchase <= 60 THEN '3. Within 2 months'
        WHEN days_to_second_purchase <= 90 THEN '4. Within 3 months'
        WHEN days_to_second_purchase <= 180 THEN '5. Within 6 months'
        ELSE '6. After 6 months'
    END
ORDER BY timeframe;

-- =====================================================
-- SECTION 4: COHORT REVENUE ANALYSIS
-- =====================================================

-- 4.1 Revenue by cohort and age
WITH cohort_revenue AS (
    SELECT 
        cc.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp) as purchase_month,
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) as months_since_cohort,
        SUM(op.payment_value) as revenue
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_payments op ON o.order_id = op.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY cc.cohort_month, DATE_TRUNC('month', o.order_purchase_timestamp), months_since_cohort
),
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) as total_customers
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT 
    cr.cohort_month,
    cs.total_customers as cohort_size,
    cr.months_since_cohort,
    ROUND(cr.revenue::numeric, 2) as total_revenue,
    ROUND((cr.revenue / cs.total_customers)::numeric, 2) as revenue_per_customer
FROM cohort_revenue cr
JOIN cohort_size cs ON cr.cohort_month = cs.cohort_month
WHERE cr.months_since_cohort <= 12
ORDER BY cr.cohort_month, cr.months_since_cohort;

-- 4.2 Cumulative revenue by cohort
WITH cohort_revenue AS (
    SELECT 
        cc.cohort_month,
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) as months_since_cohort,
        SUM(op.payment_value) as revenue
    FROM customer_cohorts cc
    JOIN olist_customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_payments op ON o.order_id = op.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY cc.cohort_month, months_since_cohort
),
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) as total_customers
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT 
    cr.cohort_month,
    cs.total_customers as cohort_size,
    cr.months_since_cohort,
    ROUND(SUM(cr.revenue) OVER (PARTITION BY cr.cohort_month ORDER BY cr.months_since_cohort)::numeric, 2) as cumulative_revenue,
    ROUND((SUM(cr.revenue) OVER (PARTITION BY cr.cohort_month ORDER BY cr.months_since_cohort) / cs.total_customers)::numeric, 2) as cumulative_revenue_per_customer
FROM cohort_revenue cr
JOIN cohort_size cs ON cr.cohort_month = cs.cohort_month
WHERE cr.months_since_cohort <= 12
ORDER BY cr.cohort_month, cr.months_since_cohort;

-- =====================================================
-- SECTION 5: COHORT QUALITY COMPARISON
-- =====================================================

-- 5.1 Compare cohort quality metrics
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_unique_id) as customers,
    ROUND(AVG(total_orders)::numeric, 2) as avg_orders,
    ROUND(AVG(lifetime_value)::numeric, 2) as avg_ltv,
    COUNT(CASE WHEN total_orders >= 2 THEN 1 END) as repeat_customers,
    ROUND(COUNT(CASE WHEN total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) as repeat_rate
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;

-- 5.2 Best vs worst performing cohorts
WITH cohort_performance AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) as customers,
        ROUND(AVG(total_orders)::numeric, 2) as avg_orders,
        ROUND(AVG(lifetime_value)::numeric, 2) as avg_ltv,
        ROUND(COUNT(CASE WHEN total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) as repeat_rate
    FROM customer_cohorts
    GROUP BY cohort_month
    HAVING COUNT(DISTINCT customer_unique_id) >= 1000  -- Only cohorts with significant size
)
SELECT 
    'Best Performing' as cohort_type,
    cohort_month,
    customers,
    avg_orders,
    avg_ltv,
    repeat_rate
FROM cohort_performance
ORDER BY repeat_rate DESC
LIMIT 5

UNION ALL

SELECT 
    'Worst Performing',
    cohort_month,
    customers,
    avg_orders,
    avg_ltv,
    repeat_rate
FROM cohort_performance
ORDER BY repeat_rate ASC
LIMIT 5;

-- =====================================================
-- SECTION 6: KEY COHORT INSIGHTS
-- =====================================================

-- 6.1 Overall retention summary
WITH retention_summary AS (
    SELECT 
        cc.cohort_month,
        COUNT(DISTINCT cc.customer_unique_id) as cohort_size,
        COUNT(DISTINCT CASE 
            WHEN EXISTS (
                SELECT 1 FROM olist_customers c2
                JOIN olist_orders o2 ON c2.customer_id = o2.customer_id
                WHERE c2.customer_unique_id = cc.customer_unique_id
                AND DATE_TRUNC('month', o2.order_purchase_timestamp) = cc.cohort_month + INTERVAL '1 month'
            ) THEN cc.customer_unique_id 
        END) as month_1_retained
    FROM customer_cohorts cc
    GROUP BY cc.cohort_month
)
SELECT 
    ROUND(AVG(month_1_retained * 100.0 / cohort_size)::numeric, 2) as avg_month_1_retention,
    ROUND(MIN(month_1_retained * 100.0 / cohort_size)::numeric, 2) as min_month_1_retention,
    ROUND(MAX(month_1_retained * 100.0 / cohort_size)::numeric, 2) as max_month_1_retention
FROM retention_summary
WHERE cohort_size >= 100;
