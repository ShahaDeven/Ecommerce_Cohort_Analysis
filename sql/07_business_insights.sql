-- =====================================================
-- E-COMMERCE FUNNEL & COHORT ANALYSIS PROJECT
-- 07 - KEY BUSINESS INSIGHTS & RECOMMENDATIONS
-- =====================================================

-- =====================================================
-- INSIGHT 1: FUNNEL DROP-OFF ANALYSIS
-- =====================================================

SELECT 
    'FUNNEL ANALYSIS'                   as insight_category,
    'Overall Conversion Rate'           as metric_name,
    ROUND(COUNT(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as metric_value,
    'Placed → Delivered'                as details
FROM olist_orders
WHERE order_status NOT IN ('canceled', 'unavailable')

UNION ALL

SELECT 
    'FUNNEL ANALYSIS',
    'Biggest Drop-off Stage',
    ROUND((COUNT(*) - COUNT(CASE WHEN order_delivered_carrier_date IS NOT NULL THEN 1 END)) * 100.0 / COUNT(*), 2),
    'Approved → Shipped drop-off %'
FROM olist_orders
WHERE order_approved_at IS NOT NULL
    AND order_status NOT IN ('canceled', 'unavailable')

UNION ALL

SELECT 
    'FUNNEL ANALYSIS',
    'Potential Revenue Lost',
    ROUND(SUM(op.payment_value)::numeric, 2),
    'Orders approved but not delivered ($)'
FROM olist_orders o
JOIN olist_order_payments op ON o.order_id = op.order_id
WHERE o.order_approved_at IS NOT NULL 
    AND o.order_delivered_customer_date IS NULL
    AND o.order_status NOT IN ('canceled', 'unavailable');

-- =====================================================
-- INSIGHT 2: RETENTION & REPEAT PURCHASE
-- =====================================================

WITH repeat_analysis AS (
    SELECT 
        COUNT(DISTINCT customer_unique_id) as total_customers,
        COUNT(DISTINCT CASE WHEN total_orders >= 2 THEN customer_unique_id END) as repeat_customers
    FROM customer_cohorts
),
second_purchase AS (
    SELECT 
        c.customer_unique_id,
        EXTRACT(DAY FROM (
            MIN(CASE WHEN o.order_purchase_timestamp > first_order.min_date 
                THEN o.order_purchase_timestamp END) - first_order.min_date
        )) as days_to_second
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN (
        SELECT c2.customer_unique_id, MIN(o2.order_purchase_timestamp) as min_date
        FROM olist_customers c2
        JOIN olist_orders o2 ON c2.customer_id = o2.customer_id
        GROUP BY c2.customer_unique_id
    ) first_order ON c.customer_unique_id = first_order.customer_unique_id
    GROUP BY c.customer_unique_id, first_order.min_date
    HAVING COUNT(DISTINCT o.order_id) >= 2
)
SELECT 
    'RETENTION'                         as insight_category,
    'Repeat Purchase Rate'              as metric_name,
    ROUND(repeat_customers * 100.0 / total_customers, 2) as metric_value,
    'Customers who made 2+ purchases'   as details
FROM repeat_analysis

UNION ALL

SELECT 
    'RETENTION',
    'Average Time to 2nd Purchase',
    ROUND(AVG(days_to_second)::numeric, 1),
    'Days from first to second purchase'
FROM second_purchase;

-- =====================================================
-- INSIGHT 3: CUSTOMER LIFETIME VALUE
-- =====================================================

WITH p90 AS (
    SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) as threshold
    FROM customer_lifetime_value
)
SELECT 
    'CLV'                               as insight_category,
    'Average CLV'                       as metric_name,
    ROUND(AVG(total_revenue)::numeric, 2) as metric_value,
    'Average revenue per customer ($)'  as details
FROM customer_lifetime_value

UNION ALL

SELECT 
    'CLV',
    'Top 10% Customer Count',
    COUNT(*)::numeric,
    'Number of high-value customers'
FROM customer_lifetime_value clv
CROSS JOIN p90
WHERE clv.total_revenue >= p90.threshold

UNION ALL

SELECT 
    'CLV',
    'Top 10% Revenue Share %',
    ROUND(SUM(clv.total_revenue) * 100.0 / (SELECT SUM(total_revenue) FROM customer_lifetime_value), 2),
    '% of total revenue from top 10%'
FROM customer_lifetime_value clv
CROSS JOIN p90
WHERE clv.total_revenue >= p90.threshold

UNION ALL

SELECT 
    'CLV',
    'One-time Customer %',
    ROUND(COUNT(CASE WHEN total_orders = 1 THEN 1 END) * 100.0 / COUNT(*), 2),
    'Customers who never returned'
FROM customer_lifetime_value;

-- =====================================================
-- INSIGHT 4: COHORT PERFORMANCE
-- =====================================================

WITH cohort_metrics AS (
    SELECT 
        cohort_month,
        COUNT(*) as cohort_size,
        AVG(total_orders) as avg_orders,
        AVG(lifetime_value) as avg_ltv,
        COUNT(CASE WHEN total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*) as repeat_rate
    FROM customer_cohorts
    GROUP BY cohort_month
    HAVING COUNT(*) >= 1000
)
SELECT 
    'COHORT PERFORMANCE'                as insight_category,
    'Best Cohort Repeat Rate'           as metric_name,
    ROUND(MAX(repeat_rate)::numeric, 2) as metric_value,
    'Best: ' || TO_CHAR(
        (SELECT cohort_month FROM cohort_metrics ORDER BY repeat_rate DESC LIMIT 1), 
        'YYYY-MM'
    ) as details
FROM cohort_metrics

UNION ALL

SELECT 
    'COHORT PERFORMANCE',
    'Worst Cohort Repeat Rate',
    ROUND(MIN(repeat_rate)::numeric, 2),
    'Worst: ' || TO_CHAR(
        (SELECT cohort_month FROM cohort_metrics ORDER BY repeat_rate ASC LIMIT 1), 
        'YYYY-MM'
    )
FROM cohort_metrics

UNION ALL

SELECT 
    'COHORT PERFORMANCE',
    'Average Cohort Repeat Rate',
    ROUND(AVG(repeat_rate)::numeric, 2),
    'Across all significant cohorts'
FROM cohort_metrics;

-- =====================================================
-- INSIGHT 5: DELIVERY PERFORMANCE IMPACT
-- =====================================================

WITH delivery_satisfaction AS (
    SELECT 
        CASE 
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
            ELSE 'Late'
        END as delivery_status,
        AVG(r.review_score) as avg_score
    FROM olist_orders o
    LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND r.review_score IS NOT NULL
    GROUP BY 
        CASE 
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
            ELSE 'Late'
        END
)
SELECT 
    'DELIVERY IMPACT'                   as insight_category,
    'On-time Delivery Rate %'           as metric_name,
    ROUND(COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) * 100.0 / COUNT(*), 2) as metric_value,
    'Orders delivered by estimated date' as details
