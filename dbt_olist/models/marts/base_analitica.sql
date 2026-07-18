-- Base analítica (feedback dado - Jos):
-- Se excluyen las órdenes 'canceled' y 'unavailable' -- no representan transacción real completa
-- distorsiona cualquier métrica de negocio (revenue, compra, tiempo entre compras)
-- Desde aquí, todo el análisis de negocio (Cohortes, LTV, RFM) parte de este mart, no de fct_ordenes

select * 
from {{ ref('fct_ordenes') }}
where order_status not in ('canceled', 'unavailable')