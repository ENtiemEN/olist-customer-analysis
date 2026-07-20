-- Segmentación RFM por cliente (Semana 3), sobre base_analitica (órdenes reales).
-- Decisión de diseño: la frecuencia colapsa (~97% compra una sola vez), así que
-- NO se puntúa en cuartiles (no tendría señal). Se usa como bandera binaria (repite = 2+ órdenes)
-- Los cuartiles 1-4 se aplican solo a Recency y Monetary

with base as (
    select customer_unique_id, order_id, fecha_compra, valor_total
    from {{ ref('base_analitica') }}
),

corte as (
    select max(fecha_compra) as fecha_corte from base
),

rfm as (
    select
        b.customer_unique_id,
        date_diff('day', max(b.fecha_compra), c.fecha_corte) as recency_dias,
        count(distinct b.order_id)  as frequency,
        sum(b.valor_total)  as monetary
    from base b
    cross join corte c
    group by b.customer_unique_id, c.fecha_corte
),

scores as (
    select
        *,
        ntile(4) over (order by recency_dias desc) as r_score,        -- reciente --> 4
        ntile(4) over (order by monetary asc) as m_score,        -- monto alto --> 4
        case when frequency >= 2 then 1 else 0 end as repite    -- F binaria
    from rfm
)

select
    customer_unique_id,
    recency_dias,
    frequency,
    monetary,
    r_score,
    m_score,
    repite,
    case
        when repite = 1 and m_score >= 3  then 'Campeones'
        when repite = 1                   then 'Leales'
        when r_score >= 3 and m_score >=3 then 'Prometedores'
        when r_score >= 3                 then 'Recientes'
        when m_score >= 3                 then 'Dormidos alto valor'
        else 'Hibernando'
    end as segmento
from scores