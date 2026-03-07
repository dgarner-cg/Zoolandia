#!/bin/bash
################################################################################
# Zoolandia v5.10 - Tools Module
#
# Description: Tools menu and utilities including Stack Manager, database creation,
#              configuration editors, and system diagnostics
################################################################################

# Tools menu
show_tools_menu() {
    while true; do
        local menu_items=(
            "Stack Manager" "Up, Down, Start, Stop, Recreate, Delete, etc."
            "Backups" "Backup Docker Folder"
            "Permissions" "Check/Fix Permissions"
            "Diagnostics" "Run System Health Checks ()"
            "Lazydocker" "Terminal UI for Docker Management"
            "MariaDB Database" "Create a MariaDB Database"
            "PostgreSQL Database" "Create a PostgreSQL Database"
            ".env Editor" "Edit Docker Environment Variables"
            "Secrets Editor" "Edit Docker Secrets"
            "Version Pins" "Edit Version Pins"
            "Change Hostname" "Adapt Zoolandia to a new hostname"
            "Change Server IP" "Adapt Zoolandia to a new server IP"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME Tools" \
            --title "Tools" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Select an option..." 26 80 12 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Stack Manager") show_stack_manager ;;
            "Backups") show_backup_menu ;;
            "Permissions") check_fix_permissions ;;
            "Diagnostics") health_diagnostics ;;
            "Lazydocker") launch_lazydocker ;;
            "MariaDB Database") create_mariadb_database ;;
            "PostgreSQL Database") create_postgresql_database ;;
            ".env Editor") edit_env_file ;;
            "Secrets Editor") edit_secrets ;;
            "Version Pins") edit_version_pins ;;
            "Change Hostname") change_hostname ;;
            "Change Server IP") change_server_ip ;;
            "Back") return ;;
        esac
    done
}

# Helper function to get available compose services
get_available_services() {
    local compose_dir="${DOCKER_DIR}/compose"

    if [[ ! -d "$compose_dir" ]]; then
        return 1
    fi

    # Find all .yml files in compose directory (excluding subdirectories)
    find "$compose_dir" -maxdepth 1 -type f -name "*.yml" -printf "%f\n" 2>/dev/null | sort
}

