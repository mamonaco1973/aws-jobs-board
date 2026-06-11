# ==============================================================================
# Input Variables
# ==============================================================================

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# S3 bucket name passed in from apply.sh (captured from 01-network output)
variable "s3_bucket_name" {
  description = "S3 bucket for ActiveStorage uploads"
  type        = string
}
