# AWS Academy: usa a VPC default (mesma do cluster EKS). O RDS aceita conexao
# de qualquer workload dentro do CIDR da VPC (pods do EKS e Lambda).

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "database" {
  name        = "${local.name_prefix}-db"
  description = "Subnets da VPC default para o RDS ${local.name_prefix}"
  subnet_ids  = data.aws_subnets.default.ids

  tags = { Name = "${local.name_prefix}-db" }
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database"
  description = "Acesso PostgreSQL para ${local.name_prefix} a partir da VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "PostgreSQL de workloads na VPC (EKS, Lambda)"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-database" }
}
