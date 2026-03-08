#!/bin/bash
################################################################################
# Zoolandia - System Management Module
################################################################################
# Description: System configuration and preparation functions
# Version: 1.0.0
# Dependencies: 00_init.sh, 01_config.sh
################################################################################

show_system_menu() {
    while true; do
        # Detect GPU status
        local gpu_status="\Z1Not Set/Found\Zn"
        if lspci 2>/dev/null | grep -iE "VGA|3D|Display" | grep -iE "NVIDIA|AMD|Intel" >/dev/null 2>&1; then
            local gpu_info
            gpu_info=$(lspci 2>/dev/null | grep -iE "VGA|3D|Display" | grep -iE "NVIDIA|AMD|Intel" | head -1 | sed 's/.*: //')
            gpu_status="\Z2${gpu_info}\Zn"
        fi

        # Detect Network adapter status
        local network_status="\Z1Not Set/Found\Zn"
        if [[ -n "$VPN_NETWORK_ADAPTER" ]]; then
            network_status="\Z2${VPN_NETWORK_ADAPTER}\Zn"
        elif ip link show 2>/dev/null | grep -E "^[0-9]+: (eth|ens|enp)" >/dev/null 2>&1; then
            local adapter
            adapter=$(ip link show 2>/dev/null | grep -E "^[0-9]+: (eth|ens|enp)" | head -1 | awk '{print $2}' | tr -d ':')
            network_status="\Z3${adapter} (not configured)\Zn"
        fi

        # Detect OS
        local detected_os
        detected_os=$(lsb_release -d 2>/dev/null | cut -f2 -d: | xargs || echo "Unknown Linux")

        # Build menu with compact layout and colors
        local menu_items=(
            "Mounts" "Rclone, SMB, NFS, etc."
            "Folders" "Set Folders"
            "GPU" "Graphics Card (for HW Transcoding) - $gpu_status"
            "Network" "Network Adapter (for VPN) - $network_status"
            "Docker Aliases" "Install Docker Aliases & Management"
            "Kubernetes Aliases" "Install Kubernetes Aliases & Management"
            "DevOps Aliases" "Install DevOps Aliases (Git, Ansible, Terraform, etc.)"
            "SMTP" "Add SMTP Details"
            "Back" "Return to main menu"
        )

        local info_text="HOW TO USE: Check About for recommendations on the order of steps. See Settings to hide this notification.\n\nDetected OS: \Z5${detected_os}\Zn"

        choice=$(dialog --colors --help-button --help-label "Settings" \
            --backtitle "$SCRIPT_NAME - System Preparation" \
            --title "System Preparation" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "$info_text\n\nSelect an option..." 24 80 8 \
            "${menu_items[@]}" 3>&1 1>&2 2>&3 3>&-)

        local ret=$?

        case $ret in
            0) # OK/Select pressed
                case "$choice" in
                    "Mounts") configure_mounts ;;
                    "Folders") configure_folders ;;
                    "GPU") detect_gpu ;;
                    "Network") configure_network_adapter ;;
                    "Docker Aliases") show_docker_aliases_menu ;;
                    "Kubernetes Aliases") show_kubernetes_aliases_menu ;;
                    "DevOps Aliases") show_devops_aliases_menu ;;
                    "SMTP") configure_smtp ;;
                    "Back") return ;;
                esac
                ;;
            2) # Help button (Settings)
                show_settings_menu
                ;;
            *) # Cancel or ESC
                return
                ;;
        esac
    done
}

configure_environment() {
    # Check if Docker folder is set
    if [[ -z "$DOCKER_DIR" || "$DOCKER_DIR" == "/root/docker" || "$DOCKER_DIR" == "/home/*/docker" ]]; then
        clear
        echo ""
        echo "---> Set the Docker folder in the Prerequisites menu."
        echo ""
        echo "[ERROR] Above requirements were not met. Complete them and re-run this step."
        echo ""
        echo "Going back to the menu in 60 seconds. Or, press OK to go back now..."

        dialog --timeout 60 --msgbox "[ERROR] Docker folder not set!\n\n---> Set the Docker folder in the Prerequisites menu.\n\nComplete this requirement and re-run Environment setup." 12 70
        return
    fi

    # Check if Docker folder already exists
    if [[ -d "$DOCKER_DIR" ]]; then
        # Docker folder exists - show menu
        local choice=$(dialog --colors \
            --backtitle "$SCRIPT_NAME by hack3r.gg - v$ZOOLANDIA_VERSION" \
            --title "Create Docker Root Folder" \
            --ok-label "Select" \
            --cancel-label "Cancel" \
            --menu "Docker Root Folder (\Z5$DOCKER_DIR\Zn) already exists.\n\nWhat would you like to do?" 14 75 3 \
            "Recreate" "Backup existing and create a new folder" \
            "Reuse" "Backup and recreate folder while keeping appdata, .env, secrets, and custom.yml" \
            "Exit" "Make no changes" \
            3>&1 1>&2 2>&3 3>&-)

        case "$choice" in
            "Recreate")
                setup_new_docker_environment "recreate"
                ;;
            "Reuse")
                setup_new_docker_environment "reuse"
                ;;
            "Exit"|"")
                return
                ;;
        esac
    else
        # First time setup
        setup_new_docker_environment "new"
    fi
}

