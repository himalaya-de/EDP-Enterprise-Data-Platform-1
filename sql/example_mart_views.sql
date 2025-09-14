-- Data Mart Views
-- These views provide curated data access for specific teams
-- Each team's service account has access only to their respective mart dataset

-- =============================================================================
-- Apple Maps Mart Views
-- =============================================================================

-- Task performance summary for Apple Maps team
CREATE OR REPLACE VIEW `${PROJECT_ID}.applemap_mart.task_summary` AS
SELECT
  d.full_date,
  d.year,
  d.quarter,
  d.month,
  dc.name AS contributor_name,
  dc.email AS contributor_email,
  ftc.task_type,
  ftc.status,
  COUNT(*) AS task_count,
  SUM(ftc.is_completed) AS completed_tasks,
  AVG(ftc.duration_seconds) AS avg_duration_seconds,
  AVG(ftc.duration_seconds) / 3600 AS avg_duration_hours,
  SUM(CASE WHEN ftc.completion_speed = 'Fast' THEN 1 ELSE 0 END) AS fast_completions,
  SUM(CASE WHEN ftc.completion_speed = 'Normal' THEN 1 ELSE 0 END) AS normal_completions,
  SUM(CASE WHEN ftc.completion_speed = 'Slow' THEN 1 ELSE 0 END) AS slow_completions
FROM `${PROJECT_ID}.enterprise_gold.fact_task_completion` ftc
JOIN `${PROJECT_ID}.enterprise_gold.dim_date` d
  ON ftc.created_date_key = d.date_key
JOIN `${PROJECT_ID}.enterprise_gold.dim_contributor` dc
  ON ftc.contributor_key = dc.contributor_key
WHERE ftc.is_valid = 1
  AND dc.is_current = TRUE
  AND d.full_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
ORDER BY d.full_date DESC, task_count DESC;

-- Contributor performance metrics for Apple Maps team
CREATE OR REPLACE VIEW `${PROJECT_ID}.applemap_mart.contributor_performance` AS
SELECT
  dc.contributor_id,
  dc.name AS contributor_name,
  dc.email AS contributor_email,
  COUNT(ftc.task_id) AS total_tasks,
  SUM(ftc.is_completed) AS completed_tasks,
  SAFE_DIVIDE(SUM(ftc.is_completed), COUNT(ftc.task_id)) AS completion_rate,
  AVG(ftc.duration_seconds) / 3600 AS avg_task_duration_hours,
  AVG(ff.rating) AS avg_feedback_rating,
  COUNT(ff.feedback_id) AS total_feedback_count,
  SUM(CASE WHEN ff.sentiment = 'Positive' THEN 1 ELSE 0 END) AS positive_feedback_count,
  SUM(CASE WHEN ff.sentiment = 'Negative' THEN 1 ELSE 0 END) AS negative_feedback_count,
  MIN(ftc.created_at) AS first_task_date,
  MAX(ftc.created_at) AS last_task_date
FROM `${PROJECT_ID}.enterprise_gold.dim_contributor` dc
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_task_completion` ftc
  ON dc.contributor_key = ftc.contributor_key
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_feedback` ff
  ON ftc.contributor_key = ff.contributor_key
WHERE dc.is_current = TRUE
  AND (ftc.created_at IS NULL OR ftc.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY))
GROUP BY 1, 2, 3
HAVING COUNT(ftc.task_id) > 0
ORDER BY completion_rate DESC, avg_feedback_rating DESC;

-- =============================================================================
-- Google Ads Mart Views
-- =============================================================================

-- Audit quality metrics for Google Ads team
CREATE OR REPLACE VIEW `${PROJECT_ID}.googleads_mart.audit_summary` AS
SELECT
  d.full_date,
  d.year,
  d.quarter,
  d.month,
  da.auditor_id,
  far.audit_type,
  far.status,
  COUNT(*) AS audit_count,
  SUM(far.is_completed) AS completed_audits,
  AVG(far.duration_hours) AS avg_duration_hours,
  SUM(far.critical_issues_count) AS total_critical_issues,
  SUM(far.high_issues_count) AS total_high_issues,
  SUM(far.medium_issues_count) AS total_medium_issues,
  SUM(far.low_issues_count) AS total_low_issues,
  SUM(far.total_issues_count) AS total_issues,
  AVG(far.total_issues_count) AS avg_issues_per_audit,
  -- Quality score (lower issues = higher quality)
  CASE 
    WHEN AVG(far.total_issues_count) <= 2 THEN 'Excellent'
    WHEN AVG(far.total_issues_count) <= 5 THEN 'Good'
    WHEN AVG(far.total_issues_count) <= 10 THEN 'Average'
    ELSE 'Needs Improvement'
  END AS quality_rating
