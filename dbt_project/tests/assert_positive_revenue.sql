-- Fails if any sale has zero or negative net revenue.
SELECT sale_id, net_revenue
FROM {{ ref('fct_sales') }}
WHERE net_revenue <= 0
