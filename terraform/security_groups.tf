# Security Group for NetWorker Server
resource "aws_security_group" "networker_server" {
  name        = "${var.project_name}-networker-server-sg"
  description = "Security group for NetWorker Server"
  vpc_id      = aws_vpc.main.id

  # SSH access from admin IP
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NetWorker Console (GST)
  ingress {
    description = "NetWorker Console"
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NetWorker Web Console
  ingress {
    description = "NetWorker Web Console"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NetWorker Server Port
  ingress {
    description = "NetWorker Server"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # HTTPS for NetWorker Web UI
  ingress {
    description = "HTTPS for NetWorker Web UI"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NetWorker Services
  ingress {
    description = "NetWorker RPC TCP"
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "NetWorker RPC UDP"
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # PostgreSQL for NetWorker Management Console
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # RabbitMQ for NetWorker messaging
  ingress {
    description = "RabbitMQ AMQP"
    from_port   = 5671
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NetWorker nsrexecd (client execution service)
  ingress {
    description = "NetWorker nsrexecd"
    from_port   = 7937
    to_port     = 7937
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NetWorker Portmapper
  ingress {
    description = "NetWorker Portmapper"
    from_port   = 7938
    to_port     = 7938
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NetWorker dynamic port range (bidirectional communication)
  ingress {
    description = "NetWorker dynamic port range"
    from_port   = 7937
    to_port     = 9936
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NetWorker Storage Node
  ingress {
    description = "Storage Node Services"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-networker-server-sg"
  }
}

# Security Group for DDVE
resource "aws_security_group" "ddve" {
  name        = "${var.project_name}-ddve-sg"
  description = "Security group for Data Domain Virtual Edition"
  vpc_id      = aws_vpc.main.id

  # SSH access from admin IP
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # DDVE System Manager
  ingress {
    description = "DDVE System Manager HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # DDVE REST API
  ingress {
    description = "DDVE REST API"
    from_port   = 3009
    to_port     = 3009
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # DDVE REST API from NetWorker Server
  ingress {
    description     = "DDVE REST API from NetWorker"
    from_port       = 3009
    to_port         = 3009
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # DD Boost (using security group reference)
  ingress {
    description     = "DD Boost from NetWorker"
    from_port       = 2052
    to_port         = 2052
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # DD Boost from admin IP (for API calls through NetWorker)
  ingress {
    description = "DD Boost from admin IP"
    from_port   = 2052
    to_port     = 2052
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NFS - Network File System access for DD Boost operations
  ingress {
    description = "NFS for DD Boost operations"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Replication - Data Domain replication between DDVE instances
  ingress {
    description = "DD Replication between instances"
    from_port   = 2051
    to_port     = 2051
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RPC Portmapper for NFS
  ingress {
    description = "RPC Portmapper TCP"
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "RPC Portmapper UDP"
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DD Boost from VPC
  ingress {
    description = "DD Boost Communication from VPC"
    from_port   = 2052
    to_port     = 2052
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DD Boost over FC (optional)
  ingress {
    description = "DD Boost over FC"
    from_port   = 3009
    to_port     = 3009
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DDVE Telemetry/Support
  ingress {
    description = "DDVE Telemetry"
    from_port   = 9011
    to_port     = 9011
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ddve-sg"
  }
}

# Security Group for Linux Client
resource "aws_security_group" "linux_client" {
  name        = "${var.project_name}-linux-client-sg"
  description = "Security group for Linux backup client"
  vpc_id      = aws_vpc.main.id

  # SSH access from NetWorker Server
  ingress {
    description     = "SSH from NetWorker Server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # SSH access from admin IP
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NetWorker client services
  ingress {
    description     = "NetWorker client services"
    from_port       = 7937
    to_port         = 7938
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # NetWorker dynamic port range from server
  ingress {
    description     = "NetWorker dynamic ports from server"
    from_port       = 7937
    to_port         = 9936
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-linux-client-sg"
  }
}

# Security Group for Windows Client
resource "aws_security_group" "windows_client" {
  name        = "${var.project_name}-windows-client-sg"
  description = "Security group for Windows backup client"
  vpc_id      = aws_vpc.main.id

  # RDP access from admin IP (optional, remove if not needed)
  ingress {
    description = "RDP from admin"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # WinRM HTTP for Ansible from NetWorker (required for initial setup)
  ingress {
    description     = "WinRM HTTP from NetWorker"
    from_port       = 5985
    to_port         = 5985
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # WinRM HTTPS for Ansible from NetWorker
  ingress {
    description     = "WinRM HTTPS from NetWorker"
    from_port       = 5986
    to_port         = 5986
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # WinRM HTTP for Ansible from admin (required for initial setup)
  ingress {
    description = "WinRM HTTP from admin"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # WinRM HTTPS for Ansible from admin
  ingress {
    description = "WinRM HTTPS from admin"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # NetWorker client services
  ingress {
    description     = "NetWorker client services"
    from_port       = 7937
    to_port         = 7938
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # NetWorker dynamic port range from server
  ingress {
    description     = "NetWorker dynamic ports from server"
    from_port       = 7937
    to_port         = 9936
    protocol        = "tcp"
    security_groups = [aws_security_group.networker_server.id]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-windows-client-sg"
  }
}

# IAM Role for EC2 instances to access S3 (for DDVE)
resource "aws_iam_role" "ddve_s3_access" {
  name = "${var.project_name}-ddve-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ddve-s3-role"
  }
}

resource "aws_iam_role_policy" "ddve_s3_access" {
  name = "${var.project_name}-ddve-s3-policy"
  role = aws_iam_role.ddve_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:ListBucketVersions",
          "s3:GetBucketTagging",
          "s3:GetBucketLogging",
          "s3:GetBucketAcl"
        ]
        Resource = aws_s3_bucket.ddve_cloud_tier.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:GetObjectAcl"
        ]
        Resource = "${aws_s3_bucket.ddve_cloud_tier.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" : "DDVE"
          }
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ddve" {
  name = "${var.project_name}-ddve-profile"
  role = aws_iam_role.ddve_s3_access.name

  tags = {
    Name = "${var.project_name}-ddve-profile"
  }
}