variable "resource_group_name" {
  type        = string
  description = "(Required) Resource Group to deploy to"
  default     = "dast-rg"
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

variable "asp_name" {
  type = string
  description = "(Required) Service plan name for webapp"
  default = "dast-asp"
}

variable "webapp_name" {
  type = string
  description = "(Required) Webapp name"
  default = "dast-wa"
}