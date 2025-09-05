output "instance_id" {
  value = length(data.aws_instances.ppdm.ids) > 0 ? data.aws_instances.ppdm.ids[0] : ""
}

output "public_ip" {
  value = null  # No public IP - access via jump box
}

output "private_ip" {
  value = length(data.aws_instances.ppdm.private_ips) > 0 ? data.aws_instances.ppdm.private_ips[0] : ""
}

