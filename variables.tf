variable "aws_region" {
  description = "Regiao AWS."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Slug do projeto usado em nomes e tags."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.project_name))
    error_message = "project_name deve comecar com letra minuscula e ter 2-20 caracteres."
  }
}

variable "environment" {
  description = "Ambiente (homolog, production...)."
  type        = string
  default     = "homolog"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.environment))
    error_message = "environment deve comecar com letra minuscula e ter 2-15 caracteres."
  }
}

variable "db_name" {
  description = "Nome do banco PostgreSQL inicial."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_name))
    error_message = "db_name invalido."
  }
}

variable "db_username" {
  description = "Usuario master (senha gerada, guardada no Secrets Manager)."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_username))
    error_message = "db_username invalido."
  }
}

variable "db_port" {
  description = "Porta do PostgreSQL."
  type        = number
  default     = 5432
}

variable "engine_version" {
  description = "Versao do PostgreSQL (major ou major.minor)."
  type        = string
  default     = "16"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?$", var.engine_version))
    error_message = "engine_version deve ser major ou major.minor."
  }
}

variable "instance_class" {
  description = "Classe da instancia RDS."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = startswith(var.instance_class, "db.")
    error_message = "instance_class deve comecar com db."
  }
}

variable "allocated_storage" {
  description = "Storage inicial em GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Limite do autoscaling de storage em GiB."
  type        = number
  default     = 50
}

variable "backup_retention_period" {
  description = "Retencao de backup automatico (dias)."
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period deve estar entre 0 e 35."
  }
}

variable "log_min_duration_statement_ms" {
  description = "Loga SQL que passar dessa duracao (ms)."
  type        = number
  default     = 1000
}

variable "password_length" {
  description = "Tamanho da senha gerada."
  type        = number
  default     = 32

  validation {
    condition     = var.password_length >= 24 && var.password_length <= 128
    error_message = "password_length deve estar entre 24 e 128."
  }
}

variable "prisma_schema" {
  description = "Parametro schema incluido na URL Prisma."
  type        = string
  default     = "public"
}

variable "tags" {
  description = "Tags adicionais."
  type        = map(string)
  default     = {}
}
