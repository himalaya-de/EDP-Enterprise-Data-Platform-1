# Enterprise Data Platform (EDP)

A complete GCP-based data lake architecture with least-privilege IAM, implementing bronze-silver-gold data layers with curated data marts.

## Architecture Overview

The EDP implements a modern medallion architecture on Google Cloud Platform:

- **Bronze Layer**: Raw data ingested from source systems (MySQL, PostgreSQL, MongoDB)
- **Silver Layer**: Cleaned and validated data with quality checks
- **Gold Layer**: Enterprise dimensional model with facts and dimensions  
- **Data Marts**: Team-specific curated views with restricted access

### Key Features

- ✅ **Least-privilege IAM**: Service accounts with minimal required permissions
- ✅ **Secure data marts**: Analysts cannot access marts, only enterprise gold
- ✅ **Real-time CDC**: Datastream integration for MySQL/PostgreSQL
- ✅ **Event-driven processing**: Cloud Functions for file-based ingestion
- ✅ **Infrastructure as Code**: Complete Terraform deployment
- ✅ **Data quality**: Built-in validation and cleansing
- ✅ **Team isolation**: Each team's service account accesses only their mart

## Quick Start

1. **Clone and Setup:**
   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy Infrastructure:**
   ```bash
   ./ci/terraform-ci.sh plan
   ./ci/terraform-ci.sh apply
   ```

3. **Initialize Schema:**
   ```bash
   bq query --use_legacy_sql=false < sql/create_gold_schema.sql
   ```

## Project Structure

```
EDP-Enterprise-Data-Platform/
├── terraform/                 # Infrastructure as Code
│   ├── provider.tf            # GCP provider and APIs
│   ├── variables.tf           # Input variables
│   ├── service_accounts.tf    # Service account definitions
│   ├── gcs.tf                # GCS staging buckets
│   ├── bigquery.tf           # BigQuery datasets and tables
│   ├── iam_bindings.tf       # Least-privilege IAM policies
│   ├── datastream.tf         # CDC configuration
│   ├── cloudfunctions.tf     # Event-driven functions
│   ├── outputs.tf            # Infrastructure outputs
│   └── README.md             # Deployment guide
├── cloud_functions/           # Staging to bronze ingestion
│   ├── cf_contributor_staging_to_bronze/
│   ├── cf_qualityaudit_staging_to_bronze/
│   └── cf_programops_staging_to_bronze/
├── sql/                      # Data transformation scripts
│   ├── bronze_to_silver.sql  # Data cleaning procedures
│   ├── silver_to_gold.sql    # Dimensional modeling
│   ├── create_gold_schema.sql # Table definitions
│   └── example_mart_views.sql # Team-specific views
├── ci/                       # CI/CD automation
│   └── terraform-ci.sh       # Deployment script
├── datastream/               # CDC setup instructions
│   └── placeholders.txt      # Database configuration
├── iam_matrix.md            # Security access matrix
└── README.md                # This file
```

## Data Flow

```
Source DBs → Datastream → Bronze → Silver → Gold → Marts
    ↓                        ↓       ↓       ↓       ↓
 CDC/Files              Raw Data  Clean  Facts  Curated
                                          Dims   Views
```

### Team Access Model

| Layer | Admins | Developers | Analysts | Mart SAs |
|-------|---------|-----------|----------|----------|
| Bronze | ✅ Full | 🔍 Read | ❌ None | ❌ None |
| Silver | ✅ Full | 🔍 Read | ❌ None | ❌ None |
| Gold | ✅ Full | 🔍 Read | 🔍 Read | ❌ None |
| Marts | ✅ Full | 🔍 Read | ❌ **None** | 🔍 Own Only |

## Created Resources

### BigQuery Datasets
- `contributor_bronze/silver` - Contributor data layers
- `qualityaudit_bronze/silver` - Quality audit data layers  
- `programops_bronze/silver` - Program ops data layers
- `enterprise_gold` - Dimensional model
- `applemap_mart` - Apple Maps team views
- `googleads_mart` - Google Ads team views
- `metaads_mart` - Meta Ads team views
- `googlesearch_mart` - Google Search team views

### Service Accounts (with team labels)
- `sa-datastream-*` - CDC ingestion (de platform)
- `sa-cf-*` - File processing (de platform)
- `sa-bronze-to-silver` - Data cleaning (de platform)
- `sa-silver-to-gold` - Dimensional modeling (de platform)
- `sa-*-mart` - Team-specific access (respective teams)

### Infrastructure Components
- GCS staging buckets for file-based ingestion
- Cloud Functions for event-driven processing
- Datastream for real-time CDC
- IAM policies enforcing least-privilege access

## Security Highlights

- **Mart Isolation**: Analysts explicitly blocked from accessing mart datasets
- **Least Privilege**: Each SA has minimal required permissions
- **Credential Security**: DB passwords stored in Secret Manager
- **Network Security**: Private connectivity for Datastream
- **Audit Logging**: Full access tracking via BigQuery logs

## Getting Started

See the detailed guides:
- [Terraform Deployment](terraform/README.md)
- [IAM Access Matrix](iam_matrix.md)
- [Datastream Setup](datastream/placeholders.txt)

## Architecture Decisions

1. **Dataset-level IAM**: More granular than project-level permissions
2. **Service Account per Function**: Better security isolation
3. **No Analyst Mart Access**: Prevents data silos and ensures governance
4. **Bronze-Silver-Gold**: Industry standard medallion architecture
5. **Event-driven Processing**: Scalable and cost-effective