setup_new_docker_environment() {
    local mode="$1"  # new, recreate, or reuse

    clear
    echo ""
    echo "############# Setup Docker Environment #############"
    echo ""

    # Backup existing folder if it exists
    if [[ "$mode" == "recreate" || "$mode" == "reuse" ]]; then
        if [[ -d "$DOCKER_DIR" ]]; then
            local backup_dest="${DOCKER_DIR}-backup-$(date +%Y%m%d_%H%M%S)"
            echo "Creating a cold tar backup of $DOCKER_DIR..."
            echo "--- Removing 'lookup_#' from member names"

            # Create backup using tar
            sudo tar --warning=no-file-changed -czf "${backup_dest}.tar.gz" -C "$(dirname "$DOCKER_DIR")" "$(basename "$DOCKER_DIR")" 2>/dev/null || true

            if [[ -f "${backup_dest}.tar.gz" ]]; then
                echo "[INFO] Backup created: ${backup_dest}.tar.gz"

                if [[ "$mode" == "reuse" ]]; then
                    # Save important files before removing
                    local temp_save="/tmp/zoolandia_save_$$"
                    mkdir -p "$temp_save"

                    [[ -f "$DOCKER_DIR/.env" ]] && cp -p "$DOCKER_DIR/.env" "$temp_save/" 2>/dev/null
                    [[ -d "$DOCKER_DIR/secrets" ]] && cp -rp "$DOCKER_DIR/secrets" "$temp_save/" 2>/dev/null
                    [[ -d "$DOCKER_DIR/compose/$HOSTNAME" ]] && cp -rp "$DOCKER_DIR/compose/$HOSTNAME" "$temp_save/" 2>/dev/null
                    [[ -d "$DOCKER_DIR/appdata" ]] && cp -rp "$DOCKER_DIR/appdata" "$temp_save/" 2>/dev/null
                fi
            fi
        fi
    fi

    echo "Creating new Docker Environment: $DOCKER_DIR"

    # Create Docker root folder
    sudo mkdir -p "$DOCKER_DIR"
    sudo chown "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR"
    echo "[INFO] Docker Root Folder (to store all container data) created: $DOCKER_DIR"
    echo ""

    # Set ACLs for Docker Root Folder
    echo "Setting ACLs for Docker Root Folder..."
    if command -v setfacl &>/dev/null; then
        sudo setfacl -Rdm g:"$PRIMARY_USERNAME":rwx "$DOCKER_DIR" 2>/dev/null || true
        sudo setfacl -Rm g:"$PRIMARY_USERNAME":rwx "$DOCKER_DIR" 2>/dev/null || true
        echo "[INFO] ACLs set for $DOCKER_DIR"
    fi
    echo ""

    # Create folder structure
    echo "Creating few more folders..."

    # Create appdata folder
    if [[ "$mode" == "reuse" && -d "/tmp/zoolandia_save_$$/appdata" ]]; then
        sudo cp -rp "/tmp/zoolandia_save_$$/appdata" "$DOCKER_DIR/"
        echo "[INFO] appdata folder restored: $DOCKER_DIR/appdata"
    else
        sudo mkdir -p "$DOCKER_DIR/appdata"
        sudo chown "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR/appdata"
        echo "[INFO] appdata folder created: $DOCKER_DIR/appdata"
    fi

    # Create secrets folder
    if [[ "$mode" == "reuse" && -d "/tmp/zoolandia_save_$$/secrets" ]]; then
        sudo cp -rp "/tmp/zoolandia_save_$$/secrets" "$DOCKER_DIR/"
        sudo chown -R "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR/secrets"
        sudo chmod 750 "$DOCKER_DIR/secrets"
        echo "[INFO] secrets folder restored: $DOCKER_DIR/secrets"
    else
        sudo mkdir -p "$DOCKER_DIR/secrets"
        sudo chown "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR/secrets"
        sudo chmod 750 "$DOCKER_DIR/secrets"
        echo "[INFO] secrets folder created: $DOCKER_DIR/secrets"
    fi

    # Create compose folder structure
    sudo mkdir -p "$DOCKER_DIR/compose/$HOSTNAME"
    sudo chown -R "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR/compose"
    echo "[INFO] compose folder created: $DOCKER_DIR/compose/$HOSTNAME"

    # Create custom.yml in compose folder
    if [[ "$mode" == "reuse" && -f "/tmp/zoolandia_save_$$/$HOSTNAME/custom.yml" ]]; then
        sudo cp -p "/tmp/zoolandia_save_$$/$HOSTNAME/custom.yml" "$DOCKER_DIR/compose/$HOSTNAME/"
        echo "[INFO] custom.yml restored"
    else
        cp "$SCRIPT_DIR/includes/docker/custom.yml" "$DOCKER_DIR/compose/$HOSTNAME/custom.yml"
        echo "[INFO] custom.yml created"
    fi

    echo ""
    echo "Creating .env file..."

    # Create or restore .env file
    if [[ "$mode" == "reuse" && -f "/tmp/zoolandia_save_$$/.env" ]]; then
        sudo cp -p "/tmp/zoolandia_save_$$/.env" "$DOCKER_DIR/"
        sudo chown "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR/.env"
        sudo chmod 640 "$DOCKER_DIR/.env"
        echo "[INFO] .env file restored"
    else
        # Generate new .env file
        local server_ip=$(hostname -I | awk '{print $1}' | xargs)
        local timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")

        cat > "$DOCKER_DIR/.env" << EOF
# Zoolandia Environment Configuration
# Generated on $(date)

# Domain Configuration

# User Configuration

# Docker Configuration

# Network Configuration
SERVER_IP=$server_ip
SERVER_LAN_IP=$server_ip

# Traefik Configuration
TRAEFIK_PORT=8080
CF_DNS_API_TOKEN=

# Database Passwords (Change these!)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
MARIADB_ROOT_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

AUTHENTIK_VERSION_PIN=2025.10.1
AUTHENTIKWORKER_VERSION_PIN=2025.10.1
AUTHELIA_VERSION_PIN=4.39.14
TINYAUTH_VERSION_PIN=v3
TRAEFIK_VERSION_PIN=3.6
POSTGRESQL_VERSION_PIN=18-alpine
IMMICH_VERSION_PIN=v2.2.3
IMMICHDB_VERSION_PIN=pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
DEPLOYRRDASHBOARD_VERSION_PIN=v1.7.0
PUID=$CURRENT_UID
PGID=$CURRENT_GID
PRIMARY_USERNAME=$PRIMARY_USERNAME
TZ=$timezone
USERDIR=$HOME
DOCKERDIR=$DOCKER_DIR
LOCAL_IPS=127.0.0.1/32,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12
CLOUDFLARE_IPS=173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22
DOMAINNAME_1=${DOMAIN_NAME_1:-}
HOSTNAME=$HOSTNAME

# Application Ports (add more as needed)
VSCODE_PORT=8443
EOF
        sudo chown "$PRIMARY_USERNAME":"$PRIMARY_USERNAME" "$DOCKER_DIR/.env"
        sudo chmod 640 "$DOCKER_DIR/.env"
        echo "[INFO] .env file created"
    fi

    echo ""
    echo "Adding environmental variables..."
    echo "[INFO] Added PUID: $CURRENT_UID"
    echo "[INFO] Added PGID: $CURRENT_GID"
    echo "[INFO] Added PRIMARY_USERNAME: $PRIMARY_USERNAME"

    echo ""
    echo "Setting permissions for various services..."
    echo "Creating starter docker-compose-$HOSTNAME.yml file..."

    # Create starter docker-compose file
    cp "$SCRIPT_DIR/includes/docker/starter.yml" "$DOCKER_DIR/docker-compose-$HOSTNAME.yml"
    echo "[INFO] Base compose file created."
    echo ""
    echo "[INFO] Docker Environment Created! Thu Dec 25 02:41:55 AM CST 2025"

    # Update ENV_FILE path
    ENV_FILE="$DOCKER_DIR/.env"
    save_config

    # Clean up temp files if reusing
    if [[ "$mode" == "reuse" && -d "/tmp/zoolandia_save_$$" ]]; then
        rm -rf "/tmp/zoolandia_save_$$"
    fi

    echo ""
    echo "Going back to the menu in 60 seconds. Or, press OK to go back now..."

    local display_docker_dir=$(display_path "$DOCKER_DIR")
    dialog --timeout 60 --msgbox "[INFO] Docker Environment Created Successfully!\n\nLocation: $display_docker_dir\n\nFiles created:\n- .env (environment variables)\n- docker-compose-$HOSTNAME.yml (main compose file)\n- compose/$HOSTNAME/custom.yml (custom services)\n- appdata/ (application data)\n- secrets/ (sensitive data)" 18 70
}

create_folders() {
    local folders=(
        "$DOCKER_DIR/appdata"
        "$DOCKER_DIR/compose"
        "$DOCKER_DIR/logs"
        "$DOCKER_DIR/secrets"
        "$DOCKER_DIR/shared"
        "/data/downloads"
        "/data/media/movies"
        "/data/media/tv"
        "/data/media/music"
        "/data/media/books"
        "/data/media/photos"
    )

    dialog --infobox "Creating folder structure..." 5 50

    for folder in "${folders[@]}"; do
        mkdir -p "$folder"
        chown -R "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$folder" 2>/dev/null || true
    done

    dialog --msgbox "Folder structure created successfully!" 8 50
}

set_username() {
    local new_user
    new_user=$(dialog --ok-label "OK" --cancel-label "Cancel" --inputbox "Enter the Linux non-root username:" 10 60 "$CURRENT_USER" 3>&1 1>&2 2>&3 3>&-)

    if [[ -n "$new_user" ]] && id "$new_user" &>/dev/null; then
        CURRENT_USER="$new_user"
        PRIMARY_USERNAME="$new_user"
        CURRENT_UID=$(id -u "$CURRENT_USER")
        CURRENT_GID=$(id -g "$CURRENT_USER")
        save_config
        dialog --msgbox "Username set to: $CURRENT_USER\nUID: $CURRENT_UID\nGID: $CURRENT_GID" 10 50
    elif [[ -n "$new_user" ]]; then
        dialog --msgbox "User '$new_user' does not exist on this system!" 8 50
    fi
}

show_system_type_info() {
    dialog --colors --title "System Type Information" --msgbox "\
\Zb\Z4Understanding System Types\Zn

Zoolandia adapts its behavior based on your system type. Here's what each type means and how it affects your deployment:

\Zb\Z2═══ BAREBONES ═══\Zn
\ZbWhen to use:\Zn Physical servers, bare metal installations
\ZbDetection:\Zn Default fallback when no other type detected
\ZbOptimizations:\Zn
  • Full hardware access assumed
  • No virtualization overhead considerations
  • Direct hardware monitoring enabled
  • Optimal for dedicated server hardware
\ZbUse cases:\Zn Home servers, dedicated hosting, rack servers

\Zb\Z2═══ VM (Virtual Machine) ═══\Zn
\ZbWhen to use:\Zn VMware, VirtualBox, KVM, QEMU, Xen environments
\ZbDetection:\Zn Checks /proc/cpuinfo for hypervisor flags
\ZbOptimizations:\Zn
  • Adjusted resource expectations
  • VM-aware disk I/O settings
  • Recognizes shared resource environment
  • Appropriate for virtio and paravirt devices
\ZbUse cases:\Zn Proxmox VMs, ESXi guests, home lab VMs

\Zb\Z2═══ LXC (Linux Container) ═══\Zn
\ZbWhen to use:\Zn LXC/LXD containers, Docker hosts
\ZbDetection:\Zn Checks /proc/1/cgroup and /.dockerenv
\ZbOptimizations:\Zn
  • Container-aware networking
  • Lightweight resource allocation
  • Shared kernel considerations
  • AppArmor/SELinux container profiles
\ZbUse cases:\Zn Proxmox LXC, LXD containers, container-in-container

\Zb\Z2═══ WSL (Windows Subsystem for Linux) ═══\Zn
\ZbWhen to use:\Zn Running on Windows with WSL/WSL2
\ZbDetection:\Zn Checks /proc/version for microsoft/wsl
\ZbOptimizations:\Zn
  • WSL-specific path handling
  • Windows filesystem integration
  • Network bridge considerations
  • systemd compatibility adjustments
\ZbUse cases:\Zn Development on Windows, testing, learning

\Zb\Z2═══ LAPTOP ═══\Zn
\ZbWhen to use:\Zn Laptops, mobile devices (battery present)
\ZbDetection:\Zn Checks for battery in /sys/class/power_supply/
\ZbOptimizations:\Zn
  • Power management awareness
  • Thermal throttling considerations
  • Portable deployment assumptions
  • Intermittent connectivity handling
\ZbUse cases:\Zn Mobile servers, portable dev environments

\Zb\Z2═══ WORKSTATION ═══\Zn
\ZbWhen to use:\Zn Desktop workstations, high-end desktops
\ZbDetection:\Zn GPU present + 4+ CPU cores
\ZbOptimizations:\Zn
  • GPU passthrough awareness
  • High-performance configurations
  • Desktop environment coexistence
  • Multi-tasking resource allocation
\ZbUse cases:\Zn Developer workstations, gaming PCs, content creation

\Zb\Z3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\Zn

\Zb\Z6IMPORTANT:\Zn The system type affects:
  ✓ Resource allocation strategies
  ✓ Monitoring and health check configurations
  ✓ Network and storage optimizations
  ✓ Container runtime settings
  ✓ Backup and snapshot strategies
  ✓ Performance tuning parameters

\Zb\Z6TIP:\Zn If auto-detection is wrong (e.g., laptop used as server),
manually select the type that matches your \ZbUSE CASE\Zn, not just
your hardware. A laptop used 24/7 as a server should be set to
'Barebones' or 'Workstation' for optimal configuration.

Press OK to return to the menu..." 45 78
}

