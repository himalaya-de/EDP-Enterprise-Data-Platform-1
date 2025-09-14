-- Bronze to Silver Data Transformation
-- This script contains stored procedures to transform data from bronze to silver datasets
-- Run this under the sa-bronze-to-silver service account

-- =============================================================================
-- Contributor Bronze to Silver Transformations
-- =============================================================================

-- Transform contributors table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.contributor_silver.transform_contributors`()
BEGIN
  -- Clean and validate contributor data
  MERGE `${PROJECT_ID}.contributor_silver.contributors` AS target
  USING (
    SELECT DISTINCT
      contributor_id,
      TRIM(UPPER(name)) AS name,
      LOWER(TRIM(email)) AS email,
      created_at,
      -- Data quality flags
      CASE 
        WHEN email IS NULL OR NOT REGEXP_CONTAINS(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') 
        THEN FALSE 
        ELSE TRUE 
      END AS email_valid,
      CASE 
        WHEN name IS NULL OR LENGTH(TRIM(name)) < 2 
        THEN FALSE 
        ELSE TRUE 
      END AS name_valid,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.contributor_bronze.contributors`
    WHERE contributor_id IS NOT NULL
      AND created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY) -- Process last 7 days
  ) AS source
  ON target.contributor_id = source.contributor_id
  WHEN MATCHED THEN
    UPDATE SET
      name = source.name,
      email = source.email,
      created_at = source.created_at,
      email_valid = source.email_valid,
      name_valid = source.name_valid,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      contributor_id, name, email, created_at, 
      email_valid, name_valid, processed_at, data_version
    )
    VALUES (
      source.contributor_id, source.name, source.email, source.created_at,
      source.email_valid, source.name_valid, source.processed_at, source.data_version
    );
END;

-- Transform tasks table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.contributor_silver.transform_tasks`()
BEGIN
  -- Clean and enrich task data
  MERGE `${PROJECT_ID}.contributor_silver.tasks` AS target
  USING (
    SELECT DISTINCT
      t.task_id,
      t.contributor_id,
      UPPER(TRIM(t.task_type)) AS task_type,
      UPPER(TRIM(t.status)) AS status,
      t.created_at,
      t.completed_at,
      -- Derived fields
      CASE 
        WHEN t.completed_at IS NOT NULL AND t.created_at IS NOT NULL
        THEN TIMESTAMP_DIFF(t.completed_at, t.created_at, SECOND)
        ELSE NULL
      END AS duration_seconds,
      CASE
        WHEN t.status = 'COMPLETED' AND t.completed_at IS NULL THEN FALSE
        WHEN t.status != 'COMPLETED' AND t.completed_at IS NOT NULL THEN FALSE
        ELSE TRUE
      END AS status_consistent,
      -- Validate contributor exists
      CASE 
        WHEN c.contributor_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
      END AS contributor_exists,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.contributor_bronze.tasks` t
    LEFT JOIN `${PROJECT_ID}.contributor_silver.contributors` c
      ON t.contributor_id = c.contributor_id
    WHERE t.task_id IS NOT NULL
      AND t.created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ) AS source
  ON target.task_id = source.task_id
  WHEN MATCHED THEN
    UPDATE SET
      contributor_id = source.contributor_id,
      task_type = source.task_type,
      status = source.status,
      created_at = source.created_at,
      completed_at = source.completed_at,
      duration_seconds = source.duration_seconds,
      status_consistent = source.status_consistent,
      contributor_exists = source.contributor_exists,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      task_id, contributor_id, task_type, status, created_at, completed_at,
      duration_seconds, status_consistent, contributor_exists, processed_at, data_version
    )
    VALUES (
      source.task_id, source.contributor_id, source.task_type, source.status,
      source.created_at, source.completed_at, source.duration_seconds,
      source.status_consistent, source.contributor_exists, source.processed_at, source.data_version
    );
END;

