resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    deployment = "terraform"
  }
}

resource "azurerm_container_group" "jenkins-controller" {
  name                = "jenkins-controller"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = var.dns_name
  os_type             = "Linux"

  identity {
    type = "SystemAssigned"
  }

  container {
    name   = "jenkins-controller"
    image  = "jenkins/jenkins:lts"
    cpu    = "2"
    memory = "2"

    volume {
      name                 = "data-volume"
      mount_path           = "/var/jenkins_home"
      share_name           = "jenkins-storage-share"
      storage_account_name = var.jenkins_storage_credentials.account_name
      storage_account_key  = var.jenkins_storage_credentials.key
    }

    ports {
      port     = 8080
      protocol = "TCP"
    }

    ports {
      port     = 5000
      protocol = "TCP"
    }
  }

  container {
    name     = "caddy-ssl-server"
    image    = "caddy:latest"
    cpu      = "1"
    memory   = "1"
    commands = ["caddy", "reverse-proxy", "--from", "${var.dns_name}.${var.resource_group_location}.azurecontainer.io", "--to", "localhost:8080"]

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  tags = {
    deployment = "terraform"
  }
}

output "jenkins-mi-id" {
  value = azurerm_container_group.jenkins-controller.identity[0].principal_id
  sensitive = true
}