-- =============================================================================
-- 01_use_case_1_procurement_taxid.sql
-- USE CASE 1: TaxID field on Procurement table containing SSNs vs EINs.
-- Objective: Automatically identify SSNs and mask them for non-procurement users.
-- =============================================================================

/*
NATIVE GCP APPROACH OVERVIEW:
1. Automated Discovery & Classification:
   - Dataplex Profiling and Cloud Sensitive Data Protection (DLP) inspect the table
     against built-in infoTypes (US_SOCIAL_SECURITY_NUMBER and US_EMPLOYER_IDENTIFICATION_NUMBER).
   - Dataplex / Data Catalog Policy Tag: "Confidential_SSN_TaxID" is attached to the tax_id column.

2. Dynamic Tag-Based Data Masking (BigQuery Data Policy):
   - Data Policy "dp_procurement_taxid_mask" is attached to the policy tag.
   - Masking Expression: LAST_FOUR_CHARACTERS (or SHA256 / ALWAYS_NULL / DEFAULT_MASKING_VALUE).
   - IAM Permission:
     * Procurement Team: Granted "roles/datacatalog.categoryFineGrainedReader" on the policy tag (sees unmasked raw tax IDs).
     * General Analysts / Others: Granted standard "roles/bigquery.dataViewer" + "roles/bigquerydatapolicy.maskedReader" (sees masked tax IDs).

3. Advanced / Pattern-Aware Alternative (Dynamic SQL Masking / Authorized View):
   - If EINs should remain readable (XX-XXXXXXX) while SSNs (XXX-XX-XXXX) are masked:
*/

-- Approach A: Direct Table Query (Leveraging BigQuery Dynamic Data Masking)
-- Non-procurement users will automatically see "XXXXX1234" while procurement users see "456-78-1234".
SELECT 
  vendor_id,
  vendor_name,
  vendor_type,
  tax_id, -- Dynamically masked at engine level based on caller IAM
  spend_amount_ytd,
  payment_terms
FROM `amm-immuta-gcp-demo.procurement_data.vendor_profiles`
ORDER BY vendor_id;

-- Approach B: Pattern-Aware Dynamic View / Authorized Function
-- Evaluates regex format or lookup to mask ONLY SSN patterns if selective unmasking of corporate EINs is desired.
CREATE OR REPLACE VIEW `amm-immuta-gcp-demo.procurement_data.v_procurement_taxid_smart_mask` AS
SELECT 
  vendor_id,
  vendor_name,
  vendor_type,
  CASE
    -- 1. Procurement Authorized Users see unmasked value
    WHEN SESSION_USER() IN ("procurement@anthonymm.altostrat.com", "procurement-team@company.internal") THEN tax_id
    -- 2. If Corporate EIN (Format XX-XXXXXXX), allow visibility if deemed non-sensitive
    WHEN vendor_type = "CORPORATE" AND REGEXP_CONTAINS(tax_id, r"^\d{2}-\d{7}$") THEN tax_id
    -- 3. If SSN pattern (Format XXX-XX-XXXX) or Sole Proprietor/Individual, mask to last 4 digits
    WHEN REGEXP_CONTAINS(tax_id, r"^\d{3}-\d{2}-\d{4}$") THEN CONCAT("***-**-", RIGHT(tax_id, 4))
    -- 4. Default fallback mask
    ELSE "********* "
  END AS tax_id,
  spend_amount_ytd,
  payment_terms
FROM `amm-immuta-gcp-demo.procurement_data.vendor_profiles`;
