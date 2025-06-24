variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "random_seed" {
  description = "Random seed for unique resource names"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL for workload identity"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}