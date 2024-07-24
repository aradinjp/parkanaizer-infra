# Configuration for Azure Resource Manager (azurerm) provider
provider "azurerm" {
  features {}
}

# Creating a resource group
resource "azurerm_resource_group" "example" {
  name     = "grupa-2-apps"
  location = "Poland Central"
}

# Creating a virtual network
resource "azurerm_virtual_network" "example" {
  name                = "gr-2-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.20.0.0/16"]
}

# Creating a subnet for Azure Container Apps
resource "azurerm_subnet" "containerapps_subnet" {
  name                 = "gr-2-containerapps-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.20.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "aca-delegation"
    service_delegation {
      name = "Microsoft.App/containerApps"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Creating a subnet for Load Balancer
resource "azurerm_subnet" "loadbalancer_subnet" {
  name                 = "gr-2-loadbalancer-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.20.3.0/24"]
}

# Creating a private DNS zone
resource "azurerm_private_dns_zone" "example" {
  name                = "example.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

# Creating a flexible PostgreSQL server
resource "azurerm_postgresql_flexible_server" "example" {
  name                          = "grupa-2-psqlflexibleserver"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  version                       = "13"
  delegated_subnet_id           = azurerm_subnet.containerapps_subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.example.id
  public_network_access_enabled = false
  administrator_login           = "korwin"
  administrator_password        = "Admin1234$"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P30"

  sku_name   = "GP_Standard_D4s_v3"
}
