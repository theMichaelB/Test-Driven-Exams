terraform {

  required_version = ">=0.12"
  
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

    # rather than defining this inline, the SAS Token can also be sourced
    # from an Environment Variable - more information is available below.
    sas_token = "?sv=2020-08-04&ss=b&srt=s&sp=rwdlacitfx&se=2023-05-04T13:04:16Z&st=2022-05-04T05:04:16Z&spr=https&sig=znWf%2Be33OqDJ6NykIi2UUX2K%2FmMTFsas4%2FACqV77y7k%3D"
  }
}

provider "azurerm" {

      subscription_id="ee2fdc11-10ed-455e-b108-5834dd20be7f"
  features {

  }
}

#BlobEndpoint=https://azureincode.blob.core.windows.net/;QueueEndpoint=https://azureincode.queue.core.windows.net/;FileEndpoint=https://azureincode.file.core.windows.net/;TableEndpoint=https://azureincode.table.core.windows.net/;SharedAccessSignature=sv=2020-08-04&ss=b&srt=s&sp=rwdlacitfx&se=2023-05-04T13:04:16Z&st=2022-05-04T05:04:16Z&spr=https&sig=znWf%2Be33OqDJ6NykIi2UUX2K%2FmMTFsas4%2FACqV77y7k%3D