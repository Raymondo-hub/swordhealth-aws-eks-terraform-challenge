data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-admin-"
  description = "Private SSM administration host; no inbound rules"
  vpc_id      = var.vpc_id
  egress {
    description = "Allow outbound administration traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "cluster_api" {
  security_group_id            = var.cluster_security_group_id
  referenced_security_group_id = aws_security_group.this.id
  description                  = "Allow the private SSM administration host to reach the Kubernetes API"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_iam_role_policy" "eks_describe" {
  name = "describe-eks-cluster"
  role = var.instance_role_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = var.cluster_arn
    }]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-admin-host"
  role = var.instance_role_name
  tags = var.tags
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false
  monitoring                  = true
  user_data_replace_on_change = true
  user_data                   = <<-USERDATA
    #!/bin/bash
    set -euo pipefail
    dnf install -y git jq unzip
    TF_VERSION="1.17.1"
    curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/$${TF_VERSION}/terraform_$${TF_VERSION}_linux_amd64.zip"
    unzip -o /tmp/terraform.zip -d /usr/local/bin
    rm -f /tmp/terraform.zip
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable-${var.kubernetes_version}.txt)"
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod 0755 /usr/local/bin/kubectl
  USERDATA
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }
  tags = merge(var.tags, { Name = "${var.name}-admin-host" })

  depends_on = [
    aws_iam_role_policy.eks_describe,
    aws_vpc_security_group_ingress_rule.cluster_api
  ]
}
