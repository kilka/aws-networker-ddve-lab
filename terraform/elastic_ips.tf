# Elastic IPs for public instances - works with both spot and on-demand

# Helper locals to get the correct instance references
locals {
  networker_server_instance = var.use_spot_instances ? (
    length(aws_instance.networker_server_spot) > 0 ? aws_instance.networker_server_spot[0] : null
    ) : (
    length(aws_instance.networker_server) > 0 ? aws_instance.networker_server[0] : null
  )

  ddve_instance = var.use_spot_instances ? (
    length(aws_instance.ddve_spot) > 0 ? aws_instance.ddve_spot[0] : null
    ) : (
    length(aws_instance.ddve) > 0 ? aws_instance.ddve[0] : null
  )

  linux_client_instance = var.use_spot_instances ? (
    length(aws_instance.linux_client_spot) > 0 ? aws_instance.linux_client_spot[0] : null
    ) : (
    length(aws_instance.linux_client) > 0 ? aws_instance.linux_client[0] : null
  )

  windows_client_instance = var.use_spot_instances ? (
    length(aws_instance.windows_client_spot) > 0 ? aws_instance.windows_client_spot[0] : null
    ) : (
    length(aws_instance.windows_client) > 0 ? aws_instance.windows_client[0] : null
  )
}

# Elastic IPs for public instances
resource "aws_eip" "networker_server" {
  instance = local.networker_server_instance != null ? local.networker_server_instance.id : null
  domain   = "vpc"

  tags = {
    Name         = "${var.project_name}-networker-server-eip"
    InstanceType = var.use_spot_instances ? "spot" : "on-demand"
  }

  depends_on = [
    aws_instance.networker_server,
    aws_instance.networker_server_spot
  ]
}

resource "aws_eip" "ddve" {
  instance = local.ddve_instance != null ? local.ddve_instance.id : null
  domain   = "vpc"

  tags = {
    Name         = "${var.project_name}-ddve-eip"
    InstanceType = var.use_spot_instances ? "spot" : "on-demand"
  }

  depends_on = [
    aws_instance.ddve,
    aws_instance.ddve_spot
  ]
}