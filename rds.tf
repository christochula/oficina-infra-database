resource "random_id" "final_snapshot" {
  count = var.skip_final_snapshot ? 0 : 1

  byte_length = 4
  keepers = {
    database_identifier = local.db_identifier
  }
}

resource "aws_db_parameter_group" "database" {
  name        = "${local.db_identifier}-secure"
  family      = "postgres${local.engine_major_version}"
  description = "TLS and audit-oriented PostgreSQL settings for ${local.name_prefix}"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "password_encryption"
    value        = "scram-sha-256"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_lock_waits"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_statement"
    value        = "ddl"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = tostring(var.log_min_duration_statement_ms)
    apply_method = "immediate"
  }

  parameter {
    name         = "idle_in_transaction_session_timeout"
    value        = tostring(var.idle_in_transaction_session_timeout_ms)
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name_prefix}-postgres-secure"
  }
}

resource "aws_db_instance" "database" {
  identifier = local.db_identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.database.result
  port     = var.db_port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.database.arn

  multi_az               = var.multi_az
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.database.name
  ca_cert_identifier     = var.ca_cert_identifier

  backup_retention_period  = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  copy_tags_to_snapshot    = true
  delete_automated_backups = var.delete_automated_backups

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.db_identifier}-final-${random_id.final_snapshot[0].hex}"

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = false
  apply_immediately           = var.apply_immediately

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.database.arn
  performance_insights_retention_period = var.performance_insights_retention_period

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  lifecycle {
    precondition {
      condition     = var.max_allocated_storage >= ceil(var.allocated_storage * 1.1)
      error_message = "max_allocated_storage must be at least 10 percent greater than allocated_storage for RDS storage autoscaling."
    }

    precondition {
      condition     = !local.is_production || var.multi_az
      error_message = "prod/production requires multi_az = true."
    }

    precondition {
      condition     = !local.is_production || var.deletion_protection
      error_message = "prod/production requires deletion_protection = true."
    }

    precondition {
      condition     = !local.is_production || !var.skip_final_snapshot
      error_message = "prod/production requires skip_final_snapshot = false."
    }

    precondition {
      condition     = !local.is_production || var.backup_retention_period >= 7
      error_message = "prod/production requires at least seven days of PITR retention."
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.database,
    aws_iam_role_policy_attachment.enhanced_monitoring,
  ]

  tags = {
    Name = local.db_identifier
  }
}
