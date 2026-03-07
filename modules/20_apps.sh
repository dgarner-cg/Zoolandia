#!/bin/bash
################################################################################
# Zoolandia v5.10 - Apps Module
#
# Description: Application management functions including app descriptions,
#              installation checks, and app installation (Docker and Ansible)
################################################################################

# Get app description
get_app_description() {
    local app_name="$1"

    case "$app_name" in
        # Media Servers
        "plex") echo "Media server with streaming and organization" ;;
        "jellyfin") echo "Free media system with apps for all devices" ;;
        "emby") echo "Personal media server for streaming content" ;;
        "airsonic-advanced") echo "Music streaming server (fork of Airsonic)" ;;
        "navidrome") echo "Modern music server and streamer" ;;
        "gonic") echo "Subsonic-compatible music streaming server" ;;
        "funkwhale") echo "Federated music streaming platform" ;;
        "lollypop") echo "Modern music player for GNOME" ;;

        # Media Management
        "sonarr") echo "TV show PVR and automation tool" ;;
        "radarr") echo "Movie collection manager and downloader" ;;
        "lidarr") echo "Music collection manager" ;;
        "readarr") echo "Ebook and audiobook collection manager" ;;
        "bazarr") echo "Companion app for Sonarr/Radarr subtitles" ;;
        "prowlarr") echo "Indexer manager for *arr apps" ;;
        "overseerr") echo "Request management and discovery tool" ;;
        "jellyseerr") echo "Media request management for Jellyfin" ;;
        "ombi") echo "Media request and user management system" ;;
        "tautulli") echo "Monitoring and tracking for Plex" ;;
        "kometa") echo "Metadata and collection manager for Plex" ;;
        "maintainerr") echo "Plex library maintenance and cleanup" ;;
        "notifiarr") echo "Unified notification system for *arr apps" ;;
        "cleanuparr") echo "Automated cleanup tool for *arr apps" ;;
        "huntarr") echo "Torrent/Usenet health checker for *arr" ;;

        # Download Clients
        "qbittorrent") echo "Lightweight BitTorrent client" ;;
        "qbittorrent-vpn") echo "qBittorrent with built-in VPN" ;;
        "transmission") echo "Fast and easy BitTorrent client" ;;
        "sabnzbd") echo "Usenet binary newsreader" ;;
        "nzbget") echo "Efficient Usenet downloader" ;;
        "jackett") echo "Proxy server for torrent trackers" ;;
        "flaresolverr") echo "Proxy server to bypass Cloudflare protection" ;;

        # Productivity & Documents
        "nextcloud") echo "Self-hosted productivity platform and cloud" ;;
        "onlyoffice") echo "Office suite with document editing" ;;
        "paperless-ngx") echo "Document management system with OCR" ;;
        "paperless-ai") echo "AI-enhanced document management" ;;
        "stirling-pdf") echo "PDF manipulation and editing tools" ;;
        "pdfding") echo "PDF editing and annotation tool" ;;
        "bookstack") echo "Wiki and documentation platform" ;;
        "wikidocs") echo "Simple wiki documentation system" ;;
        "triliumnext") echo "Hierarchical note-taking application" ;;
        "cyberchef") echo "Web app for encryption and data analysis" ;;
        "it-tools") echo "Collection of handy IT tools" ;;
        "gotenberg") echo "PDF generation API service" ;;
        "tika") echo "Content analysis and text extraction" ;;

        # Development Tools
        "docker") echo "Container platform engine" ;;
        "portainer") echo "Docker container management UI" ;;
        "vscode") echo "Visual Studio Code in browser" ;;
        "openhands") echo "AI coding assistant and IDE" ;;
        "n8n") echo "Workflow automation platform" ;;
        "node-red") echo "Low-code programming for event-driven apps" ;;
        "ollama") echo "Run large language models locally" ;;
        "open-webui") echo "Web interface for Ollama LLMs" ;;
        "flowise") echo "Drag-drop LLM flow builder" ;;

        # Dashboards & Monitoring
        "homepage") echo "Customizable application dashboard" ;;
        "homarr") echo "Sleek and modern dashboard" ;;
        "heimdall") echo "Application dashboard and launcher" ;;
        "dashy") echo "Feature-rich dashboard with widgets" ;;
        "flame") echo "Self-hosted startpage and dashboard" ;;
        "homer") echo "Simple static dashboard" ;;
        "organizr") echo "Unified dashboard with authentication" ;;
        "deployrr-dashboard") echo "Zoolandia custom dashboard" ;;

        # System Monitoring
        "uptime-kuma") echo "Self-hosted uptime monitoring tool" ;;
        "netdata") echo "Real-time performance monitoring" ;;
        "glances") echo "Cross-platform system monitoring" ;;
        "scrutiny") echo "Hard drive health monitoring (S.M.A.R.T)" ;;
        "dozzle") echo "Real-time Docker log viewer" ;;
        "dozzle-agent") echo "Agent for distributed Dozzle setup" ;;
        "cadvisor") echo "Container resource usage analytics" ;;
        "grafana") echo "Analytics and interactive visualization" ;;
        "prometheus") echo "Monitoring system and time series DB" ;;
        "influxdb") echo "Time series database" ;;
        "node-exporter") echo "Prometheus exporter for hardware metrics" ;;
        "speedtest-tracker") echo "Internet speed testing and tracking" ;;
        "smokeping") echo "Network latency measurement tool" ;;
        "deunhealth") echo "Docker container health monitoring" ;;

        # Docker Management
        "dockwatch") echo "Docker container update notifications" ;;
        "watchtower") echo "Automated Docker container updates" ;;
        "wud") echo "What's Up Docker - update notifications" ;;
        "docker-gc") echo "Docker garbage collection and cleanup" ;;
        "socket-proxy") echo "Security proxy for Docker socket" ;;

        # Security & Access Control
        "authelia") echo "Single sign-on and 2FA portal" ;;
        "authentik") echo "Identity provider with SSO" ;;
        "authentik-worker") echo "Background worker for Authentik" ;;
        "oauth") echo "OAuth authentication provider" ;;
        "tinyauth") echo "Lightweight authentication service" ;;
        "crowdsec") echo "Collaborative security engine" ;;
        "cloudflare-bouncer") echo "CrowdSec bouncer for Cloudflare" ;;
        "traefik-bouncer") echo "CrowdSec bouncer for Traefik" ;;

        # Reverse Proxy & Networking
        "traefik") echo "Modern HTTP reverse proxy and load balancer" ;;
        "traefik-error-log") echo "Error log sidecar for Traefik" ;;
        "traefik-access-log") echo "Access log sidecar for Traefik" ;;
        "traefik-certs-dumper") echo "Certificate dumper for Traefik" ;;
        "cloudflare-tunnel") echo "Secure tunnel to Cloudflare" ;;
        "ddns-updater") echo "Dynamic DNS updater for multiple providers" ;;
        "pihole") echo "Network-wide ad blocker and DNS" ;;
        "gluetun") echo "VPN client for Docker with kill switch" ;;
        "tailscale") echo "Zero-config VPN mesh network" ;;
        "zerotier") echo "Software-defined networking" ;;
        "wg-easy") echo "WireGuard VPN with web UI" ;;

        # Communication & Collaboration
        "discord") echo "Voice, video, and text communication" ;;
        "thelounge") echo "Self-hosted web IRC client" ;;
        "mailspring") echo "Beautiful, fast email client" ;;
        "zoom") echo "Video conferencing and meetings" ;;

        # Databases
        "mariadb") echo "MySQL-compatible relational database" ;;
        "postgresql") echo "Advanced open-source database" ;;
        "redis") echo "In-memory data structure store" ;;
        "redis-commander") echo "Web management tool for Redis" ;;
        "influxdb") echo "Time-series database" ;;

        # Database Management
        "phpmyadmin") echo "Web interface for MySQL/MariaDB" ;;
        "pgadmin") echo "Administration tool for PostgreSQL" ;;
        "adminer") echo "Database management in single PHP file" ;;

        # AI & Machine Learning
        "immich") echo "Self-hosted photo and video backup" ;;
        "immich-ml") echo "Machine learning service for Immich" ;;
        "immich-db") echo "Database for Immich" ;;
        "qdrant") echo "Vector similarity search engine" ;;
        "weaviate") echo "Vector database for AI applications" ;;

        # Books & Reading
        "calibre") echo "Ebook library management" ;;
        "calibre-web") echo "Web interface for Calibre" ;;
        "kavita") echo "Fast, feature-rich manga/comic reader" ;;
        "komga") echo "Media server for comics and manga" ;;
        "mylar3") echo "Automated comic book downloader" ;;
        "audiobookshelf") echo "Self-hosted audiobook and podcast server" ;;

        # Photos & Images
        "photoprism") echo "AI-powered photo management" ;;
        "piwigo") echo "Photo gallery software" ;;
        "photoshow") echo "Simple photo gallery" ;;
        "digikam") echo "Professional photo management" ;;

        # Home Automation
        "home-assistant") echo "Open-source home automation platform" ;;
        "homebridge") echo "HomeKit support for non-Apple devices" ;;
        "esphome") echo "ESP8266/ESP32 firmware for home automation" ;;
        "mosquitto") echo "MQTT message broker" ;;
        "mqttx-web") echo "Web-based MQTT client" ;;
        "grocy") echo "ERP system for household management" ;;
        "wallos") echo "Personal finance and subscription tracker" ;;

        # Desktop Apps (via Ansible)
        "vivaldi") echo "Privacy-focused web browser" ;;
        "bitwarden") echo "Password manager and vault" ;;
        "notion") echo "All-in-one workspace for notes and docs" ;;
        "notepad-plus-plus") echo "Feature-rich text and code editor" ;;
        "termius") echo "Modern SSH and SFTP client" ;;
        "protonvpn") echo "Secure VPN service" ;;
        "twingate") echo "Zero trust network access" ;;
        "icloud") echo "iCloud integration for Linux" ;;
        "ulauncher") echo "Application launcher for Linux" ;;

        # Remote Access & Management
        "guacamole") echo "Clientless remote desktop gateway" ;;
        "guacd") echo "Guacamole proxy daemon" ;;
        "sshwifty") echo "Web-based SSH and Telnet client" ;;
        "remmina") echo "Remote desktop client" ;;
        "xpipe-webtop") echo "Browser-based desktop environment" ;;
        "kasm") echo "Container streaming platform" ;;

        # File Management
        "cloud-commander") echo "Web-based file manager" ;;
        "filezilla") echo "FTP client for file transfers" ;;
        "double-commander") echo "Two-panel file manager" ;;

        # Utilities & Tools
        "vaultwarden") echo "Lightweight Bitwarden server" ;;
        "hemmelig") echo "Secure secret sharing tool" ;;
        "privatebin") echo "Minimalist encrypted pastebin" ;;
        "resilio-sync") echo "Fast file sync and sharing" ;;
        "syncthing") echo "Continuous file synchronization" ;;
        "change-detection") echo "Website change monitoring" ;;
        "searxng") echo "Privacy-respecting metasearch engine" ;;
        "freshrss") echo "Self-hosted RSS feed aggregator" ;;
        "gamevault") echo "Self-hosted gaming platform" ;;
        "vikunja") echo "To-do list and project management" ;;
        "baikal") echo "CalDAV and CardDAV server" ;;
        "gptwol") echo "Wake-on-LAN web interface" ;;

        # Music Management
        "beets") echo "Music library organizer and tagger" ;;

        # Web Browsers
        "chromium") echo "Open-source web browser" ;;

        # Custom & Themes
        "theme-park") echo "Custom themes for self-hosted apps" ;;
        "custom") echo "Custom application configuration" ;;
        "starter") echo "Starter Docker compose template" ;;
        "support") echo "Support and troubleshooting tools" ;;
        "dweebui") echo "Simple web UI framework" ;;

        # Default
        *) echo "Self-hosted application" ;;
    esac
}

