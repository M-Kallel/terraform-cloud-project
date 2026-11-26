locals {
  prefix = "${var.project_name}-${var.environment}"
  tags   = { Project = var.project_name, Environment = var.environment, Owner = var.owner, ManagedBy = "Terraform" }
}
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}
module "network" {
  source   = "../../modules/network"
  prefix   = local.prefix
  vpc_cidr = var.vpc_cidr
  dual_nat = var.environment == "prod"
}
module "security" {
  source = "../../modules/security"
  prefix = local.prefix
  vpc_id = module.network.vpc_id
}
module "load_balancer" {
  source     = "../../modules/load-balancer"
  prefix     = local.prefix
  vpc_id     = module.network.vpc_id
  public_ids = module.network.public_ids
  alb_sg     = module.security.alb_sg
}
module "compute" {
  source           = "../../modules/compute"
  prefix           = local.prefix
  app_ids          = module.network.app_ids
  app_sg           = module.security.app_sg
  target_arn       = module.load_balancer.target_arn
  instance_type    = var.instance_type
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  tags             = local.tags
  depends_on       = [module.network, module.security, module.load_balancer]
}
module "database" {
  source            = "../../modules/database"
  prefix            = local.prefix
  db_ids            = module.network.db_ids
  db_sg             = module.security.db_sg
  db_instance_class = var.db_instance_class
  production        = var.environment == "prod"
}
module "storage" {
  source = "../../modules/storage"
  prefix = local.prefix
}