show_system_type() {
    local auto_detected=$(detect_system_type)
    local current_type="$SYSTEM_TYPE"

    # Get OS version for display
    local os_version=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown OS")

    # Build menu items with descriptions
    local menu_items=()
    menu_items+=("Unprivileged LXC" "on Proxmox")
    menu_items+=("Privileged LXC" "on Proxmox")
    menu_items+=("Virtual Machine" "on any Hypervisor (Proxmox, WSL, ESXi, VirtualBox, etc.)")
    menu_items+=("Barebones" "OS directly on the hardware")
    menu_items+=("VPS" "Virtual Private Server in the cloud")
    menu_items+=("---" "───────────────────────────────────────────────────")
    menu_items+=("Info" "Learn about system types and their implications")

    local choice=$(dialog --colors \
        --backtitle "$SCRIPT_NAME by http://hack3r.gg - v$ZOOLANDIA_VERSION" \
        --title "Pick your System Type" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --default-item "$current_type" \
        --menu "Current: \Z4$current_type\Zn | Auto-Detected: \Z2$auto_detected\Zn\n\nSelect the type of your system that runs your \Z5${os_version}\Zn:" 20 80 7 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3 3>&-)

    case "$choice" in
        "Info")
            show_system_type_info
            show_system_type  # Return to this menu after viewing info
            ;;
        "---")
            show_system_type  # Ignore separator, show menu again
            ;;
        "")
            return 0
            ;;
        *)
            SYSTEM_TYPE="$choice"
            save_config
            dialog --colors --msgbox "System type set to: \Z4$SYSTEM_TYPE\Zn" 8 50
            ;;
    esac
}

select_system_type() {
    show_system_type
}

show_setup_mode_info() {
    dialog --colors --title "Setup Mode Information" --msgbox "\
\Zb\Z4Understanding Setup Modes\Zn

Zoolandia supports two deployment modes that determine how your applications are accessed and secured. Choose the mode that best fits your use case:

\Zb\Z2═══════════════════════════════════════════════════════════════\Zn
\Zb\Z6LOCAL MODE\Zn - Simple, Direct Access
\Zb\Z2═══════════════════════════════════════════════════════════════\Zn

\ZbWhat it is:\Zn
  Apps are exposed directly on ports without a reverse proxy.
  Each app gets its own port number (e.g., 8080, 9000, 3000).

\ZbAccess Method:\Zn
  http://SERVER_IP:PORT (e.g., http://192.168.1.100:8080)

\ZbRequirements:\Zn
  ✓ None - works out of the box
  ✗ No domain name needed
  ✗ No SSL certificates needed
  ✗ No DNS configuration needed

\ZbSecurity:\Zn
  • Apps accessible to anyone on your network
  • No built-in authentication layer
  • HTTP only (unencrypted)
  • Firewall protection recommended

\ZbPros:\Zn
  ✓ Simple setup - no prerequisites
  ✓ Fast deployment - no waiting for SSL certs
  ✓ No domain costs
  ✓ Perfect for learning and testing
  ✓ Ideal for internal network only access

\ZbCons:\Zn
  ✗ No HTTPS/encryption
  ✗ Not suitable for external access
  ✗ Must remember port numbers
  ✗ No centralized authentication

\ZbBest for:\Zn
  • Single-server homelabs
  • Internal network only
  • Testing and development
  • Learning Docker and containers
  • Privacy-focused (no external exposure)

\Zb\Z2═══════════════════════════════════════════════════════════════\Zn
\Zb\Z6HYBRID MODE\Zn - Traefik Reverse Proxy with SSL
\Zb\Z2═══════════════════════════════════════════════════════════════\Zn

\ZbWhat it is:\Zn
  Apps are behind Traefik reverse proxy with automatic SSL.
  Access via subdomains (e.g., app.yourdomain.com).

\ZbAccess Method:\Zn
  https://subdomain.yourdomain.com (e.g., https://portainer.example.com)

\ZbRequirements:\Zn
  ✓ Domain name (can use free dynamic DNS)
  ✓ DNS provider with API (Cloudflare supported)
  ✓ Ports 80/443 open and forwarded
  ✓ Valid email for Let's Encrypt

\ZbSecurity:\Zn
  • HTTPS encryption (Let's Encrypt SSL)
  • Optional authentication (Authelia/Authentik/OAuth)
  • Centralized access control
  • Headers security (HSTS, CSP, etc.)
  • Rate limiting and DDoS protection

\ZbPros:\Zn
  ✓ Professional HTTPS access
  ✓ Easy-to-remember URLs
  ✓ External access capability
  ✓ Centralized authentication
  ✓ SSL certificate auto-renewal
  ✓ Advanced routing and middlewares

\ZbCons:\Zn
  ✗ Requires domain name
  ✗ Requires DNS API access
  ✗ More complex initial setup
  ✗ External exposure (security risk if misconfigured)

\ZbBest for:\Zn
  • External access to services
  • Multiple users/family sharing
  • Production-like environments
  • Remote work scenarios
  • Services that need HTTPS

\Zb\Z2═══════════════════════════════════════════════════════════════\Zn

\Zb\Z3PACKAGES & PREREQUISITES:\Zn

\ZbLocal Mode:\Zn
  • No additional packages required
  • Docker and Docker Compose only
  • Apps installed with port mappings

\ZbHybrid Mode:\Zn
  • Traefik reverse proxy (automatically installed)
  • Socket Proxy (security layer for Docker socket)
  • Optional: Authelia/Authentik (SSO authentication)
  • Optional: CrowdSec (intrusion prevention)
  • Requires: Cloudflare API token for DNS challenge

\Zb\Z3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\Zn

\Zb\Z6SWITCHING MODES:\Zn
You can start with Local mode and switch to Hybrid later.
Existing apps can be reconfigured when switching modes.

\Zb\Z6RECOMMENDATION:\Zn
• Start with \ZbLocal\Zn if you're new to Docker
• Use \ZbHybrid\Zn if you need external access
• Use \ZbLocal\Zn if privacy is your top priority

Press OK to return to the menu..." 60 75
}

toggle_setup_mode() {
    local current_mode="${SETUP_MODE:-Local}"

    local choice=$(dialog --colors \
        --backtitle "$SCRIPT_NAME by http://hack3r.gg - v$ZOOLANDIA_VERSION" \
        --title "Select Setup Mode" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --default-item "$current_mode" \
        --menu "Current Mode: \Z4$current_mode\Zn\n\nHow should apps be configured?" 16 75 4 \
        "Local" "Apps accessible only on this server (no reverse proxy)" \
        "Hybrid" "Apps accessible via Traefik reverse proxy (external access)" \
        "---" "───────────────────────────────────────────────────" \
        "Info" "Learn about setup modes and their implications" \
        3>&1 1>&2 2>&3 3>&-)

    case "$choice" in
        "Info")
            show_setup_mode_info
            toggle_setup_mode  # Return to this menu after viewing info
            ;;
        "---")
            toggle_setup_mode  # Ignore separator, show menu again
            ;;
        "")
            return 0
            ;;
        *)
            if [[ "$choice" != "$current_mode" ]]; then
                SETUP_MODE="$choice"
                save_config

                local mode_info=""
                if [[ "$SETUP_MODE" == "Local" ]]; then
                    mode_info="Apps accessible via: http://SERVER_IP:PORT"
                else
                    mode_info="Apps accessible via: https://subdomain.yourdomain.com"
                fi

                dialog --colors --msgbox "Setup Mode set to: \Z4$SETUP_MODE\Zn\n\n$mode_info" 10 60
            fi
            ;;
    esac
}

