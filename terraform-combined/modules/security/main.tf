# DDVE Security Group
resource "aws_security_group" "ddve" {
  name_prefix = "${var.environment}-ddve-"
  description = "Security group for Data Domain Virtual Edition"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC for testing
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-ddve-sg"
  }
}

# Avamar Security Group
resource "aws_security_group" "avamar" {
  name_prefix = "${var.environment}-avamar-"
  description = "Security group for Avamar"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC for testing
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-avamar-sg"
  }
}

# PowerProtect Data Manager Security Group
resource "aws_security_group" "ppdm" {
  name_prefix = "${var.environment}-ppdm-"
  description = "Security group for PowerProtect Data Manager"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC for testing
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-ppdm-sg"
  }
}

# Linux Client Security Group
resource "aws_security_group" "linux_client" {
  name_prefix = "${var.environment}-linux-client-"
  description = "Security group for Linux test client"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC for testing
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-linux-client-sg"
  }
}

# Windows Client Security Group - Jump Box
resource "aws_security_group" "windows_client" {
  name_prefix = "${var.environment}-windows-client-"
  description = "Security group for Windows jump box"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC for internal communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  # RDP from Admin IP only
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "RDP Access from Admin"
  }

  # WinRM HTTP from Admin IP (for automation)
  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "WinRM HTTP from Admin"
  }

  # WinRM HTTPS from Admin IP (for automation)
  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "WinRM HTTPS from Admin"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-windows-client-sg"
  }
}