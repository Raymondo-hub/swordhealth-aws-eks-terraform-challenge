variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type    = string
  default = "swordhealth-tfstate-008003619776-us-east-1"
}

variable "production_state_key" {
  type    = string
  default = "prod/eks/terraform.tfstate"
}

variable "project_name" {
  type    = string
  default = "swordhealth"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "swordhealth-eks-challenge"
    ManagedBy = "Terraform"
  }
}
