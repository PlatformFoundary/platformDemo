# ── Managed Identity for the cluster control plane ────────────────────────────

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Allow AKS to pull images from ACR without storing credentials
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "main" {
  name                      = "aks-${var.prefix}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "aks-${var.prefix}"
  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = false
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = false # required to use kube_admin_config credentials
  tags                      = var.tags

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # System node pool – only critical add-ons run here
  default_node_pool {
    name                 = "system"
    orchestrator_version = var.kubernetes_version
    os_disk_size_gb      = 128
    os_disk_type         = "Managed"
    vm_size              = var.system_vm_size
    auto_scaling_enabled = true
    vnet_subnet_id       = var.subnet_id
    max_count            = 4
    min_count            = 1
    node_labels = {
      taskType = "system"
      cpu      = "true"
      infra    = "true"
    }
    temporary_name_for_rotation = "tmpap"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_policy    = null
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }

  # Mounts Key Vault secrets as files / env vars in pods
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}

# ── User Node Pool (application workloads) ────────────────────────────────────

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  vnet_subnet_id        = var.subnet_id
  os_disk_type          = "Managed"
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  auto_scaling_enabled  = true
  mode                  = "User"
  tags                  = var.tags

  upgrade_settings {
    max_surge = "33%"
  }
}

# ── Workload Identity (application pods → Key Vault / other Azure services) ───

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-workload-${var.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Federated credential binds the Kubernetes service account to the Azure identity
resource "azurerm_federated_identity_credential" "workload" {
  name                = "fic-workload-${var.prefix}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  # Must match the service account used by your application pods
  subject = "system:serviceaccount:default:workload-sa"
}
