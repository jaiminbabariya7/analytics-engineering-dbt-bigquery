-- stg_products.sql
-- Clean product catalogue; derive margin_pct and margin_tier.

WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
)

SELECT
    CAST(product_id AS STRING)                              AS product_id,
    TRIM(product_name)                                      AS product_name,
    INITCAP(TRIM(category))                                 AS category,
    CAST(unit_price AS NUMERIC)                             AS unit_price,
    CAST(unit_cost  AS NUMERIC)                             AS unit_cost,
    CAST(stock_quantity AS INT64)                           AS stock_quantity,
    ROUND(
        SAFE_DIVIDE(
            CAST(unit_price AS NUMERIC) - CAST(unit_cost AS NUMERIC),
            NULLIF(CAST(unit_price AS NUMERIC), 0)
        ) * 100, 2
    )                                                       AS margin_pct,
    CASE
        WHEN SAFE_DIVIDE(
            CAST(unit_price AS NUMERIC) - CAST(unit_cost AS NUMERIC),
            NULLIF(CAST(unit_price AS NUMERIC), 0)
        ) >= 0.40 THEN 'premium'
        WHEN SAFE_DIVIDE(
            CAST(unit_price AS NUMERIC) - CAST(unit_cost AS NUMERIC),
            NULLIF(CAST(unit_price AS NUMERIC), 0)
        ) >= 0.20 THEN 'standard'
        ELSE 'value'
    END                                                     AS margin_tier
FROM source
WHERE product_id IS NOT NULL
