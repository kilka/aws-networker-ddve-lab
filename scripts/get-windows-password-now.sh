#!/bin/bash

# Quick Windows password retrieval - for manual use when deployment script times out
# Usage: ./get-windows-password-now.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
KEY_PATH="$PROJECT_ROOT/aws_key.pem"

# Set AWS region (default to us-east-1)
export AWS_DEFAULT_REGION=${AWS_REGION:-us-east-1}

echo "🔓 Quick Windows Password Retrieval"
echo "=================================="

# Get instance ID from Terraform
INSTANCE_ID=$(cd "$TERRAFORM_DIR" && terraform output -raw windows_client_instance_id 2>/dev/null)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "null" ]; then
    echo "❌ Windows instance not found. Make sure infrastructure is deployed."
    exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "❌ Private key not found at $KEY_PATH"
    exit 1
fi

echo "📋 Instance ID: $INSTANCE_ID"
echo "🔍 Attempting immediate password retrieval..."

# Try to get password right now
RAW_PASSWORD_DATA=$(aws ec2 get-password-data \
    --instance-id "$INSTANCE_ID" \
    --query 'PasswordData' \
    --output text 2>/dev/null || echo "")

if [ -n "$RAW_PASSWORD_DATA" ] && [ "$RAW_PASSWORD_DATA" != "null" ] && [ "$RAW_PASSWORD_DATA" != "" ]; then
    echo "✅ Encrypted password found!"
    
    PASSWORD=$(aws ec2 get-password-data \
        --instance-id "$INSTANCE_ID" \
        --priv-launch-key "$KEY_PATH" \
        --query 'PasswordData' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$PASSWORD" ] && [ "$PASSWORD" != "null" ] && [ "$PASSWORD" != "" ]; then
        echo ""
        echo "🎉 SUCCESS! Windows Administrator Password:"
        echo "=========================================="
        echo "$PASSWORD"
        echo "=========================================="
        echo ""
        echo "💻 Connection Details:"
        PUBLIC_IP=$(cd "$TERRAFORM_DIR" && terraform output -raw windows_client_public_ip 2>/dev/null || echo "N/A")
        echo "   Host: $PUBLIC_IP"
        echo "   User: Administrator"
        echo "   Password: $PASSWORD"
        echo "   RDP Port: 3389"
        echo "   WinRM HTTP: 5985"
        echo "   WinRM HTTPS: 5986"
        echo ""
        echo "📝 To update Ansible inventory:"
        echo "   Replace 'CHANGE_ME' with the password above in:"
        echo "   ansible/inventory/dynamic_inventory.json"
        echo ""
        echo "🚀 Or run the full update script:"
        echo "   ./scripts/update-windows-password.sh"
    else
        echo "❌ Failed to decrypt password. Check private key permissions:"
        ls -la "$KEY_PATH"
    fi
else
    echo "❌ Password not yet available from AWS API"
    echo ""
    echo "ℹ️  This means:"
    echo "   • Windows may still be starting up"
    echo "   • AWS API hasn't published the encrypted password yet"
    echo "   • This is normal - try again in a few minutes"
    echo ""
    echo "🔍 Checking instance status..."
    STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text)
    echo "   Instance State: $STATE"
    
    if [ "$STATE" = "running" ]; then
        echo "   ✅ Instance is running"
        echo "   ⏳ Try running this script again in 5-10 minutes"
    else
        echo "   ⚠️  Instance is not running - check AWS Console"
    fi
fi