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

variable "aks_kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet identity to grant pull access"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}