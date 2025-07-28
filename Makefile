# AWS NetWorker Lab Deployment Makefile
# Professional automation interface for infrastructure lifecycle management

SHELL := /bin/bash
.PHONY: help setup-keys deploy destroy validate clean clean-logs lint plan

# Color definitions for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Project variables
PROJECT_NAME := aws-networker-lab
AWS_REGION ?= us-east-1
TERRAFORM_DIR := ./terraform
ANSIBLE_DIR := ./ansible
KEY_NAME := aws_key
KEY_PATH := ./$(KEY_NAME)
LOG_DIR := ./logs

# Logging function - creates logs directory and captures output
define run_with_logs
	@mkdir -p $(LOG_DIR)
	@echo "$(GREEN)Running $(1) - Full log: $(LOG_DIR)/$(1).log$(NC)"
	@{ $(2) 2>&1 | tee $(LOG_DIR)/$(1).log; } 2>&1
	@grep -E '(ERROR|error|Error|FAILED|failed|Failed|FATAL|fatal|Fatal|WARNING|warning|Warning)' $(LOG_DIR)/$(1).log > $(LOG_DIR)/$(1)-errors.log 2>/dev/null || echo "No errors detected" > $(LOG_DIR)/$(1)-errors.log
	@echo "$(GREEN)Operation complete. Logs saved to $(LOG_DIR)/$(1).log and $(LOG_DIR)/$(1)-errors.log$(NC)"
endef

# Default target - show help
help:
	@echo "$(GREEN)AWS NetWorker Lab Deployment System$(NC)"
	@echo "Quick Start:"
	@echo "  $(YELLOW)make quick-setup$(NC)  - One-command setup (generates keys + tfvars)"
	@echo "  $(YELLOW)make deploy$(NC)       - Deploy everything"
	@echo ""
	@echo "📝 $(YELLOW)Note:$(NC) All major operations automatically save logs to $(LOG_DIR)/"
	@echo ""
	@echo "All targets:"
	@echo "  $(YELLOW)quick-setup$(NC)   - Generate SSH keys and create tfvars with your IP"
	@echo "  $(YELLOW)setup-keys$(NC)    - Generate SSH key pair for AWS instances"
	@echo "  $(YELLOW)get-my-ip$(NC)     - Show your current public IP address"
	@echo "  $(YELLOW)validate$(NC)      - Validate Terraform and Ansible configurations"
	@echo "  $(YELLOW)plan$(NC)          - Show infrastructure changes without applying"
	@echo "  $(YELLOW)deploy$(NC)        - Deploy complete infrastructure and configure services (with Windows automation)"
	@echo "  $(YELLOW)destroy$(NC)       - Destroy all AWS resources"
	@echo "  $(YELLOW)stop$(NC)          - Stop all EC2 instances (save costs)"
	@echo "  $(YELLOW)start$(NC)         - Start all stopped instances"
	@echo "  $(YELLOW)status$(NC)        - Show current infrastructure status"
	@echo "  $(YELLOW)clean$(NC)         - Clean local temporary files"
	@echo "  $(YELLOW)clean-logs$(NC)    - Clean all log files"
	@echo "  $(YELLOW)lint$(NC)          - Run code quality checks"
	@echo "  $(YELLOW)validate-terraform$(NC) - Validate only Terraform code"
	@echo "  $(YELLOW)validate-ansible$(NC)   - Validate only Ansible code"
	@echo "  $(YELLOW)validate-security$(NC)  - Run security checks"
	@echo ""
	@echo "Testing targets:"
	@echo "  $(YELLOW)test-ddve$(NC)     - Deploy and configure DDVE with S3 (full setup)"
	@echo "  $(YELLOW)test-ddve-infra$(NC) - Deploy only DDVE infrastructure (no config)"
	@echo "  $(YELLOW)test-networker$(NC) - Deploy only NetWorker for testing"
	@echo "  $(YELLOW)destroy-test$(NC)  - Destroy test resources"
	@echo ""
	@echo "Utility targets:"
	@echo "  $(YELLOW)get-windows-password$(NC) - Retrieve Windows Administrator password"

