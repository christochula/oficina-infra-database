resource "aws_db_subnet_group" "database" {
  name        = "${local.name_prefix}-database"
  description = "Private subnets for ${local.name_prefix} RDS and RDS Proxy"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-database"
  }
}

resource "aws_security_group" "proxy" {
  name                   = "${local.name_prefix}-database-proxy"
  description            = "Approved workload access to ${local.name_prefix} RDS Proxy"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.name_prefix}-database-proxy"
  }
}

resource "aws_security_group" "database" {
  name                   = "${local.name_prefix}-database"
  description            = "PostgreSQL access for ${local.name_prefix}; security-group references only"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.name_prefix}-database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allowed_clients" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.proxy.id
  referenced_security_group_id = each.value
  description                  = "PostgreSQL from approved workload security group ${each.value}"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"

  lifecycle {
    create_before_destroy = true
  }
}

# The database accepts PostgreSQL only from the dedicated proxy security group.
resource "aws_vpc_security_group_ingress_rule" "proxy_to_database" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.proxy.id
  description                  = "RDS Proxy to RDS PostgreSQL"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"

  lifecycle {
    create_before_destroy = true
  }
}

# New security groups have their default allow-all egress removed by the AWS
# provider. This rule permits only the proxy-to-database data path.
resource "aws_vpc_security_group_egress_rule" "proxy_to_database" {
  security_group_id            = aws_security_group.proxy.id
  referenced_security_group_id = aws_security_group.database.id
  description                  = "RDS Proxy to RDS PostgreSQL"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"

  lifecycle {
    create_before_destroy = true
  }
}
