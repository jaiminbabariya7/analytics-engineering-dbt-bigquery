{% snapshot scd_customers %}
{{
  config(
    target_schema = 'snapshots',
    unique_key    = 'customer_id',
    strategy      = 'check',
    check_cols    = ['email', 'country', 'city', 'is_active'],
  )
}}

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    country,
    city,
    is_active,
    registration_date
FROM {{ ref('stg_customers') }}

{% endsnapshot %}
