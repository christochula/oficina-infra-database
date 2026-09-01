output "db_instance_identifier" {
  description = "RDS PostgreSQL instance identifier."
  value       = aws_db_instance.database.identifier
}

output "db_endpoint" {
  description = "Direct RDS endpoint in host:port form. The database security group accepts only RDS Proxy by default."
  value       = aws_db_instance.database.endpoint
}

output "db_address" {
  description = "Direct RDS hostname. Workload security groups are not allowed to connect to it."
  value       = aws_db_instance.database.address
}

output "db_port" {
  description = "PostgreSQL listener port."
  value       = aws_db_instance.database.port
}

output "proxy_endpoint" {
  description = "TLS-only RDS Proxy hostname for Lambda and application traffic."
  value       = aws_db_proxy.database.endpoint
}

output "secret_arn" {
  description = "Application connection secret ARN. Its JSON contains username, password, host, port, dbname and TLS Prisma url."
  value       = aws_secretsmanager_secret.connection.arn
}

output "secret_name" {
  description = "Application connection secret name."
  value       = aws_secretsmanager_secret.connection.name
}

output "proxy_auth_secret_arn" {
  description = "Internal Secrets Manager ARN consumed by RDS Proxy. Applications should use secret_arn instead."
  value       = aws_secretsmanager_secret.proxy_auth.arn
}

output "proxy_auth_secret_name" {
  description = "Internal RDS Proxy authentication secret name."
  value       = aws_secretsmanager_secret.proxy_auth.name
}

output "security_group_id" {
  description = "Backward-compatible alias for proxy_security_group_id. Client workloads connect to this security group through allowed_security_group_ids."
  value       = aws_security_group.proxy.id
}

output "proxy_security_group_id" {
  description = "Security group attached to RDS Proxy and reachable from allowed client workload security groups."
  value       = aws_security_group.proxy.id
}

output "database_security_group_id" {
  description = "Security group attached only to RDS; ingress is restricted to proxy_security_group_id."
  value       = aws_security_group.database.id
}

output "db_subnet_group_name" {
  description = "RDS private DB subnet group name."
  value       = aws_db_subnet_group.database.name
}

output "kms_key_arn" {
  description = "Customer-managed KMS key ARN used by RDS, Performance Insights and Secrets Manager."
  value       = aws_kms_key.database.arn
}
