# IAM Bindings for BigQuery Datasets

# Admin group gets dataset owner permissions on all datasets
locals {
  all_datasets = [
    google_bigquery_dataset.contributor_bronze.dataset_id,
    google_bigquery_dataset.contributor_silver.dataset_id,
    google_bigquery_dataset.qualityaudit_bronze.dataset_id,
    google_bigquery_dataset.qualityaudit_silver.dataset_id,
    google_bigquery_dataset.programops_bronze.dataset_id,
    google_bigquery_dataset.programops_silver.dataset_id,
    google_bigquery_dataset.enterprise_gold.dataset_id,
    google_bigquery_dataset.applemap_mart.dataset_id,
    google_bigquery_dataset.googleads_mart.dataset_id,
    google_bigquery_dataset.metaads_mart.dataset_id,
    google_bigquery_dataset.googlesearch_mart.dataset_id
  ]

  bronze_datasets = [
    google_bigquery_dataset.contributor_bronze.dataset_id,
    google_bigquery_dataset.qualityaudit_bronze.dataset_id,
    google_bigquery_dataset.programops_bronze.dataset_id
  ]

  silver_datasets = [
    google_bigquery_dataset.contributor_silver.dataset_id,
    google_bigquery_dataset.qualityaudit_silver.dataset_id,
    google_bigquery_dataset.programops_silver.dataset_id
  ]

  mart_datasets = [
    google_bigquery_dataset.applemap_mart.dataset_id,
    google_bigquery_dataset.googleads_mart.dataset_id,
    google_bigquery_dataset.metaads_mart.dataset_id,
    google_bigquery_dataset.googlesearch_mart.dataset_id
  ]
}

# Admin group - dataset owners for all datasets
resource "google_bigquery_dataset_iam_member" "admin_dataset_owner" {
  for_each   = toset(local.all_datasets)
  dataset_id = each.value
  role       = "roles/bigquery.dataOwner"
  member     = "group:${var.group_admins}"
  project    = var.project_id
}

# Developer group - data viewer on all datasets + job user
resource "google_bigquery_dataset_iam_member" "developer_dataset_viewer" {
  for_each   = toset(local.all_datasets)
  dataset_id = each.value
  role       = "roles/bigquery.dataViewer"
  member     = "group:${var.group_developers}"
  project    = var.project_id
}

resource "google_project_iam_member" "developer_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "group:${var.group_developers}"
}

# Analyst group - ONLY data viewer on enterprise_gold dataset
resource "google_bigquery_dataset_iam_member" "analyst_gold_viewer" {
  dataset_id = google_bigquery_dataset.enterprise_gold.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:${var.group_analysts}"
  project    = var.project_id
}

# Datastream SAs - data editor on their respective bronze datasets
resource "google_bigquery_dataset_iam_member" "datastream_contributor_bronze_editor" {
  dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.datastream_contributor.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "datastream_qualityaudit_bronze_editor" {
  dataset_id = google_bigquery_dataset.qualityaudit_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.datastream_qualityaudit.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "datastream_programops_bronze_editor" {
  dataset_id = google_bigquery_dataset.programops_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.datastream_programops.email}"
  project    = var.project_id
}

# Cloud Function SAs - data editor on their respective bronze datasets
resource "google_bigquery_dataset_iam_member" "cf_contributor_bronze_editor" {
  dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.cf_contributor.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "cf_qualityaudit_bronze_editor" {
  dataset_id = google_bigquery_dataset.qualityaudit_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.cf_qualityaudit.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "cf_programops_bronze_editor" {
  dataset_id = google_bigquery_dataset.programops_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.cf_programops.email}"
  project    = var.project_id
}

# Bronze to Silver SA - viewer on all bronze datasets, editor on all silver datasets
resource "google_bigquery_dataset_iam_member" "bronze_to_silver_bronze_viewer" {
  for_each   = toset(local.bronze_datasets)
  dataset_id = each.value
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.bronze_to_silver.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "bronze_to_silver_silver_editor" {
  for_each   = toset(local.silver_datasets)
  dataset_id = each.value
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.bronze_to_silver.email}"
  project    = var.project_id
}

# Silver to Gold SA - viewer on all silver datasets, editor on gold dataset
resource "google_bigquery_dataset_iam_member" "silver_to_gold_silver_viewer" {
  for_each   = toset(local.silver_datasets)
  dataset_id = each.value
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.silver_to_gold.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "silver_to_gold_gold_editor" {
  dataset_id = google_bigquery_dataset.enterprise_gold.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.silver_to_gold.email}"
  project    = var.project_id
}

# Data mart SAs - viewer only on their respective mart datasets
resource "google_bigquery_dataset_iam_member" "applemap_mart_viewer" {
  dataset_id = google_bigquery_dataset.applemap_mart.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.applemap_mart.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "googleads_mart_viewer" {
  dataset_id = google_bigquery_dataset.googleads_mart.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.googleads_mart.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "metaads_mart_viewer" {
  dataset_id = google_bigquery_dataset.metaads_mart.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.metaads_mart.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "googlesearch_mart_viewer" {
  dataset_id = google_bigquery_dataset.googlesearch_mart.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.googlesearch_mart.email}"
  project    = var.project_id
}

# Project-level IAM for BigQuery job execution
resource "google_project_iam_member" "datastream_job_user" {
  for_each = toset([
    google_service_account.datastream_contributor.email,
    google_service_account.datastream_qualityaudit.email,
    google_service_account.datastream_programops.email
  ])
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${each.value}"
}

resource "google_project_iam_member" "cf_job_user" {
  for_each = toset([
    google_service_account.cf_contributor.email,
    google_service_account.cf_qualityaudit.email,
    google_service_account.cf_programops.email
  ])
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${each.value}"
}

resource "google_project_iam_member" "transform_job_user" {
  for_each = toset([
    google_service_account.bronze_to_silver.email,
    google_service_account.silver_to_gold.email
  ])
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${each.value}"
}

# Secret Manager access for Datastream SAs
resource "google_secret_manager_secret_iam_member" "datastream_contributor_secret" {
  secret_id = var.secret_contributor_db
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.datastream_contributor.email}"
  project   = var.project_id
}

resource "google_secret_manager_secret_iam_member" "datastream_qualityaudit_secret" {
  secret_id = var.secret_qualityaudit_db
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.datastream_qualityaudit.email}"
  project   = var.project_id
}

resource "google_secret_manager_secret_iam_member" "datastream_programops_secret" {
  secret_id = var.secret_programops_db
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.datastream_programops.email}"
  project   = var.project_id
}
