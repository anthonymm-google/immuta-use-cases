output "project_id" {
  value       = var.project_id
  description = "Google Cloud Project ID"
}

output "procurement_taxonomy_id" {
  value       = google_data_catalog_taxonomy.procurement_taxonomy.id
  description = "Procurement Taxonomy ID"
}

output "hr_taxonomy_id" {
  value       = google_data_catalog_taxonomy.hr_taxonomy.id
  description = "HR Taxonomy ID"
}

output "confidential_ssn_policy_tag" {
  value       = google_data_catalog_policy_tag.confidential_ssn_taxid.name
  description = "Policy Tag Resource Name for SSN/TaxID"
}

output "hr_separation_policy_tag" {
  value       = google_data_catalog_policy_tag.hr_separation_confidential.name
  description = "Policy Tag Resource Name for HR Separation"
}

output "hr_pii_policy_tag" {
  value       = google_data_catalog_policy_tag.hr_pii_high_sensitivity.name
  description = "Policy Tag Resource Name for High Sensitivity PII"
}
