-- =============================================================================
-- 04_use_case_4_time_phased_access.sql
-- USE CASE 4: Tag-Based PII Masking across multiple fields (SSN, DL, Passport)
--             and Time-Phased Temporary Access (e.g. 30-Day Job Access).
-- =============================================================================

SELECT
  employee_id,
  full_legal_name,
  ssn,                  -- Masked for general users; unmasked during active PAM grant window
  drivers_license_num,  -- Masked for general users; unmasked during active PAM grant window
  passport_num,         -- Masked for general users; unmasked during active PAM grant window
  dob
FROM `amm-immuta-gcp-demo.hr_data.employee_pii_vault`
ORDER BY employee_id;
