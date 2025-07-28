# Marketplace AMI Configuration for DDVE and NetWorker
#
# IMPORTANT: You must subscribe to these marketplace offerings before deployment:
# 1. Dell EMC Data Domain Virtual Edition: 
#    https://aws.amazon.com/marketplace/pp/prodview-q7oc4shdnpc4w
# 2. Dell EMC NetWorker (if available) or use custom AMI

# Data Domain Virtual Edition AMI
# Note: The AMI ID varies by region. These are example IDs.
# NOTE: AMI mappings are now defined in locals.tf to use variables properly
# The mappings below are kept for backward compatibility but use locals instead

variable "ddve_ami_mapping" {
  description = "DDVE AMI IDs by region (deprecated - use local.ddve_ami_map)"
  type        = map(string)
  default = {
    # DDVE AMI IDs - Users must subscribe to Dell EMC Data Domain Virtual Edition in AWS Marketplace
    # https://aws.amazon.com/marketplace/pp/prodview-q7oc4shdnpc4w
    "us-east-1"      = "ami-09e2f4b415eacc1b9"
    "us-west-2"      = "ami-PLACEHOLDER-DDVE-USW2"
    "eu-west-1"      = "ami-PLACEHOLDER-DDVE-EUW1"
    "ap-southeast-1" = "ami-PLACEHOLDER-DDVE-APSE1"
  }
}

# NetWorker AMI (Virtual Edition)
variable "networker_ami_mapping" {
  description = "NetWorker AMI IDs by region (deprecated - use local.networker_ami_map)"
  type        = map(string)
  default = {
    # NetWorker Virtual Edition AMI IDs - Users must subscribe in AWS Marketplace
    "us-east-1" = "ami-08560ec5891de83bd"
    "us-west-2" = "ami-PLACEHOLDER-NETWORKER-USW2"
  }
}

# Alternative: Use data source to find DDVE AMI dynamically
# Uncomment after subscribing to marketplace
/*
data "aws_ami" "ddve" {
  most_recent = true
  owners      = ["679593333241"] # Dell EMC AWS Account ID

  filter {
    name   = "name"
    values = ["DDVE-*"]
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
*/

# For testing without marketplace access, use Amazon Linux and simulate
variable "use_marketplace_amis" {
  description = "Use actual marketplace AMIs (requires subscription)"
  type        = bool
  default     = false
}