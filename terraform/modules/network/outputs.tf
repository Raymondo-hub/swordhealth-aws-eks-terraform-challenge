output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "endpoint_security_group_id" {
  value = aws_security_group.endpoints.id
}
