-- Schema for sales data
CREATE TABLE IF NOT EXISTS `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales` (
    date DATE,
    product_id INT64,
    customer_id INT64,
    quantity INT64,
    total_price FLOAT64
);

-- Schema for product information
CREATE TABLE IF NOT EXISTS `data-pipeline-bigquery-424104.data_pipeline_bigquery.products` (
    product_id INT64,
    product_name STRING,
    category STRING
);

-- Schema for customer details
CREATE TABLE IF NOT EXISTS `data-pipeline-bigquery-424104.data_pipeline_bigquery.customers` (
    customer_id INT64,
    customer_name STRING,
    location STRING
);