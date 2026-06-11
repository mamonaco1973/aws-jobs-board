# ==========================================================================================
# IAM Role + Policy + Instance Profile for EC2 (Secrets Manager Access)
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Grants EC2 instances permissions to read secrets from AWS Secrets Manager
#   - Enables EC2 integration with AWS Systems Manager (SSM)
#   - Provides a reusable IAM instance profile to attach to EC2/ASG launch templates
# ==========================================================================================


# ------------------------------------------------------------------------------------------
# Resource: IAM Role for EC2
# - Defines a trust policy allowing EC2 service to assume the role
# ------------------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_secrets_role" {
  name = "EC2SecretsAccessRole-${var.netbios}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com" # Trusted principal: EC2 service
      }
      Action = "sts:AssumeRole" # Allow role assumption
    }]
  })
}


# ------------------------------------------------------------------------------------------
# Resource: IAM Policy (Secrets Manager Read Access)
# - Grants EC2 permissions to read secrets required for AD integration
# ------------------------------------------------------------------------------------------
resource "aws_iam_policy" "secrets_policy" {
  name        = "SecretsManagerReadAccess"
  description = "Allows EC2 instance to read secrets from AWS Secrets Manager and manage IAM instance profiles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue", # Fetch secret values
          "secretsmanager:DescribeSecret"  # View secret metadata
        ]
        Resource = [
          data.aws_secretsmanager_secret.admin_secret.arn # Restrict to AD admin secret
        ]
      }
    ]
  })
}


# ------------------------------------------------------------------------------------------
# Resource: IAM Role Policy Attachment (AmazonSSMManagedInstanceCore)
# - Provides EC2 instances SSM agent permissions (patching, commands, inventory)
# ------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ------------------------------------------------------------------------------------------
# Resource: IAM Role Policy Attachment (Secrets Manager)
# - Attaches custom Secrets Manager read policy to the EC2 role
# ------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}


# ------------------------------------------------------------------------------------------
# Resource: IAM Instance Profile
# - Binds the EC2 role to an instance profile for use in launch templates/ASG
# ------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "EC2SecretsInstanceProfile-${var.netbios}"
  role = aws_iam_role.ec2_secrets_role.name
}