# Generate SSH key pair
setup-keys:
	@echo "$(GREEN)Generating SSH key pair...$(NC)"
	@if [ -f "$(KEY_PATH)" ]; then \
		echo "$(RED)SSH key already exists at $(KEY_PATH)$(NC)"; \
		echo "$(YELLOW)Remove existing key or use different name$(NC)"; \
		exit 1; \
	fi
	@ssh-keygen -t rsa -b 4096 -f $(KEY_PATH) -N "" -C "$(PROJECT_NAME)-key"
	@chmod 600 $(KEY_PATH)
	@chmod 644 $(KEY_PATH).pub
	@echo "$(GREEN)SSH key pair generated successfully$(NC)"
	@echo "Private key: $(KEY_PATH)"
	@echo "Public key: $(KEY_PATH).pub"

# Helper to get current IP
get-my-ip:
	@echo "$(GREEN)Your current public IP address is:$(NC)"
	@curl -s https://api.ipify.org || echo "Unable to detect IP"
	@echo ""
	@echo "$(YELLOW)Add this to your terraform.tfvars file:$(NC)"
	@echo 'admin_ip_cidr = "'$$(curl -s https://api.ipify.org)'/32"'

# Quick setup helper - automated setup
quick-setup:
	@echo "$(GREEN)Starting automated setup...$(NC)"
	@./scripts/setup.sh

# Validate configurations - comprehensive validation
validate:
	@echo "$(GREEN)Running comprehensive validation...$(NC)"
	@./scripts/validate-all.sh all

# Plan infrastructure changes
plan: validate
	@echo "$(GREEN)Planning infrastructure changes...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init -upgrade && terraform plan -out=tfplan

# Deploy infrastructure
deploy: validate
	@echo "$(GREEN)🚀 AWS NetWorker Lab - Complete Deployment$(NC)"
	@echo "$(YELLOW)This will deploy infrastructure and configure all services$(NC)"
	@echo ""
	@if [ ! -f "$(KEY_PATH).pub" ]; then \
		echo "$(RED)❌ SSH public key not found$(NC)"; \
		echo "$(YELLOW)💡 Run: make setup-keys$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(TERRAFORM_DIR)/terraform.tfvars" ]; then \
		echo "$(RED)❌ terraform.tfvars not found$(NC)"; \
		echo "$(YELLOW)💡 Run: make quick-setup$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Prerequisites check passed$(NC)"
	@echo ""
	@mkdir -p $(LOG_DIR)
	$(call run_with_logs,deploy,\
		echo "$(GREEN)🏗️  Phase 1: Deploying AWS Infrastructure$(NC)" && \
		cd $(TERRAFORM_DIR) && \
			terraform init -upgrade && \
			terraform apply -auto-approve && \
		cd .. && \
		echo "$(GREEN)🔐 Phase 2: Retrieving Windows Credentials$(NC)" && \
		WINDOWS_INSTANCE_ID=$$(cd $(TERRAFORM_DIR) && terraform output -raw windows_client_instance_id 2>/dev/null || echo "") && \
		if [ -n "$$WINDOWS_INSTANCE_ID" ] && [ "$$WINDOWS_INSTANCE_ID" != "null" ]; then \
			echo "$(YELLOW)📋 Windows instance found: $$WINDOWS_INSTANCE_ID$(NC)" && \
			./scripts/update-windows-password.sh && \
			WINDOWS_READY=true; \
		else \
			echo "$(YELLOW)📋 No Windows instance deployed - skipping Windows setup$(NC)" && \
			WINDOWS_READY=false; \
		fi && \
		echo "$(GREEN)⚙️  Phase 3: Configuring Services with Ansible$(NC)" && \
		cd $(ANSIBLE_DIR) && \
			export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && \
			export ANSIBLE_HOST_KEY_CHECKING=False && \
			if [ "$$WINDOWS_READY" = true ]; then \
				echo "$(YELLOW)🎯 Running full deployment (including Windows)$(NC)" && \
				ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml; \
			else \
				echo "$(YELLOW)🎯 Running deployment without Windows client$(NC)" && \
				ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml --limit '!windows_clients'; \
			fi && \
		cd .. && \
		echo "$(GREEN)🎉 Deployment completed successfully!$(NC)" \
	)

