# PowerProtect Data Manager (PPDM) Terraform Deployment

This Terraform configuration deploys Dell EMC PowerProtect Data Manager in AWS, based on the official CloudFormation template requirements.

## Prerequisites

1. **AWS Marketplace Subscription** (for production deployment):
   - Subscribe to PowerProtect Data Manager in AWS Marketplace
   - Update AMI IDs in `main.tf` after subscription

2. **AWS CLI Configuration**:
   ```bash
   aws configure
   ```

3. **Terraform Installation**:
   - Terraform >= 1.0

## Quick Start

1. **Generate SSH Key Pair**:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ../aws_key -N ""
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Deploy PPDM**:
   ```bash
   make powerprotect
   ```

## Manual Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan Deployment**:
   ```bash
   terraform plan
   ```

3. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

## Instance Requirements

### Minimum Requirements
- **Instance Type**: m5.2xlarge (4 vCPUs, 16GB RAM)
- **Storage**: 
  - Root volume: 250GB
  - Additional volumes: 6x 500GB (configurable)
- **Network**: VPC with internet gateway

### Recommended for Production
- **Instance Type**: m5.4xlarge or larger
- **Storage**: Increase volume sizes based on data retention needs
- **Network**: Private subnet with NAT gateway

## Network Ports

The following ports are configured in the security group:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22   | TCP      | SSH Access |
| 443  | TCP      | HTTPS Web Interface |
| 8443 | TCP      | PPDM API |
| 2051 | TCP      | DD Boost |
| 111  | TCP      | NFS RPC |
| 2049 | TCP      | NFS |

## Post-Deployment Configuration

1. **Access Web Interface**:
   - URL: `https://[public-ip]` or `https://[private-ip]`
   - Initial setup wizard will guide you through configuration

2. **Default Credentials**:
   - Username: `admin`
   - Password: Value from `common_password` variable

3. **Initial Setup Steps**:
   - Configure network settings
   - Set up storage
   - Configure backup policies
   - Add protection sources

## Cost Optimization

- **Spot Instances**: Set `use_spot_instance = true` for development
- **Storage**: Adjust volume sizes in `storage_sizes` variable
- **Instance Size**: Use smaller instance types for testing

## Security Considerations

1. **IP Access**: Update `admin_ip_cidrs` with your specific IP ranges
2. **Passwords**: Change default password after deployment
3. **VPC**: Consider private subnet deployment for production
4. **IAM**: Review IAM permissions for least privilege

## Troubleshooting

### Common Issues

1. **AMI Not Found**:
   - Ensure you've subscribed to PPDM in AWS Marketplace
   - Update AMI IDs in `main.tf` for your region

2. **Instance Launch Failed**:
   - Check instance type availability in your region
   - Verify subnet has available IPs

3. **SSH Access Issues**:
   - Check security group rules
   - Verify key pair permissions (`chmod 600 aws_key`)

### Logs

- Instance user data logs: `/var/log/user-data.log`
- PPDM logs: Available through web interface

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Or using the Makefile:

```bash
make destroy-powerprotect
```

## Support

This is a community template based on Dell EMC's CloudFormation template. For PPDM product support, contact Dell EMC support.