set_backups_folder() {
    local new_folder
    new_folder=$(dialog --inputbox "Enter the backups folder path:" 10 60 "$BACKUP_DIR" 3>&1 1>&2 2>&3 3>&-)

    if [[ -n "$new_folder" ]]; then
        BACKUP_DIR="$new_folder"
        mkdir -p "$BACKUP_DIR" 2>/dev/null
        save_config
        dialog --msgbox "Backups folder set to:\n$BACKUP_DIR" 10 60
    fi
}

set_server_ip() {
    local detected_ip=$(hostname -I | awk '{print $1}')
    local new_ip
    new_ip=$(dialog --inputbox "Enter the server IP address:" 10 60 "${SERVER_IP:-$detected_ip}" 3>&1 1>&2 2>&3 3>&-)

    if [[ -n "$new_ip" ]]; then
        SERVER_IP="$new_ip"
        save_config
        dialog --msgbox "Server IP set to: $SERVER_IP" 8 50
    fi
}

set_domain() {
    local new_domain
    new_domain=$(dialog --inputbox "Enter your primary domain name:\n(Leave empty if not using reverse proxy)" 10 60 "$DOMAIN_1" 3>&1 1>&2 2>&3 3>&-)

    DOMAIN_1="$new_domain"
    save_config

    if [[ -z "$DOMAIN_1" ]]; then
        dialog --msgbox "Domain cleared. You can set it later when needed." 8 50
    else
        dialog --msgbox "Primary domain set to: $DOMAIN_1" 8 50
    fi
}

run_domain_checks() {
    if [[ -z "$DOMAIN_1" ]]; then
        dialog --msgbox "Domain Checks\n\nNo domain configured.\n\nDomain checks are only required if you plan to use a reverse proxy (Traefik) for remote access." 12 60
        return
    fi

    dialog --infobox "Running domain checks..." 5 40
    sleep 1

    local results="Domain Checks for: $DOMAIN_1\n\n"

    # Check if domain resolves
    if host "$DOMAIN_1" &>/dev/null; then
        results+="✓ Domain resolves\n"
    else
        results+="✗ Domain does not resolve\n"
    fi

    # Check if domain points to server
    local domain_ip=$(host "$DOMAIN_1" 2>/dev/null | grep "has address" | awk '{print $4}' | head -1)
    if [[ -n "$domain_ip" ]] && [[ "$domain_ip" == "${SERVER_IP}" ]]; then
        results+="✓ Domain points to server IP\n"
    elif [[ -n "$domain_ip" ]]; then
        results+="✗ Domain points to $domain_ip (expected: ${SERVER_IP:-NOT SET})\n"
    else
        results+="✗ Could not determine domain IP\n"
    fi

    dialog --title "Domain Checks" --msgbox "$results" 14 70

    # Mark domain checks as completed (checks were run — informational)
    mkdir -p "$ZOOLANDIA_CONFIG_DIR"
    touch "$ZOOLANDIA_CONFIG_DIR/domain_checks_done"
    DOMAIN_CHECKS_DONE=true
}

verify_license() {
    dialog --title "Zoolandia License" --msgbox "Your Zoolandia License: Free\n\nFree tier includes:\n- Local app deployment\n- System preparation tools\n- Docker management\n- Basic features\n\nFor advanced features (Traefik, Auth providers, etc.),\nvisit: https://www.hack3r.gg/zoolandia/" 16 70
}

set_docker_folder() {
    local new_folder
    new_folder=$(dialog --inputbox "Enter the Docker installation directory:" 10 60 "$DOCKER_DIR" 3>&1 1>&2 2>&3 3>&-)

    if [[ -n "$new_folder" ]]; then
        local real_new real_script
        real_new=$(realpath -m "$new_folder" 2>/dev/null || echo "$new_folder")
        real_script=$(realpath "$SCRIPT_DIR" 2>/dev/null || echo "$SCRIPT_DIR")
        if [[ "$real_new" == "$real_script"* ]]; then
            dialog --msgbox "Invalid path: Docker folder cannot be inside the Zoolandia directory.\n\nChoose a path outside:\n  $real_script" 10 65
            return
        fi
        DOCKER_DIR="$new_folder"
        ENV_FILE="${DOCKER_DIR}/.env"
        COMPOSE_FILE="${DOCKER_DIR}/docker-compose.yml"
        SECRETS_DIR="${DOCKER_DIR}/secrets"
        mkdir -p "$DOCKER_DIR" 2>/dev/null
        save_config
        local display_docker_dir=$(display_path "$DOCKER_DIR")
        local display_env_file=$(display_path "$ENV_FILE")
        local display_compose_file=$(display_path "$COMPOSE_FILE")
        local display_secrets_dir=$(display_path "$SECRETS_DIR")
        dialog --msgbox "Docker folder set to:\n$display_docker_dir\n\nRelated paths updated:\n- .env: $display_env_file\n- compose: $display_compose_file\n- secrets: $display_secrets_dir" 14 70
    fi
}

configure_mounts() {
    local mount_choice
    mount_choice=$(dialog --colors --menu "Configure Network Mounts\n\nSelect mount type to configure:" 18 70 5 \
        "Rclone" "Configure Rclone cloud storage" \
        "SMB/CIFS" "Configure SMB/Windows shares" \
        "NFS" "Configure NFS shares" \
        "View Mounts" "View currently configured mounts" \
        "Back" "Return to System menu" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$mount_choice" in
        "Rclone")
            if ! command -v rclone &>/dev/null; then
                if dialog --yesno "Rclone is not installed. Would you like to install it now?" 8 60; then
                    dialog --infobox "Installing Rclone..." 5 40
                    curl https://rclone.org/install.sh | sudo bash 2>&1 | tee /tmp/rclone_install.log
                    if command -v rclone &>/dev/null; then
                        dialog --msgbox "Rclone installed successfully!\n\nRun 'rclone config' to configure your remotes." 10 60
                    else
                        dialog --msgbox "Failed to install Rclone. Check /tmp/rclone_install.log" 10 60
                    fi
                fi
            else
                dialog --msgbox "Rclone is already installed.\n\nVersion: $(rclone version | head -1)\n\nRun 'rclone config' to manage your remotes." 12 60
            fi
            ;;
        "SMB/CIFS")
            local smb_share smb_mount smb_user smb_pass
            smb_share=$(dialog --inputbox "Enter SMB share (e.g., //server/share):" 10 60 3>&1 1>&2 2>&3 3>&-)
            [[ -z "$smb_share" ]] && return

            smb_mount=$(dialog --inputbox "Enter local mount point (e.g., /mnt/smb):" 10 60 3>&1 1>&2 2>&3 3>&-)
            [[ -z "$smb_mount" ]] && return

            smb_user=$(dialog --inputbox "Enter username (leave empty for guest):" 10 60 3>&1 1>&2 2>&3 3>&-)
            smb_pass=$(dialog --passwordbox "Enter password (leave empty for guest):" 10 60 3>&1 1>&2 2>&3 3>&-)

            # Install cifs-utils if needed
            if ! dpkg -l | grep -q cifs-utils; then
                dialog --infobox "Installing cifs-utils..." 5 40
                sudo apt-get update && sudo apt-get install -y cifs-utils
            fi

            sudo mkdir -p "$smb_mount"

            # Create credentials file if user provided
            local creds_opt=""
            if [[ -n "$smb_user" ]]; then
                local creds_file="/root/.smbcredentials_$(basename $smb_mount)"
                echo "username=$smb_user" | sudo tee "$creds_file" >/dev/null
                echo "password=$smb_pass" | sudo tee -a "$creds_file" >/dev/null
                sudo chmod 600 "$creds_file"
                creds_opt="credentials=$creds_file"
            else
                creds_opt="guest"
            fi

            # Add to fstab
            local fstab_entry="$smb_share $smb_mount cifs $creds_opt,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0"

            if dialog --yesno "Add this mount to /etc/fstab for automatic mounting?\n\n$fstab_entry" 12 80; then
                echo "$fstab_entry" | sudo tee -a /etc/fstab
                sudo mount -a
                dialog --msgbox "SMB mount configured!\n\nMount point: $smb_mount\nShare: $smb_share" 10 60
            fi
            ;;
        "NFS")
            local nfs_share nfs_mount
            nfs_share=$(dialog --inputbox "Enter NFS share (e.g., server:/export):" 10 60 3>&1 1>&2 2>&3 3>&-)
            [[ -z "$nfs_share" ]] && return

            nfs_mount=$(dialog --inputbox "Enter local mount point (e.g., /mnt/nfs):" 10 60 3>&1 1>&2 2>&3 3>&-)
            [[ -z "$nfs_mount" ]] && return

            # Install nfs-common if needed
            if ! dpkg -l | grep -q nfs-common; then
                dialog --infobox "Installing nfs-common..." 5 40
                sudo apt-get update && sudo apt-get install -y nfs-common
            fi

            sudo mkdir -p "$nfs_mount"

            # Add to fstab
            local fstab_entry="$nfs_share $nfs_mount nfs defaults 0 0"

            if dialog --yesno "Add this mount to /etc/fstab for automatic mounting?\n\n$fstab_entry" 12 80; then
                echo "$fstab_entry" | sudo tee -a /etc/fstab
                sudo mount -a
                dialog --msgbox "NFS mount configured!\n\nMount point: $nfs_mount\nShare: $nfs_share" 10 60
            fi
            ;;
        "View Mounts")
            local mount_info
            mount_info=$(mount | grep -E "cifs|nfs|fuse.rclone" || echo "No network mounts found")
            dialog --title "Current Network Mounts" --msgbox "$mount_info" 20 80
            ;;
    esac
}

