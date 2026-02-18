#!/usr/bin/env bash
# validate_yaml.sh
# Validates Home Assistant configuration via SSH
# Usage: ./validate_yaml.sh [--restart]

set -e

# Configuration
HA_HOST="${HA_HOST:-root@homeassistant.local}"
SSH_OPTS="-o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

# Parse arguments
RESTART=false
if [[ "$1" == "--restart" ]]; then
    RESTART=true
fi

echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}Home Assistant Configuration Validator${COLOR_RESET}"
echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
echo ""

# Check SSH connectivity
echo -e "${COLOR_BLUE}[1/4] Checking SSH connectivity to ${HA_HOST}...${COLOR_RESET}"
if ! ssh ${SSH_OPTS} "${HA_HOST}" "exit" 2>/dev/null; then
    echo -e "${COLOR_RED}✗ Cannot connect to ${HA_HOST}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Make sure:${COLOR_RESET}"
    echo "  - SSH is enabled in Home Assistant"
    echo "  - The host is reachable: ${HA_HOST}"
    echo "  - SSH keys or password authentication is configured"
    exit 1
fi
echo -e "${COLOR_GREEN}✓ SSH connection successful${COLOR_RESET}"
echo ""

# Get Home Assistant info
echo -e "${COLOR_BLUE}[2/4] Getting Home Assistant version...${COLOR_RESET}"
HA_INFO=$(ssh ${SSH_OPTS} "${HA_HOST}" "ha core info --raw-json" 2>/dev/null || echo "{}")
HA_VERSION=$(echo "${HA_INFO}" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
echo -e "${COLOR_GREEN}✓ Home Assistant version: ${HA_VERSION}${COLOR_RESET}"
echo ""

# Validate configuration
echo -e "${COLOR_BLUE}[3/4] Validating Home Assistant configuration...${COLOR_RESET}"
echo -e "${COLOR_YELLOW}Running: ha core check${COLOR_RESET}"
echo ""

VALIDATION_OUTPUT=$(ssh ${SSH_OPTS} "${HA_HOST}" "ha core check" 2>&1 || true)
echo "${VALIDATION_OUTPUT}"
echo ""

# Parse validation result
if echo "${VALIDATION_OUTPUT}" | grep -q "Configuration valid"; then
    echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}✓ Configuration is VALID${COLOR_RESET}"
    echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
    echo ""
    
    # Check for warnings
    if echo "${VALIDATION_OUTPUT}" | grep -qi "warning"; then
        echo -e "${COLOR_YELLOW}⚠ Warnings detected in output above${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Review warnings before proceeding${COLOR_RESET}"
        echo ""
    fi
    
    # Offer to restart if requested
    if [[ "$RESTART" == "true" ]]; then
        echo -e "${COLOR_BLUE}[4/4] Restarting Home Assistant Core...${COLOR_RESET}"
        ssh ${SSH_OPTS} "${HA_HOST}" "ha core restart"
        echo -e "${COLOR_GREEN}✓ Restart initiated${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Home Assistant will be unavailable for 30-60 seconds${COLOR_RESET}"
        echo ""
        echo "Monitor restart with:"
        echo "  ssh ${HA_HOST} 'ha core logs -f'"
    else
        echo -e "${COLOR_BLUE}[4/4] Skipping restart${COLOR_RESET}"
        echo ""
        echo "To restart Home Assistant:"
        echo "  ./validate_yaml.sh --restart"
        echo "Or manually:"
        echo "  ssh ${HA_HOST} 'ha core restart'"
    fi
    
    exit 0
else
    echo -e "${COLOR_RED}========================================${COLOR_RESET}"
    echo -e "${COLOR_RED}✗ Configuration is INVALID${COLOR_RESET}"
    echo -e "${COLOR_RED}========================================${COLOR_RESET}"
    echo ""
    
    echo -e "${COLOR_YELLOW}Common fixes:${COLOR_RESET}"
    echo "  1. Check YAML indentation (2 spaces, no tabs)"
    echo "  2. Verify entity_id values exist"
    echo "  3. Check for typos in integration names"
    echo "  4. Ensure all referenced files exist"
    echo "  5. Validate secrets are defined in secrets.yaml"
    echo ""
    
    echo -e "${COLOR_YELLOW}To debug:${COLOR_RESET}"
    echo "  ssh ${HA_HOST} 'ha core logs'"
    echo "  ssh ${HA_HOST} 'cat /homeassistant/config/configuration.yaml'"
    echo ""
    
    exit 1
fi
