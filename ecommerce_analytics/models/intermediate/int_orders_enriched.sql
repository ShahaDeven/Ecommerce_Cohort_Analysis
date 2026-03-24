{{
  config(
    materialized='view',
    schema='intermediate'
  )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

payments as (
    select
        order_id,
        sum(value) as total_payment
    from {{ ref('stg_payments') }}
    group by order_id
),

items as (
    select
        order_id,
        count(*) as item_count,
        sum(total_item_value) as total_item_value
    from {{ ref('stg_order_items') }}
    group by order_id
),

reviews as (
    select
        order_id,
        avg(score) as avg_review_score
    from {{ ref('stg_reviews') }}
    group by order_id
),

final as (
    select
        -- IDs
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        
        -- Status
        o.status,
        
        -- Timestamps
        o.purchase_timestamp,
        o.approved_at,
        o.shipped_at,
        o.delivered_at,
        o.estimated_delivery_date,
        
        -- Delivery metrics
        case
            when o.delivered_at is not null 
                and o.estimated_delivery_date is not null
            then case
                when o.delivered_at <= o.estimated_delivery_date then 'On Time'
                else 'Late'
            end
        end as delivery_status,
        
        case
            when o.delivered_at is not null and o.purchase_timestamp is not null
            then extract(epoch from (o.delivered_at - o.purchase_timestamp)) / 86400.0
        end as delivery_days,
        
        -- Financial
        coalesce(p.total_payment, 0) as payment_value,
        coalesce(i.total_item_value, 0) as item_value,
        coalesce(i.item_count, 0) as item_count,
        
        -- Satisfaction
        r.avg_review_score,
        
        -- Location
        c.city,
        c.state
        
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join payments p on o.order_id = p.order_id
    left join items i on o.order_id = i.order_id
    left join reviews r on o.order_id = r.order_id
)

select * from final
