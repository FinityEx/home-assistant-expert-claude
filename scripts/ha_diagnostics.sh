#!/usr/bin/env bash
# ha_diagnostics.sh
# Comprehensive Home Assistant diagnostics collector
# Usage: ./ha_diagnostics.sh [--output file.txt]

set -e

# Configuration
HA_HOST="${HA_HOST:-root@homeassistant.local}"
OUTPUT_FILE=""
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

# Parse arguments
if [[ "$1" == "--output" ]] && [[ -n "$2" ]]; then
    OUTPUT_FILE="$2"
fi

# Function to print section header
print_section() {
    echo ""
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo ""
}

# Function to run command and handle errors
run_diagnostic() {
    local description="$1"
    local command="$2"
    
    echo -e "${COLOR_YELLOW}${description}${COLOR_RESET}"
    if ssh "${HA_HOST}" "${command}" 2>&1; then
        echo -e "${COLOR_GREEN}✓ Success${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}✗ Failed${COLOR_RESET}"
    fi
    echo ""
}

# Start diagnostics
exec > >(tee -a "${OUTPUT_FILE:-/dev/null}")
exec 2>&1

echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}Home Assistant Diagnostics Report${COLOR_RESET}"
echo -e "${COLOR_BLUE}Generated: $(date)${COLOR_RESET}"
echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"

# Check connectivity
print_section "1. Connectivity Check"
if ! ssh -o ConnectTimeout=5 "${HA_HOST}" "exit" 2>/dev/null; then
    echo -e "${COLOR_RED}✗ Cannot connect to ${HA_HOST}${COLOR_RESET}"
    exit 1
fi
echo -e "${COLOR_GREEN}✓ SSH connection successful${COLOR_RESET}"

# System Information
print_section "2. System Information"
run_diagnostic "Home Assistant Core Info:" \
    "ha core info"

run_diagnostic "Supervisor Info:" \
    "ha supervisor info"

run_diagnostic "Host Info:" \
    "ha host info"

run_diagnostic "OS Info:" \
    "ha os info"

# Running Services
print_section "3. Running Add-ons"
run_diagnostic "List of installed add-ons:" \
    "ha addons"

run_diagnostic "Add-on status:" \
    "ha addons info"

# Integration Status
print_section "4. Integration Status"
run_diagnostic "Core state:" \
    "ha core stats"

echo -e "${COLOR_YELLOW}Checking integrations in configuration...${COLOR_RESET}"
ssh "${HA_HOST}" "grep -E '^[a-z_]+:' /homeassistant/config/configuration.yaml | sort | uniq" 2>/dev/null || echo "Could not read configuration.yaml"
echo ""

# Database Status
print_section "5. Database Status"
run_diagnostic "Database size:" \
    "du -sh /homeassistant/config/home-assistant_v2.db 2>/dev/null || echo 'Database file not found'"

run_diagnostic "Database record counts:" \
    "sqlite3 /homeassistant/config/home-assistant_v2.db 'SELECT COUNT(*) as states_count FROM states;' 2>/dev/null || echo 'Cannot query database'"

# System Resources
print_section "6. System Resources"
run_diagnostic "Memory usage:" \
    "free -h"

run_diagnostic "Disk usage:" \
    "df -h"

run_diagnostic "CPU info:" \
    "cat /proc/cpuinfo | grep -E '(model name|processor)' | head -5"

run_diagnostic "Top processes:" \
    "ps aux --sort=-%mem | head -10"

# Network Status
print_section "7. Network Status"
run_diagnostic "Network interfaces:" \
    "ip addr show"

run_diagnostic "DNS resolution:" \
    "cat /etc/resolv.conf"

run_diagnostic "Active connections:" \
    "netstat -tuln | grep LISTEN | head -10"

# Recent Errors
print_section "8. Recent Errors in Logs"
run_diagnostic "Last 50 error lines from Core logs:" \
    "ha core logs | grep -i error | tail -50"

run_diagnostic "Last 20 warning lines from Core logs:" \
    "ha core logs | grep -i warning | tail -20"

# Configuration Validation
print_section "9. Configuration Validation"
run_diagnostic "Validate current configuration:" \
    "ha core check"

# Summary
print_section "10. Diagnostic Summary"

echo -e "${COLOR_GREEN}Diagnostics collection complete!${COLOR_RESET}"
echo ""

if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "${COLOR_GREEN}✓ Report saved to: ${OUTPUT_FILE}${COLOR_RESET}"
    echo ""
fi

echo -e "${COLOR_YELLOW}Recommendations:${COLOR_RESET}"
echo "  1. Review error logs for recurring issues"
echo "  2. Check disk space (should be >10% free)"
echo "  3. Monitor memory usage (should be <80%)"
echo "  4. Verify all integrations loaded successfully"
echo "  5. Run 'ha core check' before making changes"
echo ""

echo -e "${COLOR_BLUE}Common next steps:${COLOR_RESET}"
echo "  - View full logs: ssh ${HA_HOST} 'ha core logs -f'"
echo "  - Restart core: ssh ${HA_HOST} 'ha core restart'"
echo "  - Update system: ssh ${HA_HOST} 'ha update'"
echo ""
