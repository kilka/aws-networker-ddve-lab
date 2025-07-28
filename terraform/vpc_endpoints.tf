# VPC Endpoints for improved performance and security

# S3 Gateway Endpoint - Free and improves S3 performance
# This endpoint allows DDVE to access S3 without going through the internet gateway,
# reducing latency and improving performance for backup operations
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  # Associate with public route table only (simplified architecture)
  route_table_ids = [
    aws_route_table.public.id
  ]

  tags = {
    Name    = "${var.project_name}-s3-endpoint"
    Purpose = "DDVE S3 Access Optimization"
  }
}

# Note: Interface endpoints (EC2, SSM) are not needed in this simplified architecture
# as all instances have public IPs and can access AWS services directly via the internet gateway