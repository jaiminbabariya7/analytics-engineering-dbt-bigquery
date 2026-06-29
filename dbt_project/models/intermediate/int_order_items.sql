-- int_order_items.sql
-- Joins sales + products + customers into a single enriched order-item grain.

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales') }}
),
products AS (
    SELECT * FROM {{ ref('stg_products') }}
),
customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
)

SELECT
    s.sale_id,
    s.sale_date,
    s.channel,
    s.quantity,
    s.unit_price,
    s.discount_pct,
    s.net_revenue,

    -- Product fields
    p.product_id,
    p.product_name,
    p.category,
    p.unit_cost,
    p.margin_pct,
    p.margin_tier,

    -- Customer fields
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.city,
    c.registration_date,

    -- Gross profit on this line item
    ROUND(s.net_revenue - (p.unit_cost * s.quantity), 2)    AS gross_profit,

    -- Days since registration (for RFM recency context)
    DATE_DIFF(CURRENT_DATE(), c.registration_date, DAY)     AS days_since_registration
FROM sales s
LEFT JOIN products  p USING (product_id)
LEFT JOIN customers c USING (customer_id)
