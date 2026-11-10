provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, length(var.private_subnet_cidrs))
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source = "../modules/network"

  name                  = local.name
  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  availability_zones    = local.azs
  private_subnet_cidrs  = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  single_nat_gateway    = var.single_nat_gateway
  tags                  = local.tags
}

module "admin_role" {
  source = "../modules/admin-role"

  name = local.name
  tags = local.tags
}

module "eks" {
  source = "../modules/eks"

  cluster_name               = "${local.name}-eks"
  kubernetes_version         = var.kubernetes_version
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnets
  platform_admin_role_arn    = var.platform_admin_role_arn
  namespace_editor_role_arns = var.namespace_editor_role_arns
  application_namespace      = var.application_namespace
  admin_host_role_arn        = module.admin_role.arn
  node_instance_types        = var.node_instance_types
  node_min_size              = var.node_min_size
  node_desired_size          = var.node_desired_size
  node_max_size              = var.node_max_size
  log_retention_days         = var.log_retention_days

  kms_key_administrators = [
    "arn:aws:iam::008003619776:role/GitHubActionsTerraformPlan"
  ]

  tags = local.tags
}
module "admin_host" {
  source = "../modules/admin-host"

  name                      = local.name
  instance_type             = var.admin_host_instance_type
  kubernetes_version        = var.kubernetes_version
  vpc_id                    = module.network.vpc_id
  private_subnet_id         = module.network.private_subnets[0]
  instance_role_name        = module.admin_role.name
  instance_role_id          = module.admin_role.id
  cluster_arn               = module.eks.cluster_arn
  cluster_security_group_id = module.eks.cluster_security_group_id
  tags                      = local.tags
}

module "mysql" {
  source = "../modules/mysql"

  name                              = local.name
  project_name                      = var.project_name
  environment                       = var.environment
  vpc_id                            = module.network.vpc_id
  database_subnet_group_name        = module.network.database_subnet_group_name
  node_security_group_ids           = toset([module.eks.node_security_group_id])
  instance_class                    = var.database_instance_class
  allocated_storage                 = var.database_allocated_storage
  max_allocated_storage             = var.database_max_allocated_storage
  multi_az                          = var.database_multi_az
  deletion_protection               = var.database_deletion_protection
  backup_retention_days             = var.database_backup_retention_days
  backup_vault_retention_days       = var.aws_backup_retention_days
  restore_test_schedule             = var.restore_test_schedule
  backup_window                     = var.database_backup_window
  enable_point_in_time_restore_test = var.enable_point_in_time_restore_test
  tags                              = local.tags
}

module "app_dependencies" {
  source = "../modules/app-dependencies"

  name = local.name
  tags = local.tags
}

module "workload_identity" {
  source = "../modules/workload-identity"

  name                                   = local.name
  account_id                             = data.aws_caller_identity.current.account_id
  cluster_name                           = module.eks.cluster_name
  cluster_arn                            = module.eks.cluster_arn
  application_namespace                  = var.application_namespace
  application_service_account_name       = var.application_service_account_name
  read_bucket_arn                        = module.app_dependencies.read_bucket_arn
  write_bucket_arn                       = module.app_dependencies.write_bucket_arn
  queue_arn                              = module.app_dependencies.queue_arn
  load_balancer_controller_version       = var.load_balancer_controller_version
  load_balancer_controller_policy_sha256 = var.load_balancer_controller_policy_sha256
  tags                                   = local.tags
}
