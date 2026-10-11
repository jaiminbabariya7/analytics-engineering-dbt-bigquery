SELECT
  p.category,
  s.date,
  SUM(s.total_price) AS total_sales
FROM
  `data-pipeline-bigquery-424104.data_pipeline_bigquery.sales` AS s
JOIN
  `data-pipeline-bigquery-424104.data_pipeline_bigquery.products` AS p
ON
  s.product_id = p.product_id
GROUP BY
  p.category, s.date
ORDER BY
  s.date;