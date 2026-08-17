-- =============================================================================
-- 06_verification_and_test_queries.sql
-- Comprehensive verification queries testing all 5 use cases in BigQuery
-- =============================================================================

-- TEST 1: Use Case 1 - Procurement Vendor Tax ID Masking
SELECT "--- TEST 1: Procurement Vendor Profiles ---" AS test_title;
SELECT vendor_id, vendor_name, vendor_type, tax_id, spend_amount_ytd 
FROM `amm-immuta-gcp-demo.procurement_data.vendor_profiles`
ORDER BY vendor_id;

-- TEST 2: Use Case 2 - Employee Directory Consent-Aware Dynamic View
SELECT "--- TEST 2: Employee Directory Consent-Aware View ---" AS test_title;
SELECT employee_id, full_name, department, pii_sharing_opted_in, personal_phone, personal_email, home_city 
FROM `amm-immuta-gcp-demo.hr_data.v_employee_directory_consent_aware`
ORDER BY employee_id;

-- TEST 3: Use Case 3 - Sensitive Employee Separation Data
SELECT "--- TEST 3: Sensitive Employee Lifecycle & Separation ---" AS test_title;
SELECT employee_id, employee_name, employment_status, separation_date, separation_reason, severance_amount 
FROM `amm-immuta-gcp-demo.hr_data.employee_lifecycle`
ORDER BY employee_id;

-- TEST 4: Use Case 4 - High-Sensitivity PII Vault
SELECT "--- TEST 4: High Sensitivity PII Vault ---" AS test_title;
SELECT employee_id, full_legal_name, ssn, drivers_license_num, passport_num 
FROM `amm-immuta-gcp-demo.hr_data.employee_pii_vault`
ORDER BY employee_id;

-- TEST 5: Use Case 5 - Break-Glass Unmasking Stored Procedure Execution
SELECT "--- TEST 5: Break-Glass Emergency Unmasking ---" AS test_title;
CALL `amm-immuta-gcp-demo.hr_data.sp_break_glass_unmask_record`("EMP-5001", "Security Incident Response Investigation INC-98124 - Legal Review");

-- TEST 5B: Inspect Audit Trail Log
SELECT "--- TEST 5B: Break-Glass Audit Trail Log ---" AS test_title;
SELECT audit_id, accessed_at, requestor_email, target_employee_id, business_justification 
FROM `amm-immuta-gcp-demo.audit_logging.break_glass_access_log`;
