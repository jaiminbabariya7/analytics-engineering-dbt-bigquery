.PHONY: help sample-data upload-data load-raw dev-up dev-down dbt-run dbt-test dbt-build \
        dbt-snapshot dbt-freshness dbt-docs churn-model terraform-init terraform-plan \
        terraform-apply lint format setup clean

PROJECT_ID ?= $(shell gcloud config get-value project)
DBT_DIR     = dbt_project
DBT         = cd $(DBT_DIR) && dbt
DBT_FLAGS   = --profiles-dir .

help:
	@echo "Analytics Engineering — Available Commands"
	@echo "==========================================="
	@echo "  make setup           Install dependencies + create dbt_project/profiles.yml"
	@echo "  make sample-data     Regenerate the synthetic CSVs in data/"
	@echo "  make upload-data     Copy data/*.csv to gs://\$$GCS_RAW_BUCKET/raw/<table>/"
	@echo "  make load-raw        Load the raw tables into BigQuery (full load)"
	@echo "  make dbt-build       dbt run + test + snapshot"
	@echo "  make churn-model     Train / evaluate / score the BigQuery ML churn model"
	@echo "  make dev-up          Start local Airflow"
	@echo "  make terraform-apply Deploy GCP infrastructure"

setup:
	pip install -r requirements.txt
	test -f $(DBT_DIR)/profiles.yml || cp $(DBT_DIR)/profiles.yml.example $(DBT_DIR)/profiles.yml

sample-data:
	python scripts/generate_sample_data.py --out data

upload-data:
	for t in customers products sales; do \
		gsutil cp data/$$t.csv gs://$(GCS_RAW_BUCKET)/raw/$$t/$$t.csv; \
	done

load-raw:
	for t in customers products sales; do \
		python ingestion/load_to_bigquery.py --table $$t --mode full; \
	done

dev-up:
	docker compose up -d
	@echo "Airflow at http://localhost:8080  (admin/admin)"

dev-down:
	docker compose down -v

dbt-run:
	$(DBT) run $(DBT_FLAGS)

dbt-test:
	$(DBT) test $(DBT_FLAGS)

dbt-snapshot:
	$(DBT) snapshot $(DBT_FLAGS)

dbt-build:
	$(DBT) build $(DBT_FLAGS)

dbt-freshness:
	$(DBT) source freshness $(DBT_FLAGS)

dbt-docs:
	$(DBT) docs generate $(DBT_FLAGS) && $(DBT) docs serve $(DBT_FLAGS) --port 8081

churn-model:
	sed "s/PROJECT_ID/$(PROJECT_ID)/g" sql/bigquery_ml_churn.sql | bq query --use_legacy_sql=false

lint:
	sqlfluff lint $(DBT_DIR)/models --dialect bigquery

format:
	sqlfluff fix $(DBT_DIR)/models --dialect bigquery

terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan -var="project_id=$(PROJECT_ID)"

terraform-apply:
	cd terraform && terraform apply -var="project_id=$(PROJECT_ID)"

clean:
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/dbt_packages $(DBT_DIR)/logs
	find . -type d -name __pycache__ -exec rm -rf {} +
