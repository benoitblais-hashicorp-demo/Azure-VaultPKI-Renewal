terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.14.0"
    }
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
