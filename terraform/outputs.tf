output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "networker_server_public_ip" {
  description = "Public IP of NetWorker Server"
  value       = aws_eip.networker_server.public_ip
}

output "networker_server_private_ip" {
  description = "Private IP of NetWorker Server"
  value       = local.networker_server_instance != null ? local.networker_server_instance.private_ip : ""
}

output "ddve_public_ip" {
  description = "Public IP of DDVE"
  value       = aws_eip.ddve.public_ip
}

output "ddve_private_ip" {
  description = "Private IP of DDVE"
  value       = local.ddve_instance != null ? local.ddve_instance.private_ip : ""
}

output "linux_client_private_ip" {
  description = "Private IP of Linux Client"
  value = var.use_spot_instances ? (
    length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0].private_ip : ""
    ) : (
    length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0].private_ip : ""
  )
}

output "linux_client_public_ip" {
  description = "Public IP of Linux Client"
  value       = aws_eip.linux_client.public_ip
}

output "windows_client_private_ip" {
  description = "Private IP of Windows Client"
  value = var.use_spot_instances ? (
    length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].private_ip : ""
    ) : (
    length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].private_ip : ""
  )
}

output "windows_client_public_ip" {
  description = "Public IP of Windows Client"
  value       = aws_eip.windows_client.public_ip
}

output "windows_client_instance_id" {
  description = "Instance ID of Windows Client"
  value = var.use_spot_instances ? (
    length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].id : ""
    ) : (
    length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].id : ""
  )
}

output "instance_type_mode" {
  description = "Instance type mode (spot or on-demand)"
  value       = var.use_spot_instances ? "spot" : "on-demand"
}

output "estimated_savings" {
  description = "Estimated cost savings using spot instances"
  value       = var.use_spot_instances ? "Up to 70-90% savings on compute costs" : "Using on-demand pricing"
}

output "s3_bucket_name" {
  description = "Name of S3 bucket for DDVE cloud tier"
  value       = aws_s3_bucket.ddve_cloud_tier.id
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.main.key_name
}

# Generate dynamic inventory for Ansible
output "ansible_inventory" {
  description = "Dynamic inventory for Ansible"
  value = jsonencode({
    all = {
      children = {
        networker_servers = {
          hosts = {
            networker_server = {
              ansible_host                 = aws_eip.networker_server.public_ip
              ansible_user                 = "admin"
              ansible_ssh_private_key_file = "../aws_key"
              private_ip                   = local.networker_server_instance != null ? local.networker_server_instance.private_ip : ""
              instance_id                  = local.networker_server_instance != null ? local.networker_server_instance.id : ""
            }
          }
        }
        ddve_systems = {
          hosts = {
            ddve = {
              ansible_host                 = aws_eip.ddve.public_ip
              ansible_user                 = "sysadmin"
              ansible_ssh_private_key_file = "../aws_key"
              private_ip                   = local.ddve_instance != null ? local.ddve_instance.private_ip : ""
              instance_id                  = local.ddve_instance != null ? local.ddve_instance.id : ""
              s3_bucket                    = aws_s3_bucket.ddve_cloud_tier.id
            }
          }
        }
        linux_clients = {
          hosts = {
            linux_client = {
              ansible_host                 = aws_eip.linux_client.public_ip
              ansible_user                 = "ec2-user"
              ansible_ssh_private_key_file = "../aws_key"
              private_ip                   = var.use_spot_instances ? (length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0].private_ip : "") : (length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0].private_ip : "")
              instance_id                  = var.use_spot_instances ? (length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0].id : "") : (length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0].id : "")
            }
          }
        }
        windows_clients = {
          hosts = {
            windows_client = {
              ansible_host                         = aws_eip.windows_client.public_ip
              ansible_user                         = "Administrator"
              ansible_password                     = "CHANGE_ME" # Will be retrieved from AWS
              ansible_connection                   = "winrm"
              ansible_winrm_transport              = "ntlm"
              ansible_winrm_server_cert_validation = "ignore"
              ansible_port                         = 5985
              ansible_winrm_scheme                 = "http"
              private_ip                           = var.use_spot_instances ? (length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].private_ip : "") : (length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].private_ip : "")
              instance_id                          = var.use_spot_instances ? (length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].id : "") : (length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].id : "")
            }
          }
        }
      }
    }
  })
}

