terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.5"
}

variable "location" {
  description = "The Azure region your resources will be deployed"
  default     = "eastus"
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "example" {
  name = "terraform-learn-state-rg"
}

resource "azurerm_virtual_network" "example_new" {
  name                = "terraform-learn-state-vnet-new"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example_new" {
  name                 = "terraform-learn-state-subnet-new"
  address_prefixes     = ["10.0.1.0/24"]
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example_new.name
}

resource "azurerm_public_ip" "example_new" {
  name                = "terraform-learn-state-pip-new"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "example_new" {
  name                = "terraform-learn-state-nsg-new"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "example_new" {
  name                = "terraform-learn-state-nic-new"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "terraform-learn-state-ipconfig"
    subnet_id                     = azurerm_subnet.example_new.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example_new.id
  }
}

resource "azurerm_linux_virtual_machine" "example_new" {
  name                  = "terraform-learn-state-vm-new"
  location              = data.azurerm_resource_group.example.location
  resource_group_name   = data.azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example_new.id]
  size                  = "Standard_F2"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  admin_username                  = "adminuser"
  admin_password                  = "Password123&*()"
  disable_password_authentication = false
  custom_data                       = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sed -i -e 's/80/8080/' /etc/apache2/ports.conf
              echo "Hello World" > /var/www/html/index.html
              sudo systemctl restart apache2
              EOF
              )
}

output "public_ip" {
  value       = azurerm_linux_virtual_machine.example_new.public_ip_address
  description = "The public IP of the web server"
}

output "security_group" {
  value = azurerm_network_security_group.example_new.id
}

output "instance_id" {
  value = azurerm_linux_virtual_machine.example_new.id
}
