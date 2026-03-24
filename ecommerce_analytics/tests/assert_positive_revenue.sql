-- Test that no customer has negative lifetime value
-- This test will fail if any customer has total_revenue < 0

select
    customer_unique_id,
    total_revenue
from {{ ref('customer_lifetime_value') }}
where total_revenue < 0
