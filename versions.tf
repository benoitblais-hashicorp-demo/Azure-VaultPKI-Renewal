terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "benoitblais-hashicorp"

    workspaces {
      name = "azure-vaultpki-renewal"
    }
  }

  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.8.0"
    }
  }
}
