# Enterprise Data Platform - Terraform Infrastructure

This directory contains Terraform configuration files to deploy the complete Enterprise Data Platform (EDP) on Google Cloud Platform.

## Architecture Overview

The EDP implements a modern data lake architecture with:
- **Bronze Layer**: Raw ingested data from source systems
- **Silver Layer**: Cleaned and validated data 
- **Gold Layer**: Enterprise dimensional model
- **Data Marts**: Curated views for specific teams

## Infrastructure Components

- **BigQuery**: Data warehouse with datasets for bronze, silver, gold, and mart layers
- **Cloud Storage**: Staging buckets for file-based ingestion
- **Cloud Functions**: Event-driven data processing
- **Datastream**: Real-time CDC from MySQL, PostgreSQL, and MongoDB
- **IAM**: Least-privilege access controls
- **Service Accounts**: Dedicated accounts for each workload

## Prerequisites

1. **GCP Project**: Active GCP project with billing enabled
2. **APIs**: The following APIs will be enabled automatically:
   - BigQuery API
   - Cloud Storage API
   - Cloud Functions API
   - Datastream API
   - Secret Manager API
   - IAM API
   - Cloud Build API

3. **Terraform**: Version >= 1.0
4. **Authentication**: 
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

5. **Permissions**: Your user/service account needs:
   - Project Editor or custom role with:
     - BigQuery Admin
     - Storage Admin
     - Cloud Functions Admin
     - IAM Admin
     - Service Account Admin
     - Secret Manager Admin

## Quick Start

1. **Clone and Navigate:**
   ```bash
   cd terraform/
   ```

2. **Copy Example Variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit Variables:**
   ```bash
   nano terraform.tfvars
   ```
   
   Fill in required values:
   ```hcl
   project_id = "your-gcp-project-id"
   region     = "us-central1"
   env        = "dev"
   
   # IAM Groups
   group_admins     = "group-admins@yourcompany.com"
   group_developers = "group-developers@yourcompany.com"
   group_analysts   = "group-analysts@yourcompany.com"
   
   # Optional: Enable features
   enable_datastream      = false  # Set to true after configuring databases
   enable_cloud_functions = true
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Plan Deployment:**
   ```bash
   terraform plan
   ```

6. **Deploy Infrastructure:**
   ```bash
   terraform apply
   ```

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_id` | GCP Project ID | `"my-data-platform"` |
| `region` | GCP region for resources | `"us-central1"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `env` | Environment name | `"dev"` |
| `owner_team_name` | Default team for labeling | `"DataPlatformTeam"` |
| `group_admins` | Admin group email | `"group-admins@example.com"` |
| `group_developers` | Developer group email | `"group-developers@example.com"` |
| `group_analysts` | Analyst group email | `"group-analysts@example.com"` |
| `enable_datastream` | Enable Datastream resources | `false` |
| `enable_cloud_functions` | Enable Cloud Functions | `true` |

### Database Secret Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `secret_contributor_db` | MySQL connection secret | `"contributor-mysql-connection"` |
| `secret_qualityaudit_db` | PostgreSQL connection secret | `"qualityaudit-postgres-connection"` |
| `secret_programops_db` | MongoDB connection secret | `"programops-mongo-connection"` |

## Post-Deployment Setup

### 1. Create Database Secrets

Before enabling Datastream, create the required secrets:

```bash
# Contributor MySQL
gcloud secrets create contributor-mysql-connection \
  --data-file=secrets/mysql-connection.json

# Quality Audit PostgreSQL  
gcloud secrets create qualityaudit-postgres-connection \
  --data-file=secrets/postgres-connection.json

# Program Ops MongoDB
gcloud secrets create programops-mongo-connection \
  --data-file=secrets/mongo-connection.json
```

See `../datastream/placeholders.txt` for secret format details.

### 2. Initialize Gold Schema

Run the SQL script to create dimensional model tables:

```bash
# Replace PROJECT_ID with your actual project ID
sed 's/${PROJECT_ID}/your-project-id/g' ../sql/create_gold_schema.sql > create_gold_schema_final.sql

# Execute in BigQuery
bq query --use_legacy_sql=false < create_gold_schema_final.sql
```

### 3. Deploy Cloud Functions

If you enabled Cloud Functions, deploy them:

```bash
# Set environment
export PROJECT_ID="your-project-id"
export REGION="us-central1"

# Deploy contributor function
cd ../cloud_functions/cf_contributor_staging_to_bronze
gcloud functions deploy cf-contributor-staging-to-bronze \
  --runtime python39 \
  --trigger-resource ${PROJECT_ID}-staging-contributor-dev \
  --trigger-event google.storage.object.finalize \
  --service-account sa-cf-contributor@${PROJECT_ID}.iam.gserviceaccount.com \
  --region ${REGION}

# Repeat for other functions...
```

### 4. Set Up Data Pipeline Scheduling

Create Cloud Scheduler jobs for data transformations:

```bash
# Bronze to Silver (daily at 2 AM)
gcloud scheduler jobs create http bronze-to-silver-job \
  --schedule="0 2 * * *" \
  --uri="https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT_ID}/jobs" \
  --http-method=POST \
  --headers="Authorization=Bearer $(gcloud auth print-access-token)" \
  --message-body='{
    "configuration": {
      "query": {
        "query": "CALL `'${PROJECT_ID}'.contributor_silver.run_all_bronze_to_silver_transforms`()",
        "useLegacySql": false
      }
    }
  }'