# Helper function to select services via checklist
select_services() {
    local title="$1"
    local prompt="$2"
    local preselect_all="$3"  # "yes" to preselect all, "no" for none

    local services=()
    while IFS= read -r service; do
        local service_name="${service%.yml}"
        local status="off"
        [[ "$preselect_all" == "yes" ]] && status="on"
        services+=("$service" "$service_name" "$status")
    done < <(get_available_services)

    if [[ ${#services[@]} -eq 0 ]]; then
        dialog --msgbox "No services found!\n\nPlease install some apps first." 10 50
        return 1
    fi

    local selected
    selected=$(dialog --clear --backtitle "$SCRIPT_NAME - Stack Manager" \
        --title "$title" \
        --ok-label "Continue" \
        --cancel-label "Cancel" \
        --checklist "$prompt" 22 70 15 \
        "${services[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return 1

    echo "$selected"
}

# Helper function to build docker compose command with selected services
build_compose_command() {
    local selected_services="$1"
    local compose_files="--env-file .env"

    # Remove quotes and build -f flags for each service
    for service in $selected_services; do
        service="${service//\"/}"  # Remove quotes
        compose_files="$compose_files -f compose/$service"
    done

    echo "$compose_files"
}

# Stack Manager - Manage Docker containers
show_stack_manager() {
    local compose_dir="${DOCKER_DIR}/compose"

    if [[ ! -d "$compose_dir" ]]; then
        dialog --msgbox "Error: Compose directory not found!\n\nPlease install some apps first." 10 50
        return 1
    fi

    # Check if any compose files exist
    local service_count=$(get_available_services | wc -l)
    if [[ $service_count -eq 0 ]]; then
        dialog --msgbox "No services found!\n\nPlease install some apps first." 10 50
        return 1
    fi

    while true; do
        local menu_items=(
            "Up" "Start selected services (docker compose up -d)"
            "Down" "Stop ALL services (docker compose down)"
            "Start" "Start selected stopped services"
            "Stop" "Stop selected running services"
            "Restart" "Restart selected services"
            "Recreate" "Recreate selected services"
            "Pull" "Pull latest images for selected services"
            "Logs" "View logs for ALL services"
            "List" "List all services and their status"
            "Remove" "Remove all stopped containers"
            "Back" "Return to Tools menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Stack Manager" \
            --title "Stack Manager - $service_count services available" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Select an action:" 22 70 11 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Up")
                local selected
                selected=$(select_services "Start Services" "Use SPACE to select, ENTER to continue:" "no") || continue

                if [[ -z "$selected" ]]; then
                    dialog --msgbox "No services selected!\n\nRemember: Press SPACE to check boxes, then ENTER to continue." 8 60
                    continue
                fi

                local compose_cmd=$(build_compose_command "$selected")
                local service_list=$(echo "$selected" | tr ' ' '\n' | sed 's/"//g' | sed 's/.yml$//' | tr '\n' ', ' | sed 's/,$//')

                dialog --infobox "Starting services: $service_list\n\nThis may take a moment..." 8 60
                cd "$DOCKER_DIR" || return 1
                local output_file="/tmp/stack_up_$$.txt"
                if docker compose $compose_cmd up -d > "$output_file" 2>&1; then
                    dialog --title "Services Started" --msgbox "Services started successfully!\n\nStarted: $service_list\n\nUse 'List' to view running containers." 12 70
                else
                    dialog --title "Docker Compose Up - ERROR" --textbox "$output_file" 24 80
                fi
                rm -f "$output_file"
                ;;
            "Down")
                if dialog --yesno "Stop ALL services?\n\nThis will stop all Docker containers." 9 50; then
                    dialog --infobox "Stopping all services...\n\nThis may take a moment..." 6 50
                    cd "$DOCKER_DIR" || return 1

                    # Build command with all compose files
                    local all_services=$(get_available_services | tr '\n' ' ')
                    local compose_cmd=$(build_compose_command "$all_services")

                    local output_file="/tmp/stack_down_$$.txt"
                    if docker compose $compose_cmd down > "$output_file" 2>&1; then
                        dialog --title "Services Stopped" --msgbox "All services stopped successfully!" 8 60
                    else
                        dialog --title "Docker Compose Down - ERROR" --textbox "$output_file" 24 80
                    fi
                    rm -f "$output_file"
                fi
                ;;
            "Start")
                local selected
                selected=$(select_services "Start Services" "Use SPACE to select, ENTER to continue:" "no") || continue

                if [[ -z "$selected" ]]; then
                    dialog --msgbox "No services selected!\n\nRemember: Press SPACE to check boxes, then ENTER to continue." 8 60
                    continue
                fi

                local compose_cmd=$(build_compose_command "$selected")
                local service_list=$(echo "$selected" | tr ' ' '\n' | sed 's/"//g' | sed 's/.yml$//' | tr '\n' ', ' | sed 's/,$//')

                dialog --infobox "Starting services: $service_list\n\nThis may take a moment..." 8 60
                cd "$DOCKER_DIR" || return 1
                local output_file="/tmp/stack_start_$$.txt"
                if docker compose $compose_cmd start > "$output_file" 2>&1; then
                    dialog --title "Services Started" --msgbox "Services started successfully!\n\nStarted: $service_list" 10 70
                else
                    dialog --title "Docker Compose Start - ERROR" --textbox "$output_file" 24 80
                fi
                rm -f "$output_file"
                ;;
            "Stop")
                local selected
                selected=$(select_services "Stop Services" "Use SPACE to select, ENTER to continue:" "no") || continue

                if [[ -z "$selected" ]]; then
                    dialog --msgbox "No services selected!\n\nRemember: Press SPACE to check boxes, then ENTER to continue." 8 60
                    continue
                fi

                local compose_cmd=$(build_compose_command "$selected")
                local service_list=$(echo "$selected" | tr ' ' '\n' | sed 's/"//g' | sed 's/.yml$//' | tr '\n' ', ' | sed 's/,$//')

                if dialog --yesno "Stop these services?\n\n$service_list" 10 70; then
                    dialog --infobox "Stopping services: $service_list\n\nThis may take a moment..." 8 60
                    cd "$DOCKER_DIR" || return 1
                    local output_file="/tmp/stack_stop_$$.txt"
                    if docker compose $compose_cmd stop > "$output_file" 2>&1; then
                        dialog --title "Services Stopped" --msgbox "Services stopped successfully!\n\nStopped: $service_list" 10 70
                    else
                        dialog --title "Docker Compose Stop - ERROR" --textbox "$output_file" 24 80
                    fi
                    rm -f "$output_file"
                fi
                ;;
            "Restart")
                local selected
                selected=$(select_services "Restart Services" "Use SPACE to select, ENTER to continue:" "no") || continue

                if [[ -z "$selected" ]]; then
                    dialog --msgbox "No services selected!\n\nRemember: Press SPACE to check boxes, then ENTER to continue." 8 60
                    continue
                fi

                local compose_cmd=$(build_compose_command "$selected")
                local service_list=$(echo "$selected" | tr ' ' '\n' | sed 's/"//g' | sed 's/.yml$//' | tr '\n' ', ' | sed 's/,$//')

                dialog --infobox "Restarting services: $service_list\n\nThis may take a moment..." 8 60
                cd "$DOCKER_DIR" || return 1
                local output_file="/tmp/stack_restart_$$.txt"
                if docker compose $compose_cmd restart > "$output_file" 2>&1; then
                    dialog --title "Services Restarted" --msgbox "Services restarted successfully!\n\nRestarted: $service_list" 10 70
                else
                    dialog --title "Docker Compose Restart - ERROR" --textbox "$output_file" 24 80
                fi
                rm -f "$output_file"
                ;;
            "Recreate")
                local selected
                selected=$(select_services "Recreate Services" "Use SPACE to select, ENTER to continue:" "no") || continue

                if [[ -z "$selected" ]]; then
                    dialog --msgbox "No services selected!\n\nRemember: Press SPACE to check boxes, then ENTER to continue." 8 60
                    continue
                fi

                local compose_cmd=$(build_compose_command "$selected")
                local service_list=$(echo "$selected" | tr ' ' '\n' | sed 's/"//g' | sed 's/.yml$//' | tr '\n' ', ' | sed 's/,$//')

                if dialog --yesno "Recreate these services?\n\nThis will rebuild and restart containers.\n\n$service_list" 12 70; then
                    dialog --infobox "Recreating services: $service_list\n\nThis may take several minutes..." 9 70
                    cd "$DOCKER_DIR" || return 1
                    local output_file="/tmp/stack_recreate_$$.txt"
                    if docker compose $compose_cmd up -d --force-recreate > "$output_file" 2>&1; then
                        dialog --title "Services Recreated" --msgbox "Services recreated successfully!\n\nRecreated: $service_list\n\nUse 'List' to view running containers." 12 70
                    else
                        dialog --title "Docker Compose Recreate - ERROR" --textbox "$output_file" 24 80
                    fi
                    rm -f "$output_file"
                fi
                ;;
            "Pull")
                local selected
                selected=$(select_services "Pull Images" "Use SPACE to select/unselect, ENTER to continue:" "yes") || continue

                if [[ -z "$selected" ]]; then
                    dialog --msgbox "No services selected!\n\nRemember: Press SPACE to check boxes, then ENTER to continue." 8 60
                    continue
                fi

                local compose_cmd=$(build_compose_command "$selected")
                local service_list=$(echo "$selected" | tr ' ' '\n' | sed 's/"//g' | sed 's/.yml$//' | tr '\n' ', ' | sed 's/,$//')

                dialog --infobox "Pulling latest images for: $service_list\n\nThis may take several minutes..." 9 70
                cd "$DOCKER_DIR" || return 1
                local output_file="/tmp/stack_pull_$$.txt"
                if docker compose $compose_cmd pull > "$output_file" 2>&1; then
                    dialog --title "Images Pulled" --msgbox "Images pulled successfully!\n\nUpdated: $service_list" 10 70
                else
                    dialog --title "Docker Compose Pull - ERROR" --textbox "$output_file" 24 80
                fi
                rm -f "$output_file"
                ;;
            "Logs")
                cd "$DOCKER_DIR" || return 1

                # Build command with all compose files
                local all_services=$(get_available_services | tr '\n' ' ')
                local compose_cmd=$(build_compose_command "$all_services")

                local output_file="/tmp/stack_logs_$$.txt"
                docker compose $compose_cmd logs --tail=100 > "$output_file" 2>&1
                dialog --title "Docker Compose Logs (Last 100 lines)" --textbox "$output_file" 24 80
                rm -f "$output_file"
                ;;
            "List")
                cd "$DOCKER_DIR" || return 1

                # Build command with all compose files
                local all_services=$(get_available_services | tr '\n' ' ')
                local compose_cmd=$(build_compose_command "$all_services")

                local output_file="/tmp/stack_ps_$$.txt"
                docker compose $compose_cmd ps --format "table" > "$output_file" 2>&1
                dialog --title "Docker Compose Services" --textbox "$output_file" 24 80
                rm -f "$output_file"
                ;;
            "Remove")
                if dialog --yesno "Remove all stopped containers?\n\nThis will remove containers but keep volumes." 9 60; then
                    cd "$DOCKER_DIR" || return 1

                    # Build command with all compose files
                    local all_services=$(get_available_services | tr '\n' ' ')
                    local compose_cmd=$(build_compose_command "$all_services")

                    local output_file="/tmp/stack_rm_$$.txt"
                    if docker compose $compose_cmd rm -f > "$output_file" 2>&1; then
                        dialog --title "Containers Removed" --msgbox "Stopped containers removed successfully!" 8 60
                    else
                        dialog --title "Docker Compose Remove - ERROR" --textbox "$output_file" 24 80
                    fi
                    rm -f "$output_file"
                fi
                ;;
            "Back")
                return
                ;;
        esac
    done
}

