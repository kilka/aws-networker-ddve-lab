provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.common_tags, {
      Project = var.project_name
    })
  }
}

# SSH Key Pair
resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-keypair"
  }
}

# S3 Bucket for DDVE Cloud Tier
resource "aws_s3_bucket" "ddve_cloud_tier" {
  bucket        = "${var.project_name}-ddve-cloud-tier-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allow deletion even if bucket contains objects

  tags = {
    Name        = "${var.project_name}-ddve-cloud-tier"
    Description = "Cloud tier storage for DDVE"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ddve_cloud_tier" {
  bucket = aws_s3_bucket.ddve_cloud_tier.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "ddve_cloud_tier" {
  bucket = aws_s3_bucket.ddve_cloud_tier.id

  versioning_configuration {
    status = var.enable_s3_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "ddve_cloud_tier" {
  bucket = aws_s3_bucket.ddve_cloud_tier.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "ddve_cloud_tier" {
  bucket = aws_s3_bucket.ddve_cloud_tier.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  # Clean up old versions if versioning is enabled
  dynamic "rule" {
    for_each = var.enable_s3_versioning ? [1] : []
    content {
      id     = "expire-old-versions"
      status = "Enabled"

      filter {}

      noncurrent_version_expiration {
        noncurrent_days = 90
      }
    }
  }
}

# S3 Bucket Logging
resource "aws_s3_bucket_logging" "ddve_cloud_tier" {
  count = var.enable_s3_logging ? 1 : 0

  bucket = aws_s3_bucket.ddve_cloud_tier.id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "ddve-s3-logs/"
}

# S3 Bucket for logs (if enabled)
resource "aws_s3_bucket" "logs" {
  count = var.enable_s3_logging ? 1 : 0

  bucket = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.enable_s3_logging ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.enable_s3_logging ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for AMIs
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat official

  filter {
    name   = "name"
    values = ["RHEL-8*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}