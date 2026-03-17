variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
}

variable "environment" {
  description = "The environment for deployment (e.g., dev, prod)."
  type        = string
}

variable "container_registry" {
  description = "The container registry URL."
  type        = string
}

variable "database_configuration" {
  description = "Database configuration settings."
  type        = map(object({
    name     = string
    username = string
    password = string
    host     = string
    port     = number
  }))
}