FROM `${PROJECT_ID}.enterprise_gold.fact_audit_result` far
JOIN `${PROJECT_ID}.enterprise_gold.dim_date` d
  ON far.created_date_key = d.date_key
JOIN `${PROJECT_ID}.enterprise_gold.dim_auditor` da
  ON far.auditor_key = da.auditor_key
WHERE far.is_valid = 1
  AND da.is_current = TRUE
  AND d.full_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1, 2, 3, 4, 5, 6, 7
ORDER BY d.full_date DESC, total_issues ASC;

-- Auditor performance for Google Ads team
CREATE OR REPLACE VIEW `${PROJECT_ID}.googleads_mart.auditor_performance` AS
SELECT
  da.auditor_id,
  COUNT(far.audit_id) AS total_audits,
  SUM(far.is_completed) AS completed_audits,
  SAFE_DIVIDE(SUM(far.is_completed), COUNT(far.audit_id)) AS completion_rate,
  AVG(far.duration_hours) AS avg_audit_duration_hours,
  SUM(far.total_issues_count) AS total_issues_found,
  AVG(far.total_issues_count) AS avg_issues_per_audit,
  SUM(far.critical_issues_count) AS total_critical_issues,
  AVG(far.critical_issues_count) AS avg_critical_issues_per_audit,
  -- Efficiency metrics
  SAFE_DIVIDE(SUM(far.total_issues_count), SUM(far.duration_hours)) AS issues_found_per_hour,
  MIN(far.created_at) AS first_audit_date,
  MAX(far.created_at) AS last_audit_date
FROM `${PROJECT_ID}.enterprise_gold.dim_auditor` da
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_audit_result` far
  ON da.auditor_key = far.auditor_key
WHERE da.is_current = TRUE
  AND (far.created_at IS NULL OR far.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY))
GROUP BY 1
HAVING COUNT(far.audit_id) > 0
ORDER BY issues_found_per_hour DESC, completion_rate DESC;

-- =============================================================================
-- Meta Ads Mart Views
-- =============================================================================

-- Feedback analysis for Meta Ads team
CREATE OR REPLACE VIEW `${PROJECT_ID}.metaads_mart.feedback_metrics` AS
SELECT
  d.full_date,
  d.year,
  d.quarter,
  d.month,
  ff.sentiment,
  ff.rating,
  COUNT(*) AS feedback_count,
  COUNT(DISTINCT ff.contributor_key) AS unique_contributors,
  AVG(ff.rating) AS avg_rating,
  SUM(ff.has_comment) AS feedback_with_comments,
  SAFE_DIVIDE(SUM(ff.has_comment), COUNT(*)) AS comment_rate
FROM `${PROJECT_ID}.enterprise_gold.fact_feedback` ff
JOIN `${PROJECT_ID}.enterprise_gold.dim_date` d
  ON ff.created_date_key = d.date_key
WHERE ff.is_valid_rating = 1
  AND ff.has_valid_task = 1
  AND d.full_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY d.full_date DESC, ff.rating DESC;

-- Task type feedback analysis for Meta Ads team
CREATE OR REPLACE VIEW `${PROJECT_ID}.metaads_mart.task_feedback_analysis` AS
SELECT
  ftc.task_type,
  COUNT(DISTINCT ftc.task_id) AS total_tasks,
  COUNT(ff.feedback_id) AS total_feedback,
  SAFE_DIVIDE(COUNT(ff.feedback_id), COUNT(DISTINCT ftc.task_id)) AS feedback_rate,
  AVG(ff.rating) AS avg_rating,
  SUM(CASE WHEN ff.sentiment = 'Positive' THEN 1 ELSE 0 END) AS positive_feedback,
  SUM(CASE WHEN ff.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS neutral_feedback,
  SUM(CASE WHEN ff.sentiment = 'Negative' THEN 1 ELSE 0 END) AS negative_feedback,
  SAFE_DIVIDE(
    SUM(CASE WHEN ff.sentiment = 'Positive' THEN 1 ELSE 0 END),
    COUNT(ff.feedback_id)
  ) AS positive_rate,
  -- Correlation with completion time
  AVG(ftc.duration_seconds) / 3600 AS avg_task_duration_hours,
  CORR(ff.rating, ftc.duration_seconds) AS rating_duration_correlation
FROM `${PROJECT_ID}.enterprise_gold.fact_task_completion` ftc
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_feedback` ff
  ON ftc.task_id = ff.task_id
