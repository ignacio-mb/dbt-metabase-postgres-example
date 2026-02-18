with source as (
    select * from {{ source('raw', 'order_events') }}
),

renamed as (
    select
        id          as event_id,
        order_id,
        event_type,
        event_data,
        created_at  as event_timestamp
    from source
)

select * from renamed
