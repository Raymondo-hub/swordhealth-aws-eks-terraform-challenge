data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:ref:refs/heads/${var.default_branch}",
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:pull_request"
      ]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:environment:${var.apply_environment}"]
    }
  }
}

data "aws_iam_policy_document" "apply_infrastructure" {
  statement {
    sid    = "ReadRegionalInfrastructureInventory"
    effect = "Allow"
    actions = [
      "backup:List*",
      "ec2:Describe*",
      "eks:Describe*",
      "eks:List*",
      "logs:Describe*",
      "logs:List*",
      "rds:Describe*",
      "rds:List*",
      "kms:ListKeys",
      "kms:ListAliases"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "CreateTaggedVpcAndAdminHostResources"
    effect  = "Allow"
    actions = ["ec2:*"]
    resources = [
      "arn:${var.aws_partition}:ec2:${var.aws_region}:${var.account_id}:*/*",
      "arn:${var.aws_partition}:ec2:${var.aws_region}::image/ami-*",
      "arn:${var.aws_partition}:ec2:${var.aws_region}::snapshot/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid       = "ModifyTaggedVpcAndAdminHostResources"
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["arn:${var.aws_partition}:ec2:${var.aws_region}:${var.account_id}:*/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid     = "ManageEksClusterResources"
    effect  = "Allow"
    actions = ["eks:*"]
    resources = [
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:cluster/${var.cluster_name}",
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:nodegroup/${var.cluster_name}/*/*",
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:addon/${var.cluster_name}/*/*",
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:access-entry/${var.cluster_name}/*/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "ManageProductionRdsResources"
    effect  = "Allow"
    actions = ["rds:*"]
    resources = [
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:db:${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:snapshot:${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:subgrp:${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:pg:${var.project_name}-${var.environment}-*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "CreateTaggedProductionBackupResources"
    effect  = "Allow"
    actions = ["backup:*"]
    resources = [
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-plan:*",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-vault:${var.project_name}-${var.environment}-mysql",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:restore-testing-plan:${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "ManageTaggedProductionBackupResources"
    effect  = "Allow"
    actions = ["backup:*"]
    resources = [
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-vault:${var.project_name}-${var.environment}-mysql",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-plan:*",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:restore-testing-plan:${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "UseBackupStorageForProductionVault"
    effect    = "Allow"
    actions   = ["backup-storage:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "ManageProductionEksLogGroup"
    effect  = "Allow"
    actions = ["logs:*"]
    resources = [
      "arn:${var.aws_partition}:logs:${var.aws_region}:${var.account_id}:log-group:/aws/eks/${var.cluster_name}:*",
      "arn:${var.aws_partition}:logs:${var.aws_region}:${var.account_id}:log-group:/aws/eks/${var.cluster_name}/*"
    ]
  }

  statement {
    sid    = "CreateTaggedProductionKmsKeys"
    effect = "Allow"
    actions = [
      "kms:CreateKey"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid       = "UseKmsForProductionBackupVault"
    effect    = "Allow"
    actions   = ["kms:DescribeKey", "kms:GenerateDataKey"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]
  }

  statement {
    sid       = "CreateProductionBackupVaultKmsGrants"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:EncryptionContextKeys"
      values   = ["aws:backup:backup-vault"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["backup.*.amazonaws.com"]
    }
  }

  statement {
    sid       = "ManageTaggedProductionKmsKeys"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }

  }

  statement {
    sid       = "CreateProjectKmsGrantsForAwsResources"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid    = "ManageProductionKmsAliasTargets"
    effect = "Allow"
    actions = [
      "kms:CreateAlias",
      "kms:UpdateAlias"
    ]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid     = "ManageNamedProductionKmsAliases"
    effect  = "Allow"
    actions = ["kms:*"]
    resources = [
      "arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:alias/${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:alias/eks/${var.cluster_name}*"
    ]
  }

  statement {
    sid     = "ManageProductionApplicationBuckets"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-read-*",
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-write-*"
    ]
  }

  statement {
    sid       = "ManageProductionQueue"
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = ["arn:${var.aws_partition}:sqs:${var.aws_region}:${var.account_id}:${var.project_name}-${var.environment}-application"]
  }

  statement {
    sid    = "ReadAmazonLinuxAmiParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:${var.aws_partition}:ssm:${var.aws_region}::parameter/aws/service/ami-amazon-linux-latest/*",
      "arn:${var.aws_partition}:ssm:${var.aws_region}::parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  statement {
    sid       = "ReadTerraformCallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "apply_boundary" {
  statement {
    effect = "Allow"
    actions = [
      "backup:List*",
      "ec2:Describe*",
      "eks:Describe*",
      "eks:List*",
      "logs:Describe*",
      "logs:List*",
      "rds:Describe*",
      "rds:List*",
      "kms:ListKeys",
      "kms:ListAliases"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [
      "arn:${var.aws_partition}:ssm:${var.aws_region}::parameter/aws/service/ami-amazon-linux-latest/*",
      "arn:${var.aws_partition}:ssm:${var.aws_region}::parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["arn:${var.aws_partition}:ec2:${var.aws_region}:${var.account_id}:*/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AllocateAddress",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:CreateVpcEndpoint",
      "ec2:RunInstances"
    ]
    resources = [
      "arn:${var.aws_partition}:ec2:${var.aws_region}:${var.account_id}:*/*",
      "arn:${var.aws_partition}:ec2:${var.aws_region}::image/ami-*",
      "arn:${var.aws_partition}:ec2:${var.aws_region}::snapshot/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }

  }

  statement {
    effect = "Allow"
    actions = [
      "eks:*"
    ]
    resources = [
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:cluster/${var.cluster_name}",
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:nodegroup/${var.cluster_name}/*/*",
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:addon/${var.cluster_name}/*/*",
      "arn:${var.aws_partition}:eks:${var.aws_region}:${var.account_id}:access-entry/${var.cluster_name}/*/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["rds:*"]
    resources = [
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:db:${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:snapshot:${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:subgrp:${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:rds:${var.aws_region}:${var.account_id}:pg:${var.project_name}-${var.environment}-*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["backup:*"]
    resources = [
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-vault:${var.project_name}-${var.environment}-mysql",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-plan:*",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:restore-testing-plan:${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "backup:CreateBackupPlan",
      "backup:CreateBackupVault",
      "backup:CreateRestoreTestingPlan"
    ]
    resources = [
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-plan:*",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-vault:${var.project_name}-${var.environment}-mysql",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:restore-testing-plan:${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["backup-storage:*"]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["logs:*"]
    resources = [
      "arn:${var.aws_partition}:logs:${var.aws_region}:${var.account_id}:log-group:/aws/eks/${var.cluster_name}:*",
      "arn:${var.aws_partition}:logs:${var.aws_region}:${var.account_id}:log-group:/aws/eks/${var.cluster_name}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:CreateKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:DescribeKey", "kms:GenerateDataKey"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:EncryptionContextKeys"
      values   = ["aws:backup:backup-vault"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["backup.*.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["kms:*"]
    resources = [
      "arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:alias/${var.project_name}-${var.environment}-*",
      "arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:alias/eks/${var.cluster_name}*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-read-*",
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-write-*",
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-read-*/*",
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-write-*/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.production_state_key}*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${var.state_bucket_arn}/${var.production_state_key}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/${var.production_state_key}.tflock"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = ["arn:${var.aws_partition}:sqs:${var.aws_region}:${var.account_id}:${var.project_name}-${var.environment}-application"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*"
    ]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:*"]
    resources = [
      "arn:${var.aws_partition}:iam::${var.account_id}:role/${var.project_role_path}*",
      "arn:${var.aws_partition}:iam::${var.account_id}:instance-profile/${var.project_role_path}*",
      "arn:${var.aws_partition}:iam::${var.account_id}:policy/${var.project_policy_path}*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:${var.aws_partition}:iam::${var.account_id}:role/${var.project_role_path}*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["backup.amazonaws.com", "ec2.amazonaws.com", "eks.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:${var.aws_partition}:iam::*:role/aws-service-role/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["eks.amazonaws.com", "eks-nodegroup.amazonaws.com", "autoscaling.amazonaws.com"]
    }
  }

  statement {
    effect    = "Deny"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:${var.aws_partition}:ec2:${var.aws_region}:${var.account_id}:*/*"]

    condition {
      test     = "Null"
      variable = "ec2:CreateAction"
      values   = ["true"]
    }
  }

  statement {
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:SetDefaultPolicyVersion",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = [
      "arn:${var.aws_partition}:iam::${var.account_id}:role/${var.plan_role_name}",
      "arn:${var.aws_partition}:iam::${var.account_id}:role/${var.apply_role_name}",
      "arn:${var.aws_partition}:iam::${var.account_id}:policy/${var.permissions_boundary_policy_name}"
    ]
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprint_list
}

resource "aws_iam_role" "plan" {
  name                 = var.plan_role_name
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
  tags                 = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "apply" {
  name                 = var.apply_role_name
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
  permissions_boundary = aws_iam_policy.apply_boundary.arn
  tags                 = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "plan_infrastructure_read" {
  statement {
    sid    = "ReadBackupPlansAndSelections"
    effect = "Allow"
    actions = [
      "backup:GetBackupPlan",
      "backup:GetBackupSelection",
      "backup:GetRestoreTestingPlan",
      "backup:GetRestoreTestingSelection"
    ]
    resources = [
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:backup-plan:*",
      "arn:${var.aws_partition}:backup:${var.aws_region}:${var.account_id}:restore-testing-plan:${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql*"
    ]
  }

  statement {
    sid    = "ReadRegionalInfrastructureInventory"
    effect = "Allow"
    actions = [
      "backup:Describe*",
      "backup:List*",
      "ec2:Describe*",
      "eks:Describe*",
      "eks:List*",
      "logs:Describe*",
      "logs:List*",
      "rds:Describe*",
      "rds:List*",
      "kms:ListAliases"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "ReadAmazonLinuxAmiParameters"
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [
      "arn:${var.aws_partition}:ssm:${var.aws_region}::parameter/aws/service/ami-amazon-linux-latest/*",
      "arn:${var.aws_partition}:ssm:${var.aws_region}::parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  statement {
    sid       = "ReadPlanRoleForTerraformProvider"
    effect    = "Allow"
    actions   = ["iam:GetRole"]
    resources = ["arn:${var.aws_partition}:iam::${var.account_id}:role/${var.plan_role_name}"]
  }

  statement {
    sid    = "ReadProjectIamConfiguration"
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListEntitiesForPolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies"
    ]
    resources = [
      "arn:${var.aws_partition}:iam::${var.account_id}:role/${var.project_role_path}*",
      "arn:${var.aws_partition}:iam::${var.account_id}:instance-profile/${var.project_role_path}*",
      "arn:${var.aws_partition}:iam::${var.account_id}:policy/${var.project_policy_path}*",
      "arn:${var.aws_partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyFor*"
    ]
  }

  statement {
    sid    = "ReadProjectKmsKeys"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:ListResourceTags"
    ]
    resources = ["arn:${var.aws_partition}:kms:${var.aws_region}:${var.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid    = "ReadApplicationBucketConfiguration"
    effect = "Allow"
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-read-*",
      "arn:${var.aws_partition}:s3:::${var.project_name}-${var.environment}-${var.account_id}-write-*"
    ]
  }

  statement {
    sid       = "ReadProjectQueueConfiguration"
    effect    = "Allow"
    actions   = ["sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ListQueueTags"]
    resources = ["arn:${var.aws_partition}:sqs:${var.aws_region}:${var.account_id}:${var.project_name}-${var.environment}-application"]
  }

  statement {
    sid       = "ReadTerraformCallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "plan_infrastructure_read" {
  name        = "${var.project_name}-${var.environment}-TerraformPlanReadOnly"
  description = "Read-only Terraform planning permissions scoped to the production infrastructure."
  policy      = data.aws_iam_policy_document.plan_infrastructure_read.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan_infrastructure_read.arn
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListProductionTerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.production_state_key}*"]
    }
  }

  statement {
    sid       = "ReadProductionTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.state_bucket_arn}/${var.production_state_key}"]
  }

  statement {
    sid       = "ManageProductionTerraformLock"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/${var.production_state_key}.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "TerraformProductionStateAccess"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

data "aws_iam_policy_document" "apply_state" {
  statement {
    sid       = "ListProductionTerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.production_state_key}*"]
    }
  }

  statement {
    sid       = "ReadWriteProductionTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${var.state_bucket_arn}/${var.production_state_key}"]
  }

  statement {
    sid       = "ManageProductionTerraformLock"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/${var.production_state_key}.tflock"]
  }
}

resource "aws_iam_role_policy" "apply_state" {
  name   = "TerraformProductionStateWrite"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_state.json
}

resource "aws_iam_policy" "apply_infrastructure" {
  name        = var.infrastructure_policy_name
  description = "Terraform production infrastructure permissions for Swordhealth resources."
  policy      = data.aws_iam_policy_document.apply_infrastructure.json
  tags        = var.tags
}

resource "aws_iam_policy" "apply_boundary" {
  name        = var.permissions_boundary_policy_name
  description = "Maximum permissions boundary for the GitHub Actions Terraform apply role."
  policy      = data.aws_iam_policy_document.apply_boundary.json
  tags        = var.tags

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = length(regexall("\\S", data.aws_iam_policy_document.apply_boundary.json)) <= 6144
      error_message = "The permissions boundary policy exceeds IAM's 6,144 non-whitespace-character customer-managed policy limit."
    }
  }
}

data "aws_iam_policy_document" "project_iam" {
  statement {
    sid    = "ReadIamConfiguration"
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListEntitiesForPolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:ListOpenIDConnectProviders",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies",
      "iam:ListRoles"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageProjectRolesAndInstanceProfiles"
    effect = "Allow"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:AttachRolePolicy",
      "iam:CreateInstanceProfile",
      "iam:CreateRole",
      "iam:DeleteInstanceProfile",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:TagRole",
      "iam:UntagInstanceProfile",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = [
      "arn:${var.aws_partition}:iam::${var.account_id}:role/${var.project_role_path}*",
      "arn:${var.aws_partition}:iam::${var.account_id}:instance-profile/${var.project_role_path}*"
    ]
  }

  statement {
    sid    = "ManageProjectPolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = ["arn:${var.aws_partition}:iam::${var.account_id}:policy/${var.project_policy_path}*"]
  }

  statement {
    sid       = "PassProjectRolesToAwsServices"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:${var.aws_partition}:iam::${var.account_id}:role/${var.project_role_path}*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "backup.amazonaws.com",
        "ec2.amazonaws.com",
        "eks.amazonaws.com"
      ]
    }
  }

  statement {
    sid       = "CreateRequiredServiceLinkedRoles"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:${var.aws_partition}:iam::*:role/aws-service-role/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com",
        "autoscaling.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "project_iam" {
  name   = "TerraformProjectIAMDeployment"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.project_iam.json
}

resource "aws_iam_role_policy_attachment" "apply_infrastructure" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply_infrastructure.arn
}
