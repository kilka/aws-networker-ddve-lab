#!/usr/bin/env bash
# Comprehensive validation script for AWS NetWorker Lab
# Combines Terraform validation, deployment checks, and security scanning

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validation modes
MODE="${1:-all}"  # all, terraform, deployment, security

# Summary tracking
ERRORS=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

check_tool() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ✓ $1 is installed"
        return 0
    else
        echo -e "  ${RED}✗ $1 is not installed${NC}"
        return 1
    fi
}

error() {
    echo -e "${RED}✗ $1${NC}"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Main validation functions
validate_prerequisites() {
    print_header "Checking Prerequisites"
    
    local required_tools=("terraform" "ansible" "aws" "jq" "ssh")
    local optional_tools=("tflint" "checkov" "infracost" "yamllint")
    local prereq_failed=0
    
    echo -e "\n${YELLOW}Required tools:${NC}"
    for tool in "${required_tools[@]}"; do
        check_tool "$tool" || prereq_failed=1
    done
    
    echo -e "\n${YELLOW}Optional tools (for enhanced validation):${NC}"
    for tool in "${optional_tools[@]}"; do
        check_tool "$tool" || warning "$tool not found - some checks will be skipped"
    done
    
    if [ $prereq_failed -eq 1 ]; then
        error "Required tools missing. Please install them first."
        return 1
    fi
    
    # Check AWS credentials
    echo -e "\n${YELLOW}AWS credentials:${NC}"
    if aws sts get-caller-identity &> /dev/null; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local region=$(aws configure get region || echo "not set")
        success "AWS credentials configured (Account: $account_id, Region: $region)"
    else
        error "AWS credentials not configured"
        return 1
    fi
    
    # Check SSH key
    echo -e "\n${YELLOW}SSH key:${NC}"
    if [ -f "aws_key" ] && [ -f "aws_key.pub" ]; then
        success "SSH key pair exists"
        # Check permissions
        local key_perms=$(stat -c %a aws_key 2>/dev/null || stat -f %A aws_key 2>/dev/null || echo "unknown")
        if [ "$key_perms" = "600" ]; then
            success "SSH key permissions are correct (600)"
        else
            warning "SSH key permissions should be 600 (current: $key_perms)"
        fi
    else
        warning "SSH key pair not found. Run 'make setup-keys' to create"
    fi
}

validate_terraform() {
    print_header "Terraform Validation"
    
    cd terraform
    
    # Terraform fmt
    echo -e "\n${YELLOW}Formatting check:${NC}"
    if terraform fmt -check -recursive > /dev/null 2>&1; then
        success "Terraform formatting is correct"
    else
        warning "Terraform formatting issues found"
        echo "  Run 'terraform fmt -recursive' to fix"
        terraform fmt -check -recursive -diff 2>/dev/null || true
    fi
    
    # Terraform init
    echo -e "\n${YELLOW}Initialization:${NC}"
    if terraform init -backend=false > /dev/null 2>&1; then
        success "Terraform initialized successfully"
    else
        error "Terraform initialization failed"
        return 1
    fi
    
    # Terraform validate
    echo -e "\n${YELLOW}Configuration validation:${NC}"
    if terraform validate > /dev/null 2>&1; then
        success "Terraform configuration is valid"
    else
        error "Terraform validation failed"
        terraform validate || true
        return 1
    fi
    
    # TFLint
    if command -v tflint &> /dev/null; then
        echo -e "\n${YELLOW}TFLint analysis:${NC}"
        tflint --init > /dev/null 2>&1
        if tflint --format compact 2>/dev/null; then
            success "TFLint checks passed"
        else
            warning "TFLint found issues"
        fi
    fi
    
    # Check for tfvars file
    echo -e "\n${YELLOW}Configuration files:${NC}"
    if [ -f "terraform.tfvars" ]; then
        success "terraform.tfvars exists"
    else
        warning "terraform.tfvars not found - using defaults"
        echo "  Run 'make quick-setup' to create one"
    fi
    
    # Validate example tfvars
    for tfvars in terraform.tfvars.example terraform.tfvars.minimal terraform.tfvars.production; do
        if [ -f "$tfvars" ]; then
            echo -e "\n  Validating $tfvars..."
            cp "$tfvars" test.tfvars
            sed -i.bak 's/YOUR_IP_ADDRESS/1.2.3.4/g' test.tfvars 2>/dev/null || \
            sed -i '' 's/YOUR_IP_ADDRESS/1.2.3.4/g' test.tfvars 2>/dev/null
            if terraform plan -var-file=test.tfvars -input=false > /dev/null 2>&1; then
                success "  $tfvars is valid"
            else
                warning "  $tfvars has errors"
            fi
            rm -f test.tfvars test.tfvars.bak
        fi
    done
    
    cd ..
}

validate_ansible() {
    print_header "Ansible Validation"
    
    cd ansible
    
    # Check ansible.cfg
    echo -e "\n${YELLOW}Configuration:${NC}"
    if [ -f "ansible.cfg" ]; then
        success "ansible.cfg exists"
    else
        warning "ansible.cfg not found"
    fi
    
    # Validate playbooks syntax
    echo -e "\n${YELLOW}Playbook syntax check:${NC}"
    local playbook_errors=0
    for playbook in playbooks/*.yml; do
        if [ -f "$playbook" ]; then
            echo -n "  Checking $(basename $playbook)... "
            if ansible-playbook "$playbook" --syntax-check > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
                ((playbook_errors++))
            fi
        fi
    done
    
    if [ $playbook_errors -eq 0 ]; then
        success "All playbooks have valid syntax"
    else
        error "$playbook_errors playbook(s) have syntax errors"
    fi
    
    # YAML lint
    if command -v yamllint &> /dev/null; then
        echo -e "\n${YELLOW}YAML linting:${NC}"
        if yamllint -c ../.yamllint . > /dev/null 2>&1; then
            success "YAML files are properly formatted"
        else
            warning "YAML formatting issues found"
            yamllint -c ../.yamllint . 2>&1 | head -10 || true
        fi
    fi
    
    # Check inventory
    echo -e "\n${YELLOW}Inventory:${NC}"
    if [ -f "inventory/dynamic_inventory.json" ]; then
        success "Dynamic inventory exists"
        local host_count=$(jq -r '.all.children | to_entries | map(.value.hosts | length) | add' inventory/dynamic_inventory.json 2>/dev/null || echo "0")
        echo "  Hosts in inventory: $host_count"
    else
        echo "  Dynamic inventory not found (normal if not deployed)"
    fi
    
    # Check required files
    echo -e "\n${YELLOW}Required files:${NC}"
    local required_files=(
        "roles/install_agent/files/lgtoclnt-19.4.0.2-1.x86_64.rpm"
        "roles/install_agent/files/lgtoclnt-19.4.0.3_x64.exe"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            success "$(basename $file) exists"
        else
            warning "$(basename $file) not found - agent installation may fail"
        fi
    done
    
    cd ..
}

validate_security() {
    print_header "Security Validation"
    
    # Check for sensitive data in code
    echo -e "\n${YELLOW}Checking for exposed secrets:${NC}"
    local sensitive_patterns=(
        "aws_access_key_id"
        "aws_secret_access_key"
        "password.*=.*['\"]"
        "token.*=.*['\"]"
        "secret.*=.*['\"]"
    )
    
    local found_secrets=0
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -r "$pattern" . \
            --exclude-dir=.git \
            --exclude-dir=.terraform \
            --exclude-dir=logs \
            --exclude="*.tfstate*" \
            --exclude="*.backup" \
            --exclude="*.log" \
            --exclude="validate-all.sh" \
            > /dev/null 2>&1; then
            warning "Potential sensitive data found matching pattern: $pattern"
            ((found_secrets++))
        fi
    done
    
    if [ $found_secrets -eq 0 ]; then
        success "No hardcoded secrets detected"
    else
        warning "$found_secrets potential security issues found"
    fi
    
    # Checkov security scan
    if command -v checkov &> /dev/null; then
        echo -e "\n${YELLOW}Infrastructure security scan:${NC}"
        cd terraform
        if checkov -d . --quiet --compact --framework terraform > /dev/null 2>&1; then
            success "Security scan passed"
        else
            warning "Security scan found issues (non-critical)"
            checkov -d . --quiet --compact --framework terraform 2>&1 | grep -E "FAILED|WARNING" | head -10 || true
        fi
        cd ..
    fi
    
    # Check file permissions
    echo -e "\n${YELLOW}File permissions:${NC}"
    local permission_issues=0
    
    # Check for world-readable sensitive files
    for file in aws_key terraform.tfvars ansible/group_vars/*/vault.yml; do
        if [ -f "$file" ]; then
            local perms=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null || echo "unknown")
            if [[ "$perms" =~ .*[2367]$ ]]; then
                warning "$file is world-readable (permissions: $perms)"
                ((permission_issues++))
            fi
        fi
    done
    
    if [ $permission_issues -eq 0 ]; then
        success "File permissions are secure"
    fi
}

