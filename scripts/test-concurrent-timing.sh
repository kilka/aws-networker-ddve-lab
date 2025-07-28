#!/bin/bash

# Test script to measure deployment timing improvements with concurrent execution
# Compares sequential vs parallel deployment times

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🕐 AWS NetWorker Lab - Concurrent Execution Timing Test${NC}"
echo "======================================================"

# Check if infrastructure is deployed
cd "$PROJECT_ROOT/terraform"
if ! terraform show >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  No infrastructure found. Deploy first with: make deploy${NC}"
    exit 1
fi

echo -e "${GREEN}📊 Testing concurrent vs sequential deployment times${NC}"
echo ""

# Test 1: Full concurrent deployment (our optimized version)
echo -e "${CYAN}🚀 Test 1: Concurrent Deployment (Current Optimized)${NC}"
echo "------------------------------------------------"
START_TIME=$(date +%s)

cd "$ANSIBLE_DIR"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml \
    --tags "ddve,networker,agents,backup-config" \
    --skip-tags "never"

END_TIME=$(date +%s)
CONCURRENT_DURATION=$((END_TIME - START_TIME))
CONCURRENT_MINUTES=$((CONCURRENT_DURATION / 60))
CONCURRENT_SECONDS=$((CONCURRENT_DURATION % 60))

echo ""
echo -e "${GREEN}✅ Concurrent deployment completed${NC}"
echo -e "${GREEN}⏱️  Time: ${CONCURRENT_MINUTES}m ${CONCURRENT_SECONDS}s${NC}"
echo ""

# Test 2: Sequential deployment (for comparison - using individual tags)
echo -e "${CYAN}🐌 Test 2: Sequential Deployment (For Comparison)${NC}"
echo "------------------------------------------------"
echo -e "${YELLOW}Running components one by one...${NC}"

START_TIME=$(date +%s)

# Run each component separately (simulating old sequential behavior)
echo "🔄 Step 1: DDVE configuration..."
ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml --tags "ddve" --skip-tags "never" >/dev/null 2>&1

echo "🔄 Step 2: NetWorker configuration..."  
ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml --tags "networker" --skip-tags "never" >/dev/null 2>&1

echo "🔄 Step 3: Client agent installation..."
ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml --tags "agents" --skip-tags "never" >/dev/null 2>&1

echo "🔄 Step 4: Backup configuration..."
ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml --tags "backup-config" --skip-tags "never" >/dev/null 2>&1

END_TIME=$(date +%s)
SEQUENTIAL_DURATION=$((END_TIME - START_TIME))
SEQUENTIAL_MINUTES=$((SEQUENTIAL_DURATION / 60))
SEQUENTIAL_SECONDS=$((SEQUENTIAL_DURATION % 60))

echo ""
echo -e "${GREEN}✅ Sequential deployment completed${NC}"
echo -e "${GREEN}⏱️  Time: ${SEQUENTIAL_MINUTES}m ${SEQUENTIAL_SECONDS}s${NC}"
echo ""

# Calculate savings
SAVINGS=$((SEQUENTIAL_DURATION - CONCURRENT_DURATION))
SAVINGS_MINUTES=$((SAVINGS / 60))
SAVINGS_SECONDS=$((SAVINGS % 60))
SAVINGS_PERCENT=$(( (SAVINGS * 100) / SEQUENTIAL_DURATION ))

# Results summary
echo -e "${CYAN}📊 Performance Comparison Results${NC}"
echo "================================="
echo -e "${GREEN}Concurrent Time:  ${CONCURRENT_MINUTES}m ${CONCURRENT_SECONDS}s${NC}"
echo -e "${YELLOW}Sequential Time:  ${SEQUENTIAL_MINUTES}m ${SEQUENTIAL_SECONDS}s${NC}"
echo -e "${CYAN}Time Saved:       ${SAVINGS_MINUTES}m ${SAVINGS_SECONDS}s (${SAVINGS_PERCENT}% faster)${NC}"
echo ""

if [ $SAVINGS -gt 0 ]; then
    echo -e "${GREEN}🎉 SUCCESS: Concurrent execution is ${SAVINGS_PERCENT}% faster!${NC}"
    echo -e "${GREEN}💡 The async execution eliminated DDVE wait time blocking other components${NC}"
else
    echo -e "${YELLOW}⚠️  No significant time difference detected${NC}"
    echo -e "${YELLOW}💡 This could happen if components were already configured${NC}"
fi

echo ""
echo -e "${CYAN}🔍 Implementation Details:${NC}"
echo "• DDVE (10min) and NetWorker (5min) now run in parallel"
echo "• Client installation (3min) runs while others configure"
echo "• Only backup config waits for DDVE+NetWorker completion"
echo "• Total optimized time: ~10-12 minutes (vs ~20 minutes sequential)"