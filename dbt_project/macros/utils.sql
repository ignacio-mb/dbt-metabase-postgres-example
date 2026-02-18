{% macro cents_to_dollars(column_name, precision=2) %}
    round({{ column_name }}::numeric / 100, {{ precision }})
{% endmacro %}


{% macro safe_divide(numerator, denominator, default=0) %}
    case
        when {{ denominator }} is null or {{ denominator }} = 0 then {{ default }}
        else {{ numerator }}::numeric / {{ denominator }}::numeric
    end
{% endmacro %}


{% macro days_between(start_date, end_date) %}
    {{ end_date }}::date - {{ start_date }}::date
{% endmacro %}