FROM olist_orders
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL

UNION ALL

SELECT 
    'DELIVERY IMPACT',
    'Satisfaction Score Difference',
    ROUND((MAX(CASE WHEN delivery_status = 'On Time' THEN avg_score END) - 
           MAX(CASE WHEN delivery_status = 'Late' THEN avg_score END))::numeric, 2),
    'On-time vs Late delivery score gap'
FROM delivery_satisfaction

UNION ALL

SELECT 
    'DELIVERY IMPACT',
    'Average Delivery Time (days)',
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1),
    'From purchase to delivery'
FROM olist_orders
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL;

-- =====================================================
-- SECTION 2: ACTIONABLE RECOMMENDATIONS
-- =====================================================

SELECT 
    'HIGH'                              as priority,
    'IMPROVE DELIVERY COMPLETION'       as recommendation,
    'Investigate why approved orders fail to ship/deliver' as action,
    'Recover $320K in stuck order revenue' as expected_impact

UNION ALL

SELECT 
    'HIGH',
    'FIX VIP CUSTOMER EXPERIENCE',
    'VIPs have lowest satisfaction (3.74/5) - audit their order journey',
    'Protect top 5% customers who drive 35% of revenue'

UNION ALL

SELECT 
    'HIGH',
    '7-DAY RE-ENGAGEMENT CAMPAIGN',
    'Email/SMS within 7 days of delivery with repeat purchase offer',
    '38% of repeaters buy within 1 week - capture this window'

UNION ALL

SELECT 
    'MEDIUM',
    'WIN-BACK LAPSED CUSTOMERS',
    'Target 22,432 at-risk customers with personalized offer',
    'Avg $326 spend - high value segment worth reactivating'

UNION ALL

