terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.8"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}