# Destroy infrastructure
destroy:
	@echo "$(RED)WARNING: This will destroy all AWS resources!$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm && \
	if [ "$$confirm" = "yes" ]; then \
		mkdir -p $(LOG_DIR); \
		echo "$(GREEN)Running destroy - Full log: $(LOG_DIR)/destroy.log$(NC)"; \
		{ \
			echo "$(YELLOW)Destroying infrastructure...$(NC)" && \
			cd $(TERRAFORM_DIR) && terraform destroy -auto-approve && \
			echo "$(GREEN)Infrastructure destroyed successfully$(NC)" && \
			echo "$(YELLOW)Cleaning up CloudWatch log group...$(NC)" && \
			aws logs delete-log-group --log-group-name "/aws/vpc/$(PROJECT_NAME)" --region $(AWS_REGION) 2>/dev/null || echo "$(GREEN)Log group already deleted or didn't exist$(NC)"; \
		} 2>&1 | tee $(LOG_DIR)/destroy.log; \
		grep -E '(ERROR|error|Error|FAILED|failed|Failed|FATAL|fatal|Fatal|WARNING|warning|Warning)' $(LOG_DIR)/destroy.log > $(LOG_DIR)/destroy-errors.log 2>/dev/null || echo "No errors detected" > $(LOG_DIR)/destroy-errors.log; \
		echo "$(GREEN)Operation complete. Logs saved to $(LOG_DIR)/destroy.log and $(LOG_DIR)/destroy-errors.log$(NC)"; \
	else \
		echo "$(YELLOW)Destruction cancelled$(NC)"; \
	fi

# Clean temporary files
clean:
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@find . -name "*.tfstate*" -type f -delete
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.retry" -type f -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@rm -f $(TERRAFORM_DIR)/tfplan
	@echo "$(GREEN)Cleanup completed$(NC)"

# Clean log files
clean-logs:
	@echo "$(YELLOW)Cleaning log files...$(NC)"
	@rm -rf $(LOG_DIR)
	@echo "$(GREEN)Log files removed$(NC)"

# Code quality checks
lint:
	@echo "$(GREEN)Running code quality checks...$(NC)"
	@echo "$(YELLOW)Checking Terraform files...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform fmt -check -recursive || (terraform fmt -recursive && echo "$(YELLOW)Terraform files formatted$(NC)")
	@echo "$(YELLOW)Checking Ansible files...$(NC)"
	@find $(ANSIBLE_DIR) -name "*.yml" -o -name "*.yaml" | xargs yamllint -c .yamllint || echo "$(YELLOW)Install yamllint for YAML validation$(NC)"
	@echo "$(GREEN)Linting completed$(NC)"

# Specific validation targets
validate-terraform:
	@./scripts/validate-all.sh terraform

validate-ansible:
	@./scripts/validate-all.sh ansible

validate-security:  # Optional - skipped by default in 'make validate'
	@./scripts/validate-all.sh security

# Quick status check
status:
	@echo "$(GREEN)Current Infrastructure Status:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform show -json 2>/dev/null | jq -r '.values.outputs | to_entries[] | "\(.key): \(.value.value)"' || echo "$(YELLOW)No infrastructure deployed$(NC)"

# Emergency stop - halt all EC2 instances
stop:
	$(call run_with_logs,stop,\
		echo "$(YELLOW)Stopping all EC2 instances...$(NC)" && \
		aws ec2 describe-instances --region $(AWS_REGION) --filters Name=tag:Project,Values=$(PROJECT_NAME) Name=instance-state-name,Values=running \
			--query "Reservations[*].Instances[*].InstanceId" --output text | \
			xargs -r aws ec2 stop-instances --region $(AWS_REGION) --instance-ids && \
		echo "$(GREEN)All instances stopped$(NC)" \
	)

# Start stopped instances
start:
	$(call run_with_logs,start,\
		echo "$(YELLOW)Starting all EC2 instances...$(NC)" && \
		aws ec2 describe-instances --region $(AWS_REGION) --filters Name=tag:Project,Values=$(PROJECT_NAME) Name=instance-state-name,Values=stopped \
			--query "Reservations[*].Instances[*].InstanceId" --output text | \
			xargs -r aws ec2 start-instances --region $(AWS_REGION) --instance-ids && \
		echo "$(GREEN)All instances started$(NC)" \
	)

# Show costs estimate
cost-estimate:
	@echo "$(GREEN)Estimated AWS Costs:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform plan -out=tfplan > /dev/null && terraform show -json tfplan | \
		jq -r '.planned_values.root_module.resources[] | select(.type | contains("ec2") or contains("ebs") or contains("s3")) | "\(.type): \(.name)"' || \
		echo "$(YELLOW)Cost estimation requires infrastructure plan$(NC)"

