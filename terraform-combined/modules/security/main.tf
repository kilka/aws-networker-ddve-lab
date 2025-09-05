# DDVE Security Group
resource "aws_security_group" "ddve" {
  name_prefix = "${var.environment}-ddve-"
  description = "Security group for Data Domain Virtual Edition"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC (temp lab)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  # HTTPS/Admin Console from Windows jump box
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description     = "HTTPS Admin Console from jump box"
  }

  # DDFS/REST API from Windows jump box
  ingress {
    from_port       = 3009
    to_port         = 3009
    protocol        = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description     = "DDFS/REST API from jump box"
  }

  # SSH from Windows jump box
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description     = "SSH from jump box"
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

  # Allow all traffic from VPC (temp lab)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  # HTTPS Admin from Admin IP
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "HTTPS Admin Console"
  }

  # Avamar Administrator Console from Admin IP
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "Avamar Administrator"
  }

  # Avamar Console Port from Admin IP
  ingress {
    from_port   = 8543
    to_port     = 8543
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "Avamar Web Services"
  }

  # Additional management ports from Admin IP
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "Management Port"
  }

  ingress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "Management SSL Port"
  }

  # SSH from Admin IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "SSH Management"
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

  # Allow all traffic from VPC (temp lab)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  # HTTPS from Admin IP
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "HTTPS"
  }

  # PowerProtect UI from Admin IP
  ingress {
    from_port   = 14443
    to_port     = 14443
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "PowerProtect UI"
  }

  # SSH from Admin IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "SSH Management"
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

  # Allow all traffic from VPC (temp lab)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  # SSH from Windows jump box
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.windows_client.id]
    description = "SSH Access from jump box"
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

# Windows Client Security Group
resource "aws_security_group" "windows_client" {
  name_prefix = "${var.environment}-windows-client-"
  description = "Security group for Windows test client"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC (temp lab)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all from VPC"
  }

  # RDP from Admin IP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "RDP Access from Admin"
  }

  # WinRM HTTP from Admin IP
  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
    description = "WinRM HTTP from Admin"
  }

  # WinRM HTTPS from Admin IP
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