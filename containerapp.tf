# Creating a managed identity for Azure Container Apps
resource "azurerm_user_assigned_identity" "example" {
  name                = "my-containerapp-identity"  # Name of the managed identity
  resource_group_name = azurerm_resource_group.example.name  # Resource group to which the managed identity belongs
  location            = azurerm_resource_group.example.location  # Location of the managed identity
}

# Creating an environment for Azure Container Apps
resource "azurerm_container_app_environment" "example" {
  name                = "my-containerapp-env"  # Name of the container app environment
  resource_group_name = azurerm_resource_group.example.name  # Resource group to which the environment belongs
  location            = azurerm_resource_group.example.location  # Location of the container app environment
}

# Creating an Azure Container App with both backend and frontend containers
resource "azurerm_container_app" "example" {
  name                        = "parkanizer-app"  # Name of the container app
  resource_group_name         = azurerm_resource_group.example.name  # Resource group to which the container app belongs
  container_app_environment_id = azurerm_container_app_environment.example.id  # ID of the container app environment
  revision_mode               = "Automatic"  # Adding the required attribute revision_mode

  template {
    container {
      name   = "backend"  # Name of the backend container
      image  = "parkanizeracr2024.azurecr.io/grupa2/parkanizer-backend:8"  # Image of the backend container
      cpu    = 1.0  # CPU allocation for the backend container
      memory = "2.0Gi"  # Memory allocation for the backend container

      env {
        name  = "DATABASE_URL"  # Name of the environment variable for the backend container
        value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.example.fqdn}:5432/${var.db_name}?user=${var.db_admin_login}&password=${var.db_admin_password}"  # Value of the environment variable for the backend container
      }
    }

    container {
      name   = "frontend"  # Name of the frontend container
      image  = "parkanizeracr2024.azurecr.io/grupa2/parkanizer-frontend:8"  # Image of the frontend container
      cpu    = 0.5  # CPU allocation for the frontend container
      memory = "1.0Gi"  # Memory allocation for the frontend container
    }

    #scale {
      #min_replicas = 1
      #max_replicas = 3
      #rules {
        #name  = "http"
        #custom {
          #type = "http"
          #metadata {
            #concurrent_requests = "50"
          #}
        #}
      #}
    #}
  }

  identity {
    type         = "UserAssigned"  # Type of identity
    identity_ids = [azurerm_user_assigned_identity.example.id]  # ID of the user-assigned identity
  }

  tags = {
    environment = "development"  # Tags for the container app
  }
}
