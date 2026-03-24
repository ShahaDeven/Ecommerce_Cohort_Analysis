{{
  config(
    materialized='view',
    schema='staging'
  )
}}

with source as (
    select * from {{ source('ecommerce_raw', 'olist_order_payments') }}
),

renamed as (
    select
        -- IDs
        order_id,
        payment_sequential,
        
        -- Payment info
        payment_type,
        payment_installments as installments,
        payment_value as value
        
    from source
)

select * from renamed
