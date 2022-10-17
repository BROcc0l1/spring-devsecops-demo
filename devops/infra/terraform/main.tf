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

# data "azurerm_key_vault_secrets" "jenkins-sa-creds" {
#   key_vault_id = data.azurerm_key_vault.jenkins-sa.id
# }

# data "azurerm_key_vault_secret" "jenkins-sa-key" {
#   for_each     = toset(data.azurerm_key_vault_secrets.jenkins-sa-creds.names)
#   name         = each.key
#   key_vault_id = data.azurerm_key_vault_secrets.jenkins-sa-creds.id
# }

# output "test_key" {
#   value = data.azurerm_key_vault_secret.jenkins-sa-key["jenkins-storage-key"]
#   sensitive = true
# }

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

  tags = {
    deployment = "terraform"
  }
}

# resource "azurerm_service_plan" "main" {
#   name = var.asp_name
#   resource_group_name = azurerm_resource_group.main.name
#   location = azurerm_resource_group.main.location
#   os_type = "Linux"
#   sku_name = "F1"

#   tags = {
#     deployment = "terraform"
#   }
# }

# resource "azurerm_linux_web_app" "main" {
#   name                = var.webapp_name
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_service_plan.main.location
#   service_plan_id     = azurerm_service_plan.main.id

#   site_config {
#     always_on = false
#   }
  
#   tags = {
#     deployment = "terraform"
#   }
# }

module "jenkins" {
  source                  = "./modules/jenkins"
  resource_group_location = var.resource_group_location
  dns_name                = var.jenkins_dns_name

  jenkins_storage_credentials = {
    account_name = data.azurerm_key_vault_secret.jenkins-storage-account-name.value
    key          = data.azurerm_key_vault_secret.jenkins-storage-access-key.value
  }
}

# output "here" {
#   value = module.jenkins.jenkins-mi[0].identity_ids
#   sensitive = true
# }

resource "azurerm_role_assignment" "aks_sp_container_registry" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = module.jenkins.jenkins-mi-id
}