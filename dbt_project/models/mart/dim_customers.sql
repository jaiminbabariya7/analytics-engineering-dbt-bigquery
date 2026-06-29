-- dim_customers.sql
-- Customer dimension: one row per customer with RFM + LTV + churn risk.

{{
  config(
    materialized = 'table'
  )
}}

SELECT
    {{ generate_surrogate_key(['customer_id']) }}            AS customer_key,
    customer_id,
    first_name,
    last_name,
    email,
    country,
    city,
    registration_date,
    recency_days,
    purchase_frequency,
    lifetime_value_usd,
    avg_order_value_usd,
    total_orders,
    first_purchase_date,
    last_purchase_date,
    ltv_tier,
    churn_risk
FROM {{ ref('int_customer_metrics') }}
