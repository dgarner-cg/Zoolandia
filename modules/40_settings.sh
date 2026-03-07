#!/bin/bash
################################################################################
# Zoolandia v5.10 - Settings Module
#
# Description: Settings menu for Zoolandia configuration, updates, and management
################################################################################

# Settings menu
show_settings_menu() {
    while true; do
        # Get current settings for display
        local intro_status="${SHOW_INTRO_MESSAGES:-ON}"
        local mode_status="${ZOOLANDIA_MODE:-NORMAL}"

        local menu_items=(
            "Intro" "Toggle Intro Messages - $intro_status"
            "Mode" "Toggle Zoolandia Mode - $mode_status"
            "Status" "View Zoolandia configuration status"
            "Logs" "Generate Sanitized Zoolandia Log"
            "Refresh" "Clear Zoolandia Cache"
            "Update" "Check for and install updates"
            "Reset" "Reset Zoolandia configuration"
            "Remove" "Completely remove Zoolandia"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME Settings" \
            --title "Settings Menu" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Select an option:" 22 70 8 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Intro") toggle_intro_messages ;;
            "Mode") toggle_zoolandia_mode ;;
            "Status") view_status ;;
            "Logs") generate_sanitized_log ;;
            "Refresh") clear_zoolandia_cache ;;
            "Update") update_script ;;
            "Reset") reset_deployrr ;;
            "Remove") remove_deployrr ;;
            "Back") return ;;
        esac
    done
}

# Show license info
show_license_info() {
    dialog --msgbox "Feature: License Information\n\nTo be implemented" 10 50
}
