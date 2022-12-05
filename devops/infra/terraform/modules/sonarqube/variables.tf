variable "resource_group_name" {
  type        = string
  description = "(Required) Resource Group to deploy to"
}

variable "resource_group_location" {
  type        = string
  description = "(Required) Resource Group location"
}

variable "sonar_config" {
  type = object({
    image_name            = string
    container_group_name  = string
    dns_name              = string
    required_memory_in_gb = string
    required_vcpu         = string
  })

  description = "(Required) SonarQube Configuration"
}

variable "sql_server_credentials" {
  type = object({
    admin_username = string
    admin_password = string
  })
  sensitive = true
}

variable "sql_config" {
  type = map(string)
  description = "(optional) describe your variable"
  default = {
    server_name = "poc-sonar-sql"
    db_name = "sonar-poc-db"
  }
}

variable "storage_share_quota_gb" {
  type = object({
    data       = number
    extensions = number
    logs       = number
    conf       = number
  })
  default = {
    data       = 10
    extensions = 10
    logs       = 10
    conf       = 1
  }
}

variable "storage_config" {
  type = object({
    name = string
    kind = string
    sku  = string
    tier = string
  })
  default = {
    name = "sonarqubestore"
    kind = "StorageV2"
    sku  = "LRS"
    tier = "Standard"
  }
}