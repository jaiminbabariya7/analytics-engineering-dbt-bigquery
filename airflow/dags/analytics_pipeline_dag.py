"""
Airflow DAG: Analytics Engineering Pipeline.
Orchestrates: raw ingestion -> dbt staging -> intermediate -> mart -> tests -> snapshots.
Schedule: Daily at 07:00 UTC.
"""
from __future__ import annotations
import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.dates import days_ago

DBT_DIR  = "/opt/airflow/dbt_project"
DBT_CMD  = f"dbt --project-dir {DBT_DIR} --profiles-dir {DBT_DIR}"

DEFAULT_ARGS = {
    "owner": "jaimin.babariya",
    "depends_on_past": False,
    "start_date": days_ago(1),
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
}


def ingest_table(table: str, mode: str = "incremental", **kwargs) -> None:
    import subprocess, sys
    subprocess.check_call([
        sys.executable, "/opt/airflow/ingestion/load_to_bigquery.py",
        "--table", table, "--mode", mode,
    ])


with DAG(
    dag_id="analytics_engineering_pipeline",
    description="Raw ingestion -> dbt transforms -> data quality tests",
    default_args=DEFAULT_ARGS,
    schedule_interval="0 7 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["analytics", "dbt", "bigquery"],
) as dag:

    start = EmptyOperator(task_id="start")
    end   = EmptyOperator(task_id="end")

    ingest_customers = PythonOperator(
        task_id="ingest_customers",
        python_callable=ingest_table,
        op_kwargs={"table": "customers", "mode": "incremental"},
    )
    ingest_products = PythonOperator(
        task_id="ingest_products",
        python_callable=ingest_table,
        op_kwargs={"table": "products", "mode": "incremental"},
    )
    ingest_sales = PythonOperator(
        task_id="ingest_sales",
        python_callable=ingest_table,
        op_kwargs={"table": "sales", "mode": "incremental"},
    )

    dbt_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=f"{DBT_CMD} run --select staging.*",
    )
    dbt_test_staging = BashOperator(
        task_id="dbt_test_staging",
        bash_command=f"{DBT_CMD} test --select staging.*",
    )
    dbt_intermediate = BashOperator(
        task_id="dbt_run_intermediate",
        bash_command=f"{DBT_CMD} run --select intermediate.*",
    )
    dbt_mart = BashOperator(
        task_id="dbt_run_mart",
        bash_command=f"{DBT_CMD} run --select mart.*",
    )
    dbt_test_mart = BashOperator(
        task_id="dbt_test_mart",
        bash_command=f"{DBT_CMD} test --select mart.*",
    )
    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command=f"{DBT_CMD} snapshot",
    )

    start >> [ingest_customers, ingest_products, ingest_sales]
    [ingest_customers, ingest_products, ingest_sales] >> dbt_staging
    dbt_staging >> dbt_test_staging >> dbt_intermediate
    dbt_intermediate >> dbt_mart >> dbt_test_mart >> dbt_snapshot >> end