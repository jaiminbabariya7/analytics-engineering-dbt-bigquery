{#
  Use the configured schema name as-is (staging, mart, snapshots) instead of
  dbt's default "<target_dataset>_<schema>", so models land in the datasets
  Terraform creates and the SQL in sql/ queries (e.g. `mart.fct_sales`).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
