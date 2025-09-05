#!/bin/bash
# PPDM CloudFormation Deployment Script
# This script switches to CloudFormation-based deployment

set -e

echo "🚀 PowerProtect Data Manager - CloudFormation Deployment"
echo "=================================================="

# Check prerequisites
if [ ! -f "../aws_key.pub" ]; then
    echo "❌ SSH public key not found at ../aws_key.pub"
    echo "💡 Run: make setup-keys from the parent directory"
    exit 1
fi

# Backup old files
echo "📦 Backing up existing configuration..."
if [ -f "main.tf" ]; then
    mv main.tf main_direct_ec2.tf.bak
    echo "✅ Backed up main.tf to main_direct_ec2.tf.bak"
fi

if [ -f "variables.tf" ]; then
    mv variables.tf variables_direct_ec2.tf.bak
    echo "✅ Backed up variables.tf to variables_direct_ec2.tf.bak"
fi

if [ -f "outputs.tf" ]; then
    mv outputs.tf outputs_direct_ec2.tf.bak
    echo "✅ Backed up outputs.tf to outputs_direct_ec2.tf.bak"
fi

if [ -f "terraform.tfvars" ]; then
    mv terraform.tfvars terraform_direct_ec2.tfvars.bak
    echo "✅ Backed up terraform.tfvars to terraform_direct_ec2.tfvars.bak"
fi

# Switch to CloudFormation files
echo "🔄 Switching to CloudFormation configuration..."
cp main_cloudformation.tf main.tf
cp variables_cloudformation.tf variables.tf  
cp outputs_cloudformation.tf outputs.tf
cp terraform_cloudformation.tfvars terraform.tfvars

echo "✅ CloudFormation configuration activated"

# Clean up terraform state if switching
if [ -f "terraform.tfstate" ]; then
    echo "⚠️  Found existing terraform state"
    echo "🧹 Cleaning up for fresh CloudFormation deployment..."
    rm -f terraform.tfstate*
    rm -rf .terraform/
fi

# Initialize terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating configuration..."
terraform validate

echo ""
echo "✅ CloudFormation configuration ready!"
echo ""
echo "Next steps:"
echo "1. Review terraform.tfvars (especially admin_ip_cidrs and common_password)"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
echo ""
echo "Web interface will be available at the IP shown in outputs after ~10-15 minutes"
echo "Default credentials: admin / PPDMAdmin2024!@#"