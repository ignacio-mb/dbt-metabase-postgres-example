{{ config(materialized='view') }}

SELECT
    id          AS payment_id,
    order_id,
    amount,
    method      AS payment_method,
    status      AS payment_status,
    created_at
FROM {{ source('raw', 'payments') }}
