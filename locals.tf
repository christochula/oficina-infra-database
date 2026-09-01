locals {
  name_prefix          = "${var.project_name}-${var.environment}"
  db_identifier        = "${local.name_prefix}-postgres"
  engine_major_version = split(".", var.engine_version)[0]
  is_production        = contains(["prod", "production"], lower(var.environment))

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "oficina-infra-database"
  }

  proxy_auth_secret_name = "${var.project_name}/${var.environment}/database/proxy-auth"
  connection_secret_name = "${var.project_name}/${var.environment}/database/connection"

  prisma_proxy_url = format(
    "postgresql://%s:%s@%s:%d/%s?schema=%s&sslmode=require",
    urlencode(var.db_username),
    urlencode(random_password.database.result),
    aws_db_proxy.database.endpoint,
    var.db_port,
    urlencode(var.db_name),
    urlencode(var.prisma_schema),
  )
}
