#!/usr/bin/env bash
# Automated setup script for AWS NetWorker Lab

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PATH="${PROJECT_ROOT}/aws_key"
TFVARS_PATH="${PROJECT_ROOT}/terraform/terraform.tfvars"

echo -e "${BLUE}AWS NetWorker Lab - Automated Setup${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing=()
    
    # Check required tools
    command -v terraform >/dev/null 2>&1 || missing+=("terraform")
    command -v aws >/dev/null 2>&1 || missing+=("aws-cli")
    command -v ssh-keygen >/dev/null 2>&1 || missing+=("ssh-keygen")
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Missing required tools: ${missing[*]}${NC}"
        echo "Please install missing tools before proceeding."
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites installed${NC}\n"
}

# Function to setup SSH keys
setup_ssh_keys() {
    echo -e "${YELLOW}Setting up SSH keys...${NC}"
    
    if [ -f "${KEY_PATH}" ]; then
        echo -e "${GREEN}✓ SSH key already exists at ${KEY_PATH}${NC}\n"
    else
        ssh-keygen -t rsa -b 4096 -f "${KEY_PATH}" -N "" -C "aws-networker-lab-key" >/dev/null 2>&1
        chmod 600 "${KEY_PATH}"
        chmod 644 "${KEY_PATH}.pub"
        echo -e "${GREEN}✓ SSH key pair generated successfully${NC}\n"
    fi
}

# Function to check AWS credentials
check_aws_credentials() {
    echo -e "${YELLOW}Checking AWS credentials...${NC}"
    
    if aws sts get-caller-identity >/dev/null 2>&1; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --query Arn --output text)
        echo -e "${GREEN}✓ AWS credentials configured${NC}"
        echo -e "  Account ID: ${account_id}"
        echo -e "  User/Role: ${user_arn}\n"
    else
        echo -e "${RED}✗ AWS credentials not configured${NC}"
        echo -e "Please run: ${YELLOW}aws configure${NC}"
        exit 1
    fi
}

# Function to detect public IP
detect_public_ip() {
    echo -e "${YELLOW}Detecting your public IP address...${NC}"
    
    local ip=""
    
    # Try multiple services in case one is down
    for service in "https://api.ipify.org" "https://checkip.amazonaws.com" "https://ipecho.net/plain"; do
        ip=$(curl -s --max-time 5 "$service" 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
        if [ -n "$ip" ]; then
            break
        fi
    done
    
    if [ -z "$ip" ]; then
        echo -e "${RED}✗ Could not detect public IP address${NC}"
        echo -e "Please enter your IP manually or use 0.0.0.0/0 (less secure)"
        read -p "Enter IP address (or press Enter for 0.0.0.0/0): " ip
        ip=${ip:-"0.0.0.0"}
    fi
    
    echo -e "${GREEN}✓ Public IP detected: ${ip}${NC}\n"
    echo "$ip"
}

# Function to create terraform.tfvars
create_tfvars() {
    echo -e "${YELLOW}Creating terraform.tfvars...${NC}"
    
    if [ -f "${TFVARS_PATH}" ]; then
        echo -e "${YELLOW}terraform.tfvars already exists${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}✓ Using existing terraform.tfvars${NC}\n"
            return
        fi
    fi
    
    local ip=$(detect_public_ip)
    
    cat > "${TFVARS_PATH}" <<EOF
# AWS NetWorker Lab Configuration
# Generated on $(date)

# Your IP address for secure access
admin_ip_cidr = "${ip}/32"

# AWS Region
aws_region = "us-east-1"

# Project identification
project_name = "aws-networker-lab"
environment  = "dev"

# Cost optimization - using spot instances
use_spot_instances = true
spot_price = "0.6"

# Marketplace AMIs (DDVE and NetWorker)
use_marketplace_amis = true
ddve_ami_mapping = {
  "us-east-1" = "ami-09e2f4b415eacc1b9"
}
networker_ami_mapping = {
  "us-east-1" = "ami-08560ec5891de83bd"
}

# Instance types (cost-optimized)
instance_types = {
  networker_server = "t3.medium"
  ddve            = "t3.xlarge"
  linux_client    = "t3.small"
  windows_client  = "t3.small"
}

# Storage sizes (minimal for lab)
storage_sizes = {
  networker_server = 50
  ddve            = 250
  linux_client    = 30
  windows_client  = 30
}

# Tags
common_tags = {
  ManagedBy   = "Terraform"
  Environment = "dev"
  Purpose     = "NetWorker Lab"
  Owner       = "$(whoami)"
}
EOF
    
    echo -e "${GREEN}✓ terraform.tfvars created successfully${NC}\n"
}

# Function to check marketplace subscriptions
check_marketplace_subscriptions() {
    echo -e "${YELLOW}Checking AWS Marketplace subscriptions...${NC}"
    
    local ddve_product_code="3xwqnn8ck5bs14h9ceivt7gv3"
    local networker_product_code="94q6vn03s9p5tnvxnoj7bnie9"
    
    echo -e "\n${YELLOW}IMPORTANT: You must subscribe to these AWS Marketplace products:${NC}"
    echo -e "1. Dell EMC Data Domain Virtual Edition (DDVE):"
    echo -e "   ${BLUE}https://aws.amazon.com/marketplace/pp/prodview-qcmtvuqexqmzw${NC}"
    echo -e "2. Dell EMC NetWorker Virtual Edition:"
    echo -e "   ${BLUE}https://aws.amazon.com/marketplace/pp/prodview-4gm7ncqvfwixw${NC}"
    echo -e "\n${YELLOW}Press Enter after subscribing to continue...${NC}"
    read -r
}

# Function to initialize Terraform
init_terraform() {
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    
    cd "${PROJECT_ROOT}/terraform"
    
    if terraform init >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Terraform initialized successfully${NC}\n"
    else
        echo -e "${RED}✗ Terraform initialization failed${NC}"
        exit 1
    fi
}

# Function to show next steps
show_next_steps() {
    echo -e "${GREEN}Setup completed successfully!${NC}\n"
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "1. Deploy the full lab:"
    echo -e "   ${YELLOW}make deploy${NC}\n"
    echo -e "2. Or test individual components:"
    echo -e "   ${YELLOW}make test-ddve${NC}     # Test DDVE only"
    echo -e "   ${YELLOW}make test-networker${NC} # Test NetWorker only\n"
    echo -e "3. To use different settings, edit:"
    echo -e "   ${YELLOW}terraform/terraform.tfvars${NC}\n"
    echo -e "4. To save costs:"
    echo -e "   - Spot instances are enabled by default"
    echo -e "   - Use ${YELLOW}make stop${NC} to stop instances when not in use"
    echo -e "   - Use ${YELLOW}make start${NC} to restart them\n"
}

# Main execution
main() {
    check_prerequisites
    check_aws_credentials
    setup_ssh_keys
    create_tfvars
    check_marketplace_subscriptions
    init_terraform
    show_next_steps
}

# Run main function
main "$@"