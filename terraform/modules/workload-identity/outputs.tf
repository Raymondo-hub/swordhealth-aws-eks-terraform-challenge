output "application_role_arn" {
  value = aws_iam_role.application.arn
}

output "load_balancer_controller_role_arn" {
  value = aws_iam_role.load_balancer_controller.arn
}
