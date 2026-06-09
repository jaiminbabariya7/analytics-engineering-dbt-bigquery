output "dbt_service_account_email" {
  value = google_service_account.dbt_sa.email
}
output "analytics_bucket_name" {
  value = google_storage_bucket.analytics_bucket.name
}
output "bigquery_datasets" {
  value = { for k, v in google_bigquery_dataset.datasets : k => v.id }
}
