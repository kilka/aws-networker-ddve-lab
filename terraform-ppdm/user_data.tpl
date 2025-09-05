#!/bin/bash
# PowerProtect Data Manager User Data Script
# This script handles PPDM-specific initialization

set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting PPDM initialization at $(date)"

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")

echo "Instance ID: $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"
echo "Public IP: $PUBLIC_IP"

# Configure hostname
echo "Configuring hostname..."
HOSTNAME="ppdm-$${INSTANCE_ID}"
hostnamectl set-hostname $HOSTNAME
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# Configure timezone
if [ -n "${timezone}" ]; then
    echo "Setting timezone to ${timezone}"
    timedatectl set-timezone "${timezone}" || echo "Failed to set timezone"
fi

# Configure NTP
if [ -n "${ntp_server}" ]; then
    echo "Configuring NTP server: ${ntp_server}"
    if [ -f /etc/chrony.conf ]; then
        echo "server ${ntp_server} iburst" >> /etc/chrony.conf
        systemctl restart chronyd || echo "Failed to restart chronyd"
    fi
fi

# Configure DNS
if [ -n "${dns_server}" ]; then
    echo "Configuring DNS server: ${dns_server}"
    echo "nameserver ${dns_server}" > /etc/resolv.conf
fi

# Wait for Docker to be ready
echo "Waiting for Docker service..."
for i in {1..30}; do
    if systemctl is-active --quiet docker; then
        echo "Docker is running"
        break
    fi
    echo "Waiting for Docker... attempt $i/30"
    sleep 10
done

# Start PPDM services if they exist
echo "Starting PPDM services..."
if [ -f /opt/dpsapps/pgutil/bin/pg_startup.sh ]; then
    /opt/dpsapps/pgutil/bin/pg_startup.sh || echo "PPDM startup script not found or failed"
fi

# Configure initial password if provided
if [ -n "${common_password}" ]; then
    echo "Password will be configured through web interface"
fi

echo "PPDM user data completed at $(date)"
echo "Web interface should be available at https://$PRIVATE_IP or https://$PUBLIC_IP"