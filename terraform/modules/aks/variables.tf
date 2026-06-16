variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "acr_id" { type = string }
variable "kubernetes_version" { type = string }
variable "system_node_count" { type = number }
variable "system_vm_size" { type = string }
variable "user_node_min_count" { type = number }
variable "user_node_max_count" { type = number }
variable "user_vm_size" { type = string }

variable "api_server_authorized_ip_ranges" {
  description = "List of CIDR blocks allowed to reach the AKS API server."
  type        = list(string)
  default     = []
}
