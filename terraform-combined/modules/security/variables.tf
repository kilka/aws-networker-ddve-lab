variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "admin_ip" {
  description = "Administrator IP address for security group rules"
  type        = string
}