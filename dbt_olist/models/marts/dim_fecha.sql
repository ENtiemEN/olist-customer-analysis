-- calendario 2016-09 a 2018-11
with fechas as (
    select unnest(range(date '2016-09-01', date '2018-11-01', interval '1 day')) as fecha
)

select 
    fecha,
    extract(year from fecha) as anio,
    extract(month from fecha) as mes,
    extract(day from fecha) as dia,
    extract(quarter from fecha) as trimestre,
    extract(dayofweek from fecha) as dia_semana,    -- 0=domingo, 6=sábado
    strftime(fecha, '%Y-%m') as anio_mes,           -- '2017-05' para agrupar por mes
from fechas
order by fecha