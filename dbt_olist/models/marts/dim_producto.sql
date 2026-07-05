with productos as (
    select * from {{ ref('stg_olist__products')}}
),

traducion as (
    select * from {{ ref('stg_olist__category_translation')}}
)

select
    p.product_id,               -- PK
    p.product_category_name,    -- categoria em português
    coalesce(t.product_category_name_english, 'sin_categoria') as product_category_name_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_photos_qty
from productos p
left join traducion t
on p.product_category_name = t.product_category_name