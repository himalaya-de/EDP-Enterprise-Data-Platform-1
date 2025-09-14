# Output values for reference

# Service Account Emails
output "service_account_emails" {
  description = "Email addresses of all created service accounts"
  value = {
    datastream_contributor  = google_service_account.datastream_contributor.email
    datastream_qualityaudit = google_service_account.datastream_qualityaudit.email
    datastream_programops   = google_service_account.datastream_programops.email
    cf_contributor          = google_service_account.cf_contributor.email
    cf_qualityaudit         = google_service_account.cf_qualityaudit.email
    cf_programops           = google_service_account.cf_programops.email
    bronze_to_silver        = google_service_account.bronze_to_silver.email
    silver_to_gold          = google_service_account.silver_to_gold.email
    applemap_mart           = google_service_account.applemap_mart.email
    googleads_mart          = google_service_account.googleads_mart.email
    metaads_mart            = google_service_account.metaads_mart.email
    googlesearch_mart       = google_service_account.googlesearch_mart.email
    bq_admin_ops            = google_service_account.bq_admin_ops.email
    monitoring              = google_service_account.monitoring.email
  }
}

# BigQuery Dataset Names
output "bigquery_datasets" {
  description = "Names of all created BigQuery datasets"
  value = {
    contributor_bronze    = google_bigquery_dataset.contributor_bronze.dataset_id
    contributor_silver    = google_bigquery_dataset.contributor_silver.dataset_id
    qualityaudit_bronze   = google_bigquery_dataset.qualityaudit_bronze.dataset_id
    qualityaudit_silver   = google_bigquery_dataset.qualityaudit_silver.dataset_id
    programops_bronze     = google_bigquery_dataset.programops_bronze.dataset_id
    programops_silver     = google_bigquery_dataset.programops_silver.dataset_id
    enterprise_gold       = google_bigquery_dataset.enterprise_gold.dataset_id
    applemap_mart         = google_bigquery_dataset.applemap_mart.dataset_id
    googleads_mart        = google_bigquery_dataset.googleads_mart.dataset_id
    metaads_mart          = google_bigquery_dataset.metaads_mart.dataset_id
    googlesearch_mart     = google_bigquery_dataset.googlesearch_mart.dataset_id
  }
}

# GCS Bucket Names
output "gcs_buckets" {
  description = "Names of all created GCS buckets"
  value = {
    staging_contributor  = google_storage_bucket.staging_contributor.name
    staging_qualityaudit = google_storage_bucket.staging_qualityaudit.name
    staging_programops   = google_storage_bucket.staging_programops.name
    function_source      = var.enable_cloud_functions ? google_storage_bucket.function_source[0].name : null
  }
}

# Cloud Function Names
output "cloud_functions" {
  description = "Names of all created Cloud Functions"
  value = var.enable_cloud_functions ? {
    cf_contributor_staging_to_bronze  = google_cloudfunctions_function.cf_contributor_staging_to_bronze[0].name
    cf_qualityaudit_staging_to_bronze = google_cloudfunctions_function.cf_qualityaudit_staging_to_bronze[0].name
    cf_programops_staging_to_bronze   = google_cloudfunctions_function.cf_programops_staging_to_bronze[0].name
  } : {}
}

# Datastream Resources
output "datastream_resources" {
  description = "Names of Datastream connection profiles and streams"
  value = var.enable_datastream ? {
    connection_profiles = {
      cp_contributor_mysql     = google_datastream_connection_profile.cp_contributor_mysql[0].connection_profile_id
      cp_qualityaudit_postgres = google_datastream_connection_profile.cp_qualityaudit_postgres[0].connection_profile_id
      cp_programops_mongo      = "manual-implementation-required"
      bq_destination          = google_datastream_connection_profile.bq_destination[0].connection_profile_id
    }
    streams = {
      stream_contributor   = google_datastream_stream.stream_contributor[0].stream_id
      stream_qualityaudit  = google_datastream_stream.stream_qualityaudit[0].stream_id
      stream_programops    = "manual-implementation-required"
    }
  } : {}
}

# Project Information
output "project_info" {
  description = "Project and region information"
  value = {
    project_id = var.project_id
    region     = var.region
    environment = var.env
  }
}

# IAM Groups
output "iam_groups" {
  description = "IAM group email addresses"
  value = {
    admins     = var.group_admins
    developers = var.group_developers
    analysts   = var.group_analysts
  }
}

# Secret Manager References
output "secret_manager_secrets" {
  description = "Secret Manager secret names for database connections"
  value = {
    contributor_db_secret  = var.secret_contributor_db
    qualityaudit_db_secret = var.secret_qualityaudit_db
    programops_db_secret   = var.secret_programops_db
  }
}