-- Transform task feedback table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.contributor_silver.transform_task_feedback`()
BEGIN
  -- Clean and validate feedback data
  MERGE `${PROJECT_ID}.contributor_silver.task_feedback` AS target
  USING (
    SELECT DISTINCT
      tf.feedback_id,
      tf.task_id,
      tf.rating,
      TRIM(tf.comment) AS comment,
      tf.created_at,
      -- Data quality validations
      CASE 
        WHEN tf.rating BETWEEN 1 AND 5 THEN TRUE 
        ELSE FALSE 
      END AS rating_valid,
      CASE 
        WHEN t.task_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
      END AS task_exists,
      CASE
        WHEN tf.comment IS NULL OR LENGTH(TRIM(tf.comment)) = 0 THEN FALSE
        ELSE TRUE
      END AS has_comment,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.contributor_bronze.task_feedback` tf
    LEFT JOIN `${PROJECT_ID}.contributor_silver.tasks` t
      ON tf.task_id = t.task_id
    WHERE tf.feedback_id IS NOT NULL
      AND tf.created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ) AS source
  ON target.feedback_id = source.feedback_id
  WHEN MATCHED THEN
    UPDATE SET
      task_id = source.task_id,
      rating = source.rating,
      comment = source.comment,
      created_at = source.created_at,
      rating_valid = source.rating_valid,
      task_exists = source.task_exists,
      has_comment = source.has_comment,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      feedback_id, task_id, rating, comment, created_at,
      rating_valid, task_exists, has_comment, processed_at, data_version
    )
    VALUES (
      source.feedback_id, source.task_id, source.rating, source.comment, source.created_at,
      source.rating_valid, source.task_exists, source.has_comment, source.processed_at, source.data_version
    );
END;

-- =============================================================================
-- Quality Audit Bronze to Silver Transformations  
-- =============================================================================

-- Transform audits table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.qualityaudit_silver.transform_audits`()
BEGIN
  MERGE `${PROJECT_ID}.qualityaudit_silver.audits` AS target
  USING (
    SELECT DISTINCT
      audit_id,
      auditor_id,
      UPPER(TRIM(audit_type)) AS audit_type,
      UPPER(TRIM(status)) AS status,
      created_at,
      completed_at,
      -- Derived fields
      CASE 
        WHEN completed_at IS NOT NULL AND created_at IS NOT NULL
        THEN TIMESTAMP_DIFF(completed_at, created_at, HOUR)
        ELSE NULL
      END AS duration_hours,
      CASE
        WHEN status = 'COMPLETED' AND completed_at IS NULL THEN FALSE
        WHEN status != 'COMPLETED' AND completed_at IS NOT NULL THEN FALSE
        ELSE TRUE
      END AS status_consistent,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.qualityaudit_bronze.audits`
    WHERE audit_id IS NOT NULL
      AND created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ) AS source
  ON target.audit_id = source.audit_id
  WHEN MATCHED THEN
    UPDATE SET
      auditor_id = source.auditor_id,
      audit_type = source.audit_type,
      status = source.status,
      created_at = source.created_at,
      completed_at = source.completed_at,
      duration_hours = source.duration_hours,
      status_consistent = source.status_consistent,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      audit_id, auditor_id, audit_type, status, created_at, completed_at,
      duration_hours, status_consistent, processed_at, data_version
    )
    VALUES (
      source.audit_id, source.auditor_id, source.audit_type, source.status,
      source.created_at, source.completed_at, source.duration_hours,
      source.status_consistent, source.processed_at, source.data_version
    );
END;

-- Transform audit issues table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.qualityaudit_silver.transform_audit_issues`()
BEGIN
  MERGE `${PROJECT_ID}.qualityaudit_silver.audit_issues` AS target
  USING (
    SELECT DISTINCT
      ai.issue_id,
      ai.audit_id,
      UPPER(TRIM(ai.severity)) AS severity,
      TRIM(ai.description) AS description,
      ai.created_at,
      -- Data quality validations
      CASE 
        WHEN ai.severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') THEN TRUE 
        ELSE FALSE 
      END AS severity_valid,
      CASE 
        WHEN a.audit_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
      END AS audit_exists,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.qualityaudit_bronze.audit_issues` ai
    LEFT JOIN `${PROJECT_ID}.qualityaudit_silver.audits` a
      ON ai.audit_id = a.audit_id
    WHERE ai.issue_id IS NOT NULL
      AND ai.created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ) AS source
  ON target.issue_id = source.issue_id
  WHEN MATCHED THEN
    UPDATE SET
      audit_id = source.audit_id,
      severity = source.severity,
      description = source.description,
      created_at = source.created_at,
      severity_valid = source.severity_valid,
      audit_exists = source.audit_exists,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      issue_id, audit_id, severity, description, created_at,
      severity_valid, audit_exists, processed_at, data_version
    )
    VALUES (
      source.issue_id, source.audit_id, source.severity, source.description, source.created_at,
      source.severity_valid, source.audit_exists, source.processed_at, source.data_version
    );
END;

-- =============================================================================
-- Program Ops Bronze to Silver Transformations
-- =============================================================================

