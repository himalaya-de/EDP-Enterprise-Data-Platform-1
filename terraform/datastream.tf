# Datastream Connection Profiles and Streams
# Note: This requires manual setup of database source systems and network connectivity

# Connection Profiles (placeholders with secret references)
resource "google_datastream_connection_profile" "cp_contributor_mysql" {
  count = var.enable_datastream ? 1 : 0
  
  location              = var.region
  connection_profile_id = "cp-contributor-mysql"
  display_name          = "Contributor MySQL Connection Profile"
  project               = var.project_id

  mysql_profile {
    hostname = "REPLACE_WITH_MYSQL_HOST"  # e.g., "10.0.0.5"
    port     = 3306
    username = "datastream_user"
    
    # Reference to Secret Manager secret containing password
    password = data.google_secret_manager_secret_version.contributor_db_secret[0].secret_data
  }

  # Private connectivity configuration (adjust based on your network setup)
  private_connectivity {
    private_connection = "REPLACE_WITH_PRIVATE_CONNECTION_ID"  # e.g., google_datastream_private_connection.main.id
  }

  labels = {
    environment = var.env
    team        = "data-platform"
  }
}

resource "google_datastream_connection_profile" "cp_qualityaudit_postgres" {
  count = var.enable_datastream ? 1 : 0
  
  location              = var.region
  connection_profile_id = "cp-qualityaudit-postgres"
  display_name          = "Quality Audit Postgres Connection Profile"
  project               = var.project_id

  postgresql_profile {
    hostname = "REPLACE_WITH_POSTGRES_HOST"  # e.g., "10.0.0.6"
    port     = 5432
    username = "datastream_user"
    database = "qualityaudit_db"
    
    # Reference to Secret Manager secret containing password
    password = data.google_secret_manager_secret_version.qualityaudit_db_secret[0].secret_data
  }

  # Private connectivity configuration
  private_connectivity {
    private_connection = "REPLACE_WITH_PRIVATE_CONNECTION_ID"
  }

  labels = {
    environment = var.env
    team        = "data-platform"
  }
}

# Note: MongoDB connection profile is not directly supported by Datastream
# This is a placeholder showing the intended configuration
# You may need to use MongoDB Atlas integration or custom CDC solution
resource "google_datastream_connection_profile" "cp_programops_mongo" {
  count = var.enable_datastream ? 1 : 0
  
  location              = var.region
  connection_profile_id = "cp-programops-mongo"
  display_name          = "Program Ops MongoDB Connection Profile"
  project               = var.project_id

  # MongoDB is not natively supported by Datastream
  # This would need to be implemented via:
  # 1. MongoDB Atlas integration
  # 2. Custom CDC solution using Change Streams
  # 3. Third-party connector
  
  # Placeholder for demonstration - replace with actual implementation
  # For now, using a generic profile that would need custom implementation
  labels = {
    environment = var.env
    team        = "data-platform"
    note        = "mongodb-requires-custom-implementation"
  }
}

# BigQuery Destination Connection Profile
resource "google_datastream_connection_profile" "bq_destination" {
  count = var.enable_datastream ? 1 : 0
  
  location              = var.region
  connection_profile_id = "bq-destination"
  display_name          = "BigQuery Destination"
  project               = var.project_id

  bigquery_profile {}

  labels = {
    environment = var.env
    team        = "data-platform"
  }
}

# Datastreams
resource "google_datastream_stream" "stream_contributor" {
  count = var.enable_datastream ? 1 : 0
  
  location   = var.region
  stream_id  = "stream-contributor"
  project    = var.project_id
  
  display_name = "Contributor MySQL to BigQuery Stream"
  
  source_config {
    source_connection_profile = google_datastream_connection_profile.cp_contributor_mysql[0].id
    
    mysql_source_config {
      # Include specific tables
      include_objects {
        mysql_databases {
          database = "contributor_db"
          mysql_tables {
            table = "contributors"
          }
          mysql_tables {
            table = "tasks"
          }
          mysql_tables {
            table = "task_feedback"
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bq_destination[0].id
    
    bigquery_destination_config {
      data_freshness = "900s"  # 15 minutes
      
      # Write to bronze dataset
      dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
    }
  }

  backfill_all {}

  labels = {
    environment = var.env
    team        = "data-platform"
    source      = "mysql"
  }

  depends_on = [
    google_bigquery_dataset.contributor_bronze
  ]
}

resource "google_datastream_stream" "stream_qualityaudit" {
  count = var.enable_datastream ? 1 : 0
  
  location   = var.region
  stream_id  = "stream-qualityaudit"
  project    = var.project_id
  
  display_name = "Quality Audit Postgres to BigQuery Stream"
  
  source_config {
    source_connection_profile = google_datastream_connection_profile.cp_qualityaudit_postgres[0].id
    
    postgresql_source_config {
      # Include specific schemas and tables
      include_objects {
        postgresql_schemas {
          schema = "public"
          postgresql_tables {
            table = "audits"
          }
          postgresql_tables {
            table = "audit_issues"
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bq_destination[0].id
    
    bigquery_destination_config {
      data_freshness = "900s"  # 15 minutes
      
      # Write to bronze dataset
      dataset_id = google_bigquery_dataset.qualityaudit_bronze.dataset_id
    }
  }

  backfill_all {}

  labels = {
    environment = var.env
    team        = "data-platform"
    source      = "postgresql"
  }

  depends_on = [
    google_bigquery_dataset.qualityaudit_bronze
  ]
}

# MongoDB stream placeholder - requires custom implementation
# This would typically be implemented using:
# 1. MongoDB Change Streams + Cloud Function
# 2. Third-party CDC tool
# 3. Debezium connector
resource "null_resource" "stream_programops_placeholder" {
  count = var.enable_datastream ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'MongoDB CDC stream requires custom implementation - see datastream/placeholders.txt for details'"
  }

  triggers = {
    environment = var.env
    note        = "mongodb-stream-placeholder"
  }
}

# Data sources for Secret Manager secrets
data "google_secret_manager_secret_version" "contributor_db_secret" {
  count   = var.enable_datastream ? 1 : 0
  secret  = var.secret_contributor_db
  project = var.project_id
}

data "google_secret_manager_secret_version" "qualityaudit_db_secret" {
  count   = var.enable_datastream ? 1 : 0
  secret  = var.secret_qualityaudit_db
  project = var.project_id
}

data "google_secret_manager_secret_version" "programops_db_secret" {
  count   = var.enable_datastream ? 1 : 0
  secret  = var.secret_programops_db
  project = var.project_id
}
