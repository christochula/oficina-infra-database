resource "aws_db_parameter_group" "database" {
  name        = "${local.db_identifier}-secure"
  family      = "postgres${local.engine_major_version}"
  description = "TLS e logging para ${local.name_prefix}"

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
    name         = "log_min_duration_statement"
    value        = tostring(var.log_min_duration_statement_ms)
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${local.name_prefix}-postgres-secure" }
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
  # Sem CMK: usa a chave gerenciada aws/rds (nao exige permissao de KMS).

  multi_az = false
  # AWS Academy: a Lambda de autenticacao roda fora de VPC. Endpoint publico
  # com TLS forcado (rds.force_ssl=1) e senha aleatoria de 32 chars. O SG ainda
  # restringe a origem. Em ambiente real: RDS privado + Lambda em VPC.
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.database.name

  backup_retention_period = var.backup_retention_period
  copy_tags_to_snapshot   = true

  deletion_protection = false
  skip_final_snapshot = true

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true

  # Enhanced Monitoring desativado (monitoring_role precisa de iam:CreateRole).
  monitoring_interval = 0

  # Performance Insights com a chave default (sem CMK).
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = { Name = local.db_identifier }
}
