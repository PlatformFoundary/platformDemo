variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }

variable "admin_username" {
  type      = string
  sensitive = true
}

variable "sku_name" { type = string }
variable "storage_mb" { type = number }
variable "postgres_version" { type = string }
variable "key_vault_id" { type = string }