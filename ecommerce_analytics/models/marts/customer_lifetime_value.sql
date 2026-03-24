{{
  config(
    materialized='table',
    schema='marts'
  )
}}

with cohorts as (
    select * from {{ ref('customer_cohorts') }}
),

rfm_scores as (
    select
        customer_unique_id,
        cohort_month,
        first_purchase_date,
        last_purchase_date,
        total_orders,
        lifetime_value as total_revenue,
        avg_satisfaction_score,
        days_since_last_order,
        
        -- RFM Scoring (1-5, where 5 is best)
        ntile(5) over (order by days_since_last_order desc) as recency_score,
        ntile(5) over (order by total_orders) as frequency_score,
        ntile(5) over (order by lifetime_value) as monetary_score
        
    from cohorts
),

rfm_segments as (
    select
        *,
        recency_score + frequency_score + monetary_score as rfm_total_score,
        
        -- RFM Segmentation
        case
            when recency_score >= 4 and frequency_score >= 4 and monetary_score >= 4 then 'Champions'
            when recency_score >= 3 and frequency_score >= 3 and monetary_score >= 3 then 'Loyal Customers'
            when recency_score >= 4 and frequency_score <= 2 and monetary_score <= 2 then 'New Customers'
            when recency_score >= 3 and frequency_score <= 2 and monetary_score <= 2 then 'Promising'
            when recency_score <= 2 and frequency_score >= 3 and monetary_score >= 3 then 'At Risk'
            when recency_score <= 2 and frequency_score >= 2 and monetary_score >= 2 then 'Need Attention'
            when recency_score <= 2 and frequency_score <= 2 and monetary_score >= 3 then 'Cant Lose Them'
            when recency_score <= 1 and frequency_score <= 2 and monetary_score <= 2 then 'Lost'
            else 'Others'
        end as rfm_segment
        
    from rfm_scores
),

-- Calculate percentiles in separate CTE
percentiles as (
    select
        percentile_cont(0.95) within group (order by total_revenue) as p95,
        percentile_cont(0.90) within group (order by total_revenue) as p90,
        percentile_cont(0.75) within group (order by total_revenue) as p75,
        percentile_cont(0.50) within group (order by total_revenue) as p50
    from rfm_segments
),

clv_tiers as (
    select
        r.*,
        -- CLV Percentile Tiers using CROSS JOIN with percentiles
        case
            when r.total_revenue >= p.p95 then '1. VIP (Top 5%)'
            when r.total_revenue >= p.p90 then '2. High Value (Top 10%)'
            when r.total_revenue >= p.p75 then '3. Medium-High (Top 25%)'
            when r.total_revenue >= p.p50 then '4. Medium (Top 50%)'
            else '5. Low Value (Bottom 50%)'
        end as clv_segment
        
    from rfm_segments r
    cross join percentiles p
),

final as (
    select
        customer_unique_id,
        cohort_month,
        first_purchase_date,
        last_purchase_date,
        total_orders,
        total_revenue,
        avg_satisfaction_score,
        days_since_last_order,
        
        -- RFM
        recency_score,
        frequency_score,
        monetary_score,
        rfm_total_score,
        rfm_segment,
        
        -- CLV Tier
        clv_segment,
        
        -- Flags
        case when total_orders = 1 then true else false end as is_one_time_customer,
        case when total_orders >= 2 then true else false end as is_repeat_customer
        
    from clv_tiers
)

select * from final