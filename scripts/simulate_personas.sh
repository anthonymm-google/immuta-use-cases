#!/usr/bin/env bash
# =============================================================================
# simulate_personas.sh
# Demonstrates querying BigQuery datasets under different caller personas
# =============================================================================

PROJECT_ID="amm-immuta-gcp-demo"

echo "========================================================================"
echo " SIMULATING DATA ACCESS UNDER MULTIPLE PERSONAS IN GOOGLE CLOUD"
echo "========================================================================"

echo ""
echo "[1] Current Authenticated Session (Privileged HR & Procurement Admin)"
echo "------------------------------------------------------------------------"
bq query --use_legacy_sql=false --label datacloud:jetski --project_id=${PROJECT_ID} "SELECT vendor_id, vendor_name, vendor_type, tax_id FROM \`${PROJECT_ID}.procurement_data.vendor_profiles\` LIMIT 3;"

echo ""
echo "[2] Simulated General Employee View (Consent-Aware Directory View)"
echo "------------------------------------------------------------------------"
# Query showing how a general employee views consented vs opted-out colleagues
bq query --use_legacy_sql=false --label datacloud:jetski --project_id=${PROJECT_ID} "SELECT employee_id, full_name, department, pii_sharing_opted_in, personal_phone, personal_email, home_city 
 FROM \`${PROJECT_ID}.hr_data.v_employee_directory_consent_aware\` LIMIT 5;"

echo ""
echo "[3] Break-Glass Audit Trail Log"
echo "------------------------------------------------------------------------"
bq query --use_legacy_sql=false --label datacloud:jetski --project_id=${PROJECT_ID} "SELECT audit_id, accessed_at, requestor_email, target_employee_id, business_justification 
 FROM \`${PROJECT_ID}.audit_logging.break_glass_access_log\` ORDER BY accessed_at DESC LIMIT 5;"
