
resource "azurerm_resource_group" "projet" {
  name     = "projet-resources"
  location = "francecentral"
}

resource "azurerm_virtual_network" "projet" {
  name                = "projet-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name
}

resource "azurerm_subnet" "projet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.projet.name
  virtual_network_name = azurerm_virtual_network.projet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "projet" {
  name                = "projet-nic"
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.projet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.projet.id
  }
}

resource "azurerm_windows_virtual_machine" "projet" {
  name                = "projet-machine"
  resource_group_name = azurerm_resource_group.projet.name
  location            = azurerm_resource_group.projet.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminProjet"
  admin_password      = "12345&azerty!!"
  network_interface_ids = [
    azurerm_network_interface.projet.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}



# stocker des fichiers statiques et gérer les permissions pour sécuriser l’accès

resource "azurerm_storage_account" "projet" {
  name                     = "projetstoragetp1203" 
  resource_group_name      = azurerm_resource_group.projet.name
  location                 = azurerm_resource_group.projet.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.projet.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.projet.name
  container_access_type = "private"
}

# Déployer un backend

resource "azurerm_public_ip" "projet" {
  name                = "projet-public-ip"
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "projet" {
  name                = "projet-nsg"
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name

  security_rule {
    name                       = "NodeJS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "projet" {
  network_interface_id      = azurerm_network_interface.projet.id
  network_security_group_id = azurerm_network_security_group.projet.id
}

output "public_ip" {
  value = azurerm_public_ip.projet.ip_address
}