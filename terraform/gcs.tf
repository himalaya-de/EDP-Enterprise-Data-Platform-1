# GCS Staging Buckets
resource "google_storage_bucket" "staging_contributor" {
  name     = "${var.project_id}-staging-contributor-${var.env}"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = false
  }
}

resource "google_storage_bucket" "staging_qualityaudit" {
  name     = "${var.project_id}-staging-qualityaudit-${var.env}"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = false
  }
}

resource "google_storage_bucket" "staging_programops" {
  name     = "${var.project_id}-staging-programops-${var.env}"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = false
  }
}

# IAM bindings for staging buckets

# Admin group gets storage admin on all staging buckets
resource "google_storage_bucket_iam_member" "staging_contributor_admin" {
  bucket = google_storage_bucket.staging_contributor.name
  role   = "roles/storage.admin"
  member = "group:${var.group_admins}"
}

resource "google_storage_bucket_iam_member" "staging_qualityaudit_admin" {
  bucket = google_storage_bucket.staging_qualityaudit.name
  role   = "roles/storage.admin"
  member = "group:${var.group_admins}"
}

resource "google_storage_bucket_iam_member" "staging_programops_admin" {
  bucket = google_storage_bucket.staging_programops.name
  role   = "roles/storage.admin"
  member = "group:${var.group_admins}"
}

# Datastream SAs get object create permissions on their respective buckets
resource "google_storage_bucket_iam_member" "datastream_contributor_write" {
  bucket = google_storage_bucket.staging_contributor.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.datastream_contributor.email}"
}

resource "google_storage_bucket_iam_member" "datastream_qualityaudit_write" {
  bucket = google_storage_bucket.staging_qualityaudit.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.datastream_qualityaudit.email}"
}

resource "google_storage_bucket_iam_member" "datastream_programops_write" {
  bucket = google_storage_bucket.staging_programops.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.datastream_programops.email}"
}

# Cloud Function SAs get object reader permissions on their respective buckets
resource "google_storage_bucket_iam_member" "cf_contributor_read" {
  bucket = google_storage_bucket.staging_contributor.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cf_contributor.email}"
}

resource "google_storage_bucket_iam_member" "cf_qualityaudit_read" {
  bucket = google_storage_bucket.staging_qualityaudit.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cf_qualityaudit.email}"
}

resource "google_storage_bucket_iam_member" "cf_programops_read" {
  bucket = google_storage_bucket.staging_programops.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cf_programops.email}"
}
