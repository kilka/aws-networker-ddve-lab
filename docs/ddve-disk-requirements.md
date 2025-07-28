# DDVE Disk Requirements for S3-Backed Deployments

## Overview

When deploying Dell EMC Data Domain Virtual Edition (DDVE) with S3 as the primary storage tier, specific disk configurations are required for proper operation.

## Required Disks for S3-Backed DDVE

### 1. Root/OS Disk
- **Purpose**: Operating system and DDVE software installation
- **Size**: 250 GB
- **Type**: gp3 EBS volume
- **Device**: `/dev/sda1` or `/dev/xvda`

### 2. NVRAM Disk
- **Purpose**: Non-volatile RAM for write caching and performance optimization
- **Size**: 10 GB
- **Type**: gp3 EBS volume
- **Device**: `/dev/sdb` or `/dev/xvdb`
- **Critical**: Required for all DDVE deployments

### 3. Metadata Disk
- **Purpose**: Stores deduplication metadata and indexes
- **Size**: 100 GB (minimum for S3-backed deployments)
- **Type**: gp3 EBS volume
- **Device**: `/dev/sdc` or `/dev/xvdc`
- **Critical**: Required for deduplication operations

### 4. S3 Bucket (Cloud Tier)
- **Purpose**: Primary data storage (active tier)
- **Size**: Unlimited (pay per use)
- **Configuration**: Configured through DDVE web interface after deployment

## What's NOT Needed

When using S3 as the primary storage tier, you do NOT need:
- Local data disks (typically 1-4 TB in traditional deployments)
- The data is stored entirely in S3

## Terraform Configuration

The Terraform configuration includes:
```hcl
# Root disk
root_block_device {
  volume_type = "gp3"
  volume_size = 250  # GB
  encrypted   = true
}

# NVRAM disk
ebs_block_device {
  device_name = "/dev/sdb"
  volume_type = "gp3"
  volume_size = 10   # GB
  encrypted   = true
}

# Metadata disk
ebs_block_device {
  device_name = "/dev/sdc"
  volume_type = "gp3"
  volume_size = 100  # GB
  encrypted   = true
}
```

## Initial Setup Process

1. **Instance Launch**: DDVE instance starts with all three disks attached
2. **Web UI Access**: Connect to `https://<ddve-public-ip>`
3. **Initial Configuration**: 
   - DDVE automatically detects and configures all disks
   - Configure S3 bucket as cloud tier through the web interface
4. **Activation**: Apply license (60-day evaluation included)

## Performance Considerations

- **NVRAM**: Critical for write performance - use SSD storage
- **Network**: Enhanced networking recommended for optimal S3 throughput
- **Instance Type**: t3.xlarge minimum for lab, m5.xlarge+ for production

## Cost Optimization

By using S3 as primary storage:
- Eliminates need for large local data disks (saves 500GB-4TB EBS)
- Pay only for actual data stored in S3
- Data deduplication reduces S3 storage costs
- Total EBS requirement: only 360GB (250GB root + 10GB NVRAM + 100GB metadata)