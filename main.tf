
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