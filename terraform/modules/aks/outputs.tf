output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "host" {
  value     = azurerm_kubernetes_cluster.main.kube_admin_config[0].host
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.main.kube_admin_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.main.kube_admin_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.main.kube_admin_config[0].cluster_ca_certificate
  sensitive = true
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive = true
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "workload_identity_object_id" {
  value = azurerm_user_assigned_identity.workload.principal_id
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}
