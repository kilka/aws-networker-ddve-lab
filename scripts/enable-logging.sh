#!/bin/bash
# Enable comprehensive logging for Terraform and Ansible

set -euo pipefail

# Create log directory structure
mkdir -p logs/{terraform,ansible,archive}

# Create enhanced ansible.cfg with logging
cat > ansible/ansible.cfg.new << 'EOF'
[defaults]
# Existing settings
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
callbacks_enabled = timer, profile_tasks
interpreter_python = auto
remote_tmp = /tmp/ansible-${USER}
# Disable warnings for experimental features
deprecation_warnings = False
command_warnings = False

# Add comprehensive logging
log_path = ./logs/ansible/ansible.log
# JSON logging for structured data
callback_whitelist = json, timer, profile_tasks

[inventory]
enable_plugins = json

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
pipelining = True
EOF

# Create log rotation configuration
cat > logs/logrotate.conf << 'EOF'
logs/terraform/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644
    dateext
    dateformat -%Y%m%d
    olddir logs/archive
}

logs/ansible/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644
    dateext
    dateformat -%Y%m%d
    olddir logs/archive
}

logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0644
    dateext
    dateformat -%Y%m%d
    olddir logs/archive
}
EOF

echo "Logging configuration created. To apply:"
echo "1. Review and move: mv ansible/ansible.cfg.new ansible/ansible.cfg"
echo "2. Add to crontab: 0 0 * * * /usr/sbin/logrotate -s logs/logrotate.state logs/logrotate.conf"