WHERE ftc.is_valid = 1
  AND ftc.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1
HAVING COUNT(ff.feedback_id) >= 10  -- Only include task types with sufficient feedback
ORDER BY avg_rating DESC, feedback_rate DESC;

-- =============================================================================
-- Google Search Mart Views
-- =============================================================================

-- Cross-domain analytics for Google Search team
CREATE OR REPLACE VIEW `${PROJECT_ID}.googlesearch_mart.cross_domain_summary` AS
SELECT
  d.full_date,
  d.year,
  d.quarter,
  d.month,
  -- Task completion metrics
  COUNT(DISTINCT ftc.task_id) AS total_tasks,
  SUM(ftc.is_completed) AS completed_tasks,
  AVG(ftc.duration_seconds) / 3600 AS avg_task_duration_hours,
  -- Audit metrics
  COUNT(DISTINCT far.audit_id) AS total_audits,
  SUM(far.is_completed) AS completed_audits,
  AVG(far.duration_hours) AS avg_audit_duration_hours,
  SUM(far.total_issues_count) AS total_issues_found,
  -- Feedback metrics
  COUNT(ff.feedback_id) AS total_feedback,
  AVG(ff.rating) AS avg_feedback_rating,
  -- Cross-domain correlations
  CORR(
    CASE WHEN ftc.is_completed = 1 THEN ftc.duration_seconds ELSE NULL END,
    ff.rating
  ) AS task_duration_rating_correlation
FROM `${PROJECT_ID}.enterprise_gold.dim_date` d
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_task_completion` ftc
  ON d.date_key = ftc.created_date_key
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_audit_result` far
  ON d.date_key = far.created_date_key
LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_feedback` ff
  ON d.date_key = ff.created_date_key
WHERE d.full_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND d.full_date <= CURRENT_DATE()
GROUP BY 1, 2, 3, 4
HAVING COUNT(DISTINCT ftc.task_id) > 0 OR COUNT(DISTINCT far.audit_id) > 0
ORDER BY d.full_date DESC;

-- Contributor journey analysis for Google Search team
CREATE OR REPLACE VIEW `${PROJECT_ID}.googlesearch_mart.contributor_journey` AS
WITH contributor_metrics AS (
  SELECT
    dc.contributor_key,
    dc.contributor_id,
    dc.name AS contributor_name,
    -- Task metrics
    COUNT(ftc.task_id) AS total_tasks,
    SUM(ftc.is_completed) AS completed_tasks,
    AVG(ftc.duration_seconds) / 3600 AS avg_task_duration_hours,
    -- Feedback metrics
    COUNT(ff.feedback_id) AS total_feedback,
    AVG(ff.rating) AS avg_rating,
    -- Time-based metrics
    MIN(ftc.created_at) AS first_task_date,
    MAX(ftc.created_at) AS last_task_date,
    DATE_DIFF(CURRENT_DATE(), DATE(MAX(ftc.created_at)), DAY) AS days_since_last_task
  FROM `${PROJECT_ID}.enterprise_gold.dim_contributor` dc
  LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_task_completion` ftc
    ON dc.contributor_key = ftc.contributor_key
  LEFT JOIN `${PROJECT_ID}.enterprise_gold.fact_feedback` ff
    ON ftc.contributor_key = ff.contributor_key
  WHERE dc.is_current = TRUE
  GROUP BY 1, 2, 3
)
SELECT
  *,
  -- Contributor lifecycle stage
  CASE
    WHEN total_tasks = 0 THEN 'Inactive'
    WHEN days_since_last_task > 30 THEN 'Dormant'
    WHEN total_tasks < 5 THEN 'New'
    WHEN avg_rating >= 4.5 AND completed_tasks / total_tasks >= 0.9 THEN 'Star Performer'
    WHEN avg_rating >= 4.0 AND completed_tasks / total_tasks >= 0.8 THEN 'Strong Performer'
    WHEN avg_rating >= 3.5 AND completed_tasks / total_tasks >= 0.7 THEN 'Regular Performer'
    ELSE 'Needs Attention'
  END AS contributor_segment,
  -- Performance trend (simplified)
  CASE
    WHEN days_since_last_task <= 7 THEN 'Active'
    WHEN days_since_last_task <= 30 THEN 'Recently Active'
    ELSE 'Inactive'
  END AS activity_status
FROM contributor_metrics
WHERE total_tasks > 0
ORDER BY avg_rating DESC, completed_tasks DESC;
