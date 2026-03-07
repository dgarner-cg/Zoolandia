#!/bin/bash
################################################################################
# Zoolandia - Docker Management Module
################################################################################
# Description: Docker installation and management functions
# Version: 1.1.0
# Dependencies: 00_init.sh, 01_config.sh
################################################################################

show_docker_menu() {
    while true; do
        # Get Docker version info
        local docker_version="Not Installed"
        local compose_version="Not Installed"

        if command -v docker &>/dev/null; then
            docker_version=$(docker --version 2>/dev/null | sed 's/Docker version //' | cut -d',' -f1)
        fi

        if docker compose version &>/dev/null 2>&1; then
            compose_version=$(docker compose version 2>/dev/null | sed 's/Docker Compose version //' | cut -d' ' -f1)
        elif command -v docker-compose &>/dev/null; then
            compose_version=$(docker-compose --version 2>/dev/null | sed 's/.*version //' | cut -d',' -f1)
        fi

        # Check UFW Docker rules status
        local ufw_status="Not Configured"
        if command -v ufw &>/dev/null; then
            if ufw status 2>/dev/null | grep -q "ALLOW.*172\." || \
               grep -q "DOCKER" /etc/ufw/after.rules 2>/dev/null; then
                ufw_status="\Z2Configured\Zn"
            else
                ufw_status="\Z3Not Configured\Zn"
            fi
        else
            ufw_status="\Z1UFW Not Installed\Zn"
        fi

        # Check Dashboard status
        local dashboard_status="\Z3Not Installed\Zn"
        local dashboard_installed=false
        local dashboard_running=false
        if docker ps -a 2>/dev/null | grep -q "zoolandia-dashboard"; then
            dashboard_installed=true
            if docker ps 2>/dev/null | grep -q "zoolandia-dashboard"; then
                dashboard_status="\Z2Running\Zn"
                dashboard_running=true
            else
                dashboard_status="\Z1Stopped\Zn"
            fi
        fi

        # Build menu items dynamically
        local menu_items=()

        # Dashboard section
        if [[ "$dashboard_installed" == true ]]; then
            if [[ "$dashboard_running" == true ]]; then
                menu_items+=("View Dashboard" "Open Zoolandia Dashboard in browser")
            fi
            menu_items+=("Manage Dashboard" "Start/Stop/Remove Dashboard - $dashboard_status")
        else
            menu_items+=("Install Dashboard" "Zoolandia Dashboard (Homepage) - $dashboard_status")
        fi

        menu_items+=(
            "Install Socket Proxy" "Install Docker Socket Proxy for security"
            "Docker Info" "Show Docker system information"
            "Disk Usage" "Calculate Docker disk usage in $DOCKER_DIR"
            "" ""
            "Install UFW Rules" "Configure UFW firewall for Docker - $ufw_status"
            "Remove UFW Rules" "Remove Docker UFW firewall rules"
            "" ""
            "Docker Prune" "Clean up unused Docker resources"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --colors --backtitle "$SCRIPT_NAME Docker" \
            --title "Docker Settings" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "\nDocker: $docker_version | Compose: $compose_version\n\nSelect an option:" 22 75 12 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Install Dashboard") install_zoolandia_dashboard ;;
            "View Dashboard") view_zoolandia_dashboard ;;
            "Manage Dashboard") manage_zoolandia_dashboard ;;
            "Install Socket Proxy") install_socket_proxy ;;
            "Docker Info") show_docker_info ;;
            "Disk Usage") show_docker_disk_usage ;;
            "Install UFW Rules") install_docker_ufw_rules ;;
            "Remove UFW Rules") remove_docker_ufw_rules ;;
            "Docker Prune") docker_prune ;;
            "Back") return ;;
            "") continue ;;
        esac
    done
}

install_socket_proxy() {
    if dialog --yesno "Install Docker Socket Proxy?\n\nThis is recommended for security when using Traefik." 10 60; then
        install_app "socket-proxy"
        SOCKET_PROXY_DONE=true
        touch "$ZOOLANDIA_CONFIG_DIR/socket_proxy_done"
    fi
}

