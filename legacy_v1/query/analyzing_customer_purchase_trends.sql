SELECT
  c.location,
  s.date,
  SUM(s.total_price) AS total_sales
FROM
  `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales` AS s
JOIN
  `data-pipeline-bigquery-424104.data_pipeline_bigquery.customers` AS c
ON
  s.customer_id = c.customer_id
GROUP BY
  c.location, s.date
ORDER BY
  s.date;