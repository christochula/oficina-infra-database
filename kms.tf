resource "aws_kms_key" "database" {
  description             = "RDS, Performance Insights and Secrets Manager key for ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  tags = {
    Name = "${local.name_prefix}-database"
  }
}

resource "aws_kms_alias" "database" {
  name          = "alias/${local.name_prefix}-database"
  target_key_id = aws_kms_key.database.key_id
}
