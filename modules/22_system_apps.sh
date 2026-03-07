#!/bin/bash
################################################################################
# Zoolandia v5.10 - System Apps Module
#
# Description: System applications menu for Ansible-based desktop applications
#              (browsers, editors, VPN clients, etc.)
################################################################################

# System Apps submenu (Ansible-based apps)
show_system_apps_menu() {
    while true; do
        local ansible_apps_dir="$SCRIPT_DIR/compose"
        local app_list=()

        # List of ansible-based apps (not docker compose apps)
        local ansible_apps=("bitwarden" "discord" "docker" "icloud" "mailspring" "n8n" "notepad-plus-plus" "notion" "onlyoffice" "portainer" "protonvpn" "termius" "twingate" "ulauncher" "vivaldi" "zoom")

        # Build app list from ansible apps with descriptions
        for app_name in "${ansible_apps[@]}"; do
            if [[ -f "$ansible_apps_dir/${app_name}.yml" ]]; then
                # Get description for the app
                local description
                description=$(get_app_description "$app_name")

                # Check if app is installed
                local status="off"
                local status_indicator=""
                if check_system_app_installed "$app_name"; then
                    status_indicator=" - \Z2INSTALLED\Zn"
                fi

                app_list+=("$app_name" "${description}${status_indicator}" "$status")
            fi
        done

        local choices
        choices=$(dialog --clear --colors --backtitle "$SCRIPT_NAME SysConfig" \
            --title "System Applications (Installed via Ansible)" \
            --ok-label "Install Selected" \
            --cancel-label "Back" \
            --checklist "Use SPACE to select/deselect apps, ENTER to install:" 24 80 15 \
            "${app_list[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        # If no apps selected, return
        if [[ -z "$choices" ]]; then
            return
        fi

        # Parse selected apps
        local selected_apps=()
        eval "selected_apps=($choices)"

        # Install each selected app
        local total_apps=${#selected_apps[@]}
        local current_app=0
        local successful_installs=0
        local failed_installs=0

        for app_name in "${selected_apps[@]}"; do
            ((current_app++))
            dialog --infobox "Installing apps...\n\nProgress: $current_app of $total_apps\n\nCurrently installing: $app_name" 10 50
            if install_ansible_app "$app_name"; then
                ((successful_installs++))
            else
                ((failed_installs++))
            fi
        done

        # Show completion message
        if [[ $failed_installs -eq 0 ]] && [[ $successful_installs -gt 0 ]]; then
            # All succeeded
            dialog --msgbox "Installation complete!\n\n$successful_installs app(s) installed successfully." 10 50
        elif [[ $successful_installs -eq 0 ]] && [[ $failed_installs -gt 0 ]]; then
            # All failed or cancelled
            dialog --msgbox "Installation cancelled or failed.\n\nNo apps were installed." 10 50
        else
            # Mixed results
            dialog --msgbox "Installation partially complete.\n\nSuccessful: $successful_installs\nFailed/Cancelled: $failed_installs" 10 50
        fi
    done
}
