# BigQuery Datasets

# Bronze Datasets
resource "google_bigquery_dataset" "contributor_bronze" {
  dataset_id  = "contributor_bronze"
  location    = var.region
  project     = var.project_id
  description = "Bronze layer for contributor data from MySQL"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "qualityaudit_bronze" {
  dataset_id  = "qualityaudit_bronze"
  location    = var.region
  project     = var.project_id
  description = "Bronze layer for quality audit data from Postgres"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "programops_bronze" {
  dataset_id  = "programops_bronze"
  location    = var.region
  project     = var.project_id
  description = "Bronze layer for program ops data from MongoDB"

  delete_contents_on_destroy = false
}

# Silver Datasets
resource "google_bigquery_dataset" "contributor_silver" {
  dataset_id  = "contributor_silver"
  location    = var.region
  project     = var.project_id
  description = "Silver layer for cleaned and validated contributor data"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "qualityaudit_silver" {
  dataset_id  = "qualityaudit_silver"
  location    = var.region
  project     = var.project_id
  description = "Silver layer for cleaned and validated quality audit data"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "programops_silver" {
  dataset_id  = "programops_silver"
  location    = var.region
  project     = var.project_id
  description = "Silver layer for cleaned and validated program ops data"

  delete_contents_on_destroy = false
}

# Gold Dataset
resource "google_bigquery_dataset" "enterprise_gold" {
  dataset_id  = "enterprise_gold"
  location    = var.region
  project     = var.project_id
  description = "Gold layer with enterprise-wide dimensional model and facts"

  delete_contents_on_destroy = false
}

# Data Mart Datasets
resource "google_bigquery_dataset" "applemap_mart" {
  dataset_id  = "applemap_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Apple Maps team analytics"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "googleads_mart" {
  dataset_id  = "googleads_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Google Ads team analytics"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "metaads_mart" {
  dataset_id  = "metaads_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Meta Ads team analytics"

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "googlesearch_mart" {
  dataset_id  = "googlesearch_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Google Search team analytics"

  delete_contents_on_destroy = false
}

# Placeholder Tables for Bronze Datasets

# Contributor tables
resource "google_bigquery_table" "contributors_bronze" {
  dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
  table_id   = "contributors"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "contributor_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "name"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "email"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}

resource "google_bigquery_table" "tasks_bronze" {
  dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
  table_id   = "tasks"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "task_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "contributor_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "task_type"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "status"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "completed_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}

resource "google_bigquery_table" "task_feedback_bronze" {
  dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
  table_id   = "task_feedback"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "feedback_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "task_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "rating"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "comment"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}

# Quality Audit tables
resource "google_bigquery_table" "audits_bronze" {
  dataset_id = google_bigquery_dataset.qualityaudit_bronze.dataset_id
  table_id   = "audits"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "audit_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "auditor_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "audit_type"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "status"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "completed_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}

resource "google_bigquery_table" "audit_issues_bronze" {
  dataset_id = google_bigquery_dataset.qualityaudit_bronze.dataset_id
  table_id   = "audit_issues"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "issue_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "audit_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "severity"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "description"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}

# Program Ops tables
resource "google_bigquery_table" "program_metadata_bronze" {
  dataset_id = google_bigquery_dataset.programops_bronze.dataset_id
  table_id   = "program_metadata"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "program_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "program_name"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "program_type"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "status"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}

resource "google_bigquery_table" "acknowledgements_bronze" {
  dataset_id = google_bigquery_dataset.programops_bronze.dataset_id
  table_id   = "acknowledgements"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "ack_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "program_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "contributor_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "ack_type"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "_datastream_metadata"
      type = "RECORD"
      mode = "NULLABLE"
      fields = [
        {
          name = "source_timestamp"
          type = "TIMESTAMP"
          mode = "NULLABLE"
        },
        {
          name = "log_file"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    }
  ])
}
