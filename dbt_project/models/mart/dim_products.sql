-- dim_products.sql
-- Product dimension enriched with sales performance metrics.

{{
  config(
    materialized = 'table'
  )
}}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),
sales_agg AS (
    SELECT
        product_id,
        SUM(quantity)       AS units_sold,
        SUM(net_revenue)    AS total_revenue,
        SUM(gross_profit)   AS total_gross_profit,
        COUNT(DISTINCT sale_id)  AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_buyers
    FROM {{ ref('int_order_items') }}
    GROUP BY product_id
)

SELECT
    {{ generate_surrogate_key(['p.product_id']) }}           AS product_key,
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    p.unit_cost,
    p.stock_quantity,
    p.margin_pct,
    p.margin_tier,
    COALESCE(s.units_sold, 0)                               AS units_sold,
    COALESCE(ROUND(s.total_revenue, 2), 0)                  AS total_revenue,
    COALESCE(ROUND(s.total_gross_profit, 2), 0)             AS total_gross_profit,
    COALESCE(s.total_transactions, 0)                       AS total_transactions,
    COALESCE(s.unique_buyers, 0)                            AS unique_buyers
FROM products p
LEFT JOIN sales_agg s USING (product_id)
