resource "aws_db_proxy" "database" {
  name                   = "${local.name_prefix}-postgres"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.proxy.arn
  require_tls            = true
  debug_logging          = var.proxy_debug_logging
  idle_client_timeout    = var.proxy_idle_client_timeout
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.proxy.id]

  auth {
    auth_scheme = "SECRETS"
    description = "Generated PostgreSQL credentials"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.proxy_auth.arn
  }

  depends_on = [
    aws_iam_role_policy.proxy_secret,
    aws_secretsmanager_secret_version.proxy_auth,
    aws_vpc_security_group_ingress_rule.allowed_clients,
    aws_vpc_security_group_ingress_rule.proxy_to_database,
    aws_vpc_security_group_egress_rule.proxy_to_database,
  ]

  tags = {
    Name = "${local.name_prefix}-postgres-proxy"
  }
}

resource "aws_db_proxy_default_target_group" "database" {
  db_proxy_name = aws_db_proxy.database.name

  connection_pool_config {
    connection_borrow_timeout    = var.proxy_connection_borrow_timeout
    max_connections_percent      = var.proxy_max_connections_percent
    max_idle_connections_percent = var.proxy_max_idle_connections_percent
  }
}

resource "aws_db_proxy_target" "database" {
  db_instance_identifier = aws_db_instance.database.identifier
  db_proxy_name          = aws_db_proxy.database.name
  target_group_name      = aws_db_proxy_default_target_group.database.name
}
