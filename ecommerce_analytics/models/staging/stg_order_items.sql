{{
  config(
    materialized='view',
    schema='staging'
  )
}}

with source as (
    select * from {{ source('ecommerce_raw', 'olist_order_items') }}
),

renamed as (
    select
        -- IDs
        order_id,
        order_item_id,
        product_id,
        seller_id,
        
        -- Pricing
        price,
        freight_value,
        price + freight_value as total_item_value
        
    from source
)

select * from renamed
