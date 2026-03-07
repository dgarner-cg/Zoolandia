#!/bin/bash
################################################################################
# Zoolandia v5.10 - Homepage Module
#
# Description: Welcome screen and homepage functions
################################################################################

# Show homepage/welcome screen
show_homepage() {
    # Check if user has opted to hide the welcome screen
    local hide_welcome_file="$ZOOLANDIA_CONFIG_DIR/hide_welcome"

    if [[ -f "$hide_welcome_file" ]]; then
        # User has chosen not to show this screen again
        return 0
    fi

    # Show dialog with extra button for "Don't show again"
    dialog --colors --backtitle "$SCRIPT_NAME by http://hack3r.gg - v$ZOOLANDIA_VERSION" \
        --title "Welcome to Zoolandia" \
        --ok-label "Continue" \
        --extra-button \
        --extra-label "Don't show again" \
        --msgbox "\n\Zb\Z4Make managing your Homelab a breeze\Zn\n\n\
We are a community-driven initiative that simplifies the setup\n\
of your Docker Homelab Environment.\n\n\
With \Zb145+ applications\Zn to help you manage your homelab,\n\
whether you're a seasoned user or a newcomer,\n\
we've got you covered.\n\n\
\Zb\Z2Features:\Zn\n\
• Quick Search (Press 's' in main menu or Ctrl+K)\n\
• 145+ Pre-configured Applications\n\
• Automated Setup & Configuration\n\
• Traefik Reverse Proxy Integration\n\
• Built-in Security Tools\n\
• Backup & Recovery Tools\n\n\
Press OK to continue to the main menu..." 24 70 || local exit_status=$?

    # If user pressed "Don't show again" (exit status 3 for extra button)
    if [[ ${exit_status:-0} -eq 3 ]]; then
        mkdir -p "$ZOOLANDIA_CONFIG_DIR"
        touch "$hide_welcome_file"
    fi

    # Always return 0 to continue execution
    return 0
}

# Check if running as root (but don't require it immediately)
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warning "Some features will require root privileges."
        log_info "You will be asked for sudo password when needed."
        return 0
    else
        log_success "Running with root privileges"
        return 0
    fi
}

# Check version
check_version() {
    log_info "Version Check"
    echo ""
    local latest_version

    # Try to fetch latest version from the repository
    latest_version=$(curl -fsSL "https://raw.githubusercontent.com/SimpleHomelab/Zoolandia/main/latest-version" 2>/dev/null | tr -d '[:space:]' || echo "")

    # If fetch failed or returned HTML, skip version check
    if [[ -z "$latest_version" ]] || [[ "$latest_version" == *"<"* ]] || [[ "$latest_version" == *"DOCTYPE"* ]]; then
        log_success "You are running version: $ZOOLANDIA_VERSION"
    elif [[ "$latest_version" == "$ZOOLANDIA_VERSION" ]]; then
        log_success "You are running latest version of the script: $ZOOLANDIA_VERSION"
    else
        log_warning "A newer version ($latest_version) is available. You are running $ZOOLANDIA_VERSION"
    fi
    echo ""
}

# Create necessary directories
create_directories() {
    mkdir -p "$ZOOLANDIA_CONFIG_DIR"
    mkdir -p "$ZOOLANDIA_CACHE_DIR"
    mkdir -p "$DOCKER_DIR"
    mkdir -p "$SECRETS_DIR"
    mkdir -p "$BACKUP_DIR"
}

# Load configuration
load_config() {
    local config_file="$ZOOLANDIA_CONFIG_DIR/zoolandia.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi

    # Check state files
    if [[ -f "$ZOOLANDIA_CONFIG_DIR/prerequisites_done" ]]; then
        PREREQUISITES_DONE=true
    fi
    if [[ -f "$ZOOLANDIA_CONFIG_DIR/docker_setup_done" ]]; then
        DOCKER_SETUP_DONE=true
    fi
    if [[ -f "$ZOOLANDIA_CONFIG_DIR/socket_proxy_done" ]]; then
        SOCKET_PROXY_DONE=true
    fi
    if [[ -f "$ZOOLANDIA_CONFIG_DIR/traefik_done" ]]; then
        TRAEFIK_DONE=true
    fi

    return 0
}

# Save configuration
save_config() {
    cat > "$ZOOLANDIA_CONFIG_DIR/zoolandia.conf" << EOF
DOCKER_DIR="$DOCKER_DIR"
BACKUP_DIR="$BACKUP_DIR"
CURRENT_USER="$CURRENT_USER"
SYSTEM_TYPE="$SYSTEM_TYPE"
SETUP_MODE="$SETUP_MODE"
SERVER_IP="$SERVER_IP"
DOMAIN_1="$DOMAIN_1"
VPN_NETWORK_ADAPTER="$VPN_NETWORK_ADAPTER"
MEDIA_FOLDER="$MEDIA_FOLDER"
DOWNLOADS_FOLDER="$DOWNLOADS_FOLDER"
DATA_FOLDER="$DATA_FOLDER"
SMTP_HOST="$SMTP_HOST"
SMTP_PORT="$SMTP_PORT"
SMTP_USER="$SMTP_USER"
SMTP_PASS="$SMTP_PASS"
SMTP_FROM="$SMTP_FROM"
TELEMETRY_ENABLED="$TELEMETRY_ENABLED"
SHOW_INTRO_MESSAGES="$SHOW_INTRO_MESSAGES"
ZOOLANDIA_MODE="$ZOOLANDIA_MODE"
EOF
}
