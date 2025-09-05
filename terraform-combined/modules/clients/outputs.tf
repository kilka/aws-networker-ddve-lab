# Linux Client Outputs
output "linux_instance_id" {
  value = var.deploy_linux_client ? aws_instance.linux_client[0].id : null
}

output "linux_public_ip" {
  value = null  # No public IP - access via Windows jump box
}

output "linux_private_ip" {
  value = var.deploy_linux_client ? aws_instance.linux_client[0].private_ip : null
}


# Windows Client Outputs
output "windows_instance_id" {
  value = var.deploy_windows_client ? aws_instance.windows_client[0].id : null
}

output "windows_public_ip" {
  value = var.deploy_windows_client ? aws_eip.windows_client[0].public_ip : null
}

output "windows_private_ip" {
  value = var.deploy_windows_client ? aws_instance.windows_client[0].private_ip : null
}


# Convenience output for Windows password retrieval
output "windows_password_command" {
  value = var.deploy_windows_client ? "aws ec2 get-password-data --instance-id ${aws_instance.windows_client[0].id} --priv-launch-key ../dataprotection_key --region ${data.aws_region.current.name}" : null
  description = "Command to retrieve Windows Administrator password"
}

# Data source for current region
data "aws_region" "current" {}