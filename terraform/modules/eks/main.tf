terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.59, < 7.0" }
  }
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids

  endpoint_private_access                  = true
  endpoint_public_access                   = false
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false

  access_entries = merge(
    {
      platform_admin = {
        principal_arn = var.platform_admin_role_arn
        policy_associations = {
          cluster_admin = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
      private_admin_host = {
        principal_arn = var.admin_host_role_arn
        policy_associations = {
          cluster_admin = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    },
    {
      for role_arn in var.namespace_editor_role_arns : role_arn => {
        principal_arn = role_arn
        policy_associations = {
          namespace_editor = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
            access_scope = {
              type       = "namespace"
              namespaces = [var.application_namespace]
            }
          }
        }
      } if role_arn != var.platform_admin_role_arn && role_arn != var.admin_host_role_arn
    }
  )

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute       = true
      configuration_values = jsonencode({ enableNetworkPolicy = "true" })
    }
    eks-pod-identity-agent = { before_compute = true }
  }

  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.log_retention_days
  create_cloudwatch_log_group            = true
  encryption_config                      = { resources = ["secrets"] }
  kms_key_administrators                 = var.kms_key_administrators

  eks_managed_node_groups = {
    system = {
      name                     = "${var.cluster_name}-system"
      ami_type                 = "AL2023_x86_64_STANDARD"
      instance_types           = var.node_instance_types
      capacity_type            = "ON_DEMAND"
      min_size                 = var.node_min_size
      desired_size             = var.node_desired_size
      max_size                 = var.node_max_size
      disk_size                = 80
      iam_role_name            = "${var.cluster_name}-node-group"
      iam_role_use_name_prefix = false
      update_config            = { max_unavailable = 1 }
      labels                   = { workload = "system" }
    }
  }

  tags = var.tags
}
