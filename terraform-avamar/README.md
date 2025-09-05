# Avamar Virtual Edition Deployment

Professional Terraform deployment for Dell EMC Avamar Virtual Edition in AWS with private subnet configuration.

## Overview

This deployment creates:
- **VPC**: 10.2.0.0/16 with public and private subnets
- **Avamar VE**: m4.xlarge instance in private subnet
- **Storage**: 3x 250GB data disks (minimum requirement)
- **Network**: NAT Gateway for private subnet internet access
- **Security**: Bastion host for secure access (optional)

## Quick Start

```bash
# 1. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# 2. Deploy Avamar VE
make avamar

# 3. Wait 10 minutes for initialization
# 4. Access AVI interface at https://<private-ip>/avi
```

## Configuration Requirements

### Storage Configuration (Pre-boot)
- **Root Volume**: 100GB (OS and application)
- **Data Volumes**: 3x 250GB minimum (configured before first boot)
- **Total Storage**: ~850GB minimum

### Network Configuration
- **Private Subnet**: Avamar instance (no public IP)
- **Public Subnet**: NAT Gateway and Bastion host
- **Security Groups**: Avamar-specific ports configured

### Initial Access
- **AVI URL**: https://\<private-ip\>/avi
- **Default Username**: admin
- **Default Password**: \<private-ip-address\>

## Deployment Details

### Infrastructure Components

```
┌─────────────────┐    ┌─────────────────┐
│  Public Subnet  │    │ Private Subnet  │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Bastion   │ │    │ │  Avamar VE  │ │
│ │ Host (opt)  │ │    │ │ m4.xlarge   │ │
│ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │                 │
│ │ NAT Gateway │ │    │                 │
│ └─────────────┘ │    │                 │
└─────────────────┘    └─────────────────┘
        │                       │
        └───────────────────────┘
              Internet Gateway
```

### Storage Layout

```
Avamar VE Instance
├── Root Volume (/dev/sda1): 100GB - OS and application
├── Data Volume 1 (/dev/sdf): 250GB - Backup data
├── Data Volume 2 (/dev/sdg): 250GB - Backup data
└── Data Volume 3 (/dev/sdh): 250GB - Backup data
```

### Security Configuration

- **SSH Access**: Via bastion host or VPN
- **AVI Interface**: HTTPS (port 443)
- **Admin Console**: Port 3008
- **Client Communication**: Ports 28001-28002
- **NDMP**: Port 10000

## Usage

### Planning Deployment
```bash
make avamar-plan
```

### Deploying Infrastructure
```bash
make avamar
```

### Destroying Infrastructure
```bash
make destroy-avamar
```

## Post-Deployment Steps

### 1. Initial Wait (10 minutes)
Wait for Avamar VE to complete system-level configuration after first boot.

### 2. Access AVI Interface
- Connect via bastion host or VPN
- Navigate to: https://\<private-ip\>/avi
- Login: admin / \<private-ip-address\>

### 3. Initial Configuration
- Complete Avamar setup wizard
- Configure backup policies
- Add client systems

## Access Methods

### Via Bastion Host (Default)
```bash
# SSH to bastion
ssh -i aws_key ec2-user@<bastion-public-ip>

# SSH to Avamar from bastion
ssh admin@<avamar-private-ip>

# SSH tunnel for AVI access
ssh -i aws_key -L 8443:<avamar-private-ip>:443 ec2-user@<bastion-public-ip>
# Then access: https://localhost:8443/avi
```

### Via VPN/Direct Connect
```bash
# Direct SSH access
ssh -i aws_key admin@<avamar-private-ip>

# Direct HTTPS access
https://<avamar-private-ip>/avi
```

## Cost Optimization

### Estimated Monthly Costs (24/7)
- **Avamar Instance (m4.xlarge)**: ~$146/month
- **NAT Gateway**: ~$45/month
- **EBS Storage (850GB)**: ~$85/month
- **Bastion Host (t3.micro)**: ~$8.50/month
- **Total**: ~$285/month

### Cost Savings
- Stop instance when not in use: Save ~70% on compute
- Use Spot instances for non-production
- Optimize storage types based on usage

## Troubleshooting

### Common Issues
1. **Access Denied**: Check security groups and NACLs
2. **Storage Issues**: Verify all 3 data volumes are attached
3. **Network Issues**: Check NAT Gateway configuration
4. **Password Issues**: Default password is the private IP address

### Validation Commands
```bash
# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>

# Check volumes
aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=<instance-id>"

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

## Technical Specifications

### Minimum Requirements
- **Instance Type**: m4.xlarge (4 vCPU, 16GB RAM)
- **Storage**: 3x 250GB data volumes + 100GB root
- **Network**: Private subnet with NAT Gateway
- **OS**: Avamar VE (Amazon Linux based)

### Supported Instance Types
- M4: m4.large, m4.xlarge, m4.2xlarge, m4.4xlarge
- M5: m5.large, m5.xlarge, m5.2xlarge, m5.4xlarge
- C4/C5: For compute-optimized workloads

## Security Best Practices

1. **Network Security**
   - Deploy in private subnet
   - Use bastion host for access
   - Restrict admin IP ranges

2. **Storage Security**
   - Enable EBS encryption
   - Use KMS keys for sensitive data
   - Enable daily snapshots

3. **Access Control**
   - Use IAM roles for EC2 permissions
   - Enable CloudTrail logging
   - Monitor access patterns

## Support

For issues specific to this deployment:
1. Check logs in `./logs/avamar*.log`
2. Validate Terraform configuration
3. Review AWS CloudFormation events
4. Check Avamar VE documentation

For Avamar-specific issues, consult Dell EMC documentation and support.