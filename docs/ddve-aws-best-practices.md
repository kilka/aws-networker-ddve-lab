# DDVE AWS Deployment Best Practices

## Overview

This document outlines the best practices implemented in our Terraform configuration for deploying Dell EMC Data Domain Virtual Edition (DDVE) on AWS.

## Infrastructure Components

### 1. S3 Bucket Configuration ✅

**Implemented:**
- ✅ Server-side encryption (AES-256)
- ✅ Bucket versioning (optional - disabled by default for cost)
- ✅ Public access blocked
- ✅ Lifecycle policies (transition to IA after 30 days)
- ✅ Access logging (optional)
- ✅ Unique bucket naming with account ID

**Best Practices:**
- Enable versioning for production (`enable_s3_versioning = true`)
- Enable access logging for compliance (`enable_s3_logging = true`)
- Consider cross-region replication for DR

### 2. IAM Roles and Policies ✅

**Implemented:**
- ✅ Least privilege S3 access
- ✅ Instance profile for EC2-S3 communication
- ✅ Support for versioned objects
- ✅ CloudWatch metrics permissions

**Permissions Granted:**
```
S3 Bucket Operations:
- ListBucket, GetBucketLocation, GetBucketVersioning
- ListBucketVersions, GetBucketTagging, GetBucketLogging

S3 Object Operations:
- GetObject, PutObject, DeleteObject
- GetObjectVersion, DeleteObjectVersion
- GetObjectTagging, PutObjectTagging

CloudWatch:
- PutMetricData (DDVE namespace only)
```

### 3. Security Groups ✅

**DDVE Security Group includes:**
- ✅ SSH (22) - Admin access only
- ✅ HTTPS (443) - System Manager UI
- ✅ DD Boost (2049) - From NetWorker only
- ✅ NFS (2049) - VPC CIDR
- ✅ Replication (2051) - VPC CIDR
- ✅ RPC Portmapper (111) - VPC CIDR
- ✅ DD Boost/FC (3009) - Optional
- ✅ Telemetry (9011) - Admin access

**Security Considerations:**
- Restrict `admin_ip_cidr` to specific IPs
- Use separate security groups per service
- No unnecessary port exposure

### 4. EC2 Instance Configuration ✅

**Implemented:**
- ✅ Enhanced networking (ENA) enabled
- ✅ IMDSv2 enforced for security
- ✅ Encrypted EBS volumes
- ✅ Proper disk layout (Root + NVRAM + Metadata)
- ✅ IAM instance profile attached

**Instance Optimization:**
- t3.xlarge for cost-optimized lab
- m5.xlarge+ for production workloads
- Consider reserved instances for long-term use

### 5. VPC and Networking ✅

**Implemented:**
- ✅ VPC with DNS enabled
- ✅ Public/Private subnet architecture
- ✅ NAT Gateway for private instances
- ✅ VPC Flow Logs enabled
- ✅ S3 Gateway Endpoint (free, improves performance)
- ✅ Optional VPC Interface Endpoints

**Network Optimization:**
- S3 Gateway Endpoint reduces data transfer costs
- VPC endpoints improve security (no internet routing)
- Consider Direct Connect for hybrid scenarios

### 6. Monitoring and Alerting 🔧

**Available (Optional):**
- ✅ CloudWatch alarms for CPU, credits, storage
- ✅ SNS topic for email alerts
- ✅ CloudWatch dashboard
- ✅ VPC Flow Log analysis

**Enable for Production:**
```hcl
enable_monitoring_alerts    = true
enable_monitoring_dashboard = true
alert_email                = "ops@company.com"
```

## Disk Configuration for S3-Backed DDVE

### Required Disks:
1. **Root Disk**: 250GB gp3 - OS and software
2. **NVRAM Disk**: 10GB gp3 - Write cache (critical for performance)
3. **Metadata Disk**: 100GB gp3 - Deduplication metadata

### Why This Configuration:
- No local data disks needed (S3 is primary storage)
- NVRAM is essential for write performance
- Metadata disk sized for cloud-tier workloads
- All disks use gp3 for consistent SSD performance

## Cost Optimization Strategies

### 1. Instance Selection
- **Lab/Test**: t3.xlarge (burst capability, lower cost)
- **Production**: m5.xlarge+ (consistent performance)
- **Cost Savings**: ~13% using t3 vs m5

### 2. Storage Optimization
- Minimal EBS volumes (360GB total)
- S3 lifecycle policies (IA after 30 days)
- No unnecessary data disks
- Consider S3 Intelligent-Tiering

### 3. Network Optimization
- S3 Gateway Endpoint (free, reduces NAT costs)
- Single AZ deployment for non-critical workloads
- Stop instances when not in use

## Security Best Practices

### 1. Access Control
- Restrict admin_ip_cidr to known IPs
- Use IAM roles, not access keys
- Enable MFA for AWS console access
- Implement least privilege

### 2. Encryption
- All EBS volumes encrypted
- S3 bucket encryption enabled
- Consider KMS for key management
- Enable in-transit encryption

### 3. Compliance
- Enable S3 versioning for data recovery
- Enable access logging for audit trails
- Implement backup policies
- Regular security assessments

## Operational Recommendations

### 1. Deployment
- Test in non-production first
- Use infrastructure as code (Terraform)
- Implement proper tagging strategy
- Document all customizations

### 2. Maintenance
- Regular AMI updates
- Monitor CPU credits (t3 instances)
- Review CloudWatch metrics
- Implement backup testing

### 3. Disaster Recovery
- Multi-region S3 replication
- EBS snapshot schedules
- Documented recovery procedures
- Regular DR testing

## Common Issues and Solutions

### Issue: High CPU Credit Consumption
**Solution**: Monitor credits, consider m5 instance for consistent workloads

### Issue: Slow S3 Performance
**Solution**: Ensure S3 Gateway Endpoint is configured, check network path

### Issue: Storage Growth
**Solution**: Monitor deduplication ratios, implement retention policies

## Production Checklist

Before going to production:
- [ ] Change admin_ip_cidr from 0.0.0.0/0
- [ ] Enable S3 versioning
- [ ] Enable monitoring and alerts
- [ ] Configure backup policies
- [ ] Test disaster recovery
- [ ] Review security groups
- [ ] Enable CloudTrail
- [ ] Implement tagging strategy
- [ ] Document operational procedures
- [ ] Train operations team