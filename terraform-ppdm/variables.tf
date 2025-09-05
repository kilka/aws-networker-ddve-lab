# PowerProtect Data Manager Variables for CloudFormation Deployment
# Based on Dell EMC PPDM CloudFormation template requirements

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "aws-ppdm-lab"
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

# CloudFormation Template Configuration
variable "cloudformation_template_url" {
  description = "URL to the official PPDM CloudFormation template"
  type        = string
  default     = "https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/bed501f4-4a5b-45c8-84c4-ad03bf330ba3/dd21ebbe2f35444ebc0d0007a5d22207.template"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "assign_public_ip" {
  description = "Assign public IP to PPDM instance"
  type        = bool
  default     = true
}

variable "private_ip" {
  description = "Static private IP for PPDM (optional - leave empty for automatic assignment)"
  type        = string
  default     = ""
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type for PPDM"
  type        = string
  default     = "m5.2xlarge"
  
  validation {
    condition = contains([
      "m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.8xlarge",
      "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge", "m6i.8xlarge",
      "c5.2xlarge", "c5.4xlarge", "c5.9xlarge",
      "r5.xlarge", "r5.2xlarge", "r5.4xlarge"
    ], var.instance_type)
    error_message = "Instance type must be one of the supported PPDM instance types."
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
  default     = "ppdm_key"
}

variable "public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "../aws_key.pub"
}

# IAM Configuration
variable "create_iam_role" {
  description = "Create IAM role for PPDM instance"
  type        = bool
  default     = true
}

variable "existing_iam_role" {
  description = "Existing IAM role name (if create_iam_role is false)"
  type        = string
  default     = ""
}

# PPDM Configuration
variable "auto_configure" {
  description = "Enable automatic PPDM configuration"
  type        = bool
  default     = true
}

variable "timezone" {
  description = "Timezone for PPDM system (e.g., America/New_York, Europe/London, Asia/Tokyo)"
  type        = string
  default     = "America/New_York"
}

variable "ntp_server" {
  description = "NTP server IP address for time synchronization"
  type        = string
  default     = "pool.ntp.org"
}

variable "dns_server" {
  description = "DNS server IP address"
  type        = string
  default     = "8.8.8.8"
}

variable "common_password" {
  description = "Common password for PPDM configuration - MUST meet complexity requirements: 9-128 characters, uppercase, lowercase, digit, special character (!@#$%^&*)"
  type        = string
  default     = "Changeme123!"
  sensitive   = true

  validation {
    condition = length(var.common_password) >= 9 && length(var.common_password) <= 128 && can(regex("[a-z]", var.common_password)) && can(regex("[A-Z]", var.common_password)) && can(regex("[0-9]", var.common_password)) && can(regex("[!@#$%^&*]", var.common_password))
    error_message = "Password must be 9-128 characters and contain: uppercase letter, lowercase letter, digit, and special character (!@#$%^&*)."
  }
}

# Resource Tagging
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Purpose     = "PPDM Lab"
    Application = "PowerProtect"
  }
}