output "cluster_name" { value = module.cluster.cluster_name }
output "cluster_arn" { value = module.cluster.cluster_arn }
output "cluster_endpoint" { value = module.cluster.cluster_endpoint }
output "cluster_security_group_id" { value = module.cluster.cluster_security_group_id }
output "node_security_group_id" { value = module.cluster.node_security_group_id }
output "oidc_provider_arn" { value = module.cluster.oidc_provider_arn }
