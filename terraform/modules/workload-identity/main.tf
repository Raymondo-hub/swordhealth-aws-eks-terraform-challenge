locals {
  controller_policy_sha256 = "16f232c9d9f79366fe949c4550ad517a202380058a9e48d45a4e215044a20a6a"
}

resource "aws_iam_role" "application" {
  name = "${var.name}-application"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = {
        StringEquals = {
          "aws:SourceAccount"                         = var.account_id
          "aws:RequestTag/eks-cluster-arn"            = var.cluster_arn
          "aws:RequestTag/kubernetes-namespace"       = var.application_namespace
          "aws:RequestTag/kubernetes-service-account" = var.application_service_account_name
        }
        ArnEquals = { "aws:SourceArn" = var.cluster_arn }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "application" {
  name = "s3-and-sqs-access"
  role = aws_iam_role.application.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListReadOnlyBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.read_bucket_arn
      },
      {
        Sid      = "ReadObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${var.read_bucket_arn}/*"
      },
      {
        Sid      = "WriteObjects"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.write_bucket_arn}/*"
      },
      {
        Sid    = "ConsumeMessages"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Resource = var.queue_arn
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "application" {
  cluster_name    = var.cluster_name
  namespace       = var.application_namespace
  service_account = var.application_service_account_name
  role_arn        = aws_iam_role.application.arn
}

data "http" "load_balancer_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${var.load_balancer_controller_version}/docs/install/iam_policy.json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_role" "load_balancer_controller" {
  name = "${var.name}-load-balancer-controller"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = {
        StringEquals = {
          "aws:SourceAccount"                         = var.account_id
          "aws:RequestTag/eks-cluster-arn"            = var.cluster_arn
          "aws:RequestTag/kubernetes-namespace"       = var.controller_namespace
          "aws:RequestTag/kubernetes-service-account" = var.controller_service_account_name
        }
        ArnEquals = { "aws:SourceArn" = var.cluster_arn }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_policy" "load_balancer_controller" {
  name        = "${var.name}-load-balancer-controller"
  description = "Policy published for AWS Load Balancer Controller ${var.load_balancer_controller_version}"
  policy      = data.http.load_balancer_controller_policy.response_body
  lifecycle {
    precondition {
      condition     = sha256(data.http.load_balancer_controller_policy.response_body) == var.load_balancer_controller_policy_sha256
      error_message = "The load balancer controller IAM policy does not match the reviewed SHA-256 for the configured release."
    }
  }
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}

resource "aws_eks_pod_identity_association" "load_balancer_controller" {
  cluster_name    = var.cluster_name
  namespace       = var.controller_namespace
  service_account = var.controller_service_account_name
  role_arn        = aws_iam_role.load_balancer_controller.arn

  depends_on = [aws_iam_role_policy_attachment.load_balancer_controller]
}
