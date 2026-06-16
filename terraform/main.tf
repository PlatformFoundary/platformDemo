locals {
  prefix = "${var.project}-${var.environment}"
  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.prefix
  location = var.location
  tags     = local.tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  prefix                = local.prefix
  tags                  = local.tags
  vnet_address_space    = var.vnet_address_space
  subnet_aks_cidr       = var.subnet_aks_cidr
  subnet_db_cidr        = var.subnet_db_cidr
  subnet_endpoints_cidr = var.subnet_endpoints_cidr
}

# ── Container Registry ────────────────────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  prefix                        = local.prefix
  tags                          = local.tags
  subnet_endpoint_id            = module.networking.subnet_endpoints_id
  private_dns_zone_id           = module.networking.acr_private_dns_zone_id
}

# ── AKS ───────────────────────────────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  prefix                          = local.prefix
  tags                            = local.tags
  subnet_id                       = module.networking.subnet_aks_id
  acr_id                          = module.acr.acr_id
  kubernetes_version              = var.aks_kubernetes_version
  system_node_count               = var.aks_system_node_count
  system_vm_size                  = var.aks_system_vm_size
  user_node_min_count             = var.aks_user_node_min_count
  user_node_max_count             = var.aks_user_node_max_count
  user_vm_size                    = var.aks_user_vm_size
  api_server_authorized_ip_ranges = concat(var.aks_api_server_authorized_ip_ranges, ["${module.networking.nat_gateway_public_ip}/32"])

  depends_on = [module.networking]
}

# ── Key Vault ─────────────────────────────────────────────────────────────────
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  prefix                          = local.prefix
  tags                            = local.tags
  subnet_endpoint_id              = module.networking.subnet_endpoints_id
  private_dns_zone_id             = module.networking.keyvault_private_dns_zone_id
  aks_workload_identity_object_id = module.aks.workload_identity_object_id
  public_ip_cidr                  = var.aks_api_server_authorized_ip_ranges
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# ── Flux CD ───────────────────────────────────────────────────────────────────

data "github_app_token" "flux" {
  app_id          = var.github_app_id
  installation_id = var.github_app_installation_id
  pem_file        = file("/home/viru/Downloads/socpocv2.2026-06-13.private-key.pem")
}

module "flux" {
  source = "./modules/flux"

  flux_target_path = var.flux_target_path
  github_repo      = var.flux_repo
  ssh_public_key   = tls_private_key.flux.public_key_openssh
  ssh_private_key  = tls_private_key.flux.private_key_pem
  key_title        = "flux-deploy-key-${local.prefix}"

  depends_on = [module.aks]
}

# ── Database ──────────────────────────────────────────────────────────────────
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  prefix              = local.prefix
  tags                = local.tags
  subnet_id           = module.networking.subnet_db_id
  private_dns_zone_id = module.networking.postgres_private_dns_zone_id
  admin_username      = var.db_admin_username
  sku_name            = var.db_sku_name
  storage_mb          = var.db_storage_mb
  postgres_version    = var.db_postgres_version
  key_vault_id        = module.keyvault.vault_id

  # Ensure the private DNS VNet link exists before the server is provisioned
  depends_on = [module.networking, module.keyvault]
}