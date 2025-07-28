# Troubleshooting Guide

## Common Issues and Solutions

### Prerequisites Issues

#### Issue: Command not found errors
```bash
make: terraform: command not found
```

**Solution**: Install missing prerequisites
```bash
# macOS
brew install terraform ansible awscli jq

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install terraform ansible awscli jq

# RHEL/CentOS
sudo yum install terraform ansible awscli jq
```

### AWS Configuration Issues

#### Issue: AWS credentials not configured
```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
```

**Solution**: Configure AWS credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (e.g., us-east-1)
# Enter default output format (json)
```

#### Issue: Insufficient AWS permissions
```
Error: error creating EC2 Instance: UnauthorizedOperation
```

**Solution**: Ensure your IAM user has AdministratorAccess or create a policy with required permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "s3:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### SSH Key Issues

#### Issue: SSH key permissions error
```
Permissions 0644 for 'aws_key' are too open.
```

**Solution**: Fix key permissions
```bash
chmod 600 aws_key
chmod 644 aws_key.pub
```

#### Issue: SSH connection refused
```
ssh: connect to host x.x.x.x port 22: Connection refused
```

**Solution**: 
1. Wait for instance to fully initialize (2-3 minutes after creation)
2. Check security group allows SSH from your IP
3. Verify instance is in running state:
```bash
aws ec2 describe-instances --instance-ids <instance-id>
```

### Terraform Issues

#### Issue: Terraform state lock
```
Error: Error acquiring the state lock
```

**Solution**: Force unlock (use with caution)
```bash
cd terraform
terraform force-unlock <lock-id>
```

#### Issue: Resource already exists
```
Error: Error creating VPC: VpcLimitExceeded
```

**Solution**: 
1. Check AWS service limits
2. Use a different region
3. Clean up existing resources:
```bash
make destroy
```

### Ansible Issues

#### Issue: Host unreachable
```
fatal: [linux_client]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

**Solution**:
1. Verify ProxyCommand in inventory for private instances
2. Ensure bastion host (NetWorker Server) is accessible
3. Check security groups allow connection

#### Issue: WinRM connection failed
```
fatal: [windows_client]: UNREACHABLE! => {"msg": "ssl: auth method ssl requires a password"}
```

**Solution**: Retrieve Windows password
```bash
aws ec2 get-password-data \
  --instance-id <instance-id> \
  --priv-launch-key aws_key
```

### Instance Issues

#### Issue: Instance capacity error
```
Error: Error launching instance: InsufficientInstanceCapacity
```

**Solution**:
1. Try a different availability zone
2. Use a different instance type
3. Try a different region

#### Issue: High costs
**Solution**: Cost optimization strategies
```bash
# Stop instances when not in use
make stop

# Start instances when needed
make start

# Destroy all resources when done
make destroy
```

### Validation Issues

#### Issue: Deployment validation fails
```bash
./scripts/validate_deployment.sh
```

Common validation failures:
1. **Missing prerequisites**: Install required tools
2. **No SSH keys**: Run `make setup-keys`
3. **No infrastructure**: Run `make deploy`
4. **Connection timeouts**: Check security groups and instance status

### Application-Specific Issues

#### NetWorker Server Issues
- **Service not starting**: Check logs in `/opt/networker/server/logs/`
- **Console not accessible**: Verify port 9001 is open in security group
- **API errors**: Default credentials may need to be changed

#### DDVE Issues
- **Storage configuration fails**: Ensure IAM role has S3 permissions
- **Web interface not accessible**: Check port 443 in security group
- **DD Boost connection fails**: Verify network connectivity between NetWorker and DDVE

### Cleanup Issues

#### Issue: Resources not deleted
```
Error: Error deleting VPC: DependencyViolation
```

**Solution**: Manual cleanup
```bash
# List all resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=aws-networker-lab"
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=aws-networker-lab"

# Delete resources manually if needed
aws ec2 terminate-instances --instance-ids <instance-ids>
aws ec2 delete-vpc --vpc-id <vpc-id>
```

## Debug Mode

### Enable Terraform debugging
```bash
export TF_LOG=DEBUG
make deploy
```

### Enable Ansible debugging
```bash
ansible-playbook -vvv -i inventory/dynamic_inventory.json playbooks/site.yml
```

### Check application logs
```bash
# NetWorker Server logs
ssh -i aws_key ec2-user@<networker-ip>
sudo tail -f /opt/networker/server/logs/daemon.log

# DDVE logs
ssh -i aws_key ec2-user@<ddve-ip>
sudo tail -f /opt/ddve/logs/system.log
```

## Getting Help

1. Check the documentation in `/docs` directory
2. Review the README.md for configuration options
3. Run validation script: `./scripts/validate_deployment.sh`
4. Check AWS CloudWatch logs for instance issues
5. Review Terraform state: `terraform show`

## Support Resources

- AWS Documentation: https://docs.aws.amazon.com/
- Terraform Documentation: https://www.terraform.io/docs/
- Ansible Documentation: https://docs.ansible.com/
- Dell EMC NetWorker Documentation: https://www.dell.com/support/