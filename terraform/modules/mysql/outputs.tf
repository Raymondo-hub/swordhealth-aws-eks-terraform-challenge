output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "backup_vault_arn" {
  value = aws_backup_vault.this.arn
}

output "point_in_time_restore_test_endpoint" {
  value = var.enable_point_in_time_restore_test ? aws_db_instance.point_in_time_restore_test[0].address : null
}
