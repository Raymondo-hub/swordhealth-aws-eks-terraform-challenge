moved {
  from = module.vpc
  to   = module.network.module.vpc
}

moved {
  from = aws_security_group.vpc_endpoints
  to   = module.network.aws_security_group.endpoints
}

moved {
  from = aws_vpc_endpoint.s3
  to   = module.network.aws_vpc_endpoint.s3
}

moved {
  from = aws_vpc_endpoint.interfaces["ecr.api"]
  to   = module.network.aws_vpc_endpoint.interfaces["ecr.api"]
}

moved {
  from = aws_vpc_endpoint.interfaces["ecr.dkr"]
  to   = module.network.aws_vpc_endpoint.interfaces["ecr.dkr"]
}

moved {
  from = aws_vpc_endpoint.interfaces["logs"]
  to   = module.network.aws_vpc_endpoint.interfaces["logs"]
}

moved {
  from = aws_vpc_endpoint.interfaces["sts"]
  to   = module.network.aws_vpc_endpoint.interfaces["sts"]
}

moved {
  from = aws_vpc_endpoint.interfaces["ssm"]
  to   = module.network.aws_vpc_endpoint.interfaces["ssm"]
}

moved {
  from = aws_vpc_endpoint.interfaces["ssmmessages"]
  to   = module.network.aws_vpc_endpoint.interfaces["ssmmessages"]
}

moved {
  from = aws_vpc_endpoint.interfaces["ec2messages"]
  to   = module.network.aws_vpc_endpoint.interfaces["ec2messages"]
}

moved {
  from = aws_vpc_endpoint.interfaces["eks"]
  to   = module.network.aws_vpc_endpoint.interfaces["eks"]
}

moved {
  from = aws_vpc_endpoint.interfaces["eks-auth"]
  to   = module.network.aws_vpc_endpoint.interfaces["eks-auth"]
}

moved {
  from = aws_vpc_endpoint.interfaces["sqs"]
  to   = module.network.aws_vpc_endpoint.interfaces["sqs"]
}

moved {
  from = aws_security_group.admin_host
  to   = module.admin_host.aws_security_group.this
}

moved {
  from = aws_vpc_security_group_ingress_rule.admin_host_to_cluster_api
  to   = module.admin_host.aws_vpc_security_group_ingress_rule.cluster_api
}

moved {
  from = aws_iam_role.admin_host
  to   = module.admin_role.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.admin_host_ssm
  to   = module.admin_role.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_role_policy.admin_host_eks_describe
  to   = module.admin_host.aws_iam_role_policy.eks_describe
}

moved {
  from = aws_iam_instance_profile.admin_host
  to   = module.admin_host.aws_iam_instance_profile.this
}

moved {
  from = aws_instance.admin_host
  to   = module.admin_host.aws_instance.this
}

moved {
  from = aws_s3_bucket.read_only
  to   = module.app_dependencies.aws_s3_bucket.read_only
}

moved {
  from = aws_s3_bucket.write_only
  to   = module.app_dependencies.aws_s3_bucket.write_only
}

moved {
  from = aws_s3_bucket_public_access_block.read_only
  to   = module.app_dependencies.aws_s3_bucket_public_access_block.read_only
}

moved {
  from = aws_s3_bucket_public_access_block.write_only
  to   = module.app_dependencies.aws_s3_bucket_public_access_block.write_only
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.read_only
  to   = module.app_dependencies.aws_s3_bucket_server_side_encryption_configuration.read_only
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.write_only
  to   = module.app_dependencies.aws_s3_bucket_server_side_encryption_configuration.write_only
}

moved {
  from = aws_s3_bucket_versioning.read_only
  to   = module.app_dependencies.aws_s3_bucket_versioning.read_only
}

moved {
  from = aws_s3_bucket_versioning.write_only
  to   = module.app_dependencies.aws_s3_bucket_versioning.write_only
}

moved {
  from = aws_sqs_queue.application
  to   = module.app_dependencies.aws_sqs_queue.this
}

moved {
  from = aws_security_group.database
  to   = module.mysql.aws_security_group.this
}

moved {
  from = aws_db_instance.mysql
  to   = module.mysql.aws_db_instance.this
}

moved {
  from = aws_backup_vault.mysql
  to   = module.mysql.aws_backup_vault.this
}

moved {
  from = aws_iam_role.backup
  to   = module.mysql.aws_iam_role.backup
}

moved {
  from = aws_iam_role_policy_attachment.backup
  to   = module.mysql.aws_iam_role_policy_attachment.backup
}

moved {
  from = aws_iam_role_policy_attachment.restore
  to   = module.mysql.aws_iam_role_policy_attachment.restore
}

moved {
  from = aws_backup_plan.mysql
  to   = module.mysql.aws_backup_plan.this
}

moved {
  from = aws_backup_selection.mysql
  to   = module.mysql.aws_backup_selection.this
}

moved {
  from = aws_backup_restore_testing_plan.mysql
  to   = module.mysql.aws_backup_restore_testing_plan.this
}

moved {
  from = aws_backup_restore_testing_selection.mysql
  to   = module.mysql.aws_backup_restore_testing_selection.this
}

moved {
  from = aws_db_instance.point_in_time_restore_test
  to   = module.mysql.aws_db_instance.point_in_time_restore_test
}

moved {
  from = aws_iam_role.application
  to   = module.workload_identity.aws_iam_role.application
}

moved {
  from = aws_iam_role_policy.application
  to   = module.workload_identity.aws_iam_role_policy.application
}

moved {
  from = aws_eks_pod_identity_association.application
  to   = module.workload_identity.aws_eks_pod_identity_association.application
}

moved {
  from = aws_iam_role.load_balancer_controller
  to   = module.workload_identity.aws_iam_role.load_balancer_controller
}

moved {
  from = aws_iam_policy.load_balancer_controller
  to   = module.workload_identity.aws_iam_policy.load_balancer_controller
}

moved {
  from = aws_iam_role_policy_attachment.load_balancer_controller
  to   = module.workload_identity.aws_iam_role_policy_attachment.load_balancer_controller
}

moved {
  from = aws_eks_pod_identity_association.load_balancer_controller
  to   = module.workload_identity.aws_eks_pod_identity_association.load_balancer_controller
}
