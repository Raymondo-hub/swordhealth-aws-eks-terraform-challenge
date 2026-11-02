variable "account_id" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "swordhealth"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "cluster_name" {
  type    = string
  default = "swordhealth-prod-eks"
}

variable "aws_partition" {
  type    = string
  default = "aws"
}

variable "state_bucket_arn" {
  type = string
}

variable "production_state_key" {
  type    = string
  default = "prod/eks/terraform.tfstate"
}

variable "project_role_path" {
  type    = string
  default = "swordhealth-prod-"
}

variable "project_policy_path" {
  type    = string
  default = "swordhealth-prod-"
}

variable "github_owner" {
  type    = string
  default = "Raymondo-hub"
}

variable "github_owner_id" {
  type    = string
  default = "70488951"
}

variable "github_repository" {
  type    = string
  default = "swordhealth-aws-eks-terraform-challenge"
}

variable "github_repository_id" {
  type    = string
  default = "1442384480"
}

variable "default_branch" {
  type    = string
  default = "main"
}

variable "apply_environment" {
  type    = string
  default = "production"
}

variable "plan_role_name" {
  type    = string
  default = "GitHubActionsTerraformPlan"
}

variable "apply_role_name" {
  type    = string
  default = "GitHubActionsTerraformApply"
}

variable "infrastructure_policy_name" {
  type    = string
  default = "GitHubActionsTerraformProductionInfrastructure"
}

variable "permissions_boundary_policy_name" {
  type    = string
  default = "GitHubActionsTerraformProductionBoundary"
}

variable "oidc_thumbprint_list" {
  type    = list(string)
  default = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "swordhealth-eks-challenge"
    ManagedBy = "Terraform"
  }
}