show_docker_info() { docker info | dialog --programbox "Docker Information" 24 80; }

docker_prune() {
    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Docker Prune" \
        --title "Docker Cleanup Options" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --menu "Select what to clean up:" 18 70 8 \
        "All" "Remove all unused data (containers, networks, images, cache)" \
        "Containers" "Remove stopped containers only" \
        "Images" "Remove unused images only" \
        "Volumes" "Remove unused volumes only (DANGER: may lose data)" \
        "Networks" "Remove unused networks only" \
        "Build Cache" "Remove build cache only" \
        "Back" "Return to Docker menu" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$choice" in
        "All")
            if dialog --yesno "Remove ALL unused Docker data?\n\nThis will remove:\n- Stopped containers\n- Unused networks\n- Dangling images\n- Build cache\n\nNote: Volumes are NOT included for safety." 14 60; then
                dialog --infobox "Cleaning up Docker resources..." 5 50
                local result
                result=$(docker system prune -af 2>&1)
                dialog --title "Docker Prune Results" --msgbox "$result" 20 80
            fi
            ;;
        "Containers")
            if dialog --yesno "Remove all stopped containers?" 8 50; then
                dialog --infobox "Removing stopped containers..." 5 50
                local result
                result=$(docker container prune -f 2>&1)
                dialog --title "Container Prune Results" --msgbox "$result" 15 70
            fi
            ;;
        "Images")
            if dialog --yesno "Remove all unused images?\n\nThis includes dangling and unreferenced images." 10 60; then
                dialog --infobox "Removing unused images..." 5 50
                local result
                result=$(docker image prune -af 2>&1)
                dialog --title "Image Prune Results" --msgbox "$result" 15 70
            fi
            ;;
        "Volumes")
            if dialog --yesno "WARNING: Remove all unused volumes?\n\nThis may result in DATA LOSS if volumes contain important data.\n\nAre you sure?" 12 60; then
                dialog --infobox "Removing unused volumes..." 5 50
                local result
                result=$(docker volume prune -f 2>&1)
                dialog --title "Volume Prune Results" --msgbox "$result" 15 70
            fi
            ;;
        "Networks")
            if dialog --yesno "Remove all unused networks?" 8 50; then
                dialog --infobox "Removing unused networks..." 5 50
                local result
                result=$(docker network prune -f 2>&1)
                dialog --title "Network Prune Results" --msgbox "$result" 15 70
            fi
            ;;
        "Build Cache")
            if dialog --yesno "Remove Docker build cache?" 8 50; then
                dialog --infobox "Removing build cache..." 5 50
                local result
                result=$(docker builder prune -af 2>&1)
                dialog --title "Build Cache Prune Results" --msgbox "$result" 15 70
            fi
            ;;
        "Back") return ;;
    esac
}

