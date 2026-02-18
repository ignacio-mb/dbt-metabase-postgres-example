{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('date_spine_start') ~ "' as date)",
        end_date="cast('" ~ var('date_spine_end') ~ "' as date)"
    ) }}
),

final as (
    select
        date_day                                          as date_key,
        extract(year from date_day)::int                  as year,
        extract(quarter from date_day)::int               as quarter,
        extract(month from date_day)::int                 as month,
        extract(week from date_day)::int                  as week_of_year,
        extract(dow from date_day)::int                   as day_of_week,
        extract(day from date_day)::int                   as day_of_month,
        to_char(date_day, 'Month')                        as month_name,
        to_char(date_day, 'Day')                          as day_name,
        date_trunc('month', date_day)::date               as first_day_of_month,
        (date_trunc('month', date_day) + interval '1 month - 1 day')::date as last_day_of_month,
        date_trunc('quarter', date_day)::date             as first_day_of_quarter,
        case
            when extract(dow from date_day) in (0, 6) then true
            else false
        end                                               as is_weekend
    from date_spine
)

select * from final