SELECT 
    'MEDIUM',
    'REDUCE LATE DELIVERIES',
    'Audit carriers in BA state (97.37% vs 98.76% in RS)',
    'Late delivery drops satisfaction by 1.72 points'

UNION ALL

SELECT 
    'MEDIUM',
    'INCREASE BASKET SIZE',
    'Product recommendations for 90% single-item orders',
    'Even 10% increase in basket size = significant revenue lift'

UNION ALL

SELECT 
    'LOW',
    'INVESTIGATE RETENTION DECLINE',
    'Repeat rate fell from 5.38% (2017) to 0.56% (2018) - find root cause',
    'Fixing this could 10x retention rates';

-- =====================================================
-- SECTION 3: QUICK WINS
-- =====================================================

SELECT 
    'QUICK WIN #1'                          as opportunity,
    'High-value one-time customers (>$100) within 6 months' as description,
    COUNT(*)                                as customer_count,
    ROUND(SUM(total_revenue)::numeric, 2)   as potential_value
FROM customer_lifetime_value
WHERE total_orders = 1
    AND total_revenue >= 100
    AND EXTRACT(DAY FROM (CURRENT_DATE - first_purchase_date)) BETWEEN 30 AND 180

UNION ALL

SELECT 
    'QUICK WIN #2',
    'Fix stuck orders: approved but not delivered',
    COUNT(DISTINCT oi.order_id),
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2)
FROM olist_order_items oi
JOIN olist_orders o ON oi.order_id = o.order_id
WHERE o.order_approved_at IS NOT NULL
    AND o.order_delivered_customer_date IS NULL
    AND o.order_status NOT IN ('canceled', 'unavailable')

UNION ALL

SELECT 
    'QUICK WIN #3',
    'Customers in repurchase window (60-120 days since last order)',
    COUNT(DISTINCT customer_unique_id),
    ROUND(AVG(total_revenue)::numeric, 2)
FROM customer_lifetime_value
WHERE total_orders >= 2
    AND EXTRACT(DAY FROM (CURRENT_DATE - last_purchase_date)) BETWEEN 60 AND 120;

-- =====================================================
-- SECTION 4: EXECUTIVE SUMMARY
-- =====================================================

WITH summary AS (
    SELECT 
        COUNT(DISTINCT c.customer_unique_id) as total_customers,
        COUNT(DISTINCT o.order_id) as total_orders,
        ROUND(SUM(op.payment_value)::numeric, 0) as total_revenue,
        ROUND(COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) * 100.0 / 
              COUNT(DISTINCT o.order_id), 1) as delivery_rate,
        ROUND(AVG(r.review_score)::numeric, 2) as avg_satisfaction
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    LEFT JOIN olist_order_payments op ON o.order_id = op.order_id
    LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
clv_summary AS (
    SELECT 
        ROUND(COUNT(CASE WHEN total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*), 1) as repeat_rate,
        ROUND(AVG(total_revenue)::numeric, 0) as avg_ltv,
        ROUND(
            SUM(CASE WHEN total_revenue >= (
                SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) 
                FROM customer_lifetime_value
            ) THEN total_revenue END) * 100.0 / SUM(total_revenue), 1
        ) as top10_revenue_share
    FROM customer_lifetime_value
)
SELECT 'SCALE' as category, 'Total Customers' as metric, total_customers::text as value, 'Unique customers' as benchmark FROM summary
UNION ALL SELECT 'SCALE', 'Total Orders', total_orders::text, 'Excl. canceled' FROM summary
UNION ALL SELECT 'SCALE', 'Total Revenue', '$' || total_revenue::text, 'Gross merchandise value' FROM summary
UNION ALL SELECT 'CONVERSION', 'Delivery Rate', delivery_rate::text || '%', 'Target: >95% ✅' FROM summary
UNION ALL SELECT 'RETENTION', 'Repeat Purchase Rate', repeat_rate::text || '%', 'Target: >25% 🚨' FROM clv_summary
UNION ALL SELECT 'SATISFACTION', 'Avg Review Score', avg_satisfaction::text || ' / 5.0', 'Target: >4.0 ✅' FROM summary
UNION ALL SELECT 'VALUE', 'Average Customer LTV', '$' || avg_ltv::text, 'Revenue per customer' FROM clv_summary
UNION ALL SELECT 'VALUE', 'Top 10% Revenue Share', top10_revenue_share::text || '%', 'Revenue concentration 🚨' FROM clv_summary;
