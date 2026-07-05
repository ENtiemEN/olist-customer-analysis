with items as (
    select * from {{ ref('stg_olist__order_items') }}
),

ordenes as (
    select order_id, customer_id, order_purchase_timestamp
    from {{ ref('stg_olist__orders') }}
),

clientes as (
    select customer_id, customer_unique_id
    from {{ ref('stg_olist__customers') }}
),

ordenes_clientes as (           -- resolvemos la identidad, como en fct_ordenes
    select
        o.order_id,
        cast(o.order_purchase_timestamp as date) as fecha_compra,
        c.customer_unique_id
    from ordenes o
    left join clientes c on o.customer_id = c.customer_id
)

select
    i.order_id || '-' || i.order_item_id as item_key,   -- surrogate key (PK)
    i.order_id,                                         -- FK -> fct_ordenes
    i.order_item_id,
    i.product_id,                                       -- FK -> dim_producto
    i.seller_id,                                        -- dimension degenerada (no hay dim_seller, aún)
    oc.customer_unique_id,                              -- FK -> dim_cliente (denormalizado)
    oc.fecha_compra,                                    -- FK -> dim_fecha (denormalizado)
    i.price as valor_producto,
    i.freight_value as valor_flete,
    i.price + i.freight_value as valor_total
from items i
left join ordenes_clientes oc on i.order_id = oc.order_id