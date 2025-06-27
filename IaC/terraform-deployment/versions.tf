terraform {
  required_version = ">= 1.0"

  # Remote backend configuration for Azure Storage Account
  # Backend configuration values will be provided during initialization
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}