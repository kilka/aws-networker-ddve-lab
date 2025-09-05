# PowerProtect Data Manager Module
# Uses CloudFormation template for proper initialization

locals {
  # CloudFormation template URL from Dell marketplace
  cloudformation_template_url = "https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/bed501f4-4a5b-45c8-84c4-ad03bf330ba3/dd21ebbe2f35444ebc0d0007a5d22207.template"
  
  ppdm_user_data = <<-EOF
    #!/bin/bash
    echo "PowerProtect Data Manager starting" > /var/log/user-data.log
    echo "Initial setup will take 10-15 minutes" >> /var/log/user-data.log
  EOF
}

# CloudFormation Stack for PPDM
resource "aws_cloudformation_stack" "ppdm" {
  name         = "${var.environment}-ppdm-stack"
  template_url = local.cloudformation_template_url
  
  parameters = {
    # Required Parameters
    PPDMVpcId                 = var.vpc_id
    InboundIPRange            = "0.0.0.0/0"
    KeyPairName               = var.key_name
    PPDMCommonPassword        = "Changeme123!"
    PPDMCommonPasswordConfirm = "Changeme123!"
    
    # Network Configuration
    PPDMSubnetId              = var.subnet_id
    PPDMPrivateIpAddress      = ""  # Let AWS assign
    PPDMEnablePublicIp        = "Yes"
    PPDMSecurityGroup         = var.security_group_id  # Use our Terraform-managed security group
    
    # Optional Configuration
    PPDMIAMRole               = ""
    PPDMTimeZone              = "America/New_York - Eastern Standard Time"  # Exact format required by CloudFormation
    PPDMNTPServers            = "pool.ntp.org"
    ConfigurePPDMDNSServers   = "No"
    PPDMDNSServers            = ""
    PPDMFqdn                  = ""
    AllowStackOptimization    = "No"
    
    # Required Acceptance
    AcceptEula                = "Yes"
  }
  
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  tags = {
    Name        = "${var.environment}-ppdm"
    Environment = var.environment
  }
}

# Get instance details from CloudFormation outputs
data "aws_instances" "ppdm" {
  depends_on = [aws_cloudformation_stack.ppdm]
  
  filter {
    name   = "tag:aws:cloudformation:stack-name"
    values = [aws_cloudformation_stack.ppdm.name]
  }
  
  filter {
    name   = "tag:aws:cloudformation:logical-id"
    values = ["PPDMEc2Instance"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running", "pending"]
  }
}

# Elastic IP and Route53 removed - using jump box architecture