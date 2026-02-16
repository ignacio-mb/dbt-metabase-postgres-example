{{ config(materialized='view') }}

SELECT
    id          AS order_id,
    customer_id,
    status      AS order_status,
    order_date,
    created_at
FROM {{ source('raw', 'orders') }}
