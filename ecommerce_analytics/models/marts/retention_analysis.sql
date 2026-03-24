{{
  config(
    materialized='table',
    schema='marts'
  )
}}

with orders as (
    select * from {{ ref('int_orders_enriched') }}
    where status = 'delivered'
),

cohort_data as (
    select
        c.customer_unique_id,
        c.cohort_month,
        date_trunc('month', o.purchase_timestamp) as order_month,
        extract(year from age(
            date_trunc('month', o.purchase_timestamp),
            c.cohort_month
        )) * 12 + extract(month from age(
            date_trunc('month', o.purchase_timestamp),
            c.cohort_month
        )) as months_since_cohort
    from {{ ref('customer_cohorts') }} c
    join orders o
        on c.customer_unique_id = o.customer_unique_id
),

cohort_sizes as (
    select
        cohort_month,
        count(distinct customer_unique_id) as cohort_size
    from cohort_data
    where months_since_cohort = 0
    group by cohort_month
),

retention_by_month as (
    select
        cd.cohort_month,
        cd.months_since_cohort,
        count(distinct cd.customer_unique_id) as retained_customers
    from cohort_data cd
    group by cd.cohort_month, cd.months_since_cohort
),

final as (
    select
        r.cohort_month,
        r.months_since_cohort,
        cs.cohort_size,
        r.retained_customers,
        round(r.retained_customers * 100.0 / cs.cohort_size, 2) as retention_rate
    from retention_by_month r
    join cohort_sizes cs
        on r.cohort_month = cs.cohort_month
    where r.cohort_month >= '2017-01-01'
        and r.cohort_month <= '2018-06-01'
        and r.months_since_cohort between 0 and 6
)

select * from final
order by cohort_month, months_since_cohort
