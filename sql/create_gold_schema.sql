-- Create Gold Schema Tables
-- This script creates the dimensional model tables in enterprise_gold dataset
-- Run this script after Terraform creates the dataset

-- =============================================================================
-- Dimension Tables
-- =============================================================================

-- Dimension: Contributors (SCD Type 2)
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.dim_contributor` (
  contributor_key STRING NOT NULL,
  contributor_id STRING NOT NULL,
  name STRING,
  email STRING,
  email_valid BOOLEAN,
  name_valid BOOLEAN,
  source_created_at TIMESTAMP,
  source_processed_at TIMESTAMP,
  effective_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  is_current BOOLEAN NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(effective_date)
CLUSTER BY contributor_id, is_current;

-- Dimension: Programs (SCD Type 2)
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.dim_program` (
  program_key STRING NOT NULL,
  program_id STRING NOT NULL,
  program_name STRING,
  program_type STRING,
  status STRING,
  source_created_at TIMESTAMP,
  source_processed_at TIMESTAMP,
  effective_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  is_current BOOLEAN NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(effective_date)
CLUSTER BY program_id, is_current;

-- Dimension: Auditors
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.dim_auditor` (
  auditor_key STRING NOT NULL,
  auditor_id STRING NOT NULL,
  total_audits INT64,
  avg_audit_duration_hours FLOAT64,
  last_audit_date TIMESTAMP,
  first_audit_date TIMESTAMP,
  effective_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  is_current BOOLEAN NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY auditor_id, is_current;

-- Dimension: Date
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.dim_date` (
  date_key INT64 NOT NULL,
  full_date DATE NOT NULL,
  year INT64,
  quarter INT64,
  month INT64,
  day INT64,
  day_of_week INT64,
  day_name STRING,
  month_name STRING,
  is_weekend BOOLEAN,
  is_holiday BOOLEAN,
  fiscal_year INT64,
  fiscal_quarter INT64,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY date_key;

-- =============================================================================
-- Fact Tables
-- =============================================================================

-- Fact: Task Completion
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.fact_task_completion` (
  task_id STRING NOT NULL,
  contributor_key STRING,
  created_date_key INT64,
  completed_date_key INT64,
  task_type STRING,
  status STRING,
  duration_seconds INT64,
  is_completed INT64,
  is_valid INT64,
  has_valid_contributor INT64,
  completion_speed STRING,
  created_at TIMESTAMP,
  completed_at TIMESTAMP,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(created_at)
CLUSTER BY contributor_key, task_type, status;

-- Fact: Audit Results
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.fact_audit_result` (
  audit_id STRING NOT NULL,
  auditor_key STRING,
  created_date_key INT64,
  completed_date_key INT64,
  audit_type STRING,
  status STRING,
  duration_hours FLOAT64,
  is_completed INT64,
  is_valid INT64,
  critical_issues_count INT64,
  high_issues_count INT64,
  medium_issues_count INT64,
  low_issues_count INT64,
  total_issues_count INT64,
  created_at TIMESTAMP,
  completed_at TIMESTAMP,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(created_at)
CLUSTER BY auditor_key, audit_type, status;

-- Fact: Feedback
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.enterprise_gold.fact_feedback` (
  feedback_id STRING NOT NULL,
  contributor_key STRING,
  created_date_key INT64,
  task_id STRING,
  rating INT64,
  has_comment INT64,
  is_valid_rating INT64,
  has_valid_task INT64,
  sentiment STRING,
  created_at TIMESTAMP,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(created_at)
CLUSTER BY contributor_key, rating, sentiment;

-- =============================================================================
-- Create Silver Dataset Tables (with data quality fields)
-- =============================================================================

-- Contributor Silver Tables
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.contributor_silver.contributors` (
  contributor_id STRING NOT NULL,
  name STRING,
  email STRING,
  created_at TIMESTAMP,
  email_valid BOOLEAN,
  name_valid BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY contributor_id;

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.contributor_silver.tasks` (
  task_id STRING NOT NULL,
  contributor_id STRING,
  task_type STRING,
  status STRING,
  created_at TIMESTAMP,
  completed_at TIMESTAMP,
  duration_seconds INT64,
  status_consistent BOOLEAN,
  contributor_exists BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY contributor_id, task_type, status;

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.contributor_silver.task_feedback` (
  feedback_id STRING NOT NULL,
  task_id STRING,
  rating INT64,
  comment STRING,
  created_at TIMESTAMP,
  rating_valid BOOLEAN,
  task_exists BOOLEAN,
  has_comment BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY task_id, rating;

-- Quality Audit Silver Tables
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.qualityaudit_silver.audits` (
  audit_id STRING NOT NULL,
  auditor_id STRING,
  audit_type STRING,
  status STRING,
  created_at TIMESTAMP,
  completed_at TIMESTAMP,
  duration_hours FLOAT64,
  status_consistent BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY auditor_id, audit_type, status;

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.qualityaudit_silver.audit_issues` (
  issue_id STRING NOT NULL,
  audit_id STRING,
  severity STRING,
  description STRING,
  created_at TIMESTAMP,
  severity_valid BOOLEAN,
  audit_exists BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY audit_id, severity;

-- Program Ops Silver Tables
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.programops_silver.program_metadata` (
  program_id STRING NOT NULL,
  program_name STRING,
  program_type STRING,
  status STRING,
  created_at TIMESTAMP,
  name_valid BOOLEAN,
  status_valid BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY program_id, program_type, status;

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.programops_silver.acknowledgements` (
  ack_id STRING NOT NULL,
  program_id STRING,
  contributor_id STRING,
  ack_type STRING,
  created_at TIMESTAMP,
  program_exists BOOLEAN,
  contributor_exists BOOLEAN,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  data_version STRING
)
PARTITION BY DATE(processed_at)
CLUSTER BY program_id, contributor_id;
