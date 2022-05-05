terraform {

  required_version = ">=0.13"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = "~>3.0"
    }
  }
  backend "azurerm" {
    storage_account_name = "azureincode"
    container_name       = "terraform"
    key                  = "terraform.tfstate"

  }
}

provider "azurerm" {

  features {

  }
}