# Write inventory to file for Ansible
resource "local_file" "ansible_inventory" {
  content = jsonencode({
    all = {
      children = {
        networker_servers = {
          hosts = {
            networker_server = {
              ansible_host                 = aws_eip.networker_server.public_ip
              ansible_user                 = "admin"
              ansible_ssh_private_key_file = "../aws_key"
              private_ip                   = local.networker_server_instance != null ? local.networker_server_instance.private_ip : ""
              instance_id                  = local.networker_server_instance != null ? local.networker_server_instance.id : ""
            }
          }
        }
        ddve_systems = {
          hosts = {
            ddve = {
              ansible_host                 = aws_eip.ddve.public_ip
              ansible_user                 = "sysadmin"
              ansible_ssh_private_key_file = "../aws_key"
              private_ip                   = local.ddve_instance != null ? local.ddve_instance.private_ip : ""
              instance_id                  = local.ddve_instance != null ? local.ddve_instance.id : ""
              s3_bucket                    = aws_s3_bucket.ddve_cloud_tier.id
            }
          }
        }
        linux_clients = {
          hosts = {
            linux_client = {
              ansible_host                 = aws_eip.linux_client.public_ip
              ansible_user                 = "ec2-user"
              ansible_ssh_private_key_file = "../aws_key"
              private_ip                   = var.use_spot_instances ? (length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0].private_ip : "") : (length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0].private_ip : "")
              instance_id                  = var.use_spot_instances ? (length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0].id : "") : (length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0].id : "")
            }
          }
        }
        windows_clients = {
          hosts = {
            windows_client = {
              ansible_host                         = aws_eip.windows_client.public_ip
              ansible_user                         = "Administrator"
              ansible_password                     = "CHANGE_ME" # Will be retrieved from AWS
              ansible_connection                   = "winrm"
              ansible_winrm_transport              = "ntlm"
              ansible_winrm_server_cert_validation = "ignore"
              ansible_port                         = 5985
              ansible_winrm_scheme                 = "http"
              private_ip                           = var.use_spot_instances ? (length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].private_ip : "") : (length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].private_ip : "")
              instance_id                          = var.use_spot_instances ? (length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].id : "") : (length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].id : "")
            }
          }
        }
      }
    }
  })
  filename = "../ansible/inventory/dynamic_inventory.json"

  depends_on = [
    aws_instance.networker_server,
    aws_instance.networker_server_spot,
    aws_instance.ddve,
    aws_instance.ddve_spot,
    aws_instance.linux_client,
    aws_instance.linux_client_spot,
    aws_instance.windows_client,
    aws_instance.windows_client_spot
  ]
}

# Output instructions
output "deployment_instructions" {
  description = "Next steps after Terraform apply"
  value       = <<-EOT
    
    Deployment Complete! Next steps:
    
    1. SSH to NetWorker Server:
       ssh -i aws_key admin@${aws_eip.networker_server.public_ip}
       Initial password: ${local.networker_server_instance != null ? local.networker_server_instance.private_ip : "<private-ip>"}
    
    2. Access DDVE Web Interface:
       https://${aws_eip.ddve.public_ip}
       
    3. SSH to Linux Client:
       ssh -i aws_key ec2-user@${aws_eip.linux_client.public_ip}
    
    4. Run Ansible configuration:
       cd ../ansible
       ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml
    
    5. For Windows client password:
       aws ec2 get-password-data --instance-id ${var.use_spot_instances ? (length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].id : "") : (length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].id : "")} --priv-launch-key ../aws_key
    
    Remember to update the Windows password in the Ansible inventory before running playbooks.
  EOT
}