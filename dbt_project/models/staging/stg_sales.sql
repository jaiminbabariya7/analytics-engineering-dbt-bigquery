-- stg_sales.sql
-- Clean raw sales records and compute net revenue.

WITH source AS (
    SELECT * FROM {{ source('raw', 'sales') }}
)

SELECT
    CAST(sale_id    AS STRING)                              AS sale_id,
    CAST(customer_id AS STRING)                             AS customer_id,
    CAST(product_id  AS STRING)                             AS product_id,
    CAST(sale_date   AS DATE)                               AS sale_date,
    CAST(quantity    AS INT64)                              AS quantity,
    CAST(unit_price  AS NUMERIC)                            AS unit_price,
    COALESCE(CAST(discount_pct AS NUMERIC), 0)              AS discount_pct,
    TRIM(channel)                                           AS channel,
    ROUND(
        CAST(unit_price AS NUMERIC)
        * CAST(quantity AS INT64)
        * (1 - COALESCE(CAST(discount_pct AS NUMERIC), 0)),
        2
    )                                                       AS net_revenue
FROM source
WHERE sale_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
