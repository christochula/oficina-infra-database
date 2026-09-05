resource "random_password" "database" {
  length      = var.password_length
  special     = true
  min_lower   = 6
  min_upper   = 6
  min_numeric = 6
  min_special = 6
  # Sem caracteres que quebram a URL Prisma / clientes pg.
  override_special = "!#%*+-.:=?_~"
}

# Secret unico entregue a aplicacao (oficina-api) e a Lambda de autenticacao
# (oficina-auth-serverless). Contem host/port/dbname/user/pass e a URL Prisma.
resource "aws_secretsmanager_secret" "connection" {
  name                    = local.connection_secret_name
  description             = "Dados de conexao PostgreSQL para as aplicacoes ${local.name_prefix}"
  recovery_window_in_days = 0

  tags = {
    Name    = "${local.name_prefix}-database-connection"
    Purpose = "ApplicationConnection"
  }
}

resource "aws_secretsmanager_secret_version" "connection" {
  secret_id = aws_secretsmanager_secret.connection.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.database.result
    engine   = "postgres"
    host     = aws_db_instance.database.address
    port     = var.db_port
    dbname   = var.db_name
    sslmode  = "require"
    # A Lambda de auth valida a cadeia TLS do RDS. Sem bundlar a CA do RDS,
    # a conexao usa TLS sem verificar o certificado (aceitavel no lab).
    ssl_reject_unauthorized = false
    url                     = local.prisma_url
  })
}
