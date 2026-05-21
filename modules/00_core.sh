#!/bin/bash
################################################################################
# Nexus v6.1.3 - Core Module
#
# Description: Core variables, configuration, and utility functions
# This module is sourced first and provides foundation for all other modules
################################################################################

# Script version
NEXUS_VERSION="6.1.3"
SCRIPT_NAME="Nexus"

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
NEXUS_CONFIG_DIR="${HOME}/.config/nexus"
NEXUS_CACHE_DIR="/var/tmp/nexus"

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
NEXUS_MODE="${NEXUS_MODE:-NORMAL}"

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
NX_PROJECT_CONFIG_DIR="${SCRIPT_DIR}/.config"

# Load saved GitHub username if exists
if [[ -f "${NX_PROJECT_CONFIG_DIR}/github" ]]; then
    GITHUB_USERNAME=$(cat "${NX_PROJECT_CONFIG_DIR}/github" 2>/dev/null)
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

 ██████   █████                                  █████████ 
▒▒██████ ▒▒███                                  ███▒▒▒▒▒███
 ▒███▒███ ▒███   ██████  █████ █████ █████ ████▒███    ▒▒▒ 
 ▒███▒▒███▒███  ███▒▒███▒▒███ ▒▒███ ▒▒███ ▒███ ▒▒█████████ 
 ▒███ ▒▒██████ ▒███████  ▒▒▒█████▒   ▒███ ▒███  ▒▒▒▒▒▒▒▒███
 ▒███  ▒▒█████ ▒███▒▒▒    ███▒▒▒███  ▒███ ▒███  ███    ▒███
 █████  ▒▒█████▒▒██████  █████ █████ ▒▒████████▒▒█████████ 
▒▒▒▒▒    ▒▒▒▒▒  ▒▒▒▒▒▒  ▒▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒  
https://hack3r.gg                              by: D.Garner

EOF
    echo ""
}

# Display splash screen with timeout
display_splash() {
    clear
    cat << "EOF"

 ██████   █████                                  █████████ 
▒▒██████ ▒▒███                                  ███▒▒▒▒▒███
 ▒███▒███ ▒███   ██████  █████ █████ █████ ████▒███    ▒▒▒ 
 ▒███▒▒███▒███  ███▒▒███▒▒███ ▒▒███ ▒▒███ ▒███ ▒▒█████████ 
 ▒███ ▒▒██████ ▒███████  ▒▒▒█████▒   ▒███ ▒███  ▒▒▒▒▒▒▒▒███
 ▒███  ▒▒█████ ▒███▒▒▒    ███▒▒▒███  ▒███ ▒███  ███    ▒███
 █████  ▒▒█████▒▒██████  █████ █████ ▒▒████████▒▒█████████ 
▒▒▒▒▒    ▒▒▒▒▒  ▒▒▒▒▒▒  ▒▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒  
https://hack3r.gg                              by: D.Garner

      Automated Homelab and Server Deployment System
                  ---Version 6.0.18---

EOF
    echo ""
    echo -e "${CYAN}Press Enter to continue or wait 10 seconds...${NC}"
    echo ""

    # Read with 10 second timeout (|| true prevents script exit on timeout)
    read -t 10 -r || true
}

################################################################################
# Module Integrity Verification
################################################################################
# Hash table is embedded here and regenerated at release time by:
#   ./scripts/nx-update-hashes.sh
#
# To bypass for development: NX_SKIP_INTEGRITY=1 ./nexus.sh
#
# Each entry: "filename|sha256hash"
# Empty hash = not yet locked (skipped). Run nx-update-hashes.sh to lock.

_NX_MODULE_HASHES=(
    "license.sh|6be0afe0aed65bdda30e6c3908b38dc1ae3b3f0cff412c136568dfa9d1a3c508"
    "01_homepage.sh|28417ed882153287290f385786756b2616790ffd3424b8c66c7b678d6e7b9925"
    "02_main_menu.sh|e07277551f78a75157c41b37ebf7bfc5c847836739a89037f28fbc2fbcff13ba"
    "10_prerequisites.sh|3b11e7b234216379d951f714d8665d6d27852a943e4e675ed191ba7f45813cdb"
    "11_system.sh|adb00e7f9d605f77b376f47b52c3f0dc012d87b100ff3c2b3c18430870bf6792"
    "12_docker.sh|c7506a756ca826129f71035a9c46d68508afefbe08827ae989bfa578e0124921"
    "13_reverse_proxy.sh|4b81996d3e2a39fbebc80ccc1c882fabd7a128b6694d1b8f492936b5fbe1e6a5"
    "14_security.sh|d634243d0cd51b37cd4d6b811cce84d70444f795eef46b6c7ab1ca1598cb7ebb"
    "20_apps.sh|14f6ef2ce6da5a4ef68324c7161217a16b8bc9801fc5f36b977c0bef1418664a"
    "21_docker_apps.sh|b4c5116b493425108c3f1a7fe6199f370f34d7a4ffcebdb4e0ec80360c6f7c40"
    "22_system_apps.sh|7376b6794aa2259adbc270b984bd6bf76c2c47f5fc3a4e58b167a1c42da0ca1c"
    "30_tools.sh|a7d682e74722045c342f540e7ca659837084e7df9cb50f8ebdd6355e736def0b"
    "31_backup.sh|62c1d14150967efb804c268621abbcbe46360eb8dd80fa18243ef370a9ee49db"
    "40_settings.sh|dcb20ccf90e8c70c381ef2463868ea183b7061ddc7c6e10a4b217f83c10f681b"
    "41_ansible.sh|1e1fbbb752b3f2b6bcfd4ec9477cef1417765819e0d71a0dc5fffe64a0896927"
    "50_about.sh|06d319df6117e692e1f1ecbb4878bbbbbd91e792e22c53346e437a2a87bc8098"
    "60_personal.sh|bad5c65e0f0ba9e590e964ffb60603cc5ad8de59264da72fa39f560e86d055f4"
)

_nx_verify_integrity() {
    [[ "${NX_SKIP_INTEGRITY:-0}" == "1" ]] && return 0

    local dir="${SCRIPT_DIR}/modules"
    local fail=0

    for entry in "${_NX_MODULE_HASHES[@]}"; do
        local file="${entry%%|*}"
        local expected="${entry##*|}"

        # Skip unlocked entries (empty hash = development mode)
        [[ -z "$expected" ]] && continue

        local actual
        actual=$(sha256sum "${dir}/${file}" 2>/dev/null | awk '{print $1}')

        if [[ "$actual" != "$expected" ]]; then
            echo "Nexus: integrity check failed — modules/${file} has been modified." >&2
            (( fail++ )) || true
        fi
    done

    if [[ $fail -gt 0 ]]; then
        echo "Nexus: $fail module(s) failed integrity check." >&2
        echo "       If you are a developer, run: NX_SKIP_INTEGRITY=1 ./nexus.sh" >&2
        echo "       To re-lock hashes after changes: ./scripts/nx-update-hashes.sh" >&2
        exit 1
    fi
}
