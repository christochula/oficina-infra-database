variable "aws_region" {
  description = "AWS region in which the database stack is provisioned."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name."
  }
}

variable "project_name" {
  description = "Lowercase project slug used in names and tags."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain 2-20 lowercase letters, numbers or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment, for example homolog or prod."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.environment))
    error_message = "environment must start with a lowercase letter and contain 2-15 lowercase letters, numbers or hyphens."
  }
}

variable "vpc_id" {
  description = "ID of the existing VPC that contains the supplied private subnets."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID."
  }
}

variable "private_subnet_ids" {
  description = "At least two existing private subnet IDs in different Availability Zones."
  type        = list(string)

  validation {
    condition = (
      length(distinct(var.private_subnet_ids)) >= 2 &&
      alltrue([for subnet_id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))])
    )
    error_message = "private_subnet_ids must contain at least two distinct valid subnet IDs."
  }
}

variable "allowed_security_group_ids" {
  description = "Workload security groups allowed to initiate PostgreSQL connections to RDS Proxy. They never receive direct RDS ingress, and no CIDR ingress is created."
  type        = set(string)

  validation {
    condition = (
      length(var.allowed_security_group_ids) > 0 &&
      alltrue([for security_group_id in var.allowed_security_group_ids : can(regex("^sg-[0-9a-f]+$", security_group_id))])
    )
    error_message = "allowed_security_group_ids must contain at least one valid security group ID."
  }
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a letter and contain at most 63 letters, numbers or underscores."
  }
}

variable "db_username" {
  description = "Generated-password master username stored in Secrets Manager."
  type        = string
  default     = "oficina_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_username))
    error_message = "db_username must start with a letter and contain at most 63 letters, numbers or underscores."
  }
}

variable "db_port" {
  description = "PostgreSQL listener port."
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port >= 1150 && var.db_port <= 65535
    error_message = "db_port must be between 1150 and 65535."
  }
}

variable "engine_version" {
  description = "RDS PostgreSQL engine version. A major version lets AWS select a supported minor release."
  type        = string
  default     = "16"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?$", var.engine_version))
    error_message = "engine_version must be a PostgreSQL major or major.minor version."
  }
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"

  validation {
    condition     = startswith(var.instance_class, "db.")
    error_message = "instance_class must start with db."
  }
}

variable "allocated_storage" {
  description = "Initial database storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage in GiB for RDS storage autoscaling; must be at least 10 percent greater than allocated_storage."
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage >= 20
    error_message = "max_allocated_storage must be at least 20 GiB."
  }
}

variable "multi_az" {
  description = "Whether to deploy a synchronous standby in another Availability Zone. Required for prod/production."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Automated backup/PITR retention in days. Must be at least 7 in prod/production."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35 days so PITR remains enabled."
  }
}

variable "backup_window" {
  description = "Daily UTC backup window."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly UTC maintenance window."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "RDS deletion protection. Required for prod/production."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether database deletion may skip its final snapshot. Must be false in prod/production."
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Whether automated backups are deleted with the instance. Keep false in production."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply disruptive RDS changes immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor engine upgrades during the maintenance window."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention. AWS supports 7 days or the long-term 731-day tier."
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "performance_insights_retention_period must be 7 or 731."
  }
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring collection interval in seconds."
  type        = number
  default     = 60

  validation {
    condition     = contains([1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 1, 5, 10, 15, 30 or 60 seconds."
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "PostgreSQL logs exported by RDS to CloudWatch Logs."
  type        = set(string)
  default     = ["postgresql", "upgrade"]

  validation {
    condition     = length(setsubtract(var.enabled_cloudwatch_logs_exports, toset(["postgresql", "upgrade"]))) == 0
    error_message = "enabled_cloudwatch_logs_exports can contain only postgresql and upgrade."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch database log retention in days."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731,
      1096, 1827, 2192, 2557, 2922, 3288, 3653,
    ], var.cloudwatch_log_retention_days)
    error_message = "cloudwatch_log_retention_days must be a CloudWatch Logs supported retention value."
  }
}

variable "log_min_duration_statement_ms" {
  description = "Log SQL statements whose execution exceeds this duration in milliseconds."
  type        = number
  default     = 1000

  validation {
    condition     = var.log_min_duration_statement_ms >= 0
    error_message = "log_min_duration_statement_ms must be zero or greater."
  }
}

variable "idle_in_transaction_session_timeout_ms" {
  description = "Terminate idle transactions after this duration in milliseconds."
  type        = number
  default     = 60000

  validation {
    condition     = var.idle_in_transaction_session_timeout_ms >= 1000
    error_message = "idle_in_transaction_session_timeout_ms must be at least 1000."
  }
}

variable "ca_cert_identifier" {
  description = "Optional RDS CA certificate identifier. Null uses the current AWS default CA."
  type        = string
  default     = null
  nullable    = true
}

variable "password_length" {
  description = "Length of the generated database password."
  type        = number
  default     = 40

  validation {
    condition     = var.password_length >= 32 && var.password_length <= 128
    error_message = "password_length must be between 32 and 128."
  }
}

variable "secret_recovery_window_in_days" {
  description = "Secrets Manager recovery window. Use zero for immediate deletion or 7-30 days."
  type        = number
  default     = 7

  validation {
    condition = (
      var.secret_recovery_window_in_days == 0 ||
      (var.secret_recovery_window_in_days >= 7 && var.secret_recovery_window_in_days <= 30)
    )
    error_message = "secret_recovery_window_in_days must be 0 or between 7 and 30."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Pending deletion window for the customer-managed database KMS key."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "prisma_schema" {
  description = "Prisma schema query parameter included in the TLS connection URLs."
  type        = string
  default     = "public"

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.prisma_schema))
    error_message = "prisma_schema must be a valid PostgreSQL identifier."
  }
}

variable "proxy_idle_client_timeout" {
  description = "RDS Proxy idle client timeout in seconds."
  type        = number
  default     = 1800

  validation {
    condition     = var.proxy_idle_client_timeout >= 1 && var.proxy_idle_client_timeout <= 28800
    error_message = "proxy_idle_client_timeout must be between 1 and 28800 seconds."
  }
}

variable "proxy_connection_borrow_timeout" {
  description = "Seconds a client waits for a database connection from the proxy pool."
  type        = number
  default     = 120

  validation {
    condition     = var.proxy_connection_borrow_timeout >= 0 && var.proxy_connection_borrow_timeout <= 300
    error_message = "proxy_connection_borrow_timeout must be between 0 and 300 seconds."
  }
}

variable "proxy_max_connections_percent" {
  description = "Maximum percentage of database connections available to the proxy pool."
  type        = number
  default     = 90

  validation {
    condition     = var.proxy_max_connections_percent >= 1 && var.proxy_max_connections_percent <= 100
    error_message = "proxy_max_connections_percent must be between 1 and 100."
  }
}

variable "proxy_max_idle_connections_percent" {
  description = "Maximum percentage of idle database connections retained by the proxy pool."
  type        = number
  default     = 50

  validation {
    condition     = var.proxy_max_idle_connections_percent >= 0 && var.proxy_max_idle_connections_percent <= 100
    error_message = "proxy_max_idle_connections_percent must be between 0 and 100."
  }
}

variable "proxy_debug_logging" {
  description = "Enable verbose RDS Proxy logs temporarily for troubleshooting."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged with the mandatory project tags."
  type        = map(string)
  default     = {}
}
