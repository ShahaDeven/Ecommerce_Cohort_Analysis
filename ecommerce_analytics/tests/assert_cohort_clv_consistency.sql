-- Test that all customers in cohorts appear in CLV table
-- This test will fail if there are customers in cohorts but not in CLV

select
    c.customer_unique_id
from {{ ref('customer_cohorts') }} c
left join {{ ref('customer_lifetime_value') }} clv
    on c.customer_unique_id = clv.customer_unique_id
where clv.customer_unique_id is null
