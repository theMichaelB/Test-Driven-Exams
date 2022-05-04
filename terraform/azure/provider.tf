terraform {

  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = "~>3.0"
    }
  }
  backend "azurerm" {
    container_name       = "terraform"
    key                  = "terraform.tfstate"

  }
}

provider "azurerm" {

  features {

  }
}