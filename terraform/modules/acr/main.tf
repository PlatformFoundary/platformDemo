resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_container_registry" "main" {
  name                          = "acr${replace(var.prefix, "-", "")}${random_string.suffix.result}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  zone_redundancy_enabled       = false
  tags                          = var.tags

  network_rule_set = [{
    default_action  = "Allow"
    ip_rule         = []
    virtual_network = []
  }]
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_endpoint_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr-${var.prefix}"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
