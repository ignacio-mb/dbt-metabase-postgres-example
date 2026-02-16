{{ config(materialized='table') }}

{# Customer dimension with lifetime order metrics #}

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
)

SELECT
    c.customer_id,
    c.full_name,
    c.email,
    c.created_at                           AS customer_since,
    COUNT(o.order_id)                      AS lifetime_orders,
    COALESCE(SUM(o.order_total), 0)        AS lifetime_revenue,
    COALESCE(AVG(o.order_total), 0)        AS avg_order_value,
    MIN(o.order_date)                      AS first_order_date,
    MAX(o.order_date)                      AS last_order_date,
    CASE
        WHEN COUNT(o.order_id) = 0 THEN 'inactive'
        WHEN COUNT(o.order_id) = 1 THEN 'new'
        WHEN COUNT(o.order_id) <= 3 THEN 'returning'
        ELSE 'loyal'
    END                                    AS customer_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email, c.created_at
