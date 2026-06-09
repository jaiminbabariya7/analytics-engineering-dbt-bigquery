# ============================================================
# Analytics Engineering - GCP Infrastructure
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
locals {
  datasets = ["raw", "staging", "intermediate", "marts_finance",
              "marts_marketing", "marts_operations", "snapshots", "seeds"]
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

# ── GCS Bucket ───────────────────────────────────────────────
resource "google_storage_bucket" "analytics_bucket" {
  name          = "${var.project_id}-analytics-artifacts"
  project       = var.project_id
  location      = var.region
  force_destroy = false

  versioning { enabled = true }

  lifecycle_rule {
    condition { age = 90 }
    action    { type = "SetStorageClass"; storage_class = "NEARLINE" }
  }

  labels = { env = var.env, managed = "terraform" }
}

# ── Service Account ──────────────────────────────────────────
resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-runner"
  display_name = "dbt Runner Service Account"
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

resource "google_storage_bucket_iam_member" "dbt_gcs_admin" {
  bucket = google_storage_bucket.analytics_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dbt_sa.email}"
}

# ── Cloud Scheduler (trigger Airflow) ────────────────────────
resource "google_cloud_scheduler_job" "daily_analytics_trigger" {
  name        = "daily-analytics-pipeline"
  description = "Trigger analytics engineering DAG daily at 06:00 UTC"
  schedule    = "0 6 * * *"
  time_zone   = "UTC"
  project     = var.project_id
  region      = var.region

  http_target {
    uri         = var.composer_trigger_url
    http_method = "POST"
    body        = base64encode(jsonencode({ conf = {} }))
    headers     = { "Content-Type" = "application/json" }
    oauth_token {
      service_account_email = google_service_account.dbt_sa.email
    }
  }
}

# ── Secret Manager ───────────────────────────────────────────
resource "google_secret_manager_secret" "slack_webhook" {
  secret_id = "slack-webhook-analytics"
  project   = var.project_id
  replication { automatic {} }
}
