"""
=============================================================================
CLOUD FUNCTION: Contributor Staging to Bronze Data Pipeline
=============================================================================

DATA LINEAGE DOCUMENTATION:
----------------------------
SOURCE: GCS Staging Bucket (gs://hackathon2025-01-staging-contributor-demo/)
├── File Types: CSV, JSON, Parquet, Avro
├── Naming Convention: {table_name}_{timestamp}.{extension}
├── Expected Tables: contributors, tasks, task_feedback

DESTINATION: BigQuery Bronze Dataset
├── Project: hackathon2025-01
├── Dataset: contributor_bronze  
├── Tables: contributors, tasks, task_feedback
├── Schema: Auto-detected + Datastream metadata fields

LINEAGE FLOW:
1. File Upload → GCS Staging Bucket
2. GCS Event Trigger → Cloud Function (THIS)
3. Cloud Function → BigQuery Bronze Tables
4. DOWNSTREAM: Bronze → Silver → Gold → Data Marts

DOWNSTREAM CONSUMERS:
- Silver Layer: contributor_silver.{contributors, tasks, task_feedback}
- Gold Layer: enterprise_gold.dim_contributor, enterprise_gold.fact_task
- Data Marts: applemap_mart, googleads_mart, metaads_mart, googlesearch_mart

DATA DOMAINS: contributor-management, task-tracking, feedback-analysis
DATA CLASSIFICATION: Restricted (contains PII)
PROCESSING_FREQUENCY: Real-time (event-driven)
=============================================================================
"""

import json
import os
import logging
from datetime import datetime
from google.cloud import bigquery
from google.cloud.exceptions import NotFound
import pandas as pd
from typing import Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables with lineage context
PROJECT_ID = os.environ.get('PROJECT_ID')
DATASET_ID = os.environ.get('DATASET_ID', 'contributor_bronze')
TABLE_MAPPING = json.loads(os.environ.get('TABLE_MAPPING', '{}'))

# LINEAGE METADATA CONSTANTS
LINEAGE_METADATA = {
    'pipeline_name': 'contributor-staging-to-bronze',
    'source_system': 'gcs-staging-bucket',
    'destination_system': 'bigquery-bronze-layer',
    'data_domain': 'contributor-management',
    'processing_tier': 'bronze-ingestion',
    'downstream_datasets': ['contributor_silver', 'enterprise_gold'],
    'downstream_marts': ['applemap_mart', 'googleads_mart', 'metaads_mart', 'googlesearch_mart'],
    'data_classification': 'restricted',
    'contains_pii': True
}

def main(event: Dict[str, Any], context: Any) -> None:
    """
    Cloud Function triggered by GCS object finalization.
    Loads staging files into BigQuery bronze dataset.
    
    LINEAGE EXECUTION:
    - SOURCE: gs://{bucket_name}/{file_name}
    - DESTINATION: {PROJECT_ID}.{DATASET_ID}.{table_name}
    - PROCESSING_TYPE: file-to-table ingestion
    - DOWNSTREAM_IMPACT: Triggers silver layer processing
    
    Args:
        event: Cloud Storage event data
        context: Cloud Function context
    """
    execution_start = datetime.utcnow()
    
    try:
        # Extract file information from event
        bucket_name = event['bucket']
        file_name = event['name']
        
        # LOG LINEAGE: Start of data flow
        lineage_context = {
            'execution_id': context.eventId if context else 'unknown',
            'source_uri': f"gs://{bucket_name}/{file_name}",
            'source_system': LINEAGE_METADATA['source_system'],
            'destination_system': LINEAGE_METADATA['destination_system'],
            'pipeline_name': LINEAGE_METADATA['pipeline_name'],
            'data_domain': LINEAGE_METADATA['data_domain'],
            'processing_tier': LINEAGE_METADATA['processing_tier'],
            'execution_start': execution_start.isoformat()
        }
        
        logger.info(f"LINEAGE_START: {json.dumps(lineage_context)}")
        logger.info(f"Processing file: gs://{bucket_name}/{file_name}")
        
        # Initialize BigQuery client
        client = bigquery.Client(project=PROJECT_ID)
        
        # Determine target table based on file name
        table_name = determine_table_name(file_name)
        if not table_name:
            logger.warning(f"No table mapping found for file: {file_name}")
            return
        
        # Create table reference
        table_ref = client.dataset(DATASET_ID).table(table_name)
        
        # Configure load job
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,  # Assume CSV has header
            autodetect=True,      # Auto-detect schema
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
            create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED
        )
        
        # Add Datastream metadata fields if not present
        add_datastream_metadata_fields(job_config)
        
        # Construct source URI
        source_uri = f"gs://{bucket_name}/{file_name}"
        
        # Start load job
        load_job = client.load_table_from_uri(
            source_uri,
            table_ref,
            job_config=job_config
        )
        
        # Wait for job completion
        load_job.result()
        
        # LOG LINEAGE: Successful completion
        destination_table = client.get_table(table_ref)
        execution_end = datetime.utcnow()
        execution_duration = (execution_end - execution_start).total_seconds()
        
        lineage_completion = {
            'execution_id': context.eventId if context else 'unknown',
            'status': 'SUCCESS',
            'source_uri': f"gs://{bucket_name}/{file_name}",
            'destination_table': f"{PROJECT_ID}.{DATASET_ID}.{table_name}",
            'rows_processed': load_job.output_rows,
            'total_rows_in_table': destination_table.num_rows,
            'execution_duration_seconds': execution_duration,
            'execution_end': execution_end.isoformat(),
            'downstream_datasets': LINEAGE_METADATA['downstream_datasets'],
            'downstream_marts': LINEAGE_METADATA['downstream_marts'],
            'data_classification': LINEAGE_METADATA['data_classification'],
            'contains_pii': LINEAGE_METADATA['contains_pii']
        }
        
        logger.info(f"LINEAGE_SUCCESS: {json.dumps(lineage_completion)}")
        logger.info(f"Successfully loaded {load_job.output_rows} rows into "
                   f"{DATASET_ID}.{table_name}. "
                   f"Total rows in table: {destination_table.num_rows}")
        
    except Exception as e:
        logger.error(f"Error processing file {file_name}: {str(e)}")
        raise


