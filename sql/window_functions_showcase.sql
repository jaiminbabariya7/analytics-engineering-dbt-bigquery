-- window_functions_showcase.sql
-- Demonstrates advanced BigQuery window functions on the sales dataset.

-- 1. Running total revenue per customer (ordered by date)
SELECT
    customer_id,
    sale_date,
    net_revenue,
    SUM(net_revenue) OVER (
        PARTITION BY customer_id
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                       AS running_revenue,

    -- 2. 30-day moving average per category
    AVG(net_revenue) OVER (
        PARTITION BY category
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL 30 DAY PRECEDING AND CURRENT ROW
    )                                                       AS ma30_revenue,

    -- 3. Rank products by revenue within category
    RANK() OVER (
        PARTITION BY category
        ORDER BY net_revenue DESC
    )                                                       AS revenue_rank_in_category,

    -- 4. % of category total
    ROUND(100 * net_revenue / SUM(net_revenue) OVER (PARTITION BY category), 2)
                                                            AS pct_of_category,

    -- 5. Previous order value (LAG)
    LAG(net_revenue, 1) OVER (
        PARTITION BY customer_id ORDER BY sale_date
    )                                                       AS prev_order_value,

    -- 6. Order number per customer
    ROW_NUMBER() OVER (
        PARTITION BY customer_id ORDER BY sale_date
    )                                                       AS customer_order_number

FROM `PROJECT_ID.mart.fct_sales`
ORDER BY customer_id, sale_date;


-- 7. Month-over-month revenue growth
WITH monthly AS (
    SELECT
        FORMAT_DATE("%Y-%m", sale_date)   AS month,
        SUM(net_revenue)                   AS monthly_revenue
    FROM `PROJECT_ID.mart.fct_sales`
    GROUP BY month
)
SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month)              AS prev_month_revenue,
    ROUND(
        100 * SAFE_DIVIDE(
            monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month),
            LAG(monthly_revenue) OVER (ORDER BY month)
        ), 2
    )                                                       AS mom_growth_pct
FROM monthly
ORDER BY month;