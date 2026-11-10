variable "name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "database_subnet_group_name" {
  type = string
}

variable "node_security_group_ids" {
  type = set(string)
}

variable "database_name" {
  type    = string
  default = "swordhealth"
}

variable "master_username" {
  type    = string
  default = "appadmin"
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  type    = number
  default = 35
}

variable "backup_vault_retention_days" {
  type    = number
  default = 35
}

variable "backup_schedule" {
  type    = string
  default = "cron(0 5 ? * * *)"
}

variable "backup_window" {
  description = "Preferred RDS backup window in UTC"
  type        = string
  default     = "03:00-05:00"
}
variable "maintenance_window" {
  type    = string
  default = "sun:05:00-sun:06:00"
}

variable "restore_test_schedule" {
  type    = string
  default = "cron(0 6 ? * SUN *)"
}

variable "restore_test_window_days" {
  type    = number
  default = 7
}

variable "restore_test_validation_window_hours" {
  type    = number
  default = 2
}

variable "enable_point_in_time_restore_test" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