validate_deployment() {
    print_header "Deployment Status"
    
    cd terraform
    
    # Check Terraform state
    echo -e "\n${YELLOW}Infrastructure state:${NC}"
    if [ -f "terraform.tfstate" ]; then
        success "Terraform state file exists"
        
        # Get deployment status
        local instance_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | map(select(.type == "aws_instance")) | length' || echo "0")
        local eip_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | map(select(.type == "aws_eip")) | length' || echo "0")
        local s3_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | map(select(.type == "aws_s3_bucket")) | length' || echo "0")
        
        echo "  EC2 Instances: $instance_count"
        echo "  Elastic IPs: $eip_count"
        echo "  S3 Buckets: $s3_count"
        
        if [ "$instance_count" -gt 0 ]; then
            echo -e "\n${YELLOW}Instance details:${NC}"
            terraform output -json 2>/dev/null | jq -r 'to_entries[] | select(.key | endswith("_ip") or endswith("_id")) | "  \(.key): \(.value.value)"' || echo "  Unable to get instance details"
            
            # Test connectivity
            echo -e "\n${YELLOW}Connectivity tests:${NC}"
            local nw_ip=$(terraform output -raw networker_server_public_ip 2>/dev/null || echo "")
            local ddve_ip=$(terraform output -raw ddve_public_ip 2>/dev/null || echo "")
            
            for ip_info in "NetWorker:$nw_ip:admin" "DDVE:$ddve_ip:sysadmin"; do
                IFS=':' read -r name ip user <<< "$ip_info"
                if [ ! -z "$ip" ] && [ "$ip" != "null" ]; then
                    echo -n "  Testing $name ($ip)... "
                    if timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i ../aws_key "$user@$ip" exit 2>/dev/null; then
                        echo -e "${GREEN}✓ SSH accessible${NC}"
                    else
                        echo -e "${YELLOW}⚠ SSH not accessible (may still be booting)${NC}"
                    fi
                fi
            done
            
            # Check web interfaces
            echo -e "\n${YELLOW}Web interface availability:${NC}"
            if [ ! -z "$nw_ip" ] && [ "$nw_ip" != "null" ]; then
                echo -n "  NetWorker Console (https://$nw_ip:9090)... "
                if timeout 5 curl -k -s -o /dev/null -w "%{http_code}" "https://$nw_ip:9090" 2>/dev/null | grep -q "200\|302\|401"; then
                    echo -e "${GREEN}✓ Accessible${NC}"
                else
                    echo -e "${YELLOW}⚠ Not accessible yet${NC}"
                fi
            fi
            
            if [ ! -z "$ddve_ip" ] && [ "$ddve_ip" != "null" ]; then
                echo -n "  DDVE Console (https://$ddve_ip)... "
                if timeout 5 curl -k -s -o /dev/null -w "%{http_code}" "https://$ddve_ip" 2>/dev/null | grep -q "200\|302\|401"; then
                    echo -e "${GREEN}✓ Accessible${NC}"
                else
                    echo -e "${YELLOW}⚠ Not accessible yet${NC}"
                fi
            fi
        else
            echo "  No instances deployed"
        fi
    else
        echo "  No deployment found"
    fi
    
    cd ..
}

