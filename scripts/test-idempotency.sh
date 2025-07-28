#!/bin/bash

# Test script to verify Ansible playbook idempotency
# Runs the playbook twice and compares execution times and changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m' 
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔄 AWS NetWorker Lab - Idempotency Test${NC}"
echo "==============================================="

# Check if infrastructure is deployed
cd "$PROJECT_ROOT/terraform"
if ! terraform show >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  No infrastructure found. Deploy first with: make deploy${NC}"
    exit 1
fi

echo -e "${GREEN}📊 Testing playbook idempotency${NC}"
echo ""

cd "$ANSIBLE_DIR"
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# First run - initial configuration
echo -e "${CYAN}🚀 Run 1: Initial Configuration${NC}"
echo "------------------------------------------------"
START_TIME1=$(date +%s)

ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml \
    --tags "ddve,networker,agents,backup-config" \
    --skip-tags "never" > /tmp/ansible_run1.log 2>&1

END_TIME1=$(date +%s)
DURATION1=$((END_TIME1 - START_TIME1))
MINUTES1=$((DURATION1 / 60))
SECONDS1=$((DURATION1 % 60))

# Extract change counts from first run
CHANGED1=$(grep -c "changed:" /tmp/ansible_run1.log || echo "0")
OK1=$(grep -c "ok:" /tmp/ansible_run1.log || echo "0")
SKIPPED1=$(grep -c "skipped:" /tmp/ansible_run1.log || echo "0")

echo -e "${GREEN}✅ First run completed${NC}"
echo -e "${GREEN}⏱️  Time: ${MINUTES1}m ${SECONDS1}s${NC}"
echo -e "${GREEN}📈 Stats: ${CHANGED1} changed, ${OK1} ok, ${SKIPPED1} skipped${NC}"
echo ""

# Wait a moment
sleep 5

# Second run - should be idempotent (no changes)
echo -e "${CYAN}🔄 Run 2: Idempotency Check${NC}"
echo "------------------------------------------------"
START_TIME2=$(date +%s)

ansible-playbook -i inventory/dynamic_inventory.json playbooks/site.yml \
    --tags "ddve,networker,agents,backup-config" \
    --skip-tags "never" > /tmp/ansible_run2.log 2>&1

END_TIME2=$(date +%s)
DURATION2=$((END_TIME2 - START_TIME2))
MINUTES2=$((DURATION2 / 60))
SECONDS2=$((DURATION2 % 60))

# Extract change counts from second run
CHANGED2=$(grep -c "changed:" /tmp/ansible_run2.log || echo "0")
OK2=$(grep -c "ok:" /tmp/ansible_run2.log || echo "0")
SKIPPED2=$(grep -c "skipped:" /tmp/ansible_run2.log || echo "0")

echo -e "${GREEN}✅ Second run completed${NC}"
echo -e "${GREEN}⏱️  Time: ${MINUTES2}m ${SECONDS2}s${NC}"
echo -e "${GREEN}📈 Stats: ${CHANGED2} changed, ${OK2} ok, ${SKIPPED2} skipped${NC}"
echo ""

# Calculate improvements
TIME_SAVED=$((DURATION1 - DURATION2))
TIME_SAVED_MINUTES=$((TIME_SAVED / 60))
TIME_SAVED_SECONDS=$((TIME_SAVED % 60))

if [ $DURATION1 -gt 0 ]; then
    SPEED_IMPROVEMENT=$(( (TIME_SAVED * 100) / DURATION1 ))
else
    SPEED_IMPROVEMENT=0
fi

# Results analysis
echo -e "${CYAN}📊 Idempotency Test Results${NC}"
echo "===================================="
echo -e "${YELLOW}Run 1 (Initial):  ${MINUTES1}m ${SECONDS1}s (${CHANGED1} changes)${NC}"
echo -e "${YELLOW}Run 2 (Rerun):    ${MINUTES2}m ${SECONDS2}s (${CHANGED2} changes)${NC}"
echo -e "${CYAN}Time Saved:       ${TIME_SAVED_MINUTES}m ${TIME_SAVED_SECONDS}s (${SPEED_IMPROVEMENT}% faster)${NC}"
echo ""

# Idempotency analysis
if [ "$CHANGED2" -eq 0 ]; then
    echo -e "${GREEN}🎉 PERFECT IDEMPOTENCY: No changes on second run!${NC}"
    echo -e "${GREEN}✅ All roles properly check existing state${NC}"
elif [ "$CHANGED2" -lt 3 ]; then
    echo -e "${YELLOW}🔄 GOOD IDEMPOTENCY: Only ${CHANGED2} minor changes on rerun${NC}"
    echo -e "${YELLOW}⚠️  Some tasks may need additional state checking${NC}"
else
    echo -e "${RED}❌ POOR IDEMPOTENCY: ${CHANGED2} changes on rerun${NC}"
    echo -e "${RED}⚠️  Significant state checking improvements needed${NC}"
fi

# Performance analysis
if [ $SPEED_IMPROVEMENT -gt 50 ]; then
    echo -e "${GREEN}🚀 EXCELLENT PERFORMANCE: ${SPEED_IMPROVEMENT}% faster on rerun${NC}"
    echo -e "${GREEN}✅ State checks significantly reduce execution time${NC}"
elif [ $SPEED_IMPROVEMENT -gt 25 ]; then
    echo -e "${YELLOW}⚡ GOOD PERFORMANCE: ${SPEED_IMPROVEMENT}% faster on rerun${NC}"
    echo -e "${YELLOW}✅ State checks provide reasonable time savings${NC}"
else
    echo -e "${YELLOW}⏳ MINIMAL IMPROVEMENT: Only ${SPEED_IMPROVEMENT}% faster${NC}"
    echo -e "${YELLOW}💡 Consider adding more comprehensive state checks${NC}"
fi

echo ""
echo -e "${CYAN}🔍 Component Analysis:${NC}"
echo "• DDVE: Checks if filesystem is running"
echo "• NetWorker: Checks if service is active"  
echo "• Agents: Checks if services are installed"
echo "• Backup: Checks if policies exist"
echo ""

# Log file locations
echo -e "${CYAN}📋 Detailed Logs:${NC}"
echo "• First run:  /tmp/ansible_run1.log"
echo "• Second run: /tmp/ansible_run2.log"
echo ""

# Summary
if [ "$CHANGED2" -eq 0 ] && [ $SPEED_IMPROVEMENT -gt 30 ]; then
    echo -e "${GREEN}🏆 IDEMPOTENCY SUCCESS: Perfect rerun behavior with significant speed improvement!${NC}"
else
    echo -e "${YELLOW}📝 PARTIAL SUCCESS: Some improvements achieved, but room for optimization${NC}"
fi