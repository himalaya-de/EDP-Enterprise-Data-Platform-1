# =============================================================================
# DATASTREAM CONFIGURATION - DATA LINEAGE DOCUMENTATION
# =============================================================================
# 
# DATA FLOW LINEAGE:
# 1. Source Systems → Datastream → BigQuery Bronze Tables → Silver Tables → Gold Tables → Data Marts
# 
# SOURCE SYSTEMS:
# - MySQL (contributor_db) → contributor_bronze.{contributors, tasks, task_feedback}
# - PostgreSQL (qualityaudit_db) → qualityaudit_bronze.{audits, audit_issues}  
# - MongoDB (programops_db) → programops_bronze.{program_metadata, acknowledgements}
#
# DESTINATION MAPPING:
# - contributor_bronze → contributor_silver → enterprise_gold.dim_contributor
# - qualityaudit_bronze → qualityaudit_silver → enterprise_gold.fact_audit
# - programops_bronze → programops_silver → enterprise_gold.dim_program
#
# DATA MART CONSUMPTION:
# - enterprise_gold → applemap_mart, googleads_mart, metaads_mart, googlesearch_mart
#
# Note: This requires manual setup of database source systems and network connectivity

# Connection Profiles (placeholders with secret references)
# =============================================================================
# MYSQL SOURCE: Contributor Database
# =============================================================================
# LINEAGE: contributor_db.{contributors,tasks,task_feedback} → contributor_bronze.{contributors,tasks,task_feedback}
# DOWNSTREAM: contributor_bronze → contributor_silver → enterprise_gold.dim_contributor → data_marts
resource "google_datastream_connection_profile" "cp_contributor_mysql" {
  count = var.enable_datastream ? 1 : 0
  
  location              = var.region
  connection_profile_id = "cp-contributor-mysql"
  display_name          = "Contributor MySQL Connection Profile - Source for contributor_bronze dataset"
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
    environment       = var.env
    team             = "data-platform"
    source_system    = "mysql-contributor-db"
    destination      = "contributor-bronze"
    data_domain      = "contributor-management"
    lineage_tier     = "source-to-bronze"
    contains_pii     = "true"
    data_classification = "restricted"
  }
}

# =============================================================================
# POSTGRESQL SOURCE: Quality Audit Database
# =============================================================================
# LINEAGE: qualityaudit_db.{audits,audit_issues} → qualityaudit_bronze.{audits,audit_issues}
# DOWNSTREAM: qualityaudit_bronze → qualityaudit_silver → enterprise_gold.fact_audit → data_marts
resource "google_datastream_connection_profile" "cp_qualityaudit_postgres" {
  count = var.enable_datastream ? 1 : 0
  
  location              = var.region
  connection_profile_id = "cp-qualityaudit-postgres"
  display_name          = "Quality Audit PostgreSQL Connection Profile - Source for qualityaudit_bronze dataset"
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
    environment       = var.env
    team             = "data-platform"
    source_system    = "postgresql-qualityaudit-db"
    destination      = "qualityaudit-bronze"
    data_domain      = "quality-assurance"
    lineage_tier     = "source-to-bronze"
    contains_pii     = "false"
    data_classification = "internal"
  }
}

# Note: MongoDB connection profile is not directly supported by Datastream
# This is a placeholder showing the intended configuration
# You may need to use MongoDB Atlas integration or custom CDC solution
# Disabled for demo - MongoDB CDC would be implemented via custom solution
# resource "google_datastream_connection_profile" "cp_programops_mongo" {
#   count = var.enable_datastream ? 1 : 0
#   
#   location              = var.region
#   connection_profile_id = "cp-programops-mongo"
#   display_name          = "Program Ops MongoDB Connection Profile"
#   project               = var.project_id
#
#   # MongoDB is not natively supported by Datastream
#   # This would need to be implemented via:
#   # 1. MongoDB Atlas integration
#   # 2. Custom CDC solution using Change Streams
#   # 3. Third-party connector
#   
#   # Placeholder for demonstration - replace with actual implementation
#   labels = {
#     environment = var.env
#     team        = "data-platform"
#     note        = "mongodb-requires-custom-implementation"
#   }
# }

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

# =============================================================================
# DATASTREAM FLOWS - DETAILED LINEAGE MAPPING
# =============================================================================

# =============================================================================
# STREAM 1: MySQL Contributor Database → BigQuery Bronze
# =============================================================================
# SOURCE: contributor_db.{contributors, tasks, task_feedback} (MySQL)
# DESTINATION: hackathon2025-01.contributor_bronze.{contributors, tasks, task_feedback} (BigQuery)
# LINEAGE_PATH: mysql://contributor_db → datastream → bigquery://contributor_bronze
# DOWNSTREAM_FLOW: contributor_bronze → contributor_silver → enterprise_gold → data_marts
# DATA_DOMAINS: contributor-management, task-tracking, feedback-analysis
resource "google_datastream_stream" "stream_contributor" {
  count = var.enable_datastream ? 1 : 0
  
  location   = var.region
  stream_id  = "stream-contributor"
  project    = var.project_id
  
  display_name = "Contributor MySQL → Bronze Layer Stream (contributor_db → contributor_bronze)"
  
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
      single_target_dataset {
        dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
      }
    }
  }

  backfill_all {}

  labels = {
    environment          = var.env
    team                = "data-platform"
    source_system       = "mysql-contributor-db"
    source_database     = "contributor_db"
    destination_dataset = "contributor-bronze"
    lineage_tier        = "source-to-bronze"
    data_domain         = "contributor-management"
    contains_tables     = "contributors-tasks-task_feedback"
    downstream_silver   = "contributor-silver"
    downstream_gold     = "enterprise-gold"
    final_consumption   = "data-marts"
    data_classification = "restricted"
    contains_pii        = "true"
  }

  depends_on = [
    google_bigquery_dataset.contributor_bronze
  ]
}

# =============================================================================
# STREAM 2: PostgreSQL Quality Audit Database → BigQuery Bronze
# =============================================================================
# SOURCE: qualityaudit_db.{audits, audit_issues} (PostgreSQL)
# DESTINATION: hackathon2025-01.qualityaudit_bronze.{audits, audit_issues} (BigQuery)
# LINEAGE_PATH: postgresql://qualityaudit_db → datastream → bigquery://qualityaudit_bronze
# DOWNSTREAM_FLOW: qualityaudit_bronze → qualityaudit_silver → enterprise_gold → data_marts
# DATA_DOMAINS: quality-assurance, audit-tracking, issue-management
resource "google_datastream_stream" "stream_qualityaudit" {
  count = var.enable_datastream ? 1 : 0
  
  location   = var.region
  stream_id  = "stream-qualityaudit"
  project    = var.project_id
  
  display_name = "Quality Audit PostgreSQL → Bronze Layer Stream (qualityaudit_db → qualityaudit_bronze)"
  
  source_config {
    source_connection_profile = google_datastream_connection_profile.cp_qualityaudit_postgres[0].id
    
    postgresql_source_config {
      replication_slot = "datastream_slot"
      publication      = "datastream_publication"
      
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
      single_target_dataset {
        dataset_id = google_bigquery_dataset.qualityaudit_bronze.dataset_id
      }
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
