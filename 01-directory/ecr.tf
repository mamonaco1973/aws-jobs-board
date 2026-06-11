# ==========================================================================================
# AWS Elastic Container Registry (ECR)
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Creates a dedicated Amazon ECR repository for RStudio container images
#   - Enables vulnerability scanning and mutable image tag management
#   - Intended for use with RStudio deployments on EKS or other container platforms
# ==========================================================================================

resource "aws_ecr_repository" "rstudio" {

  # Identification -----------------------------------------------------------
  name = "rstudio" # Repository name within the AWS account

  # Image tag behavior ------------------------------------------------------
  image_tag_mutability = "MUTABLE" # Allow overwriting of existing image tags
  # (e.g., for iterative builds during testing)

  # Image scanning ----------------------------------------------------------
  image_scanning_configuration {
    scan_on_push = true # Automatically scan images when pushed
  }

  # Tags -------------------------------------------------------------------
  tags = {
    Name = "RStudio ECR Repository"
  }
}
