#!/bin/bash
################################################################################
# Zoolandia v6.1.3 - Core Module
#
# Description: Core variables, configuration, and utility functions
# This module is sourced first and provides foundation for all other modules
################################################################################

# Script version
ZOOLANDIA_VERSION="6.1.3"
SCRIPT_NAME="Zoolandia"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Adjust SCRIPT_DIR if we're in modules subdirectory
if [[ "$(basename "$SCRIPT_DIR")" == "modules" ]]; then
    SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
fi
ZOOLANDIA_CONFIG_DIR="${HOME}/.config/zoolandia"
ZOOLANDIA_CACHE_DIR="/var/tmp/zoolandia"

# Helper function to convert absolute paths to display-friendly relative paths
display_path() {
    local path="$1"

    # Replace home directory with ~
    if [[ "$path" == "$HOME"* ]]; then
        echo "~${path#$HOME}"
    # Replace script directory with ./
    elif [[ "$path" == "$SCRIPT_DIR"* ]]; then
        echo ".${path#$SCRIPT_DIR}"
    else
        echo "$path"
    fi
}

# User preferences and settings
TELEMETRY_ENABLED="${TELEMETRY_ENABLED:-minimum}"
SHOW_INTRO_MESSAGES="${SHOW_INTRO_MESSAGES:-ON}"
ZOOLANDIA_MODE="${ZOOLANDIA_MODE:-NORMAL}"

# Default directories
DEFAULT_DOCKER_DIR="${HOME}/docker"
DOCKER_DIR="${DEFAULT_DOCKER_DIR}"
BACKUP_DIR="${HOME}/docker-backups"

# Configuration files
ENV_FILE="${DOCKER_DIR}/.env"
COMPOSE_FILE="${DOCKER_DIR}/docker-compose.yml"
SECRETS_DIR="${DOCKER_DIR}/secrets"

# System information
HOSTNAME=$(hostname)
CURRENT_USER=${SUDO_USER:-$(whoami)}
if [[ -n "$CURRENT_USER" ]] && id "$CURRENT_USER" &>/dev/null; then
    CURRENT_UID=$(id -u "${CURRENT_USER}")
    CURRENT_GID=$(id -g "${CURRENT_USER}")
else
    CURRENT_UID=$(id -u)
    CURRENT_GID=$(id -g)
fi
# Alias for compatibility
PRIMARY_USERNAME="$CURRENT_USER"

# State tracking
PREREQUISITES_DONE=false
DOCKER_SETUP_DONE=false
SOCKET_PROXY_DONE=false
TRAEFIK_DONE=false
DOMAIN_CHECKS_DONE=false

# Setup configuration
SETUP_MODE="Local"
SERVER_IP=""
DOMAIN_1=""
GITHUB_USERNAME=""

# Project-local config directory (gitignored) — stores non-sensitive runtime config
ZL_PROJECT_CONFIG_DIR="${SCRIPT_DIR}/.config"

# Load saved GitHub username if exists
if [[ -f "${ZL_PROJECT_CONFIG_DIR}/github" ]]; then
    GITHUB_USERNAME=$(cat "${ZL_PROJECT_CONFIG_DIR}/github" 2>/dev/null)
fi

################################################################################
# System Detection Functions
################################################################################

# System type detection
detect_system_type() {
    # Auto-detect system type based on hardware characteristics
    local sys_type="Barebones"

    # Check if running in LXC container
    if grep -qi "lxc" /proc/1/cgroup 2>/dev/null; then
        # Check if privileged (can see /proc/sysrq-trigger or has CAP_SYS_ADMIN)
        if [ -w /proc/sysrq-trigger ] 2>/dev/null || capsh --print 2>/dev/null | grep -q "cap_sys_admin"; then
            sys_type="Privileged LXC"
        else
            sys_type="Unprivileged LXC"
        fi
    # Check if running in a VM/Hypervisor
    elif grep -qi "hypervisor\|vmware\|virtualbox\|kvm\|qemu\|xen" /proc/cpuinfo 2>/dev/null; then
        sys_type="Virtual Machine"
    # Check if running in WSL
    elif grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        sys_type="Virtual Machine"
    # Check for VPS indicators (cloud providers)
    elif grep -qiE "amazon|google|azure|digitalocean|linode|vultr|ovh" /sys/class/dmi/id/sys_vendor 2>/dev/null || \
         grep -qiE "amazon|google|azure|digitalocean|linode|vultr|ovh" /sys/class/dmi/id/product_name 2>/dev/null; then
        sys_type="VPS"
    fi

    echo "$sys_type"
}

# Initialize system type
SYSTEM_TYPE="${SYSTEM_TYPE:-$(detect_system_type)}"

################################################################################
# Utility Functions
################################################################################

# Log message with timestamp
log_info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Display banner
display_banner() {
    clear
    cat << "EOF"

 ███████╗ ██████╗  ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ ██╗ █████╗
 ╚══███╔╝██╔═══██╗██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗██║██╔══██╗
   ███╔╝ ██║   ██║██║   ██║██║     ███████║██╔██╗ ██║██║  ██║██║███████║
  ███╔╝  ██║   ██║██║   ██║██║     ██╔══██║██║╚██╗██║██║  ██║██║██╔══██║
 ███████╗╚██████╔╝╚██████╔╝███████╗██║  ██║██║ ╚████║██████╔╝██║██║  ██║
 ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═╝

                         by D.Garner -  http://hack3r.gg

EOF
    echo ""
}

# Display splash screen with timeout
display_splash() {
    clear
    cat << "EOF"

 ███████╗ ██████╗  ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ ██╗ █████╗
 ╚══███╔╝██╔═══██╗██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗██║██╔══██╗
   ███╔╝ ██║   ██║██║   ██║██║     ███████║██╔██╗ ██║██║  ██║██║███████║
  ███╔╝  ██║   ██║██║   ██║██║     ██╔══██║██║╚██╗██║██║  ██║██║██╔══██║
 ███████╗╚██████╔╝╚██████╔╝███████╗██║  ██║██║ ╚████║██████╔╝██║██║  ██║
 ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═╝

                         by D.Garner -  http://hack3r.gg

                   Automated Docker Homelab Deployment System
                              Version 6.0.18

EOF
    echo ""
    echo -e "${CYAN}Press Enter to continue or wait 10 seconds...${NC}"
    echo ""

    # Read with 10 second timeout (|| true prevents script exit on timeout)
    read -t 10 -r || true
}
