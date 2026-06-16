# platformDemo — SocIntPoc

Full-stack GitOps demo deploying a React + Node.js/Express application on Azure Kubernetes Service, managed end-to-end with Flux CD, Terraform, and Helm.

**Application URL:** [https://app.172.193.30.158.nip.io](https://app.172.193.30.158.nip.io)
**SonarCloud:** [Overview – socIntPoc](https://sonarcloud.io/project/overview?id=sonarterst_socintpoc)

---

## Architecture

```
GitHub Repo (platformDemo)
    │
    ├── Terraform (run locally)          → Azure infrastructure provisioning
    │     ├── AKS (Kubernetes 1.34)
    │     ├── ACR (acrsocintpocdemou7yl.azurecr.io)
    │     ├── Azure Database for PostgreSQL Flexible Server
    │     ├── Azure Key Vault (SOPS encryption)
    │     └── Flux bootstrap (SSH deploy key)
    │
    ├── GitHub Actions (CI)              → Build, test, push images & Helm chart
    │     ├── SonarCloud scan
    │     ├── Docker build & push (frontend + backend → ACR)
    │     └── Helm chart package & push → ACR OCI registry
    │
    └── Flux CD (GitOps)                 → Continuous delivery to AKS
          ├── flux-system   (self-managed)
          ├── base-infra    (ingress-nginx, cert-manager)
          ├── cluster-issuers (Let's Encrypt ClusterIssuers)
          └── apps          (socpoc HelmRelease)
```

---

## Repository Structure

```
├── backend/               Node.js/Express API
├── frontend/              React (Vite) SPA
├── helm/socpoc/           Helm chart (version 0.2.0)
├── clusters/demo/         Flux GitOps manifests
│   ├── flux-system/       Flux bootstrap components
│   ├── base/              ingress-nginx + cert-manager HelmReleases
│   ├── cluster-issuers/   Let's Encrypt ClusterIssuer CRs
│   ├── apps/              socpoc HelmRelease + secrets (SOPS-encrypted)
│   ├── ks-base-infra.yaml
│   ├── ks-cluster-issuers.yaml
│   └── ks-apps.yaml
└── terraform/             Azure infrastructure (AKS, ACR, PostgreSQL, KV, Flux)
    └── modules/
        ├── aks/
        ├── acr/
        ├── database/
        ├── keyvault/
        ├── networking/
        └── flux/
```

---

## Infrastructure

| Resource | Name | Details |
|---|---|---|
| Resource Group | `socintpoc-demo` | East US 2 |
| AKS Cluster | `aks-socintpoc-demo` | Kubernetes 1.34, autoscale 1–3 nodes (Standard_D2ads_v5) |
| Container Registry | `acrsocintpocdemou7yl.azurecr.io` | Images: `frontend`, `backend`; Helm: `oci://…/helm` |
| PostgreSQL | `psql-socintpoc-demo.postgres.database.azure.com` | Flexible Server v16, DB: `tododb` |
| Key Vault | `kv-socintpoc-demo` | SOPS encryption key for Flux secrets |
| Ingress LB IP | `172.193.30.158` | ingress-nginx LoadBalancer |

> **Note:** Terraform was run locally — the Terraform CI pipeline was disabled because the `plan` step triggered a public IP change on the ACR network rules, causing the `apply` post-check to fail.

---

## Flux CD Dependency Chain

```
flux-system
  └─ base-infra          (ingress-nginx + cert-manager HelmReleases)
       └─ cluster-issuers (letsencrypt-staging + letsencrypt-prod ClusterIssuers)
            └─ apps       (socpoc HelmRelease — SOPS-decrypted secrets)
```

---

## CI/CD Pipeline (GitHub Actions)

Triggered on pushes to `main` affecting `frontend/`, `backend/`, or `helm/`:

1. **SonarCloud scan** — static analysis & quality gate
2. **Azure OIDC login** — passwordless auth to Azure
3. **Docker build & push** — `frontend:latest` and `backend:latest` → ACR
4. **Helm package & push** — `socpoc-<version>.tgz` → ACR OCI registry

Flux reconciles the cluster every 10 minutes and picks up new image tags.

---

## Secrets Management

Secrets in `clusters/demo/apps/secrets.yaml` are encrypted with [SOPS](https://github.com/getsops/sops) using Azure Key Vault. Flux decrypts them at deploy time via Workload Identity (`id-workload-socintpoc-demo`).

To edit secrets locally:
```bash
sops --decrypt --in-place clusters/demo/apps/secrets.yaml
# edit values
sops --encrypt --in-place clusters/demo/apps/secrets.yaml
```

---

## Known Issues & Resolutions

| # | Issue | Resolution |
|---|---|---|
| 1 | Flux GitRepository auth failed (HTTPS vs SSH) | Changed `gotk-sync.yaml` URL from `https://` to `ssh://git@github.com/…` |
| 2 | `kustomize build` failed on `clusters/demo` | Replaced mixed-content `kustomization.yaml` with proper kustomize config; moved Flux CRs to `ks-*.yaml` |
| 3 | `ClusterIssuer` CRD not found on apply | Split cluster-issuers into a separate Kustomization with `dependsOn: base-infra` |
| 4 | SOPS decryption: WorkloadIdentity 401 | Added federated credential for `flux-system:kustomize-controller` to `id-workload-socintpoc-demo` |
| 5 | `HelmRepository` API version not served | Updated from `source.toolkit.fluxcd.io/v1beta2` → `v1` |
| 6 | ACR name mismatch in manifests | Corrected all references to `acrsocintpocdemou7yl.azurecr.io` |
| 7 | Let's Encrypt HTTP-01 challenge timeout | Added inbound NSG rules for ports 80 and 443 on `nsg-aks-socintpoc-demo` |
