output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnets
}

output "public_subnet_ids" {
  value = module.network.public_subnets
}

output "public_subnet_cidrs" {
  value = var.public_subnet_cidrs
}

output "admin_role_arn" {
  value = var.platform_admin_role_arn
}

output "admin_host_instance_id" {
  value = module.admin_host.instance_id
}

output "admin_host_role_arn" {
  value = module.admin_role.arn
}

output "application_namespace" {
  value = var.application_namespace
}

output "application_service_account_name" {
  value = var.application_service_account_name
}

output "database_endpoint" {
  value = module.mysql.endpoint
}

output "database_secret_arn" {
  value = module.mysql.secret_arn
}

output "application_read_only_bucket" {
  value = module.app_dependencies.read_bucket_name
}

output "application_write_only_bucket" {
  value = module.app_dependencies.write_bucket_name
}

output "application_queue_url" {
  value = module.app_dependencies.queue_url
}

output "application_role_arn" {
  value = module.workload_identity.application_role_arn
}

output "load_balancer_controller_role_arn" {
  value = module.workload_identity.load_balancer_controller_role_arn
}

output "point_in_time_restore_test_endpoint" {
  value = module.mysql.point_in_time_restore_test_endpoint
}
