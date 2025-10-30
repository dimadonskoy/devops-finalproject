
output "vm_public_ip" {
  value = azurerm_public_ip.ollama.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.ollama.private_ip_address
  
}

output "password" {
  sensitive = true
  value = random_password.password.result
}

output "ssh_command" {
  value = "ssh ollama@${azurerm_public_ip.ollama.ip_address}"
}

output "ollama_api_url" {
  value = "http://${azurerm_public_ip.ollama.ip_address}:11434"
}
