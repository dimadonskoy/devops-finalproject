# ----------------------
# Variables
# ----------------------
variable "open_webui_user" {
  description = "Username to access the web UI"
  default     = "admin@demo.gs"
}

variable "openai_base" {
  description = "Optional base URL to use OpenAI API with Open Web UI" 
  default     = "https://api.openai.com/v1"
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with Open Web UI"
  default     = ""
}

variable "machine" {
  description = "The machine type and image to use for the VM"
  default = {
    "gpu" : { "type" : "Standard_NC4as_T4_v3" },
    "cpu" : { "type" : "Standard_A2_v2" },
  }
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  default     = false
}

# ----------------------
# Providers
# ----------------------
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "azurerm" {
  features {}
}

