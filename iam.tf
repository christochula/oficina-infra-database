data "aws_partition" "current" {}

resource "aws_iam_role" "enhanced_monitoring" {
  name = substr("${local.name_prefix}-rds-monitoring", 0, 64)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-rds-monitoring"
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "proxy" {
  name = substr("${local.name_prefix}-rds-proxy", 0, 64)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-rds-proxy"
  }
}

resource "aws_iam_role_policy" "proxy_secret" {
  name = "read-proxy-auth-secret"
  role = aws_iam_role.proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadProxyCredentials"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = aws_secretsmanager_secret.proxy_auth.arn
      },
      {
        Sid    = "DecryptProxyCredentials"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        Resource = aws_kms_key.database.arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })
}
