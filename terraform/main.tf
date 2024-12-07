provider "azurerm" {
  features {}
  
  subscription_id = "2fa0e512-f70e-430f-9186-1b06543a848e"
}

resource "azurerm_resource_group" "candidate_rg" {
  name     = "Oleksii-CANDIDATE_RG"
  location = "westeurope"
}

resource "azurerm_virtual_network" "candidate_vnet" {
  name                = "candidate-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.candidate_rg.location
  resource_group_name = azurerm_resource_group.candidate_rg.name
}

resource "azurerm_subnet" "candidate_subnet" {
  name                 = "candidate-subnet"
  resource_group_name  = azurerm_resource_group.candidate_rg.name
  virtual_network_name = azurerm_virtual_network.candidate_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "candidate_ip" {
  name                = "candidate-ip"
  location            = azurerm_resource_group.candidate_rg.location
  resource_group_name = azurerm_resource_group.candidate_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "candidate_nic" {
  name                = "candidate-nic"
  location            = azurerm_resource_group.candidate_rg.location
  resource_group_name = azurerm_resource_group.candidate_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.candidate_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.candidate_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "candidate_vm" {
  name                = "candidate-vm"
  resource_group_name = azurerm_resource_group.candidate_rg.name
  location            = azurerm_resource_group.candidate_rg.location
  size                = "Standard_B1ls"

  admin_username      = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.candidate_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "vm_public_ip" {
  value = azurerm_public_ip.candidate_ip.ip_address
}
