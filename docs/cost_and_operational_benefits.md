# Total Cost of Ownership (TCO) & Operational Benefits: Immuta vs. GCP Native

This document provides an executive comparison of the operational footprint, cost model, and performance characteristics of migrating from Immuta to GCP-native governance.

---

## 1. Comparison Matrix

| Dimension | Immuta Third-Party Architecture | Google Cloud Native Architecture |
| :--- | :--- | :--- |
| **Licensing Cost** | High annual software license per core/user/data volume | Included natively with BigQuery, Dataplex, and IAM (pay only for standard GCP compute/storage) |
| **Infrastructure Overhead** | Requires managing Immuta proxy servers, Kubernetes clusters, or query engines | 100% Serverless. Zero infrastructure to deploy, patch, monitor, or manage |
| **Query Latency** | Network hop and query translation overhead through external policy proxies | Zero latency. Dynamic masking executed in-memory during BigQuery storage-to-compute scan |
| **Identity Synchronization** | Requires maintaining user/group sync between IdP, Immuta, and BigQuery | Native Cloud IAM integration with Google Workspace, Microsoft Entra ID, Okta, and SAML/OIDC |
| **Security & Bypass Risk** | Risk of users bypassing proxy if direct BigQuery access is granted | Impossible to bypass. Policy tags and data policies are bound at the BigQuery storage engine level |
| **Break-Glass & JIT** | Immuta proprietary access request workflows | Google Cloud Privileged Access Manager (PAM) with native Cloud Audit Logs |
| **Automation & IaC** | Proprietary API / CLI integration | Native Terraform (`google` provider), Google Cloud SDK (`gcloud`), and Dataplex APIs |

---

## 2. Key Takeaways for Enterprise Customers

1. **Massive TCO Reduction**: Eliminating third-party governance software licenses and the underlying compute clusters required to host them results in substantial cost savings.
2. **Simplified Enterprise Architecture**: One less vendor in the data path reduces security review surface, maintenance overhead, and failure points.
3. **Consistent Governance Across All Tools**: Policies apply identically whether queries originate from BigQuery Studio, Looker, Dataform, Vertex AI, Jupyter Notebooks, or Cloud Functions.
