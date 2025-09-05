# Avamar Virtual Edition Variables

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "aws-avamar-lab"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet (NAT Gateway)"
  type        = string
  default     = "10.2.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet (Avamar)"
  type        = string
  default     = "10.2.2.0/24"
}

variable "assign_public_ip" {
  description = "Assign public IP to Avamar instance"
  type        = bool
  default     = true
}

# Instance Configuration
variable "avamar_ami" {
  description = "AMI ID for Avamar Virtual Edition"
  type        = string
  default     = "ami-07fbfe86046159cc0"
}

variable "instance_type" {
  description = "EC2 instance type for Avamar VE"
  type        = string
  default     = "m4.xlarge"

  validation {
    condition = contains([
      "m4.large", "m4.xlarge", "m4.2xlarge", "m4.4xlarge",
      "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
      "c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge"
    ], var.instance_type)
    error_message = "Instance type must be suitable for Avamar VE workloads."
  }
}

# Storage Configuration
variable "root_disk_size" {
  description = "Size of root disk in GB (minimum 161GB for Avamar AMI)"
  type        = number
  default     = 161

  validation {
    condition     = var.root_disk_size >= 161
    error_message = "Root disk size must be at least 161GB for Avamar VE AMI requirements."
  }
}

variable "data_disk_size" {
  description = "Size of each data disk in GB (minimum 250GB per Avamar requirements)"
  type        = number
  default     = 250

  validation {
    condition     = var.data_disk_size >= 250
    error_message = "Data disk size must be at least 250GB per Avamar VE requirements."
  }
}

variable "data_disk_count" {
  description = "Number of data disks (minimum 3 per Avamar requirements)"
  type        = number
  default     = 3

  validation {
    condition     = var.data_disk_count >= 3
    error_message = "Minimum 3 data disks required for Avamar VE."
  }
}

# Security Configuration
variable "admin_ip_cidrs" {
  description = "List of CIDR blocks for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Update this for better security
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "avamar_key"
}

variable "public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "../aws_key.pub"
}

# Access Configuration
variable "create_bastion" {
  description = "Create bastion host for accessing private Avamar instance"
  type        = bool
  default     = true
}

# Resource Tagging
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Purpose     = "Avamar Lab"
    Application = "Avamar VE"
  }
}

# Backup Configuration
variable "enable_daily_snapshots" {
  description = "Enable daily EBS snapshots for data volumes"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Number of days to retain EBS snapshots"
  type        = number
  default     = 7
}