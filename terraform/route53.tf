# Route53 Private Hosted Zone for Internal DNS Resolution
# This enables servers to communicate using FQDNs and short names

resource "aws_route53_zone" "private" {
  name          = var.internal_domain_name
  comment       = "Private DNS zone for ${var.project_name} internal communication"
  force_destroy = true

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-zone"
    Environment = var.environment
    Purpose     = "Internal DNS Resolution"
  }

  # Prevent conflicts with existing zones
  lifecycle {
    create_before_destroy = true
  }
}

# DNS Records for DDVE
resource "aws_route53_record" "ddve_a" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "networker-lab-ddve-01.${var.internal_domain_name}"
  type    = "A"
  ttl     = 300
  records = [local.ddve_instance != null ? local.ddve_instance.private_ip : ""]

  depends_on = [
    aws_instance.ddve,
    aws_instance.ddve_spot
  ]
}

# Short name CNAME for DDVE
resource "aws_route53_record" "ddve_cname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "ddve.${var.internal_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["networker-lab-ddve-01.${var.internal_domain_name}"]

  depends_on = [aws_route53_record.ddve_a]
}

# DNS Records for NetWorker Server
resource "aws_route53_record" "networker_a" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "networker-lab-server-01.${var.internal_domain_name}"
  type    = "A"
  ttl     = 300
  records = [local.networker_server_instance != null ? local.networker_server_instance.private_ip : ""]

  depends_on = [
    aws_instance.networker_server,
    aws_instance.networker_server_spot
  ]
}

# Short name CNAME for NetWorker
resource "aws_route53_record" "networker_cname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "networker.${var.internal_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["networker-lab-server-01.${var.internal_domain_name}"]

  depends_on = [aws_route53_record.networker_a]
}

# DNS Records for Linux Client
resource "aws_route53_record" "linux_client_a" {
  count   = var.use_spot_instances ? (length(aws_instance.linux_client_spot) > 0 ? 1 : 0) : (length(aws_instance.linux_client) > 0 ? 1 : 0)
  zone_id = aws_route53_zone.private.zone_id
  name    = "networker-lab-linux-01.${var.internal_domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.use_spot_instances ?
    (length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0].private_ip : "") :
    (length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0].private_ip : "")
  ]

  depends_on = [
    aws_instance.linux_client,
    aws_instance.linux_client_spot
  ]
}

# DNS Records for Windows Client
resource "aws_route53_record" "windows_client_a" {
  count   = var.use_spot_instances ? (length(aws_instance.windows_client_spot) > 0 ? 1 : 0) : (length(aws_instance.windows_client) > 0 ? 1 : 0)
  zone_id = aws_route53_zone.private.zone_id
  name    = "networker-lab-windows-01.${var.internal_domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.use_spot_instances ?
    (length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0].private_ip : "") :
    (length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0].private_ip : "")
  ]

  depends_on = [
    aws_instance.windows_client,
    aws_instance.windows_client_spot
  ]
}

# Output the private zone details
output "private_dns_zone" {
  description = "Private DNS zone information"
  value = {
    zone_id      = aws_route53_zone.private.zone_id
    domain_name  = aws_route53_zone.private.name
    name_servers = aws_route53_zone.private.name_servers
  }
}

output "dns_records" {
  description = "Internal DNS records for server communication"
  value = {
    ddve_fqdn       = "networker-lab-ddve-01.${var.internal_domain_name}"
    ddve_short      = "ddve.${var.internal_domain_name}"
    networker_fqdn  = "networker-lab-server-01.${var.internal_domain_name}"
    networker_short = "networker.${var.internal_domain_name}"
    linux_fqdn      = "networker-lab-linux-01.${var.internal_domain_name}"
    windows_fqdn    = "networker-lab-windows-01.${var.internal_domain_name}"
  }
}