
output "vm_public_ip" {
  value = azurerm_public_ip.openwebui.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.openwebui.private_ip_address
  
}

output "password" {
  sensitive = true
  value = random_password.password.result
}