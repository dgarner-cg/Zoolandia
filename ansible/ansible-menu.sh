#!/bin/bash
################################################################################
# Zoolandia Workstation Setup - Interactive Menu
# File: ansible-menu.sh
# Purpose: Interactive checkbox menu for selective installation
#
# USAGE:
#   ./ansible-menu.sh
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="/tmp/ansible_workstation_config.yml"
PLAYBOOK="$SCRIPT_DIR/workstations.yml"

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo -e "${YELLOW}Installing dialog...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y dialog
fi

################################################################################
# HELPER FUNCTIONS
################################################################################

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "🚀 ZOOLANDIA WORKSTATION SETUP - INTERACTIVE MENU"
    echo "═══════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

detect_installed_apps() {
    local installed_apps=""

    # Check snap apps
    if command -v snap &> /dev/null; then
        snap list 2>/dev/null | grep -q "^vivaldi" && installed_apps+="vivaldi "
        snap list 2>/dev/null | grep -q "^bitwarden" && installed_apps+="bitwarden "
        snap list 2>/dev/null | grep -q "^notepad-plus-plus" && installed_apps+="notepad "
        snap list 2>/dev/null | grep -q "^notion-snap-reborn" && installed_apps+="notion "
        snap list 2>/dev/null | grep -q "^mailspring" && installed_apps+="mailspring "
        snap list 2>/dev/null | grep -q "^claude-code" && installed_apps+="claude-code "
        snap list 2>/dev/null | grep -q "^chatgpt-desktop-client" && installed_apps+="chatgpt "
        snap list 2>/dev/null | grep -q "^icloud-for-linux" && installed_apps+="icloud "
    fi

    # Check deb apps
    dpkg -l discord 2>/dev/null | grep -q "^ii" && installed_apps+="discord "
    dpkg -l zoom 2>/dev/null | grep -q "^ii" && installed_apps+="zoom "
    dpkg -l termius 2>/dev/null | grep -q "^ii" && installed_apps+="termius "
    dpkg -l onlyoffice-desktopeditors 2>/dev/null | grep -q "^ii" && installed_apps+="onlyoffice "

    # Check complex apps
    command -v docker &> /dev/null && installed_apps+="docker "
    command -v portainer &> /dev/null && docker ps -a 2>/dev/null | grep -q portainer && installed_apps+="portainer "
    command -v twingate &> /dev/null && installed_apps+="twingate "
    command -v protonvpn &> /dev/null && installed_apps+="protonvpn "
    command -v ulauncher &> /dev/null && installed_apps+="ulauncher "
    systemctl --user list-units --all 2>/dev/null | grep -q "n8n" && installed_apps+="n8n "

    # Check system configurations (basic heuristic checks)
    [ -f /etc/systemd/logind.conf ] && grep -q "HandleLidSwitch" /etc/systemd/logind.conf 2>/dev/null && installed_apps+="power "
    [ -f /etc/X11/xorg.conf.d/30-touchpad.conf ] && installed_apps+="touchpad "
    [ -f "$HOME/.config/nautilus/scripts" ] && installed_apps+="nautilus "

    # Check chrome extensions
    [ -d "$HOME/.local/share/chrome-extensions/ai-chat-exporter" ] && installed_apps+="chrome-ext "

    # Check mouse settings (GNOME gsettings)
    command -v gsettings &> /dev/null && gsettings get org.gnome.desktop.peripherals.mouse speed &>/dev/null && installed_apps+="mouse "

    # Check NTFS support
    dpkg -l ntfs-3g 2>/dev/null | grep -q "^ii" && installed_apps+="ntfs "

    # Check Razer GRUB config
    [ -f /etc/default/grub ] && grep -q "i915.enable_psr=0" /etc/default/grub 2>/dev/null && installed_apps+="razer "

    # Check security tools
    dpkg -l fail2ban 2>/dev/null | grep -q "^ii" && installed_apps+="fail2ban "
    dpkg -l clamav 2>/dev/null | grep -q "^ii" && installed_apps+="clamav "
    dpkg -l auditd 2>/dev/null | grep -q "^ii" && installed_apps+="auditd "

    echo "$installed_apps"
}

