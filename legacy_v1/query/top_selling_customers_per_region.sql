SELECT
  c.customer_id,
  c.customer_name,
  c.location,
  SUM(s.total_price) AS total_spent
FROM
  `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales` AS s
JOIN
  `data-pipeline-bigquery-424104.data_pipeline_bigquery.customers` AS c
ON
  s.customer_id = c.customer_id
WHERE
  c.location = 'Montreal'
GROUP BY
  c.customer_id, c.customer_name, c.location
ORDER BY
  total_spent DESC
LIMIT 10;