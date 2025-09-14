"""
=============================================================================
CLOUD FUNCTION: Quality Audit Staging to Bronze Data Pipeline
=============================================================================

DATA LINEAGE DOCUMENTATION:
----------------------------
SOURCE: GCS Staging Bucket (gs://hackathon2025-01-staging-qualityaudit-demo/)
├── File Types: CSV, JSON, Parquet, Avro
├── Naming Convention: {table_name}_{timestamp}.{extension}
├── Expected Tables: audits, audit_issues

DESTINATION: BigQuery Bronze Dataset
├── Project: hackathon2025-01
├── Dataset: qualityaudit_bronze  
├── Tables: audits, audit_issues
├── Schema: Auto-detected + Datastream metadata fields

LINEAGE FLOW:
1. File Upload → GCS Staging Bucket
2. GCS Event Trigger → Cloud Function (THIS)
3. Cloud Function → BigQuery Bronze Tables
4. DOWNSTREAM: Bronze → Silver → Gold → Data Marts

DOWNSTREAM CONSUMERS:
- Silver Layer: qualityaudit_silver.{audits, audit_issues}
- Gold Layer: enterprise_gold.fact_audit, enterprise_gold.dim_audit_issue
- Data Marts: applemap_mart, googleads_mart, metaads_mart, googlesearch_mart

DATA DOMAINS: quality-assurance, audit-tracking, issue-management
DATA CLASSIFICATION: Internal (no PII)
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
DATASET_ID = os.environ.get('DATASET_ID', 'qualityaudit_bronze')
TABLE_MAPPING = json.loads(os.environ.get('TABLE_MAPPING', '{}'))

# LINEAGE METADATA CONSTANTS
LINEAGE_METADATA = {
    'pipeline_name': 'qualityaudit-staging-to-bronze',
    'source_system': 'gcs-staging-bucket',
    'destination_system': 'bigquery-bronze-layer',
    'data_domain': 'quality-assurance',
    'processing_tier': 'bronze-ingestion',
    'downstream_datasets': ['qualityaudit_silver', 'enterprise_gold'],
    'downstream_marts': ['applemap_mart', 'googleads_mart', 'metaads_mart', 'googlesearch_mart'],
    'data_classification': 'internal',
    'contains_pii': False
}

def main(event: Dict[str, Any], context: Any) -> None:
    """
    Cloud Function triggered by GCS object finalization.
    Loads quality audit staging files into BigQuery bronze dataset.
    
    Args:
        event: Cloud Storage event data
        context: Cloud Function context
    """
    try:
        # Extract file information from event
        bucket_name = event['bucket']
        file_name = event['name']
        
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
        
        # Log success
        destination_table = client.get_table(table_ref)
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
    # Assumes file naming convention like: audits_YYYYMMDD_HHMMSS.csv
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
        'audits': [
            bigquery.SchemaField("audit_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("auditor_id", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("audit_type", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("status", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
            bigquery.SchemaField("completed_at", "TIMESTAMP", mode="NULLABLE"),
        ],
        'audit_issues': [
            bigquery.SchemaField("issue_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("audit_id", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("severity", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("description", "STRING", mode="NULLABLE"),
            bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
        ]
    }
    
    return schemas.get(table_name, [])