# Check if a system app is installed
check_system_app_installed() {
    local app_name="$1"

    # Map app names to their package/command names
    case "$app_name" in
        "bitwarden")
            command -v bitwarden >/dev/null 2>&1 || dpkg -l | grep -q bitwarden 2>/dev/null
            ;;
        "discord")
            dpkg -l | grep -q discord 2>/dev/null
            ;;
        "docker")
            command -v docker >/dev/null 2>&1
            ;;
        "icloud")
            # iCloud might be installed as a web app or snap
            snap list 2>/dev/null | grep -q icloud || command -v icloud >/dev/null 2>&1
            ;;
        "mailspring")
            command -v mailspring >/dev/null 2>&1 || dpkg -l | grep -q mailspring 2>/dev/null
            ;;
        "n8n")
            command -v n8n >/dev/null 2>&1 || snap list 2>/dev/null | grep -q n8n
            ;;
        "notepad-plus-plus")
            command -v notepad-plus-plus >/dev/null 2>&1 || snap list 2>/dev/null | grep -q notepad-plus-plus
            ;;
        "notion")
            command -v notion >/dev/null 2>&1 || snap list 2>/dev/null | grep -q notion
            ;;
        "onlyoffice")
            command -v onlyoffice >/dev/null 2>&1 || dpkg -l | grep -q onlyoffice 2>/dev/null
            ;;
        "portainer")
            command -v portainer >/dev/null 2>&1
            ;;
        "protonvpn")
            command -v protonvpn >/dev/null 2>&1 || dpkg -l | grep -q protonvpn 2>/dev/null
            ;;
        "termius")
            command -v termius >/dev/null 2>&1 || snap list 2>/dev/null | grep -q termius
            ;;
        "twingate")
            command -v twingate >/dev/null 2>&1 || dpkg -l | grep -q twingate 2>/dev/null
            ;;
        "ulauncher")
            command -v ulauncher >/dev/null 2>&1 || dpkg -l | grep -q ulauncher 2>/dev/null
            ;;
        "vivaldi")
            command -v vivaldi >/dev/null 2>&1 || snap list 2>/dev/null | grep -q vivaldi || dpkg -l | grep -q vivaldi 2>/dev/null
            ;;
        "zoom")
            command -v zoom >/dev/null 2>&1 || dpkg -l | grep -q zoom 2>/dev/null
            ;;
        *)
            # Default: check if command exists
            command -v "$app_name" >/dev/null 2>&1
            ;;
    esac
}

