# Staging environment configuration
environment  = "staging"
project_name = "aws-networker-lab-staging"

# Production-like sizing
instance_types = {
  networker_server = "t3.medium"
  ddve             = "t3.xlarge"
  linux_client     = "t3.small"
  windows_client   = "t3.small"
}

# Standard storage
storage_sizes = {
  networker_server = 50
  ddve             = 250
  linux_client     = 30
  windows_client   = 30
}

# Mixed instance strategy
use_spot_instances = true
spot_price         = "0.8"

# Enable some production features
enable_s3_versioning        = true
enable_s3_logging           = true
enable_monitoring_alerts    = false
enable_monitoring_dashboard = true

# Staging tags
common_tags = {
  ManagedBy   = "Terraform"
  Environment = "staging"
  Purpose     = "Pre-Production Testing"
}