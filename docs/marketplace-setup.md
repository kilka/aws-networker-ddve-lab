# AWS Marketplace Setup Guide

## Overview

This guide explains how to use the actual Dell EMC Data Domain Virtual Edition (DDVE) and NetWorker from AWS Marketplace instead of the simulation mode.

## Prerequisites

### 1. Subscribe to AWS Marketplace Offerings

#### Data Domain Virtual Edition (DDVE)
1. Visit the [DDVE Marketplace Page](https://aws.amazon.com/marketplace/pp/prodview-2x2p43yvgswtm)
2. Click "Continue to Subscribe"
3. Accept the terms and conditions
4. Wait for subscription to be processed (can take a few minutes)

#### NetWorker Virtual Edition
1. Visit the [NetWorker VE Marketplace Page](https://aws.amazon.com/marketplace/pp/prodview-34uq7mzbzj4c4)
2. Click "Continue to Subscribe"
3. Accept the terms and conditions
4. Wait for subscription to be processed

### 2. Find Your AMI IDs

After subscribing, find the AMI IDs for your region:

```bash
# Find DDVE AMI IDs (Dell EMC's AWS Account ID: 679593333241)
aws ec2 describe-images \
  --owners 679593333241 \
  --filters "Name=name,Values=*DDVE*" \
  --query 'Images[?State==`available`].[ImageId,Name,Description]' \
  --output table

# Get the AMI ID for your region
aws ec2 describe-images \
  --owners 679593333241 \
  --filters "Name=name,Values=*DDVE*" \
  --region us-east-1 \
  --query 'Images[0].ImageId' \
  --output text
```

### 3. Update Terraform Configuration

#### Option 1: Update marketplace.tf directly

Edit `terraform/marketplace.tf` and replace the placeholder AMI IDs:

```hcl
variable "ddve_ami_mapping" {
  description = "DDVE AMI IDs by region"
  type        = map(string)
  default = {
    "us-east-1"    = "ami-0xxxxxxxxxxxxx"  # Replace with actual AMI ID
    "us-west-2"    = "ami-0xxxxxxxxxxxxx"  # Replace with actual AMI ID
    "eu-west-1"    = "ami-0xxxxxxxxxxxxx"  # Replace with actual AMI ID
  }
}
```

#### Option 2: Use terraform.tfvars

Add to your `terraform/terraform.tfvars`:

```hcl
# Enable marketplace AMIs
use_marketplace_amis = true

# Override AMI mappings
ddve_ami_mapping = {
  "us-east-1" = "ami-0xxxxxxxxxxxxx"
  "us-west-2" = "ami-0xxxxxxxxxxxxx"
}
```

## DDVE Specific Requirements

### Instance Types
DDVE instance type options:
- Cost-optimized (Lab): t3.xlarge (4 vCPU, 16 GB RAM with burst)
- Minimum production: m5.xlarge (4 vCPU, 16 GB RAM)
- Recommended production: m5.2xlarge or larger
- Storage: 250 GB root + 10 GB NVRAM + 100 GB metadata (S3 for data storage)

### Initial Configuration
DDVE requires initial configuration through its web interface:
1. Default username: `sysadmin`
2. Default password: `changeme`
3. You must change the password on first login

### Licensing
- DDVE comes with a 60-day evaluation license
- For production use, contact Dell EMC for licensing

## Updated Deployment Process

### For US-East-1 Region (Pre-configured)

The DDVE AMI for us-east-1 is already configured in the project:
- AMI ID: `ami-09e2f4b415eacc1b9`

Simply deploy:
```bash
# Ensure you're in us-east-1
export AWS_REGION=us-east-1

# Deploy with real DDVE
make deploy
```

### For Other Regions

1. **Subscribe to marketplace offerings** (see above)

2. **Get AMI IDs for your region**:
   ```bash
   # Helper script to get DDVE AMI
   ./scripts/find-marketplace-amis.sh
   ```

3. **Update configuration**:
   ```bash
   # Add to terraform.tfvars
   echo 'ddve_ami_mapping = { "us-west-2" = "ami-xxxxx" }' >> terraform/terraform.tfvars
   ```

4. **Deploy as normal**:
   ```bash
   make deploy
   ```

## Verification

After deployment with marketplace AMIs:

1. **Access DDVE Web UI**:
   ```bash
   # Get DDVE IP
   cd terraform && terraform output ddve_public_ip
   
   # Access via browser
   https://<ddve-public-ip>
   ```

2. **Initial DDVE Setup**:
   - Login with default credentials
   - Change password
   - Configure storage
   - Enable DD Boost

3. **NetWorker Configuration**:
   - If using marketplace AMI, NetWorker should be pre-installed
   - If using custom AMI, follow your organization's setup process

## Troubleshooting

### Issue: Cannot find marketplace AMI
```bash
# Verify subscription
aws marketplace describe-entities \
  --catalog "AWSMarketplace" \
  --entity-type "Product"

# Check available images
aws ec2 describe-images --owners 679593333241
```

### Issue: Instance type not supported
Some marketplace AMIs have instance type restrictions. Check the marketplace page for supported types.

### Issue: DDVE won't start
- Check CloudWatch logs
- Ensure instance has proper IAM role for S3 access
- Verify security groups allow required ports

## Simulation vs Production Mode

| Feature | Simulation Mode | Production Mode |
|---------|----------------|-----------------|
| AMI | Amazon Linux 2 | DDVE Marketplace AMI |
| Software | Simulated services | Actual DDVE/NetWorker |
| Configuration | Automated mock setup | Real web UI setup |
| Licensing | Not required | 60-day eval or purchased |
| Cost | EC2 only | EC2 + Marketplace fees |

## Next Steps

1. After subscribing to marketplace offerings, update the AMI IDs
2. Deploy with `use_marketplace_amis = true`
3. Complete initial configuration through web interfaces
4. Update Ansible roles for actual software configuration (not simulation)