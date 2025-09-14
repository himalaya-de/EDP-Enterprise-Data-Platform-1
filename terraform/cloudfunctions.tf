# Cloud Functions for staging bucket to BigQuery ingestion

# Cloud Function source code archives
data "archive_file" "cf_contributor_source" {
  count       = var.enable_cloud_functions ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../cloud_functions/cf_contributor_staging_to_bronze"
  output_path = "${path.module}/cf_contributor_staging_to_bronze.zip"
}

data "archive_file" "cf_qualityaudit_source" {
  count       = var.enable_cloud_functions ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../cloud_functions/cf_qualityaudit_staging_to_bronze"
  output_path = "${path.module}/cf_qualityaudit_staging_to_bronze.zip"
}

data "archive_file" "cf_programops_source" {
  count       = var.enable_cloud_functions ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../cloud_functions/cf_programops_staging_to_bronze"
  output_path = "${path.module}/cf_programops_staging_to_bronze.zip"
}

# Cloud Storage buckets for function source code
resource "google_storage_bucket" "function_source" {
  count    = var.enable_cloud_functions ? 1 : 0
  name     = "${var.project_id}-function-source-${var.env}"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
}

# Upload function source code to bucket
resource "google_storage_bucket_object" "cf_contributor_source" {
  count  = var.enable_cloud_functions ? 1 : 0
  name   = "cf_contributor_staging_to_bronze-${data.archive_file.cf_contributor_source[0].output_md5}.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = data.archive_file.cf_contributor_source[0].output_path
}

resource "google_storage_bucket_object" "cf_qualityaudit_source" {
  count  = var.enable_cloud_functions ? 1 : 0
  name   = "cf_qualityaudit_staging_to_bronze-${data.archive_file.cf_qualityaudit_source[0].output_md5}.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = data.archive_file.cf_qualityaudit_source[0].output_path
}

resource "google_storage_bucket_object" "cf_programops_source" {
  count  = var.enable_cloud_functions ? 1 : 0
  name   = "cf_programops_staging_to_bronze-${data.archive_file.cf_programops_source[0].output_md5}.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = data.archive_file.cf_programops_source[0].output_path
}

# Cloud Functions
resource "google_cloudfunctions_function" "cf_contributor_staging_to_bronze" {
  count = var.enable_cloud_functions ? 1 : 0
  
  name        = "cf-contributor-staging-to-bronze"
  project     = var.project_id
  region      = var.region
  description = "Processes contributor staging files and loads them into BigQuery bronze dataset"

  runtime     = "python39"
  entry_point = "main"

  source_archive_bucket = google_storage_bucket.function_source[0].name
  source_archive_object = google_storage_bucket_object.cf_contributor_source[0].name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.staging_contributor.name
  }

  environment_variables = {
    PROJECT_ID      = var.project_id
    DATASET_ID      = google_bigquery_dataset.contributor_bronze.dataset_id
    TABLE_MAPPING   = jsonencode({
      "contributors"   = "contributors"
      "tasks"         = "tasks"
      "task_feedback" = "task_feedback"
    })
  }

  service_account_email = google_service_account.cf_contributor.email

  labels = {
    environment = var.env
    team        = "data-platform"
    function    = "staging-to-bronze"
  }

  depends_on = [
    google_bigquery_dataset.contributor_bronze,
    google_storage_bucket.staging_contributor
  ]
}

resource "google_cloudfunctions_function" "cf_qualityaudit_staging_to_bronze" {
  count = var.enable_cloud_functions ? 1 : 0
  
  name        = "cf-qualityaudit-staging-to-bronze"
  project     = var.project_id
  region      = var.region
  description = "Processes quality audit staging files and loads them into BigQuery bronze dataset"

  runtime     = "python39"
  entry_point = "main"

  source_archive_bucket = google_storage_bucket.function_source[0].name
  source_archive_object = google_storage_bucket_object.cf_qualityaudit_source[0].name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.staging_qualityaudit.name
  }

  environment_variables = {
    PROJECT_ID    = var.project_id
    DATASET_ID    = google_bigquery_dataset.qualityaudit_bronze.dataset_id
    TABLE_MAPPING = jsonencode({
      "audits"       = "audits"
      "audit_issues" = "audit_issues"
    })
  }

  service_account_email = google_service_account.cf_qualityaudit.email

  labels = {
    environment = var.env
    team        = "data-platform"
    function    = "staging-to-bronze"
  }

  depends_on = [
    google_bigquery_dataset.qualityaudit_bronze,
    google_storage_bucket.staging_qualityaudit
  ]
}

resource "google_cloudfunctions_function" "cf_programops_staging_to_bronze" {
  count = var.enable_cloud_functions ? 1 : 0
  
  name        = "cf-programops-staging-to-bronze"
  project     = var.project_id
  region      = var.region
  description = "Processes program ops staging files and loads them into BigQuery bronze dataset"

  runtime     = "python39"
  entry_point = "main"

  source_archive_bucket = google_storage_bucket.function_source[0].name
  source_archive_object = google_storage_bucket_object.cf_programops_source[0].name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.staging_programops.name
  }

  environment_variables = {
    PROJECT_ID    = var.project_id
    DATASET_ID    = google_bigquery_dataset.programops_bronze.dataset_id
    TABLE_MAPPING = jsonencode({
      "program_metadata"  = "program_metadata"
      "acknowledgements" = "acknowledgements"
    })
  }

  service_account_email = google_service_account.cf_programops.email

  labels = {
    environment = var.env
    team        = "data-platform"
    function    = "staging-to-bronze"
  }

  depends_on = [
    google_bigquery_dataset.programops_bronze,
    google_storage_bucket.staging_programops
  ]
}
