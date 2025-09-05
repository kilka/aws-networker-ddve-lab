# DDVE AMI Mapping
locals {
  ddve_ami_map = {
    "us-east-1" = "ami-09e2f4b415eacc1b9"  # DDVE marketplace AMI
  }
  
  ddve_ami = lookup(local.ddve_ami_map, data.aws_region.current.name, data.aws_ami.amazon_linux_2.id)
  
  ddve_user_data = <<-EOF
    #!/bin/bash
    echo "DDVE instance starting" > /var/log/user-data.log
    echo "Default credentials: sysadmin / <instance-id>" >> /var/log/user-data.log
    echo "Access via Windows jump box" >> /var/log/user-data.log
    echo "S3 bucket: ${aws_s3_bucket.storage.id}" >> /var/log/user-data.log
  EOF
}

# Data sources
data "aws_region" "current" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM Role for DDVE S3 Access
resource "aws_iam_role" "ddve" {
  name = "${var.environment}-ddve-role"

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
}

# IAM Policy for S3 Access
resource "aws_iam_role_policy" "ddve_s3" {
  name = "${var.environment}-ddve-s3-policy"
  role = aws_iam_role.ddve.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion",
          "s3:ListBucketVersions"
        ]
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ddve" {
  name = "${var.environment}-ddve-profile"
  role = aws_iam_role.ddve.name
}

# S3 Bucket for DDVE Storage
resource "aws_s3_bucket" "storage" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "${var.environment}-ddve-storage"
    Environment = var.environment
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# DDVE EC2 Instance
resource "aws_instance" "ddve" {
  ami                    = local.ddve_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ddve.name

  # Root disk (OS)
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 250
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-ddve-root"
    }
  }

  # NVRAM disk
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp3"
    volume_size           = 10
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-ddve-nvram"
    }
  }

  # Metadata disk
  ebs_block_device {
    device_name           = "/dev/sdc"
    volume_type           = "gp3"
    volume_size           = 200
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-ddve-metadata"
    }
  }

  user_data = base64encode(local.ddve_user_data)

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${var.environment}-ddve"
    Type = "DataDomain"
  }
}

# Elastic IP and Route53 removed - using jump box architecture