configure_folders() {
    local folder_choice
    folder_choice=$(dialog --colors --menu "Configure Custom Folders\n\nSelect folder to configure:" 18 70 6 \
        "Media" "Set media folder (movies, TV, music)" \
        "Downloads" "Set downloads folder" \
        "Data" "Set general data folder" \
        "Backups" "Set backups folder" \
        "View All" "View all configured folders" \
        "Back" "Return to System menu" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$folder_choice" in
        "Media")
            local media_folder
            media_folder=$(dialog --inputbox "Enter media folder path:" 10 60 "${MEDIA_FOLDER:-/mnt/media}" 3>&1 1>&2 2>&3 3>&-)
            if [[ -n "$media_folder" ]]; then
                MEDIA_FOLDER="$media_folder"
                mkdir -p "$MEDIA_FOLDER"/{movies,tv,music,photos} 2>/dev/null
                save_config
                dialog --msgbox "Media folder set to:\n$MEDIA_FOLDER\n\nSubfolders created:\n- movies\n- tv\n- music\n- photos" 12 60
            fi
            ;;
        "Downloads")
            local downloads_folder
            downloads_folder=$(dialog --inputbox "Enter downloads folder path:" 10 60 "${DOWNLOADS_FOLDER:-/mnt/downloads}" 3>&1 1>&2 2>&3 3>&-)
            if [[ -n "$downloads_folder" ]]; then
                DOWNLOADS_FOLDER="$downloads_folder"
                mkdir -p "$DOWNLOADS_FOLDER" 2>/dev/null
                save_config
                dialog --msgbox "Downloads folder set to:\n$DOWNLOADS_FOLDER" 10 60
            fi
            ;;
        "Data")
            local data_folder
            data_folder=$(dialog --inputbox "Enter data folder path:" 10 60 "${DATA_FOLDER:-/mnt/data}" 3>&1 1>&2 2>&3 3>&-)
            if [[ -n "$data_folder" ]]; then
                DATA_FOLDER="$data_folder"
                mkdir -p "$DATA_FOLDER" 2>/dev/null
                save_config
                dialog --msgbox "Data folder set to:\n$DATA_FOLDER" 10 60
            fi
            ;;
        "Backups")
            set_backups_folder
            ;;
        "View All")
            local folder_list="Configured Folders:\n\n"
            folder_list+="Docker: ${DOCKER_DIR:-Not set}\n"
            folder_list+="Backups: ${BACKUP_DIR:-Not set}\n"
            folder_list+="Media: ${MEDIA_FOLDER:-Not set}\n"
            folder_list+="Downloads: ${DOWNLOADS_FOLDER:-Not set}\n"
            folder_list+="Data: ${DATA_FOLDER:-Not set}\n"
            dialog --title "Configured Folders" --msgbox "$folder_list" 16 70
            ;;
    esac
}

detect_gpu() {
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -iE "VGA|3D|Display" || echo "No GPU detected")

    local nvidia_detected=false
    local amd_detected=false
    local intel_detected=false

    if echo "$gpu_info" | grep -iq "NVIDIA"; then
        nvidia_detected=true
    fi
    if echo "$gpu_info" | grep -iq "AMD"; then
        amd_detected=true
    fi
    if echo "$gpu_info" | grep -iq "Intel"; then
        intel_detected=true
    fi

    local gpu_menu=()
    [[ $nvidia_detected == true ]] && gpu_menu+=("NVIDIA" "Configure NVIDIA GPU")
    [[ $amd_detected == true ]] && gpu_menu+=("AMD" "Configure AMD GPU")
    [[ $intel_detected == true ]] && gpu_menu+=("Intel" "Configure Intel iGPU")
    gpu_menu+=("Info" "Show detected GPU information")
    gpu_menu+=("Back" "Return to System menu")

    local gpu_choice
    gpu_choice=$(dialog --colors --menu "GPU Detection and Configuration\n\n$gpu_info" 18 70 5 \
        "${gpu_menu[@]}" 3>&1 1>&2 2>&3 3>&-) || return

    case "$gpu_choice" in
        "NVIDIA")
            if ! command -v nvidia-smi &>/dev/null; then
                if dialog --yesno "NVIDIA drivers not detected.\n\nWould you like to install NVIDIA drivers and Docker runtime?" 10 60; then
                    dialog --infobox "Installing NVIDIA drivers and container toolkit...\nThis may take several minutes..." 6 60
                    (
                        sudo apt-get update
                        sudo apt-get install -y nvidia-driver-535

                        # Install NVIDIA Container Toolkit
                        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
                        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
                        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
                            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
                        sudo apt-get update
                        sudo apt-get install -y nvidia-container-toolkit
                        sudo nvidia-ctk runtime configure --runtime=docker
                        sudo systemctl restart docker
                    ) 2>&1 | tee /tmp/nvidia_install.log

                    dialog --msgbox "NVIDIA setup complete!\n\nPlease reboot your system for changes to take effect.\n\nLog: /tmp/nvidia_install.log" 12 60
                fi
            else
                local nvidia_info
                nvidia_info=$(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "Error querying GPU")
                dialog --msgbox "NVIDIA GPU Configured!\n\n$nvidia_info\n\nGPU is ready for hardware transcoding in Plex, Jellyfin, etc." 14 70
            fi
            ;;
        "AMD")
            dialog --msgbox "AMD GPU detected!\n\n$gpu_info\n\nFor hardware transcoding:\n- ROCm drivers may be needed\n- Add '--device=/dev/dri' to Docker containers\n- Set VAAPI/AMF in transcoding apps" 16 70
            ;;
        "Intel")
            # Check if render group exists and add user
            if getent group render >/dev/null; then
                if ! groups "$CURRENT_USER" | grep -q render; then
                    if dialog --yesno "Add user '$CURRENT_USER' to 'render' group for GPU access?" 8 60; then
                        sudo usermod -aG render "$CURRENT_USER"
                        dialog --msgbox "User added to render group!\n\nLog out and back in for changes to take effect." 10 60
                    fi
                fi
            fi
            dialog --msgbox "Intel iGPU detected!\n\n$gpu_info\n\nFor hardware transcoding:\n- Add '--device=/dev/dri' to Docker containers\n- User should be in 'render' and 'video' groups\n- Set QuickSync/VAAPI in transcoding apps" 16 70
            ;;
        "Info")
            local detailed_gpu
            detailed_gpu=$(lspci -v 2>/dev/null | grep -A 15 -iE "VGA|3D|Display" || echo "Could not get detailed GPU info")
            dialog --title "GPU Information" --msgbox "$detailed_gpu" 24 80
            ;;
    esac
}

