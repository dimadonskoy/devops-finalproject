variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "play-ground"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "example-machine"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B4ms" # 4 vCPUs, 8 GB RAM
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "openwebui"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_ip" {
  description = "IP address allowed to SSH (use '*' for any)"
  type        = string
  default     = "*"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "development"
    project     = "devops-finalproject"
    deployment  = "terraform"
  }
}

variable "openai_key" {
  description = "OpenAI API key"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
