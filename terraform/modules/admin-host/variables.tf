variable "name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "instance_role_name" {
  type = string
}

variable "instance_role_id" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "cluster_security_group_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
