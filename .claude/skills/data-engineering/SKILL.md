---
name: data-engineering
description: "Patterns d'ingénierie de données : ETL/ELT pipelines, transformation dbt, orchestration Airflow, validation de qualité et architectures data modernes. Activer pour concevoir des pipelines de données, traiter de grands volumes ou mettre en place un data warehouse."
license: MIT
sources: "wshobson/agents (data-engineer, dbt-transformation-patterns, airflow-dag-patterns, data-quality-frameworks, spark-optimization)"
---

# Data Engineering

## Quand utiliser cette skill

- Concevoir des pipelines ETL/ELT
- Transformer et modéliser des données avec dbt
- Orchestrer des workflows avec Airflow ou Prefect
- Valider la qualité des données
- Architecting un data warehouse ou data lakehouse

## 1. Architecture Data Moderne

```
Sources → Ingestion → Storage → Transform → Serve → Consume
  │           │          │          │          │        │
  DB          Airbyte    S3/GCS    dbt       Metabase  BI/ML
  API         Fivetran   Snowflake  Spark     Tableau   Apps
  Events      Kafka      BigQuery   Python    API
              Batch      Delta Lake            Redshift
```

**Choix d'architecture** :
- **Petit volume (< 10GB)** : PostgreSQL + dbt + Metabase
- **Medium (10GB-1TB)** : Snowflake/BigQuery + dbt + Airflow
- **Large (> 1TB)** : Delta Lake/Iceberg + Spark + Databricks

## 2. dbt — Transformation et modélisation

```sql
-- models/staging/stg_orders.sql
-- Staging : nettoyage et typage depuis la source brute
{{ config(materialized='view') }}

SELECT
    id::text                                    AS order_id,
    user_id::text                               AS user_id,
    LOWER(TRIM(status))                         AS status,
    total_amount / 100.0                        AS total_amount,  -- Centimes → euros
    created_at AT TIME ZONE 'UTC'               AS created_at_utc,
    _ingested_at                                AS _source_ingested_at
FROM {{ source('raw', 'orders') }}
WHERE id IS NOT NULL
  AND total_amount > 0

-- models/marts/fct_orders.sql
-- Fact table : métriques métier
{{ config(materialized='incremental', unique_key='order_id') }}

WITH orders AS (SELECT * FROM {{ ref('stg_orders') }}),
     users  AS (SELECT * FROM {{ ref('stg_users') }}),
     items  AS (SELECT * FROM {{ ref('stg_order_items') }})

SELECT
    o.order_id,
    o.user_id,
    u.country,
    o.status,
    o.total_amount,
    i.item_count,
    i.product_count,
    o.created_at_utc,
    DATE_TRUNC('month', o.created_at_utc) AS order_month
FROM orders o
LEFT JOIN users u USING (user_id)
LEFT JOIN (
    SELECT order_id,
           COUNT(*) AS item_count,
           COUNT(DISTINCT product_id) AS product_count
    FROM items GROUP BY order_id
) i USING (order_id)

{% if is_incremental() %}
WHERE o.created_at_utc > (SELECT MAX(created_at_utc) FROM {{ this }})
{% endif %}
```

### Tests dbt

```yaml
# models/staging/schema.yml
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        tests: [unique, not_null]
      - name: status
        tests:
          - not_null
          - accepted_values:
              values: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']
      - name: total_amount
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 100000
```

## 3. Airflow — DAG structuré

```python
# dags/orders_pipeline.py
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.sensors.external_task import ExternalTaskSensor

DEFAULT_ARGS = {
    'owner': 'data-team',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,
    'email_on_failure': True,
    'email': ['data-alerts@company.com'],
}

with DAG(
    dag_id='orders_daily_pipeline',
    default_args=DEFAULT_ARGS,
    description='Daily orders ETL pipeline',
    schedule='0 6 * * *',           # 6h UTC tous les jours
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,               # Pas de runs en parallèle
    tags=['orders', 'daily', 'etl'],
) as dag:

    # 1. Attendre que la source soit prête
    wait_for_source = ExternalTaskSensor(
        task_id='wait_for_source_refresh',
        external_dag_id='source_ingestion',
        external_task_id='mark_complete',
        timeout=3600,
    )

    # 2. Extraction
    extract = PythonOperator(
        task_id='extract_orders',
        python_callable=extract_orders_from_source,
        op_kwargs={'date': '{{ ds }}'},
    )

    # 3. Validation qualité
    validate = PythonOperator(
        task_id='validate_data_quality',
        python_callable=run_data_quality_checks,
    )

    # 4. Transformation dbt
    transform = BashOperator(
        task_id='dbt_run',
        bash_command='dbt run --select orders+ --target prod',
    )

    # 5. Tests dbt
    test = BashOperator(
        task_id='dbt_test',
        bash_command='dbt test --select orders+ --target prod',
    )

    wait_for_source >> extract >> validate >> transform >> test
```

## 4. Validation de qualité des données

```python
from dataclasses import dataclass
from typing import Callable
import pandas as pd

@dataclass
class DataQualityCheck:
    name: str
    query: str
    threshold: float   # % acceptable de violations
    severity: str      # 'error' | 'warning'

QUALITY_CHECKS = [
    DataQualityCheck(
        name='orders_completeness',
        query="SELECT COUNT(*) FROM orders WHERE user_id IS NULL",
        threshold=0.0,    # 0% de null accepté
        severity='error',
    ),
    DataQualityCheck(
        name='orders_freshness',
        query="""
            SELECT EXTRACT(EPOCH FROM (NOW() - MAX(created_at)))/3600 AS hours_since_last
            FROM orders
        """,
        threshold=25,     # Pas de données depuis > 25h = anomalie
        severity='warning',
    ),
    DataQualityCheck(
        name='negative_amounts',
        query="SELECT COUNT(*) FROM orders WHERE total_amount < 0",
        threshold=0.0,
        severity='error',
    ),
]
```

## 5. Modélisation dimensionnelle (Star Schema)

```sql
-- Dimension date (très courante)
CREATE TABLE dim_date AS
WITH dates AS (
    SELECT generate_series(
        '2020-01-01'::date,
        '2030-12-31'::date,
        '1 day'::interval
    )::date AS date
)
SELECT
    date,
    EXTRACT(year FROM date)   AS year,
    EXTRACT(month FROM date)  AS month,
    EXTRACT(day FROM date)    AS day,
    EXTRACT(dow FROM date)    AS day_of_week,
    TO_CHAR(date, 'Month')    AS month_name,
    TO_CHAR(date, 'Day')      AS day_name,
    date = DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day' AS is_last_day_of_month
FROM dates;
```

## Anti-patterns à éviter

```python
# ❌ Charger tout en mémoire pour les grands volumes
df = pd.read_csv('10gb_file.csv')  # OOM

# ✅ Traitement par chunks
for chunk in pd.read_csv('10gb_file.csv', chunksize=10_000):
    process(chunk)

# ❌ Pas de schéma de données (tout en string)
df['amount'] = df['amount']  # reste string → calculs faux

# ✅ Typage explicite
df['amount'] = pd.to_numeric(df['amount'], errors='coerce')

# ❌ Transformation dans les pipelines d'ingestion
# Mélanger extraction et transformation = difficile à débugger

# ✅ Principe ELT : extraire brut, transformer séparément (dbt)

# ❌ Pas de gestion des doublons dans les pipelines
# INSERT INTO ... SELECT ...  → doublons si retry

# ✅ UPSERT / MERGE avec clé naturelle
# INSERT ... ON CONFLICT (id) DO UPDATE SET ...
```
