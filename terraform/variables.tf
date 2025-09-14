variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner_team_name" {
  description = "Default team name for resource labeling"
  type        = string
  default     = "DataPlatformTeam"
}

# Secret Manager secret names for database connections
variable "secret_contributor_db" {
  description = "Secret Manager secret name for contributor MySQL connection"
  type        = string
  default     = "contributor-mysql-connection"
}

variable "secret_qualityaudit_db" {
  description = "Secret Manager secret name for quality audit Postgres connection"
  type        = string
  default     = "qualityaudit-postgres-connection"
}

variable "secret_programops_db" {
  description = "Secret Manager secret name for program ops MongoDB connection"
  type        = string
  default     = "programops-mongo-connection"
}

# IAM Groups
variable "group_admins" {
  description = "Admin group email"
  type        = string
  default     = "group-admins@example.com"
}

variable "group_developers" {
  description = "Developer group email"
  type        = string
  default     = "group-developers@example.com"
}

variable "group_analysts" {
  description = "Analyst group email"
  type        = string
  default     = "group-analysts@example.com"
}

# Optional flags
variable "enable_datastream" {
  description = "Enable Datastream resources (requires additional setup)"
  type        = bool
  default     = false
}

variable "enable_cloud_functions" {
  description = "Enable Cloud Functions deployment"
  type        = bool
  default     = true
}
