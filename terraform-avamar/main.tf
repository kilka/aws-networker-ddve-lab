# Avamar Virtual Edition Deployment
# Private subnet deployment with required storage configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.common_tags, {
      Project = var.project_name
    })
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Configuration
resource "aws_vpc" "avamar_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-avamar-vpc"
  }
}

resource "aws_internet_gateway" "avamar_igw" {
  vpc_id = aws_vpc.avamar_vpc.id

  tags = {
    Name = "${var.project_name}-avamar-igw"
  }
}

# NAT Gateway for private subnet internet access
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-avamar-nat-eip"
  }

  depends_on = [aws_internet_gateway.avamar_igw]
}

# Public subnet for NAT Gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.avamar_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-avamar-public-subnet"
  }
}

# Private subnet for Avamar instance
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.avamar_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-avamar-private-subnet"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-avamar-nat-gateway"
  }

  depends_on = [aws_internet_gateway.avamar_igw]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.avamar_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.avamar_igw.id
  }

  tags = {
    Name = "${var.project_name}-avamar-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.avamar_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-avamar-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Key Pair
resource "aws_key_pair" "avamar_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-avamar-key"
  }
}

# Security Group for Avamar
resource "aws_security_group" "avamar" {
  name_prefix = "${var.project_name}-avamar-"
  vpc_id      = aws_vpc.avamar_vpc.id

  # ICMP rules for network diagnostics
  ingress {
    description = "ICMP Time Exceeded"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SNMP TCP and UDP (port 161)
  ingress {
    description = "SNMP TCP"
    from_port   = 161
    to_port     = 161
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SNMP UDP"
    from_port   = 161
    to_port     = 161
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP/UDP port 163
  ingress {
    description = "Custom TCP 163"
    from_port   = 163
    to_port     = 163
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom UDP 163"
    from_port   = 163
    to_port     = 163
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP port 700
  ingress {
    description = "Custom TCP 700"
    from_port   = 700
    to_port     = 700
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP port 7543
  ingress {
    description = "Custom TCP 7543"
    from_port   = 7543
    to_port     = 7543
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Avamar Administrator Console (ports 7778-7781)
  ingress {
    description = "Avamar Administrator Console"
    from_port   = 7778
    to_port     = 7781
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP port 8543
  ingress {
    description = "Custom TCP 8543"
    from_port   = 8543
    to_port     = 8543
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP port 9090
  ingress {
    description = "Custom TCP 9090"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP port 9443
  ingress {
    description = "Custom TCP 9443"
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP port 27000
  ingress {
    description = "Custom TCP 27000"
    from_port   = 27000
    to_port     = 27000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Avamar Client/Server communication (ports 28001-28002)
  ingress {
    description = "Avamar Client/Server communication"
    from_port   = 28001
    to_port     = 28002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP ports 28810-28819
  ingress {
    description = "Custom TCP 28810-28819"
    from_port   = 28810
    to_port     = 28819
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Avamar inter-node communication (port 29000)
  ingress {
    description = "Avamar inter-node communication"
    from_port   = 29000
    to_port     = 29000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP ports 30001-30003
  ingress {
    description = "Custom TCP 30001-30003"
    from_port   = 30001
    to_port     = 30003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-avamar-sg"
  }
}

# IAM Role for Avamar instance
resource "aws_iam_role" "avamar" {
  name = "${var.project_name}-avamar-role"

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
  name = "${var.project_name}-avamar-policy"
  role = aws_iam_role.avamar.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:CreateTags",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "avamar" {
  name = "${var.project_name}-avamar-profile"
  role = aws_iam_role.avamar.name
}

# EBS Volumes for Avamar storage requirements
# Root volume (handled by launch template)
# Data volumes: minimum 3 x 250GB as per requirements

resource "aws_ebs_volume" "avamar_data_1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.data_disk_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-avamar-data-1"
  }
}

resource "aws_ebs_volume" "avamar_data_2" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.data_disk_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-avamar-data-2"
  }
}

resource "aws_ebs_volume" "avamar_data_3" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.data_disk_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-avamar-data-3"
  }
}

# Avamar Virtual Edition Instance
resource "aws_instance" "avamar" {
  ami                         = var.avamar_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.avamar_key.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.avamar.id]
  iam_instance_profile        = aws_iam_instance_profile.avamar.name
  associate_public_ip_address = true

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size          = var.root_disk_size
    encrypted            = true
    delete_on_termination = true
    tags = {
      Name = "${var.project_name}-avamar-root"
    }
  }

  # Enable detailed monitoring
  monitoring = true

  # Enable metadata service for SSH key retrieval
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"  # Allow both IMDSv1 and v2 for compatibility
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "${var.project_name}-avamar-ve"
    Type = "Avamar Virtual Edition"
  }

  # Don't start the instance until storage is attached
  lifecycle {
    ignore_changes = [ami]
  }
}

# Attach data volumes to Avamar instance
resource "aws_volume_attachment" "avamar_data_1" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.avamar_data_1.id
  instance_id  = aws_instance.avamar.id
  force_detach = true
  skip_destroy = false

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "avamar_data_2" {
  device_name  = "/dev/sdg"
  volume_id    = aws_ebs_volume.avamar_data_2.id
  instance_id  = aws_instance.avamar.id
  force_detach = true
  skip_destroy = false

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "avamar_data_3" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.avamar_data_3.id
  instance_id  = aws_instance.avamar.id
  force_detach = true
  skip_destroy = false

  lifecycle {
    prevent_destroy = false
  }
}

# Bastion host for access to private Avamar instance (optional)
resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.avamar_key.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-avamar-bastion"
  }
}

# Security group for bastion host
resource "aws_security_group" "bastion" {
  count       = var.create_bastion ? 1 : 0
  name_prefix = "${var.project_name}-bastion-"
  vpc_id      = aws_vpc.avamar_vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# Data source for Amazon Linux AMI (for bastion)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Local values for configuration
locals {
  avamar_private_ip = aws_instance.avamar.private_ip
  avamar_public_ip  = aws_instance.avamar.public_ip
  avi_url          = "https://${local.avamar_public_ip}/avi"
  default_password = local.avamar_private_ip
}