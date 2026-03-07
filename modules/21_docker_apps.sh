#!/bin/bash
################################################################################
# Zoolandia v5.10 - Docker Apps Module
#
# Description: Docker applications menu with app selection, batch installation,
#              and container management
################################################################################

# Docker Apps submenu (original functionality)
show_docker_apps_menu() {
    while true; do
        local compose_dir="$SCRIPT_DIR/compose"
        local app_list=()

        # Read all available apps from compose directory
        if [[ -d "$compose_dir" ]]; then
            while IFS= read -r compose_file; do
                local app_name
                app_name=$(basename "$compose_file" .yml)

                # Skip ansible apps - they're in SysConfig now
                case "$app_name" in
                    bitwarden|discord|docker|icloud|mailspring|n8n|notepad-plus-plus|notion|onlyoffice|portainer|protonvpn|termius|twingate|ulauncher|vivaldi|zoom)
                        continue
                        ;;
                esac

                # Check if app is already installed
                local status="off"
                local status_indicator=""
                if [[ -f "$DOCKER_DIR/compose/${app_name}.yml" ]]; then
                    status_indicator=" - \Z2INSTALLED\Zn"
                fi

                # Get description for the app
                local description
                description=$(get_app_description "$app_name")

                app_list+=("$app_name" "${description}${status_indicator}" "$status")
            done < <(find "$compose_dir" -name "*.yml" -type f | sort)
        fi

        local choices
        choices=$(dialog --clear --colors --backtitle "$SCRIPT_NAME Apps" \
            --title "Docker Apps Menu (150+ Supported Apps)" \
            --ok-label "Install Selected" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect apps, ENTER to install:\n\n(Already installed apps are pre-checked)" 24 70 15 \
            "${app_list[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        # If no apps selected, return
        if [[ -z "$choices" ]]; then
            return
        fi

    # Parse selected apps (dialog returns space-separated quoted strings)
    local selected_apps=()
    eval "selected_apps=($choices)"

    # Count total apps to install
    local total_apps=${#selected_apps[@]}
    local current_app=0

    # For batch installation, ask about common settings once
    local batch_gpu_enabled="no"
    local batch_traefik_enabled="no"
    local batch_mode="no"

    if [[ $total_apps -gt 1 ]]; then
        batch_mode="yes"

        # Ask about GPU for all apps
        if dialog --yes-label "Yes" --no-label "No" --yesno "Enable GPU/Hardware transcoding for all apps that support it?" 8 60; then
            batch_gpu_enabled="yes"
        fi

        # Ask about Traefik for all apps
        if dialog --yes-label "Yes" --no-label "No" --yesno "Configure Traefik reverse proxy for all apps?" 8 60; then
            batch_traefik_enabled="yes"
        fi
    fi

    # Install each selected app
    local successful_installs=0
    local failed_installs=0
    for app_name in "${selected_apps[@]}"; do
        ((current_app++))

        # Show progress
        dialog --infobox "Installing apps...\n\nProgress: $current_app of $total_apps\n\nCurrently installing: $app_name" 10 50
        sleep 1

        # Install the app with batch settings
        if [[ "$batch_mode" == "yes" ]]; then
            if install_app_batch "$app_name" "$batch_gpu_enabled" "$batch_traefik_enabled"; then
                ((successful_installs++))
            else
                ((failed_installs++))
            fi
        else
            if install_app "$app_name"; then
                ((successful_installs++))
            else
                ((failed_installs++))
            fi
        fi
    done

        # Show completion message and optionally start containers
        if [[ $failed_installs -eq 0 ]] && [[ $successful_installs -gt 0 ]]; then
            # All succeeded
            if [[ $successful_installs -eq 1 ]]; then
                local msg="1 app configured successfully."
            else
                local msg="$successful_installs apps configured successfully."
            fi

            # Ask if user wants to start containers (only for batch mode)
            if [[ "$batch_mode" == "yes" ]]; then
                if dialog --yesno "$msg\n\nDo you want to start all containers now?" 10 60; then
                    # Check if Docker is running
                    if ! docker info >/dev/null 2>&1; then
                        dialog --msgbox "Error: Docker is not running!\n\nPlease start Docker first:\nsudo systemctl start docker\n\nThen use Tools > Stack Manager" 12 70
                    else
                        # Check .env file permissions before attempting to start
                        if [[ -f "$ENV_FILE" ]]; then
                            if ! test -r "$ENV_FILE"; then
                                if dialog --yesno "Error: Cannot read .env file (permission denied)\n\nThis usually means the .env file has incorrect ownership/permissions.\n\nWould you like to fix this now?" 12 70; then
                                    if pkexec chown "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$ENV_FILE" && \
                                       pkexec chmod 640 "$ENV_FILE"; then
                                        dialog --msgbox "Permissions fixed!\n\nContinuing with container startup..." 8 60
                                        sleep 1
                                    else
                                        dialog --msgbox "Failed to fix permissions.\n\nPlease run: Tools > Permissions\n\nThen try starting containers again." 10 70
                                        return
                                    fi
                                else
                                    dialog --msgbox "Cannot start containers without .env file access.\n\nPlease run: Tools > Permissions\n\nThen try again." 10 70
                                    return
                                fi
                            fi
                        fi

                        # Start all containers
                        dialog --infobox "Starting containers...\n\nThis may take a moment..." 6 50

                        if cd "$DOCKER_DIR" && docker compose up -d 2>&1 | tee /tmp/docker_compose_batch.log; then
                            sleep 2
                            dialog --msgbox "$msg\n\nContainers have been started.\n\nUse Tools > Stack Manager to view status." 12 70
                        else
                            dialog --title "Container Start Issues" --textbox /tmp/docker_compose_batch.log 24 80
                            dialog --msgbox "Some containers may have issues.\n\nUse Tools > Stack Manager to check status." 10 70
                        fi
                        rm -f /tmp/docker_compose_batch.log
                    fi
                else
                    dialog --msgbox "$msg\n\nUse Tools > Stack Manager to start containers later." 10 70
                fi
            else
                dialog --msgbox "$msg" 8 50
            fi
        elif [[ $successful_installs -eq 0 ]] && [[ $failed_installs -gt 0 ]]; then
            # All failed or cancelled
            dialog --msgbox "Installation cancelled or failed.\n\nNo apps were installed." 10 50
        else
            # Mixed results
            dialog --msgbox "Installation partially complete.\n\nSuccessful: $successful_installs\nFailed/Cancelled: $failed_installs\n\nUse Tools > Stack Manager to manage containers." 12 70
        fi
    done
}
