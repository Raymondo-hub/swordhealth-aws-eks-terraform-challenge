variable "name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "database_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "interface_services" {
  type = set(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "sts",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "eks",
    "eks-auth",
    "sqs"
  ]
}

variable "tags" {
  type    = map(string)
  default = {}
}
