variable "resource_group_name" {
  type        = string
  description = "(Required) Resource Group to deploy Jenkins"
  default     = "jenkins-rg"
}

variable "resource_group_location" {
  type        = string
  description = "(Required) Resource Group location"
}

variable "dns_name" {
  type        = string
  description = "(Required) Domain name for ACI"
}

variable "jenkins_storage_credentials" {
  type = object({
    account_name = string
    key          = string
  })
  sensitive = true
}
