{{
  config(
    materialized='view',
    schema='staging'
  )
}}

with source as (
    select * from {{ source('ecommerce_raw', 'olist_orders') }}
),

renamed as (
    select
        -- IDs
        order_id,
        customer_id,
        
        -- Status
        order_status as status,
        
        -- Timestamps
        order_purchase_timestamp as purchase_timestamp,
        order_approved_at as approved_at,
        order_delivered_carrier_date as shipped_at,
        order_delivered_customer_date as delivered_at,
        order_estimated_delivery_date as estimated_delivery_date
        
    from source
)

select * from renamed