configure_network_adapter() {
    local adapters
    adapters=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo\|docker\|br-" || echo "")

    if [[ -z "$adapters" ]]; then
        dialog --msgbox "No network adapters found!" 8 50
        return
    fi

    local adapter_menu=()
    while IFS= read -r adapter; do
        local adapter_info
        adapter_info=$(ip addr show "$adapter" | grep "inet " | awk '{print $2}' || echo "No IP")
        adapter_menu+=("$adapter" "$adapter_info")
    done <<< "$adapters"

    adapter_menu+=("Clear" "Clear VPN adapter selection")
    adapter_menu+=("Back" "Return to System menu")

    local adapter_choice
    adapter_choice=$(dialog --colors --menu "Select Network Adapter for VPN\n\nThis adapter will be used for VPN containers:" 20 70 10 \
        "${adapter_menu[@]}" 3>&1 1>&2 2>&3 3>&-) || return

    case "$adapter_choice" in
        "Clear")
            VPN_NETWORK_ADAPTER=""
            save_config
            dialog --msgbox "VPN network adapter cleared." 8 50
            ;;
        "Back")
            return
            ;;
        *)
            VPN_NETWORK_ADAPTER="$adapter_choice"
            save_config
            dialog --msgbox "VPN network adapter set to:\n$VPN_NETWORK_ADAPTER\n\nThis will be used for Gluetun and other VPN containers." 10 60
            ;;
    esac
}

show_docker_aliases_menu() {
    while true; do
        # Check installation status
        local docker_alias_status="Not installed"
        local docker_menu_status="Not installed"
        [[ -f "$HOME/.docker_aliases" ]] && docker_alias_status="\Z2Installed\Zn"
        [[ -f "$HOME/.local/bin/dom" ]] && docker_menu_status="\Z2Installed\Zn"

        local choice=$(dialog --colors \
            --backtitle "$SCRIPT_NAME - Docker Management" \
            --title "Docker Aliases & Management" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure Docker aliases and management tools:" 18 78 6 \
            "View Aliases" "Preview Docker/Compose aliases before installing" \
            "Install Aliases" "Install Docker/Compose bash aliases - $docker_alias_status" \
            "Run Docker Menu" "Launch Docker operations menu now (no install needed)" \
            "Install Docker Menu" "Install as 'dom' command - $docker_menu_status" \
            "Uninstall" "Remove installed Docker aliases and menu" \
            "Back" "Return to System menu" \
            3>&1 1>&2 2>&3 3>&-)

        case "$choice" in
            "View Aliases") view_docker_aliases ;;
            "Install Aliases") install_docker_aliases ;;
            "Run Docker Menu") run_docker_ops_menu ;;
            "Install Docker Menu") install_docker_ops_menu ;;
            "Uninstall") uninstall_docker_components ;;
            "Back"|"") return ;;
        esac
    done
}

show_kubernetes_aliases_menu() {
    while true; do
        # Check installation status
        local k8s_alias_status="Not installed"
        local k8s_menu_status="Not installed"
        [[ -f "$HOME/.k8s_aliases" ]] && k8s_alias_status="\Z2Installed\Zn"
        [[ -f "$HOME/.local/bin/k8m" ]] && k8s_menu_status="\Z2Installed\Zn"

        local choice=$(dialog --colors \
            --backtitle "$SCRIPT_NAME - Kubernetes Management" \
            --title "Kubernetes Aliases & Management" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure Kubernetes aliases and management tools:" 20 78 6 \
            "View Aliases" "Preview kubectl aliases before installing" \
            "Install Aliases" "Install kubectl bash aliases - $k8s_alias_status" \
            "Run K8s Menu" "Launch Kubernetes operations menu now (no install needed)" \
            "Install K8s Menu" "Install as 'k8m' command - $k8s_menu_status" \
            "Uninstall" "Remove installed Kubernetes aliases and menu" \
            "Back" "Return to System menu" \
            3>&1 1>&2 2>&3 3>&-)

        case "$choice" in
            "View Aliases") view_kubernetes_aliases ;;
            "Install Aliases") install_kubernetes_aliases ;;
            "Run K8s Menu") run_k8s_ops_menu ;;
            "Install K8s Menu") install_k8s_ops_menu ;;
            "Uninstall") uninstall_k8s_components ;;
            "Back"|"") return ;;
        esac
    done
}

show_devops_aliases_menu() {
    while true; do
        # Check installation status
        local devops_status="Not installed"
        [[ -f "$HOME/.devops_extras" ]] && devops_status="\Z2Installed\Zn"

        local choice=$(dialog --colors \
            --backtitle "$SCRIPT_NAME - DevOps Management" \
            --title "DevOps Aliases" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure DevOps aliases (Git, Ansible, Terraform, etc.):" 16 78 4 \
            "View Aliases" "Preview 150+ DevOps aliases before installing" \
            "Install Aliases" "Install DevOps bash aliases - $devops_status" \
            "Uninstall" "Remove installed DevOps aliases" \
            "Back" "Return to System menu" \
            3>&1 1>&2 2>&3 3>&-)

        case "$choice" in
            "View Aliases") view_devops_extras ;;
            "Install Aliases") install_devops_extras ;;
            "Uninstall") uninstall_devops_components ;;
            "Back"|"") return ;;
        esac
    done
}

install_docker_aliases() {
    local aliases_file="$HOME/.docker_aliases"
    local source_file="$SCRIPT_DIR/importing/docker.md"

    if dialog --yesno "Install Docker Bash Aliases?\n\nThis will add helpful Docker shortcuts:\n- dc (smart docker compose wrapper)\n- dps, dpa (docker ps variants)\n- dcu, dcd, dcr (compose shortcuts)\n- dlogs, denter_last (convenience functions)\n- Cleanup functions with confirmations\n- and many more...\n\nInstall location: $aliases_file" 18 75; then
        dialog --infobox "Installing Docker bash aliases..." 5 40

        # Extract bash code from markdown
        if [[ -f "$source_file" ]]; then
            # Extract all code blocks and create the aliases file
            awk '/^```bash$/,/^```$/ {if (!/^```/) print}' "$source_file" > "$aliases_file"

            # Source in bashrc if not already there
            if ! grep -q ".docker_aliases" "$HOME/.bashrc" 2>/dev/null; then
                {
                    echo ""
                    echo "# Load Docker bash aliases"
                    echo "[[ -f ~/.docker_aliases ]] && source ~/.docker_aliases"
                } >> "$HOME/.bashrc"
            fi

            dialog --msgbox "Docker aliases installed successfully!\n\nLocation: $aliases_file\n\nRestart your terminal or run:\nsource ~/.docker_aliases\n\nTo see all aliases, run: alias | grep '^d'" 16 70
        else
            dialog --msgbox "Failed to find docker.md source file.\n\nExpected location: $source_file" 10 70
        fi
    fi
}

install_kubernetes_aliases() {
    local aliases_file="$HOME/.k8s_aliases"
    local source_file="$SCRIPT_DIR/importing/kubernetes.md"

    # Check if kubectl is installed
    if ! command -v kubectl &>/dev/null; then
        if dialog --yesno "kubectl is not installed.\n\nKubernetes aliases require kubectl.\nWould you like to continue anyway?" 10 60; then
            : # continue
        else
            return
        fi
    fi

    if dialog --yesno "Install Kubernetes Bash Aliases?\n\nThis will add helpful kubectl shortcuts:\n- k (kubectl)\n- kctx, kns (context/namespace)\n- kgp, kgs, kgd (get pods/services/deployments)\n- klogs, kexec (logs and exec)\n- ksh (shell into pod)\n- and many more...\n\nInstall location: $aliases_file" 18 75; then
        dialog --infobox "Installing Kubernetes bash aliases..." 5 40

        if [[ -f "$source_file" ]]; then
            # Copy the pure bash file (no markdown extraction needed)
            cp "$source_file" "$aliases_file"
            chmod +x "$aliases_file"

            # Source in bashrc if not already there
            if ! grep -q ".k8s_aliases" "$HOME/.bashrc" 2>/dev/null; then
                {
                    echo ""
                    echo "# Load Kubernetes bash aliases"
                    echo "[[ -f ~/.k8s_aliases ]] && source ~/.k8s_aliases"
                } >> "$HOME/.bashrc"
            fi

            dialog --msgbox "Kubernetes aliases installed successfully!\n\nLocation: $aliases_file\n\nRestart your terminal or run:\nsource ~/.k8s_aliases\n\nTo see all aliases, run: alias | grep '^k'" 16 70
        else
            dialog --msgbox "Failed to find kubernetes.md source file.\n\nExpected location: $source_file" 10 70
        fi
    fi
}

install_docker_ops_menu() {
    local menu_script="$HOME/.local/bin/dom"
    local source_file="$SCRIPT_DIR/importing/docker-ops-menu.sh"

    if dialog --yesno "Install Docker Management Menu?\n\nThis will install an interactive TUI for Docker operations:\n- Container management (list, logs, exec)\n- Image management\n- Network and volume operations\n- Docker Compose shortcuts\n- Cleanup operations\n\nInstall location: $menu_script\nCommand: dom (short for Docker Ops Menu)" 18 75; then
        dialog --infobox "Installing Docker operations menu..." 5 40

        if [[ -f "$source_file" ]]; then
            # Create bin directory if needed
            mkdir -p "$HOME/.local/bin"

            # Copy and make executable
            cp "$source_file" "$menu_script"
            chmod +x "$menu_script"

            # Add to PATH if not already there
            if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
                {
                    echo ""
                    echo "# Add local bin to PATH"
                    echo 'export PATH="$HOME/.local/bin:$PATH"'
                } >> "$HOME/.bashrc"
            fi

            dialog --msgbox "Docker Management Menu installed successfully!\n\nLocation: $menu_script\n\nRun with command:\ndom\n\nRestart your terminal or run:\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" 16 70
        else
            dialog --msgbox "Failed to find docker-ops-menu.sh source file.\n\nExpected location: $source_file" 10 70
        fi
    fi
}

