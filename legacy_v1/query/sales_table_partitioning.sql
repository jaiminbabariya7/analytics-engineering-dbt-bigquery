-- Create a partitioned table for sales data
CREATE OR REPLACE TABLE `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales_partitioned`
PARTITION BY date AS
SELECT * FROM `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales`;
