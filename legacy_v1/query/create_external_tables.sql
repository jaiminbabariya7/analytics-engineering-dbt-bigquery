-- External table for sales data
CREATE OR REPLACE EXTERNAL TABLE `data-pipeline-bigquery-424104.data_pipeline_bigquery.ext_sales`
OPTIONS (
  format = 'CSV',
  uris = ['gs://pip-bucket1/data/sales.csv']
);

-- External table for product information
CREATE OR REPLACE EXTERNAL TABLE `data-pipeline-bigquery-424104.data_pipeline_bigquery.ext_products`
OPTIONS (
  format = 'CSV',
  uris = ['gs://pip-bucket1/data/products.csv']
);

-- External table for customer details
CREATE OR REPLACE EXTERNAL TABLE `data-pipeline-bigquery-424104.data_pipeline_bigquery.ext_customers`
OPTIONS (
  format = 'CSV',
  uris = ['gs://pip-bucket1/data/customers.csv']
);