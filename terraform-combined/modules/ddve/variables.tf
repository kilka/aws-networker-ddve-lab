variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for DDVE"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for DDVE"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for DDVE storage"
  type        = string
}