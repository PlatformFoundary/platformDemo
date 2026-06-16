output "fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn }
output "server_name" { value = azurerm_postgresql_flexible_server.main.name }
output "db_name" { value = azurerm_postgresql_flexible_server_database.app.name }
