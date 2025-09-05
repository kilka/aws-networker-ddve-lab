# PowerProtect Data Manager (PPDM) via CloudFormation Template
# This uses the official Dell EMC CloudFormation template for proper initialization

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
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Configuration (required by CloudFormation template)
resource "aws_vpc" "ppdm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ppdm-vpc"
  })
}

resource "aws_internet_gateway" "ppdm_igw" {
  vpc_id = aws_vpc.ppdm_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ppdm-igw"
  })
}

resource "aws_subnet" "ppdm_subnet" {
  vpc_id                  = aws_vpc.ppdm_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = var.assign_public_ip

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ppdm-subnet"
  })
}

resource "aws_route_table" "ppdm_rt" {
  vpc_id = aws_vpc.ppdm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ppdm_igw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ppdm-rt"
  })
}

resource "aws_route_table_association" "ppdm_rta" {
  subnet_id      = aws_subnet.ppdm_subnet.id
  route_table_id = aws_route_table.ppdm_rt.id
}

# Key Pair
resource "aws_key_pair" "ppdm_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ppdm-key"
  })
}

# IAM Role for PPDM (optional - CloudFormation can create its own)
resource "aws_iam_role" "ppdm_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.project_name}-ppdm-role"

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

  tags = var.common_tags
}

resource "aws_iam_role_policy" "ppdm_policy" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.project_name}-ppdm-policy"
  role  = aws_iam_role.ppdm_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "iam:PassRole",
          "iam:ListInstanceProfiles",
          "iam:ListRoles"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ppdm_profile" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.project_name}-ppdm-profile"
  role  = aws_iam_role.ppdm_role[0].name
}

# PowerProtect Data Manager CloudFormation Stack
resource "aws_cloudformation_stack" "ppdm" {
  name         = "${var.project_name}-ppdm-stack"
  template_url = var.cloudformation_template_url

  parameters = {
    # Required Parameters
    PPDMVpcId                 = aws_vpc.ppdm_vpc.id
    InboundIPRange            = join(",", var.admin_ip_cidrs)
    KeyPairName               = aws_key_pair.ppdm_key.key_name
    PPDMCommonPassword        = var.common_password
    PPDMCommonPasswordConfirm = var.common_password
    
    # Optional Network Configuration
    PPDMSubnetId              = aws_subnet.ppdm_subnet.id
    PPDMPrivateIpAddress      = ""  # Empty when using AWS DNS
    PPDMEnablePublicIp        = var.assign_public_ip ? "Yes" : "No"
    
    # Optional Instance Configuration
    PPDMIAMRole               = var.create_iam_role ? aws_iam_instance_profile.ppdm_profile[0].name : ""
    
    # Optional PPDM Configuration  
    PPDMTimeZone              = var.timezone
    PPDMNTPServers            = var.ntp_server
    ConfigurePPDMDNSServers   = "No"  # Use AWS DNS
    PPDMDNSServers            = ""    # Required by template even when DNS config disabled
    PPDMFqdn                  = ""    # Required by template even when DNS config disabled
    AllowStackOptimization    = "No"
    
    # Required Acceptance
    AcceptEula                = "Yes"
  }

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ppdm-stack"
  })

  # Add timeout for stack operations
  timeout_in_minutes = 60

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# Data source to fetch EC2 instance details
data "aws_instances" "ppdm_instances" {
  filter {
    name   = "tag:aws:cloudformation:stack-name"
    values = ["aws-ppdm-lab-ppdm-stack"]
  }
  
  filter {
    name   = "tag:aws:cloudformation:logical-id"
    values = ["PPDMEc2Instance"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running", "pending"]
  }

  depends_on = [aws_cloudformation_stack.ppdm]
}

# Local values for configuration
locals {
  # Get instance details directly from EC2
  ppdm_instance_id = length(data.aws_instances.ppdm_instances.ids) > 0 ? data.aws_instances.ppdm_instances.ids[0] : ""
  ppdm_public_ip   = length(data.aws_instances.ppdm_instances.public_ips) > 0 ? data.aws_instances.ppdm_instances.public_ips[0] : ""
  ppdm_private_ip  = length(data.aws_instances.ppdm_instances.private_ips) > 0 ? data.aws_instances.ppdm_instances.private_ips[0] : "10.1.1.100"
  ppdm_web_url     = local.ppdm_public_ip != "" ? "https://${local.ppdm_public_ip}" : "https://${local.ppdm_private_ip}"
}