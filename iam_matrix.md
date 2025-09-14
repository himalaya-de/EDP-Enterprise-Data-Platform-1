# IAM Access Matrix

This document provides a comprehensive view of IAM permissions across all datasets, buckets, and service accounts in the EDP (Enterprise Data Platform).

## Summary

| ✅ = Full Access | 🔍 = Read Only | ❌ = No Access |

## BigQuery Datasets Access Matrix

| Principal | contributor_bronze | contributor_silver | qualityaudit_bronze | qualityaudit_silver | programops_bronze | programops_silver | enterprise_gold | applemap_mart | googleads_mart | metaads_mart | googlesearch_mart |
|-----------|-------------------|-------------------|-------------------|-------------------|------------------|------------------|----------------|---------------|---------------|-------------|------------------|
| **Groups** |
| group-admins@example.com | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner | ✅ Owner |
| group-developers@example.com | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer | 🔍 Viewer |
| group-analysts@example.com | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | 🔍 Viewer | ❌ **No Access** | ❌ **No Access** | ❌ **No Access** | ❌ **No Access** |
| **Datastream SAs** |
| sa-datastream-contributor | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| sa-datastream-qualityaudit | ❌ No Access | ❌ No Access | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| sa-datastream-programops | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| **Cloud Function SAs** |
| sa-cf-contributor | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| sa-cf-qualityaudit | ❌ No Access | ❌ No Access | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| sa-cf-programops | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| **Transform SAs** |
| sa-bronze-to-silver | 🔍 Viewer | ✅ Editor | 🔍 Viewer | ✅ Editor | 🔍 Viewer | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| sa-silver-to-gold | ❌ No Access | 🔍 Viewer | ❌ No Access | 🔍 Viewer | ❌ No Access | 🔍 Viewer | ✅ Editor | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access |
| **Mart SAs** |
| sa-applemap-mart | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | 🔍 Viewer | ❌ No Access | ❌ No Access | ❌ No Access |
| sa-googleads-mart | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | 🔍 Viewer | ❌ No Access | ❌ No Access |
| sa-metaads-mart | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | 🔍 Viewer | ❌ No Access |
| sa-googlesearch-mart | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | ❌ No Access | 🔍 Viewer |

## GCS Staging Buckets Access Matrix

| Principal | staging_contributor | staging_qualityaudit | staging_programops |
|-----------|-------------------|-------------------|------------------|
| **Groups** |
| group-admins@example.com | ✅ Admin | ✅ Admin | ✅ Admin |
| group-developers@example.com | ❌ No Access | ❌ No Access | ❌ No Access |
| group-analysts@example.com | ❌ No Access | ❌ No Access | ❌ No Access |
| **Datastream SAs** |
| sa-datastream-contributor | ✅ Creator | ❌ No Access | ❌ No Access |
| sa-datastream-qualityaudit | ❌ No Access | ✅ Creator | ❌ No Access |
| sa-datastream-programops | ❌ No Access | ❌ No Access | ✅ Creator |
| **Cloud Function SAs** |
| sa-cf-contributor | 🔍 Viewer | ❌ No Access | ❌ No Access |
| sa-cf-qualityaudit | ❌ No Access | 🔍 Viewer | ❌ No Access |
| sa-cf-programops | ❌ No Access | ❌ No Access | 🔍 Viewer |

## Secret Manager Access Matrix

| Principal | contributor-mysql-connection | qualityaudit-postgres-connection | programops-mongo-connection |
|-----------|----------------------------|--------------------------------|---------------------------|
| **Datastream SAs** |
| sa-datastream-contributor | 🔍 Accessor | ❌ No Access | ❌ No Access |
| sa-datastream-qualityaudit | ❌ No Access | 🔍 Accessor | ❌ No Access |
| sa-datastream-programops | ❌ No Access | ❌ No Access | 🔍 Accessor |

## Project-Level IAM Roles

| Principal | bigquery.jobUser | Role Purpose |
|-----------|-----------------|--------------|
| group-developers@example.com | ✅ | Execute BigQuery queries |
| sa-datastream-* | ✅ | Execute BigQuery load jobs |
| sa-cf-* | ✅ | Execute BigQuery load jobs |
| sa-bronze-to-silver | ✅ | Execute transformation queries |
| sa-silver-to-gold | ✅ | Execute transformation queries |

## Key Security Principles Enforced

### ✅ Least Privilege Access
- Each service account has access only to the resources it needs
- No overly broad permissions granted

### ✅ Mart Isolation
- **Analysts have NO access to mart datasets** - only to `enterprise_gold`
- Each mart SA can only access its own mart dataset
- Cross-mart access is prevented

### ✅ Layer Separation
- Bronze layer: Only ingestion SAs have write access
- Silver layer: Only transformation SAs have write access  
- Gold layer: Only silver-to-gold SA has write access
- Marts: Only respective mart SAs have read access

### ✅ Data Pipeline Security
- Datastream SAs: Write only to their target bronze dataset
- Cloud Function SAs: Read from staging bucket, write to bronze dataset
- Transform SAs: Read from source layer, write to target layer
- Mart SAs: Read-only access to their designated mart

### ✅ Administrative Oversight
- Admin group has full access for operational needs
- Developer group has read access for troubleshooting
- Analyst group intentionally restricted from marts

## Service Account Ownership Labels

All service accounts are labeled with their owning team:

| Service Account | Owner Team |
|----------------|------------|
| sa-datastream-* | de platform |
| sa-cf-* | de platform |
| sa-bronze-to-silver | de platform |
| sa-silver-to-gold | de platform |
| sa-applemap-mart | applemaps |
| sa-googleads-mart | googleads |
| sa-metaads-mart | metaads |
| sa-googlesearch-mart | googlesearch |
| sa-bq-admin-ops | DataPlatformTeam |
| sa-monitoring | DataPlatformTeam |

## Compliance Notes

1. **Analyst Restriction**: The most critical requirement is that `group-analysts@example.com` has **NO ACCESS** to any `*_mart` datasets, only to `enterprise_gold`.

2. **Data Lineage**: Clear separation between bronze (raw), silver (cleaned), gold (dimensional), and mart (curated) layers.

3. **Audit Trail**: All data access is traceable through BigQuery audit logs with service account attribution.

4. **Secret Management**: Database credentials are stored in Secret Manager with restricted access.

5. **Network Security**: Datastream uses private connectivity (implementation dependent on network setup).
