#!/bin/bash

# Enterprise Data Platform - Terraform CI/CD Script
# This script runs Terraform validation, planning, and optional deployment
# Usage: ./terraform-ci.sh [plan|apply|destroy]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ACTION="${1:-plan}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check terraform version
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: $TF_VERSION"
    
    # Check if gcloud is installed and authenticated
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        exit 1
    fi
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        log_error "Not authenticated with gcloud. Run: gcloud auth application-default login"
        exit 1
    fi
    
    # Check if project is set
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
    if [[ -z "$PROJECT_ID" ]]; then
        log_error "GCP project not set. Run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    log_info "Using GCP project: $PROJECT_ID"
    
    # Check if jq is available (for JSON parsing)
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed. Some features may not work properly."
    fi
    
    log_success "Prerequisites check passed"
}

# Validate Terraform configuration
validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    cd "$TERRAFORM_DIR"
    
    # Format check
    log_info "Checking Terraform formatting..."
    if ! terraform fmt -check=true -diff=true; then
        log_error "Terraform files are not properly formatted. Run: terraform fmt"
        return 1
    fi
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    if ! terraform validate; then
        log_error "Terraform validation failed"
        return 1
    fi
    
    log_success "Terraform validation passed"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Copy terraform.tfvars.example and fill in values."
        exit 1
    fi
    
    # Initialize
    if ! terraform init -input=false; then
        log_error "Terraform initialization failed"
        exit 1
    fi
    
    log_success "Terraform initialized"
}

# Run Terraform plan
plan_terraform() {
    log_info "Running Terraform plan..."
    
    cd "$TERRAFORM_DIR"
    
    # Create plan output
    PLAN_FILE="terraform-plan-$(date +%Y%m%d-%H%M%S).tfplan"
    
    if terraform plan -input=false -out="$PLAN_FILE"; then
        log_success "Terraform plan completed successfully"
        log_info "Plan saved to: $PLAN_FILE"
        
        # Show plan summary if jq is available
        if command -v jq &> /dev/null; then
            log_info "Plan summary:"
            terraform show -json "$PLAN_FILE" | jq -r '
                .resource_changes[]? | 
                select(.change.actions != ["no-op"]) | 
                "\(.change.actions[0]): \(.address)"
            ' | sort
        fi
        
        return 0
    else
        log_error "Terraform plan failed"
        return 1
    fi
}

# Apply Terraform changes
apply_terraform() {
    log_info "Applying Terraform changes..."
    
    cd "$TERRAFORM_DIR"
    
    # Find the latest plan file
    PLAN_FILE=$(ls -t terraform-plan-*.tfplan 2>/dev/null | head -n1 || echo "")
    
    if [[ -n "$PLAN_FILE" ]]; then
        log_info "Using plan file: $PLAN_FILE"
        terraform apply -input=false "$PLAN_FILE"
    else
        log_warning "No plan file found. Running apply without plan file."
        terraform apply -input=false -auto-approve
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Terraform apply completed successfully"
        
        # Show outputs
        log_info "Infrastructure outputs:"
        terraform output -json | jq -r 'to_entries[] | "\(.key): \(.value.value)"'
        
        return 0
    else
        log_error "Terraform apply failed"
        return 1
    fi
}

# Destroy Terraform infrastructure
destroy_terraform() {
    log_warning "This will DESTROY all infrastructure!"
    read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log_info "Destruction cancelled"
        return 0
    fi
    
    log_info "Destroying Terraform infrastructure..."
    
    cd "$TERRAFORM_DIR"
    
    if terraform destroy -input=false -auto-approve; then
        log_success "Infrastructure destroyed successfully"
        return 0
    else
        log_error "Terraform destroy failed"
        return 1
    fi
}

# Run security checks (optional)
security_check() {
    log_info "Running security checks..."
    
    cd "$TERRAFORM_DIR"
    
    # Check for hardcoded secrets (basic regex)
    log_info "Checking for potential secrets..."
    if grep -r -i -n \
        -e "password.*=" \
        -e "secret.*=" \
        -e "api[_-]key" \
        -e "access[_-]key" \
        --include="*.tf" \
        --include="*.tfvars" \
        . 2>/dev/null; then
        log_warning "Potential secrets found in Terraform files. Please review."
    else
        log_success "No obvious secrets found in Terraform files"
    fi
    
    # Check for overly permissive IAM
    log_info "Checking for overly permissive IAM roles..."
    if grep -r -n "roles/owner\|roles/editor\|roles/\*" --include="*.tf" . 2>/dev/null; then
        log_warning "Potentially overly permissive IAM roles found. Please review."
    else
        log_success "No overly permissive IAM roles found"
    fi
}

# Generate deployment report
generate_report() {
    log_info "Generating deployment report..."
    
    cd "$TERRAFORM_DIR"
    
    REPORT_FILE="deployment-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$REPORT_FILE" << EOF
# EDP Deployment Report

**Date:** $(date)
**Project:** $(gcloud config get-value project 2>/dev/null)
**Region:** $(terraform output -raw project_info 2>/dev/null | jq -r '.region' 2>/dev/null || echo "unknown")
**Environment:** $(terraform output -raw project_info 2>/dev/null | jq -r '.environment' 2>/dev/null || echo "unknown")

## Infrastructure Components

### Service Accounts
$(terraform output -json service_account_emails 2>/dev/null | jq -r 'to_entries[] | "- \(.key): \(.value)"' 2>/dev/null || echo "- Unable to retrieve service accounts")

### BigQuery Datasets
$(terraform output -json bigquery_datasets 2>/dev/null | jq -r 'to_entries[] | "- \(.key): \(.value)"' 2>/dev/null || echo "- Unable to retrieve datasets")

### GCS Buckets
$(terraform output -json gcs_buckets 2>/dev/null | jq -r 'to_entries[] | "- \(.key): \(.value)"' 2>/dev/null || echo "- Unable to retrieve buckets")

## Next Steps

1. Create database connection secrets in Secret Manager
2. Configure source databases for Datastream
3. Deploy SQL schemas using create_gold_schema.sql
4. Set up Cloud Scheduler for data pipeline automation
5. Configure monitoring and alerting

## Security Notes

- All service accounts follow least-privilege principle
- Analysts have NO access to mart datasets (only enterprise_gold)
- Database credentials stored in Secret Manager
- Audit logging enabled on BigQuery

For more information, see:
- IAM Matrix: ../iam_matrix.md
- Datastream Setup: ../datastream/placeholders.txt
- Architecture Documentation: ../terraform/README.md
EOF

    log_success "Deployment report generated: $REPORT_FILE"
}

# Cleanup old plan files
cleanup() {
    log_info "Cleaning up old plan files..."
    
    cd "$TERRAFORM_DIR"
    
    # Keep only the 5 most recent plan files
    ls -t terraform-plan-*.tfplan 2>/dev/null | tail -n +6 | xargs rm -f
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting EDP Terraform CI/CD pipeline..."
    log_info "Action: $ACTION"
    
    check_prerequisites
    init_terraform
    validate_terraform
    security_check
    
    case "$ACTION" in
        "plan")
            plan_terraform
            ;;
        "apply")
            plan_terraform && apply_terraform && generate_report
            ;;
        "destroy")
            destroy_terraform
            ;;
        *)
            log_error "Unknown action: $ACTION"
            log_info "Usage: $0 [plan|apply|destroy]"
            exit 1
            ;;
    esac
    
    cleanup
    log_success "CI/CD pipeline completed successfully!"
}

# Run main function with error handling
if ! main "$@"; then
    log_error "CI/CD pipeline failed!"
    exit 1
fi
