terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Project     = "DataProtectionLab"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Key Pair for EC2 instances
resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file("../${var.key_name}.pub")
  
  tags = {
    Name = "${var.environment}-keypair"
  }
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  environment    = var.environment
  vpc_cidr      = var.vpc_cidr
  public_cidr   = var.public_cidr
}

# Security Groups
module "security" {
  source = "./modules/security"
  
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  admin_ip    = var.admin_ip
}

# Data Domain Virtual Edition
module "ddve" {
  source = "./modules/ddve"
  
  environment           = var.environment
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security.ddve_sg_id
  instance_type        = var.ddve_instance_type
  key_name             = aws_key_pair.main.key_name
  s3_bucket_name       = "${var.environment}-ddve-storage-${random_id.bucket_suffix.hex}"
}

# Avamar
module "avamar" {
  count = var.deploy_avamar ? 1 : 0
  
  source = "./modules/avamar"
  
  environment       = var.environment
  subnet_id        = module.vpc.public_subnet_id
  security_group_id = module.security.avamar_sg_id
  instance_type    = var.avamar_instance_type
  key_name         = aws_key_pair.main.key_name
}

# PowerProtect Data Manager
module "powerprotect" {
  count = var.deploy_powerprotect ? 1 : 0
  
  source = "./modules/powerprotect"
  
  environment       = var.environment
  subnet_id        = module.vpc.public_subnet_id
  security_group_id = module.security.ppdm_sg_id
  instance_type    = var.ppdm_instance_type
  key_name         = aws_key_pair.main.key_name
  vpc_id           = module.vpc.vpc_id
}

# Test Clients
module "clients" {
  source = "./modules/clients"
  
  environment               = var.environment
  subnet_id                = module.vpc.public_subnet_id
  key_name                 = aws_key_pair.main.key_name
  
  # Linux client configuration
  deploy_linux_client      = var.deploy_test_clients
  linux_instance_type      = var.linux_client_instance_type
  linux_security_group_id  = module.security.linux_client_sg_id
  
  # Windows client configuration
  deploy_windows_client    = var.deploy_test_clients
  windows_instance_type    = var.windows_client_instance_type
  windows_security_group_id = module.security.windows_client_sg_id
  
  # Pass private IPs for Windows shortcuts
  ddve_private_ip   = module.ddve.private_ip
  avamar_private_ip = var.deploy_avamar ? module.avamar[0].private_ip : ""
  ppdm_private_ip   = var.deploy_powerprotect ? module.powerprotect[0].private_ip : ""
}

# Random ID for S3 bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Outputs
output "ddve_instance_id" {
  value = module.ddve.instance_id
  description = "DDVE Instance ID"
}

output "ddve_public_ip" {
  value = module.ddve.public_ip
  description = "DDVE Public IP for GUI access"
}

output "ddve_private_ip" {
  value = module.ddve.private_ip
  description = "DDVE Private IP for internal communication"
}

output "avamar_instance_id" {
  value = var.deploy_avamar ? module.avamar[0].instance_id : null
  description = "Avamar Instance ID"
}

output "avamar_public_ip" {
  value = var.deploy_avamar ? module.avamar[0].public_ip : null
  description = "Avamar Public IP for GUI access"
}

output "avamar_private_ip" {
  value = var.deploy_avamar ? module.avamar[0].private_ip : null
  description = "Avamar Private IP for internal communication"
}

output "ppdm_instance_id" {
  value = var.deploy_powerprotect ? module.powerprotect[0].instance_id : null
  description = "PowerProtect Instance ID"
}

output "powerprotect_public_ip" {
  value = var.deploy_powerprotect ? module.powerprotect[0].public_ip : null
  description = "PowerProtect Public IP for GUI access"
}

output "powerprotect_private_ip" {
  value = var.deploy_powerprotect ? module.powerprotect[0].private_ip : null
  description = "PowerProtect Private IP for internal communication"
}

output "s3_bucket_name" {
  value = module.ddve.s3_bucket_name
  description = "S3 bucket for DDVE storage"
}

output "admin_urls" {
  value = {
    ddve        = "https://${module.ddve.private_ip}"
    avamar      = var.deploy_avamar ? "https://${module.avamar[0].private_ip}:8443" : null
    powerprotect = var.deploy_powerprotect ? "https://${module.powerprotect[0].private_ip}:14443" : null
    jump_box    = "rdp://${module.clients.windows_public_ip}"
  }
  description = "Admin console URLs (access via Windows jump box)"
}

# Test Client Outputs
output "linux_client_instance_id" {
  value = module.clients.linux_instance_id
  description = "Linux client Instance ID"
}

output "linux_client_public_ip" {
  value = module.clients.linux_public_ip
  description = "Linux client Public IP"
}

output "linux_client_private_ip" {
  value = module.clients.linux_private_ip
  description = "Linux client Private IP"
}

output "windows_client_instance_id" {
  value = module.clients.windows_instance_id
  description = "Windows client Instance ID"
}

output "windows_client_public_ip" {
  value = module.clients.windows_public_ip
  description = "Windows client Public IP"
}

output "windows_client_private_ip" {
  value = module.clients.windows_private_ip
  description = "Windows client Private IP"
}

output "windows_password_command" {
  value = module.clients.windows_password_command
  description = "Command to retrieve Windows Administrator password"
}

output "client_access" {
  value = {
    linux_ssh    = var.deploy_test_clients ? "SSH via jump box to ${module.clients.linux_private_ip}" : null
    windows_rdp  = var.deploy_test_clients ? "RDP to ${module.clients.windows_public_ip} (get password with: make get-windows-password)" : null
  }
  description = "Client access commands (Linux via jump box)"
}