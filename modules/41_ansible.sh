#!/bin/bash
################################################################################
# Zoolandia v5.10 - Ansible Module
#
# Description: Ansible menu for system configuration and automation tasks
################################################################################

# Paths
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
ANSIBLE_CONFIG_FILE="/tmp/ansible_workstation_config.yml"
ANSIBLE_PLAYBOOK="$ANSIBLE_DIR/workstations.yml"

################################################################################
# Helper Functions (from ansible-menu.sh)
################################################################################

detect_installed_apps() {
    local installed_apps=""

    # Resolve actual user's home dir (Zoolandia runs as root; user home differs)
    local _user_home
    _user_home=$(getent passwd "${CURRENT_USER:-$USER}" | cut -d: -f6 2>/dev/null || echo "$HOME")

    # Check snap apps via filesystem (reliable regardless of whether running as root)
    [ -d "/snap/vivaldi" ]               && installed_apps+="vivaldi "
    [ -d "/snap/bitwarden" ]             && installed_apps+="bitwarden "
    [ -d "/snap/notepad-plus-plus" ]     && installed_apps+="notepad "
    [ -d "/snap/notion-snap-reborn" ]    && installed_apps+="notion "
    [ -d "/snap/mailspring" ]            && installed_apps+="mailspring "
    [ -d "/snap/chatgpt-desktop-client" ] && installed_apps+="chatgpt "
    [ -d "/snap/icloud-for-linux" ]      && installed_apps+="icloud "
    [ -d "/snap/obsidian" ]              && installed_apps+="obsidian "

    # Claude Code: npm package (@anthropic-ai/claude-code), binary is 'claude'
    # Check snap dir, global npm (/usr/local/bin), and user-local npm (~/.local/bin)
    { [ -d "/snap/claude-code" ] || [ -f "/usr/local/bin/claude" ] || [ -f "${_user_home}/.local/bin/claude" ]; } \
        && installed_apps+="claude-code "

    # Check deb apps
    dpkg -l discord 2>/dev/null | grep -q "^ii" && installed_apps+="discord "
    dpkg -l zoom 2>/dev/null | grep -q "^ii" && installed_apps+="zoom "
    dpkg -l termius 2>/dev/null | grep -q "^ii" && installed_apps+="termius "
    dpkg -l onlyoffice-desktopeditors 2>/dev/null | grep -q "^ii" && installed_apps+="onlyoffice "

    # Check complex apps
    command -v docker &> /dev/null && installed_apps+="docker "
    docker ps -a 2>/dev/null | grep -qi portainer && installed_apps+="portainer "
    command -v twingate &> /dev/null && installed_apps+="twingate "
    command -v protonvpn &> /dev/null && installed_apps+="protonvpn "
    command -v ulauncher &> /dev/null && installed_apps+="ulauncher "
    systemctl --user list-units --all 2>/dev/null | grep -q "n8n" && installed_apps+="n8n "
    command -v subl &> /dev/null && installed_apps+="sublime-text "
    command -v codex &> /dev/null && installed_apps+="codex "
    command -v gemini &> /dev/null && installed_apps+="gemini "

    # Check chrome extensions (use actual user's home, not root's)
    [ -d "${_user_home}/.local/share/chrome-extensions/ai-chat-exporter" ] && installed_apps+="chrome-ext "

    # Check security tools
    systemctl is-active --quiet fail2ban && installed_apps+="fail2ban "
    dpkg -l clamav 2>/dev/null | grep -q "^ii" && installed_apps+="clamav "
    dpkg -l auditd 2>/dev/null | grep -q "^ii" && installed_apps+="auditd "
    systemctl is-active --quiet ufw && installed_apps+="ufw "

    echo "$installed_apps"
}

# Detect installed system configurations
detect_installed_configs() {
    local installed=""

    # Power management
    [ -f /etc/systemd/logind.conf ] && grep -q "HandleLidSwitch" /etc/systemd/logind.conf 2>/dev/null && installed+="power "

    # Touchpad (check if configured via gsettings - role sets click-method to 'fingers')
    if command -v gsettings &>/dev/null; then
        local click_method
        click_method=$(gsettings get org.gnome.desktop.peripherals.touchpad click-method 2>/dev/null | tr -d "'")
        [ "$click_method" = "fingers" ] && installed+="touchpad "
    fi

    # Nautilus (check if configured via gsettings - role sets sort order to 'type')
    if command -v gsettings &>/dev/null; then
        local sort_order
        sort_order=$(gsettings get org.gnome.nautilus.preferences default-sort-order 2>/dev/null | tr -d "'")
        [ "$sort_order" = "type" ] && installed+="nautilus "
    fi

    # Mouse settings (GNOME gsettings)
    command -v gsettings &> /dev/null && gsettings get org.gnome.desktop.peripherals.mouse speed &>/dev/null && installed+="mouse "

    # NTFS support
    dpkg -l ntfs-3g 2>/dev/null | grep -q "^ii" && installed+="ntfs "

    # Razer GRUB config
    [ -f /etc/default/grub ] && grep -q "i915.enable_psr=0" /etc/default/grub 2>/dev/null && installed+="razer "

    echo "$installed"
}

# Detect installed common/server packages
detect_installed_common() {
    local installed=""

    # Essential tools
    command -v git &>/dev/null && installed+="git "
    command -v curl &>/dev/null && installed+="curl "
    command -v wget &>/dev/null && installed+="wget "
    command -v tmux &>/dev/null && installed+="tmux "
    command -v tree &>/dev/null && installed+="tree "
    command -v htop &>/dev/null && installed+="htop "
    command -v gotop &>/dev/null && installed+="gotop "
    command -v jq &>/dev/null && installed+="jq "
    command -v fzf &>/dev/null && installed+="fzf "
    command -v rg &>/dev/null && installed+="ripgrep "
    command -v ncdu &>/dev/null && installed+="ncdu "
    command -v neofetch &>/dev/null && installed+="neofetch "
    command -v bat &>/dev/null && installed+="bat "
    command -v rclone &>/dev/null && installed+="rclone "

    # Network tools
    dpkg -l openssh-server 2>/dev/null | grep -q "^ii" && installed+="openssh-server "
    command -v netstat &>/dev/null && installed+="net-tools "
    command -v dig &>/dev/null && installed+="dnsutils "

    # System monitoring
    command -v glances &>/dev/null && installed+="glances "
    command -v iotop &>/dev/null && installed+="iotop "
    systemctl is-active --quiet netdata && installed+="netdata "

    # Security
    systemctl is-active --quiet ufw && installed+="ufw "
    systemctl is-active --quiet fail2ban && installed+="fail2ban "
    command -v auditd &>/dev/null && installed+="auditd "
    dpkg -l clamav 2>/dev/null | grep -q "^ii" && installed+="clamav "

    # Desktop (workstation only)
    command -v gnome-tweaks &>/dev/null && installed+="gnome-tweaks "
    command -v vlc &>/dev/null && installed+="vlc "

    # Language Runtimes
    command -v go &>/dev/null && installed+="golang "
    command -v node &>/dev/null && installed+="nodejs "
    command -v yarn &>/dev/null && installed+="yarn "

    # Secret Management
    command -v vault &>/dev/null && installed+="vault "

    echo "$installed"
}

# Detect installed web server packages
detect_installed_web() {
    local installed=""

    # Web servers
    systemctl is-active --quiet nginx && installed+="nginx "
    systemctl is-active --quiet apache2 && installed+="apache2 "

    # Reverse proxies / Load balancers
    command -v traefik &>/dev/null && installed+="traefik "
    command -v haproxy &>/dev/null && installed+="haproxy "

    # SSL/TLS
    command -v certbot &>/dev/null && installed+="certbot "

    # PHP
    systemctl is-active --quiet php*-fpm && installed+="php-fpm "

    # Caching
    systemctl is-active --quiet redis-server && installed+="redis-server "
    systemctl is-active --quiet memcached && installed+="memcached "

    echo "$installed"
}

# Detect installed database packages
detect_installed_db() {
    local installed=""

    # SQL Databases
    systemctl is-active --quiet postgresql && installed+="postgresql "
    systemctl is-active --quiet mysql && installed+="mysql "
    systemctl is-active --quiet mariadb && installed+="mariadb "

    # NoSQL
    systemctl is-active --quiet redis-server && installed+="redis "
    systemctl is-active --quiet mongod && installed+="mongodb "

    # Database admin tools (docker)
    docker ps -a 2>/dev/null | grep -q pgadmin && installed+="pgadmin "
    docker ps -a 2>/dev/null | grep -q phpmyadmin && installed+="phpmyadmin "
    docker ps -a 2>/dev/null | grep -q adminer && installed+="adminer "

    # Backup tools
    command -v pgbackrest &>/dev/null && installed+="pgbackrest "

    echo "$installed"
}

# Detect installed monitoring containers
detect_installed_monitoring() {
    local installed=""
    docker ps -a 2>/dev/null | grep -q grafana && installed+="grafana "
    docker ps -a 2>/dev/null | grep -q prometheus && installed+="prometheus "
    docker ps -a 2>/dev/null | grep -q influxdb && installed+="influxdb "
    docker ps -a 2>/dev/null | grep -q telegraf && installed+="telegraf "
    docker ps -a 2>/dev/null | grep -q node-exporter && installed+="node-exporter "
    docker ps -a 2>/dev/null | grep -q cadvisor && installed+="cadvisor "
    docker ps -a 2>/dev/null | grep -q elasticsearch && installed+="elasticsearch "
    docker ps -a 2>/dev/null | grep -q kibana && installed+="kibana "
    echo "$installed"
}

