variable "flux_target_path" { type = string }
variable "github_repo" { type = string }
variable "key_title" { type = string }

variable "ssh_public_key" {
  description = "OpenSSH public key to register as a GitHub deploy key on the Flux repo."
  type        = string
}

variable "ssh_private_key" {
  description = "PEM private key used by Flux in-cluster to authenticate with GitHub via SSH."
  type        = string
  sensitive   = true
}
