# Output for the resource group name
output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

# Output for the container app name
output "container_app_name" {
  value = azurerm_container_app.example.name
}

# Output for the PostgreSQL server fully qualified domain name (FQDN)
output "postgresql_server_fqdn" {
  value = azurerm_postgresql_flexible_server.example.fqdn
}

# Output for the Load Balancer public IP address
output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}
