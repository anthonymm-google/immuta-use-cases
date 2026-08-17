variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID"
  default     = "amm-immuta-gcp-demo"
}

variable "region" {
  type        = string
  description = "The Google Cloud region for BigQuery and Dataplex"
  default     = "us-central1"
}

variable "procurement_readers" {
  type        = list(string)
  description = "List of IAM members with fine-grained access to Procurement TaxIDs"
  default     = ["user:procurement@anthonymm.altostrat.com"]
}

variable "hr_readers" {
  type        = list(string)
  description = "List of IAM members with fine-grained access to HR sensitive and PII data"
  default     = ["user:hr@anthonymm.altostrat.com"]
}

variable "enable_temporary_auditor" {
  type        = bool
  description = "Whether to create a time-phased conditional IAM grant"
  default     = true
}

variable "temporary_auditor_email" {
  type        = string
  description = "IAM member for temporary time-bounded auditor"
  default     = "user:admin@anthonymm.altostrat.com"
}

variable "temporary_access_expiration_timestamp" {
  type        = string
  description = "RFC3339 timestamp when temporary access expires (e.g., 30 days from project start)"
  default     = "2026-09-17T00:00:00Z"
}
