# PowerProtect Data Manager CloudFormation Outputs

# CloudFormation Stack Information
output "cloudformation_stack_id" {
  description = "CloudFormation stack ID"
  value       = aws_cloudformation_stack.ppdm.id
}

output "cloudformation_stack_outputs" {
  description = "All CloudFormation stack outputs"
  value       = aws_cloudformation_stack.ppdm.outputs
}

# PPDM Instance Information
output "ppdm_instance_id" {
  description = "Instance ID of the PPDM server"
  value       = local.ppdm_instance_id
}

output "ppdm_private_ip" {
  description = "Private IP address of the PPDM server"
  value       = local.ppdm_private_ip
}

output "ppdm_public_ip" {
  description = "Public IP address of the PPDM server"
  value       = var.assign_public_ip ? local.ppdm_public_ip : null
}

output "ppdm_web_url" {
  description = "PPDM web interface URL"
  value       = var.assign_public_ip ? "https://${local.ppdm_public_ip}" : "https://${local.ppdm_private_ip}"
}

output "ppdm_api_url" {
  description = "PPDM API URL"
  value       = var.assign_public_ip ? "https://${local.ppdm_public_ip}:8443" : "https://${local.ppdm_private_ip}:8443"
}

output "ssh_command" {
  description = "SSH command to connect to PPDM"
  value       = var.assign_public_ip ? "ssh -i ${var.key_name}.pem admin@${local.ppdm_public_ip}" : "ssh -i ${var.key_name}.pem admin@${local.ppdm_private_ip}"
}

# Network Information
output "vpc_id" {
  description = "VPC ID where PPDM is deployed"
  value       = aws_vpc.ppdm_vpc.id
}

output "subnet_id" {
  description = "Subnet ID where PPDM is deployed"
  value       = aws_subnet.ppdm_subnet.id
}

# IAM Information
output "iam_role_arn" {
  description = "IAM role ARN for PPDM (if created)"
  value       = var.create_iam_role ? aws_iam_role.ppdm_role[0].arn : null
}

# Deployment Information
output "deployment_info" {
  description = "Complete deployment information and access details"
  sensitive   = true
  value = {
    web_interface = var.assign_public_ip ? "https://${local.ppdm_public_ip}" : "https://${local.ppdm_private_ip}"
    api_endpoint  = var.assign_public_ip ? "https://${local.ppdm_public_ip}:8443" : "https://${local.ppdm_private_ip}:8443"
    ssh_access    = var.assign_public_ip ? "ssh -i ${var.key_name}.pem admin@${local.ppdm_public_ip}" : "ssh -i ${var.key_name}.pem admin@${local.ppdm_private_ip}"
    default_credentials = "admin / ${var.common_password}"
    initial_setup_url   = var.assign_public_ip ? "https://${local.ppdm_public_ip}/setup" : "https://${local.ppdm_private_ip}/setup"
    deployment_method   = "CloudFormation"
    stack_status       = try(aws_cloudformation_stack.ppdm.outputs["Status"], "Creating")
  }
}

# Quick Access Information
output "quick_access" {
  description = "Quick access information for PPDM"
  value = {
    web_url     = var.assign_public_ip ? "https://${local.ppdm_public_ip}" : "https://${local.ppdm_private_ip}"
    username    = "admin"
    ready_check = "curl -k -s -o /dev/null -w '%%{http_code}' ${var.assign_public_ip ? "https://${local.ppdm_public_ip}" : "https://${local.ppdm_private_ip}"}"
  }
}

# Cost Information
output "estimated_hourly_cost" {
  description = "Estimated hourly cost breakdown"
  value = {
    instance = "~$0.384/hour (m5.2xlarge)"
    storage  = "Included in CloudFormation template"
    network  = "~$0.005/hour (Elastic IP)"
    total    = "~$0.39/hour"
    monthly  = "~$281/month (24/7)"
    note     = "Actual costs depend on usage and CloudFormation template configuration"
  }
}