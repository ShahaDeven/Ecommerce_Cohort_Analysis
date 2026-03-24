{{
  config(
    materialized='view',
    schema='staging'
  )
}}

with source as (
    select * from {{ source('ecommerce_raw', 'olist_order_reviews') }}
),

renamed as (
    select
        -- IDs
        review_id,
        order_id,
        
        -- Review content
        review_score as score,
        review_comment_title as comment_title,
        review_comment_message as comment_message,
        review_creation_date as created_at,
        review_answer_timestamp as answered_at
        
    from source
)

select * from renamed
