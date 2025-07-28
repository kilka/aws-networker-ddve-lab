#!/bin/bash

# Update Windows password in Ansible inventory
# This script retrieves the Windows Administrator password and updates the inventory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
KEY_PATH="$PROJECT_ROOT/aws_key"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/dynamic_inventory.json"

# Set AWS region (default to us-east-1)  
export AWS_DEFAULT_REGION=${AWS_REGION:-us-east-1}

echo "🔐 Retrieving Windows Administrator password..."

# Get instance ID from Terraform
INSTANCE_ID=$(cd "$TERRAFORM_DIR" && terraform output -raw windows_client_instance_id 2>/dev/null)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "null" ]; then
    echo "❌ Windows instance not found or not deployed"
    exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "❌ Private key not found at $KEY_PATH"
    exit 1
fi

echo "📋 Instance ID: $INSTANCE_ID"
echo "⏳ Retrieving password (may take a few minutes after instance launch)..."

# First check if instance is actually running and ready
echo "📊 Checking instance status..."
INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null || echo "unknown")

echo "   Instance State: $INSTANCE_STATE"

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "⚠️  Instance is not running (state: $INSTANCE_STATE)"
    echo "💡 Wait for instance to start or check AWS Console"
    exit 1
fi

# Check system status before trying password (with timeout)
echo "🔍 Waiting for instance to pass system checks..."
timeout 180 aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" 2>/dev/null && {
    echo "✅ Instance status checks passed"
} || {
    echo "⚠️  Status checks taking longer than expected, but proceeding..."
    echo "   (This is normal for Windows instances)"
}

# Retry password retrieval with smarter timing
MAX_ATTEMPTS=6  # Reduced attempts but more efficient
ATTEMPT=1
SLEEP_TIME=15   # Start with shorter waits

echo ""
echo "🔐 Starting password retrieval (AWS API timing can vary)..."

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "🔄 Attempt $ATTEMPT/$MAX_ATTEMPTS..."
    
    # First check if password data exists (without decryption) 
    echo "   Checking if encrypted password is available..."
    RAW_PASSWORD_DATA=$(aws ec2 get-password-data \
        --instance-id "$INSTANCE_ID" \
        --query 'PasswordData' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$RAW_PASSWORD_DATA" ] && [ "$RAW_PASSWORD_DATA" != "null" ] && [ "$RAW_PASSWORD_DATA" != "" ]; then
        echo "   ✅ Encrypted password found in AWS API!"
        echo "   🔓 Decrypting with private key..."
        
        # Now decrypt it
        PASSWORD=$(aws ec2 get-password-data \
            --instance-id "$INSTANCE_ID" \
            --priv-launch-key "$KEY_PATH" \
            --query 'PasswordData' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$PASSWORD" ] && [ "$PASSWORD" != "null" ] && [ "$PASSWORD" != "" ]; then
            echo "   🎉 Password successfully decrypted!"
            break
        else
            echo "   ❌ Decryption failed - checking private key permissions..."
            ls -la "$KEY_PATH" 2>/dev/null || echo "   Private key not found!"
        fi
    else
        echo "   ⏳ AWS API hasn't published encrypted password yet..."
        
        # Quick check of Windows logs to see if instance is actually ready
        if [ $ATTEMPT -eq 3 ]; then
            echo "   📋 Checking Windows initialization status..."
            CONSOLE_OUTPUT=$(aws ec2 get-console-output --instance-id "$INSTANCE_ID" --output text 2>/dev/null | tail -5)
            if echo "$CONSOLE_OUTPUT" | grep -q "Windows is Ready to use"; then
                echo "   ✅ Windows reports ready - AWS API just needs more time"
            else
                echo "   ⏳ Windows may still be initializing"
            fi
        fi
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo "❌ Password retrieval timed out after $MAX_ATTEMPTS attempts"
        echo ""
        echo "🤔 This is likely an AWS API timing issue where:"
        echo "   • Windows finished setup but AWS API hasn't caught up"
        echo "   • Password encryption/publishing has a delay"
        echo "   • This is normal behavior, not a script error"
        echo ""
        echo "💡 Recommended actions:"
        echo "   1. 🕐 Wait 5-10 more minutes, then run: make get-windows-password"
        echo "   2. 🚀 Continue deployment without Windows (--limit '!windows_clients')"
        echo "   3. 📊 Check AWS Console → EC2 → Instance → Actions → Security → Get Windows Password"
        echo "   4. 🔍 View instance console output for any Windows errors"
        echo ""
        echo "⚠️  Deployment will continue without Windows automation"
        exit 1
    fi
    
    # Adaptive timing strategy
    if [ $ATTEMPT -eq 1 ]; then
        SLEEP_TIME=15   # Quick first retry
    elif [ $ATTEMPT -eq 2 ]; then
        SLEEP_TIME=30   # Medium wait
    else
        SLEEP_TIME=60   # Longer waits for later attempts
    fi
    
    echo "   ⏰ Waiting ${SLEEP_TIME}s before next attempt..."
    sleep $SLEEP_TIME
    ATTEMPT=$((ATTEMPT + 1))
done

echo "🔧 Updating Ansible inventory with Windows password..."

# Update the inventory file with the actual password
if [ -f "$INVENTORY_FILE" ]; then
    # Use jq to update the password in the JSON inventory
    if command -v jq >/dev/null 2>&1; then
        # Create a temporary file with updated password
        jq --arg password "$PASSWORD" \
           '.all.children.windows_clients.hosts.windows_client.ansible_password = $password' \
           "$INVENTORY_FILE" > "${INVENTORY_FILE}.tmp" && \
           mv "${INVENTORY_FILE}.tmp" "$INVENTORY_FILE"
        
        echo "✅ Inventory updated with Windows password"
        echo "🎯 Windows client is ready for Ansible automation"
    else
        echo "⚠️  jq not found - updating inventory manually"
        # Fallback: simple sed replacement (less robust but works)
        sed -i.bak "s/\"CHANGE_ME\"/\"$PASSWORD\"/g" "$INVENTORY_FILE"
        echo "✅ Inventory updated (backup saved as ${INVENTORY_FILE}.bak)"
    fi
else
    echo "⚠️  Inventory file not found at $INVENTORY_FILE"
    echo "💡 Run terraform apply to generate the inventory first"
fi

echo ""
echo "📝 Windows Connection Details:"
echo "   Host: $(cd "$TERRAFORM_DIR" && terraform output -raw windows_client_public_ip)"
echo "   User: Administrator"
echo "   Password: $PASSWORD"
echo "   RDP Port: 3389"
echo "   WinRM Ports: 5985 (HTTP), 5986 (HTTPS)"
echo ""
echo "🚀 Ready to run Ansible playbooks!"