# Silver to Gold (daily at 4 AM)  
gcloud scheduler jobs create http silver-to-gold-job \
  --schedule="0 4 * * *" \
  --uri="https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT_ID}/jobs" \
  --http-method=POST \
  --headers="Authorization=Bearer $(gcloud auth print-access-token)" \
  --message-body='{
    "configuration": {
      "query": {
        "query": "CALL `'${PROJECT_ID}'.enterprise_gold.run_all_silver_to_gold_transforms`()",
        "useLegacySql": false
      }
    }
  }'
```

### 5. Enable Datastream (Optional)

After configuring source databases:

1. Update `terraform.tfvars`:
   ```hcl
   enable_datastream = true
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

## File Structure

```
terraform/
├── provider.tf              # Provider configuration and API enablement
├── variables.tf             # Input variable definitions
├── service_accounts.tf      # Service account creation and labeling
├── gcs.tf                  # GCS staging buckets and IAM
├── bigquery.tf             # BigQuery datasets and tables
├── iam_bindings.tf         # Dataset-level IAM permissions
├── datastream.tf           # Datastream connection profiles and streams
├── cloudfunctions.tf       # Cloud Functions deployment
├── outputs.tf              # Output values
├── terraform.tfvars.example # Example variables file
└── README.md               # This file
```

## Validation and Testing

### 1. Terraform Validation

```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Security scan (optional)
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq > plan.json
# Use tools like checkov or tfsec for security scanning
```

### 2. Infrastructure Testing

```bash
# Verify BigQuery datasets
bq ls

# Check service accounts
gcloud iam service-accounts list

# Test bucket access
gsutil ls gs://$(terraform output -raw gcs_buckets | jq -r '.staging_contributor')

# Verify IAM bindings
gcloud projects get-iam-policy ${PROJECT_ID}
```

### 3. Data Pipeline Testing

```bash
# Test bronze to silver transformation
bq query --use_legacy_sql=false \
  "CALL \`${PROJECT_ID}.contributor_silver.transform_contributors\`()"

# Test silver to gold transformation  
bq query --use_legacy_sql=false \
  "CALL \`${PROJECT_ID}.enterprise_gold.build_dim_contributor\`()"

# Verify data marts
bq query --use_legacy_sql=false \
  "SELECT COUNT(*) FROM \`${PROJECT_ID}.applemap_mart.task_summary\`"
```

## Troubleshooting

### Common Issues

1. **API Not Enabled:**
   ```
   Error: googleapi: Error 403: BigQuery API has not been used
   ```
   **Solution:** APIs are enabled automatically, but may take a few minutes. Wait and retry.

2. **Permission Denied:**
   ```
   Error: googleapi: Error 403: Permission denied
   ```
   **Solution:** Ensure your user has the required IAM roles listed in Prerequisites.

3. **Service Account Creation Failed:**
   ```
   Error: Error creating service account
   ```
   **Solution:** Check if service account limit is reached or if the name already exists.

4. **BigQuery Dataset Already Exists:**
   ```
   Error: googleapi: Error 409: Already Exists: Dataset
   ```
   **Solution:** Either delete existing datasets or import them into Terraform state.

### Debugging Commands

```bash
# View Terraform logs
export TF_LOG=DEBUG
terraform apply

# Check GCP quotas
gcloud compute project-info describe

# View IAM policies
gcloud projects get-iam-policy ${PROJECT_ID} --format=json

# Check service account permissions
gcloud iam service-accounts get-iam-policy \
  sa-bronze-to-silver@${PROJECT_ID}.iam.gserviceaccount.com
```

## Cleanup

To destroy all infrastructure:

```bash
# Remove Cloud Scheduler jobs first (if created)
gcloud scheduler jobs delete bronze-to-silver-job --quiet
gcloud scheduler jobs delete silver-to-gold-job --quiet

# Destroy Terraform resources
terraform destroy

# Clean up any remaining resources manually if needed
```

**Warning:** This will permanently delete all data in BigQuery datasets and GCS buckets.

## Cost Estimation

| Resource | Estimated Monthly Cost | Notes |
|----------|----------------------|-------|
| BigQuery | $50-200 | Depends on data volume and queries |
| Cloud Storage | $10-50 | Depends on staging data volume |
| Cloud Functions | $5-20 | Based on invocation frequency |
| Datastream | $100-500 | Based on CDC data volume |
| **Total** | **$165-770** | Scales with usage |

Use the [GCP Pricing Calculator](https://cloud.google.com/products/calculator) for detailed estimates.

## Security Best Practices

1. **Least Privilege**: Service accounts have minimal required permissions
2. **Secret Management**: Database credentials stored in Secret Manager
3. **Network Security**: Use private connectivity for Datastream
4. **Audit Logging**: Enable BigQuery audit logs
5. **Regular Reviews**: Periodically review IAM permissions
6. **Data Classification**: Implement data classification labels
7. **Encryption**: All data encrypted at rest and in transit

## Support

For issues or questions:
1. Check this README and troubleshooting section
2. Review the IAM matrix in `../iam_matrix.md`
3. Check Datastream setup in `../datastream/placeholders.txt`
4. Review Cloud Function logs in Cloud Console
