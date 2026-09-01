resource "random_password" "database" {
  length           = var.password_length
  special          = true
  min_lower        = 6
  min_upper        = 6
  min_numeric      = 6
  min_special      = 6
  override_special = "!#$%&*+-.:;<=>?[]^_{|}~"
}

# This internal secret is deliberately independent of the proxy endpoint. RDS
# Proxy needs it during creation, which avoids a proxy <-> secret cycle.
resource "aws_secretsmanager_secret" "proxy_auth" {
  name                    = local.proxy_auth_secret_name
  description             = "Internal credential source for ${local.name_prefix} RDS Proxy"
  kms_key_id              = aws_kms_key.database.arn
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = {
    Name    = "${local.name_prefix}-database-proxy-auth"
    Purpose = "RDSProxyAuthentication"
  }
}

resource "aws_secretsmanager_secret_version" "proxy_auth" {
  secret_id = aws_secretsmanager_secret.proxy_auth.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.database.result
  })
}

resource "aws_secretsmanager_secret" "connection" {
  name                    = local.connection_secret_name
  description             = "TLS PostgreSQL connection data for ${local.name_prefix} applications"
  kms_key_id              = aws_kms_key.database.arn
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = {
    Name    = "${local.name_prefix}-database-connection"
    Purpose = "ApplicationConnection"
  }
}

# The application secret is created after the proxy. Its required host and url
# fields therefore point to the TLS-only proxy. Direct RDS connection material is
# deliberately excluded from the application secret.
resource "aws_secretsmanager_secret_version" "connection" {
  secret_id = aws_secretsmanager_secret.connection.id
  secret_string = jsonencode({
    username    = var.db_username
    password    = random_password.database.result
    engine      = "postgres"
    host        = aws_db_proxy.database.endpoint
    port        = var.db_port
    dbname      = var.db_name
    url         = local.prisma_proxy_url
  })

  depends_on = [aws_db_proxy_target.database]
}
