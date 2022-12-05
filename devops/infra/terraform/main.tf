terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.27.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatesa12353450"// "tfstatesa1235345"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

}

provider "azurerm" {
  features {}
}

data "azurerm_key_vault" "jenkins-sa" {
  name                = var.jenkins_sa_keyvault_name
  resource_group_name = var.jenkins_sa_resource_group_name
}

data "azurerm_key_vault_secret" "jenkins-storage-account-name" {
  name         = "jenkins-storage-account-name"
  key_vault_id = data.azurerm_key_vault.jenkins-sa.id
}

data "azurerm_key_vault_secret" "jenkins-storage-access-key" {
  name         = "jenkins-storage-key"
  key_vault_id = data.azurerm_key_vault.jenkins-sa.id
}

data "azuread_service_principal" "jenkins" {
  display_name = var.jenkins_sp_name
}

data "azurerm_resource_group" "dast" {
  name = "dast-rg"
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    deployment = "terraform"
  }
}

resource "azurerm_container_registry" "main" {
  name = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  sku = "Basic"
  admin_enabled = true

  tags = {
    deployment = "terraform"
  }
}

resource "azurerm_service_plan" "main" {
  name = var.asp_name
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  os_type = "Linux"
  sku_name = "F1"

  tags = {
    deployment = "terraform"
  }
}

resource "azurerm_linux_web_app" "main" {
  name                = var.webapp_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = false
    container_registry_use_managed_identity = true
  }

  app_settings = {
    "WEBSITES_PORT" = "8080"
  }

  identity {
    type = "SystemAssigned"
  }
  
  tags = {
    deployment = "terraform"
  }
}

module "jenkins" {
  source                  = "./modules/jenkins"
  resource_group_location = var.resource_group_location
  dns_name                = var.jenkins_dns_name

  jenkins_storage_credentials = {
    account_name = data.azurerm_key_vault_secret.jenkins-storage-account-name.value
    key          = data.azurerm_key_vault_secret.jenkins-storage-access-key.value
  }
}

resource "azurerm_role_assignment" "jenkins-dast-rg" {
  scope                = data.azurerm_resource_group.dast.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.jenkins.object_id
}

resource "azurerm_role_assignment" "jenkins-acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.jenkins.object_id
}

resource "azurerm_role_assignment" "jenkins-webapp-contributor" {
  scope                = azurerm_linux_web_app.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.jenkins.object_id
}
resource "azurerm_role_assignment" "webapp-acr-pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

# SonarQube

# data "azurerm_resource_group" {
#   name = "sonarqube-rg"
# }

# data "azurerm_key_vault" "sonar" {
#   name                = "sonar-kv"
#   resource_group_name = data.azurerm_resource_group.name
# }
# data "azurerm_key_vault_secret" "sonar-jdbc-username" {
#   name         = "SONARQUBE-JDBC-USERNAME"
#   key_vault_id = data.azurerm_key_vault.sonar.id
# }

# data "azurerm_key_vault_secret" "sonar-jdbc-password" {
#   name         = "SONARQUBE-JDBC-PASSWORD"
#   key_vault_id = data.azurerm_key_vault.sonar.id
# }

# module "sonarqube" {
#   source = "./modules/sonarqube"
#   resource_group_name     = data.azurerm_resource_group.instance.name
#   resource_group_location = data.azurerm_resource_group.instance.location

#   sql_server_credentials = {
#     admin_username = data.azurerm_key_vault_secret.sonar-jdbc-username.value
#     admin_password = data.azurerm_key_vault_secret.sonar-jdbc-password.value
#   }

#   sonar_config = {
#     container_group_name  = "sonarqubecontainer"
#     required_memory_in_gb = "4"
#     required_vcpu         = "2"
#     image_name            = "sonarqube:latest"
#     dns_name              = "am-demo-sonarqube"
#   }

#   storage_share_quota_gb = {
#     data       = 50
#     extensions = 10
#     logs       = 20
#     conf       = 1
#   }
# }