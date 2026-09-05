locals {
  name_prefix          = "${var.project_name}-${var.environment}"
  db_identifier        = "${local.name_prefix}-postgres"
  engine_major_version = split(".", var.engine_version)[0]

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "oficina-infra-database"
  }

  connection_secret_name = "${var.project_name}/${var.environment}/database/connection"

  # AWS Academy: sem RDS Proxy (precisa de IAM role). A aplicacao e a Lambda
  # conectam direto ao endpoint do RDS. rds.force_ssl exige TLS; sslmode=require
  # criptografa sem exigir a CA (suficiente para o lab).
  prisma_url = format(
    "postgresql://%s:%s@%s:%d/%s?schema=%s&sslmode=require",
    urlencode(var.db_username),
    urlencode(random_password.database.result),
    aws_db_instance.database.address,
    var.db_port,
    urlencode(var.db_name),
    urlencode(var.prisma_schema),
  )
}
