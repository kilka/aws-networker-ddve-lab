#!/bin/bash

# AWS NetWorker Lab - DDVE Only Deployment Script
# This script deploys only the DDVE component for testing

set -euo pipefail

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
ANSIBLE_DIR="$PROJECT_DIR/ansible"

echo -e "${GREEN}🚀 AWS NetWorker Lab - DDVE Only Deployment${NC}"
echo "=================================="

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo -e "${RED}❌ AWS CLI not configured. Run 'aws configure' first.${NC}"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform not installed.${NC}"
        exit 1
    fi
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}❌ Ansible not installed.${NC}"
        exit 1
    fi
    
    # Check if SSH key exists
    if [ ! -f "$PROJECT_DIR/aws_key.pub" ]; then
        echo -e "${YELLOW}⚠️ SSH key not found. Generating...${NC}"
        ssh-keygen -t rsa -b 4096 -f "$PROJECT_DIR/aws_key" -N "" -C "aws-networker-lab-key"
        chmod 600 "$PROJECT_DIR/aws_key"
        chmod 644 "$PROJECT_DIR/aws_key.pub"
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        echo -e "${YELLOW}⚠️ terraform.tfvars not found. Creating basic config...${NC}"
        CURRENT_IP=$(curl -s https://api.ipify.org || echo "0.0.0.0")
        cat > "$TERRAFORM_DIR/terraform.tfvars" << EOF
# AWS NetWorker Lab - DDVE Only Configuration
aws_region = "us-east-1"
project_name = "aws-networker-lab"
environment = "test"
key_name = "aws_key"
public_key_path = "../aws_key.pub"
admin_ip_cidr = "${CURRENT_IP}/32"

# Use marketplace AMIs in us-east-1
use_marketplace_amis = true

# Instance settings
use_spot_instances = false

# Enable S3 features
enable_s3_versioning = false
enable_s3_logging = false
EOF
        echo -e "${GREEN}✅ Created terraform.tfvars with your IP: ${CURRENT_IP}${NC}"
    fi
    
    echo -e "${GREEN}✅ Prerequisites check complete${NC}"
}

# Function to deploy DDVE infrastructure
deploy_ddve_infrastructure() {
    echo -e "${BLUE}📦 Deploying DDVE infrastructure...${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init -upgrade
    
    # Deploy only DDVE and required components
    terraform apply -auto-approve \
        -target=aws_vpc.main \
        -target=aws_subnet.public \
        -target=aws_subnet.private \
        -target=aws_internet_gateway.main \
        -target=aws_eip.nat \
        -target=aws_nat_gateway.main \
        -target=aws_route_table.public \
        -target=aws_route_table.private \
        -target=aws_route_table_association.public \
        -target=aws_route_table_association.private \
        -target=aws_route53_zone.private \
        -target=aws_security_group.ddve \
        -target=aws_iam_role.ddve \
        -target=aws_iam_instance_profile.ddve \
        -target=aws_iam_role_policy.ddve_s3 \
        -target=aws_s3_bucket.ddve_cloud_tier \
        -target=aws_s3_bucket_public_access_block.ddve_cloud_tier \
        -target=aws_s3_bucket_server_side_encryption_configuration.ddve_cloud_tier \
        -target=aws_s3_bucket_versioning.ddve_cloud_tier \
        -target=aws_s3_bucket_lifecycle_configuration.ddve_cloud_tier \
        -target=aws_instance.ddve \
        -target=aws_instance.ddve_spot \
        -target=aws_eip.ddve \
        -target=aws_key_pair.main \
        -target=aws_route53_record.ddve_a \
        -target=aws_route53_record.ddve_cname
    
    echo -e "${GREEN}✅ DDVE infrastructure deployed successfully${NC}"
}

# Function to configure DDVE using Ansible
configure_ddve() {
    echo -e "${BLUE}⚙️ Configuring DDVE using Ansible...${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Get DDVE public IP and instance ID
    DDVE_IP=$(terraform output -raw ddve_public_ip 2>/dev/null || echo "")
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
    
    # Get instance ID from Terraform state
    DDVE_INSTANCE_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_instance" and .name == "ddve") | .values.id' 2>/dev/null || \
                       terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_instance" and .name == "ddve_spot") | .values.id' 2>/dev/null || echo "")
    
    if [ -z "$DDVE_IP" ]; then
        echo -e "${RED}❌ Could not retrieve DDVE IP address${NC}"
        exit 1
    fi
    
    if [ -z "$S3_BUCKET" ]; then
        echo -e "${RED}❌ Could not retrieve S3 bucket name${NC}"
        exit 1
    fi
    
    if [ -z "$DDVE_INSTANCE_ID" ]; then
        echo -e "${RED}❌ Could not retrieve DDVE instance ID${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}DDVE IP: ${DDVE_IP}${NC}"
    echo -e "${YELLOW}DDVE Instance ID: ${DDVE_INSTANCE_ID}${NC}"
    echo -e "${YELLOW}S3 Bucket: ${S3_BUCKET}${NC}"
    
    # Create dynamic inventory for DDVE only
    cat > "$ANSIBLE_DIR/inventory/ddve_only.yml" << EOF
