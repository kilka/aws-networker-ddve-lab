# EC2 Instance Module - Handles both on-demand and spot instances

# On-demand instance
resource "aws_instance" "this" {
  count = var.use_spot ? 0 : 1

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile
  monitoring             = var.enable_monitoring
  user_data              = var.user_data
  private_ip             = var.private_ip

  associate_public_ip_address = var.associate_public_ip

  # Root volume configuration
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  # Additional volumes
  dynamic "ebs_block_device" {
    for_each = var.additional_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.size
      volume_type           = ebs_block_device.value.type
      encrypted             = ebs_block_device.value.encrypted
      delete_on_termination = true
    }
  }

  # Metadata options for security
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
  }

  tags = merge(var.tags, {
    Name         = var.name
    InstanceType = "on-demand"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Spot instance request
resource "aws_spot_instance_request" "this" {
  count = var.use_spot ? 1 : 0

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile
  monitoring             = var.enable_monitoring
  user_data              = var.user_data
  private_ip             = var.private_ip
  spot_price             = var.spot_price

  associate_public_ip_address = var.associate_public_ip

  # Root volume configuration
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  # Additional volumes
  dynamic "ebs_block_device" {
    for_each = var.additional_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.size
      volume_type           = ebs_block_device.value.type
      encrypted             = ebs_block_device.value.encrypted
      delete_on_termination = true
    }
  }

  # Metadata options for security
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
  }

  tags = merge(var.tags, {
    Name         = var.name
    InstanceType = "spot"
  })

  # Spot instance specific settings
  wait_for_fulfillment = true
  spot_type            = "persistent"

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}