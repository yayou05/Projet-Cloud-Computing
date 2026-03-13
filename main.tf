
resource "azurerm_resource_group" "projet" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_virtual_network" "projet" {
  name                = var.virtual_network_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name
}

resource "azurerm_subnet" "projet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.projet.name
  virtual_network_name = azurerm_virtual_network.projet.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_interface" "projet" {
  name                = var.network_interface_name
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.projet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.projet.id
  }
}

resource "azurerm_linux_virtual_machine" "projet" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.projet.name
  location            = azurerm_resource_group.projet.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.projet.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}



# stocker des fichiers statiques et gérer les permissions pour sécuriser l’accès

resource "azurerm_storage_account" "projet" {
  name                     = var.storage_account_name
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
  name                = var.public_ip_name
  location            = azurerm_resource_group.projet.location
  resource_group_name = azurerm_resource_group.projet.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "projet" {
  name                = var.network_security_group_name
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

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "projet" {
  network_interface_id      = azurerm_network_interface.projet.id
  network_security_group_id = azurerm_network_security_group.projet.id
}
