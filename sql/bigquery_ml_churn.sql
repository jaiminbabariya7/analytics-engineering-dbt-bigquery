-- bigquery_ml_churn.sql
-- BigQuery ML: train logistic regression churn model, evaluate, predict.

-- Step 1: Train the model
CREATE OR REPLACE MODEL `PROJECT_ID.mart.churn_model`
OPTIONS (
    model_type        = "LOGISTIC_REG",
    input_label_cols  = ["is_churned"],
    max_iterations    = 50,
    l2_reg            = 0.1,
    data_split_method = "AUTO_SPLIT"
) AS
SELECT
    CAST(recency_days        AS FLOAT64) AS recency_days,
    CAST(purchase_frequency  AS FLOAT64) AS purchase_frequency,
    CAST(lifetime_value_usd  AS FLOAT64) AS lifetime_value_usd,
    CAST(avg_order_value_usd AS FLOAT64) AS avg_order_value_usd,
    CAST(total_orders        AS FLOAT64) AS total_orders,
    ltv_tier,
    CASE WHEN churn_risk = "high" THEN 1 ELSE 0 END AS is_churned
FROM `PROJECT_ID.mart.dim_customers`
WHERE recency_days IS NOT NULL;


-- Step 2: Evaluate
SELECT *
FROM ML.EVALUATE(
    MODEL `PROJECT_ID.mart.churn_model`,
    (SELECT * FROM `PROJECT_ID.mart.dim_customers` WHERE recency_days IS NOT NULL)
);


-- Step 3: Predict churn probability
SELECT
    customer_id,
    first_name,
    last_name,
    lifetime_value_usd,
    predicted_is_churned,
    ROUND(predicted_is_churned_probs[OFFSET(1)].prob, 4) AS churn_probability
FROM ML.PREDICT(
    MODEL `PROJECT_ID.mart.churn_model`,
    (SELECT * FROM `PROJECT_ID.mart.dim_customers`)
)
ORDER BY churn_probability DESC;