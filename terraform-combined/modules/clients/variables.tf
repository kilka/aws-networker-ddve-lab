variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for client instances"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

# Linux Client Variables
variable "deploy_linux_client" {
  description = "Deploy Linux test client"
  type        = bool
  default     = true
}

variable "linux_instance_type" {
  description = "Instance type for Linux client"
  type        = string
  default     = "t3.small"
}

variable "linux_security_group_id" {
  description = "Security group ID for Linux client"
  type        = string
}

# Windows Client Variables
variable "deploy_windows_client" {
  description = "Deploy Windows test client"
  type        = bool
  default     = true
}

variable "windows_instance_type" {
  description = "Instance type for Windows client"
  type        = string
  default     = "t3.medium"
}

variable "windows_security_group_id" {
  description = "Security group ID for Windows client"
  type        = string
}

# Private IPs for hosts file configuration
variable "ddve_private_ip" {
  description = "DDVE private IP for Windows hosts file"
  type        = string
  default     = ""
}

variable "avamar_private_ip" {
  description = "Avamar private IP for Windows hosts file"
  type        = string
  default     = ""
}

variable "ppdm_private_ip" {
  description = "PPDM private IP for Windows hosts file"
  type        = string
  default     = ""
}