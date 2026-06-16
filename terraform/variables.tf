variable "project" {
  description = "Short project name used as prefix for all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod | staging | dev)."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_appgw_cidr" {
  description = "CIDR for the Application Gateway dedicated subnet (/27 minimum)."
  type        = string
  default     = "10.0.0.0/27"
}

variable "subnet_aks_cidr" {
  description = "CIDR for AKS nodes + pods (Azure CNI needs a large range, /22 recommended)."
  type        = string
  default     = "10.0.4.0/22"
}

variable "subnet_db_cidr" {
  description = "CIDR for PostgreSQL Flexible Server delegated subnet (/28 minimum)."
  type        = string
  default     = "10.0.8.0/28"
}

variable "subnet_endpoints_cidr" {
  description = "CIDR for private endpoints (ACR, Key Vault)."
  type        = string
  default     = "10.0.9.0/27"
}

# ── AKS ───────────────────────────────────────────────────────────────────────

variable "aks_kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "aks_system_node_count" {
  description = "Fixed node count for the system node pool."
  type        = number
  default     = 1
}

variable "aks_system_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "aks_user_node_min_count" {
  description = "Minimum nodes in the auto-scaling user node pool."
  type        = number
  default     = 1
}

variable "aks_user_node_max_count" {
  description = "Maximum nodes in the auto-scaling user node pool."
  type        = number
  default     = 3
}

variable "aks_user_vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "aks_api_server_authorized_ip_ranges" {
  description = "CIDR ranges allowed to reach the AKS API server. Add your local IP and GHA runner IPs here."
  type        = list(string)
  default     = []
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_admin_username" {
  type      = string
  sensitive = true
}

variable "db_sku_name" {
  description = "PostgreSQL Flexible Server SKU (e.g. B_Standard_B1ms for cheapest)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  type    = number
  default = 32768
}

variable "db_postgres_version" {
  type    = string
  default = "16"
}

# ── GitHub App / Flux ─────────────────────────────────────────────────────────

variable "github_owner" {
  description = "GitHub organisation or username that owns the repositories."
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID (numeric). Found in the App settings page."
  type        = string
}

variable "github_app_installation_id" {
  description = "Installation ID of the GitHub App on the org/user account."
  type        = string
}

# variable "github_app_pem" {
#   description = "Contents of the GitHub App private key PEM. In GHA set via: TF_VAR_github_app_pem= secrets.GH_APP_PEM"
#   type        = string
#   sensitive   = true
# }

variable "flux_repo" {
  description = "Name of the GitHub repository where Flux stores cluster manifests."
  type        = string
}

variable "flux_target_path" {
  description = "Path inside the Flux repository for this cluster's manifests."
  type        = string
  default     = "clusters/production"
}

variable "flux_branch" {
  description = "Branch Flux will track."
  type        = string
  default     = "main"
}
