-- bigquery_ml_churn.sql
-- BigQuery ML: churn model with a time-based label (no label leakage).
--
-- Churn definition: a customer who bought on or before the cutoff date and made
-- NO purchase in the following `horizon_days`. Features are computed only from
-- sales up to the cutoff, so the model never sees the period it predicts.
-- (The rule-based `churn_risk` column in dim_customers is a separate heuristic
-- segment and is NOT used as the label.)
--
-- Run as one BigQuery script (replace PROJECT_ID).

DECLARE horizon_days INT64 DEFAULT 90;
DECLARE scoring_date DATE DEFAULT (SELECT MAX(sale_date) FROM `PROJECT_ID.mart.fct_sales`);
DECLARE cutoff       DATE DEFAULT DATE_SUB(scoring_date, INTERVAL horizon_days DAY);


-- Step 0: Customer features as of a given date (only sales on or before it)
CREATE OR REPLACE TABLE FUNCTION `PROJECT_ID.mart.churn_features`(as_of DATE) AS
SELECT
    customer_id,
    DATE_DIFF(as_of, MAX(sale_date), DAY)                          AS recency_days,
    COUNT(DISTINCT sale_id)                                        AS total_orders,
    COUNT(DISTINCT IF(sale_date > DATE_SUB(as_of, INTERVAL 90 DAY),
                      sale_id, NULL))                              AS orders_last_90d,
    SUM(net_revenue)                                               AS revenue_usd,
    SAFE_DIVIDE(SUM(net_revenue), COUNT(DISTINCT sale_id))         AS avg_order_value_usd,
    DATE_DIFF(as_of, MIN(sale_date), DAY)                          AS tenure_days,
    COUNT(DISTINCT category)                                       AS categories_bought,
    AVG(discount_pct)                                              AS avg_discount_pct
FROM `PROJECT_ID.mart.fct_sales`
WHERE sale_date <= as_of
GROUP BY customer_id;


-- Step 1: Training set: features at the cutoff + what happened afterwards
CREATE OR REPLACE TABLE `PROJECT_ID.mart.churn_training` AS
SELECT
    f.*,
    IF(future.customer_id IS NULL, 1, 0) AS is_churned
FROM `PROJECT_ID.mart.churn_features`(cutoff) AS f
LEFT JOIN (
    SELECT DISTINCT customer_id
    FROM `PROJECT_ID.mart.fct_sales`
    WHERE sale_date >  cutoff
      AND sale_date <= DATE_ADD(cutoff, INTERVAL horizon_days DAY)
) AS future
USING (customer_id);


-- Step 2: Train (20% held out for evaluation; class weights for imbalance)
CREATE OR REPLACE MODEL `PROJECT_ID.mart.churn_model`
OPTIONS (
    model_type               = "LOGISTIC_REG",
    input_label_cols         = ["is_churned"],
    auto_class_weights       = TRUE,
    l2_reg                   = 0.1,
    max_iterations           = 50,
    data_split_method        = "RANDOM",
    data_split_eval_fraction = 0.2
) AS
SELECT * EXCEPT (customer_id)
FROM `PROJECT_ID.mart.churn_training`;


-- Step 3: Evaluate on the held-out split (precision, recall, ROC AUC, log loss)
SELECT *
FROM ML.EVALUATE(MODEL `PROJECT_ID.mart.churn_model`);


-- Step 4: Score every customer as of the latest date: probability of no
-- purchase in the next `horizon_days`
CREATE OR REPLACE TABLE `PROJECT_ID.mart.churn_scores` AS
SELECT
    p.customer_id,
    c.first_name,
    c.last_name,
    c.lifetime_value_usd,
    p.predicted_is_churned,
    ROUND((SELECT prob FROM UNNEST(p.predicted_is_churned_probs) WHERE label = 1), 4)
                                                              AS churn_probability,
    scoring_date                                              AS scored_as_of
FROM ML.PREDICT(
    MODEL `PROJECT_ID.mart.churn_model`,
    (SELECT * FROM `PROJECT_ID.mart.churn_features`(scoring_date))
) AS p
LEFT JOIN `PROJECT_ID.mart.dim_customers` AS c
USING (customer_id)
ORDER BY churn_probability DESC;
