-- Silver to Gold Data Transformation  
-- This script creates dimensional model in the enterprise_gold dataset
-- Run this under the sa-silver-to-gold service account

-- =============================================================================
-- Dimension Tables (SCD Type 2 where applicable)
-- =============================================================================

-- Dimension: Contributors
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_dim_contributor`()
BEGIN
  -- SCD Type 2 for contributor dimension
  MERGE `${PROJECT_ID}.enterprise_gold.dim_contributor` AS target
  USING (
    WITH current_contributors AS (
      SELECT
        contributor_id,
        name,
        email,
        email_valid,
        name_valid,
        created_at AS source_created_at,
        processed_at AS source_processed_at,
        -- Generate surrogate key
        GENERATE_UUID() AS contributor_key,
        CURRENT_TIMESTAMP() AS effective_date,
        TIMESTAMP('2099-12-31 23:59:59') AS end_date,
        TRUE AS is_current,
        ROW_NUMBER() OVER (PARTITION BY contributor_id ORDER BY processed_at DESC) as rn
      FROM `${PROJECT_ID}.contributor_silver.contributors`
      WHERE email_valid = TRUE AND name_valid = TRUE
    )
    SELECT * FROM current_contributors WHERE rn = 1
  ) AS source
  ON target.contributor_id = source.contributor_id AND target.is_current = TRUE
  WHEN MATCHED AND (
    target.name != source.name OR 
    target.email != source.email OR
    target.email_valid != source.email_valid OR
    target.name_valid != source.name_valid
  ) THEN
    UPDATE SET
      end_date = CURRENT_TIMESTAMP(),
      is_current = FALSE
  WHEN NOT MATCHED THEN
    INSERT (
      contributor_key, contributor_id, name, email, email_valid, name_valid,
      source_created_at, source_processed_at, effective_date, end_date, is_current
    )
    VALUES (
      source.contributor_key, source.contributor_id, source.name, source.email,
      source.email_valid, source.name_valid, source.source_created_at,
      source.source_processed_at, source.effective_date, source.end_date, source.is_current
    );
  
  -- Insert new versions for changed records
  INSERT INTO `${PROJECT_ID}.enterprise_gold.dim_contributor` (
    contributor_key, contributor_id, name, email, email_valid, name_valid,
    source_created_at, source_processed_at, effective_date, end_date, is_current
  )
  SELECT
    GENERATE_UUID() AS contributor_key,
    c.contributor_id,
    c.name,
    c.email,
    c.email_valid,
    c.name_valid,
    c.created_at,
    c.processed_at,
    CURRENT_TIMESTAMP() AS effective_date,
    TIMESTAMP('2099-12-31 23:59:59') AS end_date,
    TRUE AS is_current
  FROM `${PROJECT_ID}.contributor_silver.contributors` c
  INNER JOIN `${PROJECT_ID}.enterprise_gold.dim_contributor` dc
    ON c.contributor_id = dc.contributor_id
  WHERE dc.is_current = FALSE
    AND dc.end_date = CURRENT_TIMESTAMP()
    AND c.email_valid = TRUE 
    AND c.name_valid = TRUE;
END;

-- Dimension: Programs
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_dim_program`()
BEGIN
  MERGE `${PROJECT_ID}.enterprise_gold.dim_program` AS target
  USING (
    SELECT
      program_id,
      program_name,
      program_type,
      status,
      created_at AS source_created_at,
      processed_at AS source_processed_at,
      GENERATE_UUID() AS program_key,
      CURRENT_TIMESTAMP() AS effective_date,
      TIMESTAMP('2099-12-31 23:59:59') AS end_date,
      TRUE AS is_current,
      ROW_NUMBER() OVER (PARTITION BY program_id ORDER BY processed_at DESC) as rn
    FROM `${PROJECT_ID}.programops_silver.program_metadata`
    WHERE name_valid = TRUE AND status_valid = TRUE
  ) AS source
  WHERE source.rn = 1
  ON target.program_id = source.program_id AND target.is_current = TRUE
  WHEN MATCHED AND (
    target.program_name != source.program_name OR 
    target.program_type != source.program_type OR
    target.status != source.status
  ) THEN
    UPDATE SET
      end_date = CURRENT_TIMESTAMP(),
      is_current = FALSE
  WHEN NOT MATCHED THEN
    INSERT (
      program_key, program_id, program_name, program_type, status,
      source_created_at, source_processed_at, effective_date, end_date, is_current
    )
    VALUES (
      source.program_key, source.program_id, source.program_name, source.program_type,
      source.status, source.source_created_at, source.source_processed_at,
      source.effective_date, source.end_date, source.is_current
    );
END;

