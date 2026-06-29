-- Fails if any sale references a customer not in dim_customers.
SELECT s.sale_id, s.customer_id
FROM {{ ref('fct_sales') }}      s
LEFT JOIN {{ ref('dim_customers') }} c USING (customer_id)
WHERE c.customer_id IS NULL
