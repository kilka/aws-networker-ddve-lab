output "ddve_sg_id" {
  value = aws_security_group.ddve.id
}

output "avamar_sg_id" {
  value = aws_security_group.avamar.id
}

output "ppdm_sg_id" {
  value = aws_security_group.ppdm.id
}

output "linux_client_sg_id" {
  value = aws_security_group.linux_client.id
}

output "windows_client_sg_id" {
  value = aws_security_group.windows_client.id
}