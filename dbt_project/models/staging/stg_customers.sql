-- stg_customers.sql
-- Normalise raw customer records: trim names, lowercase email, cast types.

WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
)

SELECT
    CAST(customer_id AS STRING)                             AS customer_id,
    INITCAP(TRIM(first_name))                               AS first_name,
    INITCAP(TRIM(last_name))                                AS last_name,
    LOWER(TRIM(email))                                      AS email,
    INITCAP(TRIM(country))                                  AS country,
    INITCAP(TRIM(city))                                     AS city,
    CAST(registration_date AS DATE)                         AS registration_date,
    COALESCE(CAST(is_active AS BOOL), FALSE)                AS is_active
FROM source
WHERE customer_id IS NOT NULL
