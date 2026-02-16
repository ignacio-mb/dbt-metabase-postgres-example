{{ config(materialized='view') }}

SELECT
    id          AS product_id,
    name        AS product_name,
    category,
    price,
    created_at
FROM {{ source('raw', 'products') }}
