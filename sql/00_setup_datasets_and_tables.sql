-- =============================================================================
-- 00_setup_datasets_and_tables.sql
-- Population of realistic synthetic data for Immuta to GCP native migration demo
-- Target Project: amm-immuta-gcp-demo
-- =============================================================================

-- 1. Populate Procurement Vendors Data (Use Case 1)
INSERT INTO `amm-immuta-gcp-demo.procurement_data.vendor_profiles` 
(vendor_id, vendor_name, vendor_type, tax_id, spend_amount_ytd, payment_terms, created_at)
VALUES
  ("VND-1001", "Acme Cloud Infrastructure LLC", "CORPORATE", "12-3456789", 245000.00, "Net 30", CURRENT_TIMESTAMP()),
  ("VND-1002", "Johnathan Doe IT Consulting", "INDIVIDUAL_CONTRACTOR", "456-78-1234", 85400.50, "Net 15", CURRENT_TIMESTAMP()),
  ("VND-1003", "Apex Logistics Corp", "CORPORATE", "98-7654321", 1200000.00, "Net 60", CURRENT_TIMESTAMP()),
  ("VND-1004", "Sarah Jenkins Design Studio", "SOLE_PROPRIETOR", "987-65-4321", 42300.00, "Net 30", CURRENT_TIMESTAMP()),
  ("VND-1005", "Global Supply Dynamics Inc", "CORPORATE", "33-9988771", 650000.75, "Net 45", CURRENT_TIMESTAMP()),
  ("VND-1006", "Michael Chang Translation Svcs", "INDIVIDUAL_CONTRACTOR", "555-12-8899", 18750.00, "Net 15", CURRENT_TIMESTAMP());

-- 2. Populate Employee Directory with Privacy Consent Flags (Use Case 2)
INSERT INTO `amm-immuta-gcp-demo.hr_data.employee_directory`
(employee_id, full_name, department, job_title, work_email, pii_sharing_opted_in, personal_phone, personal_email, home_city, emergency_contact_phone)
VALUES
  ("EMP-5001", "Alice Walker", "Engineering", "Lead Cloud Architect", "alice.walker@company.internal", TRUE, "415-555-0191", "alice.personal@gmail.com", "San Francisco", "415-555-9988"),
  ("EMP-5002", "Bob Martinez", "Finance", "Senior Financial Analyst", "bob.martinez@company.internal", FALSE, "212-555-0144", "bmartinez88@outlook.com", "New York", "212-555-8877"),
  ("EMP-5003", "Carol Chen", "Marketing", "VP of Global Growth", "carol.chen@company.internal", TRUE, "312-555-0178", "carol.chen.home@yahoo.com", "Chicago", "312-555-7766"),
  ("EMP-5004", "David Kim", "Human Resources", "HR Operations Director", "david.kim@company.internal", FALSE, "206-555-0123", "dkim_private@protonmail.com", "Seattle", "206-555-6655"),
  ("EMP-5005", "Elena Rostova", "Procurement", "Global Sourcing Manager", "elena.rostova@company.internal", TRUE, "512-555-0167", "elena.rostova@gmail.com", "Austin", "512-555-5544");

-- 3. Populate Employee Lifecycle & Separation Data (Use Case 3)
INSERT INTO `amm-immuta-gcp-demo.hr_data.employee_lifecycle`
(employee_id, employee_name, hire_date, employment_status, separation_date, separation_reason, severance_amount, exit_interview_notes)
VALUES
  ("EMP-5001", "Alice Walker", DATE "2021-03-15", "ACTIVE", NULL, NULL, NULL, NULL),
  ("EMP-5002", "Bob Martinez", DATE "2019-06-01", "ACTIVE", NULL, NULL, NULL, NULL),
  ("EMP-5003", "Carol Chen", DATE "2022-01-10", "ACTIVE", NULL, NULL, NULL, NULL),
  ("EMP-5006", "Franklin Harris", DATE "2018-09-01", "SEPARATED", DATE "2026-06-30", "VOLUNTARY_CAREER_TRANSITION", 0.00, "Left to pursue graduate studies in AI."),
  ("EMP-5007", "Grace Hopper-Smith", DATE "2020-04-15", "SEPARATED", DATE "2026-07-15", "INVOLUNTARY_RESTRUCTURING", 45000.00, "Role eliminated during Q3 regional consolidation. Standard severance applied."),
  ("EMP-5008", "Henry Vance", DATE "2023-11-01", "SEPARATED", DATE "2026-08-01", "INVOLUNTARY_PERFORMANCE", 12000.00, "Performance improvement plan unfulfilled. Non-disclosure agreement executed.");

-- 4. Populate High-Sensitivity PII Vault (Use Case 4)
INSERT INTO `amm-immuta-gcp-demo.hr_data.employee_pii_vault`
(employee_id, full_legal_name, ssn, drivers_license_num, passport_num, dob)
VALUES
  ("EMP-5001", "Alice Marie Walker", "111-22-3333", "DL-CA-88992211", "US-PASS-90812345", DATE "1988-04-12"),
  ("EMP-5002", "Roberto Martinez", "444-55-6666", "DL-NY-44556677", "US-PASS-11223344", DATE "1992-09-28"),
  ("EMP-5003", "Carolyn Xiao Chen", "777-88-9999", "DL-IL-99001122", "US-PASS-55667788", DATE "1985-12-05"),
  ("EMP-5004", "David Sungho Kim", "222-33-4444", "DL-WA-33445566", "US-PASS-99887766", DATE "1980-07-19");
