# CloudWatch monitoring for DDVE and infrastructure

# SNS Topic for alerts (optional)
resource "aws_sns_topic" "alerts" {
  count = var.enable_monitoring_alerts ? 1 : 0

  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count = var.enable_monitoring_alerts && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# DDVE CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ddve_cpu_high" {
  count = var.enable_monitoring_alerts ? 1 : 0

  alarm_name          = "${var.project_name}-ddve-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "DDVE CPU utilization is above 80%"

  dimensions = {
    InstanceId = local.ddve_instance != null ? local.ddve_instance.id : ""
  }

  alarm_actions = var.enable_monitoring_alerts ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name = "${var.project_name}-ddve-cpu-alarm"
  }
}

# DDVE CPU Credits (for t3 instances)
resource "aws_cloudwatch_metric_alarm" "ddve_cpu_credits_low" {
  count = var.enable_monitoring_alerts && substr(var.instance_types.ddve, 0, 2) == "t3" ? 1 : 0

  alarm_name          = "${var.project_name}-ddve-cpu-credits-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "DDVE CPU credit balance is low"

  dimensions = {
    InstanceId = local.ddve_instance != null ? local.ddve_instance.id : ""
  }

  alarm_actions = var.enable_monitoring_alerts ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name = "${var.project_name}-ddve-cpu-credits-alarm"
  }
}

# S3 Bucket Size Monitoring
resource "aws_cloudwatch_metric_alarm" "s3_bucket_size_high" {
  count = var.enable_monitoring_alerts ? 1 : 0

  alarm_name          = "${var.project_name}-s3-bucket-size-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400" # Check daily for cost management
  statistic           = "Average"
  threshold           = "1099511627776" # 1TB threshold - adjust based on expected backup volume
  alarm_description   = "DDVE S3 bucket size exceeds 1TB"

  dimensions = {
    BucketName  = aws_s3_bucket.ddve_cloud_tier.id
    StorageType = "StandardStorage"
  }

  alarm_actions = var.enable_monitoring_alerts ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name = "${var.project_name}-s3-size-alarm"
  }
}

# EBS Volume monitoring for DDVE disks
resource "aws_cloudwatch_metric_alarm" "ddve_disk_throughput" {
  for_each = var.enable_monitoring_alerts ? {
    root     = "Root disk"
    nvram    = "NVRAM disk"
    metadata = "Metadata disk"
  } : {}

  alarm_name          = "${var.project_name}-ddve-${each.key}-throughput"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeReadBytes"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1073741824" # 1GB in 5 minutes
  alarm_description   = "DDVE ${each.value} read throughput is high"

  alarm_actions = var.enable_monitoring_alerts ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name = "${var.project_name}-ddve-${each.key}-alarm"
  }
}

# Create CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_monitoring_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "CPUCreditBalance", { stat = "Average", yAxis = "right" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DDVE CPU Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", aws_s3_bucket.ddve_cloud_tier.id, "StorageType", "StandardStorage"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DDVE S3 Storage Usage"
          period  = 86400
        }
      }
    ]
  })
}