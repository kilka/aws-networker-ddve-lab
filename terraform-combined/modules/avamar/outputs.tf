output "instance_id" {
  value = aws_instance.avamar.id
}

output "public_ip" {
  value = null  # No public IP - access via jump box
}

output "private_ip" {
  value = aws_instance.avamar.private_ip
}

