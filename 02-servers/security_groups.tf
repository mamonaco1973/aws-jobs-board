# ==========================================================================================
# Security Groups: RDP (Windows) + SSH/SMB (Linux)
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Defines network access for Windows (RDP 3389) and Linux (SSH 22, SMB 445) instances
#   - Provides ICMP (ping) access for diagnostics
#   - Allows all outbound traffic by default
#
# ⚠️ WARNING:
#   - Current configuration allows unrestricted inbound access (0.0.0.0/0)
#   - Highly insecure; use only for lab/demo environments
#   - In production, restrict to trusted IP CIDR ranges or VPN access
# ==========================================================================================


# ------------------------------------------------------------------------------------------
# Resource: Security Group for RDP (Windows)
# - Allows inbound RDP (3389) + ICMP
# - Open to all IPs (for testing/demo purposes only)
# ------------------------------------------------------------------------------------------
resource "aws_security_group" "ad_rdp_sg" {
  name        = "ad-rdp-security-group"              # Security group name
  description = "Allow RDP access from the internet" # Purpose
  vpc_id      = data.aws_vpc.ecs_vpc.id              # Target VPC

  # Ingress: RDP access (port 3389)
  ingress {
    description = "Allow RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Open to all IPs
  }

  # Ingress: ICMP (ping)
  ingress {
    description = "Allow ICMP (ping) from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Open to all IPs
  }

  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ------------------------------------------------------------------------------------------
# Resource: Security Group for SSH/SMB (Linux)
# - Allows inbound SSH (22), SMB (445), + ICMP
# - Open to all IPs (for testing/demo purposes only)
# ------------------------------------------------------------------------------------------
resource "aws_security_group" "ad_ssh_sg" {
  name        = "ad-ssh-security-group"              # Security group name
  description = "Allow SSH access from the internet" # Purpose
  vpc_id      = data.aws_vpc.ecs_vpc.id              # Target VPC

  # Ingress: SSH access (port 22)
  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Open to all IPs
  }

  # Ingress: SMB access (port 445)
  ingress {
    description = "Allow SMB from anywhere"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Open to all IPs
  }

  # Ingress: ICMP (ping)
  ingress {
    description = "Allow ICMP (ping) from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Open to all IPs
  }

  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
