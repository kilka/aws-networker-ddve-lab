# EC2 Instance Module Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = var.use_spot ? (length(aws_spot_instance_request.this) > 0 ? aws_spot_instance_request.this[0].spot_instance_id : null) : (length(aws_instance.this) > 0 ? aws_instance.this[0].id : null)
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = var.use_spot ? (length(aws_spot_instance_request.this) > 0 ? aws_spot_instance_request.this[0].private_ip : null) : (length(aws_instance.this) > 0 ? aws_instance.this[0].private_ip : null)
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = var.use_spot ? (length(aws_spot_instance_request.this) > 0 ? aws_spot_instance_request.this[0].public_ip : null) : (length(aws_instance.this) > 0 ? aws_instance.this[0].public_ip : null)
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = var.use_spot ? (length(aws_spot_instance_request.this) > 0 ? aws_spot_instance_request.this[0].private_dns : null) : (length(aws_instance.this) > 0 ? aws_instance.this[0].private_dns : null)
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = var.use_spot ? (length(aws_spot_instance_request.this) > 0 ? aws_spot_instance_request.this[0].public_dns : null) : (length(aws_instance.this) > 0 ? aws_instance.this[0].public_dns : null)
}

output "spot_request_id" {
  description = "Spot instance request ID (only for spot instances)"
  value       = var.use_spot && length(aws_spot_instance_request.this) > 0 ? aws_spot_instance_request.this[0].id : null
}