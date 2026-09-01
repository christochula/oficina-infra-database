resource "aws_cloudwatch_log_group" "database" {
  for_each = var.enabled_cloudwatch_logs_exports

  name              = "/aws/rds/instance/${local.db_identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name    = "${local.name_prefix}-rds-${each.value}"
    Purpose = "RDSLogExport"
  }
}