# Apps menu - now just shows Docker apps directly
show_apps_menu() {
    show_docker_apps_menu
}

# Install application (interactive mode)
install_app() {
    local app_name="$1"
    local compose_source="$SCRIPT_DIR/compose/${app_name}.yml"
    local compose_dest="$DOCKER_DIR/compose/${app_name}.yml"
    local includes_source="$SCRIPT_DIR/includes/${app_name}"
    local includes_dest="$DOCKER_DIR/appdata/${app_name}"

    # Check if compose file exists
    if [[ ! -f "$compose_source" ]]; then
        dialog --msgbox "Error: Compose file not found for $app_name" 8 50
        return 1
    fi

    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment not configured!\n\nPlease complete Prerequisites first." 10 50
        return 1
    fi

    # Create compose directory if it doesn't exist
    mkdir -p "$DOCKER_DIR/compose"

    # Copy compose file
    dialog --infobox "Installing $app_name...\n\nCopying compose file..." 6 50
    cp "$compose_source" "$compose_dest"

    # Handle GPU placeholder if present
    if grep -q "# DEVICES-GPU-PLACEHOLDER-DO-NOT-DELETE" "$compose_dest"; then
        if dialog --yesno "Do you want to enable GPU/Hardware transcoding for $app_name?" 8 60; then
            if [[ -f "$SCRIPT_DIR/includes/devices_gpu.yml" ]]; then
                # Insert GPU configuration
                sed -i "/# DEVICES-GPU-PLACEHOLDER-DO-NOT-DELETE/r $SCRIPT_DIR/includes/devices_gpu.yml" "$compose_dest"
            fi
        fi
    fi

    # Handle Traefik labels placeholder if present
    if grep -q "# DOCKER-LABELS-PLACEHOLDER" "$compose_dest"; then
        if dialog --yesno "Do you want to configure Traefik reverse proxy for $app_name?" 8 60; then
            local subdomain
            subdomain=$(dialog --ok-label "OK" --cancel-label "Cancel" --inputbox "Enter subdomain for $app_name:" 10 60 "$app_name" 3>&1 1>&2 2>&3 3>&-)

            if [[ -n "$subdomain" ]]; then
                local port
                port=$(dialog --ok-label "OK" --cancel-label "Cancel" --inputbox "Enter internal port for $app_name:" 10 60 3>&1 1>&2 2>&3 3>&-)

                if [[ -n "$port" ]]; then
                    # Create labels from template
                    local temp_labels="/tmp/zoolandia_labels_${app_name}.yml"
                    cp "$SCRIPT_DIR/includes/traefik/labels-template.yml" "$temp_labels"

                    # Replace placeholders
                    sed -i "s/LABEL-SERVICE-NAME-PLACEHOLDER/${app_name}/g" "$temp_labels"
                    sed -i "s/SUBDOMAIN-PLACEHOLDER/${subdomain}/g" "$temp_labels"
                    sed -i "s/LABEL-SERVICE-PORT-PLACEHOLDER/${port}/g" "$temp_labels"
                    sed -i "s/ENTRYPOINT-PLACEHOLDER/websecure-internal,websecure-external/g" "$temp_labels"
                    sed -i "s/CHAIN-PLACEHOLDER/chain-no-auth/g" "$temp_labels"

                    # Insert labels
                    sed -i "/# DOCKER-LABELS-PLACEHOLDER/r $temp_labels" "$compose_dest"
                    rm -f "$temp_labels"
                fi
            fi
        fi
    fi

    # Copy app-specific includes if they exist
    if [[ -d "$includes_source" ]]; then
        dialog --infobox "Installing $app_name...\n\nCopying configuration files..." 6 50
        mkdir -p "$includes_dest"
        cp -r "$includes_source/"* "$includes_dest/"
        chown -R "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$includes_dest" 2>/dev/null || true
    fi

    # Add to main docker-compose.yml if not already present
    if [[ -f "$COMPOSE_FILE" ]]; then
        if ! grep -q "compose/${app_name}.yml" "$COMPOSE_FILE"; then
            dialog --infobox "Installing $app_name...\n\nAdding to docker-compose.yml..." 6 50
            sed -i "/# SERVICE-PLACEHOLDER-DO-NOT-DELETE/i\\  - compose/${app_name}.yml" "$COMPOSE_FILE"
        fi
    else
        # Create docker-compose.yml from starter template
        if [[ -f "$SCRIPT_DIR/compose/starter.yml" ]]; then
            cp "$SCRIPT_DIR/compose/starter.yml" "$COMPOSE_FILE"
            sed -i "/# SERVICE-PLACEHOLDER-DO-NOT-DELETE/i\\  - compose/${app_name}.yml" "$COMPOSE_FILE"
        fi
    fi

    # Set permissions
    chown -R "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$DOCKER_DIR/compose" 2>/dev/null || true

    # Ask if user wants to start the container now
    if dialog --yesno "$app_name has been configured.\n\nDo you want to start the container now?" 10 60; then
        # Check if Docker is running
        if ! docker info >/dev/null 2>&1; then
            dialog --msgbox "Error: Docker is not running!\n\nPlease start Docker first:\nsudo systemctl start docker\n\nThen use Tools > Stack Manager to start $app_name" 12 70
            return 0
        fi

        # Check .env file permissions before attempting to start
        if [[ -f "$ENV_FILE" ]]; then
            if ! test -r "$ENV_FILE"; then
                if dialog --yesno "Error: Cannot read .env file (permission denied)\n\nThis usually means the .env file has incorrect ownership/permissions.\n\nWould you like to fix this now?" 12 70; then
                    if pkexec chown "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$ENV_FILE" && \
                       pkexec chmod 640 "$ENV_FILE"; then
                        dialog --msgbox "Permissions fixed!\n\nContinuing with container startup..." 8 60
                        sleep 1
                    else
                        dialog --msgbox "Failed to fix permissions.\n\nPlease run: Tools > Permissions\n\nThen try starting the container again." 10 70
                        return 0
                    fi
                else
                    dialog --msgbox "Cannot start container without .env file access.\n\nPlease run: Tools > Permissions\n\nThen try again." 10 70
                    return 0
                fi
            fi
        fi

        # Start the container
        dialog --infobox "Starting $app_name container...\n\nThis may take a moment..." 6 50

        if cd "$DOCKER_DIR" && docker compose up -d "$app_name" 2>&1 | tee /tmp/docker_compose_up_${app_name}.log; then
            sleep 2
            # Check if container is running
            if docker ps --filter "name=$app_name" --format "{{.Names}}" | grep -q "^${app_name}$"; then
                dialog --msgbox "$app_name started successfully!\n\nContainer is now running.\n\nAccess it via:\n- Stack Manager (status/logs)\n- Direct container: docker logs $app_name" 14 70
            else
                dialog --title "Container Start Warning" --textbox /tmp/docker_compose_up_${app_name}.log 24 80
                dialog --msgbox "$app_name may have issues starting.\n\nCheck logs:\ndocker logs $app_name\n\nOr use Tools > Stack Manager" 12 70
            fi
        else
            dialog --title "Container Start Failed" --textbox /tmp/docker_compose_up_${app_name}.log 24 80
            dialog --msgbox "$app_name failed to start!\n\nCheck the error above or use:\ndocker logs $app_name" 10 70
        fi
        rm -f /tmp/docker_compose_up_${app_name}.log
    else
        dialog --msgbox "$app_name installed successfully!\n\nCompose file: $compose_dest\n\nUse Tools > Stack Manager to start the service later." 12 70
    fi

    return 0
}