generate_config_from_selections() {
    local selections="$1"

    cat > "$CONFIG_FILE" <<EOF
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

snap_apps:
EOF

    # Snap apps
    if [[ "$selections" == *"vivaldi"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: vivaldi
    enabled: true
    category: browser
    description: "Modern Chromium-based browser"
EOF
    fi

    if [[ "$selections" == *"bitwarden"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: bitwarden
    enabled: true
    category: security
    description: "Password manager"
EOF
    fi

    if [[ "$selections" == *"notepad"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: notepad-plus-plus
    enabled: true
    category: development
    description: "Advanced text editor"
EOF
    fi

    if [[ "$selections" == *"notion"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: notion-snap-reborn
    enabled: true
    category: productivity
    description: "Note-taking and collaboration"
EOF
    fi

    if [[ "$selections" == *"mailspring"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: mailspring
    enabled: true
    category: communication
    description: "Email client"
EOF
    fi

    if [[ "$selections" == *"claude-code"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: claude-code
    enabled: true
    category: development
    description: "Claude AI code assistant CLI"
EOF
    fi

    if [[ "$selections" == *"chatgpt"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: chatgpt-desktop-client
    enabled: true
    category: productivity
    description: "ChatGPT desktop application"
EOF
    fi

    if [[ "$selections" == *"icloud"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: icloud-for-linux
    enabled: true
    category: cloud
    description: "iCloud integration"
EOF
    fi

    # DEB apps
    cat >> "$CONFIG_FILE" <<EOF

################################################################################
# DEB PACKAGE APPLICATIONS
################################################################################

deb_apps:
EOF

    if [[ "$selections" == *"discord"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: discord
    url: "https://discord.com/api/download?platform=linux&format=deb"
    dest: "/tmp/zoolandia_ansible_downloads/discord.deb"
    enabled: true
    category: communication
    description: "Voice and text chat"
    retries: 3
    timeout: 1200
EOF
    fi

    if [[ "$selections" == *"zoom"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: zoom
    url: "https://zoom.us/client/latest/zoom_amd64.deb"
    dest: "/tmp/zoolandia_ansible_downloads/zoom_amd64.deb"
    enabled: true
    category: communication
    description: "Video conferencing"
    retries: 3
    timeout: 1200
EOF
    fi

    if [[ "$selections" == *"termius"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: termius
    url: "https://www.termius.com/download/linux/Termius.deb"
    dest: "/tmp/zoolandia_ansible_downloads/termius.deb"
    enabled: true
    category: development
    description: "SSH client"
    retries: 3
    timeout: 1200
EOF
    fi

    if [[ "$selections" == *"onlyoffice"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
  - name: onlyoffice
    url: "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
    dest: "/tmp/zoolandia_ansible_downloads/onlyoffice_amd64.deb"
    enabled: true
    category: productivity
    description: "Office suite"
    retries: 3
    timeout: 1200
EOF
    fi

    # Complex apps
    cat >> "$CONFIG_FILE" <<EOF

################################################################################
# COMPLEX APPLICATIONS
################################################################################

EOF

    if [[ "$selections" == *"docker"* ]]; then
        echo "install_docker: true" >> "$CONFIG_FILE"
    else
        echo "install_docker: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"portainer"* ]]; then
        echo "install_portainer: true" >> "$CONFIG_FILE"
    else
        echo "install_portainer: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"twingate"* ]]; then
        echo "install_twingate: true" >> "$CONFIG_FILE"
    else
        echo "install_twingate: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"protonvpn"* ]]; then
        echo "install_protonvpn: true" >> "$CONFIG_FILE"
    else
        echo "install_protonvpn: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"ulauncher"* ]]; then
        echo "install_ulauncher: true" >> "$CONFIG_FILE"
    else
        echo "install_ulauncher: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"n8n"* ]]; then
        echo "install_n8n: true" >> "$CONFIG_FILE"
    else
        echo "install_n8n: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"chrome-ext"* ]]; then
        echo "install_chrome_extensions: true" >> "$CONFIG_FILE"
    else
        echo "install_chrome_extensions: false" >> "$CONFIG_FILE"
    fi

    # System configurations
    cat >> "$CONFIG_FILE" <<EOF

################################################################################
# SYSTEM CONFIGURATION
################################################################################

EOF

    if [[ "$selections" == *"power"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
power_management:
  enabled: true
EOF
    else
        cat >> "$CONFIG_FILE" <<EOF
power_management:
  enabled: false
EOF
    fi

    if [[ "$selections" == *"touchpad"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
touchpad:
  enabled: true
EOF
    else
        cat >> "$CONFIG_FILE" <<EOF
touchpad:
  enabled: false
EOF
    fi

    if [[ "$selections" == *"nautilus"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
nautilus:
  enabled: true
EOF
    else
        cat >> "$CONFIG_FILE" <<EOF
nautilus:
  enabled: false
EOF
    fi

    if [[ "$selections" == *"mouse"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
mouse:
  enabled: true
EOF
    else
        cat >> "$CONFIG_FILE" <<EOF
mouse:
  enabled: false
EOF
    fi

    if [[ "$selections" == *"ntfs"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
ntfs_support:
  enabled: true
EOF
    else
        cat >> "$CONFIG_FILE" <<EOF
ntfs_support:
  enabled: false
EOF
    fi

    if [[ "$selections" == *"razer"* ]]; then
        cat >> "$CONFIG_FILE" <<EOF
razer_grub:
  enabled: true
EOF
    else
        cat >> "$CONFIG_FILE" <<EOF
razer_grub:
  enabled: false
EOF
    fi

    # Security tools
    cat >> "$CONFIG_FILE" <<EOF

################################################################################
# SECURITY TOOLS
################################################################################

EOF

    if [[ "$selections" == *"fail2ban"* ]]; then
        echo "install_fail2ban: true" >> "$CONFIG_FILE"
    else
        echo "install_fail2ban: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"clamav"* ]]; then
        echo "install_clamav: true" >> "$CONFIG_FILE"
    else
        echo "install_clamav: false" >> "$CONFIG_FILE"
    fi

    if [[ "$selections" == *"auditd"* ]]; then
        echo "install_auditd: true" >> "$CONFIG_FILE"
    else
        echo "install_auditd: false" >> "$CONFIG_FILE"
    fi

    echo -e "${GREEN}✅ Configuration generated: $CONFIG_FILE${NC}"
}

show_selection_menu() {
    local installed_apps="$1"

    # Helper function to determine if app is installed
    is_installed() {
        local app="$1"
        [[ " $installed_apps " =~ " $app " ]] && echo "ON" || echo "OFF"
    }

    local selections
    selections=$(dialog --clear --backtitle "Zoolandia Workstation Setup" \
        --title "Select Applications and Configurations" \
        --checklist "Use SPACE to select/deselect, ENTER to confirm.\n\n─── APPLICATIONS ───" 45 80 38 \
        "vivaldi" "Vivaldi Browser" $(is_installed "vivaldi") \
        "bitwarden" "Bitwarden Password Manager" $(is_installed "bitwarden") \
        "notepad" "Notepad++ Text Editor" $(is_installed "notepad") \
        "notion" "Notion Productivity App" $(is_installed "notion") \
        "mailspring" "Mailspring Email Client" $(is_installed "mailspring") \
        "claude-code" "Claude AI Code Assistant" $(is_installed "claude-code") \
        "chatgpt" "ChatGPT Desktop Client" $(is_installed "chatgpt") \
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
        "---" "─── SYSTEM CONFIGS ───────────────────────────" "OFF" \
        "power" "Power Management (lid close, sleep)" $(is_installed "power") \
        "touchpad" "Touchpad Settings (speed, tap-to-click)" $(is_installed "touchpad") \
        "mouse" "Mouse Settings (speed, acceleration)" $(is_installed "mouse") \
        "nautilus" "Nautilus File Manager (sort, view)" $(is_installed "nautilus") \
        "ntfs" "NTFS/exFAT Filesystem Support" $(is_installed "ntfs") \
        "razer" "Razer Laptop GRUB Config (Intel GPU fix)" $(is_installed "razer") \
        "----" "─── SECURITY TOOLS ───────────────────────────" "OFF" \
        "fail2ban" "Fail2ban Intrusion Prevention" $(is_installed "fail2ban") \
        "clamav" "ClamAV Antivirus" $(is_installed "clamav") \
        "auditd" "Auditd System Auditing" $(is_installed "auditd") \
        2>&1 >/dev/tty)

    echo "$selections"
}

run_ansible_with_config() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Starting Ansible playbook with selected configuration...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""

    cd "$SCRIPT_DIR"
    ansible-playbook "$PLAYBOOK" -e "@$CONFIG_FILE"

    local exit_code=$?

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ Installation completed successfully!${NC}"
    else
        echo -e "${RED}❌ Installation completed with errors (exit code: $exit_code)${NC}"
    fi
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"

    # Cleanup config file
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        echo -e "${YELLOW}🧹 Cleaned up temporary config file${NC}"
    fi
}

install_all() {
    echo -e "${GREEN}Installing all default applications and configurations...${NC}"

    cd "$SCRIPT_DIR"
    ansible-playbook "$PLAYBOOK"

    local exit_code=$?

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ Installation completed successfully!${NC}"
    else
        echo -e "${RED}❌ Installation completed with errors (exit code: $exit_code)${NC}"
    fi
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
}

################################################################################
# MAIN MENU
################################################################################

main_menu() {
    while true; do
        show_banner

        choice=$(dialog --clear --backtitle "Zoolandia Workstation Setup" \
            --title "Main Menu" \
            --menu "Choose installation method:" 15 60 5 \
            1 "Install All (Default Configuration)" \
            2 "Custom Selection (Choose Apps)" \
            3 "Dry Run (Test Without Installing)" \
            4 "View Documentation" \
            5 "Exit" \
            2>&1 >/dev/tty)

        case $choice in
            1)
                clear
                show_banner
                echo -e "${YELLOW}📦 Installing all default applications...${NC}"
                echo ""
                install_all
                read -p "Press ENTER to continue..."
                ;;
            2)
                clear
                # Detect already installed applications
                installed_apps=$(detect_installed_apps)
                selections=$(show_selection_menu "$installed_apps")

                if [ -n "$selections" ]; then
                    # Filter out already installed apps to show only newly selected ones
                    new_selections=""
                    for item in $selections; do
                        if [[ ! " $installed_apps " =~ " $item " ]]; then
                            new_selections+="$item "
                        fi
                    done

                    clear
                    show_banner
                    echo -e "${YELLOW}📝 Generating configuration from selections...${NC}"
                    generate_config_from_selections "$selections"
                    echo ""

                    if [ -n "$new_selections" ]; then
                        echo -e "${BLUE}Newly selected items to install:${NC}"
                        echo "$new_selections" | tr ' ' '\n' | sed 's/^/  - /'
                    else
                        echo -e "${YELLOW}No new items selected (all selected items are already installed)${NC}"
                    fi

                    if [ -n "$installed_apps" ]; then
                        echo ""
                        echo -e "${GREEN}Already installed items (will be reconfigured if needed):${NC}"
                        # Show which selected items are already installed
                        for item in $selections; do
                            if [[ " $installed_apps " =~ " $item " ]]; then
                                echo "  - $item"
                            fi
                        done
                    fi

                    echo ""
                    read -p "Press ENTER to start installation, or Ctrl+C to cancel..."
                    run_ansible_with_config
                else
                    dialog --msgbox "No selections made. Returning to main menu." 8 50
                fi
                read -p "Press ENTER to continue..."
                ;;
            3)
                clear
                show_banner
                echo -e "${YELLOW}🔍 Running dry run (check mode)...${NC}"
                echo ""
                cd "$SCRIPT_DIR"
                ansible-playbook "$PLAYBOOK" --check
                read -p "Press ENTER to continue..."
                ;;
            4)
                dialog --textbox "$SCRIPT_DIR/README.md" 30 80
                ;;
            5)
                clear
                echo -e "${GREEN}Thank you for using Zoolandia Workstation Setup!${NC}"
                exit 0
                ;;
            *)
                dialog --msgbox "Invalid option. Please try again." 8 50
                ;;
        esac
    done
}

################################################################################
# ENTRY POINT
################################################################################

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Do not run this script as root (sudo)${NC}"
    echo -e "${YELLOW}The script will request sudo password when needed.${NC}"
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ansible not found. Installing...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y ansible
fi

# Verify playbook exists
if [ ! -f "$PLAYBOOK" ]; then
    echo -e "${RED}❌ Playbook not found: $PLAYBOOK${NC}"
    echo -e "${YELLOW}Please run this script from the ansible directory.${NC}"
    exit 1
fi

# Start main menu
main_menu
