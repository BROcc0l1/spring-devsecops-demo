variable "resource_group_name" {
  type        = string
  description = "(Required) Resource Group to deploy to"
  default     = "amdemo-rg"
}

variable "resource_group_location" {
  type        = string
  description = "(Required) Resource Group location"
  default     = "northeurope"
}

variable "jenkins_sp_name" {
  type        = string
  description = "(Required) Jenkins service principal name"
  default     = "am-demo-jenkins"
}
variable "jenkins_sa_resource_group_name" {
  type        = string
  description = "(Required) Resource Group to deploy Jenkins"
  default     = "jenkins-storage-rg"
}

variable "acr_name" {
  type = string
  description = "(Required) Container registry name to store artifacts"
  default = "amdemoacr"
}

variable "asp_name" {
  type = string
  description = "(Required) Service plan name for webapp"
  default = "amdemo-asp"
}

variable "webapp_name" {
  type = string
  description = "(Required) Webapp name"
  default = "am-demo-wa"
}

variable "jenkins_sa_keyvault_name" {
  type        = string
  description = "Tha name of KeyVault that contains Jenkins storage account credentials"
  default     = "jenkins-sa-kv0" // "jenkins-sa-kv"
}

variable "jenkins_dns_name" {
  type        = string
  description = "(Required) Domain name for ACI"
  default     = "am-demo-jenkins"
}