# Install application (batch mode - non-interactive)
install_app_batch() {
    local app_name="$1"
    local enable_gpu="$2"
    local enable_traefik="$3"
    local compose_source="$SCRIPT_DIR/compose/${app_name}.yml"
    local compose_dest="$DOCKER_DIR/compose/${app_name}.yml"
    local includes_source="$SCRIPT_DIR/includes/${app_name}"
    local includes_dest="$DOCKER_DIR/appdata/${app_name}"

    # Check if compose file exists
    if [[ ! -f "$compose_source" ]]; then
        return 1
    fi

    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        return 1
    fi

    # Create compose directory if it doesn't exist
    mkdir -p "$DOCKER_DIR/compose"

    # Copy compose file
    cp "$compose_source" "$compose_dest"

    # Handle GPU placeholder if present
    if grep -q "# DEVICES-GPU-PLACEHOLDER-DO-NOT-DELETE" "$compose_dest"; then
        if [[ "$enable_gpu" == "yes" ]]; then
            if [[ -f "$SCRIPT_DIR/includes/devices_gpu.yml" ]]; then
                # Insert GPU configuration
                sed -i "/# DEVICES-GPU-PLACEHOLDER-DO-NOT-DELETE/r $SCRIPT_DIR/includes/devices_gpu.yml" "$compose_dest"
            fi
        fi
    fi

    # Handle Traefik labels placeholder if present
    if grep -q "# DOCKER-LABELS-PLACEHOLDER" "$compose_dest"; then
        if [[ "$enable_traefik" == "yes" ]]; then
            # Use app name as subdomain and try to detect common ports
            local subdomain="$app_name"
            local port=""

            # Try to detect port from compose file (look for PORT variable)
            if grep -q "${app_name^^}_PORT" "$compose_source"; then
                # Port is defined as a variable, skip for now
                port=""
            fi

            # If we have a port, add labels
            if [[ -n "$port" ]] || true; then
                # For batch mode, use app name as subdomain
                # Port will need to be configured manually or we use a default
                local temp_labels="/tmp/zoolandia_labels_${app_name}.yml"
                cp "$SCRIPT_DIR/includes/traefik/labels-template.yml" "$temp_labels"

                # Replace placeholders with defaults
                sed -i "s/LABEL-SERVICE-NAME-PLACEHOLDER/${app_name}/g" "$temp_labels"
                sed -i "s/SUBDOMAIN-PLACEHOLDER/${subdomain}/g" "$temp_labels"
                sed -i "s/LABEL-SERVICE-PORT-PLACEHOLDER/8080/g" "$temp_labels"  # Default port
                sed -i "s/ENTRYPOINT-PLACEHOLDER/websecure-internal,websecure-external/g" "$temp_labels"
                sed -i "s/CHAIN-PLACEHOLDER/chain-no-auth/g" "$temp_labels"

                # Insert labels
                sed -i "/# DOCKER-LABELS-PLACEHOLDER/r $temp_labels" "$compose_dest"
                rm -f "$temp_labels"
            fi
        fi
    fi

    # Copy app-specific includes if they exist
    if [[ -d "$includes_source" ]]; then
        mkdir -p "$includes_dest"
        cp -r "$includes_source/"* "$includes_dest/"
        chown -R "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$includes_dest" 2>/dev/null || true
    fi

    # Add to main docker-compose.yml if not already present
    if [[ -f "$COMPOSE_FILE" ]]; then
        if ! grep -q "compose/${app_name}.yml" "$COMPOSE_FILE"; then
            sed -i "/# SERVICE-PLACEHOLDER-DO-NOT-DELETE/i\\  - compose/${app_name}.yml" "$COMPOSE_FILE"
        fi
    else
        # Create docker-compose.yml from starter template
        if [[ -f "$SCRIPT_DIR/compose/starter.yml" ]]; then
            cp "$SCRIPT_DIR/compose/starter.yml" "$COMPOSE_FILE"
            sed -i "/# SERVICE-PLACEHOLDER-DO-NOT-DELETE/i\\  - compose/${app_name}.yml" "$COMPOSE_FILE"
        fi
    fi

    # Set permissions
    chown -R "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$DOCKER_DIR/compose" 2>/dev/null || true
    return 0
}