show_docker_disk_usage() {
    dialog --infobox "Calculating Docker disk usage...\n\nThis may take a moment." 7 50

    local output=""
    local total_size="0"

    # Docker directory usage (from Prerequisites DOCKER_DIR)
    if [[ -n "$DOCKER_DIR" && -d "$DOCKER_DIR" ]]; then
        local docker_dir_size
        docker_dir_size=$(du -sh "$DOCKER_DIR" 2>/dev/null | cut -f1)
        output+="Docker Directory ($DOCKER_DIR):\n"
        output+="  Total Size: $docker_dir_size\n\n"

        # Breakdown by subdirectory
        if [[ -d "$DOCKER_DIR/appdata" ]]; then
            local appdata_size
            appdata_size=$(du -sh "$DOCKER_DIR/appdata" 2>/dev/null | cut -f1)
            output+="  - appdata: $appdata_size\n"
        fi

        if [[ -d "$DOCKER_DIR/compose" ]]; then
            local compose_size
            compose_size=$(du -sh "$DOCKER_DIR/compose" 2>/dev/null | cut -f1)
            output+="  - compose: $compose_size\n"
        fi

        if [[ -d "$DOCKER_DIR/logs" ]]; then
            local logs_size
            logs_size=$(du -sh "$DOCKER_DIR/logs" 2>/dev/null | cut -f1)
            output+="  - logs: $logs_size\n"
        fi

        if [[ -d "$DOCKER_DIR/secrets" ]]; then
            local secrets_size
            secrets_size=$(du -sh "$DOCKER_DIR/secrets" 2>/dev/null | cut -f1)
            output+="  - secrets: $secrets_size\n"
        fi

        if [[ -d "$DOCKER_DIR/shared" ]]; then
            local shared_size
            shared_size=$(du -sh "$DOCKER_DIR/shared" 2>/dev/null | cut -f1)
            output+="  - shared: $shared_size\n"
        fi

        output+="\n"
    else
        output+="Docker Directory: Not configured\n"
        output+="(Set in Prerequisites > Docker Folder)\n\n"
    fi

    # Docker system disk usage
    if command -v docker &>/dev/null; then
        output+="═══════════════════════════════════════════════════════════════\n"
        output+="Docker System Disk Usage:\n"
        output+="═══════════════════════════════════════════════════════════════\n\n"

        # Get docker system df output
        local docker_df
        docker_df=$(docker system df 2>/dev/null)
        output+="$docker_df\n\n"

        # Get total reclaimable space
        local reclaimable
        reclaimable=$(docker system df 2>/dev/null | tail -n +2 | awk '{sum += $4} END {print sum}' 2>/dev/null)

        output+="═══════════════════════════════════════════════════════════════\n"
        output+="Detailed Breakdown:\n"
        output+="═══════════════════════════════════════════════════════════════\n\n"

        # Images
        local images_count images_size
        images_count=$(docker images -q 2>/dev/null | wc -l)
        images_size=$(docker system df --format '{{.Size}}' 2>/dev/null | head -1)
        output+="Images: $images_count ($images_size)\n"

        # Containers
        local containers_running containers_stopped
        containers_running=$(docker ps -q 2>/dev/null | wc -l)
        containers_stopped=$(docker ps -aq 2>/dev/null | wc -l)
        output+="Containers: $containers_stopped total ($containers_running running)\n"

        # Volumes
        local volumes_count
        volumes_count=$(docker volume ls -q 2>/dev/null | wc -l)
        output+="Volumes: $volumes_count\n"

        # Networks
        local networks_count
        networks_count=$(docker network ls -q 2>/dev/null | wc -l)
        output+="Networks: $networks_count\n"

        output+="\n"
        output+="TIP: Use 'Docker Prune' to reclaim unused disk space.\n"
    else
        output+="Docker is not installed.\n"
    fi

    # Display the output
    echo -e "$output" | dialog --title "Docker Disk Usage" --programbox 30 75
}

