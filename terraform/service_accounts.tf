# Datastream Service Accounts
resource "google_service_account" "datastream_contributor" {
  account_id   = "sa-datastream-contributor"
  display_name = "Datastream Contributor SA"
  description  = "Service account for Datastream contributor MySQL CDC"
  project      = var.project_id
}

resource "google_service_account" "datastream_qualityaudit" {
  account_id   = "sa-datastream-qualityaudit"
  display_name = "Datastream Quality Audit SA"
  description  = "Service account for Datastream quality audit Postgres CDC"
  project      = var.project_id
}

resource "google_service_account" "datastream_programops" {
  account_id   = "sa-datastream-programops"
  display_name = "Datastream Program Ops SA"
  description  = "Service account for Datastream program ops MongoDB CDC"
  project      = var.project_id
}

# Cloud Function Service Accounts
resource "google_service_account" "cf_contributor" {
  account_id   = "sa-cf-contributor"
  display_name = "Cloud Function Contributor SA"
  description  = "Service account for contributor staging to bronze Cloud Function"
  project      = var.project_id
}

resource "google_service_account" "cf_qualityaudit" {
  account_id   = "sa-cf-qualityaudit"
  display_name = "Cloud Function Quality Audit SA"
  description  = "Service account for quality audit staging to bronze Cloud Function"
  project      = var.project_id
}

resource "google_service_account" "cf_programops" {
  account_id   = "sa-cf-programops"
  display_name = "Cloud Function Program Ops SA"
  description  = "Service account for program ops staging to bronze Cloud Function"
  project      = var.project_id
}

# Data Pipeline Service Accounts
resource "google_service_account" "bronze_to_silver" {
  account_id   = "sa-bronze-to-silver"
  display_name = "Bronze to Silver Transform SA"
  description  = "Service account for bronze to silver data transformations"
  project      = var.project_id
}

resource "google_service_account" "silver_to_gold" {
  account_id   = "sa-silver-to-gold"
  display_name = "Silver to Gold Transform SA"
  description  = "Service account for silver to gold data transformations"
  project      = var.project_id
}

# Data Mart Service Accounts
resource "google_service_account" "applemap_mart" {
  account_id   = "sa-applemap-mart"
  display_name = "Apple Map Mart SA"
  description  = "Service account for Apple Map mart access"
  project      = var.project_id
}

resource "google_service_account" "googleads_mart" {
  account_id   = "sa-googleads-mart"
  display_name = "Google Ads Mart SA"
  description  = "Service account for Google Ads mart access"
  project      = var.project_id
}

resource "google_service_account" "metaads_mart" {
  account_id   = "sa-metaads-mart"
  display_name = "Meta Ads Mart SA"
  description  = "Service account for Meta Ads mart access"
  project      = var.project_id
}

resource "google_service_account" "googlesearch_mart" {
  account_id   = "sa-googlesearch-mart"
  display_name = "Google Search Mart SA"
  description  = "Service account for Google Search mart access"
  project      = var.project_id
}

# Optional Administrative Service Accounts
resource "google_service_account" "bq_admin_ops" {
  account_id   = "sa-bq-admin-ops"
  display_name = "BigQuery Admin Ops SA"
  description  = "Service account for BigQuery administrative operations"
  project      = var.project_id
}

resource "google_service_account" "monitoring" {
  account_id   = "sa-monitoring"
  display_name = "Monitoring SA"
  description  = "Service account for monitoring and alerting"
  project      = var.project_id
}

# Add labels to all service accounts
locals {
  service_accounts = {
    "sa-datastream-contributor"  = { sa = google_service_account.datastream_contributor, owner = "de platform" }
    "sa-datastream-qualityaudit" = { sa = google_service_account.datastream_qualityaudit, owner = "de platform" }
    "sa-datastream-programops"   = { sa = google_service_account.datastream_programops, owner = "de platform" }
    "sa-cf-contributor"          = { sa = google_service_account.cf_contributor, owner = "de platform" }
    "sa-cf-qualityaudit"         = { sa = google_service_account.cf_qualityaudit, owner = "de platform" }
    "sa-cf-programops"           = { sa = google_service_account.cf_programops, owner = "de platform" }
    "sa-bronze-to-silver"        = { sa = google_service_account.bronze_to_silver, owner = "de platform" }
    "sa-silver-to-gold"          = { sa = google_service_account.silver_to_gold, owner = "de platform" }
    "sa-applemap-mart"           = { sa = google_service_account.applemap_mart, owner = "applemaps" }
    "sa-googleads-mart"          = { sa = google_service_account.googleads_mart, owner = "googleads" }
    "sa-metaads-mart"            = { sa = google_service_account.metaads_mart, owner = "metaads" }
    "sa-googlesearch-mart"       = { sa = google_service_account.googlesearch_mart, owner = "googlesearch" }
    "sa-bq-admin-ops"            = { sa = google_service_account.bq_admin_ops, owner = var.owner_team_name }
    "sa-monitoring"              = { sa = google_service_account.monitoring, owner = var.owner_team_name }
  }
}

# Apply labels to service accounts using google_project_iam_member doesn't support labels
# Using null_resource to apply labels via gcloud CLI
resource "null_resource" "sa_labels" {
  for_each = local.service_accounts
  
  provisioner "local-exec" {
    command = <<-EOT
      gcloud iam service-accounts update ${each.value.sa.email} \
        --update-labels="Owner=${replace(each.value.owner, " ", "")}" \
        --project=${var.project_id}
    EOT
  }
  
  depends_on = [
    google_service_account.datastream_contributor,
    google_service_account.datastream_qualityaudit,
    google_service_account.datastream_programops,
    google_service_account.cf_contributor,
    google_service_account.cf_qualityaudit,
    google_service_account.cf_programops,
    google_service_account.bronze_to_silver,
    google_service_account.silver_to_gold,
    google_service_account.applemap_mart,
    google_service_account.googleads_mart,
    google_service_account.metaads_mart,
    google_service_account.googlesearch_mart,
    google_service_account.bq_admin_ops,
    google_service_account.monitoring
  ]
}