# Launch Lazydocker
launch_lazydocker() {
    # Check if lazydocker is installed
    if ! command -v lazydocker &> /dev/null; then
        if dialog --yesno "Lazydocker is not installed.\n\nDo you want to install it now?" 10 50; then
            dialog --infobox "Installing Lazydocker..." 5 40

            # Install lazydocker
            curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1 | tee /tmp/lazydocker_install.log

            if command -v lazydocker &> /dev/null; then
                dialog --msgbox "Lazydocker installed successfully!\n\nLaunching..." 8 50
            else
                dialog --msgbox "Failed to install Lazydocker.\n\nCheck logs: /tmp/lazydocker_install.log" 10 60
                return 1
            fi
        else
            return
        fi
    fi

    # Launch lazydocker
    clear
    lazydocker

    # Return to menu after exit
    display_banner
}

# Create MariaDB Database
create_mariadb_database() {
    local db_name
    local db_user
    local db_pass

    # Check if MariaDB is running
    if ! docker ps | grep -q mariadb; then
        dialog --msgbox "Error: MariaDB container is not running!\n\nPlease install and start MariaDB first." 10 50
        return 1
    fi

    db_name=$(dialog --inputbox "Enter database name:" 10 50 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$db_name" ]]; then
        return
    fi

    db_user=$(dialog --inputbox "Enter database user:" 10 50 "$db_name" 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$db_user" ]]; then
        return
    fi

    db_pass=$(dialog --passwordbox "Enter database password:" 10 50 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$db_pass" ]]; then
        db_pass=$(openssl rand -base64 16)
        dialog --msgbox "Generated password: $db_pass\n\nPlease save this password!" 10 50
    fi

    dialog --infobox "Creating MariaDB database..." 5 40

    # Create database and user
    docker exec mariadb mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $db_name; CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_pass'; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%'; FLUSH PRIVILEGES;" 2>&1

    if [[ $? -eq 0 ]]; then
        dialog --msgbox "MariaDB Database created successfully!\n\nDatabase: $db_name\nUser: $db_user\nPassword: $db_pass\n\nConnection string:\nmariadb://$db_user:$db_pass@mariadb:3306/$db_name" 16 70
    else
        dialog --msgbox "Failed to create MariaDB database!\n\nMake sure MARIADB_ROOT_PASSWORD is set in .env" 10 60
    fi
}

# Create PostgreSQL Database
create_postgresql_database() {
    local db_name
    local db_user
    local db_pass

    # Check if PostgreSQL is running
    if ! docker ps | grep -q postgresql; then
        dialog --msgbox "Error: PostgreSQL container is not running!\n\nPlease install and start PostgreSQL first." 10 50
        return 1
    fi

    db_name=$(dialog --inputbox "Enter database name:" 10 50 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$db_name" ]]; then
        return
    fi

    db_user=$(dialog --inputbox "Enter database user:" 10 50 "$db_name" 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$db_user" ]]; then
        return
    fi

    db_pass=$(dialog --passwordbox "Enter database password:" 10 50 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$db_pass" ]]; then
        db_pass=$(openssl rand -base64 16)
        dialog --msgbox "Generated password: $db_pass\n\nPlease save this password!" 10 50
    fi

    dialog --infobox "Creating PostgreSQL database..." 5 40

    # Create database and user
    docker exec postgresql psql -U postgres -c "CREATE DATABASE $db_name;" 2>&1
    docker exec postgresql psql -U postgres -c "CREATE USER $db_user WITH PASSWORD '$db_pass';" 2>&1
    docker exec postgresql psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;" 2>&1

    if [[ $? -eq 0 ]]; then
        dialog --msgbox "PostgreSQL Database created successfully!\n\nDatabase: $db_name\nUser: $db_user\nPassword: $db_pass\n\nConnection string:\npostgresql://$db_user:$db_pass@postgresql:5432/$db_name" 16 70
    else
        dialog --msgbox "Failed to create PostgreSQL database!" 10 50
    fi
}

# Edit .env file
edit_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: .env file not found!\n\nLocation: $ENV_FILE\n\nPlease configure environment first." 10 60
        return 1
    fi

    # Use default editor or nano
    local editor="${EDITOR:-nano}"

    clear
    $editor "$ENV_FILE"

    display_banner
    dialog --msgbox ".env file editing complete.\n\nRestart services for changes to take effect." 10 50
}

# Edit secrets
edit_secrets() {
    if [[ ! -d "$SECRETS_DIR" ]]; then
        mkdir -p "$SECRETS_DIR"
    fi

    while true; do
        # List all secret files
        local secret_files=()
        if [[ -d "$SECRETS_DIR" ]]; then
            while IFS= read -r file; do
                local filename=$(basename "$file")
                secret_files+=("$filename" "Edit $filename")
            done < <(find "$SECRETS_DIR" -type f | sort)
        fi

        secret_files+=("New Secret" "Create a new secret file")
        secret_files+=("Back" "Return to Tools menu")

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Secrets Editor" \
            --title "Secrets Editor" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Select a secret to edit:" 20 70 10 \
            "${secret_files[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        if [[ "$choice" == "Back" ]]; then
            return
        elif [[ "$choice" == "New Secret" ]]; then
            local secret_name
            secret_name=$(dialog --inputbox "Enter secret name:" 10 50 3>&1 1>&2 2>&3 3>&-)
            if [[ -n "$secret_name" ]]; then
                local editor="${EDITOR:-nano}"
                clear
                $editor "$SECRETS_DIR/$secret_name"
                chmod 600 "$SECRETS_DIR/$secret_name"
                display_banner
            fi
        else
            local editor="${EDITOR:-nano}"
            clear
            $editor "$SECRETS_DIR/$choice"
            chmod 600 "$SECRETS_DIR/$choice"
            display_banner
        fi
    done
}

# Edit version pins
edit_version_pins() {
    dialog --msgbox "Version Pins allow you to pin Docker images to specific versions.\n\nThis feature will edit compose files to set specific image tags." 12 60

    # This would typically edit a version pins configuration file
    # For now, show a message
    dialog --msgbox "Feature: Version Pins\n\nTo be implemented\n\nYou can manually edit compose files to pin versions:\nimage: container:version\n\nExample:\nimage: traefik:3.3" 14 60
}

# Change hostname
change_hostname() {
    local new_hostname
    local old_hostname="$HOSTNAME"

    new_hostname=$(dialog --inputbox "Enter new hostname:\n\nCurrent hostname: $old_hostname" 10 60 3>&1 1>&2 2>&3 3>&-)

    if [[ -z "$new_hostname" ]] || [[ "$new_hostname" == "$old_hostname" ]]; then
        return
    fi

    if ! dialog --yesno "Change hostname from '$old_hostname' to '$new_hostname'?\n\nThis will:\n- Update Traefik rules directory\n- Update compose files\n- Update configuration files" 12 60; then
        return
    fi

    dialog --infobox "Changing hostname..." 5 40

    # Update Traefik rules directory
    if [[ -d "$DOCKER_DIR/appdata/traefik3/rules/$old_hostname" ]]; then
        mv "$DOCKER_DIR/appdata/traefik3/rules/$old_hostname" "$DOCKER_DIR/appdata/traefik3/rules/$new_hostname"
    fi

    # Update HOSTNAME in .env
    if [[ -f "$ENV_FILE" ]]; then
        sed -i "s/HOSTNAME=$old_hostname/HOSTNAME=$new_hostname/g" "$ENV_FILE"
    fi

    # Update docker-compose.yml references
    if [[ -f "$COMPOSE_FILE" ]]; then
        sed -i "s/\$HOSTNAME/$new_hostname/g" "$COMPOSE_FILE"
    fi

    dialog --msgbox "Hostname changed successfully!\n\nOld: $old_hostname\nNew: $new_hostname\n\nPlease restart services for changes to take effect." 12 60
}

# Change server IP
change_server_ip() {
    local new_ip
    local old_ip="$SERVER_IP"

    new_ip=$(dialog --inputbox "Enter new server IP:\n\nCurrent IP: $old_ip" 10 60 3>&1 1>&2 2>&3 3>&-)

    if [[ -z "$new_ip" ]] || [[ "$new_ip" == "$old_ip" ]]; then
        return
    fi

    # Validate IP format
    if ! [[ "$new_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        dialog --msgbox "Error: Invalid IP address format!" 8 50
        return 1
    fi

    if ! dialog --yesno "Change server IP from '$old_ip' to '$new_ip'?\n\nThis will update .env file." 10 60; then
        return
    fi

    dialog --infobox "Changing server IP..." 5 40

    # Update SERVER_IP in .env
    if [[ -f "$ENV_FILE" ]]; then
        sed -i "s/SERVER_IP=$old_ip/SERVER_IP=$new_ip/g" "$ENV_FILE"
        sed -i "s/SERVER_LAN_IP=$old_ip/SERVER_LAN_IP=$new_ip/g" "$ENV_FILE"
    fi

    SERVER_IP="$new_ip"
    save_config

    dialog --msgbox "Server IP changed successfully!\n\nOld: $old_ip\nNew: $new_ip\n\nPlease restart services for changes to take effect." 12 60
}

# Health diagnostics
health_diagnostics() {
    dialog --infobox "Running system health checks..." 5 40

    local report="/tmp/zoolandia_health.txt"

    {
        echo "=== Zoolandia Health Diagnostics ==="
        echo "Generated: $(date)"
        echo ""
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 -d: || echo 'Unknown')"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo ""
        echo "=== Docker Status ==="
        if docker info &>/dev/null; then
            echo "Docker: Running"
            docker version | grep -E "Version|Server"
        else
            echo "Docker: Not running or not installed"
        fi
        echo ""
        echo "=== Disk Usage ==="
        df -h "$DOCKER_DIR" 2>/dev/null || echo "Docker directory not found"
        echo ""
        echo "=== Docker Compose Status ==="
        if [[ -f "$COMPOSE_FILE" ]]; then
            cd "$DOCKER_DIR" && docker compose ps 2>/dev/null || echo "No services running"
        else
            echo "docker-compose.yml not found"
        fi
        echo ""
        echo "=== Network Connectivity ==="
        if ping -c 1 1.1.1.1 &>/dev/null; then
            echo "Internet: Connected"
        else
            echo "Internet: Not connected"
        fi
        echo ""
        echo "=== Port Status ==="
        echo "Port 80: $(ss -tuln | grep -q ':80 ' && echo 'In use' || echo 'Available')"
        echo "Port 443: $(ss -tuln | grep -q ':443 ' && echo 'In use' || echo 'Available')"
    } > "$report"

    dialog --textbox "$report" 24 80

    if dialog --yesno "Save report to file?" 7 40; then
        local save_path="$BACKUP_DIR/health-report-$(date +%Y%m%d-%H%M%S).txt"
        mkdir -p "$BACKUP_DIR"
        cp "$report" "$save_path"
        dialog --msgbox "Report saved to:\n$save_path" 8 60
    fi
}