install_docker_ufw_rules() {
    # Check if UFW is installed
    if ! command -v ufw &>/dev/null; then
        dialog --msgbox "UFW (Uncomplicated Firewall) is not installed.\n\nInstall UFW first:\n  sudo apt install ufw" 12 60
        return 1
    fi

    # Check if UFW is active
    local ufw_status
    ufw_status=$(sudo ufw status 2>/dev/null | head -1)
    if [[ "$ufw_status" != *"active"* ]]; then
        if ! dialog --yesno "UFW is not currently active.\n\nDo you want to enable UFW?\n\nNote: Make sure SSH (port 22) is allowed before enabling!" 12 60; then
            return 1
        fi
    fi

    local msg="Install Docker UFW Rules?\n\n"
    msg+="This will configure UFW to work properly with Docker by:\n\n"
    msg+="1. Allowing Docker bridge network traffic (172.16.0.0/12)\n"
    msg+="2. Adding DOCKER-USER chain rules\n"
    msg+="3. Preventing Docker from bypassing UFW\n\n"
    msg+="The following rules will be added to /etc/ufw/after.rules:\n"
    msg+="- Allow established connections\n"
    msg+="- Allow Docker internal network communication\n"
    msg+="- Route traffic through DOCKER-USER chain\n\n"
    msg+="Continue?"

    if ! dialog --yesno "$msg" 22 70; then
        return 0
    fi

    dialog --infobox "Installing Docker UFW rules...\n\nPlease wait..." 7 50

    # Backup existing after.rules
    local backup_file="/etc/ufw/after.rules.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp /etc/ufw/after.rules "$backup_file" 2>/dev/null

    # Check if Docker rules already exist
    if grep -q "# BEGIN DOCKER UFW RULES" /etc/ufw/after.rules 2>/dev/null; then
        dialog --msgbox "Docker UFW rules are already installed.\n\nBackup saved to: $backup_file" 10 60
        return 0
    fi

    # Add Docker UFW rules
    sudo tee -a /etc/ufw/after.rules > /dev/null << 'DOCKER_UFW_RULES'

# BEGIN DOCKER UFW RULES
*filter
:DOCKER-USER - [0:0]
:ufw-user-input - [0:0]

# Allow established connections
-A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow Docker internal network (172.16.0.0/12)
-A DOCKER-USER -s 172.16.0.0/12 -j ACCEPT
-A DOCKER-USER -d 172.16.0.0/12 -j ACCEPT

# Allow localhost
-A DOCKER-USER -s 127.0.0.0/8 -j ACCEPT
-A DOCKER-USER -d 127.0.0.0/8 -j ACCEPT

# Allow Docker bridge network (default 172.17.0.0/16)
-A DOCKER-USER -s 172.17.0.0/16 -j ACCEPT
-A DOCKER-USER -d 172.17.0.0/16 -j ACCEPT

# Return to continue processing
-A DOCKER-USER -j RETURN

COMMIT
# END DOCKER UFW RULES
DOCKER_UFW_RULES

    # Reload UFW
    sudo ufw reload 2>/dev/null

    local result_msg="Docker UFW rules installed successfully!\n\n"
    result_msg+="Rules added:\n"
    result_msg+="- Docker bridge networks allowed\n"
    result_msg+="- Established connections allowed\n"
    result_msg+="- DOCKER-USER chain configured\n\n"
    result_msg+="Backup saved to:\n$backup_file\n\n"
    result_msg+="UFW has been reloaded."

    dialog --msgbox "$result_msg" 18 65
}

remove_docker_ufw_rules() {
    # Check if UFW is installed
    if ! command -v ufw &>/dev/null; then
        dialog --msgbox "UFW is not installed." 8 50
        return 1
    fi

    # Check if Docker rules exist
    if ! grep -q "# BEGIN DOCKER UFW RULES" /etc/ufw/after.rules 2>/dev/null; then
        dialog --msgbox "Docker UFW rules are not installed.\n\nNo changes needed." 10 50
        return 0
    fi

    if ! dialog --yesno "Remove Docker UFW Rules?\n\nThis will remove the Docker-specific firewall rules from /etc/ufw/after.rules.\n\nA backup will be created before removal.\n\nContinue?" 14 60; then
        return 0
    fi

    dialog --infobox "Removing Docker UFW rules...\n\nPlease wait..." 7 50

    # Backup existing after.rules
    local backup_file="/etc/ufw/after.rules.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp /etc/ufw/after.rules "$backup_file" 2>/dev/null

    # Remove Docker UFW rules section
    sudo sed -i '/# BEGIN DOCKER UFW RULES/,/# END DOCKER UFW RULES/d' /etc/ufw/after.rules

    # Reload UFW
    sudo ufw reload 2>/dev/null

    local result_msg="Docker UFW rules removed successfully!\n\n"
    result_msg+="Backup saved to:\n$backup_file\n\n"
    result_msg+="UFW has been reloaded.\n\n"
    result_msg+="Note: Docker may now bypass UFW for container networking."

    dialog --msgbox "$result_msg" 16 65
}

################################################################################
# Zoolandia Dashboard Functions
################################################################################

