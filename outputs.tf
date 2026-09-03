output "db_instance_identifier" {
  description = "Identificador da instancia RDS."
  value       = aws_db_instance.database.identifier
}

output "db_endpoint" {
  description = "Endpoint do RDS (host:port)."
  value       = aws_db_instance.database.endpoint
}

output "db_address" {
  description = "Hostname do RDS."
  value       = aws_db_instance.database.address
}

output "db_port" {
  description = "Porta do PostgreSQL."
  value       = aws_db_instance.database.port
}

output "secret_arn" {
  description = "ARN do secret de conexao. JSON: username, password, host, port, dbname, sslmode, url."
  value       = aws_secretsmanager_secret.connection.arn
}

output "secret_name" {
  description = "Nome do secret de conexao (consumido por oficina-api e oficina-auth-serverless)."
  value       = aws_secretsmanager_secret.connection.name
}

output "database_security_group_id" {
  description = "SG do RDS."
  value       = aws_security_group.database.id
}

output "db_subnet_group_name" {
  description = "Nome do DB subnet group."
  value       = aws_db_subnet_group.database.name
}
