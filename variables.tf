variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "projet-resources"
}

variable "virtual_network_name" {
  description = "Virtual network name"
  type        = string
  default     = "projet-network"
}

variable "vnet_address_space" {
  description = "CIDR for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "internal"
}

variable "subnet_address_prefix" {
  description = "CIDR for subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "network_interface_name" {
  description = "Network interface name"
  type        = string
  default     = "projet-nic"
}

variable "vm_name" {
  description = "Virtual machine name"
  type        = string
  default     = "projet-machine"
}

variable "vm_size" {
  description = "Virtual machine size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "adminProjet"
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}

variable "storage_account_name" {
  description = "Azure Storage Account name (must be globally unique, 3-24 lowercase chars)"
  type        = string
}

variable "public_ip_name" {
  description = "Public IP resource name"
  type        = string
  default     = "projet-public-ip"
}

variable "network_security_group_name" {
  description = "Network security group name"
  type        = string
  default     = "projet-nsg"
}