# Test specific components
test-ddve:
	$(call run_with_logs,test-ddve,\
		echo "$(GREEN)🚀 Deploying DDVE with full configuration...$(NC)" && \
		./scripts/deploy-ddve-only.sh \
	)

test-ddve-infra: validate
	$(call run_with_logs,test-ddve-infra,\
		echo "$(BLUE)Testing DDVE infrastructure only...$(NC)" && \
		if [ ! -f "$(KEY_PATH)" ]; then \
			echo "$(RED)SSH key not found. Running setup...$(NC)"; \
			make setup-keys; \
		fi && \
		if [ ! -f "$(TERRAFORM_DIR)/terraform.tfvars" ]; then \
			echo "$(RED)terraform.tfvars not found. Running quick-setup...$(NC)"; \
			./scripts/setup.sh; \
		fi && \
		cd $(TERRAFORM_DIR) && terraform apply -auto-approve \
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
			-target=aws_route53_record.ddve_cname && \
		echo "$(GREEN)DDVE infrastructure deployment complete!$(NC)" && \
		echo "$(YELLOW)Access DDVE at: https://$$(cd $(TERRAFORM_DIR) && terraform output -raw ddve_public_ip)$(NC)" && \
		echo "$(YELLOW)Initial credentials: sysadmin / <instance-id>$(NC)" && \
		echo "$(YELLOW)Final credentials: sysadmin / Changeme123!$(NC)" \
	)

test-networker:
	$(call run_with_logs,test-networker,\
		echo "$(BLUE)Testing NetWorker deployment only...$(NC)" && \
		cd $(TERRAFORM_DIR) && terraform apply -auto-approve \
		-target=module.vpc \
		-target=aws_vpc.main \
		-target=aws_subnet.public \
		-target=aws_internet_gateway.main \
		-target=aws_route_table.public \
		-target=aws_route_table_association.public \
		-target=aws_security_group.networker_server \
		-target=aws_instance.networker_server \
		-target=aws_instance.networker_server_spot \
		-target=aws_eip.networker_server \
		-target=aws_key_pair.main && \
		echo "$(GREEN)NetWorker test deployment complete!$(NC)" && \
		echo "$(YELLOW)Access NetWorker at: https://$$(cd $(TERRAFORM_DIR) && terraform output -raw networker_server_public_ip):9090$(NC)" \
	)

destroy-test:
	@echo "$(RED)Destroying test resources...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform destroy -auto-approve \
		-target=aws_instance.ddve \
		-target=aws_instance.ddve_spot \
		-target=aws_instance.networker_server \
		-target=aws_instance.networker_server_spot

# Get Windows password for Administrator user
get-windows-password:
	@echo "$(GREEN)Retrieving Windows Administrator password...$(NC)"
	@INSTANCE_ID=$$(cd $(TERRAFORM_DIR) && terraform output -raw windows_client_instance_id 2>/dev/null) && \
	if [ -z "$$INSTANCE_ID" ] || [ "$$INSTANCE_ID" = "null" ]; then \
		echo "$(RED)Windows instance not found or not deployed$(NC)"; \
		exit 1; \
	fi && \
	if [ ! -f "$(KEY_PATH)" ]; then \
		echo "$(RED)Private key not found at $(KEY_PATH)$(NC)"; \
		echo "$(YELLOW)Make sure you have the SSH private key$(NC)"; \
		exit 1; \
	fi && \
	echo "$(YELLOW)Instance ID: $$INSTANCE_ID$(NC)" && \
	echo "$(YELLOW)Retrieving password (this may take a few minutes after instance launch)...$(NC)" && \
	PASSWORD=$$(aws ec2 get-password-data --instance-id $$INSTANCE_ID --priv-launch-key $(KEY_PATH) --query 'PasswordData' --output text 2>/dev/null) && \
	if [ -z "$$PASSWORD" ] || [ "$$PASSWORD" = "null" ]; then \
		echo "$(YELLOW)Password not yet available. Windows instance may still be initializing.$(NC)"; \
		echo "$(YELLOW)Try again in a few minutes, or check instance status.$(NC)"; \
	else \
		echo "$(GREEN)Windows Administrator Password: $$PASSWORD$(NC)"; \
		echo "$(YELLOW)Update your Ansible inventory with:$(NC)"; \
		echo "ansible_password: \"$$PASSWORD\""; \
	fi

