{{ config(materialized='table', tags=['daily', 'reporting']) }}

{# Monthly revenue aggregation for dashboards #}

WITH orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
    WHERE order_status = 'completed'
)

SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(order_id)                       AS total_orders,
    COUNT(DISTINCT customer_id)           AS unique_customers,
    SUM(order_total)                      AS gross_revenue,
    SUM(amount_paid)                      AS collected_revenue,
    AVG(order_total)                      AS avg_order_value,
    SUM(total_quantity)                   AS items_sold
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month