generate_config_from_selections() {
    local selections="$1"

    cat > "$ANSIBLE_CONFIG_FILE" <<EOF
---
################################################################################
# Auto-generated Ansible Configuration
# Generated: $(date -Iseconds)
# Source: Interactive Menu Selection
################################################################################

# User configuration (auto-detected if not set)
# workstation_user: "{{ lookup('env', 'USER') }}"

################################################################################
# SNAP APPLICATIONS
################################################################################

EOF

    # Snap apps - pre-check to avoid null list (bare 'snap_apps:' is null in YAML)
    local has_snap_apps=false
    [[ "$selections" == *"vivaldi"* ]]    && has_snap_apps=true
    [[ "$selections" == *"bitwarden"* ]]  && has_snap_apps=true
    [[ "$selections" == *"notepad"* ]]    && has_snap_apps=true
    [[ "$selections" == *"notion"* ]]     && has_snap_apps=true
    [[ "$selections" == *"mailspring"* ]] && has_snap_apps=true
    [[ "$selections" == *"claude-code"* ]] && has_snap_apps=true
    [[ "$selections" == *"chatgpt"* ]]    && has_snap_apps=true
    [[ "$selections" == *"icloud"* ]]     && has_snap_apps=true

    if $has_snap_apps; then
        echo "snap_apps:" >> "$ANSIBLE_CONFIG_FILE"
        [[ "$selections" == *"vivaldi"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: vivaldi
    enabled: true
    category: browser
    description: "Modern Chromium-based browser"
EOF
        [[ "$selections" == *"bitwarden"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: bitwarden
    enabled: true
    category: security
    description: "Password manager"
EOF
        [[ "$selections" == *"notepad"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: notepad-plus-plus
    enabled: true
    category: development
    description: "Advanced text editor"
EOF
        [[ "$selections" == *"notion"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: notion-snap-reborn
    enabled: true
    category: productivity
    description: "Note-taking and collaboration"
EOF
        [[ "$selections" == *"mailspring"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: mailspring
    enabled: true
    category: communication
    description: "Email client"
EOF
        [[ "$selections" == *"claude-code"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: claude-code
    enabled: true
    category: development
    description: "Claude AI code assistant CLI"
EOF
        [[ "$selections" == *"chatgpt"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: chatgpt-desktop-client
    enabled: true
    category: productivity
    description: "ChatGPT desktop application"
EOF
        [[ "$selections" == *"icloud"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: icloud-for-linux
    enabled: true
    category: cloud
    description: "iCloud integration"
EOF
    else
        echo "snap_apps: []" >> "$ANSIBLE_CONFIG_FILE"
    fi

    # DEB apps - pre-check to avoid null list (bare 'deb_apps:' is null in YAML)
    cat >> "$ANSIBLE_CONFIG_FILE" <<EOF

################################################################################
# DEB PACKAGE APPLICATIONS
################################################################################

EOF

    local has_deb_apps=false
    [[ "$selections" == *"discord"* ]]    && has_deb_apps=true
    [[ "$selections" == *"zoom"* ]]       && has_deb_apps=true
    [[ "$selections" == *"termius"* ]]    && has_deb_apps=true
    [[ "$selections" == *"onlyoffice"* ]] && has_deb_apps=true

    if $has_deb_apps; then
        echo "deb_apps:" >> "$ANSIBLE_CONFIG_FILE"
        [[ "$selections" == *"discord"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: discord
    url: "https://discord.com/api/download?platform=linux&format=deb"
    dest: "/tmp/zoolandia_ansible_downloads/discord.deb"
    enabled: true
    category: communication
    description: "Voice and text chat"
    retries: 3
    timeout: 1200
EOF
        [[ "$selections" == *"zoom"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: zoom
    url: "https://zoom.us/client/latest/zoom_amd64.deb"
    dest: "/tmp/zoolandia_ansible_downloads/zoom_amd64.deb"
    enabled: true
    category: communication
    description: "Video conferencing"
    retries: 3
    timeout: 1200
EOF
        [[ "$selections" == *"termius"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: termius
    url: "https://www.termius.com/download/linux/Termius.deb"
    dest: "/tmp/zoolandia_ansible_downloads/termius.deb"
    enabled: true
    category: development
    description: "SSH client"
    retries: 3
    timeout: 1200
EOF
        [[ "$selections" == *"onlyoffice"* ]] && cat >> "$ANSIBLE_CONFIG_FILE" <<EOF
  - name: onlyoffice
    url: "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
    dest: "/tmp/zoolandia_ansible_downloads/onlyoffice_amd64.deb"
    enabled: true
    category: productivity
    description: "Office suite"
    retries: 3
    timeout: 1200
EOF
    else
        echo "deb_apps: []" >> "$ANSIBLE_CONFIG_FILE"
    fi

    # Complex apps
    cat >> "$ANSIBLE_CONFIG_FILE" <<EOF

################################################################################
# COMPLEX APPLICATIONS
################################################################################

EOF

    if [[ "$selections" == *"docker"* ]]; then
        echo "install_docker: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_docker: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"portainer"* ]]; then
        echo "install_portainer: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_portainer: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"twingate"* ]]; then
        echo "install_twingate: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_twingate: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"protonvpn"* ]]; then
        echo "install_protonvpn: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_protonvpn: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"ulauncher"* ]]; then
        echo "install_ulauncher: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_ulauncher: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"n8n"* ]]; then
        echo "install_n8n: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_n8n: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"obsidian"* ]]; then
        echo "install_obsidian: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_obsidian: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"codex"* ]]; then
        echo "install_codex: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_codex: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"gemini"* ]]; then
        echo "install_gemini: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_gemini: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"chrome-ext"* ]]; then
        echo "install_chrome_extensions: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_chrome_extensions: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    # Security tools - only enable the role when something is explicitly selected
    cat >> "$ANSIBLE_CONFIG_FILE" <<EOF

################################################################################
# SECURITY TOOLS
################################################################################

EOF

    if [[ "$selections" == *"fail2ban"* ]] || [[ "$selections" == *"clamav"* ]] || [[ "$selections" == *"auditd"* ]] || [[ "$selections" == *"ufw"* ]]; then
        echo "install_security: true" >> "$ANSIBLE_CONFIG_FILE"
    else
        echo "install_security: false" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"fail2ban"* ]]; then
        echo "install_fail2ban: true" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"clamav"* ]]; then
        echo "install_clamav: true" >> "$ANSIBLE_CONFIG_FILE"
    fi

    if [[ "$selections" == *"auditd"* ]]; then
        echo "install_auditd: true" >> "$ANSIBLE_CONFIG_FILE"
    fi
}

# Uninstall items that were deselected in the menu
# Usage: run_uninstall_items "item1 item2 item3"
run_uninstall_items() {
    local items="$1"
    local snap_user="${CURRENT_USER:-$USER}"
    local snap_user_home
    snap_user_home=$(getent passwd "$snap_user" | cut -d: -f6 2>/dev/null || echo "$HOME")

    echo ""
    echo "======================================================================="
    echo "Uninstalling deselected items..."
    echo "======================================================================="

    for item in $items; do
        case "$item" in
            vivaldi)
                echo "  Removing snap: vivaldi..."
                sudo -u "$snap_user" snap remove vivaldi 2>/dev/null || true
                ;;
            bitwarden)
                echo "  Removing snap: bitwarden..."
                sudo -u "$snap_user" snap remove bitwarden 2>/dev/null || true
                ;;
            notepad)
                echo "  Removing snap: notepad-plus-plus..."
                sudo -u "$snap_user" snap remove notepad-plus-plus 2>/dev/null || true
                ;;
            notion)
                echo "  Removing snap: notion-snap-reborn..."
                sudo -u "$snap_user" snap remove notion-snap-reborn 2>/dev/null || true
                ;;
            mailspring)
                echo "  Removing snap: mailspring..."
                sudo -u "$snap_user" snap remove mailspring 2>/dev/null || true
                ;;
            claude-code)
                echo "  Removing Claude Code (npm @anthropic-ai/claude-code)..."
                npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
                sudo -u "$snap_user" snap remove claude-code 2>/dev/null || true
                ;;
            chatgpt)
                echo "  Removing snap: chatgpt-desktop-client..."
                sudo -u "$snap_user" snap remove chatgpt-desktop-client 2>/dev/null || true
                ;;
            icloud)
                echo "  Removing snap: icloud-for-linux..."
                sudo -u "$snap_user" snap remove icloud-for-linux 2>/dev/null || true
                ;;
            obsidian)
                echo "  Removing snap: obsidian..."
                sudo -u "$snap_user" snap remove obsidian 2>/dev/null || true
                ;;
            discord)
                echo "  Removing package: discord..."
                apt remove -y discord 2>/dev/null || true
                ;;
            zoom)
                echo "  Removing package: zoom..."
                apt remove -y zoom 2>/dev/null || true
                ;;
            termius)
                echo "  Removing package: termius..."
                apt remove -y termius 2>/dev/null || true
                ;;
            onlyoffice)
                echo "  Removing package: onlyoffice-desktopeditors..."
                apt remove -y onlyoffice-desktopeditors 2>/dev/null || true
                ;;
            portainer)
                echo "  Stopping and removing Portainer container..."
                docker stop portainer 2>/dev/null || true
                docker rm portainer 2>/dev/null || true
                docker volume rm portainer_data 2>/dev/null || true
                ;;
            n8n)
                echo "  Stopping and removing n8n container..."
                docker stop n8n 2>/dev/null || true
                docker rm n8n 2>/dev/null || true
                ;;
            twingate)
                echo "  Removing Twingate..."
                apt remove -y twingate 2>/dev/null || true
                ;;
            protonvpn)
                echo "  Removing ProtonVPN..."
                apt remove -y proton-vpn-gnome-desktop 2>/dev/null || true
                ;;
            ulauncher)
                echo "  Removing Ulauncher..."
                apt remove -y ulauncher 2>/dev/null || true
                ;;
            sublime-text)
                echo "  Removing Sublime Text..."
                apt remove -y sublime-text 2>/dev/null || true
                ;;
            codex)
                echo "  Removing @openai/codex npm package..."
                npm uninstall -g @openai/codex 2>/dev/null || true
                ;;
            gemini)
                echo "  Removing @google/gemini-cli npm package..."
                npm uninstall -g @google/gemini-cli 2>/dev/null || true
                ;;
            chrome-ext)
                echo "  Removing Chrome extensions..."
                rm -rf "${snap_user_home}/.local/share/chrome-extensions/ai-chat-exporter" 2>/dev/null || true
                rm -rf "${snap_user_home}/.local/share/chrome-extensions/gpt-saves" 2>/dev/null || true
                ;;
            fail2ban)
                echo "  Removing fail2ban..."
                sudo systemctl disable --now fail2ban 2>/dev/null || true
                sudo DEBIAN_FRONTEND=noninteractive apt remove -y fail2ban
                ;;
            clamav)
                echo "  Removing ClamAV..."
                sudo systemctl disable --now clamav-daemon clamav-freshclam 2>/dev/null || true
                sudo DEBIAN_FRONTEND=noninteractive apt remove -y clamav clamav-daemon clamav-freshclam
                ;;
            auditd)
                echo "  Removing auditd..."
                sudo systemctl disable --now auditd 2>/dev/null || true
                sudo DEBIAN_FRONTEND=noninteractive apt remove -y auditd audispd-plugins
                ;;
            ufw)
                echo "  Disabling and removing UFW firewall..."
                sudo ufw disable 2>/dev/null || true
                sudo systemctl disable --now ufw 2>/dev/null || true
                sudo DEBIAN_FRONTEND=noninteractive apt remove -y ufw
                ;;
            docker)
                echo "  NOTE: Docker removal skipped (manual step required)"
                echo "        Run: apt remove docker-ce docker-ce-cli containerd.io"
                ;;
            *)
                echo "  NOTE: Uninstall not supported for: $item (skip)"
                ;;
        esac
    done

    echo ""
    echo "======================================================================="
    echo "Uninstall complete."
    echo "======================================================================="
}

