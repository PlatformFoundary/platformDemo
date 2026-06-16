variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "tags" { type = map(string) }
variable "subnet_endpoint_id" { type = string }
variable "private_dns_zone_id" { type = string }
variable "aks_workload_identity_object_id" { type = string }
variable "public_ip_cidr" { type = list(string) }
