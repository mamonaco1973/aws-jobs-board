# ===================================================================
# RANDOM PASSWORD: Active Directory (AD) Administrator
# -------------------------------------------------------------------
# Generates a secure 24-character password for the built-in
# Active Directory Administrator account. The password includes
# limited special characters (underscore and period) to remain
# compatible with Windows domain password policies.
# ===================================================================
resource "random_password" "admin_password" {
  length           = 24
  special          = true
  override_special = "_."
}

# ===================================================================
# SECRET: AD Administrator Credentials
# -------------------------------------------------------------------
# Creates an AWS Secrets Manager secret to securely store the
# Administrator’s username and password for the Active Directory.
# The secret is versioned automatically to maintain history
# across password rotations or re-deployments.
# ===================================================================
resource "aws_secretsmanager_secret" "admin_secret" {
  name        = "admin_ad_credentials"
  description = "AD Administrator Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "admin_secret_version" {
  secret_id = aws_secretsmanager_secret.admin_secret.id
  secret_string = jsonencode({
    username = "${var.netbios}\\Admin"              
    password = random_password.admin_password.result
  })
}

# ===================================================================
# RANDOM PASSWORD: John Smith
# -------------------------------------------------------------------
# Generates a 24-character password for John Smith’s domain
# account, including a limited set of special characters for
# strong authentication.
# ===================================================================
resource "random_password" "jsmith_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ===================================================================
# SECRET: John Smith AD Credentials
# -------------------------------------------------------------------
# Creates a versioned Secrets Manager entry for John Smith’s
# Active Directory credentials. The password is managed and
# updated automatically as Terraform resources change.
# ===================================================================
resource "aws_secretsmanager_secret" "jsmith_secret" {
  name        = "jsmith_ad_credentials"
  description = "John Smith's AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "jsmith_secret_version" {
  secret_id = aws_secretsmanager_secret.jsmith_secret.id
  secret_string = jsonencode({
    username = "jsmith@${var.dns_zone}"
    password = random_password.jsmith_password.result
  })
}

# ===================================================================
# RANDOM PASSWORD: Emily Davis
# -------------------------------------------------------------------
# Generates a secure 24-character password for Emily Davis’s
# Active Directory account, using a defined set of allowed
# special characters.
# ===================================================================
resource "random_password" "edavis_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ===================================================================
# SECRET: Emily Davis AD Credentials
# -------------------------------------------------------------------
# Stores Emily Davis’s Active Directory credentials in AWS Secrets
# Manager. The secret is versioned and supports password rotation
# without losing access history.
# ===================================================================
resource "aws_secretsmanager_secret" "edavis_secret" {
  name        = "edavis_ad_credentials"
  description = "Emily Davis's AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "edavis_secret_version" {
  secret_id = aws_secretsmanager_secret.edavis_secret.id
  secret_string = jsonencode({
    username = "edavis@${var.dns_zone}"
    password = random_password.edavis_password.result
  })
}

# ===================================================================
# RANDOM PASSWORD: Raj Patel
# -------------------------------------------------------------------
# Generates a secure 24-character password for Raj Patel’s
# Active Directory account. Uses a restricted character set
# to ensure compatibility across services.
# ===================================================================
resource "random_password" "rpatel_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ===================================================================
# SECRET: Raj Patel AD Credentials
# -------------------------------------------------------------------
# Creates a Secrets Manager entry to securely store Raj Patel’s
# Active Directory username and password with full version history.
# ===================================================================
resource "aws_secretsmanager_secret" "rpatel_secret" {
  name        = "rpatel_ad_credentials"
  description = "Raj Patel's AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "rpatel_secret_version" {
  secret_id = aws_secretsmanager_secret.rpatel_secret.id
  secret_string = jsonencode({
    username = "rpatel@${var.dns_zone}"
    password = random_password.rpatel_password.result
  })
}

# ===================================================================
# RANDOM PASSWORD: Amit Kumar
# -------------------------------------------------------------------
# Generates a 24-character password for Amit Kumar’s Active
# Directory account with limited special characters to maintain
# compliance with domain policy.
# ===================================================================
resource "random_password" "akumar_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ===================================================================
# SECRET: Amit Kumar AD Credentials
# -------------------------------------------------------------------
# Creates an AWS Secrets Manager entry for Amit Kumar’s AD
# credentials. Prevent_destroy is set to false to allow clean
# teardown in lab or demo environments.
# ===================================================================
resource "aws_secretsmanager_secret" "akumar_secret" {
  name        = "akumar_ad_credentials"
  description = "Amit Kumar's AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "akumar_secret_version" {
  secret_id = aws_secretsmanager_secret.akumar_secret.id
  secret_string = jsonencode({
    username = "akumar@${var.dns_zone}"
    password = random_password.akumar_password.result
  })
}

# ===================================================================
# RANDOM PASSWORD: RStudio Service Account
# -------------------------------------------------------------------
# Generates a 24-character alphanumeric password for the RStudio
# service account. This account is typically used for automation
# or local fallback login to RStudio Server.
# ===================================================================
resource "random_password" "rstudio_password" {
  length  = 24
  special = false
}

# ===================================================================
# SECRET: RStudio Service Account Credentials
# -------------------------------------------------------------------
# Stores the RStudio service account credentials in AWS Secrets
# Manager for secure, programmatic retrieval during Docker builds
# or automated deployment pipelines.
# ===================================================================
resource "aws_secretsmanager_secret" "rstudio_secret" {
  name        = "rstudio_credentials"
  description = "RStudio Service Account Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "rstudio_secret_version" {
  secret_id = aws_secretsmanager_secret.rstudio_secret.id
  secret_string = jsonencode({
    username = "rstudio"
    password = random_password.rstudio_password.result
  })
}
