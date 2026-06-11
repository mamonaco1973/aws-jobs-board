# ==============================================================================
# Input Variables
# ==============================================================================

variable "app_name" {
  description = "Application name used as a prefix for all resources"
  type        = string
  default     = "jobboard"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "jobboard_production"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "jobboard"
}