-- Dimension: Auditors (derived from audit data)
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_dim_auditor`()
BEGIN
  MERGE `${PROJECT_ID}.enterprise_gold.dim_auditor` AS target
  USING (
    SELECT DISTINCT
      auditor_id,
      GENERATE_UUID() AS auditor_key,
      -- Derive auditor metrics
      COUNT(*) OVER (PARTITION BY auditor_id) AS total_audits,
      AVG(duration_hours) OVER (PARTITION BY auditor_id) AS avg_audit_duration_hours,
      MAX(created_at) OVER (PARTITION BY auditor_id) AS last_audit_date,
      MIN(created_at) OVER (PARTITION BY auditor_id) AS first_audit_date,
      CURRENT_TIMESTAMP() AS effective_date,
      TIMESTAMP('2099-12-31 23:59:59') AS end_date,
      TRUE AS is_current
    FROM `${PROJECT_ID}.qualityaudit_silver.audits`
    WHERE auditor_id IS NOT NULL
      AND status_consistent = TRUE
  ) AS source
  ON target.auditor_id = source.auditor_id AND target.is_current = TRUE
  WHEN MATCHED THEN
    UPDATE SET
      total_audits = source.total_audits,
      avg_audit_duration_hours = source.avg_audit_duration_hours,
      last_audit_date = source.last_audit_date,
      first_audit_date = source.first_audit_date
  WHEN NOT MATCHED THEN
    INSERT (
      auditor_key, auditor_id, total_audits, avg_audit_duration_hours,
      last_audit_date, first_audit_date, effective_date, end_date, is_current
    )
    VALUES (
      source.auditor_key, source.auditor_id, source.total_audits,
      source.avg_audit_duration_hours, source.last_audit_date, source.first_audit_date,
      source.effective_date, source.end_date, source.is_current
    );
END;

-- Dimension: Date (standard date dimension)
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_dim_date`()
BEGIN
  -- Create date dimension for the next 5 years if not exists
  INSERT INTO `${PROJECT_ID}.enterprise_gold.dim_date` (
    date_key, full_date, year, quarter, month, day, day_of_week, day_name,
    month_name, is_weekend, is_holiday, fiscal_year, fiscal_quarter
  )
  WITH date_spine AS (
    SELECT 
      DATE_ADD(DATE('2020-01-01'), INTERVAL day_offset DAY) AS full_date
    FROM UNNEST(GENERATE_ARRAY(0, 365 * 8)) AS day_offset -- 8 years of dates
  )
  SELECT
    CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date) AS year,
    EXTRACT(QUARTER FROM full_date) AS quarter,
    EXTRACT(MONTH FROM full_date) AS month,
    EXTRACT(DAY FROM full_date) AS day,
    EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week,
    FORMAT_DATE('%A', full_date) AS day_name,
    FORMAT_DATE('%B', full_date) AS month_name,
    CASE WHEN EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend,
    -- Simple holiday logic - extend as needed
    CASE 
      WHEN FORMAT_DATE('%m-%d', full_date) IN ('01-01', '07-04', '12-25') THEN TRUE 
      ELSE FALSE 
    END AS is_holiday,
    -- Fiscal year starting July 1st
    CASE 
      WHEN EXTRACT(MONTH FROM full_date) >= 7 THEN EXTRACT(YEAR FROM full_date) + 1
      ELSE EXTRACT(YEAR FROM full_date)
    END AS fiscal_year,
    CASE 
      WHEN EXTRACT(MONTH FROM full_date) BETWEEN 7 AND 9 THEN 1
      WHEN EXTRACT(MONTH FROM full_date) BETWEEN 10 AND 12 THEN 2
      WHEN EXTRACT(MONTH FROM full_date) BETWEEN 1 AND 3 THEN 3
      ELSE 4
    END AS fiscal_quarter
  FROM date_spine
  WHERE full_date NOT IN (SELECT full_date FROM `${PROJECT_ID}.enterprise_gold.dim_date`);
END;

-- =============================================================================
-- Fact Tables
-- =============================================================================

