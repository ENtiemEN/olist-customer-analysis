with ordenes as (
    select * from {{ ref('stg_olist__orders')}}
),

clientes as (
    select customer_id, customer_unique_id
    from {{ ref('stg_olist__customers')}}
),

items_por_orden as (            -- agregamos Al grain de orden antes de unir
    select
        order_id,
        count(*) as cantidad_items,
        sum(price) as valor_productos,
        sum(freight_value) as valor_flete
    from {{ ref('stg_olist__order_items')}}
    group by order_id
)

select
    o.order_id,                                                 -- PK (grain = order)
    c.customer_unique_id,                                       -- FK -> dim_cliente
    cast(o.order_purchase_timestamp as date) as fecha_compra,   -- FK -> dim_fecha
    o.order_status,

    -- Métricas (subidas desde los items, 0 si la orden no tiene items)
    coalesce(i.cantidad_items,0)                                as cantidad_items,
    coalesce(i.valor_productos, 0)                              as valor_productos,
    coalesce(i.valor_flete, 0)                                  as valor_flete,
    coalesce(i.valor_productos, 0) + coalesce(i.valor_flete, 0) as valor_total
from ordenes o
left join clientes c        on o.customer_id = c.customer_id
left join items_por_orden i   on o.order_id = i.order_id