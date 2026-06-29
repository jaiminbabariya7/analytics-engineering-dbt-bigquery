{% macro generate_surrogate_key(field_list) %}
    TO_HEX(MD5(CONCAT(
        {% for field in field_list %}
            COALESCE(CAST({{ field }} AS STRING), '__null__')
            {% if not loop.last %}, '|', {% endif %}
        {% endfor %}
    )))
{% endmacro %}
