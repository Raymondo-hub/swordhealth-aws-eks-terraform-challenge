output "plan_role_arn" {
  value = module.github_oidc.plan_role_arn
}

output "apply_role_arn" {
  value = module.github_oidc.apply_role_arn
}

output "oidc_provider_arn" {
  value = module.github_oidc.oidc_provider_arn
}

output "permissions_boundary_arn" {
  value = module.github_oidc.permissions_boundary_arn
}
