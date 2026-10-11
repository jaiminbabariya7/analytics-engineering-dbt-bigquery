# Legacy v1 (May 2024)

The first version of this project, kept for history. It is **not** used by the
current pipeline.

- `docs/`: the six-phase plan (data preparation, BigQuery schema, upsert ingestion, joins, partitioning, automation)
- `data/`: the small hand-made CSVs from that version (`customer_name`, `location`, `total_price` columns)
- `query/`: BigQuery SQL for external tables, `MERGE` upserts, partitioning and analysis
- `scripts/`: the data-simulation notebook and a Cloud Function + Cloud Scheduler job that ran the upsert daily
- `output/`: screenshots of query results from that version

The current project (repository root) replaced it with a Python loader, a
three-layer dbt project, an SCD Type 2 snapshot, Airflow orchestration and a
BigQuery ML churn model.
