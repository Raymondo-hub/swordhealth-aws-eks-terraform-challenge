variable "cluster_name" { type = string }
variable "kubernetes_version" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "platform_admin_role_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.platform_admin_role_arn))
    error_message = "Use an IAM role ARN, not a user ARN."
  }
}
variable "namespace_editor_role_arns" {
  type    = set(string)
  default = []

  validation {
    condition     = alltrue([for role_arn in var.namespace_editor_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", role_arn))])
    error_message = "Every namespace editor must be an IAM role ARN."
  }
}
variable "application_namespace" {
  type = string
}
variable "admin_host_role_arn" {
  type = string
}
variable "node_instance_types" {
  type = list(string)
}
variable "node_min_size" {
  type = number
}
variable "node_desired_size" {
  type = number
}
variable "node_max_size" {
  type = number
}

variable "kms_key_administrators" {
  description = "IAM role ARNs allowed to administer the EKS KMS encryption key"
  type        = list(string)

  validation {
    condition = alltrue([
      for role_arn in var.kms_key_administrators :
      can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", role_arn))
    ])
    error_message = "Every KMS key administrator must be an IAM role ARN."
  }
}
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}