-- Transform program metadata table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.programops_silver.transform_program_metadata`()
BEGIN
  MERGE `${PROJECT_ID}.programops_silver.program_metadata` AS target
  USING (
    SELECT DISTINCT
      program_id,
      TRIM(program_name) AS program_name,
      UPPER(TRIM(program_type)) AS program_type,
      UPPER(TRIM(status)) AS status,
      created_at,
      -- Data quality validations
      CASE 
        WHEN program_name IS NULL OR LENGTH(TRIM(program_name)) < 3 THEN FALSE 
        ELSE TRUE 
      END AS name_valid,
      CASE 
        WHEN status IN ('ACTIVE', 'INACTIVE', 'PENDING', 'COMPLETED') THEN TRUE 
        ELSE FALSE 
      END AS status_valid,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.programops_bronze.program_metadata`
    WHERE program_id IS NOT NULL
      AND created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ) AS source
  ON target.program_id = source.program_id
  WHEN MATCHED THEN
    UPDATE SET
      program_name = source.program_name,
      program_type = source.program_type,
      status = source.status,
      created_at = source.created_at,
      name_valid = source.name_valid,
      status_valid = source.status_valid,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      program_id, program_name, program_type, status, created_at,
      name_valid, status_valid, processed_at, data_version
    )
    VALUES (
      source.program_id, source.program_name, source.program_type, source.status, source.created_at,
      source.name_valid, source.status_valid, source.processed_at, source.data_version
    );
END;

-- Transform acknowledgements table
CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.programops_silver.transform_acknowledgements`()
BEGIN
  MERGE `${PROJECT_ID}.programops_silver.acknowledgements` AS target
  USING (
    SELECT DISTINCT
      ack.ack_id,
      ack.program_id,
      ack.contributor_id,
      UPPER(TRIM(ack.ack_type)) AS ack_type,
      ack.created_at,
      -- Reference validations
      CASE 
        WHEN p.program_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
      END AS program_exists,
      CASE 
        WHEN c.contributor_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
      END AS contributor_exists,
      CURRENT_TIMESTAMP() AS processed_at,
      '1.0' AS data_version
    FROM `${PROJECT_ID}.programops_bronze.acknowledgements` ack
    LEFT JOIN `${PROJECT_ID}.programops_silver.program_metadata` p
      ON ack.program_id = p.program_id
    LEFT JOIN `${PROJECT_ID}.contributor_silver.contributors` c
      ON ack.contributor_id = c.contributor_id
    WHERE ack.ack_id IS NOT NULL
      AND ack.created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ) AS source
  ON target.ack_id = source.ack_id
  WHEN MATCHED THEN
    UPDATE SET
      program_id = source.program_id,
      contributor_id = source.contributor_id,
      ack_type = source.ack_type,
      created_at = source.created_at,
      program_exists = source.program_exists,
      contributor_exists = source.contributor_exists,
      processed_at = source.processed_at,
      data_version = source.data_version
  WHEN NOT MATCHED THEN
    INSERT (
      ack_id, program_id, contributor_id, ack_type, created_at,
      program_exists, contributor_exists, processed_at, data_version
    )
    VALUES (
      source.ack_id, source.program_id, source.contributor_id, source.ack_type, source.created_at,
      source.program_exists, source.contributor_exists, source.processed_at, source.data_version
    );
END;

-- =============================================================================
-- Master Procedure to Run All Bronze to Silver Transformations
-- =============================================================================

CREATE OR REPLACE PROCEDURE `${PROJECT_ID}.contributor_silver.run_all_bronze_to_silver_transforms`()
BEGIN
  DECLARE error_message STRING;
  
  BEGIN
    -- Contributor transformations
    CALL `${PROJECT_ID}.contributor_silver.transform_contributors`();
    CALL `${PROJECT_ID}.contributor_silver.transform_tasks`();
    CALL `${PROJECT_ID}.contributor_silver.transform_task_feedback`();
    
    -- Quality audit transformations
    CALL `${PROJECT_ID}.qualityaudit_silver.transform_audits`();
    CALL `${PROJECT_ID}.qualityaudit_silver.transform_audit_issues`();
    
    -- Program ops transformations
    CALL `${PROJECT_ID}.programops_silver.transform_program_metadata`();
    CALL `${PROJECT_ID}.programops_silver.transform_acknowledgements`();
    
    -- Log completion
    SELECT 'All bronze to silver transformations completed successfully' AS status;
    
  EXCEPTION WHEN ERROR THEN
    GET DIAGNOSTICS error_message = MESSAGE_TEXT;
    SELECT CONCAT('Error in bronze to silver transformation: ', error_message) AS error;
    RAISE USING MESSAGE = error_message;
  END;
END;
