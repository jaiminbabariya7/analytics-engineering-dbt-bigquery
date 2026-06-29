-- int_customer_metrics.sql
-- Computes RFM (Recency, Frequency, Monetary) metrics per customer,
-- plus LTV tier and a simple churn-risk heuristic.

WITH order_items AS (
    SELECT * FROM {{ ref('int_order_items') }}
),

rfm AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        country,
        city,
        registration_date,

        -- Recency: days since last purchase
        DATE_DIFF(CURRENT_DATE(), MAX(sale_date), DAY)      AS recency_days,

        -- Frequency: number of distinct purchase dates
        COUNT(DISTINCT sale_date)                            AS purchase_frequency,

        -- Monetary: total lifetime spend
        ROUND(SUM(net_revenue), 2)                          AS lifetime_value_usd,
        ROUND(AVG(net_revenue), 2)                          AS avg_order_value_usd,
        COUNT(DISTINCT sale_id)                             AS total_orders,
        MIN(sale_date)                                      AS first_purchase_date,
        MAX(sale_date)                                      AS last_purchase_date

    FROM order_items
    GROUP BY 1, 2, 3, 4, 5, 6, 7
)

SELECT
    *,
    -- LTV tier
    CASE
        WHEN lifetime_value_usd >= 5000 THEN 'platinum'
        WHEN lifetime_value_usd >= 2000 THEN 'gold'
        WHEN lifetime_value_usd >= 500  THEN 'silver'
        ELSE 'bronze'
    END                                                     AS ltv_tier,

    -- Churn risk: high if no purchase in 90 days and low frequency
    CASE
        WHEN recency_days > 90 AND purchase_frequency <= 2 THEN 'high'
        WHEN recency_days > 60 AND purchase_frequency <= 4 THEN 'medium'
        ELSE 'low'
    END                                                     AS churn_risk
FROM rfm
