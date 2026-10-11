-- Upsert logic for sales data
MERGE INTO `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales` AS target
USING `data-pipeline-bigquery-424104.data_pipeline_bigquery.ext_sales` AS source
ON target.date = source.date AND target.product_id = source.product_id AND target.customer_id = source.customer_id
WHEN MATCHED THEN
  UPDATE SET
    target.quantity = source.quantity,
    target.total_price = source.total_price
WHEN NOT MATCHED THEN
  INSERT (date, product_id, customer_id, quantity, total_price)
  VALUES (source.date, source.product_id, source.customer_id, source.quantity, source.total_price);

-- Upsert logic for product information
MERGE INTO `data-pipeline-bigquery-424104.data_pipeline_bigquery.products` AS target
USING `data-pipeline-bigquery-424104.data_pipeline_bigquery.ext_products` AS source
ON target.product_id = source.product_id
WHEN MATCHED THEN
  UPDATE SET
    target.product_name = source.product_name,
    target.category = source.category
WHEN NOT MATCHED THEN
  INSERT (product_id, product_name, category)
  VALUES (source.product_id, source.product_name, source.category);

-- Upsert logic for customer details
MERGE INTO `data-pipeline-bigquery-424104.data_pipeline_bigquery.customers` AS target
USING `data-pipeline-bigquery-424104.data_pipeline_bigquery.ext_customers` AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN
  UPDATE SET
    target.customer_name = source.customer_name,
    target.location = source.location
WHEN NOT MATCHED THEN
  INSERT (customer_id, customer_name, location)
  VALUES (source.customer_id, source.customer_name, source.location);