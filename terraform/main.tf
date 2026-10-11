# ============================================================
# Analytics Engineering - GCP Infrastructure
#   - BigQuery datasets used by the loader and dbt (raw, staging, mart, snapshots)
#   - GCS bucket for raw CSV drops (GCS_RAW_BUCKET)
#   - Service account for the loader / dbt runs
# Scheduling is done by the Airflow DAG itself (daily 07:00 UTC).
# ============================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "tf-state-analytics-engineering"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── BigQuery Datasets ────────────────────────────────────────
# Names match dbt_project.yml (+schema) via macros/generate_schema_name.sql
locals {
  datasets = ["raw", "staging", "mart", "snapshots"]
}

resource "google_bigquery_dataset" "datasets" {
  for_each   = toset(local.datasets)
  dataset_id = each.value
  project    = var.project_id
  location   = var.bq_location

  labels = {
    env     = var.env
    managed = "terraform"
    layer   = each.value
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ── GCS bucket for raw CSV files ─────────────────────────────
resource "google_storage_bucket" "raw_bucket" {
  name                        = "${var.project_id}-analytics-raw"
  project                     = var.project_id
  location                    = var.bq_location
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  labels = {
    env     = var.env
    managed = "terraform"
  }
}

# ── Service Account ──────────────────────────────────────────
resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-runner"
  display_name = "Loader + dbt Runner Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "dbt_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_project_iam_member" "dbt_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_storage_bucket_iam_member" "dbt_gcs_reader" {
  bucket = google_storage_bucket.raw_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dbt_sa.email}"
}
