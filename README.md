# AWS NetWorker Lab

Automated deployment of Dell EMC NetWorker and Data Domain Virtual Edition (DDVE) on AWS for backup and recovery testing.

## Prerequisites

### AWS Marketplace Subscriptions

For  deployment in us-east-1, subscribe to these free marketplace listings:
- [Dell EMC Data Domain Virtual Edition (DDVE)](https://aws.amazon.com/marketplace/pp/prodview-2x2p43yvgswtm)
- [Dell EMC NetWorker Virtual Edition](https://aws.amazon.com/marketplace/pp/prodview-34uq7mzbzj4c4)

- **AWS Account** with billing enabled
- **AWS CLI** configured with credentials (`aws configure`)
- **Terraform** >= 1.5.0
- **Ansible** >= 2.14.0
- **Make** and **jq** installed
- **Git** for cloning the repository

### Quick Install (macOS)
```bash
brew install terraform ansible awscli make jq
```

### Quick Install (Ubuntu/Debian)
```bash
sudo apt update && sudo apt install -y terraform ansible awscli make jq
```

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AWS VPC (10.0.0.0/16)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────┐                  ┌────────────────────┐    │
│  │   Public Subnet     │                  │   Private Subnet   │    │
│  │   10.0.1.0/24       │                  │   10.0.2.0/24      │    │
│  ├─────────────────────┤                  ├────────────────────┤    │
│  │                     │                  │                    │    │
│  │  ┌───────────────┐  │                  │  ┌──────────────┐  │    │
│  │  │   NetWorker   │  │                  │  │    Linux     │  │    │
│  │  │    Server     │◄─┼──────────────────┼──┤   Client     │  │    │
│  │  │  (Management) │  │                  │  │   (RHEL)     │  │    │
│  │  └───────────────┘  │                  │  └──────────────┘  │    │
│  │          ▲          │                  │                    │    │
│  │          │          │                  │  ┌──────────────┐  │    │
│  │          │          │                  │  │   Windows    │  |    │
│  │          └──────────┼──────────────────┼──┤   Client     │  │    │
│  │                     │                  │  │  (Server)    │  │    │
│  │  ┌───────────────┐  │                  │  └──────────────┘  │    │
│  │  │     DDVE      │  │                  │                    │    │
│  │  │  (Storage)    │  │                  └───────────────────-┘    │
│  │  │               │  │                                            │
│  │  └───────┬───────┘  │                                            │ 
│  │          │          │         ┌─────────────────┐                │
│  │          │          │         │ Internet Gateway │               │
│  └──────────┼──────────┘         └────────┬────────┘                │
│             │                              │                        │
└─────────────┼──────────────────────────────┼────────────────────────┘
              │                              │
              ▼                              ▼
         ┌─────────┐                    ┌─────────┐
         │   S3    │                    │Internet │
         │ Bucket  │                    └─────────┘
         └─────────┘
```

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/kilka/aws-networker-ddve-lab.git
cd aws-networker-ddve-lab
make quick-setup
```

### 2. Deploy
```bash
make deploy
```
Deployment takes ~20 minutes and will display login URLs when complete.

### 3. Access Your Environment
```bash
make status  # Shows all instance IPs and login URLs
```

### 4. Save Money
```bash
make stop    # Stop instances when not in use
make start   # Restart instances when needed
```

### 5. Clean Up
```bash
make destroy # Remove all AWS resources
```

## What Gets Deployed

| Component | Instance Type | Purpose |
|-----------|--------------|---------|
| NetWorker Server | m5.xlarge | Central backup management |
| DDVE | m5.xlarge | Deduplication storage with S3 backend |
| Linux Client | t3.small | RHEL backup client |
| Windows Client | t3.small | Windows Server 2022 backup client |

**Cost**: ~$0.50/hour when running, ~$360/month if left running 24/7

## Detailed Usage

### Available Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Display all available targets |
| `make setup-keys` | Generate SSH key pair |
| `make validate` | Validate Terraform and Ansible configs |
| `make plan` | Preview infrastructure changes |
| `make deploy` | Full deployment (provision + configure) |
| `make destroy` | Complete teardown |
| `make clean` | Remove local temporary files |
| `make lint` | Run code quality checks |
| `make status` | Show current infrastructure state |
| `make stop` | Stop all EC2 instances (cost saving) |
| `make start` | Start all stopped instances |
| `make cost-estimate` | Show estimated AWS costs |

### Customization

#### Region Selection
```bash
AWS_REGION=us-west-2 make deploy
```

#### Instance Sizing
Edit `terraform/terraform.tfvars`:
```hcl
instance_sizes = {
  networker_server = "t3.xlarge"
  ddve            = "m5.2xlarge"
  linux_client    = "t3.large"
  windows_client  = "t3.large"
}
```

## Security Considerations

### Default Credentials (Lab Environment)
**⚠️ WARNING**: This is a lab environment with hardcoded demo credentials. Change these immediately for any production use.

- **DDVE**:
  - Initial password: EC2 instance ID
  - Changed by Ansible to: `Changeme123!`
  - Username: `sysadmin`
  
- **NetWorker VE**:
  - Initial password: Private IP address
  - Changed by Ansible to: `Changeme123!`
  - Username: `admin`

- **Linux/Windows Clients**:
  - SSH Key: Uses generated `aws_key` file
  - Windows Admin: Password available via `make get-windows-password`

### Security Best Practices

1. **Credential Management**:
   - SSH keys auto-generated, never committed to git
   - AWS credentials via environment variables or profiles
   - Sensitive Terraform outputs marked as sensitive
   - All default passwords should be changed after deployment

2. **Network Security**:
   - All instances use public IPs for simplified lab access
   - Security groups restrict access to your IP only (set via admin_ip_cidr)
   - Inter-instance communication uses private IPs
   - All unnecessary ports blocked by default

3. **Data Protection**:
   - All EBS volumes encrypted at rest
   - S3 bucket encryption enabled
   - TLS/SSL for all API communications
   - VPC endpoints for secure S3 access

## Troubleshooting

### Common Issues

1. **AWS Quota Limits**
   ```bash
   Error: Error launching instance: InsufficientInstanceCapacity
   ```
   Solution: Try different region or instance type

2. **SSH Key Issues**
   ```bash
   Permission denied (publickey)
   ```
   Solution: Verify key permissions (600 for private key)

3. **Terraform State Lock**
   ```bash
   Error acquiring the state lock
   ```
   Solution: `terraform force-unlock <lock-id>`

### Debug Commands

```bash
# Terraform debug
TF_LOG=DEBUG terraform apply

# Ansible verbose mode
ansible-playbook -vvv playbooks/site.yml

# AWS CLI debug
aws --debug ec2 describe-instances
```


## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/enhancement`)
3. Commit changes (`git commit -am 'Add enhancement'`)
4. Push to branch (`git push origin feature/enhancement`)
5. Create Pull Request

### Code Standards

- Terraform: Use `terraform fmt` before committing
- Ansible: Follow Ansible best practices guide
- Documentation: Update README for any new features

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: [Report bugs](https://github.com/kilka/aws-networker-ddve-lab/issues)

## Acknowledgments

- Dell EMC for NetWorker documentation
- HashiCorp for Terraform
- Red Hat for Ansible
- AWS for cloud infrastructure

---

**Version**: 1.0.0  
**Last Updated**: 2025-07-28  
**Maintainer**: Josh Eagar