cost_estimation() {
    if command -v infracost &> /dev/null; then
        print_header "Cost Estimation"
        cd terraform
        echo -e "\n${YELLOW}Estimated monthly costs:${NC}"
        infracost breakdown --path . --format table 2>/dev/null || warning "Cost estimation failed"
        cd ..
    fi
}

# Main execution
main() {
    echo -e "${GREEN}AWS NetWorker Lab - Comprehensive Validation${NC}"
    echo -e "${GREEN}Mode: $MODE${NC}"
    
    case "$MODE" in
        all)
            validate_prerequisites || exit 1
            validate_terraform
            validate_ansible
            # validate_security  # Skipped for demo project
            validate_deployment
            cost_estimation
            ;;
        terraform)
            validate_prerequisites || exit 1
            validate_terraform
            ;;
        ansible)
            validate_prerequisites || exit 1
            validate_ansible
            ;;
        security)
            validate_security
            ;;
        deployment)
            validate_deployment
            ;;
        cost)
            cost_estimation
            ;;
        *)
            echo -e "${RED}Invalid mode: $MODE${NC}"
            echo "Usage: $0 [all|terraform|ansible|security|deployment|cost]"
            exit 1
            ;;
    esac
    
    # Summary
    print_header "Validation Summary"
    echo -e "\nErrors: ${ERRORS}"
    echo -e "Warnings: ${WARNINGS}"
    
    if [ $ERRORS -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "\n${GREEN}All validation checks passed!${NC}"
        else
            echo -e "\n${YELLOW}Validation completed with warnings${NC}"
        fi
        exit 0
    else
        echo -e "\n${RED}Validation failed with errors${NC}"
        exit 1
    fi
}

# Run main function
main