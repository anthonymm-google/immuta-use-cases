terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. BigQuery Datasets
resource "google_bigquery_dataset" "procurement_data" {
  dataset_id                  = "procurement_data"
  friendly_name               = "Procurement & Vendor Data"
  description                 = "Contains vendor master, purchase orders, and tax profiles"
  location                    = var.region
  default_table_expiration_ms = null
  labels = {
    domain     = "procurement"
    governance = "gcp_native"
  }
}

resource "google_bigquery_dataset" "hr_data" {
  dataset_id                  = "hr_data"
  friendly_name               = "Human Resources Data"
  description                 = "Contains employee profiles, directory, lifecycle, and PII vault"
  location                    = var.region
  default_table_expiration_ms = null
  labels = {
    domain     = "human_resources"
    governance = "gcp_native"
  }
}

resource "google_bigquery_dataset" "audit_logging" {
  dataset_id                  = "audit_logging"
  friendly_name               = "Security & Break-Glass Audit Logs"
  description                 = "Immutable audit logs for privileged and break-glass data access"
  location                    = var.region
  default_table_expiration_ms = null
  labels = {
    domain     = "compliance_audit"
    governance = "gcp_native"
  }
}

# 2. Dataplex / Data Catalog Taxonomies & Policy Tags
resource "google_data_catalog_taxonomy" "procurement_taxonomy" {
  provider               = google
  region                 = var.region
  display_name           = "Procurement_Security_Taxonomy"
  description            = "Taxonomy for procurement, vendor tax identifiers, and SSN governance"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

resource "google_data_catalog_policy_tag" "confidential_ssn_taxid" {
  provider     = google
  taxonomy     = google_data_catalog_taxonomy.procurement_taxonomy.id
  display_name = "Confidential_SSN_TaxID"
  description  = "Policy tag for Tax IDs containing SSNs or EINs"
}

resource "google_data_catalog_taxonomy" "hr_taxonomy" {
  provider               = google
  region                 = var.region
  display_name           = "HR_Security_Taxonomy"
  description            = "Taxonomy for HR sensitive attributes, separation data, and high-risk PII"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

resource "google_data_catalog_policy_tag" "hr_separation_confidential" {
  provider     = google
  taxonomy     = google_data_catalog_taxonomy.hr_taxonomy.id
  display_name = "HR_Separation_Confidential"
  description  = "Policy tag for sensitive employee leaving reasons, separation dates, and severance"
}

resource "google_data_catalog_policy_tag" "hr_pii_high_sensitivity" {
  provider     = google
  taxonomy     = google_data_catalog_taxonomy.hr_taxonomy.id
  display_name = "PII_High_Sensitivity"
  description  = "Policy tag for SSN, Driver License, and Passport numbers across HR records"
}

# 3. BigQuery Dynamic Data Policies (Masking Rules)
resource "google_bigquery_datapolicy_data_policy" "mask_tax_id" {
  location         = var.region
  data_policy_id   = "dp_procurement_taxid_mask"
  policy_tag       = google_data_catalog_policy_tag.confidential_ssn_taxid.name
  data_policy_type = "DATA_MASKING_POLICY"
  data_masking_policy {
    predefined_expression = "LAST_FOUR_CHARACTERS"
  }
}

resource "google_bigquery_datapolicy_data_policy" "mask_hr_separation" {
  location         = var.region
  data_policy_id   = "dp_hr_separation_mask"
  policy_tag       = google_data_catalog_policy_tag.hr_separation_confidential.name
  data_policy_type = "DATA_MASKING_POLICY"
  data_masking_policy {
    predefined_expression = "ALWAYS_NULL"
  }
}

resource "google_bigquery_datapolicy_data_policy" "mask_high_pii" {
  location         = var.region
  data_policy_id   = "dp_pii_high_sensitivity_mask"
  policy_tag       = google_data_catalog_policy_tag.hr_pii_high_sensitivity.name
  data_policy_type = "DATA_MASKING_POLICY"
  data_masking_policy {
    predefined_expression = "LAST_FOUR_CHARACTERS"
  }
}

# 4. BigQuery Tables with Policy Tagged Columns
resource "google_bigquery_table" "vendor_profiles" {
  dataset_id          = google_bigquery_dataset.procurement_data.dataset_id
  table_id            = "vendor_profiles"
  deletion_protection = false
  schema = jsonencode([
    {
      name        = "vendor_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique vendor identifier"
    },
    {
      name        = "vendor_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Legal business name or individual contractor name"
    },
    {
      name        = "vendor_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "CORPORATE, INDIVIDUAL_CONTRACTOR, or SOLE_PROPRIETOR"
    },
    {
      name        = "tax_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Tax Identifier (EIN for businesses, SSN for sole proprietors/individuals)"
      policyTags = {
        names = [google_data_catalog_policy_tag.confidential_ssn_taxid.name]
      }
    },
    {
      name        = "spend_amount_ytd"
      type        = "NUMERIC"
      mode        = "NULLABLE"
      description = "Year to date spend in USD"
    },
    {
      name        = "payment_terms"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Net 30, Net 60, etc."
    },
    {
      name        = "created_at"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Record creation timestamp"
    }
  ])
  depends_on = [google_bigquery_datapolicy_data_policy.mask_tax_id]
}

resource "google_bigquery_table" "employee_directory" {
  dataset_id          = google_bigquery_dataset.hr_data.dataset_id
  table_id            = "employee_directory"
  deletion_protection = false
  schema = jsonencode([
    {
      name        = "employee_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique employee identifier"
    },
    {
      name        = "full_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Full employee name"
    },
    {
      name        = "department"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Department name"
    },
    {
      name        = "job_title"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Job title"
    },
    {
      name        = "work_email"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Official corporate work email (always public internally)"
    },
    {
      name        = "pii_sharing_opted_in"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Privacy consent flag: TRUE if employee consents to sharing personal contact info internally; FALSE if opted out"
    },
    {
      name        = "personal_phone"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Personal cell phone number"
    },
    {
      name        = "personal_email"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Personal private email"
    },
    {
      name        = "home_city"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Home residence city"
    },
    {
      name        = "emergency_contact_phone"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Emergency contact phone"
    }
  ])
}

resource "google_bigquery_table" "employee_lifecycle" {
  dataset_id          = google_bigquery_dataset.hr_data.dataset_id
  table_id            = "employee_lifecycle"
  deletion_protection = false
  schema = jsonencode([
    {
      name        = "employee_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Employee ID"
    },
    {
      name        = "employee_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Employee name"
    },
    {
      name        = "hire_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Hire date"
    },
    {
      name        = "employment_status"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "ACTIVE, ON_LEAVE, or SEPARATED"
    },
    {
      name        = "separation_date"
      type        = "DATE"
      mode        = "NULLABLE"
      description = "Date of employee departure (Confidential HR attribute)"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_separation_confidential.name]
      }
    },
    {
      name        = "separation_reason"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Reason for leaving: Resignation, Termination, Layoff, Retirement"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_separation_confidential.name]
      }
    },
    {
      name        = "severance_amount"
      type        = "NUMERIC"
      mode        = "NULLABLE"
      description = "Severance package compensation in USD"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_separation_confidential.name]
      }
    },
    {
      name        = "exit_interview_notes"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Confidential HR exit notes and feedback"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_separation_confidential.name]
      }
    }
  ])
  depends_on = [google_bigquery_datapolicy_data_policy.mask_hr_separation]
}

