output "azure_location" {
  description = "Azure region used"
  value       = var.azure_location
}

output "public_ip" {
  description = "IP publique de la VM backend"
  value       = azurerm_public_ip.projet.ip_address
}

output "backend_url" {
  description = "URL du backend Node.js"
  value       = "http://${azurerm_public_ip.projet.ip_address}:3000"
}

output "storage_account_name" {
  description = "Nom du compte de stockage"
  value       = azurerm_storage_account.projet.name
}

output "storage_connection_string" {
  description = "Connection string Azure Storage pour le backend"
  value       = azurerm_storage_account.projet.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_key" {
  description = "Clé primaire du compte de stockage (SAS)"
  value       = azurerm_storage_account.projet.primary_access_key
  sensitive   = true
}
