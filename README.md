# Immuta to Google Cloud Platform: Native Data Governance & Security Reference Implementation

This repository provides a complete, production-ready architecture and demonstration of how to implement **Immuta data governance and security use cases natively in Google Cloud Platform (GCP)** using **BigQuery**, **Dataplex Universal Catalog**, **Dynamic Data Policies**, **Cloud IAM**, **Privileged Access Manager (PAM)**, and **Cloud Sensitive Data Protection (DLP)**.

---

## 🎯 Target GCP Project Details

- **GCP Project ID**: `amm-immuta-gcp-demo`
- **Location**: `us-central1`
- **Infrastructure Status**: Fully deployed and verified via Terraform and BigQuery

---

## 📋 The 5 Customer Use Cases & GCP Native Solutions

| # | Immuta Use Case | GCP Native Architecture & Solution | Live BigQuery Asset |
|---|---|---|---|
| **1** | **Procurement TaxID SSN vs EIN Masking**<br>Mask SSNs in a procurement table for everyone except the Procurement team | **Dataplex Policy Tags + BigQuery Dynamic Data Policies** (`LAST_FOUR_CHARACTERS` masking) + Pattern-Aware Smart View (`REGEXP_CONTAINS`) | `procurement_data.vendor_profiles`<br>`procurement_data.v_procurement_taxid_smart_mask` |
| **2** | **Employee PII Opt-In / Opt-Out Consent**<br>Mask PII based on a consent column flag for general employees, while HR always sees cleartext | **Dynamic Consent-Aware Authorized View** (`SESSION_USER()` + `pii_sharing_opted_in` evaluation) + BigQuery Row Access Policies | `hr_data.employee_directory`<br>`hr_data.v_employee_directory_consent_aware` |
| **3** | **Sensitive HR Separation & Leaving Details**<br>Mask separation date, reason, and severance for everyone except HR | **Dataplex Policy Tags (`HR_Separation_Confidential`) + BigQuery Data Policy (`ALWAYS_NULL`)** with Fine-Grained Reader IAM | `hr_data.employee_lifecycle` |
| **4** | **Tag-Based PII Masking & Time-Phased Access**<br>Tag-based universal PII masking with temporary 30-day access that automatically expires | **Universal Dataplex Policy Tags (`PII_High_Sensitivity`) + Privileged Access Manager (PAM)** JIT workflow & Time-Bounded IAM Conditions | `hr_data.employee_pii_vault`<br>`scripts/pam_entitlement_setup.sh` |
| **5** | **Data Unmasking Architectural Options**<br>Options for allowing legitimate users/processes to unmask fields safely and with auditability | **5 Enterprise Options**: 1. Privileged Access Manager (PAM), 2. Time-Bounded IAM, 3. Break-Glass Procedure with Immutable Audit Log, 4. Cloud DLP Crypto-Tokenization, 5. BigQuery Clean Rooms | `hr_data.sp_break_glass_unmask_record`<br>`audit_logging.break_glass_access_log` |

---

## 📁 Repository Structure

```
immuta-use-cases/
├── README.md                                  # Executive overview and quickstart guide
├── terraform/                                 # Complete Infrastructure-as-Code (IaC)
│   ├── main.tf                                # BigQuery datasets, tables, taxonomies, policy tags, data policies, IAM
│   ├── variables.tf                           # Configurable variables (project, region, members)
│   └── outputs.tf                             # Policy tag ARNs, dataset IDs, table names
├── sql/                                       # Modular SQL implementation scripts
│   ├── 00_setup_datasets_and_tables.sql       # Synthetic data population
│   ├── 01_use_case_1_procurement_taxid.sql    # UC1: TaxID SSN discovery & dynamic column masking
│   ├── 02_use_case_2_pii_opt_in_out.sql       # UC2: Employee directory PII opt-in/opt-out consent view
│   ├── 03_use_case_3_hr_separation_data.sql   # UC3: Sensitive HR separation & leaving reason masking
│   ├── 04_use_case_4_time_phased_access.sql   # UC4: Universal PII tags & time-phased PAM/IAM access
│   ├── 05_use_case_5_unmasking_options.sql    # UC5: 5 unmasking architectures + Break-Glass Stored Proc
│   └── 06_verification_and_test_queries.sql  # Comprehensive test queries verifying all personas
├── scripts/                                   # Automation & verification tools
│   ├── simulate_personas.sh                   # Script demonstrating queries under different user contexts
│   └── pam_entitlement_setup.sh               # Privileged Access Manager setup script
└── docs/                                      # In-depth architectural guides
    ├── immuta_to_gcp_mapping_guide.md         # Feature-by-feature comparison (Immuta vs GCP Dataplex/BQ)
    ├── use_case_deep_dives.md                 # Deep technical walkthrough of all 5 use cases
    ├── pam_and_jit_governance.md              # Privileged Access Management & time-bound access guide
    └── cost_and_operational_benefits.md       # TCO, maintenance, performance, and architecture comparison
```

---

## 🚀 Quickstart: Running the Demonstrations

### 1. View Deployed BigQuery Datasets & Tables
```bash
bq ls --project_id=amm-immuta-gcp-demo
bq ls --project_id=amm-immuta-gcp-demo hr_data
bq ls --project_id=amm-immuta-gcp-demo procurement_data
```

### 2. Run Verification Test Suite
```bash
bq query --use_legacy_sql=false --project_id=amm-immuta-gcp-demo < sql/06_verification_and_test_queries.sql
```

### 3. Simulate Personas
```bash
./scripts/simulate_personas.sh
```

---

## 🔐 Security & Governance Architecture Highlights

1. **Zero Standing Privileges**: Users query masked data by default. Elevation is temporary and auditable.
2. **In-Engine Enforcement**: Security is enforced inside BigQuery's distributed engine with zero network hops, zero proxies, and no external query translation.
3. **Immutable Audit Trails**: Break-glass unmasking and PAM grants write directly to Cloud Audit Logs and immutable BigQuery audit tables.
