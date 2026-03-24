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

funnel_stages as (
    select
        order_id,
        payment_value,
        case
            when delivered_at is not null then '4. Order Delivered'
            when shipped_at is not null then '3. Order Shipped'
            when approved_at is not null then '2. Order Approved'
            else '1. Order Placed'
        end as funnel_stage
    from orders
),

stage_metrics as (
    select
        funnel_stage,
        count(*) as orders,
        sum(payment_value) as total_revenue
    from funnel_stages
    group by funnel_stage
),

total_orders as (
    select count(*) as total from orders
),

final as (
    select
        s.funnel_stage,
        s.orders,
        s.total_revenue,
        round(s.orders * 100.0 / t.total, 2) as conversion_rate,
        round((t.total - s.orders) * 100.0 / t.total, 2) as drop_off_rate
    from stage_metrics s
    cross join total_orders t
)

select * from final
order by funnel_stage
