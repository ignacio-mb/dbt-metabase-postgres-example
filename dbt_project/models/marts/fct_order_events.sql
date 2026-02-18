{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='delete+insert'
    )
}}

with order_events as (
    select * from {{ ref('stg_order_events') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

order_totals as (
    select
        order_id,
        sum(line_total) as order_total
    from {{ ref('stg_order_items') }}
    group by 1
),

final as (
    select
        oe.event_id,
        oe.order_id,
        oe.event_type,
        oe.event_timestamp,
        oe.event_data,

        o.customer_id,
        c.full_name          as customer_name,
        c.email              as customer_email,
        o.order_status       as current_order_status,
        o.order_date,
        coalesce(ot.order_total, 0) as order_total,

        case oe.event_type
            when 'placed'           then 1
            when 'confirmed'        then 2
            when 'processing'       then 3
            when 'shipped'          then 4
            when 'out_for_delivery' then 5
            when 'delivered'        then 6
            when 'cancelled'        then -1
            when 'refunded'         then -2
            else 0
        end as event_sequence,

        oe.event_type in ('cancelled', 'refunded') as is_terminal_negative,
        oe.event_type = 'delivered'                 as is_successful_completion,

        lag(oe.event_type) over (
            partition by oe.order_id
            order by oe.event_timestamp
        ) as previous_event_type,

        lag(oe.event_timestamp) over (
            partition by oe.order_id
            order by oe.event_timestamp
        ) as previous_event_timestamp,

        case
            when lag(oe.event_timestamp) over (
                partition by oe.order_id
                order by oe.event_timestamp
            ) is not null
            then extract(epoch from (
                oe.event_timestamp
                - lag(oe.event_timestamp) over (
                    partition by oe.order_id
                    order by oe.event_timestamp
                )
            )) / 3600.0
        end as hours_since_previous_event

    from order_events oe
    left join orders o    on oe.order_id = o.order_id
    left join customers c on o.customer_id = c.customer_id
    left join order_totals ot on oe.order_id = ot.order_id

    {% if is_incremental() %}
    where oe.event_timestamp > (select max(event_timestamp) from {{ this }})
    {% endif %}
)

select * from final
