output "resource_group_name" {
  description = "Name of the main resource group."
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "acr_login_server" {
  description = "Login server URL of the container registry."
  value       = module.acr.login_server
}

output "postgres_fqdn" {
  description = "Fully-qualified domain name of the PostgreSQL server (private)."
  value       = module.database.fqdn
  sensitive   = true
}

output "keyvault_uri" {
  description = "URI of the Key Vault."
  value       = module.keyvault.vault_uri
}

output "nat_gateway_public_ip" {
  description = "Public IP used for AKS outbound traffic."
  value       = module.networking.nat_gateway_public_ip
}

output "workload_identity_client_id" {
  description = "Client ID of the AKS workload identity (inject into pod annotations)."
  value       = module.aks.workload_identity_client_id
}
