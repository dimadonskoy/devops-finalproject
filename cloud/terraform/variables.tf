# ----------------------
# Variables
# ----------------------

variable "ollama_user" {
  description = "Username to access Ollama"
  type        = string
  default     = "admin@demo.gs"
}

variable "openai_base" {
  description = "Optional base URL to use with Ollama API"
  type        = string
  default     = "https://api.openai.com/v1"
}

variable "machine" {
  description = "The machine type and image to use for the VM"
  type = object({
    gpu = object({ type = string })
    cpu = object({ type = string })
  })
  default = {
    gpu = { type = "Standard_NC4as_T4_v3" }
    cpu = { type = "Standard_B8ms" }
  }
}

variable "gpu_enabled" {
  description = "Is the VM GPU enabled"
  type        = bool
  default     = false
}

variable "openai_key" {
  description = "OpenAI API key"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