-- Fact: Task Completion
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_fact_task_completion`()
BEGIN
  MERGE `${PROJECT_ID}.enterprise_gold.fact_task_completion` AS target
  USING (
    SELECT
      t.task_id,
      dc.contributor_key,
      CAST(FORMAT_DATE('%Y%m%d', DATE(t.created_at)) AS INT64) AS created_date_key,
      CASE 
        WHEN t.completed_at IS NOT NULL 
        THEN CAST(FORMAT_DATE('%Y%m%d', DATE(t.completed_at)) AS INT64)
        ELSE NULL
      END AS completed_date_key,
      t.task_type,
      t.status,
      t.duration_seconds,
      CASE WHEN t.status = 'COMPLETED' THEN 1 ELSE 0 END AS is_completed,
      CASE WHEN t.status_consistent THEN 1 ELSE 0 END AS is_valid,
      CASE WHEN t.contributor_exists THEN 1 ELSE 0 END AS has_valid_contributor,
      -- Calculate performance metrics
      CASE 
        WHEN t.duration_seconds <= 3600 THEN 'Fast' -- <= 1 hour
        WHEN t.duration_seconds <= 28800 THEN 'Normal' -- <= 8 hours  
        ELSE 'Slow'
      END AS completion_speed,
      t.created_at,
      t.completed_at,
      CURRENT_TIMESTAMP() AS processed_at
    FROM `${PROJECT_ID}.contributor_silver.tasks` t
    LEFT JOIN `${PROJECT_ID}.enterprise_gold.dim_contributor` dc
      ON t.contributor_id = dc.contributor_id AND dc.is_current = TRUE
    WHERE t.status_consistent = TRUE
  ) AS source
  ON target.task_id = source.task_id
  WHEN MATCHED THEN
    UPDATE SET
      contributor_key = source.contributor_key,
      created_date_key = source.created_date_key,
      completed_date_key = source.completed_date_key,
      task_type = source.task_type,
      status = source.status,
      duration_seconds = source.duration_seconds,
      is_completed = source.is_completed,
      is_valid = source.is_valid,
      has_valid_contributor = source.has_valid_contributor,
      completion_speed = source.completion_speed,
      created_at = source.created_at,
      completed_at = source.completed_at,
      processed_at = source.processed_at
  WHEN NOT MATCHED THEN
    INSERT (
      task_id, contributor_key, created_date_key, completed_date_key,
      task_type, status, duration_seconds, is_completed, is_valid,
      has_valid_contributor, completion_speed, created_at, completed_at, processed_at
    )
    VALUES (
      source.task_id, source.contributor_key, source.created_date_key, source.completed_date_key,
      source.task_type, source.status, source.duration_seconds, source.is_completed,
      source.is_valid, source.has_valid_contributor, source.completion_speed,
      source.created_at, source.completed_at, source.processed_at
    );
END;

-- Fact: Audit Results
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_fact_audit_result`()
BEGIN
  MERGE `${PROJECT_ID}.enterprise_gold.fact_audit_result` AS target
  USING (
    SELECT
      a.audit_id,
      da.auditor_key,
      CAST(FORMAT_DATE('%Y%m%d', DATE(a.created_at)) AS INT64) AS created_date_key,
      CASE 
        WHEN a.completed_at IS NOT NULL 
        THEN CAST(FORMAT_DATE('%Y%m%d', DATE(a.completed_at)) AS INT64)
        ELSE NULL
      END AS completed_date_key,
      a.audit_type,
      a.status,
      a.duration_hours,
      CASE WHEN a.status = 'COMPLETED' THEN 1 ELSE 0 END AS is_completed,
      CASE WHEN a.status_consistent THEN 1 ELSE 0 END AS is_valid,
      -- Count issues by severity
      COALESCE(issues.critical_issues, 0) AS critical_issues_count,
      COALESCE(issues.high_issues, 0) AS high_issues_count,
      COALESCE(issues.medium_issues, 0) AS medium_issues_count,
      COALESCE(issues.low_issues, 0) AS low_issues_count,
      COALESCE(issues.total_issues, 0) AS total_issues_count,
      a.created_at,
      a.completed_at,
      CURRENT_TIMESTAMP() AS processed_at
    FROM `${PROJECT_ID}.qualityaudit_silver.audits` a
    LEFT JOIN `${PROJECT_ID}.enterprise_gold.dim_auditor` da
      ON a.auditor_id = da.auditor_id AND da.is_current = TRUE
    LEFT JOIN (
      SELECT
        audit_id,
        SUM(CASE WHEN severity = 'CRITICAL' THEN 1 ELSE 0 END) AS critical_issues,
        SUM(CASE WHEN severity = 'HIGH' THEN 1 ELSE 0 END) AS high_issues,
        SUM(CASE WHEN severity = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_issues,
        SUM(CASE WHEN severity = 'LOW' THEN 1 ELSE 0 END) AS low_issues,
        COUNT(*) AS total_issues
      FROM `${PROJECT_ID}.qualityaudit_silver.audit_issues`
      WHERE severity_valid = TRUE AND audit_exists = TRUE
      GROUP BY audit_id
    ) issues ON a.audit_id = issues.audit_id
    WHERE a.status_consistent = TRUE
  ) AS source
  ON target.audit_id = source.audit_id
  WHEN MATCHED THEN
    UPDATE SET
      auditor_key = source.auditor_key,
      created_date_key = source.created_date_key,
      completed_date_key = source.completed_date_key,
      audit_type = source.audit_type,
      status = source.status,
      duration_hours = source.duration_hours,
      is_completed = source.is_completed,
      is_valid = source.is_valid,
      critical_issues_count = source.critical_issues_count,
      high_issues_count = source.high_issues_count,
      medium_issues_count = source.medium_issues_count,
      low_issues_count = source.low_issues_count,
      total_issues_count = source.total_issues_count,
      created_at = source.created_at,
      completed_at = source.completed_at,
      processed_at = source.processed_at
  WHEN NOT MATCHED THEN
    INSERT (
      audit_id, auditor_key, created_date_key, completed_date_key,
      audit_type, status, duration_hours, is_completed, is_valid,
      critical_issues_count, high_issues_count, medium_issues_count,
      low_issues_count, total_issues_count, created_at, completed_at, processed_at
    )
    VALUES (
      source.audit_id, source.auditor_key, source.created_date_key, source.completed_date_key,
      source.audit_type, source.status, source.duration_hours, source.is_completed,
      source.is_valid, source.critical_issues_count, source.high_issues_count,
      source.medium_issues_count, source.low_issues_count, source.total_issues_count,
      source.created_at, source.completed_at, source.processed_at
    );
END;

-- Fact: Feedback
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.build_fact_feedback`()
BEGIN
  MERGE `${PROJECT_ID}.enterprise_gold.fact_feedback` AS target
  USING (
    SELECT
      tf.feedback_id,
      ftc.contributor_key,
      CAST(FORMAT_DATE('%Y%m%d', DATE(tf.created_at)) AS INT64) AS created_date_key,
      tf.task_id,
      tf.rating,
      CASE WHEN tf.has_comment THEN 1 ELSE 0 END AS has_comment,
      CASE WHEN tf.rating_valid THEN 1 ELSE 0 END AS is_valid_rating,
      CASE WHEN tf.task_exists THEN 1 ELSE 0 END AS has_valid_task,
      -- Sentiment analysis (simple)
      CASE 
        WHEN tf.rating >= 4 THEN 'Positive'
        WHEN tf.rating = 3 THEN 'Neutral'
        ELSE 'Negative'
      END AS sentiment,
      tf.created_at,
      CURRENT_TIMESTAMP() AS processed_at
    FROM `${PROJECT_ID}.contributor_silver.task_feedback` tf
    LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_task_completion` ftc
      ON tf.task_id = ftc.task_id
    WHERE tf.rating_valid = TRUE AND tf.task_exists = TRUE
  ) AS source
  ON target.feedback_id = source.feedback_id
  WHEN MATCHED THEN
    UPDATE SET
      contributor_key = source.contributor_key,
      created_date_key = source.created_date_key,
      task_id = source.task_id,
      rating = source.rating,
      has_comment = source.has_comment,
      is_valid_rating = source.is_valid_rating,
      has_valid_task = source.has_valid_task,
      sentiment = source.sentiment,
      created_at = source.created_at,
      processed_at = source.processed_at
  WHEN NOT MATCHED THEN
    INSERT (
      feedback_id, contributor_key, created_date_key, task_id, rating,
      has_comment, is_valid_rating, has_valid_task, sentiment, created_at, processed_at
    )
    VALUES (
      source.feedback_id, source.contributor_key, source.created_date_key,
      source.task_id, source.rating, source.has_comment, source.is_valid_rating,
      source.has_valid_task, source.sentiment, source.created_at, source.processed_at
    );
