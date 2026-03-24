{{
  config(
    materialized='view',
    schema='staging'
  )
}}

with source as (
    select * from {{ source('ecommerce_raw', 'olist_customers') }}
),

renamed as (
    select
        -- IDs
        customer_id,
        customer_unique_id,
        
        -- Location
        customer_zip_code_prefix as zip_code_prefix,
        customer_city as city,
        customer_state as state
        
    from source
)

select * from renamed
