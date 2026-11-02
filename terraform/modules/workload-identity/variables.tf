variable "name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "application_namespace" {
  type    = string
  default = "swordhealth"
}

variable "application_service_account_name" {
  type    = string
  default = "node-example"
}

variable "read_bucket_arn" {
  type = string
}

variable "write_bucket_arn" {
  type = string
}

variable "queue_arn" {
  type = string
}

variable "controller_namespace" {
  type    = string
  default = "kube-system"
}

variable "controller_service_account_name" {
  type    = string
  default = "aws-load-balancer-controller"
}

variable "load_balancer_controller_version" {
  type    = string
  default = "v3.6.2"
}

variable "load_balancer_controller_policy_sha256" {
  type    = string
  default = "16f232c9d9f79366fe949c4550ad517a202380058a9e48d45a4e215044a20a6a"
}

variable "tags" {
  type    = map(string)
  default = {}
}
