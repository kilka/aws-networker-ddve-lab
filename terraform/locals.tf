# Local values for reducing duplication and improving maintainability

locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  # AMI mappings using variables
  ddve_ami_map = var.ddve_ami_mapping

  networker_ami_map = var.networker_ami_mapping


  # Network configuration constants
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr

  # Common instance user data script parts
  common_user_data_header = <<-EOF
    #!/bin/bash
    set -ex
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    
    # Update system
    yum update -y || apt-get update -y
    
    # Set hostname
    INSTANCE_ID=$(ec2-metadata --instance-id | cut -d' ' -f2)
  EOF

  # Volume encryption settings
  volume_encrypted  = true
  volume_kms_key_id = null # Use default AWS managed key

  # S3 bucket naming
  s3_bucket_prefix = "${var.project_name}-${var.environment}"
}