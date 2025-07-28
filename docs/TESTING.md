# Testing Guide for AWS NetWorker Lab

## Overview

This guide covers professional testing practices for the AWS NetWorker Lab Terraform infrastructure.

## Testing Levels

### 1. Local Validation (Pre-commit)

Run before committing any changes:

```bash
# Full validation suite
./scripts/validate.sh

# Or use Make
make lint
```

This runs:
- Terraform format check
- Terraform validate
- TFLint (if installed)
- Checkov security scan (if installed)
- Sensitive data detection
- Cost estimation

### 2. Unit Testing

Using Terratest for infrastructure testing:

```bash
cd terraform/tests
go mod init github.com/your-org/aws-networker-lab
go mod tidy
go test -v -timeout 30m
```

Tests cover:
- VPC and subnet creation
- Security group rules
- IAM policies
- S3 bucket configuration
- Spot instance creation

### 3. Integration Testing

Test individual components:

```bash
# Test DDVE deployment only
make test-ddve

# Test NetWorker deployment only
make test-networker

# Clean up test resources
make destroy-test
```

### 4. Environment Testing

Deploy to different environments:

```bash
# Development environment
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Staging environment
terraform plan -var-file=environments/staging.tfvars
terraform apply -var-file=environments/staging.tfvars

# Production environment
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

## CI/CD Pipeline

GitHub Actions workflow automatically runs:

1. **On Push/PR**:
   - Terraform format check
   - Terraform validate
   - TFLint
   - Checkov security scan
   - Infracost analysis

2. **On PR Only**:
   - Terraform plan
   - Cost estimation comment
   - Security findings report

## Testing Best Practices

### 1. Pre-deployment Checklist

- [ ] Run local validation: `make lint`
- [ ] Review cost estimate: `make cost-estimate`
- [ ] Check for hardcoded values
- [ ] Verify variable defaults
- [ ] Test with minimal permissions
- [ ] Review security group rules
- [ ] Validate IAM policies

### 2. Deployment Testing

```bash
# 1. Start with dry run
terraform plan -out=tfplan

# 2. Review the plan
terraform show tfplan

# 3. Apply with specific targets for testing
terraform apply -target=aws_vpc.main -target=aws_subnet.public

# 4. Full deployment
terraform apply tfplan
```

### 3. Post-deployment Validation

```bash
# Check instance connectivity
aws ec2 describe-instances --filters "Name=tag:Project,Values=aws-networker-lab"

# Verify S3 bucket
aws s3 ls s3://$(terraform output -raw s3_bucket_name)

# Test SSH access
ssh -i aws_key ec2-user@$(terraform output -raw networker_server_public_ip)

# Check DDVE web interface
curl -k https://$(terraform output -raw ddve_public_ip)
```

### 4. Disaster Recovery Testing

```bash
# 1. Take snapshot of current state
terraform state pull > state-backup.json

# 2. Test destroy and recreate
make destroy
make deploy

# 3. Verify data persistence (S3 bucket retained)
aws s3 ls s3://$(terraform output -raw s3_bucket_name)
```

## Security Testing

### Static Analysis

```bash
# Checkov scan
checkov -d terraform/ --framework terraform

# tfsec (alternative)
tfsec terraform/

# Terrascan (alternative)
terrascan scan -i terraform -t aws
```

### Runtime Testing

```bash
# AWS Config Rules validation
aws configservice describe-compliance-by-config-rule

# AWS Security Hub findings
aws securityhub get-findings --filters '{"ProductArn": [{"Value": "arn:aws:securityhub:*:*:product/aws/securityhub"}]}'
```

## Cost Testing

### Estimate costs before deployment

```bash
# Using Infracost
infracost breakdown --path terraform/

# Compare environments
infracost diff --path terraform/ --compare-to=environments/prod.tfvars
```

### Monitor actual costs

```bash
# AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter file://cost-filter.json
```

## Troubleshooting Tests

### Common Issues

1. **State Lock Error**
```bash
terraform force-unlock <lock-id>
```

2. **Resource Already Exists**
```bash
terraform import aws_instance.ddve i-1234567890abcdef0
```

3. **Spot Instance Unavailable**
```bash
# Switch to on-demand
terraform apply -var="use_spot_instances=false"
```

### Debug Mode

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform apply

# AWS CLI debug
export AWS_DEBUG=1
aws ec2 describe-instances
```

## Compliance Testing

For regulated environments:

```bash
# CIS Benchmark scan
prowler -g cis_level2_aws

# PCI-DSS compliance
prowler -g pci

# HIPAA compliance
prowler -g hipaa
```

## Performance Testing

```bash
# Time the deployment
time terraform apply -auto-approve

# Measure instance startup time
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name StatusCheckFailed \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --statistics Average \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300
```

## Test Reports

Generate test reports for documentation:

```bash
# Terraform plan in JSON
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# Generate HTML report
python3 scripts/generate_report.py plan.json > report.html

# Security report
checkov -d terraform/ -o json > security-report.json
```

## Continuous Improvement

1. **Monitor test failures** in CI/CD
2. **Update test cases** for new features
3. **Review security findings** weekly
4. **Optimize costs** based on usage patterns
5. **Document lessons learned** from failures