# Install Ansible application
install_ansible_app() {
    local app_name="$1"
    local ansible_apps_dir="$SCRIPT_DIR/compose"
    local ansible_task_file="$ansible_apps_dir/${app_name}.yml"

    # Check if ansible task file exists
    if [[ ! -f "$ansible_task_file" ]]; then
        dialog --msgbox "Error: Ansible task file not found for $app_name" 8 50
        return 1
    fi

    # Check if ansible is installed
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        dialog --msgbox "Error: ansible-playbook not found!\n\nPlease install Ansible first:\nsudo apt install ansible" 12 60
        return 1
    fi

    # Check if pkexec is installed (needed for graphical sudo prompt)
    if ! command -v pkexec >/dev/null 2>&1; then
        dialog --msgbox "Error: pkexec not found!\n\npkexec is required for privilege elevation.\n\nPlease install it:\nsudo apt install policykit-1" 12 60
        return 1
    fi

    # Create a temporary playbook that includes this task
    local temp_playbook="/tmp/zoolandia_${app_name}_playbook.yml"
    cat > "$temp_playbook" <<EOF
---
- name: Install $app_name
  hosts: localhost
  become: true
  vars:
    failures: []
    ansible_python_interpreter: /usr/bin/python3
  tasks:
    - name: Install $app_name
      include_tasks: $ansible_task_file
EOF

    # Show info that password prompt will appear
    dialog --msgbox "Installing $app_name via Ansible\n\nYou will be prompted for your password in a graphical dialog.\n\nAfter entering your password, you'll see real-time installation progress." 12 60

    # Run ansible playbook with pkexec and show real-time output
    # Note: pkexec shows a graphical password prompt and runs with elevated privileges
    pkexec ansible-playbook "$temp_playbook" 2>&1 | \
        dialog --title "Installing: $app_name" --programbox 24 80

    # Check the exit status of ansible-playbook
    local playbook_status=${PIPESTATUS[0]}

    # Cleanup temp playbook
    rm -f "$temp_playbook"

    # Show result
    if [ $playbook_status -eq 0 ]; then
        dialog --msgbox "Installation completed successfully!\n\n$app_name" 8 60
        return 0
    else
        dialog --msgbox "Installation failed with errors.\n\n$app_name\n\nExit code: $playbook_status\n\nPlease review the output above for error details." 12 70
        return 1
    fi
}

