with customers as (
    select * from {{ ref('stg_olist__customers') }}
),

ordenes as (
    select order_id, customer_id, order_purchase_timestamp
    from {{ ref('stg_olist__orders') }}
),

clientes_agg as (                          -- agregado 1: atributos por cliente (tu código original)
    select
        customer_unique_id,
        count(*)             as cantidad_customer_id,
        mode(customer_state) as customer_state,
        mode(customer_city)  as customer_city
    from customers
    group by customer_unique_id
),

ordenes_clientes as (                      -- resolvemos identidad antes de agregar fechas
    select
        c.customer_unique_id,
        o.order_purchase_timestamp
    from ordenes o
    left join customers c on o.customer_id = c.customer_id
),

fechas_agg as (                            -- agregado 2: fechas por cliente
    select
        customer_unique_id,
        min(cast(order_purchase_timestamp as date)) as fecha_primera_compra,
        max(cast(order_purchase_timestamp as date)) as fecha_ultima_compra
    from ordenes_clientes
    group by customer_unique_id
)

select
    ca.customer_unique_id,                 -- PK: persona real
    ca.cantidad_customer_id,               -- cuántas identidades-de-pedido tiene esta persona
    ca.customer_state,                     -- estado más frecuente de la persona
    ca.customer_city,                      -- ciudad más frecuente de la persona
    fa.fecha_primera_compra,               -- primera compra (nuevo)
    fa.fecha_ultima_compra                 -- última compra (nuevo)
from clientes_agg ca
left join fechas_agg fa on ca.customer_unique_id = fa.customer_unique_id