---
all:
  children:
    ddve_systems:
      hosts:
        networker-lab-ddve-01.networker.lab:
          ansible_host: ${DDVE_IP}
          ansible_user: admin
          ansible_connection: local
          instance_id: ${DDVE_INSTANCE_ID}
      vars:
        ddve_username: "sysadmin"
        ddve_password: "Changeme123!"
        ddve_passphrase: "Changeme123!"
        
    # Empty groups for playbook compatibility
    networker_servers:
      hosts: {}
    linux_clients:
      hosts: {}
    windows_clients:
      hosts: {}
      
  vars:
    s3_bucket: "${S3_BUCKET}"
    ddboost_user: "networker"
    ddboost_password: "Changeme123!"
    storage_unit_name: "NetWorker_SU"
    aws_region: "us-east-1"
    internal_domain_name: "networker.lab"
EOF
    
    cd "$ANSIBLE_DIR"
    
    # Wait for DDVE to be ready
    echo -e "${YELLOW}⏳ Waiting for DDVE to be accessible...${NC}"
    timeout=300
    counter=0
    while ! curl -k -s --connect-timeout 5 "https://${DDVE_IP}" > /dev/null; do
        sleep 10
        counter=$((counter + 10))
        if [ $counter -ge $timeout ]; then
            echo -e "${RED}❌ Timeout waiting for DDVE to be accessible${NC}"
            exit 1
        fi
        echo -e "${YELLOW}⏳ Still waiting... (${counter}/${timeout}s)${NC}"
    done
    
    echo -e "${GREEN}✅ DDVE is accessible${NC}"
    
    # Run Ansible playbook for DDVE only
    ansible-playbook -i inventory/ddve_only.yml playbooks/site.yml --tags ddve -v
    
    echo -e "${GREEN}✅ DDVE configuration completed${NC}"
}

# Function to display results
display_results() {
    echo -e "${GREEN}🎉 DDVE Deployment Complete!${NC}"
    echo "=============================="
    
    cd "$TERRAFORM_DIR"
    DDVE_IP=$(terraform output -raw ddve_public_ip 2>/dev/null || echo "N/A")
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "N/A")
    DDVE_INSTANCE_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_instance" and .name == "ddve") | .values.id' 2>/dev/null || \
                       terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_instance" and .name == "ddve_spot") | .values.id' 2>/dev/null || echo "N/A")
    
    echo -e "${YELLOW}DDVE Access Information:${NC}"
    echo "  • Web Interface: https://${DDVE_IP}"
    echo "  • Hostname (FQDN): networker-lab-ddve-01.networker.lab"
    echo "  • Hostname (Short): ddve.networker.lab"
    echo "  • Private IP: $(cd $(TERRAFORM_DIR) && terraform output -raw ddve_private_ip 2>/dev/null || echo "N/A")"
    echo "  • Instance ID: ${DDVE_INSTANCE_ID}"
    echo "  • Initial Credentials: sysadmin / ${DDVE_INSTANCE_ID}"
    echo "  • Updated Credentials: sysadmin / Changeme123!"
    echo "  • S3 Backend Bucket: ${S3_BUCKET}"
    echo ""
    echo -e "${YELLOW}Internal DNS Resolution:${NC}"
    echo "  • Domain: networker.lab"
    echo "  • DDVE FQDN: networker-lab-ddve-01.networker.lab"
    echo "  • DDVE Short: ddve.networker.lab"
    echo "  • Future NetWorker: networker-lab-server-01.networker.lab"
    echo ""
    echo -e "${YELLOW}DD Boost Information:${NC}"
    echo "  • DD Boost User: networker"
    echo "  • DD Boost Password: Changeme123!"
    echo "  • Storage Unit: NetWorker_SU"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Test DDVE web interface access"
    echo "  2. Verify S3 bucket integration"
    echo "  3. Test internal DNS resolution (when NetWorker is deployed)"
    echo "  4. Test DD Boost connectivity"
    echo ""
    echo -e "${YELLOW}Clean up when done:${NC}"
    echo "  make destroy"
}

# Main execution
main() {
    check_prerequisites
    deploy_ddve_infrastructure
    configure_ddve
    display_results
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi