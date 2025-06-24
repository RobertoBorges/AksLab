variable "random_seed" {
  description = "Random string for unique resource names"
  type        = string
  default     = null
}

variable "user_object_id" {
  description = "The object ID of the user to assign admin permissions"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "AKS Lab"
    ManagedBy   = "Terraform"
  }
}