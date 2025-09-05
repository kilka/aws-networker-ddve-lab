# Avamar Virtual Edition Outputs

output "deployment_info" {
  description = "Complete deployment information for Avamar VE"
  value = <<-EOT
    
    🚀 Avamar Virtual Edition Deployment Complete!
    
    📋 Instance Information:
    ├── Instance ID: ${aws_instance.avamar.id}
    ├── Instance Type: ${aws_instance.avamar.instance_type}
    ├── Private IP: ${aws_instance.avamar.private_ip}
    ├── Availability Zone: ${aws_instance.avamar.availability_zone}
    └── AMI: ${var.avamar_ami}
    
    🌐 Network Configuration:
    ├── VPC ID: ${aws_vpc.avamar_vpc.id}
    ├── VPC CIDR: ${aws_vpc.avamar_vpc.cidr_block}
    ├── Private Subnet: ${aws_subnet.private.cidr_block}
    ${var.create_bastion ? "└── Bastion Host IP: ${aws_instance.bastion[0].public_ip}" : "└── No Bastion Host Created"}
    
    💾 Storage Configuration:
    ├── Root Volume: ${var.root_disk_size}GB (${aws_instance.avamar.root_block_device[0].volume_id})
    ├── Data Volume 1: ${var.data_disk_size}GB (${aws_ebs_volume.avamar_data_1.id})
    ├── Data Volume 2: ${var.data_disk_size}GB (${aws_ebs_volume.avamar_data_2.id})
    └── Data Volume 3: ${var.data_disk_size}GB (${aws_ebs_volume.avamar_data_3.id})
    
    🔐 Access Information:
    ├── AVI Configuration URL: https://${aws_instance.avamar.public_ip}/avi
    ├── Public IP: ${aws_instance.avamar.public_ip}
    ├── Private IP: ${aws_instance.avamar.private_ip}
    ├── Default Username: admin
    ├── Default Password: ${aws_instance.avamar.private_ip}
    └── SSH Key: ${var.key_name}
    
    ⏱️  Initial Setup:
    ├── Wait 10 minutes for instance to be fully configured
    └── Then access AVI interface for configuration
    
    🌐 Direct Access:
    ├── Web GUI: https://${aws_instance.avamar.public_ip}/avi
    ├── SSH: ssh -i ${replace(var.public_key_path, ".pub", ".pem")} admin@${aws_instance.avamar.public_ip}
    ${var.create_bastion ? "└── Bastion Host: ${aws_instance.bastion[0].public_ip} (optional)" : "└── Direct public IP access enabled"}
    
    EOT
}

# Individual outputs for programmatic access
output "avamar_instance_id" {
  description = "Avamar instance ID"
  value       = aws_instance.avamar.id
}

output "avamar_private_ip" {
  description = "Avamar private IP address"
  value       = aws_instance.avamar.private_ip
}

output "avamar_public_ip" {
  description = "Avamar public IP address"
  value       = aws_instance.avamar.public_ip
}

output "avamar_default_password" {
  description = "Default password for Avamar (private IP address)"
  value       = aws_instance.avamar.private_ip
  sensitive   = true
}

output "avi_url" {
  description = "AVI configuration interface URL"
  value       = "https://${aws_instance.avamar.public_ip}/avi"
}

output "bastion_public_ip" {
  description = "Bastion host public IP (if created)"
  value       = var.create_bastion ? aws_instance.bastion[0].public_ip : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.avamar_vpc.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Avamar security group ID"
  value       = aws_security_group.avamar.id
}

output "data_volume_ids" {
  description = "Data volume IDs"
  value = [
    aws_ebs_volume.avamar_data_1.id,
    aws_ebs_volume.avamar_data_2.id,
    aws_ebs_volume.avamar_data_3.id
  ]
}

output "ssh_command" {
  description = "SSH command to connect to Avamar"
  value = "ssh -i ${replace(var.public_key_path, ".pub", ".pem")} admin@${aws_instance.avamar.public_ip}"
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = <<-EOT
    💰 Estimated Monthly Costs (24/7 operation):
    ├── Avamar Instance (${var.instance_type}): ~$${format("%.2f", 146.0)} 
    ├── NAT Gateway: ~$45.00
    ├── EBS Storage (${var.root_disk_size + (var.data_disk_size * 3)}GB): ~$${format("%.2f", (var.root_disk_size + (var.data_disk_size * 3)) * 0.10)}
    ${var.create_bastion ? "├── Bastion Host (t3.micro): ~$8.50" : ""}
    └── Total: ~$${format("%.2f", 146.0 + 45.0 + ((var.root_disk_size + (var.data_disk_size * 3)) * 0.10) + (var.create_bastion ? 8.50 : 0.0))} per month
    
    💡 Cost Optimization:
    └── Stop instance when not in use to save ~70% on compute costs
  EOT
}

# Connection details for automation
output "connection_details" {
  description = "Connection details for automation tools"
  value = {
    avamar_private_ip    = aws_instance.avamar.private_ip
    avamar_public_ip     = aws_instance.avamar.public_ip
    avi_url             = "https://${aws_instance.avamar.public_ip}/avi"
    default_username    = "admin"
    default_password    = aws_instance.avamar.private_ip
    ssh_key_name        = var.key_name
    bastion_public_ip   = var.create_bastion ? aws_instance.bastion[0].public_ip : null
    security_group_id   = aws_security_group.avamar.id
    vpc_id              = aws_vpc.avamar_vpc.id
    public_subnet_id    = aws_subnet.public.id
    instance_id         = aws_instance.avamar.id
  }
  sensitive = true
}