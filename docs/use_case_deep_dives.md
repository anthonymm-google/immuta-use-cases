# Deep Dive: Implementing the 5 Customer Use Cases in GCP

This document details the architectural design, security model, and implementation specifics for each of the 5 customer governance use cases.

---

## Use Case 1: Procurement Vendor Tax ID Masking (SSN vs. EIN Protection)

### Customer Problem Statement
A `tax_id` field on a procurement table contains vendor tax identification numbers. For corporate vendors, this is an Employer Identification Number (EIN). For individual contractors and sole proprietors, this is a Social Security Number (SSN). SSNs must be identified and masked for everyone except authorized procurement team members.

### GCP Native Solution Architecture
1. **Automated Discovery & Tagging**:
   - Cloud DLP inspects `procurement_data.vendor_profiles` and identifies SSN and EIN patterns using built-in infoTypes (`US_SOCIAL_SECURITY_NUMBER`, `US_EMPLOYER_IDENTIFICATION_NUMBER`).
   - A Dataplex Policy Tag `Confidential_SSN_TaxID` is assigned to the `tax_id` schema column.
2. **BigQuery Dynamic Data Policy**:
   - Data Policy `dp_procurement_taxid_mask` applies `LAST_FOUR_CHARACTERS` masking.
   - **Procurement Group**: Granted `roles/datacatalog.categoryFineGrainedReader` on `Confidential_SSN_TaxID` -> Sees unmasked values (`456-78-1234`).
   - **General Analysts**: Granted `roles/bigquerydatapolicy.maskedReader` -> Automatically sees masked values (`XXXXX1234`) with no query failures or schema changes.
3. **Pattern-Aware Dynamic SQL Alternative**:
   - An authorized view `v_procurement_taxid_smart_mask` uses regular expressions (`REGEXP_CONTAINS`) to allow non-sensitive corporate EINs (`XX-XXXXXXX`) to be viewed by all analysts while selectively masking individual SSNs (`XXX-XX-XXXX`).

---

## Use Case 2: Employee PII Opt-In / Opt-Out Consent-Based Masking

### Customer Problem Statement
Employees can allow their personal contact information (personal email, personal phone, emergency contacts) to be shared internally or opt-out via a privacy flag (`pii_sharing_opted_in BOOLEAN`). PII must be masked for opted-out employees when viewed by general staff, but always visible unmasked to HR employees.

### GCP Native Solution Architecture
1. **Dynamic Consent-Aware Authorized View**:
   - View `hr_data.v_employee_directory_consent_aware` evaluates `SESSION_USER()` against `hr_data.hr_authorized_readers`.
   - If caller is in HR, full cleartext is returned.
   - If caller is a general colleague, opted-in employees show full details, while opted-out employees dynamically show `***-***-XXXX (OPTED-OUT)`.
2. **BigQuery Row Access Policies (Alternative / Supplementary)**:
   - Row-level access policies can filter rows completely if opted-out employees should be hidden from search:
     * HR Access Policy: `FILTER USING (TRUE)` for `group:hr-admin@company.com`.
     * General Access Policy: `FILTER USING (pii_sharing_opted_in = TRUE)` for `allAuthenticatedUsers`.

---

## Use Case 3: Sensitive Employee Separation / Leaving Details Masking

### Customer Problem Statement
Sensitive employee lifecycle attributes such as `separation_date`, `separation_reason`, `severance_amount`, and `exit_interview_notes` must be masked for general employees and only visible to specific HR staff.

### GCP Native Solution Architecture
1. **Dataplex Policy Tag**: `HR_Separation_Confidential` applied across sensitive lifecycle columns in `hr_data.employee_lifecycle`.
2. **BigQuery Data Policy**: `dp_hr_separation_mask` with `ALWAYS_NULL` or `DEFAULT_MASKING_VALUE`.
3. **IAM Authorization**:
   - HR Group granted `roles/datacatalog.categoryFineGrainedReader`.
   - General analysts querying `SELECT * FROM hr_data.employee_lifecycle` see `employment_status = "SEPARATED"`, but `separation_reason`, `severance_amount`, and `separation_date` return `NULL`.

---

## Use Case 4: Multi-Field PII Masking & Time-Phased Temporary Access

### Customer Problem Statement
Tags identify high-sensitivity PII fields (Driver's License, SSN, Passport Number) that must be masked for all employees except HR. Additionally, external auditors or temporary project staff need access for a limited time (e.g. 30 days) that expires automatically without manual intervention.

### GCP Native Solution Architecture
1. **Universal Tag-Based Masking**:
   - Policy Tag `PII_High_Sensitivity` applied to `ssn`, `drivers_license_num`, and `passport_num` in `hr_data.employee_pii_vault`.
   - Data Policy `dp_pii_high_sensitivity_mask` enforces `LAST_FOUR_CHARACTERS` masking.
2. **Time-Phased Access Options**:
   - **Option A: Google Cloud Privileged Access Manager (PAM) (Enterprise Standard)**:
     * Entitlement defines eligibility for external auditor group.
     * Maximum duration set to 30 days (720 hours).
     * Requires business justification and multi-party approval by HR Director / CISO.
     * Access activates temporary `FineGrainedReader` role and automatically revokes upon duration expiry.
   - **Option B: Cloud IAM Conditions**:
     * Direct IAM grant with expression `request.time < timestamp("2026-09-17T00:00:00Z")`.
     * Authorization engine automatically revokes access once the timestamp passes.

---

## Use Case 5: Enterprise Architectural Options for Allowing Data Unmasking

### Customer Problem Statement
When a field is normally masked, what are the enterprise architectural options in Google Cloud to allow legitimate users or processes to obtain unmasked data when justified?

### Comparison of the 5 Native GCP Options

| Option | Mechanism | Workflow & Trigger | Audit & Compliance | Recommended Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **1. Privileged Access Manager (PAM)** | JIT Role Elevation | Self-service request in Cloud Console / PAM API with manager approval | Full Cloud Audit Logs of request, approval, and BigQuery queries | Ad-hoc analytics, investigations, compliance audits |
| **2. Time-Bounded IAM Conditions** | IAM Condition Expression | Scheduled grant with `request.time < timestamp(...)` | IAM audit trail + auto-revocation | Fixed-term contractor projects, 30-day migrations |
| **3. Break-Glass Stored Procedure** | Authorized Stored Procedure | Call `sp_break_glass_unmask_record(emp_id, ticket_id)` | Mandatory real-time audit record insertion | Emergency incident response, legal holds, on-call support |
| **4. Cloud DLP Re-identification** | KMS Token Decryption | Cloud DLP API / Remote UDF calls Cloud KMS decryption | Cloud KMS key access audit logs | Tokenized data architectures, automated data pipelines |
| **5. BigQuery Data Clean Rooms** | Differential Privacy / Clean Room | Aggregate queries with mathematical privacy noise | Privacy budget tracking | Cross-organization analytics without raw PII exposure |
