# Generate Random String to Storage Names
resource "random_string" "random" {
  length  = 16
  special = false
  upper   = false
}

# Storage Account and Shares
resource "azurerm_storage_account" "storage" {
  name                     = lower(substr("${var.storage_config.name}${random_string.random.result}", 0, 24))
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_kind             = var.storage_config.kind
  account_tier             = var.storage_config.tier
  account_replication_type = var.storage_config.sku
}

resource "azurerm_storage_share" "data-share" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = var.storage_share_quota_gb.data
}

resource "azurerm_storage_share" "extensions-share" {
  name                 = "extensions"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = var.storage_share_quota_gb.extensions
}

resource "azurerm_storage_share" "logs-share" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = var.storage_share_quota_gb.logs
}

resource "azurerm_storage_share" "conf-share" {
  name                 = "conf"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = var.storage_share_quota_gb.conf
}

data "azurerm_mssql_server" "sql" {
  name                = var.sql_config.server_name
  resource_group_name = var.resource_group_name
}

data "azurerm_mssql_database" "sqldb" {
  name      = var.sql_config.db_name
  server_id = data.azurerm_mssql_server.sql.id
}

# Container Group with SonarQube and Caddy
resource "azurerm_container_group" "container" {
  name                = var.sonar_config.container_group_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  ip_address_type     = "public"
  dns_name_label      = var.sonar_config.dns_name
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "sonarqube-server"
    image  = var.sonar_config.image_name
    cpu    = var.sonar_config.required_vcpu
    memory = var.sonar_config.required_memory_in_gb

    secure_environment_variables = {
      SONARQUBE_JDBC_URL      = "jdbc:sqlserver://${data.azurerm_mssql_server.sql.name}.database.windows.net:1433;database=${data.azurerm_mssql_database.sqldb.name};user=${var.sql_server_credentials.admin_username}@${data.azurerm_mssql_server.sql.name};password=${var.sql_server_credentials.admin_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
      SONARQUBE_JDBC_USERNAME = var.sql_server_credentials.admin_username
      SONARQUBE_JDBC_PASSWORD = var.sql_server_credentials.admin_password
    }

    ports {
      port     = 9000
      protocol = "TCP"
    }

    volume {
      name                 = "data"
      mount_path           = "/opt/sonarqube/data"
      share_name           = "data"
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }

    volume {
      name                 = "extensions"
      mount_path           = "/opt/sonarqube/extensions"
      share_name           = "extensions"
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }

    volume {
      name                 = "logs"
      mount_path           = "/opt/sonarqube/logs"
      share_name           = "logs"
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }

    volume {
      name                 = "conf"
      mount_path           = "/opt/sonarqube/conf"
      share_name           = "conf"
      storage_account_name = azure
    }
  }
}