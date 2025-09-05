# Avamar AMI Mapping
locals {
  avamar_ami_map = {
    "us-east-1" = "ami-07fbfe86046159cc0"  # Avamar marketplace AMI
  }
  
  # Use Amazon Linux 2 as fallback for simulation
  avamar_ami = lookup(local.avamar_ami_map, data.aws_region.current.name, data.aws_ami.amazon_linux_2.id)
  
  avamar_user_data = <<-EOF
    #!/bin/bash
    echo "Avamar instance starting" > /var/log/user-data.log
    echo "Access via Windows jump box" >> /var/log/user-data.log
    echo "Administrator Console available on port 8443" >> /var/log/user-data.log
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

# IAM Role for Avamar instance
resource "aws_iam_role" "avamar" {
  name = "${var.environment}-avamar-role"

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

resource "aws_iam_role_policy" "avamar" {
  name = "${var.environment}-avamar-policy"
  role = aws_iam_role.avamar.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "avamar" {
  name = "${var.environment}-avamar-profile"
  role = aws_iam_role.avamar.name
}

# Avamar EC2 Instance
resource "aws_instance" "avamar" {
  ami                    = local.avamar_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.avamar.name

  # Root disk - Avamar requires 161GB minimum per AMI spec
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 161
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-avamar-root"
    }
  }

  # Data disk 1 - 250GB minimum per Avamar requirements
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = 250
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-avamar-data1"
    }
  }

  # Data disk 2 - 250GB minimum per Avamar requirements
  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_type           = "gp3"
    volume_size           = 250
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-avamar-data2"
    }
  }

  # Data disk 3 - 250GB minimum per Avamar requirements
  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_type           = "gp3"
    volume_size           = 250
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.environment}-avamar-checkpoint"
    }
  }

  user_data = base64encode(local.avamar_user_data)

  metadata_options {
    http_tokens   = "optional"  # Allow both IMDSv1 and v2 for Avamar compatibility
    http_endpoint = "enabled"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "${var.environment}-avamar"
    Type = "Avamar"
  }
}

# Elastic IP and Route53 removed - using jump box architecture