# Install everything from all roles
install_all_everything() {
    clear
    echo "======================================================================="
    echo "Installing ALL - Complete System Configuration"
    echo "======================================================================="
    echo ""
    echo "This will install:"
    echo "  - Workstation apps (21 items)"
    echo "  - Common base tools (25+ items)"
    echo "  - Database servers (PostgreSQL, MySQL, Redis, MongoDB)"
    echo "  - Web servers (Nginx, Apache, Traefik, SSL/TLS)"
    echo ""
    echo "WARNING: This is a FULL installation. It may take 30-60 minutes."
    echo ""
    read -p "Press ENTER to continue, or Ctrl+C to cancel..."

    cd "$ANSIBLE_DIR"
    # Run all playbooks
    ansible-playbook "$ANSIBLE_DIR/playbooks/workstation.yml" && \
    ansible-playbook "$ANSIBLE_DIR/playbooks/common.yml" && \
    ansible-playbook "$ANSIBLE_DIR/playbooks/webtier.yml" && \
    ansible-playbook "$ANSIBLE_DIR/playbooks/dbserver.yml"

    local exit_code=$?

    echo ""
    echo "======================================================================="
    if [ $exit_code -eq 0 ]; then
        echo "Complete installation finished successfully!"
    else
        echo "Installation completed with errors (exit code: $exit_code)"
    fi
    echo "======================================================================="
    echo ""
    read -p "Press Enter to continue..." -r
}

# Run Ansible playbook with proper error handling
run_ansible_playbook() {
    local playbook_path="$1"
    local playbook_name="$2"
    local inventory="${3:-$ANSIBLE_DIR/inventories/production/localhost.yml}"

    # Check if Ansible is installed
    if ! command -v ansible-playbook &>/dev/null; then
        dialog --msgbox "Ansible is not installed!\n\nPlease install Ansible first from the menu." 10 60
        return 1
    fi

    # Check if playbook exists
    if [ ! -f "$playbook_path" ]; then
        dialog --msgbox "Error: Playbook not found!\n\nPath: $playbook_path" 10 70
        return 1
    fi

    # Confirm execution
    if ! dialog --yesno "Run Ansible Playbook: $playbook_name?\n\nThis will execute:\n$playbook_path\n\nContinue?" 12 70; then
        return 0
    fi

    # Clear screen and run playbook in terminal (for password prompt)
    clear
    echo "=========================================="
    echo "Ansible Playbook: $playbook_name"
    echo "=========================================="
    echo ""
    echo "Playbook Path: $playbook_path"
    echo "Inventory: $inventory"
    echo ""
    echo "Note: You will be prompted for your sudo password"
    echo "=========================================="
    echo ""

    # Run ansible-playbook with become password prompt
    ansible-playbook -i "$inventory" --ask-become-pass "$playbook_path"

    local exit_code=$?

    echo ""
    echo "=========================================="
    echo "Playbook execution completed (exit code: $exit_code)"
    echo "=========================================="
    echo ""
    read -p "Press Enter to continue..." -r

    return $exit_code
}

################################################################################
# Password Management and Bitwarden Integration
################################################################################

