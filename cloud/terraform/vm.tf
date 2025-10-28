data "azurerm_platform_image" "openwebui" {
  location  = azurerm_resource_group.openwebui.location
  publisher = "Debian"
  offer     = "debian-11"
  sku       = "11"
}

resource "random_password" "password" {
  length           = 16
  special          = false
}

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/scripts/provision_script.sh",
    {
      open_webui_user = var.open_webui_user,
      open_webui_password = random_password.password.result,
      openai_base = var.openai_base,
      gpu_enabled = var.gpu_enabled,
    }) 
  }
  
  part {
    content_type = "text/cloud-config"
    content = file("${path.module}/scripts/init.yaml")
  }

  part {
    filename     = "provision_script.sh"
    content_type = "text/x-shellscript"

    # Use path.root to reference the repo root where provision_script.sh lives
    content = file("${path.root}/scripts/provision_script.sh")
  }
}

resource "azurerm_resource_group" "openwebui" {
  name     = "play-ground"
  location = "West Europe"
}

resource "azurerm_virtual_network" "openwebui" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name
}

resource "azurerm_subnet" "openwebui" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.openwebui.name
  virtual_network_name = azurerm_virtual_network.openwebui.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.openwebui.address_space[0], 8, 2)]
}

resource "azurerm_public_ip" "openwebui" {
  name                = "openwebui-ip"
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name

  allocation_method   = "Static"   # or "Dynamic"
  sku                 = "Standard" # <- FIX: use Standard instead of Basic
}


resource "azurerm_network_interface" "openwebui" {
  name                = "example-nic"
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.openwebui.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.openwebui.id
  }
}




resource "azurerm_linux_virtual_machine" "openwebui" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.openwebui.name
  location            = azurerm_resource_group.openwebui.location
  size                = var.gpu_enabled ? var.machine.gpu.type : var.machine.cpu.type
  admin_username      = "openwebui"
  network_interface_ids = [
    azurerm_network_interface.openwebui.id,
  ]

  admin_ssh_key {
    username   = "openwebui"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = data.azurerm_platform_image.openwebui.publisher
    offer     = data.azurerm_platform_image.openwebui.offer
    sku       = data.azurerm_platform_image.openwebui.sku
    version   = data.azurerm_platform_image.openwebui.version
  }

  custom_data = data.cloudinit_config.config.rendered
}



# Network Security Group 

resource "azurerm_network_security_group" "openwebui" {
  name                = "webserver"
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = [80,443]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WEB_OUT"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [8080, 443]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "openwebui" {
  subnet_id                 = azurerm_subnet.openwebui.id
  network_security_group_id = azurerm_network_security_group.openwebui.id
  
}