END;

-- =============================================================================
-- Master Procedure to Run All Silver to Gold Transformations
-- =============================================================================

CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.enterprise_gold.run_all_silver_to_gold_transforms`()
BEGIN
  DECLARE error_message STRING;
  
  BEGIN
    -- Build dimensions first
    CALL `${PROJECT_ID}.enterprise_gold.build_dim_date`();
    CALL `${PROJECT_ID}.enterprise_gold.build_dim_contributor`();
    CALL `${PROJECT_ID}.enterprise_gold.build_dim_program`();
    CALL `${PROJECT_ID}.enterprise_gold.build_dim_auditor`();
    
    -- Build facts (depends on dimensions)
    CALL `${PROJECT_ID}.enterprise_gold.build_fact_task_completion`();
    CALL `${PROJECT_ID}.enterprise_gold.build_fact_audit_result`();
    CALL `${PROJECT_ID}.enterprise_gold.build_fact_feedback`();
    
    -- Log completion
    SELECT 'All silver to gold transformations completed successfully' AS status;
    
  EXCEPTION WHEN ERROR THEN
    GET DIAGNOSTICS error_message = MESSAGE_TEXT;
    SELECT CONCAT('Error in silver to gold transformation: ', error_message) AS error;
    RAISE USING MESSAGE = error_message;
  END;
END;
