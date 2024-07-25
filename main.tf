provider "azurerm" {
  features {}
}

variable "acr_password" {
  description = "Password for the Azure Container Registry"
  type        = string
}

resource "azurerm_resource_group" "example" {
  name     = "grupa-2-apps-m"
  location = "Poland Central"
}

resource "azurerm_virtual_network" "example" {
  name                = "gr-2-vn-m"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "gr-2-sn-m"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.20.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = "tmp.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                          = "grupa-2-psqlflexibleserver-m"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  version                       = "13"
  delegated_subnet_id           = azurerm_subnet.example.id
  private_dns_zone_id           = azurerm_private_dns_zone.example.id
  public_network_access_enabled = false
  administrator_login           = "korwin"
  administrator_password        = "Admin1234$"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P30"

  sku_name   = "GP_Standard_D4s_v3"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "grupa-2-acc-m"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "example" {
  name                       = "grupa-2-Environment-m"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
}

resource "azurerm_container_app" "backend" {
  name                         = "backend-app-m"
  container_app_environment_id = azurerm_container_app_environment.example.id
  resource_group_name          = azurerm_resource_group.example.name
  revision_mode                = "Single"

  registry {
    server = "parkanizeracr2024.azurecr.io"
    username    = "parkanizeracr2024"
    password_secret_name    = "docker-io-pass"
  }

  template {
    container {
      name   = "backend-container-m"
      image  = "parkanizeracr2024.azurecr.io/grupa2/parkanizer-backend:8"
      cpu    = 0.25
      memory = "0.5Gi"

      #ports {
        #port     = 8080
        #protocol = "TCP"
      #}

      env {
        name  = "SPRING_DATASOURCE_URL"
        value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.example.fqdn}:5432/parkingDb"
      }
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = "admin"
      }
      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = "Admin1234$"
      }
    }
  }

  secret { 
    name  = "docker-io-pass" 
    value = var.acr_password
  }
}

resource "azurerm_container_app" "frontend" {
  name                         = "frontend-app-m"
  container_app_environment_id = azurerm_container_app_environment.example.id
  resource_group_name          = azurerm_resource_group.example.name
  revision_mode                = "Single"

  ingress {
    external_enabled = true
    target_port = 80 

    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  registry {
    server = "parkanizeracr2024.azurecr.io"
    username    = "parkanizeracr2024"
    password_secret_name    = "docker-io-pass"
  }

  template {
    container {
      name   = "frontend-container-m"
      image  = "parkanizeracr2024.azurecr.io/grupa2/parkanizer-frontend:8"
      cpu    = 0.25
      memory = "0.5Gi"

      #ports {
        #port     = 80
        #protocol = "TCP"
      #}
      
      env {
        name  = "REACT_APP_PROTOCOL"
        value = "http"
      }
      env {
        name  = "REACT_APP_HOST"
        value = "backend"
      }
      env {
        name  = "REACT_APP_PORT"
        value = "8080"
      }
    }
  }

  secret { 
    name  = "docker-io-pass" 
    value = var.acr_password
  }
}

resource "azurerm_public_ip" "example" {
  name                = "frontend-public-ip-m"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "frontend" {
  name                = "gr2-load-balancer-m"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend-ip"
    public_ip_address_id           = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "frontend_pool" {
  loadbalancer_id = azurerm_lb.frontend.id
  name            = "frontend-backend-pool"
}

resource "azurerm_lb_probe" "frontend_probe" {
  name                = "frontend-probe"
  loadbalancer_id     = azurerm_lb.frontend.id
  port                = 80
  protocol            = "Http"
  request_path        = "/"
}

resource "azurerm_lb_rule" "frontend_rule" {
  name                           = "frontend-rule"
  loadbalancer_id                = azurerm_lb.frontend.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "frontend-ip"
  probe_id                       = azurerm_lb_probe.frontend_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.frontend_pool.id]
}