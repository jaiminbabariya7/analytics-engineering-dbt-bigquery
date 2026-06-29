-- fct_sales.sql
-- Central fact table: one row per sale line item.
-- Partitioned by sale_date, clustered by category / country / channel.

{{
  config(
    materialized  = 'table',
    partition_by  = { 'field': 'sale_date', 'data_type': 'date', 'granularity': 'day' },
    cluster_by    = ['category', 'country', 'channel']
  )
}}

WITH order_items AS (
    SELECT * FROM {{ ref('int_order_items') }}
)

SELECT
    {{ generate_surrogate_key(['sale_id', 'product_id', 'customer_id']) }} AS sale_key,
    sale_id,
    sale_date,
    channel,
    product_id,
    product_name,
    category,
    margin_tier,
    customer_id,
    country,
    city,
    quantity,
    unit_price,
    unit_cost,
    discount_pct,
    net_revenue,
    gross_profit
FROM order_items