run_docker_ops_menu() {
    local source_file="$SCRIPT_DIR/importing/docker-ops-menu.sh"

    if [[ -f "$source_file" ]]; then
        clear
        bash "$source_file"
    else
        dialog --msgbox "Docker operations menu not found!\n\nExpected location: $source_file" 10 70
    fi
}

install_k8s_ops_menu() {
    local menu_script="$HOME/.local/bin/k8m"
    local source_file="$SCRIPT_DIR/importing/k8s-ops-menu.sh"

    # Check if kubectl is installed
    if ! command -v kubectl &>/dev/null; then
        dialog --msgbox "kubectl is not installed.\n\nKubernetes Management Menu requires kubectl.\n\nPlease install kubectl first." 10 60
        return
    fi

    if dialog --yesno "Install Kubernetes Management Menu?\n\nThis will install an interactive TUI for Kubernetes operations:\n- Context and namespace management\n- Pod operations (list, logs, exec)\n- Deployment management\n- Rollout operations\n- Resource cleanup\n\nInstall location: $menu_script\nCommand: k8m (short for K8s Menu)" 18 75; then
        dialog --infobox "Installing Kubernetes operations menu..." 5 40

        if [[ -f "$source_file" ]]; then
            # Create bin directory if needed
            mkdir -p "$HOME/.local/bin"

            # Copy and make executable
            cp "$source_file" "$menu_script"
            chmod +x "$menu_script"

            # Add to PATH if not already there
            if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
                {
                    echo ""
                    echo "# Add local bin to PATH"
                    echo 'export PATH="$HOME/.local/bin:$PATH"'
                } >> "$HOME/.bashrc"
            fi

            dialog --msgbox "Kubernetes Management Menu installed successfully!\n\nLocation: $menu_script\n\nRun with command:\nk8m\n\nRestart your terminal or run:\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" 16 70
        else
            dialog --msgbox "Failed to find k8s-ops-menu.sh source file.\n\nExpected location: $source_file" 10 70
        fi
    fi
}

run_k8s_ops_menu() {
    local source_file="$SCRIPT_DIR/importing/k8s-ops-menu.sh"

    # Check if kubectl is installed
    if ! command -v kubectl &>/dev/null; then
        dialog --msgbox "kubectl is not installed.\n\nKubernetes operations menu requires kubectl.\n\nPlease install kubectl first." 10 60
        return
    fi

    if [[ -f "$source_file" ]]; then
        clear
        bash "$source_file"
    else
        dialog --msgbox "Kubernetes operations menu not found!\n\nExpected location: $source_file" 10 70
    fi
}

view_docker_aliases() {
    local source_file="$SCRIPT_DIR/importing/docker.md"

    if [[ ! -f "$source_file" ]]; then
        dialog --msgbox "Source file not found!\n\nExpected: $source_file" 10 60
        return
    fi

    # Extract alias examples from markdown for preview
    local preview_text="Docker & Compose Bash Aliases Preview\n"
    preview_text+="=====================================\n\n"
    preview_text+="Smart Compose Wrapper:\n"
    preview_text+="  dc              - Auto-detect docker compose/docker-compose\n\n"
    preview_text+="Docker Commands (Safe):\n"
    preview_text+="  d, dps, dpa     - Docker & container listing\n"
    preview_text+="  dlog, dexec     - Logs & exec into containers\n"
    preview_text+="  dstats, dtop    - Container stats & top\n"
    preview_text+="  dimg, dnet      - Images & networks\n\n"
    preview_text+="Compose Commands (Safe):\n"
    preview_text+="  dcu, dcd        - Compose up/down\n"
    preview_text+="  dcl, dcp        - Compose logs/pull\n"
    preview_text+="  dcr, dcps       - Compose restart/ps\n\n"
    preview_text+="Helper Functions:\n"
    preview_text+="  dls             - Pretty container list\n"
    preview_text+="  dlogs <name>    - Follow logs by container name\n"
    preview_text+="  denter_last     - Exec into last started container\n\n"
    preview_text+="Cleanup Functions (with confirmation):\n"
    preview_text+="  dprune_containers, dprune_images\n"
    preview_text+="  dprune_volumes, dprune_system\n\n"
    preview_text+="Plus docker_ops_menu() interactive TUI!\n\n"
    preview_text+="Total: 30+ aliases and functions\n"
    preview_text+="Full details in: $source_file"

    dialog --title "Docker Aliases Preview" --msgbox "$preview_text" 30 70
}

view_kubernetes_aliases() {
    local source_file="$SCRIPT_DIR/importing/kubernetes.md"

    if [[ ! -f "$source_file" ]]; then
        dialog --msgbox "Source file not found!\n\nExpected: $source_file" 10 60
        return
    fi

    # Preview of Kubernetes aliases
    local preview_text="Kubernetes (kubectl) Bash Aliases Preview\n"
    preview_text+="=========================================\n\n"
    preview_text+="Core Aliases (Safe):\n"
    preview_text+="  k               - kubectl shortcut\n"
    preview_text+="  kctx, kctxs     - Context management\n"
    preview_text+="  kns, knset      - Namespace management\n\n"
    preview_text+="Get Resources:\n"
    preview_text+="  kget, kga       - Get resources\n"
    preview_text+="  kgp, kgpa       - Get pods (all namespaces)\n"
    preview_text+="  kgs, kgd        - Get services/deployments\n"
    preview_text+="  kgn, kgi        - Get nodes/ingress\n\n"
    preview_text+="Operations:\n"
    preview_text+="  kdesc           - Describe resources\n"
    preview_text+="  klogs           - Follow logs\n"
    preview_text+="  kexec           - Exec into pod\n"
    preview_text+="  kapp, kdel      - Apply/delete manifests\n\n"
    preview_text+="Helper Functions:\n"
    preview_text+="  kwhere          - Show current context & namespace\n"
    preview_text+="  ksn <ns>        - Quick namespace switch\n"
    preview_text+="  klog <pod>      - Follow logs by pod substring\n"
    preview_text+="  ksh <pod>       - Shell into pod by substring\n"
    preview_text+="  kroll, khist    - Rollout status & history\n\n"
    preview_text+="Total: 40+ aliases and functions\n"
    preview_text+="Full details in: $source_file"

    dialog --title "Kubernetes Aliases Preview" --msgbox "$preview_text" 30 70
}

view_devops_extras() {
    local source_file="$SCRIPT_DIR/importing/devops-extras.md"

    if [[ ! -f "$source_file" ]]; then
        dialog --msgbox "Source file not found!\n\nExpected: $source_file" 10 60
        return
    fi

    # Preview of DevOps extras
    local preview_text="Additional DevOps Aliases Preview\n"
    preview_text+="==================================\n\n"
    preview_text+="Git Version Control (40+ aliases):\n"
    preview_text+="  g, gs, gss      - Git & status\n"
    preview_text+="  ga, gaa, gc     - Add & commit\n"
    preview_text+="  gp, gpl, gf     - Push, pull, fetch\n"
    preview_text+="  gco, gcb, gb    - Checkout & branches\n"
    preview_text+="  gl, glog        - Pretty logs\n"
    preview_text+="  gst, gstp       - Stash operations\n\n"
    preview_text+="Ansible Automation (15+ aliases):\n"
    preview_text+="  ap, apv, apc    - Playbook execution\n"
    preview_text+="  ag, ainv        - Galaxy & inventory\n\n"
    preview_text+="Terraform/OpenTofu (15+ aliases):\n"
    preview_text+="  tf, tfi, tfp    - Terraform init/plan\n"
    preview_text+="  tfa, tfd        - Apply & destroy\n\n"
    preview_text+="System & Tools:\n"
    preview_text+="  jc, jcf, jcu    - Journalctl logs (8+ aliases)\n"
    preview_text+="  ta, tl, ts      - Tmux/Screen (10+ aliases)\n"
    preview_text+="  rsync-*         - Rsync operations (6+ aliases)\n"
    preview_text+="  py, pip, venv   - Python tools (10+ aliases)\n"
    preview_text+="  certinfo        - SSL/TLS tools (8+ aliases)\n\n"
    preview_text+="Plus: Process mgmt, SSH, time/date utils!\n\n"
    preview_text+="Total: 150+ aliases\n"
    preview_text+="Full details in: $source_file"

    dialog --title "DevOps Extras Preview" --msgbox "$preview_text" 32 70
}

