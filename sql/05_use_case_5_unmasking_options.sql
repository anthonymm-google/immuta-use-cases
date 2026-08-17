-- =============================================================================
-- 05_use_case_5_unmasking_options.sql
-- USE CASE 5: Enterprise Architectural Options for Allowing Unmasking on Demand
-- =============================================================================

-- IMPLEMENTATION OF OPTION 3: Break-Glass Stored Procedure with Immutable Logging
CREATE OR REPLACE PROCEDURE `amm-immuta-gcp-demo.hr_data.sp_break_glass_unmask_record`(
  IN in_employee_id STRING,
  IN in_business_justification STRING
)
BEGIN
  DECLARE v_audit_id STRING;
  
  -- Validate business justification is provided
  IF in_business_justification IS NULL OR LENGTH(TRIM(in_business_justification)) < 10 THEN
    RAISE USING MESSAGE = "Access Denied: A valid business justification and ticket ID (min 10 chars) is strictly required for break-glass unmasking.";
  END IF;

  SET v_audit_id = GENERATE_UUID();

  -- 1. Insert immutable audit record into audit_logging dataset
  INSERT INTO `amm-immuta-gcp-demo.audit_logging.break_glass_access_log`
  (audit_id, accessed_at, requestor_email, target_employee_id, business_justification, client_ip)
  VALUES
  (
    v_audit_id,
    CURRENT_TIMESTAMP(),
    SESSION_USER(),
    in_employee_id,
    in_business_justification,
    "CLOUD_CONSOLE_SESSION"
  );

  -- 2. Return unmasked record for authorized emergency context
  SELECT 
    v.employee_id,
    v.full_legal_name,
    v.ssn,
    v.drivers_license_num,
    v.passport_num,
    v.dob,
    v_audit_id AS audit_tracking_token,
    CURRENT_TIMESTAMP() AS unmasked_timestamp
  FROM `amm-immuta-gcp-demo.hr_data.employee_pii_vault` v
  WHERE v.employee_id = in_employee_id;

END;
