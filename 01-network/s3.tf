# ==============================================================================
# S3 Bucket — ActiveStorage File Uploads
# ==============================================================================
# Stores resume uploads from job applicants. All objects are private;
# the ECS task role grants the Rails app presigned-URL access via IAM.
# ==============================================================================

resource "aws_s3_bucket" "uploads" {
  bucket_prefix = "jobboard-uploads-"

  tags = { Name = "jobboard-uploads" }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}
