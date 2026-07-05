with source as (
    select * from {{ source('olist', 'category_translation')}}
)

select
    trim(replace(product_category_name, chr(65279), '')) as product_category_name,
    product_category_name_english
from source