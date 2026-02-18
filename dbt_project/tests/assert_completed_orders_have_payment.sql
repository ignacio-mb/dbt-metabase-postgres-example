-- Every completed order should have at least one successful payment
select
    o.order_id,
    o.order_status,
    p.payment_status
from {{ ref('stg_orders') }} o
left join {{ ref('stg_payments') }} p
    on o.order_id = p.order_id
    and p.payment_status = 'success'
where o.order_status = 'completed'
  and p.payment_id is null
