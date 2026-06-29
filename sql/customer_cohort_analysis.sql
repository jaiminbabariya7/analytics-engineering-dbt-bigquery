-- customer_cohort_analysis.sql
-- Monthly cohort retention: what % of customers return in months 1-12.

WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC(first_purchase_date, MONTH)  AS cohort_month
    FROM `PROJECT_ID.mart.dim_customers`
    WHERE first_purchase_date IS NOT NULL
),
purchases AS (
    SELECT
        customer_id,
        DATE_TRUNC(sale_date, MONTH)             AS purchase_month
    FROM `PROJECT_ID.mart.fct_sales`
    GROUP BY customer_id, purchase_month
),
cohort_data AS (
    SELECT
        c.cohort_month,
        DATE_DIFF(p.purchase_month, c.cohort_month, MONTH) AS month_number,
        COUNT(DISTINCT c.customer_id)                       AS customers
    FROM cohorts c
    LEFT JOIN purchases p USING (customer_id)
    GROUP BY cohort_month, month_number
),
cohort_sizes AS (
    SELECT cohort_month, customers AS cohort_size
    FROM cohort_data WHERE month_number = 0
)
SELECT
    cd.cohort_month,
    cs.cohort_size,
    cd.month_number,
    cd.customers                                                AS retained_customers,
    ROUND(100 * SAFE_DIVIDE(cd.customers, cs.cohort_size), 1)  AS retention_pct
FROM cohort_data cd
JOIN cohort_sizes cs USING (cohort_month)
WHERE cd.month_number BETWEEN 0 AND 12
ORDER BY cohort_month, month_number;