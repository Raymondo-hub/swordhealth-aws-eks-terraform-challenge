module "vpc" {
  source                             = "terraform-aws-modules/vpc/aws"
  version                            = "~> 6.0"
  name                               = "${var.name}-vpc"
  cidr                               = var.vpc_cidr
  azs                                = var.availability_zones
  private_subnets                    = var.private_subnet_cidrs
  public_subnets                     = var.public_subnet_cidrs
  database_subnets                   = var.database_subnet_cidrs
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  enable_nat_gateway                 = true
  single_nat_gateway                 = var.single_nat_gateway
  one_nat_gateway_per_az             = !var.single_nat_gateway
  enable_dns_support                 = true
  enable_dns_hostnames               = true
  map_public_ip_on_launch            = false
  private_subnet_tags                = { "kubernetes.io/role/internal-elb" = "1" }
  public_subnet_tags                 = { "kubernetes.io/role/elb" = "1" }
  tags                               = var.tags
}

resource "aws_security_group" "endpoints" {
  name_prefix = "${var.name}-endpoints-"
  description = "Private HTTPS access to regional VPC interface endpoints"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
  tags              = merge(var.tags, { Name = "${var.name}-s3" })
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each = var.interface_services

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
  tags                = merge(var.tags, { Name = "${var.name}-${replace(each.key, ".", "-")}" })
}
