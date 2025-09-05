variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dataprotection-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "admin_ip" {
  description = "Administrator IP address for security group rules"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "aws_key"
}

# DDVE Configuration
variable "ddve_instance_type" {
  description = "Instance type for DDVE"
  type        = string
  default     = "m5.xlarge"
}

# Avamar Configuration
variable "deploy_avamar" {
  description = "Deploy Avamar instance"
  type        = bool
  default     = true
}

variable "avamar_instance_type" {
  description = "Instance type for Avamar"
  type        = string
  default     = "m4.xlarge"  # Matching working config
}

# PowerProtect Configuration
variable "deploy_powerprotect" {
  description = "Deploy PowerProtect Data Manager"
  type        = bool
  default     = true
}

variable "ppdm_instance_type" {
  description = "Instance type for PowerProtect Data Manager"
  type        = string
  default     = "m5.2xlarge"
}

# Test Client Configuration
variable "deploy_test_clients" {
  description = "Deploy test client instances (Linux and Windows)"
  type        = bool
  default     = true
}

variable "linux_client_instance_type" {
  description = "Instance type for Linux test client"
  type        = string
  default     = "t3.small"
}

variable "windows_client_instance_type" {
  description = "Instance type for Windows test client"
  type        = string
  default     = "t3.medium"
}