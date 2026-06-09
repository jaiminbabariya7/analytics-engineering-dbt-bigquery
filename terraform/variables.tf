variable "project_id"           { type = string }
variable "region"               { type = string; default = "us-central1" }
variable "bq_location"          { type = string; default = "US" }
variable "env"                  { type = string; default = "prod" }
variable "composer_trigger_url" { type = string; description = "Cloud Composer Airflow API trigger URL" }