install_zoolandia_dashboard() {
    # Check prerequisites
    if ! command -v docker &>/dev/null; then
        dialog --msgbox "Docker is not installed.\n\nPlease install Docker first." 10 50
        return 1
    fi

    if [[ -z "$DOCKER_DIR" || ! -d "$DOCKER_DIR" ]]; then
        dialog --msgbox "Docker directory is not configured.\n\nPlease set the Docker Folder in Prerequisites first." 10 60
        return 1
    fi

    # Check if already installed
    if docker ps -a 2>/dev/null | grep -q "zoolandia-dashboard"; then
        dialog --msgbox "Zoolandia Dashboard is already installed.\n\nUse 'Manage Dashboard' to start/stop/remove it." 10 60
        return 0
    fi

    local msg="Install Zoolandia Dashboard?\n\n"
    msg+="This will install a Homepage-based dashboard for managing\n"
    msg+="your Docker containers and services.\n\n"
    msg+="Features:\n"
    msg+="- System resource monitoring (CPU, Memory, Disk)\n"
    msg+="- Docker container status\n"
    msg+="- Quick links to your apps\n"
    msg+="- Customizable bookmarks and widgets\n\n"
    msg+="The dashboard will be available at:\n"
    msg+="  http://${SERVER_IP:-localhost}:3010\n\n"
    msg+="Continue?"

    if ! dialog --yesno "$msg" 22 65; then
        return 0
    fi

    dialog --infobox "Installing Zoolandia Dashboard...\n\nPlease wait..." 7 50

    # Create dashboard directories
    local dashboard_dir="$DOCKER_DIR/appdata/zoolandia-dashboard"
    local config_dir="$dashboard_dir/config"
    local images_dir="$dashboard_dir/images"

    mkdir -p "$config_dir" "$images_dir" 2>/dev/null

    # Copy configuration files from includes
    local includes_dir="$SCRIPT_DIR/includes/deployrr-dashboard"

    if [[ -d "$includes_dir" ]]; then
        # Copy settings
        if [[ -f "$includes_dir/settings.yaml" ]]; then
            cp "$includes_dir/settings.yaml" "$config_dir/"
        fi

        # Copy bookmarks
        if [[ -f "$includes_dir/bookmarks.yaml" ]]; then
            cp "$includes_dir/bookmarks.yaml" "$config_dir/"
        fi

        # Copy widgets
        if [[ -f "$includes_dir/widgets.yaml" ]]; then
            cp "$includes_dir/widgets.yaml" "$config_dir/"
        fi

        # Copy services template
        if [[ -f "$includes_dir/services.yaml" ]]; then
            cp "$includes_dir/services.yaml" "$config_dir/"
        fi

        # Copy docker.yaml (uses local docker socket)
        if [[ -f "$includes_dir/docker.yaml" ]]; then
            cp "$includes_dir/docker.yaml" "$config_dir/"
        fi

        # Copy icons
        if [[ -f "$includes_dir/deployrr_icon.ico" ]]; then
            cp "$includes_dir/deployrr_icon.ico" "$images_dir/zoolandia_icon.ico"
        fi
        if [[ -f "$includes_dir/deployrr_icon.png" ]]; then
            cp "$includes_dir/deployrr_icon.png" "$images_dir/zoolandia_icon.png"
        fi
    else
        # Create minimal configuration if includes not found
        cat > "$config_dir/settings.yaml" << 'EOF'
---
title: Zoolandia Dashboard
theme: dark
color: slate
headerStyle: boxed
hideErrors: true
EOF

        cat > "$config_dir/widgets.yaml" << 'EOF'
---
- greeting:
    text_size: xl
    text: Zoolandia Dashboard

- resources:
    cpu: true
    memory: true
    disk: /

- search:
    provider: duckduckgo
    target: _blank
EOF

        cat > "$config_dir/services.yaml" << 'EOF'
---
- Docker:
    - Containers:
        widget:
          type: docker
          server: local
EOF

        cat > "$config_dir/docker.yaml" << EOF
---
local:
  socket: /var/run/docker.sock
EOF
    fi

    # Set permissions
    chown -R "${PUID:-1000}:${PGID:-1000}" "$dashboard_dir" 2>/dev/null

    # Get dashboard port (default 3010)
    local dashboard_port="${ZOOLANDIA_DASHBOARD_PORT:-3010}"

    # Build allowed hosts list
    local allowed_hosts="localhost:${dashboard_port},127.0.0.1:${dashboard_port},0.0.0.0:${dashboard_port}"
    if [[ -n "$SERVER_IP" ]]; then
        allowed_hosts="${allowed_hosts},${SERVER_IP}:${dashboard_port}"
    fi
    if [[ -n "$HOSTNAME" ]]; then
        allowed_hosts="${allowed_hosts},${HOSTNAME}:${dashboard_port}"
    fi

    # Create and start the container
    docker run -d \
        --name zoolandia-dashboard \
        --restart unless-stopped \
        --security-opt no-new-privileges:true \
        -p "${dashboard_port}:3000" \
        -v "$config_dir:/app/config" \
        -v "$images_dir:/app/public/images" \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -e TZ="${TZ:-UTC}" \
        -e PUID="${PUID:-1000}" \
        -e PGID="${PGID:-1000}" \
        -e "HOMEPAGE_ALLOWED_HOSTS=${allowed_hosts}" \
        ghcr.io/gethomepage/homepage:latest \
        2>/dev/null

    if [[ $? -eq 0 ]]; then
        local success_msg="Zoolandia Dashboard installed successfully!\n\n"
        success_msg+="Dashboard URL:\n"
        success_msg+="  http://${SERVER_IP:-localhost}:${dashboard_port}\n\n"
        success_msg+="Configuration directory:\n"
        success_msg+="  $config_dir\n\n"
        success_msg+="You can customize the dashboard by editing:\n"
        success_msg+="  - settings.yaml (theme, title)\n"
        success_msg+="  - services.yaml (your apps)\n"
        success_msg+="  - bookmarks.yaml (quick links)\n"
        success_msg+="  - widgets.yaml (dashboard widgets)"

        dialog --msgbox "$success_msg" 20 65

        # Offer to open in browser
        if dialog --yesno "Open dashboard in browser now?" 8 50; then
            view_zoolandia_dashboard
        fi
    else
        dialog --msgbox "Failed to install Zoolandia Dashboard.\n\nCheck Docker logs for details:\n  docker logs zoolandia-dashboard" 12 60
        return 1
    fi
}

