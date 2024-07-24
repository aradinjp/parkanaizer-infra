# Creating a public IP address for the Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Creating a Load Balancer
resource "azurerm_lb" "example" {
  name                = "my-load-balancer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "frontendConfig"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Creating a Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "example" {
  name                = "backendPool"
  loadbalancer_id     = azurerm_lb.example.id
  resource_group_name = azurerm_resource_group.example.name
}

# Creating a Load Balancer rule
resource "azurerm_lb_rule" "example" {
  name                          = "http-rule"
  resource_group_name           = azurerm_resource_group.example.name
  loadbalancer_id               = azurerm_lb.example.id
  frontend_ip_configuration_name = azurerm_lb.example.frontend_ip_configuration[0].name
  backend_address_pool_id       = azurerm_lb_backend_address_pool.example.id
  protocol                      = "Tcp"
  frontend_port                 = 80
  backend_port                  = 80
  enable_floating_ip            = false
  idle_timeout_in_minutes       = 5
}

# Creating a WAF (Application Gateway)
resource "azurerm_application_gateway" "example" {
  name                = "my-application-gateway"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.loadbalancer_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendIpConfig"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }

  backend_address_pool {
    name = "backendPool"
  }

  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appGatewayHttpListener"
    frontend_ip_configuration_name = "frontendIpConfig"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  url_path_map {
    name               = "urlPathMap"
    default_backend_address_pool_name = "backendPool"
    default_backend_http_settings_name = "appGatewayBackendHttpSettings"
  }

  gateway_request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "appGatewayHttpListener"
    backend_address_pool_name  = "backendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}
