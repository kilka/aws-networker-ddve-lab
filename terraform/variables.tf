variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "aws-networker-lab"
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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "AWS Availability Zone"
  type        = string
  default     = "us-east-1a"
}

variable "internal_domain_name" {
  description = "Internal domain name for private DNS resolution"
  type        = string
  default     = "networker.lab"
}

variable "instance_types" {
  description = "EC2 instance types for each component"
  type = object({
    networker_server = string
    ddve             = string
    linux_client     = string
    windows_client   = string
  })
  default = {
    networker_server = "m5.xlarge" # Production-grade for NetWorker
    ddve             = "m5.xlarge" # Production-grade: 4 vCPU, 16GB RAM, dedicated compute
    linux_client     = "t3.small"  # Minimal for lab client
    windows_client   = "t3.small"  # Minimal for lab client
  }
}

variable "storage_sizes" {
  description = "EBS volume sizes in GB"
  type = object({
    networker_server = number
    ddve             = number
    linux_client     = number
    windows_client   = number
  })
  default = {
    networker_server = 126 # Minimum required by marketplace AMI
    ddve             = 250 # Minimum metadata disk per DDVE docs
    linux_client     = 30  # Minimum for OS
    windows_client   = 30  # Minimum for Windows OS
  }
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "aws_key"
}

variable "public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "../aws_key.pub"
}

variable "admin_ip_cidr" {
  description = "CIDR block for administrative access (your IP)"
  type        = string
  default     = "0.0.0.0/0" # Update this to your actual IP for better security
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Purpose     = "NetWorker Lab"
  }
}


variable "enable_s3_versioning" {
  description = "Enable S3 bucket versioning for DDVE cloud tier"
  type        = bool
  default     = false # Set to true for production
}

variable "enable_s3_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false # Set to true for compliance
}

variable "enable_ssm_endpoints" {
  description = "Enable Systems Manager VPC endpoints for secure access"
  type        = bool
  default     = false # Set to true for enhanced security
}

variable "enable_monitoring_alerts" {
  description = "Enable CloudWatch alarms and SNS notifications"
  type        = bool
  default     = false # Set to true for production monitoring
}

variable "enable_monitoring_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = false # Set to true for visibility
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
}

variable "use_spot_instances" {
  description = "Use spot instances for cost savings (up to 90% discount)"
  type        = bool
  default     = false
}

variable "spot_price" {
  description = "Maximum spot price as percentage of on-demand price (e.g., '0.5' = 50% of on-demand)"
  type        = string
  default     = "0.6" # 60% of on-demand price
}

variable "spot_instance_types" {
  description = "Alternative instance types for spot (increases availability)"
  type = object({
    networker_server = list(string)
    ddve             = list(string)
    linux_client     = list(string)
    windows_client   = list(string)
  })
  default = {
    networker_server = ["t3.medium", "t3a.medium", "t2.medium"]
    ddve             = ["t3.xlarge", "t3a.xlarge", "m5.large", "m5a.large"]
    linux_client     = ["t3.small", "t3a.small", "t2.small"]
    windows_client   = ["t3.small", "t3a.small", "t2.small"]
  }
}


