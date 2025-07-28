# Development environment configuration
environment  = "dev"
project_name = "aws-networker-lab-dev"

# Cost-optimized for development
instance_types = {
  networker_server = "t3.small"
  ddve             = "t3.large"
  linux_client     = "t3.micro"
  windows_client   = "t3.small"
}

# Minimal storage for dev
storage_sizes = {
  networker_server = 30
  ddve             = 100
  linux_client     = 20
  windows_client   = 30
}

# Always use spot in dev
use_spot_instances = true
spot_price         = "0.7"

# Disable production features
enable_s3_versioning        = false
enable_s3_logging           = false
enable_monitoring_alerts    = false
enable_monitoring_dashboard = false

# Dev tags
common_tags = {
  ManagedBy    = "Terraform"
  Environment  = "dev"
  Purpose      = "Development Testing"
  AutoShutdown = "true"
}