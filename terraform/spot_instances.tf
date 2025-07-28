# Spot Instance Launch Templates for cost optimization

# Data source to get current on-demand price
data "aws_ec2_instance_type_offering" "networker" {
  filter {
    name   = "instance-type"
    values = [var.instance_types.networker_server]
  }
  preferred_instance_types = var.spot_instance_types.networker_server
}

data "aws_ec2_instance_type_offering" "ddve" {
  filter {
    name   = "instance-type"
    values = [var.instance_types.ddve]
  }
  preferred_instance_types = var.spot_instance_types.ddve
}

# Launch Template for NetWorker Server
resource "aws_launch_template" "networker_server" {
  count = var.use_spot_instances ? 1 : 0

  name_prefix = "${var.project_name}-networker-lt-"
  description = "Launch template for NetWorker Server with spot instances"

  image_id      = (var.aws_region == "us-east-1" || var.use_marketplace_amis) && lookup(var.networker_ami_mapping, var.aws_region, "") != "" ? var.networker_ami_mapping[var.aws_region] : data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_types.networker_server
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.networker_server.id]

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price                      = var.spot_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop" # Stop instead of terminate
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(local.networker_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name         = "${var.project_name}-networker-server-spot"
      Role         = "NetWorker-Server"
      Environment  = var.environment
      SpotInstance = "true"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-networker-server-root"
    })
  }
}

# Launch Template for DDVE
resource "aws_launch_template" "ddve" {
  count = var.use_spot_instances ? 1 : 0

  name_prefix = "${var.project_name}-ddve-lt-"
  description = "Launch template for DDVE with spot instances"

  image_id      = (var.aws_region == "us-east-1" || var.use_marketplace_amis) && lookup(var.ddve_ami_mapping, var.aws_region, "") != "" ? var.ddve_ami_mapping[var.aws_region] : data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_types.ddve
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.ddve.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ddve.name
  }

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price                      = var.spot_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # EBS optimized
  ebs_optimized = true

  user_data = base64encode(local.ddve_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name         = "${var.project_name}-ddve-spot"
      Role         = "DDVE"
      Environment  = var.environment
      SpotInstance = "true"
    })
  }
}

