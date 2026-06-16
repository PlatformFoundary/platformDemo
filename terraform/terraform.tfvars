project     = "socintpoc"
environment = "demo"
location    = "eastus2"

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space    = ["10.24.0.0/16"]
subnet_aks_cidr       = "10.24.4.0/22"
subnet_db_cidr        = "10.24.8.0/28"
subnet_endpoints_cidr = "10.24.9.0/27"

# ── AKS ───────────────────────────────────────────────────────────────────────
aks_kubernetes_version              = "1.34"
aks_system_node_count               = 1
aks_system_vm_size                  = "Standard_D2ads_v5"
aks_user_node_min_count             = 1
aks_user_node_max_count             = 3
aks_user_vm_size                    = "Standard_D2ads_v5"
aks_api_server_authorized_ip_ranges = ["223.185.134.168/32","49.37.179.24/32"]

# ── Database ──────────────────────────────────────────────────────────────────
db_admin_username   = "pgadmin"         # override via GHA secret TF_VAR_db_admin_username
db_sku_name         = "B_Standard_B1ms" # Burstable 1 vCPU, 2 GB RAM — cheapest Flexible Server SKU
db_storage_mb       = 32768
db_postgres_version = "16"

# ── GitHub App / Flux ─────────────────────────────────────────────────────────
github_owner               = "PlatformFoundary"
github_app_id              = "4044924"   # GHA secret: TF_VAR_github_app_id
github_app_installation_id = "140061174" # GHA secret: TF_VAR_github_app_installation_id
flux_repo                  = "platformDemo"
flux_target_path           = "clusters/demo"
flux_branch                = "main"
