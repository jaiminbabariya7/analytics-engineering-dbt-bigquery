"""
Ingestion: loads CSV files from GCS into BigQuery raw tables.
Supports full (WRITE_TRUNCATE) and incremental (MERGE) modes.

Usage:
    python load_to_bigquery.py --table customers --mode full
    python load_to_bigquery.py --table sales     --mode incremental
"""
from __future__ import annotations
import argparse, logging, os
from google.cloud import bigquery, storage

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("bq_loader")

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
GCS_BUCKET = os.environ["GCS_RAW_BUCKET"]
BQ_DATASET = os.getenv("BQ_RAW_DATASET", "raw")
bq  = bigquery.Client(project=PROJECT_ID)

TABLE_CONFIG = {
    "customers": {
        "gcs_path": "raw/customers/customers.csv",
        "primary_key": "customer_id",
        "schema": [
            bigquery.SchemaField("customer_id",       "STRING",  "REQUIRED"),
            bigquery.SchemaField("first_name",        "STRING",  "NULLABLE"),
            bigquery.SchemaField("last_name",         "STRING",  "NULLABLE"),
            bigquery.SchemaField("email",             "STRING",  "NULLABLE"),
            bigquery.SchemaField("country",           "STRING",  "NULLABLE"),
            bigquery.SchemaField("city",              "STRING",  "NULLABLE"),
            bigquery.SchemaField("registration_date", "DATE",    "NULLABLE"),
            bigquery.SchemaField("is_active",         "BOOLEAN", "NULLABLE"),
        ],
    },
    "products": {
        "gcs_path": "raw/products/products.csv",
        "primary_key": "product_id",
        "schema": [
            bigquery.SchemaField("product_id",   "STRING",  "REQUIRED"),
            bigquery.SchemaField("product_name", "STRING",  "NULLABLE"),
            bigquery.SchemaField("category",     "STRING",  "NULLABLE"),
            bigquery.SchemaField("unit_price",   "NUMERIC", "NULLABLE"),
            bigquery.SchemaField("unit_cost",    "NUMERIC", "NULLABLE"),
            bigquery.SchemaField("stock_quantity","INTEGER","NULLABLE"),
        ],
    },
    "sales": {
        "gcs_path": "raw/sales/sales.csv",
        "primary_key": "sale_id",
        "schema": [
            bigquery.SchemaField("sale_id",      "STRING",  "REQUIRED"),
            bigquery.SchemaField("customer_id",  "STRING",  "NULLABLE"),
            bigquery.SchemaField("product_id",   "STRING",  "NULLABLE"),
            bigquery.SchemaField("sale_date",    "DATE",    "NULLABLE"),
            bigquery.SchemaField("quantity",     "INTEGER", "NULLABLE"),
            bigquery.SchemaField("unit_price",   "NUMERIC", "NULLABLE"),
            bigquery.SchemaField("discount_pct", "NUMERIC", "NULLABLE"),
            bigquery.SchemaField("channel",      "STRING",  "NULLABLE"),
        ],
    },
}


def full_load(table: str, cfg: dict) -> None:
    gcs_uri   = f"gs://{GCS_BUCKET}/{cfg['gcs_path']}"
    table_ref = f"{PROJECT_ID}.{BQ_DATASET}.{table}"
    job_config = bigquery.LoadJobConfig(
        schema=cfg["schema"],
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED,
    )
    logger.info("Full load: %s -> %s", gcs_uri, table_ref)
    job = bq.load_table_from_uri(gcs_uri, table_ref, job_config=job_config)
    job.result()
    logger.info("Loaded %d rows", job.output_rows)


def incremental_load(table: str, cfg: dict) -> None:
    pk          = cfg["primary_key"]
    staging_ref = f"{PROJECT_ID}.{BQ_DATASET}.{table}_staging"
    target_ref  = f"{PROJECT_ID}.{BQ_DATASET}.{table}"
    gcs_uri     = f"gs://{GCS_BUCKET}/{cfg['gcs_path']}"
    job_config  = bigquery.LoadJobConfig(
        schema=cfg["schema"], source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED,
    )
    bq.load_table_from_uri(gcs_uri, staging_ref, job_config=job_config).result()
    cols     = [f.name for f in cfg["schema"]]
    updates  = ", ".join(f"T.{c} = S.{c}" for c in cols if c != pk)
    inserts  = ", ".join(f"S.{c}" for c in cols)
    col_list = ", ".join(cols)
    merge_sql = f"""
        MERGE `{target_ref}` T USING `{staging_ref}` S ON T.{pk} = S.{pk}
        WHEN MATCHED     THEN UPDATE SET {updates}
        WHEN NOT MATCHED THEN INSERT ({col_list}) VALUES ({inserts})
    """
    logger.info("MERGE into %s ...", target_ref)
    bq.query(merge_sql).result()
    logger.info("MERGE complete for %s.", table)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", required=True, choices=list(TABLE_CONFIG))
    parser.add_argument("--mode",  default="full", choices=["full", "incremental"])
    args = parser.parse_args()
    cfg = TABLE_CONFIG[args.table]
    if args.mode == "full":
        full_load(args.table, cfg)
    else:
        incremental_load(args.table, cfg)