-- =============================================================================
-- 02_use_case_2_pii_opt_in_out.sql
-- USE CASE 2: Employee PII Opt-In / Opt-Out Consent-Based Masking
-- Objective: Mask PII based on a column flag (pii_sharing_opted_in = FALSE)
--            for general employees, while HR employees always see unmasked values.
-- =============================================================================

-- 1. Create Lookup Table for HR Authorized User Group / Members
CREATE OR REPLACE TABLE `amm-immuta-gcp-demo.hr_data.hr_authorized_readers` (
  member_email STRING,
  role_title STRING,
  granted_at TIMESTAMP
);

INSERT INTO `amm-immuta-gcp-demo.hr_data.hr_authorized_readers` VALUES
  ("hr@anthonymm.altostrat.com", "HR System Administrator", CURRENT_TIMESTAMP()),
  ("hr-lead@company.internal", "Head of People Operations", CURRENT_TIMESTAMP()),
  ("hr-partner@company.internal", "Senior HR Business Partner", CURRENT_TIMESTAMP());

-- 2. Create Dynamic Consent-Aware Authorized View
CREATE OR REPLACE VIEW `amm-immuta-gcp-demo.hr_data.v_employee_directory_consent_aware` AS
SELECT
  employee_id,
  full_name,
  department,
  job_title,
  work_email,
  pii_sharing_opted_in,
  -- Dynamic Phone Masking
  CASE 
    WHEN SESSION_USER() IN (SELECT member_email FROM `amm-immuta-gcp-demo.hr_data.hr_authorized_readers`) THEN personal_phone
    WHEN pii_sharing_opted_in = TRUE THEN personal_phone
    ELSE "***-***-XXXX (OPTED-OUT)"
  END AS personal_phone,
  -- Dynamic Email Masking
  CASE 
    WHEN SESSION_USER() IN (SELECT member_email FROM `amm-immuta-gcp-demo.hr_data.hr_authorized_readers`) THEN personal_email
    WHEN pii_sharing_opted_in = TRUE THEN personal_email
    ELSE "redacted.optout@privacy.internal"
  END AS personal_email,
  -- Dynamic Home City Masking
  CASE 
    WHEN SESSION_USER() IN (SELECT member_email FROM `amm-immuta-gcp-demo.hr_data.hr_authorized_readers`) THEN home_city
    WHEN pii_sharing_opted_in = TRUE THEN home_city
    ELSE "[HIDDEN]"
  END AS home_city,
  -- Dynamic Emergency Contact Masking
  CASE 
    WHEN SESSION_USER() IN (SELECT member_email FROM `amm-immuta-gcp-demo.hr_data.hr_authorized_readers`) THEN emergency_contact_phone
    WHEN pii_sharing_opted_in = TRUE THEN emergency_contact_phone
    ELSE "***-***-XXXX (CONFIDENTIAL)"
  END AS emergency_contact_phone
FROM `amm-immuta-gcp-demo.hr_data.employee_directory`;
