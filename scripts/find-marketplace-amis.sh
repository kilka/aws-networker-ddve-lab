#!/bin/bash
# Script to find Dell EMC marketplace AMIs

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Dell EMC Marketplace AMI Finder${NC}"
echo "================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI not configured${NC}"
    exit 1
fi

# Get current region
REGION=${AWS_REGION:-$(aws configure get region)}
echo -e "Current region: ${YELLOW}$REGION${NC}"

# Dell EMC AWS Account ID
DELL_EMC_ACCOUNT="679593333241"

echo -e "\n${YELLOW}Searching for DDVE AMIs...${NC}"

# Find DDVE AMIs
DDVE_AMIS=$(aws ec2 describe-images \
    --owners $DELL_EMC_ACCOUNT \
    --filters "Name=name,Values=*DDVE*" "Name=state,Values=available" \
    --query 'Images[*].[ImageId,Name,Description,CreationDate]' \
    --output text 2>/dev/null | sort -k4 -r)

if [ -z "$DDVE_AMIS" ]; then
    echo -e "${RED}No DDVE AMIs found in region $REGION${NC}"
    echo -e "${YELLOW}Have you subscribed to the DDVE marketplace offering?${NC}"
    echo -e "Visit: https://aws.amazon.com/marketplace/pp/prodview-q7oc4shdnpc4w"
else
    echo -e "${GREEN}Found DDVE AMIs:${NC}"
    echo "$DDVE_AMIS" | while IFS=$'\t' read -r ami_id name desc date; do
        echo -e "  AMI ID: ${GREEN}$ami_id${NC}"
        echo -e "  Name: $name"
        echo -e "  Date: $date"
        echo ""
    done
    
    # Get the most recent AMI
    LATEST_DDVE=$(echo "$DDVE_AMIS" | head -n1 | cut -f1)
    echo -e "${GREEN}Latest DDVE AMI: $LATEST_DDVE${NC}"
fi

echo -e "\n${YELLOW}Searching for NetWorker AMIs...${NC}"

# Search for NetWorker AMIs (might not exist in marketplace)
NW_AMIS=$(aws ec2 describe-images \
    --owners $DELL_EMC_ACCOUNT \
    --filters "Name=name,Values=*NetWorker*,*networker*" "Name=state,Values=available" \
    --query 'Images[*].[ImageId,Name,Description,CreationDate]' \
    --output text 2>/dev/null | sort -k4 -r)

if [ -z "$NW_AMIS" ]; then
    echo -e "${YELLOW}No NetWorker AMIs found in marketplace${NC}"
    echo -e "You may need to use a custom AMI or install NetWorker on a base OS"
else
    echo -e "${GREEN}Found NetWorker AMIs:${NC}"
    echo "$NW_AMIS" | while IFS=$'\t' read -r ami_id name desc date; do
        echo -e "  AMI ID: ${GREEN}$ami_id${NC}"
        echo -e "  Name: $name"
        echo -e "  Date: $date"
        echo ""
    done
fi

# Generate Terraform variables
echo -e "\n${YELLOW}Terraform Configuration:${NC}"
echo -e "Add this to your terraform.tfvars file:"
echo ""
echo "# Enable marketplace AMIs"
echo "use_marketplace_amis = true"
echo ""
echo "# DDVE AMI for region $REGION"
if [ ! -z "$LATEST_DDVE" ]; then
    echo "ddve_ami_mapping = {"
    echo "  \"$REGION\" = \"$LATEST_DDVE\""
    echo "}"
else
    echo "# No DDVE AMI found - subscribe to marketplace first"
fi

# Check other regions
echo -e "\n${YELLOW}Checking other common regions...${NC}"
for region in us-east-1 us-west-2 eu-west-1 ap-southeast-1; do
    if [ "$region" != "$REGION" ]; then
        ami=$(aws ec2 describe-images \
            --owners $DELL_EMC_ACCOUNT \
            --filters "Name=name,Values=*DDVE*" "Name=state,Values=available" \
            --query 'Images[0].ImageId' \
            --region $region \
            --output text 2>/dev/null)
        if [ "$ami" != "None" ] && [ ! -z "$ami" ]; then
            echo -e "  $region: ${GREEN}$ami${NC}"
        fi
    fi
done

echo -e "\n${GREEN}Done!${NC}"
echo -e "Next steps:"
echo -e "1. Subscribe to DDVE in AWS Marketplace if not already done"
echo -e "2. Add the AMI configuration to terraform.tfvars"
echo -e "3. Run 'make deploy' to use the marketplace AMIs"