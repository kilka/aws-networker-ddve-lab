output "instance_id" {
  value = aws_instance.ddve.id
}

output "public_ip" {
  value = null  # No public IP - access via jump box
}

output "private_ip" {
  value = aws_instance.ddve.private_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.storage.id
}