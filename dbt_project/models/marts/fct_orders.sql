{{ config(materialized='table') }}

{# Fact table: one row per order with aggregated totals #}

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_items AS (
    SELECT
        order_id,
        COUNT(*)           AS item_count,
        SUM(quantity)      AS total_quantity,
        SUM(line_total)    AS order_total
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

payments AS (
    SELECT
        order_id,
        SUM(CASE WHEN payment_status = 'success' THEN amount ELSE 0 END) AS amount_paid,
        COUNT(*)            AS payment_count,
        MAX(payment_method) AS payment_method
    FROM {{ ref('stg_payments') }}
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_date,
    oi.item_count,
    oi.total_quantity,
    oi.order_total,
    COALESCE(p.amount_paid, 0)    AS amount_paid,
    oi.order_total - COALESCE(p.amount_paid, 0) AS amount_outstanding,
    p.payment_method,
    o.created_at
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN payments p     ON o.order_id = p.order_id
WHERE oi.order_total >= {{ var('min_order_amount') }}
