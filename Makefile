.PHONY: help dev-up dev-down dbt-run dbt-test dbt-docs ge-validate \
        terraform-init terraform-apply lint setup clean

PROJECT_ID ?= $(shell gcloud config get-value project)
DBT_DIR     = dbt_project
GE_DIR      = great_expectations

help:
	@echo "Analytics Engineering — Available Commands"
	@echo "==========================================="
	@echo "  make dev-up          Start local Airflow + services"
	@echo "  make dev-down        Stop local services"
	@echo "  make dbt-run         Run full dbt pipeline (dev)"
	@echo "  make dbt-test        Run all dbt tests"
	@echo "  make dbt-docs        Generate & serve dbt docs (localhost:8081)"
	@echo "  make ge-validate     Run Great Expectations checkpoints"
	@echo "  make setup           Install dependencies + init BigQuery"
	@echo "  make lint            Run sqlfluff on dbt models"
	@echo "  make terraform-apply Deploy GCP infrastructure"
	@echo "  make clean           Remove build artefacts"

dev-up:
	docker compose up -d --build
	@echo "✅  Airflow at http://localhost:8080  (admin/admin)"

dev-down:
	docker compose down -v

setup:
	pip install -r requirements.txt
	cd $(DBT_DIR) && dbt deps
	python scripts/setup_bigquery.py

dbt-run:
	cd $(DBT_DIR) && dbt run --profiles-dir . --target dev

dbt-run-prod:
	cd $(DBT_DIR) && dbt run --profiles-dir . --target prod

dbt-test:
	cd $(DBT_DIR) && dbt test --profiles-dir . --target dev

dbt-docs:
	cd $(DBT_DIR) && dbt docs generate --profiles-dir . && dbt docs serve --port 8081

dbt-snapshot:
	cd $(DBT_DIR) && dbt snapshot --profiles-dir . --target dev

dbt-freshness:
	cd $(DBT_DIR) && dbt source freshness --profiles-dir .

ge-validate:
	cd $(GE_DIR) && great_expectations checkpoint run raw_data_checkpoint
	cd $(GE_DIR) && great_expectations checkpoint run marts_checkpoint

lint:
	sqlfluff lint $(DBT_DIR)/models --dialect bigquery

format:
	sqlfluff fix $(DBT_DIR)/models --dialect bigquery

terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan -var="project_id=$(PROJECT_ID)"

terraform-apply:
	cd terraform && terraform apply -var="project_id=$(PROJECT_ID)" -auto-approve

clean:
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/dbt_packages $(DBT_DIR)/logs
	find . -type d -name __pycache__ -exec rm -rf {} +
