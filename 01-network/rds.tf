# ==============================================================================
# RDS PostgreSQL — Primary Datastore
# ==============================================================================
# Single-AZ t3.micro for demo cost; multi-AZ would be set here for production.
# Placed in private subnets; no public endpoint exposed.
# ==============================================================================

resource "aws_db_subnet_group" "jobboard" {
  name       = "jobboard-db-subnet-group"
  subnet_ids = [aws_subnet.priv-subnet-1.id, aws_subnet.priv-subnet-2.id]

  tags = { Name = "jobboard-db-subnet-group" }
}

# Allow PostgreSQL from within the VPC only — ECS tasks are in private subnets
resource "aws_security_group" "rds" {
  name        = "jobboard-rds-sg"
  description = "Allow PostgreSQL from VPC"
  vpc_id      = aws_vpc.ecs-vpc.id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ecs-vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jobboard-rds-sg" }
}

resource "aws_db_instance" "jobboard" {
  identifier        = "jobboard-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.jobboard.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Skip final snapshot — demo environment; change for production
  skip_final_snapshot = true
  publicly_accessible = false

  tags = { Name = "jobboard-db" }
}
