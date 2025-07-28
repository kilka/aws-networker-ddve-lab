# DDVE Disk Configuration Summary

## Final Configuration for S3-Backed DDVE

### Disk Layout
1. **Root Disk** (`/dev/sda`)
   - Size: 250 GB
   - Type: gp3
   - Purpose: Operating System and DDVE software

2. **NVRAM Disk** (`/dev/sdb`)
   - Size: 10 GB
   - Type: gp3
   - Purpose: Write cache for performance

3. **Metadata Disk** (`/dev/sdc`)
   - Size: 100 GB
   - Type: gp3
   - Purpose: Deduplication metadata and indexes

4. **Data Storage**
   - Location: S3 Bucket
   - Size: Unlimited (pay per use)
   - Purpose: Primary data storage (active tier)

### Total EBS Storage
- **Per DDVE**: 360 GB (250 + 10 + 100)
- **Storage Type**: All gp3 for consistent SSD performance
- **All volumes**: Encrypted at rest

### Cost Impact
- Additional 100GB for metadata disk (~$8/month)
- Still 61% less storage than original configuration
- Significant savings vs traditional DDVE with local data disks

This configuration meets Dell EMC requirements for DDVE with cloud storage while optimizing for cost.