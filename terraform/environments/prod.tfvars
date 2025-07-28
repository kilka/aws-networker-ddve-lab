# Production environment configuration
environment  = "prod"
project_name = "aws-networker-lab-prod"

# Production sizing per Dell EMC recommendations
instance_types = {
  networker_server = "t3.large"
  ddve             = "m5.xlarge"
  linux_client     = "t3.medium"
  windows_client   = "t3.medium"
}

# Production storage
storage_sizes = {
  networker_server = 100
  ddve             = 500
  linux_client     = 50
  windows_client   = 50
}

# No spot instances in production
use_spot_instances = false

# Enable all production features
enable_s3_versioning        = true
enable_s3_logging           = true
enable_ssm_endpoints        = true
enable_monitoring_alerts    = true
enable_monitoring_dashboard = true

# Production alerting
alert_email = "ops-team@company.com"

# Production tags
common_tags = {
  ManagedBy    = "Terraform"
  Environment  = "prod"
  Purpose      = "Production Data Protection"
  Compliance   = "Required"
  BackupPolicy = "Daily"
}