resource "google_bigquery_table" "employee_pii_vault" {
  dataset_id          = google_bigquery_dataset.hr_data.dataset_id
  table_id            = "employee_pii_vault"
  deletion_protection = false
  schema = jsonencode([
    {
      name        = "employee_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Employee ID"
    },
    {
      name        = "full_legal_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Full legal name as on government ID"
    },
    {
      name        = "ssn"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "US Social Security Number"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_pii_high_sensitivity.name]
      }
    },
    {
      name        = "drivers_license_num"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Driver License Number"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_pii_high_sensitivity.name]
      }
    },
    {
      name        = "passport_num"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Passport Identification Number"
      policyTags = {
        names = [google_data_catalog_policy_tag.hr_pii_high_sensitivity.name]
      }
    },
    {
      name        = "dob"
      type        = "DATE"
      mode        = "NULLABLE"
      description = "Date of Birth"
    }
  ])
  depends_on = [google_bigquery_datapolicy_data_policy.mask_high_pii]
}

resource "google_bigquery_table" "break_glass_access_log" {
  dataset_id          = google_bigquery_dataset.audit_logging.dataset_id
  table_id            = "break_glass_access_log"
  deletion_protection = false
  schema = jsonencode([
    {
      name        = "audit_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique audit record ID"
    },
    {
      name        = "accessed_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when unmasking occurred"
    },
    {
      name        = "requestor_email"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "User or service account who executed unmasking"
    },
    {
      name        = "target_employee_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Employee record ID unmasked"
    },
    {
      name        = "business_justification"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Mandatory ticket number and justification provided"
    },
    {
      name        = "client_ip"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Client caller IP"
    }
  ])
}

# 5. IAM Policy Bindings & Conditional Access
resource "google_data_catalog_policy_tag_iam_member" "procurement_readers" {
  count      = length(var.procurement_readers)
  policy_tag = google_data_catalog_policy_tag.confidential_ssn_taxid.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = var.procurement_readers[count.index]
}

resource "google_data_catalog_policy_tag_iam_member" "hr_separation_readers" {
  count      = length(var.hr_readers)
  policy_tag = google_data_catalog_policy_tag.hr_separation_confidential.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = var.hr_readers[count.index]
}

resource "google_data_catalog_policy_tag_iam_member" "hr_pii_readers" {
  count      = length(var.hr_readers)
  policy_tag = google_data_catalog_policy_tag.hr_pii_high_sensitivity.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = var.hr_readers[count.index]
}

