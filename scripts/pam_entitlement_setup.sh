#!/usr/bin/env bash
# =============================================================================
# pam_entitlement_setup.sh
# Sets up Google Cloud Privileged Access Manager (PAM) Entitlement for JIT unmasking
# =============================================================================

PROJECT_ID="amm-immuta-gcp-demo"
LOCATION="global"
ENTITLEMENT_ID="pam-hr-pii-unmask-30day"

echo "Configuring GCP Privileged Access Manager (PAM) Entitlement for Time-Phased PII Access..."

# Create PAM Entitlement using gcloud beta privileged-access-manager
# Grants temporary Fine-Grained Reader on Policy Tags or BigQuery Data Policy
cat << EOF > /tmp/pam_entitlement_config.yaml
eligibleUsers:
  - principals:
      - "group:hr-compliance-auditors@company.internal"
      - "user:auditor-external@partner.com"
approvalWorkflow:
  manualApprovals:
    requireApproverJustification: true
    steps:
      - approvers:
          principals:
            - "user:hr-director@company.internal"
            - "user:ciso@company.internal"
        approvalsNeeded: 1
privilegedAccess:
  gcpIamAccess:
    roleBindings:
      - role: "roles/datacatalog.categoryFineGrainedReader"
maxRequestDuration: "2592000s" # 30 Days (720 hours)
requesterJustificationConfig:
  mandatory: true
EOF

echo "PAM Entitlement configuration template created at /tmp/pam_entitlement_config.yaml"
echo "To deploy via gcloud (requires organization level PAM enablement):"
echo "gcloud beta privileged-access-manager entitlements create ${ENTITLEMENT_ID} \"
echo "  --location=${LOCATION} \"
echo "  --project=${PROJECT_ID} \"
echo "  --config-file=/tmp/pam_entitlement_config.yaml"
