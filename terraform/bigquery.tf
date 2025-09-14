# BigQuery Datasets

# Bronze Datasets
resource "google_bigquery_dataset" "contributor_bronze" {
  dataset_id  = "contributor_bronze"
  location    = var.region
  project     = var.project_id
  description = "Bronze layer for contributor data from MySQL"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "qualityaudit_bronze" {
  dataset_id  = "qualityaudit_bronze"
  location    = var.region
  project     = var.project_id
  description = "Bronze layer for quality audit data from Postgres"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "programops_bronze" {
  dataset_id  = "programops_bronze"
  location    = var.region
  project     = var.project_id
  description = "Bronze layer for program ops data from MongoDB"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

# Silver Datasets
resource "google_bigquery_dataset" "contributor_silver" {
  dataset_id  = "contributor_silver"
  location    = var.region
  project     = var.project_id
  description = "Silver layer for cleaned and validated contributor data"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "silver"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "qualityaudit_silver" {
  dataset_id  = "qualityaudit_silver"
  location    = var.region
  project     = var.project_id
  description = "Silver layer for cleaned and validated quality audit data"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "silver"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "programops_silver" {
  dataset_id  = "programops_silver"
  location    = var.region
  project     = var.project_id
  description = "Silver layer for cleaned and validated program ops data"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "silver"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

# Gold Dataset
resource "google_bigquery_dataset" "enterprise_gold" {
  dataset_id  = "enterprise_gold"
  location    = var.region
  project     = var.project_id
  description = "Gold layer with enterprise-wide dimensional model and facts"

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "gold"
    team        = "data-platform"
  }

  delete_contents_on_destroy = false
}

# Data Mart Datasets
resource "google_bigquery_dataset" "applemap_mart" {
  dataset_id  = "applemap_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Apple Maps team analytics"

  labels = {
    owner       = "apple-maps"
    environment = var.env
    layer       = "mart"
    team        = "applemap"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "googleads_mart" {
  dataset_id  = "googleads_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Google Ads team analytics"

  labels = {
    owner       = "google-ads"
    environment = var.env
    layer       = "mart"
    team        = "googleads"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "metaads_mart" {
  dataset_id  = "metaads_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Meta Ads team analytics"

  labels = {
    owner       = "meta-ads"
    environment = var.env
    layer       = "mart"
    team        = "metaads"
  }

  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "googlesearch_mart" {
  dataset_id  = "googlesearch_mart"
  location    = var.region
  project     = var.project_id
  description = "Data mart for Google Search team analytics"

  labels = {
    owner       = "google-search"
    environment = var.env
    layer       = "mart"
    team        = "googlesearch"
  }

  delete_contents_on_destroy = false
}

# Placeholder Tables for Bronze Datasets

# Contributor tables
resource "google_bigquery_table" "contributors_bronze" {
  dataset_id = google_bigquery_dataset.contributor_bronze.dataset_id
  table_id   = "contributors"
  project    = var.project_id

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "fact"
  }

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

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "fact"
  }

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

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "fact"
  }

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

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "fact"
  }

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

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "fact"
  }

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

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "dimension"
  }

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

  labels = {
    owner       = "de-platform"
    environment = var.env
    layer       = "bronze"
    team        = "data-platform"
    table_type  = "fact"
  }

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


# ==============================================================================
# DATA MART VIEWS - LINEAGE DOCUMENTATION
# ==============================================================================
#
# LINEAGE FLOW:
# Source Systems → Bronze → Silver → Gold → Data Marts (THESE VIEWS)
#
# VIEW LINEAGE MAPPING:
# 1. applemap_mart views ← enterprise_gold ← contributor_silver ← contributor_bronze ← MySQL
# 2. googleads_mart views ← enterprise_gold ← contributor_silver ← contributor_bronze ← MySQL  
# 3. metaads_mart views ← enterprise_gold ← contributor_silver ← contributor_bronze ← MySQL
# 4. googlesearch_mart views ← enterprise_gold ← contributor_silver ← contributor_bronze ← MySQL
#
# DATA CONSUMPTION:
# - BI Tools: Connect to these views for reporting
# - Analytics: Query these views for insights
# - APIs: Expose these views via data APIs
# - ML Pipelines: Use these views as feature sources
#
# ==============================================================================

# =============================================================================
# APPLE MAPS MART VIEWS
# =============================================================================
# LINEAGE: MySQL contributor_db → contributor_bronze → contributor_silver → enterprise_gold → applemap_mart
# CONSUMERS: Apple Maps team analytics, performance dashboards, reporting tools

# VIEW: Apple Maps Performance Summary
# LINEAGE_PATH: contributor_bronze.{tasks, task_feedback} → applemap_mart.performance_summary
# PURPOSE: Daily performance metrics for Apple Maps tasks
# CONSUMERS: Apple Maps performance dashboards, daily reports
resource "google_bigquery_table" "applemap_performance_summary" {
  dataset_id = google_bigquery_dataset.applemap_mart.dataset_id
  table_id   = "performance_summary"
  project    = var.project_id

  labels = {
    owner       = "apple-maps"
    environment = var.env
    layer       = "mart"
    team        = "applemap"
    table_type  = "view"
  }

  view {
    query = <<EOF
-- LINEAGE: This view aggregates data from contributor_bronze tables
-- SOURCE_TABLES: contributor_bronze.tasks, contributor_bronze.task_feedback
-- FILTER: task_type = 'apple_maps'
-- AGGREGATION: Daily performance metrics
SELECT 
  DATE(t.created_at) as date,
  COUNT(DISTINCT t.contributor_id) as active_contributors,
  COUNT(t.task_id) as total_tasks,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
  AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END) as avg_rating,
  ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as completion_rate
FROM `${var.project_id}.contributor_bronze.tasks` t
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'apple_maps'
GROUP BY DATE(t.created_at)
ORDER BY date DESC
EOF
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

resource "google_bigquery_table" "applemap_contributor_leaderboard" {
  dataset_id = google_bigquery_dataset.applemap_mart.dataset_id
  table_id   = "contributor_leaderboard"
  project    = var.project_id

  labels = {
    owner       = "apple-maps"
    environment = var.env
    layer       = "mart"
    team        = "applemap"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  c.contributor_id,
  c.name as contributor_name,
  COUNT(t.task_id) as total_tasks,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
  AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END) as avg_rating,
  ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as completion_rate
FROM `${var.project_id}.contributor_bronze.contributors` c
JOIN `${var.project_id}.contributor_bronze.tasks` t 
  ON c.contributor_id = t.contributor_id
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'apple_maps'
GROUP BY c.contributor_id, c.name
HAVING COUNT(t.task_id) >= 5
ORDER BY avg_rating DESC, completed_tasks DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.contributors_bronze,
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

# Google Ads Mart Views
resource "google_bigquery_table" "googleads_campaign_performance" {
  dataset_id = google_bigquery_dataset.googleads_mart.dataset_id
  table_id   = "campaign_performance"
  project    = var.project_id

  labels = {
    owner       = "google-ads"
    environment = var.env
    layer       = "mart"
    team        = "googleads"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  DATE(t.created_at) as campaign_date,
  COUNT(DISTINCT t.contributor_id) as unique_contributors,
  COUNT(t.task_id) as total_ad_tasks,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_ad_tasks,
  AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END) as avg_quality_score,
  ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as campaign_success_rate,
  COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) as high_quality_ads
FROM `${var.project_id}.contributor_bronze.tasks` t
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'google_ads'
GROUP BY DATE(t.created_at)
ORDER BY campaign_date DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

resource "google_bigquery_table" "googleads_quality_metrics" {
  dataset_id = google_bigquery_dataset.googleads_mart.dataset_id
  table_id   = "quality_metrics"
  project    = var.project_id

  labels = {
    owner       = "google-ads"
    environment = var.env
    layer       = "mart"
    team        = "googleads"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  EXTRACT(WEEK FROM t.created_at) as week_number,
  EXTRACT(YEAR FROM t.created_at) as year,
  COUNT(t.task_id) as total_ads_created,
  AVG(tf.rating) as avg_quality_rating,
  STDDEV(tf.rating) as quality_std_dev,
  COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) as premium_quality_ads,
  COUNT(CASE WHEN tf.rating <= 2 THEN 1 END) as low_quality_ads,
  ROUND(AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END), 2) as weekly_quality_trend
FROM `${var.project_id}.contributor_bronze.tasks` t
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'google_ads'
  AND tf.rating IS NOT NULL
GROUP BY EXTRACT(WEEK FROM t.created_at), EXTRACT(YEAR FROM t.created_at)
ORDER BY year DESC, week_number DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

# Meta Ads Mart Views
resource "google_bigquery_table" "metaads_engagement_analytics" {
  dataset_id = google_bigquery_dataset.metaads_mart.dataset_id
  table_id   = "engagement_analytics"
  project    = var.project_id

  labels = {
    owner       = "meta-ads"
    environment = var.env
    layer       = "mart"
    team        = "metaads"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  DATE(t.created_at) as analytics_date,
  COUNT(DISTINCT t.contributor_id) as active_creators,
  COUNT(t.task_id) as total_meta_ads,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as live_ads,
  AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END) as avg_engagement_score,
  COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) as viral_potential_ads,
  ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as launch_success_rate
FROM `${var.project_id}.contributor_bronze.tasks` t
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'meta_ads'
GROUP BY DATE(t.created_at)
ORDER BY analytics_date DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

resource "google_bigquery_table" "metaads_creator_insights" {
  dataset_id = google_bigquery_dataset.metaads_mart.dataset_id
  table_id   = "creator_insights"
  project    = var.project_id

  labels = {
    owner       = "meta-ads"
    environment = var.env
    layer       = "mart"
    team        = "metaads"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  c.contributor_id,
  c.name as creator_name,
  c.email as creator_contact,
  COUNT(t.task_id) as total_campaigns,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as successful_campaigns,
  AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END) as avg_creative_score,
  MAX(tf.rating) as best_campaign_score,
  COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) as viral_campaigns,
  ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as success_rate
FROM `${var.project_id}.contributor_bronze.contributors` c
JOIN `${var.project_id}.contributor_bronze.tasks` t 
  ON c.contributor_id = t.contributor_id
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'meta_ads'
GROUP BY c.contributor_id, c.name, c.email
HAVING COUNT(t.task_id) >= 3
ORDER BY avg_creative_score DESC, viral_campaigns DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.contributors_bronze,
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

# Google Search Mart Views
resource "google_bigquery_table" "googlesearch_optimization_metrics" {
  dataset_id = google_bigquery_dataset.googlesearch_mart.dataset_id
  table_id   = "optimization_metrics"
  project    = var.project_id

  labels = {
    owner       = "google-search"
    environment = var.env
    layer       = "mart"
    team        = "googlesearch"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  DATE(t.created_at) as optimization_date,
  COUNT(DISTINCT t.contributor_id) as seo_specialists,
  COUNT(t.task_id) as total_optimizations,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as live_optimizations,
  AVG(CASE WHEN tf.rating IS NOT NULL THEN tf.rating END) as avg_seo_score,
  COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) as high_impact_optimizations,
  ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as implementation_rate
FROM `${var.project_id}.contributor_bronze.tasks` t
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'google_search'
GROUP BY DATE(t.created_at)
ORDER BY optimization_date DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}

resource "google_bigquery_table" "googlesearch_ranking_impact" {
  dataset_id = google_bigquery_dataset.googlesearch_mart.dataset_id
  table_id   = "ranking_impact"
  project    = var.project_id

  labels = {
    owner       = "google-search"
    environment = var.env
    layer       = "mart"
    team        = "googlesearch"
    table_type  = "view"
  }

  view {
    query = <<EOQ
SELECT 
  EXTRACT(MONTH FROM t.created_at) as month,
  EXTRACT(YEAR FROM t.created_at) as year,
  COUNT(t.task_id) as total_seo_tasks,
  AVG(tf.rating) as avg_ranking_improvement,
  COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) as top_ranking_improvements,
  COUNT(CASE WHEN tf.rating = 5 THEN 1 END) as exceptional_results,
  ROUND(COUNT(CASE WHEN tf.rating >= 4 THEN 1 END) * 100.0 / COUNT(t.task_id), 2) as high_impact_percentage,
  COUNT(DISTINCT t.contributor_id) as active_seo_experts
FROM `${var.project_id}.contributor_bronze.tasks` t
LEFT JOIN `${var.project_id}.contributor_bronze.task_feedback` tf 
  ON t.task_id = tf.task_id
WHERE t.task_type = 'google_search'
  AND tf.rating IS NOT NULL
GROUP BY EXTRACT(MONTH FROM t.created_at), EXTRACT(YEAR FROM t.created_at)
ORDER BY year DESC, month DESC
EOQ
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.tasks_bronze,
    google_bigquery_table.task_feedback_bronze
  ]
}
