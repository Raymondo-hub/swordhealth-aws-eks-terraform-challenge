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

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Use lowercase letters, digits, or hyphens for the environment name."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/20", "10.20.16.0/20"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Provide one private subnet CIDR for each of the two availability zones."
  }
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.40.0/24", "10.20.41.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Provide one public subnet CIDR for each of the two availability zones."
  }
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.32.0/24", "10.20.33.0/24"]

  validation {
    condition     = length(var.database_subnet_cidrs) == 2
    error_message = "Provide one database subnet CIDR for each of the two availability zones."
  }
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "platform_admin_role_arn" {
  description = "ARN of an existing IAM role authorized to administer the EKS cluster."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.platform_admin_role_arn))
    error_message = "Use an IAM role ARN, not a user ARN."
  }
}

variable "namespace_editor_role_arns" {
  description = "IAM role ARNs granted edit access only in the application namespace."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for role_arn in var.namespace_editor_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", role_arn))])
    error_message = "Every namespace editor must be an IAM role ARN."
  }
}

variable "node_instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "database_backup_window" {
  description = "Production RDS backup window in UTC"
  type        = string
  default     = "03:00-05:00"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "admin_host_instance_type" {
  type    = string
  default = "t3.small"
}

variable "database_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "database_allocated_storage" {
  type    = number
  default = 20
}

variable "database_max_allocated_storage" {
  type    = number
  default = 100
}

variable "database_backup_retention_days" {
  type    = number
  default = 7
}

variable "aws_backup_retention_days" {
  type    = number
  default = 35
}

variable "database_multi_az" {
  type    = bool
  default = false
}

variable "database_deletion_protection" {
  type    = bool
  default = true
}

variable "application_namespace" {
  type        = string
  description = "Kubernetes namespace whose workload service account receives the application AWS role."
  default     = "swordhealth"
}

variable "application_service_account_name" {
  type        = string
  description = "Kubernetes service account associated with the application AWS role."
  default     = "node-example"
}

variable "restore_test_schedule" {
  type    = string
  default = "cron(0 6 ? * SUN *)"
}

variable "enable_point_in_time_restore_test" {
  type    = bool
  default = false
}

variable "load_balancer_controller_version" {
  type    = string
  default = "v3.6.2"
}

variable "load_balancer_controller_policy_sha256" {
  type    = string
  default = "16f232c9d9f79366fe949c4550ad517a202380058a9e48d45a4e215044a20a6a"
}