install_devops_extras() {
    local aliases_file="$HOME/.devops_extras"
    local source_file="$SCRIPT_DIR/importing/devops-extras.md"

    if dialog --yesno "Install Additional DevOps Aliases?\n\nThis will add helpful aliases for:\n- Git (version control)\n- Ansible (automation)\n- Terraform/OpenTofu (IaC)\n- Systemd journalctl (logging)\n- Tmux/Screen (sessions)\n- Rsync (backups)\n- SSH (remote access)\n- Python/pip (scripting)\n- SSL certificates\n- and more...\n\nInstall location: $aliases_file" 22 75; then
        dialog --infobox "Installing additional DevOps aliases..." 5 40

        if [[ -f "$source_file" ]]; then
            # Extract bash code from markdown
            awk '/^```bash$/,/^```$/ {if (!/^```/) print}' "$source_file" > "$aliases_file"

            # Source in bashrc if not already there
            if ! grep -q ".devops_extras" "$HOME/.bashrc" 2>/dev/null; then
                {
                    echo ""
                    echo "# Load additional DevOps aliases"
                    echo "[[ -f ~/.devops_extras ]] && source ~/.devops_extras"
                } >> "$HOME/.bashrc"
            fi

            dialog --msgbox "DevOps extras installed successfully!\n\nLocation: $aliases_file\n\nRestart your terminal or run:\nsource ~/.devops_extras\n\nIncludes aliases for:\n- Git, Ansible, Terraform\n- Journalctl, Tmux/Screen\n- Rsync, SSH, Python\n- and many more!" 18 70
        else
            dialog --msgbox "Failed to find devops-extras.md source file.\n\nExpected location: $source_file" 10 70
        fi
    fi
}

uninstall_docker_components() {
    local items_to_remove=()
    local removal_list=""

    # Check what's installed
    [[ -f "$HOME/.docker_aliases" ]] && items_to_remove+=("docker_aliases") && removal_list+="- Docker aliases (~/.docker_aliases)\n"
    [[ -f "$HOME/.local/bin/dom" ]] && items_to_remove+=("dom") && removal_list+="- Docker ops menu (~/.local/bin/dom)\n"

    if [[ ${#items_to_remove[@]} -eq 0 ]]; then
        dialog --msgbox "Nothing to uninstall.\n\nNo Docker components are currently installed." 10 60
        return
    fi

    if dialog --yesno "Uninstall Docker Components?\n\nThe following will be removed:\n\n$removal_list\nBashrc entries will also be cleaned up.\n\nContinue?" 14 70; then
        # Remove files
        [[ -f "$HOME/.docker_aliases" ]] && rm -f "$HOME/.docker_aliases"
        [[ -f "$HOME/.local/bin/dom" ]] && rm -f "$HOME/.local/bin/dom"

        # Clean up bashrc entries
        if [[ -f "$HOME/.bashrc" ]]; then
            sed -i '/# Load Docker bash aliases/d' "$HOME/.bashrc"
            sed -i '\|^\[\[ -f ~/.docker_aliases \]\]|d' "$HOME/.bashrc"
        fi

        dialog --msgbox "Docker components uninstalled successfully!\n\nRemoved:\n$removal_list\nBashrc has been cleaned up." 12 70
    fi
}

uninstall_devops_components() {
    local items_to_remove=()
    local removal_list=""

    # Check what's installed
    [[ -f "$HOME/.devops_extras" ]] && items_to_remove+=("devops_extras") && removal_list+="- DevOps aliases (~/.devops_extras)\n"

    if [[ ${#items_to_remove[@]} -eq 0 ]]; then
        dialog --msgbox "Nothing to uninstall.\n\nNo DevOps components are currently installed." 10 60
        return
    fi

    if dialog --yesno "Uninstall DevOps Components?\n\nThe following will be removed:\n\n$removal_list\nBashrc entries will also be cleaned up.\n\nContinue?" 12 70; then
        # Remove files
        [[ -f "$HOME/.devops_extras" ]] && rm -f "$HOME/.devops_extras"

        # Clean up bashrc entries
        if [[ -f "$HOME/.bashrc" ]]; then
            sed -i '/# Load additional DevOps aliases/d' "$HOME/.bashrc"
            sed -i '\|^\[\[ -f ~/.devops_extras \]\]|d' "$HOME/.bashrc"
        fi

        dialog --msgbox "DevOps components uninstalled successfully!\n\nRemoved:\n$removal_list\nBashrc has been cleaned up." 12 70
    fi
}

uninstall_k8s_components() {
    local items_to_remove=()
    local removal_list=""

    # Check what's installed
    [[ -f "$HOME/.k8s_aliases" ]] && items_to_remove+=("k8s_aliases") && removal_list+="- Kubernetes aliases (~/.k8s_aliases)\n"
    [[ -f "$HOME/.local/bin/k8m" ]] && items_to_remove+=("k8m") && removal_list+="- K8s ops menu (~/.local/bin/k8m)\n"

    if [[ ${#items_to_remove[@]} -eq 0 ]]; then
        dialog --msgbox "Nothing to uninstall.\n\nNo Kubernetes components are currently installed." 10 60
        return
    fi

    if dialog --yesno "Uninstall Kubernetes Components?\n\nThe following will be removed:\n\n$removal_list\nBashrc entries will also be cleaned up.\n\nContinue?" 14 70; then
        # Remove files
        [[ -f "$HOME/.k8s_aliases" ]] && rm -f "$HOME/.k8s_aliases"
        [[ -f "$HOME/.local/bin/k8m" ]] && rm -f "$HOME/.local/bin/k8m"

        # Clean up bashrc entries
        if [[ -f "$HOME/.bashrc" ]]; then
            sed -i '/# Load Kubernetes bash aliases/d' "$HOME/.bashrc"
            sed -i '\|^\[\[ -f ~/.k8s_aliases \]\]|d' "$HOME/.bashrc"
        fi

        dialog --msgbox "Kubernetes components uninstalled successfully!\n\nRemoved:\n$removal_list\nBashrc has been cleaned up." 12 70
    fi
}

configure_smtp() {
    local smtp_host smtp_port smtp_user smtp_pass smtp_from

    smtp_host=$(dialog --inputbox "Enter SMTP server hostname:\n(e.g., smtp.gmail.com)" 10 60 "${SMTP_HOST:-}" 3>&1 1>&2 2>&3 3>&-)
    [[ -z "$smtp_host" ]] && return

    smtp_port=$(dialog --inputbox "Enter SMTP port:\n(Usually 587 for TLS or 465 for SSL)" 10 60 "${SMTP_PORT:-587}" 3>&1 1>&2 2>&3 3>&-)
    [[ -z "$smtp_port" ]] && return

    smtp_user=$(dialog --inputbox "Enter SMTP username:\n(Usually your email address)" 10 60 "${SMTP_USER:-}" 3>&1 1>&2 2>&3 3>&-)
    [[ -z "$smtp_user" ]] && return

    smtp_pass=$(dialog --passwordbox "Enter SMTP password or app password:" 10 60 3>&1 1>&2 2>&3 3>&-)
    [[ -z "$smtp_pass" ]] && return

    smtp_from=$(dialog --inputbox "Enter 'From' email address:" 10 60 "${SMTP_FROM:-$smtp_user}" 3>&1 1>&2 2>&3 3>&-)
    [[ -z "$smtp_from" ]] && smtp_from="$smtp_user"

    # Save to config
    SMTP_HOST="$smtp_host"
    SMTP_PORT="$smtp_port"
    SMTP_USER="$smtp_user"
    SMTP_PASS="$smtp_pass"
    SMTP_FROM="$smtp_from"
    save_config

    # Also save to .env if it exists
    if [[ -f "$ENV_FILE" ]]; then
        {
            echo ""
            echo "# SMTP Configuration"
            echo "SMTP_HOST=$smtp_host"
            echo "SMTP_PORT=$smtp_port"
            echo "SMTP_USER=$smtp_user"
            echo "SMTP_PASS=$smtp_pass"
            echo "SMTP_FROM=$smtp_from"
        } >> "$ENV_FILE"
    fi

    dialog --msgbox "SMTP configuration saved!\n\nHost: $smtp_host\nPort: $smtp_port\nUser: $smtp_user\nFrom: $smtp_from\n\nThese settings will be available to Docker containers via the .env file." 14 70
}

create_user() { dialog --msgbox "Feature: Create User\n\nTo be implemented" 10 50; }
