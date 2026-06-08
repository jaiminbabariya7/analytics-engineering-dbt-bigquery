# BigQuery Data Pipeline

![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)
![BigQuery](https://img.shields.io/badge/BigQuery-Data%20Warehouse-4285F4?logo=googlebigquery)
![SQL](https://img.shields.io/badge/SQL-Advanced-lightblue)
![dbt-ready](https://img.shields.io/badge/dbt--ready-compatible-FF694B)
![License](https://img.shields.io/badge/License-MIT-green)

> End-to-end BigQuery data pipeline: schema design, GCS-based ingestion with upsert (MERGE) logic, analytical SQL, time-based partitioning, and automated scheduling.

## Table of Contents
- [Architecture](#architecture)
- [Pipeline Phases](#pipeline-phases)
- [Project Structure](#project-structure)
- [SQL Queries](#sql-queries)
- [Setup](#setup)
- [Sample Data](#sample-data)
- [Skills Demonstrated](#skills-demonstrated)

## Architecture
```
CSV Files (customers / products / sales)
        ↓
Google Cloud Storage (raw zone)
        ↓
BigQuery External Tables
        ↓  MERGE (upsert)
BigQuery Native Tables  ←─ partitioned by date
        ↓
Analytical SQL Queries → Business Insights
```

## Pipeline Phases

| Phase | Description | Key Technique |
|---|---|---|
| 1. Data Preparation | Load CSV data to GCS | pandas + google-cloud-storage |
| 2. Schema Definition | CREATE TABLE with type constraints | BigQuery DDL |
| 3. Ingestion with Upsert | MERGE into target table | BigQuery MERGE statement |
| 4. Joining & Analysis | Multi-table analytical queries | JOINs, aggregations, window functions |
| 5. Partitioning | Date-partitioned tables for cost & performance | PARTITION BY DATE |
| 6. Automation | Scheduled queries via Cloud Scheduler | BigQuery Scheduled Queries |

## Project Structure
```
├── data/
│   ├── customers.csv
│   ├── products.csv
│   └── sales.csv
├── query/
│   ├── Schema_Table.sql              # CREATE TABLE DDL
│   ├── create_external_tables.sql    # GCS → BigQuery external tables
│   ├── Merge_Table_Upsert_Logic.sql  # MERGE (upsert) logic
│   ├── analyzing_customer_purchase_trends.sql
│   ├── top_selling_customers_per_region.sql
│   └── sales_table_partitioning.sql
├── docs/                             # Phase-by-phase walkthrough
└── output/                           # Screenshots of query results
```

## SQL Highlights

### Upsert with MERGE
```sql
MERGE sales_dataset.sales_table T
USING (SELECT * FROM sales_dataset.sales_staging) S
ON T.sale_id = S.sale_id
WHEN MATCHED THEN
  UPDATE SET amount = S.amount, updated_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (sale_id, customer_id, product_id, amount, sale_date)
  VALUES (S.sale_id, S.customer_id, S.product_id, S.amount, S.sale_date);
```

### Partitioned Table
```sql
CREATE TABLE sales_dataset.sales_partitioned
PARTITION BY DATE(sale_date)
CLUSTER BY customer_id, product_id
AS SELECT * FROM sales_dataset.sales_table;
```

## Setup
```bash
git clone https://github.com/jaiminbabariya7/Data-Pipeline-BigQuery
cd Data-Pipeline-BigQuery
pip install google-cloud-bigquery google-cloud-storage pandas
export GOOGLE_APPLICATION_CREDENTIALS=path/to/sa.json
export GCP_PROJECT_ID=your-project
```

## Skills Demonstrated
`BigQuery` · `SQL` · `MERGE/Upsert` · `Table Partitioning` · `GCS` · `Data Pipeline Design` · `Python` · `GCP`
