{{
  config(
    materialized='table',
    schema='marts'
  )
}}

with orders as (
    select * from {{ ref('int_orders_enriched') }}
    where status not in ('canceled', 'unavailable')
),

first_orders as (
    select
        customer_unique_id,
        min(purchase_timestamp) as first_order_date
    from orders
    group by customer_unique_id
),

cohort_base as (
    select
        f.customer_unique_id,
        date_trunc('month', f.first_order_date) as cohort_month,
        f.first_order_date as first_purchase_date,
        count(o.order_id) as total_orders,
        sum(o.payment_value) as lifetime_value,
        max(o.purchase_timestamp) as last_purchase_date,
        avg(o.avg_review_score) as avg_satisfaction_score
    from first_orders f
    left join orders o
        on f.customer_unique_id = o.customer_unique_id
    group by f.customer_unique_id, f.first_order_date
),

final as (
    select
        customer_unique_id,
        cohort_month,
        first_purchase_date,
        last_purchase_date,
        total_orders,
        lifetime_value,
        avg_satisfaction_score,
        
        -- Derived metrics
        extract(day from (current_date - last_purchase_date)) as days_since_last_order,
        
        -- Cohort age in months
        extract(year from age(current_date, cohort_month)) * 12 +
        extract(month from age(current_date, cohort_month)) as cohort_age_months
        
    from cohort_base
)

select * from final
