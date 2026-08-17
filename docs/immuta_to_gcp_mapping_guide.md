# Immuta to Google Cloud Platform: Native Governance Architecture Mapping

This document provides a comprehensive mapping of **Immuta** governance concepts and policy primitives to **Google Cloud Platform (GCP)** native security, data classification, and access control capabilities.

---

## 1. Executive Summary

Organizations migrating from Immuta to GCP-native governance eliminate external policy sync agents, sidecar proxies, and duplicate metadata catalogs. By leveraging **BigQuery**, **Dataplex Universal Catalog**, **Cloud IAM**, **Privileged Access Manager (PAM)**, and **Cloud Sensitive Data Protection (DLP)**, all governance enforcement occurs directly inside BigQuery's distributed execution engine with zero query overhead and native auditability.

---

## 2. Conceptual Feature Mapping

| Immuta Capability | GCP Native Equivalent | Key Technical Component / Mechanism |
| :--- | :--- | :--- |
| **Data Tagging & Classification** | **Dataplex Universal Catalog & Policy Tags** | Taxonomies, Policy Tags, and Automated Data Profiling |
| **Automated PII Discovery** | **Sensitive Data Protection (Cloud DLP)** | Cloud DLP inspection templates, infoTypes (`US_SSN`, `EMAIL`, etc.) |
| **Global Masking Policies** | **BigQuery Dynamic Data Policies** | Policy Tag-based masking (`LAST_FOUR_CHARACTERS`, `ALWAYS_NULL`, `SHA256`, `DEFAULT_MASKING_VALUE`) |
| **Column-Level Security (CLS)** | **Dataplex Policy Tags + Fine-Grained Reader IAM** | `roles/datacatalog.categoryFineGrainedReader` vs `roles/bigquerydatapolicy.maskedReader` |
| **Row-Level Security (RLS)** | **BigQuery Row Access Policies** | `CREATE ROW ACCESS POLICY ... FILTER USING (...)` |
| **Attribute-Based Access Control (ABAC)** | **Authorized Views & `SESSION_USER()` Functions** | Dynamic SQL projections evaluating caller email, group membership, and row flags |
| **Time-Phased / Temporary Access** | **Privileged Access Manager (PAM) & IAM Conditions** | JIT self-service elevation with multi-party approval and auto-revocation; time-bounded IAM conditions |
| **Break-Glass / Exception Access** | **Authorized Stored Procedures + Audit Logging** | Immutable BigQuery audit logging in definer's rights procedures |
| **Format-Preserving Encryption (FPE)** | **Cloud DLP Crypto-Tokenization & Cloud KMS** | Deterministic tokenization, surrogate keys, and KMS-governed re-identification |
| **Cross-Organization Sharing** | **BigQuery Analytics Hub & Data Clean Rooms** | Differential privacy, multi-party clean rooms without data movement |
| **Access Audit & Compliance** | **Cloud Audit Logs + BigQuery Information Schema** | Immutable audit logs, `INFORMATION_SCHEMA.JOBS_BY_PROJECT`, and Security Command Center |

---

## 3. Architecture Comparison: Immuta vs. GCP Native

```
+-----------------------------------------------------------------------------------+
| IMMUTA ARCHITECTURE                                                               |
|                                                                                   |
|  [ User / BI Tool ]                                                              |
|          │                                                                        |
|          ▼                                                                        |
|  [ Immuta Query Engine / Policy Agent / Proxy ]                                   |
|    - External RBAC/ABAC catalog sync                                              |
|    - External policy compilation & query rewriting                                |
|    - Additional infrastructure maintenance & license costs                        |
|          │                                                                        |
|          ▼                                                                        |
|  [ BigQuery Engine ] ──> [ Raw Data Storage ]                                     |
+-----------------------------------------------------------------------------------+

                                        vs.

+-----------------------------------------------------------------------------------+
| GCP NATIVE ARCHITECTURE (Deployed in amm-immuta-gcp-demo)                         |
|                                                                                   |
|  [ User / BI Tool / Service Account ]                                             |
|          │                                                                        |
|          ▼ (Direct Query Execution)                                               |
|  [ BigQuery Native Execution Engine ]                                             |
|    ├── Evaluates Dataplex Policy Tags & Dynamic Data Policies (In-Memory Masking) |
|    ├── Evaluates Row Access Policies & Session User Context                       |
|    └── Enforces IAM & Privileged Access Manager (PAM) Entitlements                |
|          │                                                                        |
|          ▼ (Zero-Copy Masked / Filtered Result Set)                               |
|  [ BigQuery Storage & Dataplex Catalog ]                                          |
|    ├── Cloud DLP Automated Profiling & Classification                             |
|    └── Cloud Audit Logs (Immutable Query & Access Logging)                        |
+-----------------------------------------------------------------------------------+
```

---

## 4. Key Advantages of the GCP Native Approach

1. **Zero Added Query Latency**: Enforcement happens directly inside the BigQuery storage-to-compute shuffle layer, avoiding query rewriting bottlenecks or proxy hops.
2. **Unified Identity & Access Management (IAM)**: Utilizes Google Workspace, Google Cloud IAM, Google Groups, and SAML/OIDC federated identity without maintaining dual user directories.
3. **No External Infrastructure**: No virtual machines, clusters, or agents to deploy, patch, monitor, or scale.
4. **Resilience to Query Bypass**: Because policies are attached directly to the dataset, table schema, and policy tags in BigQuery, users cannot bypass security regardless of whether they connect via SQL workspace, Python/Pandas, Spark (BigQuery connector), Dataform, Looker, or REST API.
5. **Just-In-Time (JIT) Governance**: Native integration with Google Cloud Privileged Access Manager (PAM) for automated approvals, time-bounded grants, and compliance reporting.