view_zoolandia_dashboard() {
    local dashboard_port="${ZOOLANDIA_DASHBOARD_PORT:-3010}"
    local dashboard_url="http://${SERVER_IP:-localhost}:${dashboard_port}"

    # Check if dashboard is running
    if ! docker ps 2>/dev/null | grep -q "zoolandia-dashboard"; then
        dialog --msgbox "Zoolandia Dashboard is not running.\n\nUse 'Manage Dashboard' to start it." 10 50
        return 1
    fi

    # Try to open in browser
    if command -v xdg-open &>/dev/null; then
        xdg-open "$dashboard_url" 2>/dev/null &
        dialog --msgbox "Opening dashboard in browser...\n\nURL: $dashboard_url" 10 55
    elif command -v open &>/dev/null; then
        open "$dashboard_url" 2>/dev/null &
        dialog --msgbox "Opening dashboard in browser...\n\nURL: $dashboard_url" 10 55
    else
        dialog --msgbox "Dashboard URL:\n\n$dashboard_url\n\nOpen this URL in your browser to access the dashboard." 12 60
    fi
}

manage_zoolandia_dashboard() {
    while true; do
        # Get current status
        local status="Not Running"
        local status_color="\Z1"
        if docker ps 2>/dev/null | grep -q "zoolandia-dashboard"; then
            status="Running"
            status_color="\Z2"
        elif docker ps -a 2>/dev/null | grep -q "zoolandia-dashboard"; then
            status="Stopped"
            status_color="\Z3"
        fi

        local dashboard_port="${ZOOLANDIA_DASHBOARD_PORT:-3010}"

        local menu_items=()

        if [[ "$status" == "Running" ]]; then
            menu_items+=(
                "View" "Open dashboard in browser"
                "Stop" "Stop the dashboard container"
                "Restart" "Restart the dashboard container"
            )
        else
            menu_items+=(
                "Start" "Start the dashboard container"
            )
        fi

        menu_items+=(
            "Logs" "View dashboard container logs"
            "Config" "Open configuration directory"
            "Remove" "Remove dashboard completely"
            "Back" "Return to Docker menu"
        )

        local choice
        choice=$(dialog --clear --colors --backtitle "$SCRIPT_NAME - Dashboard Management" \
            --title "Zoolandia Dashboard - ${status_color}${status}\Zn" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "\nPort: ${dashboard_port} | URL: http://${SERVER_IP:-localhost}:${dashboard_port}\n\nSelect an action:" 18 70 8 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "View")
                view_zoolandia_dashboard
                ;;
            "Start")
                dialog --infobox "Starting Zoolandia Dashboard..." 5 45
                docker start zoolandia-dashboard 2>/dev/null
                sleep 2
                if docker ps 2>/dev/null | grep -q "zoolandia-dashboard"; then
                    dialog --msgbox "Dashboard started successfully!\n\nURL: http://${SERVER_IP:-localhost}:${dashboard_port}" 10 55
                else
                    dialog --msgbox "Failed to start dashboard.\n\nCheck logs for details." 10 50
                fi
                ;;
            "Stop")
                dialog --infobox "Stopping Zoolandia Dashboard..." 5 45
                docker stop zoolandia-dashboard 2>/dev/null
                sleep 1
                dialog --msgbox "Dashboard stopped." 8 40
                ;;
            "Restart")
                dialog --infobox "Restarting Zoolandia Dashboard..." 5 45
                docker restart zoolandia-dashboard 2>/dev/null
                sleep 2
                if docker ps 2>/dev/null | grep -q "zoolandia-dashboard"; then
                    dialog --msgbox "Dashboard restarted successfully!" 8 45
                else
                    dialog --msgbox "Failed to restart dashboard.\n\nCheck logs for details." 10 50
                fi
                ;;
            "Logs")
                docker logs --tail 100 zoolandia-dashboard 2>&1 | dialog --title "Dashboard Logs (last 100 lines)" --programbox 30 100
                ;;
            "Config")
                local config_dir="$DOCKER_DIR/appdata/zoolandia-dashboard/config"
                if [[ -d "$config_dir" ]]; then
                    if command -v xdg-open &>/dev/null; then
                        xdg-open "$config_dir" 2>/dev/null &
                        dialog --msgbox "Opening configuration directory:\n\n$config_dir" 10 60
                    else
                        dialog --msgbox "Configuration directory:\n\n$config_dir\n\nFiles:\n- settings.yaml\n- services.yaml\n- bookmarks.yaml\n- widgets.yaml\n- docker.yaml" 16 60
                    fi
                else
                    dialog --msgbox "Configuration directory not found:\n\n$config_dir" 10 60
                fi
                ;;
            "Remove")
                if dialog --yesno "Remove Zoolandia Dashboard?\n\nThis will:\n- Stop and remove the container\n- Keep configuration files in:\n  $DOCKER_DIR/appdata/zoolandia-dashboard\n\nContinue?" 14 60; then
                    dialog --infobox "Removing Zoolandia Dashboard..." 5 45
                    docker stop zoolandia-dashboard 2>/dev/null
                    docker rm zoolandia-dashboard 2>/dev/null

                    if dialog --yesno "Also remove configuration files?\n\nDirectory:\n$DOCKER_DIR/appdata/zoolandia-dashboard\n\nThis cannot be undone!" 12 60; then
                        rm -rf "$DOCKER_DIR/appdata/zoolandia-dashboard" 2>/dev/null
                        dialog --msgbox "Dashboard and configuration removed." 8 50
                    else
                        dialog --msgbox "Dashboard removed.\n\nConfiguration files preserved at:\n$DOCKER_DIR/appdata/zoolandia-dashboard" 12 60
                    fi
                    return
                fi
                ;;
            "Back")
                return
                ;;
        esac
    done
}
