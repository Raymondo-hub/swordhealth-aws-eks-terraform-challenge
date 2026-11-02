resource "aws_security_group" "this" {
  name_prefix = "${var.name}-mysql-"
  description = "MySQL ingress from the EKS worker nodes only"
  vpc_id      = var.vpc_id
  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.node_security_group_ids
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier                      = "${var.name}-mysql"
  engine                          = "mysql"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage
  max_allocated_storage           = max(var.allocated_storage, var.max_allocated_storage)
  storage_type                    = "gp3"
  storage_encrypted               = true
  db_name                         = var.database_name
  username                        = var.master_username
  manage_master_user_password     = true
  db_subnet_group_name            = var.database_subnet_group_name
  vpc_security_group_ids          = [aws_security_group.this.id]
  publicly_accessible             = false
  multi_az                        = var.multi_az
  backup_retention_period         = var.backup_retention_days
  backup_window                   = var.backup_window
  maintenance_window              = var.maintenance_window
  auto_minor_version_upgrade      = true
  deletion_protection             = var.deletion_protection
  copy_tags_to_snapshot           = true
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${var.name}-mysql-final"
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  tags                            = var.tags
}

resource "aws_backup_vault" "this" {
  name = "${var.name}-mysql"
  tags = var.tags
}

resource "aws_iam_role" "backup" {
  name = "${var.name}-backup"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_plan" "this" {
  name = "${var.name}-mysql-daily"
  rule {
    rule_name                = "daily-mysql"
    target_vault_name        = aws_backup_vault.this.name
    schedule                 = var.backup_schedule
    enable_continuous_backup = true
    lifecycle {
      delete_after = var.backup_vault_retention_days
    }
  }
  tags = var.tags
}

resource "aws_backup_selection" "this" {
  name         = "${var.name}-mysql"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = aws_iam_role.backup.arn
  resources    = [aws_db_instance.this.arn]
}

resource "aws_backup_restore_testing_plan" "this" {
  name                = "${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql_weekly"
  schedule_expression = var.restore_test_schedule
  recovery_point_selection {
    algorithm             = "LATEST_WITHIN_WINDOW"
    include_vaults        = [aws_backup_vault.this.arn]
    recovery_point_types  = ["CONTINUOUS", "SNAPSHOT"]
    selection_window_days = var.restore_test_window_days
  }
  tags = var.tags
}

resource "aws_backup_restore_testing_selection" "this" {
  name                      = "${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}_mysql"
  restore_testing_plan_name = aws_backup_restore_testing_plan.this.name
  protected_resource_type   = "RDS"
  protected_resource_arns   = [aws_db_instance.this.arn]
  iam_role_arn              = aws_iam_role.backup.arn
  validation_window_hours   = var.restore_test_validation_window_hours
  restore_metadata_overrides = {
    dbInstanceClass     = var.instance_class
    dbSubnetGroupName   = var.database_subnet_group_name
    publiclyAccessible  = "false"
    vpcSecurityGroupIds = jsonencode([aws_security_group.this.id])
  }
  depends_on = [
    aws_iam_role_policy_attachment.backup,
    aws_iam_role_policy_attachment.restore
  ]
}

resource "aws_db_instance" "point_in_time_restore_test" {
  count          = var.enable_point_in_time_restore_test ? 1 : 0
  identifier     = "${var.name}-mysql-restore-test"
  instance_class = var.instance_class
  restore_to_point_in_time {
    source_db_instance_identifier = aws_db_instance.this.identifier
    use_latest_restorable_time    = true
  }
  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  deletion_protection    = false
  skip_final_snapshot    = true
  copy_tags_to_snapshot  = true
  tags                   = merge(var.tags, { Purpose = "temporary-point-in-time-restore-test" })
}