# Run Ansible playbook
run_ansible_playbook() {
    local playbook_path="$1"
    local playbook_name="$2"
    local inventory_path="${3:-$SCRIPT_DIR/ansible/inventories/production/localhost.yml}"

    # Check if playbook exists
    if [[ ! -f "$playbook_path" ]]; then
        local display_playbook_path=$(display_path "$playbook_path")
        dialog --msgbox "Error: Playbook not found at:\n$display_playbook_path" 10 70
        return 1
    fi

    # Check if inventory exists
    if [[ ! -f "$inventory_path" ]]; then
        local display_inventory_path=$(display_path "$inventory_path")
        dialog --msgbox "Error: Inventory not found at:\n$display_inventory_path" 10 70
        return 1
    fi

    # Check if ansible is installed
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        dialog --msgbox "Error: ansible-playbook not found!\n\nPlease install Ansible first:\nsudo apt install ansible" 12 60
        return 1
    fi

    # Confirm with user
    local display_playbook_path=$(display_path "$playbook_path")
    local display_inventory_path=$(display_path "$inventory_path")
    if ! dialog --yesno "Run Ansible playbook:\n\n$playbook_name\n\nPath: $display_playbook_path\nInventory: $display_inventory_path\n\nContinue?" 14 70; then
        dialog --msgbox "Operation cancelled." 6 40
        return 1
    fi

    # Run ansible playbook with real-time output display
    # Use programbox to show live progress as tasks execute
    ansible-playbook -i "$inventory_path" "$playbook_path" 2>&1 | \
        dialog --title "Running: $playbook_name" --programbox 24 80

    # Check the exit status of ansible-playbook (first command in pipe)
    local playbook_status=${PIPESTATUS[0]}

    # Show result
    if [ $playbook_status -eq 0 ]; then
        dialog --msgbox "Playbook completed successfully!\n\n$playbook_name" 8 60
        return 0
    else
        dialog --msgbox "Playbook failed with errors.\n\n$playbook_name\n\nExit code: $playbook_status\n\nPlease review the output above for error details." 12 70
        return 1
    fi
}
