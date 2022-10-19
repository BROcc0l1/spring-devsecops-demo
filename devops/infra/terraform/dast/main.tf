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
    key                  = "dast.tfstate"
  }

}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azuread_service_principal" "jenkins" {
  display_name = var.jenkins_sp_name
}

data "azurerm_container_registry" "main" {
    name = "amdemoacr"
    resource_group_name = "amdemo-rg"
}

resource "azurerm_role_assignment" "jenkins-dast-rg" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.jenkins.object_id
}

resource "azurerm_service_plan" "main" {
  name = var.asp_name
  resource_group_name = data.azurerm_resource_group.main.name
  location = data.azurerm_resource_group.main.location
  os_type = "Linux"
  sku_name = "F1"

  tags = {
    deployment = "terraform"
  }
}

resource "azurerm_linux_web_app" "main" {
  name                = var.webapp_name
  resource_group_name = data.azurerm_resource_group.main.name
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

resource "azurerm_role_assignment" "webapp-acr-pull" {
  scope                = data.azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}