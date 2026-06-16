resource "random_password" "postgres" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "psql-${var.prefix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = var.admin_username
  administrator_password        = random_password.postgres.result
  sku_name                      = var.sku_name
  zone                          = "1"
  storage_mb                    = var.storage_mb
  tags                          = var.tags

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # high_availability {
  #   mode                      = "ZoneRedundant"
  #   standby_availability_zone = "2"
  # }

  lifecycle {
    # Prevent accidental destruction of production data
    # prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "tododb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Store the username in Key Vault
resource "azurerm_key_vault_secret" "postgres_username" {
  name         = "postgres-admin-username"
  value        = azurerm_postgresql_flexible_server.main.administrator_login
  key_vault_id = var.key_vault_id
}

# Store the password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = azurerm_postgresql_flexible_server.main.administrator_password
  key_vault_id = var.key_vault_id
}