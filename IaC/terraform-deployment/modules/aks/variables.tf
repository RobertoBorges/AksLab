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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for AKS monitoring"
  type        = string
}

variable "monitoring_account_id" {
  description = "Azure Monitor account ID for Prometheus metrics"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}