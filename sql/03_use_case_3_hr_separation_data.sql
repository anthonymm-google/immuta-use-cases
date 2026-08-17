-- =============================================================================
-- 03_use_case_3_hr_separation_data.sql
-- USE CASE 3: Sensitive Employee Separation Date and Leaving Reason Masking
-- Objective: Mask separation_date, separation_reason, severance_amount, and
--            exit_interview_notes for everyone except specific HR group.
-- =============================================================================

SELECT
  employee_id,
  employee_name,
  hire_date,
  employment_status,
  separation_date,        -- Masked to NULL for non-HR
  separation_reason,      -- Masked to NULL for non-HR
  severance_amount,       -- Masked to NULL for non-HR
  exit_interview_notes    -- Masked to NULL for non-HR
FROM `amm-immuta-gcp-demo.hr_data.employee_lifecycle`
ORDER BY employee_id;
