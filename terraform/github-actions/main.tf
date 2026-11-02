provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

module "github_oidc" {
  source = "../modules/github-oidc"

  account_id           = data.aws_caller_identity.current.account_id
  aws_region           = var.aws_region
  aws_partition        = data.aws_partition.current.partition
  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = "${var.project_name}-${var.environment}-eks"
  state_bucket_arn     = "arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket_name}"
  production_state_key = var.production_state_key
  tags                 = var.tags
}

import {
  to = module.github_oidc.aws_iam_openid_connect_provider.github
  id = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

import {
  to = module.github_oidc.aws_iam_role.plan
  id = "GitHubActionsTerraformPlan"
}

import {
  to = module.github_oidc.aws_iam_role.apply
  id = "GitHubActionsTerraformApply"
}

import {
  to = module.github_oidc.aws_iam_role_policy_attachment.plan_read_only
  id = "GitHubActionsTerraformPlan/arn:aws:iam::aws:policy/ReadOnlyAccess"
}

import {
  to = module.github_oidc.aws_iam_role_policy.apply_state
  id = "GitHubActionsTerraformApply:TerraformProductionStateWrite"
}
