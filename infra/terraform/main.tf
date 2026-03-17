# Terraform Configuration for MoveEasy Core Infrastructure

provider "aws" {
  region = var.region
}

module "network" {
  source = "./modules/network"
}

module "compute" {
  source = "./modules/compute"
}

module "database" {
  source = "./modules/database"
}

module "container_registry" {
  source = "./modules/container_registry"
}