# Generate random password
generate_password() {
    local length="${1:-24}"
    # Generate alphanumeric password with mixed case
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

# Save credentials to file
save_credentials_to_file() {
    local service="$1"
    local username="$2"
    local password="$3"
    local creds_file="$HOME/.zoolandia/credentials.txt"

    # Create directory if it doesn't exist
    mkdir -p "$HOME/.zoolandia"

    # Append credential
    echo "========================================" >> "$creds_file"
    echo "Service: $service" >> "$creds_file"
    echo "Username: $username" >> "$creds_file"
    echo "Password: $password" >> "$creds_file"
    echo "Generated: $(date -Iseconds)" >> "$creds_file"
    echo "" >> "$creds_file"

    # Secure the file
    chmod 600 "$creds_file"

    echo "✓ Saved to: $creds_file"
}

# Install Bitwarden CLI if not present
ensure_bitwarden_cli() {
    if ! command -v bw &>/dev/null; then
        echo "Installing Bitwarden CLI..."
        snap install bw || {
            echo "ERROR: Failed to install Bitwarden CLI"
            return 1
        }
    fi
    return 0
}

# Store credential in Bitwarden
store_in_bitwarden() {
    local service="$1"
    local username="$2"
    local password="$3"
    local folder_name="Zoolandia"

    # Ensure Bitwarden CLI is installed
    ensure_bitwarden_cli || return 1

    # Check if logged in
    if ! bw login --check &>/dev/null; then
        echo ""
        echo "======================================================================="
        echo "Bitwarden Login Required"
        echo "======================================================================="
        echo ""
        read -p "Email: " bw_email
        bw login "$bw_email" || {
            echo "ERROR: Bitwarden login failed"
            return 1
        }
    fi

    # Unlock vault
    echo ""
    echo "Unlocking Bitwarden vault..."
    BW_SESSION=$(bw unlock --raw) || {
        echo "ERROR: Failed to unlock Bitwarden vault"
        return 1
    }
    export BW_SESSION

    # Get or create Zoolandia folder
    local folder_id
    folder_id=$(bw list folders --session "$BW_SESSION" | jq -r ".[] | select(.name==\"$folder_name\") | .id")

    if [ -z "$folder_id" ]; then
        echo "Creating '$folder_name' folder in Bitwarden..."
        folder_id=$(bw get template folder | jq ".name=\"$folder_name\"" | bw encode | bw create folder --session "$BW_SESSION" | jq -r '.id')
    fi

    # Create credential item
    local item_name="Zoolandia $service"
    echo "Storing '$item_name' in Bitwarden..."

    bw get template item | jq \
        --arg folder_id "$folder_id" \
        --arg name "$item_name" \
        --arg username "$username" \
        --arg password "$password" \
        --arg uri "$service://localhost" \
        '.folderId=$folder_id | .type=1 | .name=$name | .login.username=$username | .login.password=$password | .login.uris=[{"match":null,"uri":$uri}]' | \
        bw encode | bw create item --session "$BW_SESSION" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✓ Stored in Bitwarden: $item_name"
        return 0
    else
        echo "✗ Failed to store in Bitwarden"
        return 1
    fi
}

# Store credential in HashiCorp Vault
store_in_vault() {
    local service="$1"
    local username="$2"
    local password="$3"

    # Check if Vault is configured
    if [ -z "$VAULT_ADDR" ]; then
        echo "⊘ Vault not configured (VAULT_ADDR not set)"
        return 1
    fi

    if ! command -v vault &>/dev/null; then
        echo "⊘ Vault CLI not installed"
        return 1
    fi

    # Check if authenticated
    if ! vault token lookup &>/dev/null; then
        echo ""
        echo "Vault authentication required..."
        read -p "Vault Username: " vault_user
        read -sp "Vault Password: " vault_pass
        echo ""

        vault login -method=userpass username="$vault_user" password="$vault_pass" &>/dev/null || {
            echo "✗ Vault authentication failed"
            return 1
        }
    fi

    # Store credential
    local vault_path="secret/zoolandia/${service,,}"
    vault kv put "$vault_path" username="$username" password="$password" &>/dev/null

    if [ $? -eq 0 ]; then
        echo "✓ Stored in Vault: $vault_path"
        return 0
    else
        echo "✗ Failed to store in Vault"
        return 1
    fi
}

# Main credential management function
manage_credential() {
    local service="$1"
    local username="$2"
    local password_length="${3:-24}"

    # Generate password
    local password
    password=$(generate_password "$password_length")

    echo ""
    echo "Generated credentials for $service:"
    echo "  Username: $username"
    echo "  Password: $password"
    echo ""

    # 1. Save to file (ALWAYS)
    save_credentials_to_file "$service" "$username" "$password"

    # 2. Store in Bitwarden (if available)
    if command -v bw &>/dev/null; then
        echo ""
        read -p "Store in Bitwarden vault? (Y/n): " store_bw
        store_bw=${store_bw:-Y}

        if [[ "$store_bw" =~ ^[Yy] ]]; then
            store_in_bitwarden "$service" "$username" "$password"
        fi
    fi

    # 3. Store in Vault (if configured and available)
    if [ -n "$VAULT_ADDR" ] && command -v vault &>/dev/null; then
        echo ""
        read -p "Store in HashiCorp Vault? (Y/n): " store_vault
        store_vault=${store_vault:-Y}

        if [[ "$store_vault" =~ ^[Yy] ]]; then
            store_in_vault "$service" "$username" "$password"
        fi
    fi

    # Return password for use in Ansible vars
    echo "$password"
}

# Show credentials summary at end of installation
show_credentials_summary() {
    local creds_file="$HOME/.zoolandia/credentials.txt"

    if [ -f "$creds_file" ]; then
        echo ""
        echo "======================================================================="
        echo "CREDENTIALS SUMMARY"
        echo "======================================================================="
        echo ""
        echo "All generated credentials have been saved to:"
        echo "  $creds_file"
        echo ""
        echo "This file is secured with permissions 600 (owner read/write only)."
        echo ""
        if command -v bw &>/dev/null && bw login --check &>/dev/null; then
            echo "Credentials were also stored in your Bitwarden vault under the"
            echo "'Zoolandia' folder."
        fi
        echo ""
        echo "======================================================================="
    fi
}

# Workstation menu - Desktop apps and configurations
show_workstation_menu() {
    while true; do
        local installed_apps
        installed_apps=$(detect_installed_apps)

        # Helper function to determine if app is installed
        is_installed() {
            local app="$1"
            [[ " $installed_apps " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible Workstation" \
            --title "Workstation Setup - Select Apps & Configurations" \
            --ok-label "Install" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to install (checkmarks show installed):" 42 80 34 \
            "install-all" "Install All Workstation Apps" OFF \
            "─────────" "── APPLICATIONS ──" OFF \
            "vivaldi" "Vivaldi Browser" $(is_installed "vivaldi") \
            "bitwarden" "Bitwarden Password Manager" $(is_installed "bitwarden") \
            "notepad" "Notepad++ Text Editor" $(is_installed "notepad") \
            "notion" "Notion Productivity App" $(is_installed "notion") \
            "obsidian" "Obsidian Knowledge Base" $(is_installed "obsidian") \
            "mailspring" "Mailspring Email Client" $(is_installed "mailspring") \
            "claude-code" "Claude AI Code Assistant" $(is_installed "claude-code") \
            "chatgpt" "ChatGPT Desktop Client" $(is_installed "chatgpt") \
            "codex" "OpenAI Codex CLI (Node 22 + npm)" $(is_installed "codex") \
            "gemini" "Google Gemini CLI (npm)" $(is_installed "gemini") \
            "icloud" "iCloud for Linux (experimental)" $(is_installed "icloud") \
            "discord" "Discord Communication" $(is_installed "discord") \
            "zoom" "Zoom Video Conferencing" $(is_installed "zoom") \
            "termius" "Termius SSH Client" $(is_installed "termius") \
            "onlyoffice" "OnlyOffice Suite" $(is_installed "onlyoffice") \
            "chrome-ext" "Chrome Extensions (AI Chat Exporter)" $(is_installed "chrome-ext") \
            "docker" "Docker Container Platform" $(is_installed "docker") \
            "portainer" "Portainer Docker Management" $(is_installed "portainer") \
            "twingate" "Twingate VPN Client" $(is_installed "twingate") \
            "protonvpn" "ProtonVPN Client" $(is_installed "protonvpn") \
            "ulauncher" "Ulauncher App Launcher" $(is_installed "ulauncher") \
            "n8n" "n8n Workflow Automation" $(is_installed "n8n") \
            "sublime-text" "Sublime Text Editor" $(is_installed "sublime-text") \
            "─────────" "── SECURITY TOOLS ──" OFF \
            "fail2ban" "Fail2ban Intrusion Prevention" $(is_installed "fail2ban") \
            "clamav" "ClamAV Antivirus" $(is_installed "clamav") \
            "auditd" "Auditd System Auditing" $(is_installed "auditd") \
            "ufw" "UFW Firewall" $(is_installed "ufw") \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Installing All Workstation Applications"
            echo "======================================================================="
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/workstation.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Workstation installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # All items shown in this dialog (used to detect deselections)
            local ws_dialog_items="vivaldi bitwarden notepad notion obsidian mailspring claude-code chatgpt codex gemini icloud discord zoom termius onlyoffice chrome-ext docker portainer twingate protonvpn ulauncher n8n sublime-text fail2ban clamav auditd ufw"

            # Calculate new installs and removals
            local new_items=""
            local to_uninstall=""
            for item in $selections; do
                [[ " $installed_apps " =~ " $item " ]] || new_items+="$item "
            done
            for item in $ws_dialog_items; do
                if [[ " $installed_apps " =~ " $item " ]] && [[ ! " $selections " =~ " $item " ]]; then
                    to_uninstall+="$item "
                fi
            done

            # No changes at all?
            if [ -z "$new_items" ] && [ -z "$to_uninstall" ]; then
                clear
                echo "======================================================================="
                echo "Ansible Workstation - No Changes"
                echo "======================================================================="
                echo ""
                echo "No changes detected. All selected items are already installed and"
                echo "no installed items were deselected."
                echo ""
                read -p "Press Enter to continue..." -r
                continue
            fi

            # Show summary
            clear
            echo "======================================================================="
            echo "Ansible Workstation - Summary"
            echo "======================================================================="
            echo ""
            if [ -n "$new_items" ]; then
                echo "Items to be INSTALLED:"
                echo "$new_items" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  + /'
                echo ""
            fi
            if [ -n "$to_uninstall" ]; then
                echo "Items to be UNINSTALLED:"
                echo "$to_uninstall" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  - /'
                echo ""
            fi
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            # Run install playbook if needed
            if [ -n "$new_items" ]; then
                generate_config_from_selections "$new_items"
                cd "$ANSIBLE_DIR"
                ansible-playbook "$ANSIBLE_PLAYBOOK" -e "@$ANSIBLE_CONFIG_FILE"
                local exit_code=$?
                echo ""
                echo "======================================================================="
                if [ $exit_code -eq 0 ]; then
                    echo "Installation completed successfully!"
                else
                    echo "Installation completed with errors (exit code: $exit_code)"
                fi
                echo "======================================================================="
                [ -f "$ANSIBLE_CONFIG_FILE" ] && rm -f "$ANSIBLE_CONFIG_FILE"
            fi

            # Run uninstall if needed
            if [ -n "$to_uninstall" ]; then
                run_uninstall_items "$to_uninstall"
            fi

            echo ""
            read -p "Press Enter to continue..." -r
        fi
    done
}

# Common menu - Base system tools
show_common_menu() {
    while true; do
        local installed_common
        installed_common=$(detect_installed_common)

        # Helper function
        is_installed_common() {
            local app="$1"
            [[ " $installed_common " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible Common" \
            --title "Common Tools - Select Base System Packages" \
            --ok-label "Install" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to install (checkmarks show installed):" 28 80 20 \
            "install-all" "Install All Common Tools" OFF \
            "git" "Git version control" $(is_installed_common "git") \
            "curl" "cURL - Transfer data" $(is_installed_common "curl") \
            "wget" "Wget - Download files" $(is_installed_common "wget") \
            "tmux" "Terminal multiplexer" $(is_installed_common "tmux") \
            "tree" "Directory tree viewer" $(is_installed_common "tree") \
            "htop" "Interactive process viewer" $(is_installed_common "htop") \
            "gotop" "System monitor" $(is_installed_common "gotop") \
            "jq" "JSON processor" $(is_installed_common "jq") \
            "fzf" "Fuzzy finder" $(is_installed_common "fzf") \
            "ripgrep" "Fast grep alternative" $(is_installed_common "ripgrep") \
            "ncdu" "Disk usage analyzer" $(is_installed_common "ncdu") \
            "neofetch" "System information" $(is_installed_common "neofetch") \
            "bat" "Cat clone with syntax highlighting" $(is_installed_common "bat") \
            "rclone" "Cloud storage sync" $(is_installed_common "rclone") \
            "openssh-server" "OpenSSH server" $(is_installed_common "openssh-server") \
            "net-tools" "Network tools" $(is_installed_common "net-tools") \
            "dnsutils" "DNS utilities" $(is_installed_common "dnsutils") \
            "glances" "System monitor" $(is_installed_common "glances") \
            "nodejs" "Node.js runtime (v20 LTS)" $(is_installed_common "nodejs") \
            "yarn" "Yarn package manager" $(is_installed_common "yarn") \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Installing All Common Tools"
            echo "======================================================================="
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/common.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Common tools installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # Calculate what's new (not already installed)
            local new_items=""
            local already_installed=""
            for item in $selections; do
                if [[ " $installed_common " =~ " $item " ]]; then
                    already_installed+="$item "
                else
                    new_items+="$item "
                fi
            done

            # Show summary - only display changes
            clear
            echo "======================================================================="
            echo "Common Tools - Installation Summary"
            echo "======================================================================="
            echo ""
            if [ -n "$new_items" ]; then
                echo "Items to be INSTALLED:"
                echo "$new_items" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  + /'
                echo ""
            else
                echo "No new items to install. All selected items are already installed."
                echo ""
                read -p "Press Enter to continue..." -r
                continue
            fi
            read -p "Press ENTER to start installation, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/common.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Common tools installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        fi
    done
}

show_database_menu() {
    while true; do
        local installed_db
        installed_db=$(detect_installed_db)

        # Helper function
        is_installed_db() {
            local app="$1"
            [[ " $installed_db " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible Database" \
            --title "Database Servers - Select Database Packages" \
            --ok-label "Install" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to install (checkmarks show installed):" 24 80 16 \
            "install-all" "Install All Database Servers" OFF \
            "postgresql" "PostgreSQL database server" $(is_installed_db "postgresql") \
            "mysql" "MySQL database server" $(is_installed_db "mysql") \
            "mariadb" "MariaDB database server" $(is_installed_db "mariadb") \
            "redis" "Redis in-memory database" $(is_installed_db "redis") \
            "mongodb" "MongoDB NoSQL database" $(is_installed_db "mongodb") \
            "pgadmin" "PostgreSQL admin (Docker)" $(is_installed_db "pgadmin") \
            "phpmyadmin" "MySQL/MariaDB admin (Docker)" $(is_installed_db "phpmyadmin") \
            "adminer" "Database admin tool (Docker)" $(is_installed_db "adminer") \
            "pgbackrest" "PostgreSQL backup tool" $(is_installed_db "pgbackrest") \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Installing All Database Servers"
            echo "======================================================================="
            echo ""
            echo "NOTE: Passwords will be generated for:"
            echo "  - PostgreSQL 'postgres' user"
            echo "  - MySQL 'root' user"
            echo "  - Redis authentication"
            echo "  - MongoDB admin user"
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/dbserver.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Database servers installation completed successfully!"
                show_credentials_summary
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # Calculate what's new (not already installed)
            local new_items=""
            local already_installed=""
            for item in $selections; do
                if [[ " $installed_db " =~ " $item " ]]; then
                    already_installed+="$item "
                else
                    new_items+="$item "
                fi
            done

            # Show summary - only display changes
            clear
            echo "======================================================================="
            echo "Database Servers - Installation Summary"
            echo "======================================================================="
            echo ""
            if [ -n "$new_items" ]; then
                echo "Items to be INSTALLED:"
                echo "$new_items" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  + /'
                echo ""
            else
                echo "No new items to install. All selected items are already installed."
                echo ""
                read -p "Press Enter to continue..." -r
                continue
            fi
            read -p "Press ENTER to start installation, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/dbserver.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Database servers installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        fi
    done
}

show_web_menu() {
    while true; do
        local installed_web
        installed_web=$(detect_installed_web)

        # Helper function
        is_installed_web() {
            local app="$1"
            [[ " $installed_web " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible Web" \
            --title "Web Servers - Select Web Tier Packages" \
            --ok-label "Install" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to install (checkmarks show installed):" 24 80 16 \
            "install-all" "Install All Web Tier Packages" OFF \
            "nginx" "Nginx web server" $(is_installed_web "nginx") \
            "apache2" "Apache web server" $(is_installed_web "apache2") \
            "traefik" "Traefik reverse proxy (Docker)" $(is_installed_web "traefik") \
            "haproxy" "HAProxy load balancer" $(is_installed_web "haproxy") \
            "certbot" "Let's Encrypt SSL certificates" $(is_installed_web "certbot") \
            "php-fpm" "PHP FastCGI Process Manager" $(is_installed_web "php-fpm") \
            "redis-server" "Redis caching server" $(is_installed_web "redis-server") \
            "memcached" "Memcached caching" $(is_installed_web "memcached") \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Installing All Web Server Packages"
            echo "======================================================================="
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/webtier.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Web servers installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # Calculate what's new (not already installed)
            local new_items=""
            local already_installed=""
            for item in $selections; do
                if [[ " $installed_web " =~ " $item " ]]; then
                    already_installed+="$item "
                else
                    new_items+="$item "
                fi
            done

            # Show summary - only display changes
            clear
            echo "======================================================================="
            echo "Web Servers - Installation Summary"
            echo "======================================================================="
            echo ""
            if [ -n "$new_items" ]; then
                echo "Items to be INSTALLED:"
                echo "$new_items" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  + /'
                echo ""
            else
                echo "No new items to install. All selected items are already installed."
                echo ""
                read -p "Press Enter to continue..." -r
                continue
            fi
            read -p "Press ENTER to start installation, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/webtier.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Web servers installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        fi
    done
}

show_tags_menu() {
    while true; do
        local menu_items=(
            "Browse by Category" "Hierarchical navigation by category tags"
            "Select Multiple Tags" "Power user checklist - combine any tags"
            "Criteria Builder" "Guided wizard with filters"
            "Back" "Return to Ansible menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible Tags" \
            --title "Install by Tags - Choose Method" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Choose how you want to select packages by tags:" 14 70 4 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Browse by Category")
                show_tags_by_category
                ;;
            "Select Multiple Tags")
                show_tags_multi_select
                ;;
            "Criteria Builder")
                show_tags_criteria_builder
                ;;
            "Back") return ;;
        esac
    done
}

# Tags Method 1: Browse by Category
show_tags_by_category() {
    local category_choice
    category_choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Tags by Category" \
        --title "Browse by Category" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --menu "Choose a category to see all items with that tag:" 18 70 10 \
        "common" "Base system tools (git, curl, tmux, etc.)" \
        "workstation" "Desktop applications" \
        "web" "Web servers and proxies" \
        "database" "Database servers" \
        "security" "Security hardening tools" \
        "monitoring" "Metrics and logging" \
        "development" "Development tools and runtimes" \
        "media" "Homelab media stack" \
        "Back" "Return to tags menu" \
        3>&1 1>&2 2>&3 3>&-) || return

    if [ "$category_choice" != "Back" ]; then
        dialog --msgbox "Would install all items tagged with: $category_choice\n\n(Implementation pending playbook creation)" 10 60
    fi
}

# Tags Method 2: Select Multiple Tags
show_tags_multi_select() {
    local selections
    selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Multiple Tags" \
        --title "Select Multiple Tags" \
        --ok-label "Next" \
        --cancel-label "Back" \
        --checklist "Select one or more tags to combine:" 30 80 22 \
        "[CATEGORY]" "--- Category Tags ---" OFF \
        "common" "Base system tools" OFF \
        "workstation" "Desktop applications" OFF \
        "web" "Web servers" OFF \
        "database" "Database servers" OFF \
        "security" "Security tools" OFF \
        "monitoring" "Metrics/logging" OFF \
        "development" "Dev tools" OFF \
        "media" "Media stack" OFF \
        "" "" OFF \
        "[ENVIRONMENT]" "--- Environment Tags ---" OFF \
        "production" "Production-ready" OFF \
        "homelab" "Homelab/personal" OFF \
        "cloud" "Cloud/VPS optimized" OFF \
        "" "" OFF \
        "[PRIORITY]" "--- Priority Tags ---" OFF \
        "critical" "Must-have essentials" OFF \
        "recommended" "Should-have" OFF \
        "optional" "Nice-to-have" OFF \
        "" "" OFF \
        "[METHOD]" "--- Install Method ---" OFF \
        "apt" "APT packages" OFF \
        "docker" "Docker containers" OFF \
        "snap" "Snap packages" OFF \
        3>&1 1>&2 2>&3 3>&-) || return

    if [ -n "$selections" ]; then
        # Ask for AND/OR logic
        local logic_choice
        logic_choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Tag Logic" \
            --title "Tag Combination Logic" \
            --ok-label "Select" \
            --cancel-label "Cancel" \
            --menu "How should the selected tags be combined?" 12 70 2 \
            "OR" "Install items matching ANY selected tag (broader)" \
            "AND" "Install items matching ALL selected tags (narrower)" \
            3>&1 1>&2 2>&3 3>&-)

        if [ -n "$logic_choice" ]; then
            dialog --msgbox "Would install packages using $logic_choice logic:\n\nTags: $selections\n\n(Implementation pending playbook creation)" 12 60
        fi
    fi
}

# Tags Method 3: Criteria Builder
show_tags_criteria_builder() {
    # Step 1: Environment
    local env_choice
    env_choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Criteria Builder (1/4)" \
        --title "Step 1: Select Environment" \
        --ok-label "Next" \
        --cancel-label "Cancel" \
        --radiolist "Choose target environment:" 14 70 5 \
        "all" "All Environments" ON \
        "production" "Production Only" OFF \
        "homelab" "Homelab Only" OFF \
        "development" "Development Only" OFF \
        "cloud" "Cloud/VPS" OFF \
        3>&1 1>&2 2>&3 3>&-) || return

    # Step 2: Priority
    local priority_choice
    priority_choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Criteria Builder (2/4)" \
        --title "Step 2: Select Priority" \
        --ok-label "Next" \
        --cancel-label "Back" \
        --checklist "Choose priority levels to include:" 12 70 3 \
        "critical" "Critical (essentials only)" ON \
        "recommended" "Recommended (add recommended items)" ON \
        "optional" "Optional (include optional items)" OFF \
        3>&1 1>&2 2>&3 3>&-) || return

    # Step 3: Categories
    local category_choice
    category_choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Criteria Builder (3/4)" \
        --title "Step 3: Select Categories" \
        --ok-label "Next" \
        --cancel-label "Back" \
        --checklist "Choose categories to install:" 16 70 8 \
        "common" "Common tools" OFF \
        "workstation" "Workstation apps" OFF \
        "web" "Web servers" OFF \
        "database" "Database servers" OFF \
        "security" "Security" OFF \
        "monitoring" "Monitoring" OFF \
        "development" "Development" OFF \
        "media" "Media stack" OFF \
        3>&1 1>&2 2>&3 3>&-) || return

    # Step 4: Review and install
    dialog --clear --backtitle "$SCRIPT_NAME - Criteria Builder (4/4)" \
        --title "Step 4: Review Selection" \
        --msgbox "Review your criteria:\n\nEnvironment: $env_choice\nPriority: $priority_choice\nCategories: $category_choice\n\n(Implementation pending playbook creation)" 16 70
}


# By Role submenu - navigate to individual role menus
show_by_role_menu() {
    while true; do
        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible" \
            --title "Configure By Role" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Choose a configuration category:" 18 70 9 \
            "Common" "Base system tools (git, curl, tmux, monitoring, security, vault)" \
            "Workstations" "Desktop applications and configurations" \
            "Configs" "System settings (power, touchpad, mouse, NTFS, Nautilus)" \
            "App Server" "VS Code Tunnel and application development tools" \
            "Database Servers" "PostgreSQL, MySQL, Redis, MongoDB, admin tools" \
            "Web Servers" "Nginx, Apache, Traefik, SSL/TLS, PHP, caching" \
            "HashiCorp Stack" "Boundary, Consul, Nomad, Packer, Terraform, Vault, Waypoint" \
            "Monitoring Stack" "Grafana, Prometheus, InfluxDB, Telegraf, ELK, cAdvisor" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Workstations")    show_workstation_menu ;;
            "Configs")         show_configs_menu ;;
            "Common")          show_common_menu ;;
            "App Server")      show_appserver_menu ;;
            "Database Servers") show_database_menu ;;
            "Web Servers")     show_web_menu ;;
            "HashiCorp Stack") show_hashicorp_menu ;;
            "Monitoring Stack") show_monitoring_menu ;;
        esac
    done
}

# Ansible menu - All applications checklist with By Role / Advanced at bottom
show_ansible_menu() {
    while true; do
        # Detect all installed items
        local installed_apps installed_configs installed_common installed_web installed_db installed_hashicorp installed_monitoring
        installed_apps=$(detect_installed_apps)
        installed_configs=$(detect_installed_configs)
        installed_common=$(detect_installed_common)
        installed_web=$(detect_installed_web)
        installed_db=$(detect_installed_db)
        installed_monitoring=$(detect_installed_monitoring)

        # HashiCorp detection
        installed_hashicorp=""
        command -v boundary &>/dev/null && installed_hashicorp+="boundary "
        command -v consul &>/dev/null && installed_hashicorp+="consul "
        command -v nomad &>/dev/null && installed_hashicorp+="nomad "
        command -v packer &>/dev/null && installed_hashicorp+="packer "
        command -v terraform &>/dev/null && installed_hashicorp+="terraform "
        command -v vault &>/dev/null && installed_hashicorp+="vault "
        command -v vault-radar &>/dev/null && installed_hashicorp+="vault-radar "
        command -v waypoint &>/dev/null && installed_hashicorp+="waypoint "

        # App Server detection
        local installed_appserver=""
        command -v code &>/dev/null && installed_appserver+="vscode "
        systemctl is-enabled code-tunnel &>/dev/null 2>&1 && installed_appserver+="vscode-tunnel "
        docker ps -a 2>/dev/null | grep -q jenkins && installed_appserver+="jenkins "
        command -v kubectl &>/dev/null && installed_appserver+="kubernetes "

        # Combine all installed into one string for checking
        local all_installed="$installed_apps $installed_configs $installed_common $installed_web $installed_db $installed_hashicorp $installed_appserver $installed_monitoring"

        # Helper function to check if installed
        is_installed_all() {
            local app="$1"
            [[ " $all_installed " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible" \
            --title "Ansible Automation - All Applications" \
            --ok-label "Install Selected" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select, ENTER to install. Use / to search in dialog." 50 90 42 \
            "─────────" "── WORKSTATION APPS ──" OFF \
            "vivaldi" "[Workstation] Vivaldi Browser" $(is_installed_all "vivaldi") \
            "bitwarden" "[Workstation] Bitwarden Password Manager" $(is_installed_all "bitwarden") \
            "notepad" "[Workstation] Notepad++ Text Editor" $(is_installed_all "notepad") \
            "notion" "[Workstation] Notion Productivity App" $(is_installed_all "notion") \
            "obsidian" "[Workstation] Obsidian Knowledge Base" $(is_installed_all "obsidian") \
            "mailspring" "[Workstation] Mailspring Email Client" $(is_installed_all "mailspring") \
            "claude-code" "[Workstation] Claude AI Code Assistant" $(is_installed_all "claude-code") \
            "chatgpt" "[Workstation] ChatGPT Desktop Client" $(is_installed_all "chatgpt") \
            "codex" "[Workstation] OpenAI Codex CLI (Node 22 + npm)" $(is_installed_all "codex") \
            "gemini" "[Workstation] Google Gemini CLI (npm)" $(is_installed_all "gemini") \
            "icloud" "[Workstation] iCloud for Linux" $(is_installed_all "icloud") \
            "discord" "[Workstation] Discord Communication" $(is_installed_all "discord") \
            "zoom" "[Workstation] Zoom Video Conferencing" $(is_installed_all "zoom") \
            "termius" "[Workstation] Termius SSH Client" $(is_installed_all "termius") \
            "onlyoffice" "[Workstation] OnlyOffice Suite" $(is_installed_all "onlyoffice") \
            "chrome-ext" "[Workstation] Chrome Extensions (AI Chat Exporter)" $(is_installed_all "chrome-ext") \
            "docker" "[Workstation] Docker Container Platform" $(is_installed_all "docker") \
            "portainer" "[Workstation] Portainer Docker Management" $(is_installed_all "portainer") \
            "twingate" "[Workstation] Twingate VPN Client" $(is_installed_all "twingate") \
            "protonvpn" "[Workstation] ProtonVPN Client" $(is_installed_all "protonvpn") \
            "ulauncher" "[Workstation] Ulauncher App Launcher" $(is_installed_all "ulauncher") \
            "n8n" "[Workstation] n8n Workflow Automation" $(is_installed_all "n8n") \
            "sublime-text" "[Workstation] Sublime Text Editor" $(is_installed_all "sublime-text") \
            "─────────" "── SYSTEM CONFIGS ──" OFF \
            "power" "[Config] Power Management (lid close, sleep)" $(is_installed_all "power") \
            "touchpad" "[Config] Touchpad Settings (speed, tap-to-click)" $(is_installed_all "touchpad") \
            "mouse" "[Config] Mouse Settings (speed, acceleration)" $(is_installed_all "mouse") \
            "nautilus" "[Config] Nautilus File Manager (sort, view)" $(is_installed_all "nautilus") \
            "ntfs" "[Config] NTFS/exFAT Filesystem Support" $(is_installed_all "ntfs") \
            "razer" "[Config] Razer Laptop GRUB Config (Intel GPU fix)" $(is_installed_all "razer") \
            "─────────" "── SECURITY TOOLS ──" OFF \
            "fail2ban" "[Security] Fail2ban Intrusion Prevention" $(is_installed_all "fail2ban") \
            "clamav" "[Security] ClamAV Antivirus" $(is_installed_all "clamav") \
            "auditd" "[Security] Auditd System Auditing" $(is_installed_all "auditd") \
            "ufw" "[Security] UFW Firewall" $(is_installed_all "ufw") \
            "─────────" "── COMMON TOOLS ──" OFF \
            "git" "[Common] Git version control" $(is_installed_all "git") \
            "curl" "[Common] cURL - Transfer data" $(is_installed_all "curl") \
            "wget" "[Common] Wget - Download files" $(is_installed_all "wget") \
            "tmux" "[Common] Terminal multiplexer" $(is_installed_all "tmux") \
            "tree" "[Common] Directory tree viewer" $(is_installed_all "tree") \
            "htop" "[Common] Interactive process viewer" $(is_installed_all "htop") \
            "gotop" "[Common] System monitor" $(is_installed_all "gotop") \
            "jq" "[Common] JSON processor" $(is_installed_all "jq") \
            "fzf" "[Common] Fuzzy finder" $(is_installed_all "fzf") \
            "ripgrep" "[Common] Fast grep alternative" $(is_installed_all "ripgrep") \
            "ncdu" "[Common] Disk usage analyzer" $(is_installed_all "ncdu") \
            "neofetch" "[Common] System information" $(is_installed_all "neofetch") \
            "bat" "[Common] Cat with syntax highlighting" $(is_installed_all "bat") \
            "rclone" "[Common] Cloud storage sync" $(is_installed_all "rclone") \
            "openssh-server" "[Common] OpenSSH server" $(is_installed_all "openssh-server") \
            "net-tools" "[Common] Network tools" $(is_installed_all "net-tools") \
            "dnsutils" "[Common] DNS utilities" $(is_installed_all "dnsutils") \
            "glances" "[Common] System monitor" $(is_installed_all "glances") \
            "nodejs" "[Common] Node.js runtime (v20 LTS)" $(is_installed_all "nodejs") \
            "yarn" "[Common] Yarn package manager" $(is_installed_all "yarn") \
            "─────────" "── DATABASE SERVERS ──" OFF \
            "postgresql" "[Database] PostgreSQL server" $(is_installed_all "postgresql") \
            "mysql" "[Database] MySQL server" $(is_installed_all "mysql") \
            "mariadb" "[Database] MariaDB server" $(is_installed_all "mariadb") \
            "redis" "[Database] Redis in-memory DB" $(is_installed_all "redis") \
            "mongodb" "[Database] MongoDB NoSQL" $(is_installed_all "mongodb") \
            "pgadmin" "[Database] PostgreSQL admin (Docker)" $(is_installed_all "pgadmin") \
            "phpmyadmin" "[Database] MySQL admin (Docker)" $(is_installed_all "phpmyadmin") \
            "adminer" "[Database] Database admin (Docker)" $(is_installed_all "adminer") \
            "pgbackrest" "[Database] PostgreSQL backup" $(is_installed_all "pgbackrest") \
            "─────────" "── WEB SERVERS ──" OFF \
            "nginx" "[Web] Nginx web server" $(is_installed_all "nginx") \
            "apache2" "[Web] Apache web server" $(is_installed_all "apache2") \
            "traefik" "[Web] Traefik reverse proxy" $(is_installed_all "traefik") \
            "haproxy" "[Web] HAProxy load balancer" $(is_installed_all "haproxy") \
            "certbot" "[Web] Let's Encrypt SSL" $(is_installed_all "certbot") \
            "php-fpm" "[Web] PHP FastCGI" $(is_installed_all "php-fpm") \
            "redis-server" "[Web] Redis caching" $(is_installed_all "redis-server") \
            "memcached" "[Web] Memcached caching" $(is_installed_all "memcached") \
            "─────────" "── APP SERVER ──" OFF \
            "vscode-tunnel" "[AppServer] VS Code Tunnel (remote dev)" $(is_installed_all "vscode-tunnel") \
            "jenkins" "[AppServer] Jenkins CI/CD (Docker)" $(is_installed_all "jenkins") \
            "kubernetes" "[AppServer] Kubernetes CLI tools" $(is_installed_all "kubernetes") \
            "─────────" "── HASHICORP STACK ──" OFF \
            "boundary" "[HashiCorp] Secure remote access" $(is_installed_all "boundary") \
            "consul" "[HashiCorp] Service networking" $(is_installed_all "consul") \
            "nomad" "[HashiCorp] Workload orchestration" $(is_installed_all "nomad") \
            "packer" "[HashiCorp] Image builder" $(is_installed_all "packer") \
            "terraform" "[HashiCorp] Infrastructure as Code" $(is_installed_all "terraform") \
            "vault" "[HashiCorp] Secrets management" $(is_installed_all "vault") \
            "vault-radar" "[HashiCorp] Secret sprawl detection" $(is_installed_all "vault-radar") \
            "waypoint" "[HashiCorp] Developer platform" $(is_installed_all "waypoint") \
            "─────────" "── MONITORING STACK ──" OFF \
            "grafana" "[Monitoring] Grafana Dashboard" $(is_installed_all "grafana") \
            "prometheus" "[Monitoring] Prometheus Metrics DB" $(is_installed_all "prometheus") \
            "influxdb" "[Monitoring] InfluxDB Time-Series DB" $(is_installed_all "influxdb") \
            "telegraf" "[Monitoring] Telegraf Metrics Agent" $(is_installed_all "telegraf") \
            "node-exporter" "[Monitoring] Node Exporter" $(is_installed_all "node-exporter") \
            "cadvisor" "[Monitoring] cAdvisor Container Metrics" $(is_installed_all "cadvisor") \
            "elasticsearch" "[Monitoring] Elasticsearch" $(is_installed_all "elasticsearch") \
            "kibana" "[Monitoring] Kibana Visualization" $(is_installed_all "kibana") \
            "─────────" "── ─────────────────────── ──" OFF \
            "nav-by-role" "→ By Role (Workstation, Common, DB, Web, etc.)" OFF \
            "nav-advanced" "→ Advanced: Install by Tags" OFF \
            3>&1 1>&2 2>&3 3>&-) || return

        # Remove separator items from selection
        selections=$(echo "$selections" | sed 's/─────────//g' | xargs)

        # Handle navigation items (take priority over app selections)
        if [[ "$selections" == *"nav-by-role"* ]]; then
            show_by_role_menu
            continue
        fi
        if [[ "$selections" == *"nav-advanced"* ]]; then
            show_tags_menu
            continue
        fi

        if [ -z "$selections" ]; then
            return
        fi

        # All dialog items that support uninstall tracking (workstation + security only)
        local all_dialog_ws="vivaldi bitwarden notepad notion obsidian mailspring claude-code chatgpt codex gemini icloud discord zoom termius onlyoffice chrome-ext docker portainer twingate protonvpn ulauncher n8n sublime-text fail2ban clamav auditd ufw"

        # Calculate new installs and removals
        local new_items=""
        local to_uninstall=""
        for item in $selections; do
            [[ " $all_installed " =~ " $item " ]] || new_items+="$item "
        done
        for item in $all_dialog_ws; do
            if [[ " $all_installed " =~ " $item " ]] && [[ ! " $selections " =~ " $item " ]]; then
                to_uninstall+="$item "
            fi
        done

        # No changes at all?
        if [ -z "$new_items" ] && [ -z "$to_uninstall" ]; then
            clear
            echo "======================================================================="
            echo "All Applications - No Changes"
            echo "======================================================================="
            echo ""
            echo "No changes detected. All selected items are already installed and"
            echo "no installed items were deselected."
            echo ""
            read -p "Press Enter to continue..." -r
            continue
        fi

        # Show summary
        clear
        echo "======================================================================="
        echo "All Applications - Summary"
        echo "======================================================================="
        echo ""
        if [ -n "$new_items" ]; then
            echo "Items to be INSTALLED:"
            echo "$new_items" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  + /'
            echo ""
        fi
        if [ -n "$to_uninstall" ]; then
            echo "Items to be UNINSTALLED:"
            echo "$to_uninstall" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  - /'
            echo ""
        fi
        if [ -n "$new_items" ]; then
            echo "NOTE: Install will run playbooks for each category with selected items."
            echo ""
        fi
        read -p "Press ENTER to continue, or Ctrl+C to cancel..."

        # Categorize selections by role/playbook
        local ws_list="vivaldi bitwarden notepad notion obsidian mailspring claude-code chatgpt codex gemini icloud discord zoom termius onlyoffice chrome-ext docker portainer twingate protonvpn ulauncher n8n sublime-text fail2ban clamav auditd ufw"
        local configs_list="power touchpad mouse nautilus ntfs razer"
        local common_list="git curl wget tmux tree htop gotop jq fzf ripgrep ncdu neofetch bat rclone openssh-server net-tools dnsutils glances nodejs yarn"
        local db_list="postgresql mysql mariadb redis mongodb pgadmin phpmyadmin adminer pgbackrest"
        local web_list="nginx apache2 traefik haproxy certbot php-fpm redis-server memcached"
        local appserver_list="vscode-tunnel jenkins kubernetes"
        local hashicorp_list="boundary consul nomad packer terraform vault vault-radar waypoint"
        local monitoring_list="grafana prometheus influxdb telegraf node-exporter cadvisor elasticsearch kibana"

        local workstation_items="" configs_items="" common_items="" db_items="" web_items=""
        local appserver_items="" hashicorp_items="" monitoring_items=""

        # Only categorize NEW items (not already installed) to avoid unnecessary playbook runs
        for item in $new_items; do
            if [[ " $ws_list " =~ " $item " ]]; then
                workstation_items+="$item "
            elif [[ " $configs_list " =~ " $item " ]]; then
                configs_items+="$item "
            elif [[ " $common_list " =~ " $item " ]]; then
                common_items+="$item "
            elif [[ " $db_list " =~ " $item " ]]; then
                db_items+="$item "
            elif [[ " $web_list " =~ " $item " ]]; then
                web_items+="$item "
            elif [[ " $appserver_list " =~ " $item " ]]; then
                appserver_items+="$item "
            elif [[ " $hashicorp_list " =~ " $item " ]]; then
                hashicorp_items+="$item "
            elif [[ " $monitoring_list " =~ " $item " ]]; then
                monitoring_items+="$item "
            fi
        done

        local overall_exit=0

        # Run workstation playbook if any NEW workstation items selected
        if [ -n "$workstation_items" ]; then
            echo ""
            echo ">>> Running Workstation playbook..."
            generate_config_from_selections "$workstation_items"
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_PLAYBOOK" -e "@$ANSIBLE_CONFIG_FILE"
            [ $? -ne 0 ] && overall_exit=1
            [ -f "$ANSIBLE_CONFIG_FILE" ] && rm -f "$ANSIBLE_CONFIG_FILE"
        fi

        # Run configs playbook with tags if any config items selected
        if [ -n "$configs_items" ]; then
            echo ""
            echo ">>> Running System Configs playbook..."
            local cfg_tags
            cfg_tags=$(echo "$configs_items" | xargs | tr ' ' ',')
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/configs.yml" --tags "$cfg_tags"
            [ $? -ne 0 ] && overall_exit=1
        fi

        # Run common playbook if any common items selected
        if [ -n "$common_items" ]; then
            echo ""
            echo ">>> Running Common Tools playbook..."
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/common.yml"
            [ $? -ne 0 ] && overall_exit=1
        fi

        # Run database playbook if any db items selected
        if [ -n "$db_items" ]; then
            echo ""
            echo ">>> Running Database Servers playbook..."
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/dbserver.yml"
            [ $? -ne 0 ] && overall_exit=1
        fi

        # Run web playbook if any web items selected
        if [ -n "$web_items" ]; then
            echo ""
            echo ">>> Running Web Servers playbook..."
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/webtier.yml"
            [ $? -ne 0 ] && overall_exit=1
        fi

        # Run appserver playbook with tags if any appserver items selected
        if [ -n "$appserver_items" ]; then
            echo ""
            echo ">>> Running App Server playbook..."
            local app_tags
            app_tags=$(echo "$appserver_items" | xargs | tr ' ' ',')
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/appserver.yml" --tags "$app_tags"
            [ $? -ne 0 ] && overall_exit=1
        fi

        # Run hashicorp playbook with tags if any hashicorp items selected
        if [ -n "$hashicorp_items" ]; then
            echo ""
            echo ">>> Running HashiCorp Stack playbook..."
            local hashi_tags
            hashi_tags=$(echo "$hashicorp_items" | xargs | tr ' ' ',')
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/hashicorp.yml" --tags "$hashi_tags"
            [ $? -ne 0 ] && overall_exit=1
        fi

        # Run monitoring playbook with tags if any monitoring items selected
        if [ -n "$monitoring_items" ]; then
            echo ""
            echo ">>> Running Monitoring Stack playbook..."
            local mon_tags
            mon_tags=$(echo "$monitoring_items" | xargs | tr ' ' ',')
            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/monitoring.yml" --tags "$mon_tags"
            [ $? -ne 0 ] && overall_exit=1
        fi

        if [ -n "$new_items" ]; then
            echo ""
            echo "======================================================================="
            if [ $overall_exit -eq 0 ]; then
                echo "All installations completed successfully!"
            else
                echo "Installation completed with some errors. Check output above."
            fi
            echo "======================================================================="
        fi

        # Run uninstall if any items were deselected
        if [ -n "$to_uninstall" ]; then
            run_uninstall_items "$to_uninstall"
        fi

        echo ""
        read -p "Press Enter to continue..." -r
    done
}

# Configs menu - System configuration settings
show_configs_menu() {
    while true; do
        local installed_configs
        installed_configs=$(detect_installed_configs)

        # Helper function
        is_installed_config() {
            local app="$1"
            [[ " $installed_configs " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible Configs" \
            --title "System Configs - Select Settings to Apply" \
            --ok-label "Apply" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to apply (checkmarks show configured):" 18 80 8 \
            "install-all" "Apply All System Configurations" OFF \
            "power" "Power Management (sleep, lid close)" $(is_installed_config "power") \
            "touchpad" "Touchpad Settings (speed, tap-to-click)" $(is_installed_config "touchpad") \
            "mouse" "Mouse Settings (speed, acceleration)" $(is_installed_config "mouse") \
            "nautilus" "Nautilus File Manager (sort, view)" $(is_installed_config "nautilus") \
            "ntfs" "NTFS/exFAT Filesystem Support" $(is_installed_config "ntfs") \
            "razer" "Razer Laptop GRUB Config (Intel GPU fix)" $(is_installed_config "razer") \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Applying All System Configurations"
            echo "======================================================================="
            echo ""
            echo "Configurations to apply:"
            echo "  - Power Management, Touchpad, Mouse"
            echo "  - Nautilus, NTFS Support, Razer GRUB"
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/configs.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "System configuration completed successfully!"
            else
                echo "Configuration completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # Build tags from selection
            local tags=""
            [[ "$selections" == *"power"* ]] && tags+="power,"
            [[ "$selections" == *"touchpad"* ]] && tags+="touchpad,"
            [[ "$selections" == *"mouse"* ]] && tags+="mouse,"
            [[ "$selections" == *"nautilus"* ]] && tags+="nautilus,"
            [[ "$selections" == *"ntfs"* ]] && tags+="ntfs,"
            [[ "$selections" == *"razer"* ]] && tags+="razer,"
            tags="${tags%,}"  # Remove trailing comma

            if [ -n "$tags" ]; then
                clear
                echo "======================================================================="
                echo "Applying System Configurations"
                echo "======================================================================="
                echo ""
                echo "Selected: $selections"
                echo ""
                read -p "Press ENTER to continue, or Ctrl+C to cancel..."

                cd "$ANSIBLE_DIR"
                ansible-playbook "$ANSIBLE_DIR/playbooks/configs.yml" --tags "$tags"

                local exit_code=$?
                echo ""
                echo "======================================================================="
                if [ $exit_code -eq 0 ]; then
                    echo "Configuration completed successfully!"
                else
                    echo "Configuration completed with errors (exit code: $exit_code)"
                fi
                echo "======================================================================="
                echo ""
                read -p "Press Enter to continue..." -r
            fi
        fi
    done
}

# App Server menu - VS Code Tunnel and development tools
show_appserver_menu() {
    while true; do
        # Detect installed app server components
        local vscode_installed="OFF"
        local vscode_tunnel_installed="OFF"

        command -v code &>/dev/null && vscode_installed="ON"
        systemctl is-enabled code-tunnel &>/dev/null 2>&1 && vscode_tunnel_installed="ON"

        local jenkins_installed="OFF"
        local kubernetes_installed="OFF"
        docker ps -a 2>/dev/null | grep -q jenkins && jenkins_installed="ON"
        command -v kubectl &>/dev/null && kubernetes_installed="ON"

        # Check if GitHub username is configured
        local github_status=""
        if [[ -n "$GITHUB_USERNAME" ]]; then
            github_status=" (GitHub: $GITHUB_USERNAME)"
        else
            github_status=" (GitHub: NOT SET)"
        fi

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Ansible App Server" \
            --title "App Server Setup - Development Tools$github_status" \
            --ok-label "Install" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to install:" 18 80 8 \
            "install-all" "Install All App Server Components" OFF \
            "vscode-tunnel" "VS Code Tunnel (remote development)$github_status" $vscode_tunnel_installed \
            "jenkins" "Jenkins CI/CD Server (Docker)" $jenkins_installed \
            "kubernetes" "Kubernetes CLI (kubectl, kubeadm, kubelet)" $kubernetes_installed \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if GitHub username is set for VS Code tunnel
        if [[ "$selections" == *"vscode-tunnel"* ]] || [[ "$selections" == *"install-all"* ]]; then
            if [[ -z "$GITHUB_USERNAME" ]]; then
                dialog --yesno "GitHub username is not configured.\n\nVS Code Tunnel requires GitHub authentication.\nWould you like to set your GitHub username now?\n\n(You can also set it later in Prerequisites > GitHub Username)" 14 70
                if [[ $? -eq 0 ]]; then
                    set_github_username
                fi
            fi
        fi

        # Build extra vars for Ansible
        local extra_vars=""
        if [[ -n "$GITHUB_USERNAME" ]]; then
            extra_vars="-e github_username=$GITHUB_USERNAME"
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Installing All App Server Components"
            echo "======================================================================="
            echo ""
            if [[ -n "$GITHUB_USERNAME" ]]; then
                echo "GitHub Username: $GITHUB_USERNAME"
            else
                echo "GitHub Username: Not configured (you'll need to set this for VS Code Tunnel)"
            fi
            echo ""
            echo "Components to install:"
            echo "  - VS Code Editor"
            echo "  - VS Code Tunnel systemd service"
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            if [[ -n "$extra_vars" ]]; then
                ansible-playbook "$ANSIBLE_DIR/playbooks/appserver.yml" $extra_vars
            else
                ansible-playbook "$ANSIBLE_DIR/playbooks/appserver.yml"
            fi

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "App server installation completed successfully!"
                echo ""
                echo "NEXT STEPS for VS Code Tunnel:"
                echo "  1. Run: code tunnel --accept-server-license-terms"
                if [[ -n "$GITHUB_USERNAME" ]]; then
                    echo "  2. Login with GitHub account: $GITHUB_USERNAME"
                else
                    echo "  2. Login with your GitHub account"
                fi
                echo "  3. Press Ctrl+C after authentication"
                echo "  4. Start service: sudo systemctl start code-tunnel"
                echo "  5. Access: https://vscode.dev/tunnel/$(hostname)"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # Individual component installation
            local tags=""
            [[ "$selections" == *"vscode-tunnel"* ]] && tags+="vscode-tunnel,"
            [[ "$selections" == *"jenkins"* ]] && tags+="jenkins,"
            [[ "$selections" == *"kubernetes"* ]] && tags+="kubernetes,"
            tags="${tags%,}"  # Remove trailing comma

            if [ -n "$tags" ]; then
                clear
                echo "======================================================================="
                echo "Installing App Server Components"
                echo "======================================================================="
                echo ""
                echo "Selected: $selections"
                if [[ -n "$GITHUB_USERNAME" ]]; then
                    echo "GitHub Username: $GITHUB_USERNAME"
                fi
                echo ""
                read -p "Press ENTER to continue, or Ctrl+C to cancel..."

                cd "$ANSIBLE_DIR"
                if [[ -n "$extra_vars" ]]; then
                    ansible-playbook "$ANSIBLE_DIR/playbooks/appserver.yml" --tags "$tags" $extra_vars
                else
                    ansible-playbook "$ANSIBLE_DIR/playbooks/appserver.yml" --tags "$tags"
                fi

                local exit_code=$?
                echo ""
                echo "======================================================================="
                if [ $exit_code -eq 0 ]; then
                    echo "Installation completed successfully!"
                else
                    echo "Installation completed with errors (exit code: $exit_code)"
                fi
                echo "======================================================================="
                echo ""
                read -p "Press Enter to continue..." -r
            fi
        fi
    done
}

# HashiCorp Stack menu
show_hashicorp_menu() {
    # Detect installed HashiCorp tools (alphabetically sorted)
    local installed_tools=""
    command -v boundary &>/dev/null && installed_tools+="boundary "
    command -v consul &>/dev/null && installed_tools+="consul "
    command -v nomad &>/dev/null && installed_tools+="nomad "
    command -v packer &>/dev/null && installed_tools+="packer "
    command -v terraform &>/dev/null && installed_tools+="terraform "
    command -v vault &>/dev/null && installed_tools+="vault "
    command -v vault-radar &>/dev/null && installed_tools+="vault-radar "
    command -v waypoint &>/dev/null && installed_tools+="waypoint "

    # Alphabetically sorted list
    local hashicorp_apps=(
        "boundary" "Secure remote access" "off"
        "consul" "Service-based networking" "off"
        "nomad" "Workload scheduling and orchestration" "off"
        "packer" "Build and manage images as code" "off"
        "terraform" "Provision cloud infrastructure" "off"
        "vault" "Identity-based secrets management" "off"
        "vault-radar" "Discover and remediate secret sprawl" "off"
        "waypoint" "Internal developer platform" "off"
    )

    # Mark installed tools as ON
    local updated_apps=()
    for ((i=0; i<${#hashicorp_apps[@]}; i+=3)); do
        local tool="${hashicorp_apps[i]}"
        local desc="${hashicorp_apps[i+1]}"
        local status="off"

        [[ $installed_tools =~ $tool ]] && status="on"

        updated_apps+=("$tool" "$desc" "$status")
    done

    # Add Install All option at the top
    local all_status="off"
    local checklist_items=(
        "all" "Install ALL HashiCorp tools" "$all_status"
        "${updated_apps[@]}"
    )

    local selected
    selected=$(dialog --clear --backtitle "$SCRIPT_NAME - HashiCorp Stack" \
        --title "HashiCorp Stack Installation" \
        --ok-label "Install" \
        --cancel-label "Back" \
        --checklist "Select HashiCorp tools to install:" 20 70 10 \
        "${checklist_items[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    # Remove quotes and parse selection
    selected=$(echo "$selected" | tr -d '"')

    if [ -z "$selected" ]; then
        return
    fi

    # Build Ansible tags from selection
    local ansible_tags=""
    if [[ $selected =~ "all" ]]; then
        ansible_tags="hashicorp"
    else
        # Convert space-separated list to comma-separated tags
        ansible_tags=$(echo "$selected" | tr ' ' ',')
    fi

    # Confirm installation
    if dialog --yesno "Install selected HashiCorp tools?\n\nTools: $selected\n\nThis will run Ansible playbook with tags: $ansible_tags" 12 70; then
        clear
        echo "Installing HashiCorp Stack..."
        echo "Running: ansible-playbook playbooks/hashicorp.yml --tags \"$ansible_tags\""
        echo ""

        cd "$SCRIPT_DIR/ansible" || return
        ansible-playbook playbooks/hashicorp.yml --tags "$ansible_tags"

        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Monitoring Stack menu
show_monitoring_menu() {
    while true; do
        local installed_monitoring
        installed_monitoring=$(detect_installed_monitoring)

        # Helper function
        is_installed_monitoring() {
            local app="$1"
            [[ " $installed_monitoring " =~ " $app " ]] && echo "ON" || echo "OFF"
        }

        local selections
        selections=$(dialog --clear --backtitle "$SCRIPT_NAME - Monitoring Stack" \
            --title "Monitoring Stack - Select Components" \
            --ok-label "Install" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect, ENTER to install (checkmarks show installed):" 22 80 12 \
            "install-all" "Install All Monitoring Components" OFF \
            "grafana" "Grafana Dashboard (port 3000)" $(is_installed_monitoring "grafana") \
            "prometheus" "Prometheus Metrics DB (port 9090)" $(is_installed_monitoring "prometheus") \
            "influxdb" "InfluxDB Time-Series DB (port 8086)" $(is_installed_monitoring "influxdb") \
            "telegraf" "Telegraf Metrics Agent (port 8125)" $(is_installed_monitoring "telegraf") \
            "node-exporter" "Node Exporter System Metrics (port 9100)" $(is_installed_monitoring "node-exporter") \
            "cadvisor" "cAdvisor Container Metrics (port 8081)" $(is_installed_monitoring "cadvisor") \
            "elasticsearch" "Elasticsearch Search Engine (port 9200)" $(is_installed_monitoring "elasticsearch") \
            "kibana" "Kibana Visualization (port 5601)" $(is_installed_monitoring "kibana") \
            3>&1 1>&2 2>&3 3>&-) || return

        if [ -z "$selections" ]; then
            return
        fi

        # Check if "install-all" was selected
        if [[ "$selections" == *"install-all"* ]]; then
            clear
            echo "======================================================================="
            echo "Installing All Monitoring Components"
            echo "======================================================================="
            echo ""
            echo "Components to install:"
            echo "  - Grafana, Prometheus, InfluxDB, Telegraf"
            echo "  - Node Exporter, cAdvisor"
            echo "  - Elasticsearch, Kibana"
            echo ""
            read -p "Press ENTER to continue, or Ctrl+C to cancel..."

            cd "$ANSIBLE_DIR"
            ansible-playbook "$ANSIBLE_DIR/playbooks/monitoring.yml"

            local exit_code=$?
            echo ""
            echo "======================================================================="
            if [ $exit_code -eq 0 ]; then
                echo "Monitoring stack installation completed successfully!"
            else
                echo "Installation completed with errors (exit code: $exit_code)"
            fi
            echo "======================================================================="
            echo ""
            read -p "Press Enter to continue..." -r
        else
            # Build tags from selection
            local tags=""
            [[ "$selections" == *"grafana"* ]] && tags+="grafana,"
            [[ "$selections" == *"prometheus"* ]] && tags+="prometheus,"
            [[ "$selections" == *"influxdb"* ]] && tags+="influxdb,"
            [[ "$selections" == *"telegraf"* ]] && tags+="telegraf,"
            [[ "$selections" == *"node-exporter"* ]] && tags+="node-exporter,"
            [[ "$selections" == *"cadvisor"* ]] && tags+="cadvisor,"
            [[ "$selections" == *"elasticsearch"* ]] && tags+="elasticsearch,"
            [[ "$selections" == *"kibana"* ]] && tags+="kibana,"
            tags="${tags%,}"  # Remove trailing comma

            if [ -n "$tags" ]; then
                clear
                echo "======================================================================="
                echo "Installing Monitoring Components"
                echo "======================================================================="
                echo ""
                echo "Selected: $selections"
                echo ""
                read -p "Press ENTER to continue, or Ctrl+C to cancel..."

                cd "$ANSIBLE_DIR"
                ansible-playbook "$ANSIBLE_DIR/playbooks/monitoring.yml" --tags "$tags"

                local exit_code=$?
                echo ""
                echo "======================================================================="
                if [ $exit_code -eq 0 ]; then
                    echo "Installation completed successfully!"
                else
                    echo "Installation completed with errors (exit code: $exit_code)"
                fi
                echo "======================================================================="
                echo ""
                read -p "Press Enter to continue..." -r
            fi
        fi
    done
}
