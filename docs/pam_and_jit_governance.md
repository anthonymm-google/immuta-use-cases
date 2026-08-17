# Privileged Access Management (PAM) & Just-In-Time Data Governance in GCP

This guide explains how **Google Cloud Privileged Access Manager (PAM)** and **IAM Conditions** provide automated, time-phased, and auditable Just-In-Time (JIT) access to masked BigQuery data.

---

## 1. Why Privileged Access Manager (PAM)?

In traditional data governance architectures, users are either granted **standing unmasked access** (violating the principle of least privilege) or administrators must manually grant and revoke permissions (creating operational overhead and security blind spots).

Google Cloud PAM provides:
- **Zero Standing Privileges**: Users operate with masked data by default.
- **Self-Service Elevation**: Users request temporary unmasked access via the Cloud Console or API.
- **Multi-Step Approval**: Requests can be routed to Data Owners, Compliance Leads, or Line Managers.
- **Automated Revocation**: Grants automatically expire after the requested duration (e.g. 2 hours to 30 days).
- **End-to-End Auditability**: Cloud Audit Logs capture the justification, approver identity, grant timestamps, and every SQL query executed during the unmasked session.

---

## 2. PAM Entitlement Architecture for BigQuery & Dataplex

```
  +─────────────────────────────────────────────────────────────+
  | 1. User Requests Unmasking                                  |
  |    - Target: Dataplex Policy Tag (PII_High_Sensitivity)     |
  |    - Justification: "Q3 SOX HR Audit Ticket #AUD-4029"      |
  |    - Duration: 30 Days (720 Hours)                          |
  +──────────────────────────────┬──────────────────────────────+
                                 │
                                 ▼
  +─────────────────────────────────────────────────────────────+
  | 2. Multi-Party Approval Workflow (PAM)                      |
  |    - Approvers: HR Director & Security Lead                 |
  |    - Notification: Email / Cloud Pub/Sub / Slack / Jira     |
  +──────────────────────────────┬──────────────────────────────+
                                 │ Approved
                                 ▼
  +─────────────────────────────────────────────────────────────+
  | 3. JIT Role Activation                                      |
  |    - PAM binds `roles/datacatalog.categoryFineGrainedReader`|
  |    - User immediately sees unmasked BigQuery data           |
  +──────────────────────────────┬──────────────────────────────+
                                 │ 30 Days Elapsed
                                 ▼
  +─────────────────────────────────────────────────────────────+
  | 4. Automatic Revocation & Audit Closure                     |
  |    - PAM removes IAM binding instantly                      |
  |    - BigQuery reverts to masked data automatically          |
  +─────────────────────────────────────────────────────────────+
```

---

## 3. Configuring PAM via Terraform and gcloud CLI

### YAML Configuration (`pam_entitlement.yaml`)
```yaml
eligibleUsers:
  - principals:
      - "group:hr-auditors@company.com"
approvalWorkflow:
  manualApprovals:
    requireApproverJustification: true
    steps:
      - approvers:
          principals:
            - "user:hr-director@company.com"
        approvalsNeeded: 1
privilegedAccess:
  gcpIamAccess:
    roleBindings:
      - role: "roles/datacatalog.categoryFineGrainedReader"
maxRequestDuration: "2592000s" # 30 Days
requesterJustificationConfig:
  mandatory: true
```

### Deployment via gcloud CLI
```bash
gcloud beta privileged-access-manager entitlements create pam-hr-pii-unmask-30day   --location=global   --project=amm-immuta-gcp-demo   --config-file=pam_entitlement.yaml
```
