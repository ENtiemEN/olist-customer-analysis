# Olist Customer Analysis

Análisis de la base de clientes del dataset público de [Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (e-commerce brasileño), usando **dbt + DuckDB** para el modelado de datos y **Jupyter/pandas** para la exploración.

Proyecto de capacitación en curso — Semana 1 (modelado de datos): completa. Semanas 2-3 (cohortes, RFM, segmentación) pendientes.

## Stack

- **DuckDB** — motor de base de datos analítico embebido (un solo archivo, sin servidor).
- **dbt-core + dbt-duckdb** — transforma los datos crudos en un modelo dimensional (staging → marts), con tests automáticos.
- **Python 3.12 + Jupyter** — exploración de datos y queries de negocio (`pandas`, `duckdb`).

## Estructura del repo

```
olist-customer-analysis/
├── dbt_olist/                          # proyecto dbt
│   ├── models/
│   │   ├── staging/                    # 9 vistas 1:1 sobre bronze (limpieza ligera)
│   │   └── marts/                      # modelo estrella: dimensiones + hechos
│   ├── macros/
│   ├── dbt_project.yml
│   └── profiles.yml                    # conexión a ../olist.duckdb (vive junto al proyecto, no en ~/.dbt/)
├── notebooks/
│   └── 01_setup.ipynb                  # carga a bronze + exploración + 16 queries de negocio
├── olist.duckdb                        # la base de datos (se genera localmente, no se versiona)
├── requirements.txt
└── README.md
```

Los 9 CSV originales de Olist **no viven dentro de este repo**: se esperan en `../Data/` (un nivel arriba de `olist-customer-analysis/`), es decir:

```
Entregable-Julio/
├── Data/                                <- los 9 CSV de Olist van acá
│   ├── olist_customers_dataset.csv
│   ├── olist_orders_dataset.csv
│   └── ... (9 en total)
└── olist-customer-analysis/             <- este repo
```

## Setup

**1. Entorno virtual e instalación de dependencias** (parado en la raíz del repo, `olist-customer-analysis/`):

```powershell
py -3.12 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

**2. Los datos.** Asegurate de tener los 9 CSV de Olist en `../Data/` (ver estructura arriba). Si no los tenés, descargalos del [dataset original en Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

## Cómo correr el proyecto de punta a punta

### Paso 1 — Cargar los datos crudos a DuckDB (capa `bronze`)

Abrí `notebooks/01_setup.ipynb` y corré todas las celdas (`Restart & Run All` / *Restart Kernel and Run All Cells*). La primera celda lee los 9 CSV desde `../Data/` y los carga como tablas en el schema `bronze` del archivo `olist.duckdb` (se crea automáticamente en la raíz del repo si no existe).

### Paso 2 — Correr el modelo dbt (staging + marts)

Los comandos de dbt se corren **siempre parado en `dbt_olist/`** (el `profiles.yml` de ahí apunta a `../olist.duckdb`):

```powershell
cd dbt_olist
dbt debug --profiles-dir .      # solo verifica la conexión, no transforma nada
dbt run --profiles-dir .        # corre las 14 vistas/tablas: staging + marts
dbt test --profiles-dir .       # corre las 22 pruebas (unique, not_null, relationships)
```

Resultado esperado: `dbt run` con 14 modelos en `OK`, `dbt test` con `PASS=22 WARN=0 ERROR=0`.

> **Ojo con las rutas relativas.** DuckDB no falla si te conectás a una ruta que no existe: crea silenciosamente una base vacía nueva ahí. Por eso la regla fija de este proyecto es: **comandos dbt se corren desde `dbt_olist/`** (usa `../olist.duckdb`), **cualquier verificación en Python suelta se corre desde la raíz del repo** (usa `olist.duckdb`, sin `../`). Si en algún momento una tabla que debería existir "no aparece", lo primero a revisar es si se generó un archivo `.duckdb` fantasma de pocos KB en el lugar equivocado.

### Paso 3 — Explorar los resultados

De vuelta en `notebooks/01_setup.ipynb`: además de la carga y exploración inicial de `bronze`, el notebook tiene una sección **"Tarea 3 — Queries de negocio sobre el modelo marts"** con 16 queries de negocio, agrupadas en 6 bloques temáticos:

1. Volumen y tendencia temporal
2. Producto y categoría
3. Comportamiento de cliente (recompra, tiempo entre compras)
4. Geografía
5. Vendedores
6. Pagos y satisfacción

Cada query tiene una celda markdown explicando la pregunta de negocio y el criterio de diseño antes del código.

## El modelo de datos

```
Data/*.csv  →  bronze.*  →  stg_olist__*  →  dim_* / fct_*
 (archivo)     (tabla        (vista limpia    (modelo de negocio:
               cruda)         1:1)             joins, filtros, métricas)
```

**Staging** (9 vistas, schema `staging`): una vista 1:1 por cada tabla de `bronze` — mismas filas, columnas explícitas, tipos corregidos, sin joins ni filtros de negocio.

**Marts** (schema `marts`), esquema estrella:

| Modelo | Grain (1 fila =) | Filas |
|---|---|---|
| `dim_cliente` | una persona real (`customer_unique_id`) | 96.096 |
| `dim_producto` | un producto (`product_id`) | 32.951 |
| `dim_fecha` | un día del calendario | 791 |
| `fct_ordenes` | una orden (`order_id`) | 99.441 |
| `fct_items` | un ítem de orden (`order_id` + `order_item_id`) | 112.650 |

**Decisión clave del proyecto:** la identidad del cliente se resuelve sobre `customer_unique_id`, no sobre `customer_id` (este último es casi 1:1 con las órdenes). Toda métrica de cliente (recompra, cohortes, RFM) se apoya en `customer_unique_id`.

## Tests de calidad (dbt)

22 tests en `dbt_olist/models/marts/_marts__models.yml`: `unique` y `not_null` en las claves de cada tabla, y `relationships` para validar la integridad referencial entre hechos y dimensiones (por ejemplo, que todo `product_id` de `fct_items` exista en `dim_producto`).

## Próximos pasos (fuera del alcance de este README)

- **Quality checks** (base analítica filtrada por `order_status`, funnel de reconciliación, variable `FECHA_CORTE` única) antes de arrancar cohortes.
- **Semana 2:** cohortes de retención y segmentación RFM.
- **Semana 3:** caracterización de segmentos y deck final.