def determine_table_name(file_name: str) -> str:
    """
    Determine target BigQuery table based on file name.
    
    Args:
        file_name: GCS file name
        
    Returns:
        BigQuery table name or None if no mapping found
    """
    # Extract table identifier from file name
    # Assumes file naming convention like: contributors_YYYYMMDD_HHMMSS.csv
    for keyword, table_name in TABLE_MAPPING.items():
        if keyword in file_name.lower():
            return table_name
    
    # If no specific mapping, try to extract from file name
    # Remove extension and timestamp patterns
    base_name = file_name.split('.')[0]
    base_name = base_name.split('_')[0]  # Take first part before underscore
    
    # Return base name if it exists in table mapping values
    if base_name in TABLE_MAPPING.values():
        return base_name
    
    return None


def add_datastream_metadata_fields(job_config: bigquery.LoadJobConfig) -> None:
    """
    Add Datastream metadata fields to schema if auto-detection is disabled.
    
    Args:
        job_config: BigQuery load job configuration
    """
    if not job_config.autodetect:
        # Add common Datastream metadata fields
        metadata_fields = [
            bigquery.SchemaField("_datastream_metadata", "RECORD", mode="NULLABLE", fields=[
                bigquery.SchemaField("source_timestamp", "TIMESTAMP", mode="NULLABLE"),
                bigquery.SchemaField("log_file", "STRING", mode="NULLABLE"),
            ])
        ]
        
        if job_config.schema:
            job_config.schema.extend(metadata_fields)
        else:
            job_config.schema = metadata_fields


def validate_file_format(bucket_name: str, file_name: str) -> bool:
    """
    Validate that the file is in expected format (CSV, JSON, etc.).
    
    Args:
        bucket_name: GCS bucket name
        file_name: File name
        
    Returns:
        True if file format is valid
    """
    valid_extensions = ['.csv', '.json', '.avro', '.parquet']
    return any(file_name.lower().endswith(ext) for ext in valid_extensions)


def get_table_schema(table_name: str) -> list:
    """
    Get predefined schema for specific table.
    This is useful when auto-detection is not desired.
    
    Args:
        table_name: BigQuery table name
        
    Returns:
        List of BigQuery schema fields
    """
    schemas = {
        'contributors': [
            bigquery.SchemaField("contributor_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("name", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("email", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
        ],
        'tasks': [
            bigquery.SchemaField("task_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("contributor_id", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("task_type", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("status", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
            bigquery.SchemaField("completed_at", "TIMESTAMP", mode="NULLABLE"),
        ],
        'task_feedback': [
            bigquery.SchemaField("feedback_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("task_id", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("rating", "INTEGER", mode="NULLABLE"),
            bigquery.SchemaField("comment", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
        ]
    }
    
    return schemas.get(table_name, [])
