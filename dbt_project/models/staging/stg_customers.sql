{{ config(materialized='view') }}

SELECT
    id          AS customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,
    email,
    created_at
FROM {{ source('raw', 'customers') }}
