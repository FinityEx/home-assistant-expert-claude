#!/usr/bin/env bash
# backup_config.sh
# Backs up Home Assistant configuration files
# Usage: ./backup_config.sh [--local-dir /path/to/backups]

set -e

# Configuration
HA_HOST="${HA_HOST:-root@homeassistant.local}"
SSH_OPTS="-o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2"
SCP_OPTS="-o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2"
LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:-./ha_backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ha_config_${TIMESTAMP}"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

# Parse arguments
if [[ "$1" == "--local-dir" ]] && [[ -n "$2" ]]; then
    LOCAL_BACKUP_DIR="$2"
fi

echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}Home Assistant Configuration Backup${COLOR_RESET}"
echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
echo ""

# Create local backup directory
echo -e "${COLOR_BLUE}[1/5] Creating local backup directory...${COLOR_RESET}"
mkdir -p "${LOCAL_BACKUP_DIR}"
echo -e "${COLOR_GREEN}✓ Directory: ${LOCAL_BACKUP_DIR}${COLOR_RESET}"
echo ""

# Check SSH connectivity
echo -e "${COLOR_BLUE}[2/5] Checking SSH connectivity...${COLOR_RESET}"
if ! ssh ${SSH_OPTS} "${HA_HOST}" "exit" 2>/dev/null; then
    echo -e "${COLOR_RED}✗ Cannot connect to ${HA_HOST}${COLOR_RESET}"
    exit 1
fi
echo -e "${COLOR_GREEN}✓ SSH connection successful${COLOR_RESET}"
echo ""

# Create remote backup
echo -e "${COLOR_BLUE}[3/5] Creating backup on Home Assistant...${COLOR_RESET}"
echo -e "${COLOR_YELLOW}Backing up configuration files...${COLOR_RESET}"

# Create temporary backup directory on remote
ssh ${SSH_OPTS} "${HA_HOST}" "mkdir -p /tmp/${BACKUP_NAME}"

# Copy essential configuration files
FILES_TO_BACKUP=(
    "configuration.yaml"
    "automations.yaml"
    "scripts.yaml"
    "scenes.yaml"
    "secrets.yaml"
    "customize.yaml"
    "groups.yaml"
    "recorder.yaml"
    "ui-lovelace.yaml"
    ".storage/lovelace"
    ".storage/core.config_entries"
    ".storage/core.entity_registry"
    ".storage/core.device_registry"
)

echo "Copying files:"
for file in "${FILES_TO_BACKUP[@]}"; do
    if ssh ${SSH_OPTS} "${HA_HOST}" "test -e /homeassistant/config/${file}"; then
        echo "  ✓ ${file}"
        ssh ${SSH_OPTS} "${HA_HOST}" "mkdir -p /tmp/${BACKUP_NAME}/$(dirname ${file}) && cp -r /homeassistant/config/${file} /tmp/${BACKUP_NAME}/${file}" 2>/dev/null || true
    else
        echo "  - ${file} (not found)"
    fi
done

# Backup custom_components and packages if they exist
for dir in "custom_components" "packages" "themes" "www"; do
    if ssh ${SSH_OPTS} "${HA_HOST}" "test -d /homeassistant/config/${dir}"; then
        echo "  ✓ ${dir}/ (directory)"
        ssh ${SSH_OPTS} "${HA_HOST}" "cp -r /homeassistant/config/${dir} /tmp/${BACKUP_NAME}/"
    fi
done

echo ""

# Create tarball
echo -e "${COLOR_BLUE}[4/5] Creating archive...${COLOR_RESET}"
ssh ${SSH_OPTS} "${HA_HOST}" "cd /tmp && tar czf ${BACKUP_NAME}.tar.gz ${BACKUP_NAME}"
echo -e "${COLOR_GREEN}✓ Archive created${COLOR_RESET}"
echo ""

# Download backup
echo -e "${COLOR_BLUE}[5/5] Downloading backup...${COLOR_RESET}"
scp ${SCP_OPTS} "${HA_HOST}:/tmp/${BACKUP_NAME}.tar.gz" "${LOCAL_BACKUP_DIR}/"
echo -e "${COLOR_GREEN}✓ Backup downloaded to: ${LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz${COLOR_RESET}"
echo ""

# Cleanup remote files
echo -e "${COLOR_YELLOW}Cleaning up remote files...${COLOR_RESET}"
ssh ${SSH_OPTS} "${HA_HOST}" "rm -rf /tmp/${BACKUP_NAME} /tmp/${BACKUP_NAME}.tar.gz"
echo -e "${COLOR_GREEN}✓ Cleanup complete${COLOR_RESET}"
echo ""

# Calculate backup size
BACKUP_SIZE=$(du -h "${LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
echo -e "${COLOR_GREEN}✓ Backup completed successfully${COLOR_RESET}"
echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
echo ""
echo "Backup details:"
echo "  File: ${BACKUP_NAME}.tar.gz"
echo "  Size: ${BACKUP_SIZE}"
echo "  Location: ${LOCAL_BACKUP_DIR}/"
echo ""

# List recent backups
echo -e "${COLOR_BLUE}Recent backups in ${LOCAL_BACKUP_DIR}/:${COLOR_RESET}"
ls -lht "${LOCAL_BACKUP_DIR}"/ha_config_*.tar.gz 2>/dev/null | head -5 || echo "  No previous backups found"
echo ""

# Provide restoration instructions
echo -e "${COLOR_YELLOW}To restore this backup:${COLOR_RESET}"
echo "  1. Extract: tar xzf ${LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "  2. Review files in ${BACKUP_NAME}/"
echo "  3. Copy files to HA: scp -r ${BACKUP_NAME}/* ${HA_HOST}:/homeassistant/config/"
echo "  4. Validate: ssh ${HA_HOST} 'ha core check'"
echo "  5. Restart: ssh ${HA_HOST} 'ha core restart'"
echo ""

# Cleanup old backups (keep last 10)
echo -e "${COLOR_YELLOW}Managing backup retention...${COLOR_RESET}"
BACKUP_COUNT=$(ls -1 "${LOCAL_BACKUP_DIR}"/ha_config_*.tar.gz 2>/dev/null | wc -l)
if [[ ${BACKUP_COUNT} -gt 10 ]]; then
    echo "Found ${BACKUP_COUNT} backups, removing oldest to keep last 10..."
    ls -1t "${LOCAL_BACKUP_DIR}"/ha_config_*.tar.gz | tail -n +11 | xargs rm -f
    echo -e "${COLOR_GREEN}✓ Old backups cleaned up${COLOR_RESET}"
else
    echo "Keeping all ${BACKUP_COUNT} backups (less than 10)"
fi
echo ""

echo -e "${COLOR_BLUE}Backup process complete!${COLOR_RESET}"
