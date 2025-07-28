# AWS NetWorker Lab - Quick Start Guide

## 2-Minute Deployment

### Prerequisites Check (30 seconds)
```bash
# Verify you have required tools
terraform --version  # Need 1.5+
ansible --version    # Need 2.14+
aws --version        # Need AWS CLI v2
make --version       # Need GNU Make

# Verify AWS credentials
aws sts get-caller-identity
```

### Deploy (90 seconds to start)
```bash
# Clone the repository
git clone https://github.com/your-org/aws-networker-lab.git
cd aws-networker-lab

# One-command setup (generates keys + config)
make quick-setup

# Deploy everything
make deploy
```

That's it! The deployment will take about 10-15 minutes to complete.

## What Just Happened?

1. **SSH Keys Generated**: Secure key pair created automatically
2. **Your IP Detected**: Security groups configured for your access only
3. **Infrastructure Deployed**: 
   - VPC with public/private subnets
   - NetWorker Server
   - DDVE storage system
   - Linux and Windows backup clients
4. **Services Configured**: All components connected and ready

## Access Your Environment

```bash
# See all access details
make status

# SSH to NetWorker Server
ssh -i aws_key ec2-user@<networker-ip>

# View costs estimate
make cost-estimate
```

## Save Money

```bash
# Stop all instances when not using
make stop

# Start them again when needed
make start

# Completely remove everything
make destroy
```

## Troubleshooting

**Issue**: Can't connect to instances
```bash
# Check your current IP
make get-my-ip
# Update terraform/terraform.tfvars if IP changed
# Re-run: make deploy
```

**Issue**: Deployment fails
```bash
# Check AWS limits
aws service-quotas list-service-quotas --service-code ec2

# Try different region
AWS_REGION=us-west-2 make deploy
```

## Minimal Manual Configuration

If automatic setup fails, you only need ONE configuration:

```bash
# Edit this file
vi terraform/terraform.tfvars

# Add just this line with your IP:
admin_ip_cidr = "YOUR_IP_ADDRESS/32"
```

To find your IP: `curl -s https://api.ipify.org`

## Cost Breakdown

**Estimated hourly cost**: ~$0.20-0.25/hour when running (50% savings!)

| Component | Type | Hourly Cost |
|-----------|------|-------------|
| NetWorker | t3.medium | ~$0.042 |
| DDVE | t3.xlarge | ~$0.166 |
| Linux Client | t3.small | ~$0.021 |
| Windows Client | t3.small | ~$0.021 |
| Storage & Network | Reduced | ~$0.02-0.05 |

**Remember**: Use `make stop` when not actively using the lab!