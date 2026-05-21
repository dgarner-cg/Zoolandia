#!/bin/bash
################################################################################
# Nexus v5.10 - Settings Module
#
# Description: Settings menu for Nexus configuration, updates, and management
################################################################################

# Settings menu
show_settings_menu() {
    while true; do
        # Get current settings for display
        local intro_status="${SHOW_INTRO_MESSAGES:-ON}"
        local mode_status="${NEXUS_MODE:-NORMAL}"

        local license_summary
        license_summary=$(nx_license_status 2>/dev/null || echo "No license")

        local menu_items=(
            "License" "Manage License — $license_summary"
            "Intro" "Toggle Intro Messages - $intro_status"
            "Mode" "Toggle Nexus Mode - $mode_status"
            "Status" "View Nexus configuration status"
            "Logs" "Generate Sanitized Nexus Log"
            "Refresh" "Clear Nexus Cache"
            "Update" "Check for and install updates"
            "Reset" "Reset Nexus configuration"
            "Remove" "Completely remove Nexus"
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
            "License") show_license_menu ;;
            "Intro") toggle_intro_messages ;;
            "Mode") toggle_nexus_mode ;;
            "Status") view_status ;;
            "Logs") generate_sanitized_log ;;
            "Refresh") clear_nexus_cache ;;
            "Update") update_script ;;
            "Reset") reset_deployrr ;;
            "Remove") remove_deployrr ;;
            "Back") return ;;
        esac
    done
}

# License management menu
show_license_menu() {
    while true; do
        # Build current status summary for the menu header
        local status_line
        status_line=$(nx_license_status 2>/dev/null || echo "No license installed")

        local key_file_info="Not installed"
        local features_line="None"
        local tier_line="Free"
        local expires_line="—"
        local email_line="—"

        if [[ -f "$LICENSE_FILE" ]]; then
            local key payload rc
            key=$(cat "$LICENSE_FILE")
            payload=$(nx_validate_key "$key" 2>/dev/null); rc=$?
            if [[ $rc -eq 0 ]]; then
                email_line=$(_nx_json_field "$payload" "email")
                tier_line=$(_nx_json_field "$payload" "tier")
                expires_line=$(_nx_json_field "$payload" "expires")
                features_line=$(echo "$payload" | grep -oP '"features":\[[^\]]*\]' | \
                    grep -oP '"[^"]*"' | tr -d '"' | tr '\n' ',' | sed 's/,$//')
                key_file_info="Installed"
            elif [[ $rc -eq 2 ]]; then
                key_file_info="EXPIRED"
                email_line=$(_nx_json_field "$payload" "email" 2>/dev/null || echo "—")
                tier_line=$(_nx_json_field "$payload" "tier" 2>/dev/null || echo "—")
                expires_line=$(_nx_json_field "$payload" "expires" 2>/dev/null || echo "—")
            else
                key_file_info="INVALID"
            fi
        fi

        local header="License Status\n\n\
  Status:   ${key_file_info}\n\
  Email:    ${email_line}\n\
  Tier:     ${tier_line}\n\
  Expires:  ${expires_line}\n\
  Location: ${LICENSE_FILE}"

        local choice
        choice=$(dialog --clear \
            --backtitle "$SCRIPT_NAME — License" \
            --title "License & Activation" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "${header}" 22 72 5 \
            "Activate"  "Enter or replace license key" \
            "Validate"  "Re-validate current license key" \
            "Features"  "View license features" \
            "Remove"    "Remove installed license key" \
            "Back"      "Return to Settings" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Activate")
                nx_activate_license
                ;;
            "Features")
                if [[ "$features_line" == "None" ]]; then
                    dialog --title " License Features " --msgbox "\nNo license installed — running Free tier.\n" 7 45
                else
                    local bullet_features=""
                    while IFS= read -r feat; do
                        [[ -n "$feat" ]] && bullet_features+="  • ${feat}\n"
                    done < <(echo "$features_line" | tr ',' '\n')
                    dialog --title " License Features " --msgbox "\nFeatures included with your license:\n\n${bullet_features}" 20 55
                fi
                ;;
            "Validate")
                if [[ ! -f "$LICENSE_FILE" ]]; then
                    dialog --msgbox "\nNo license key installed.\n\nUse Activate to enter a key." 9 50
                else
                    local vkey vpayload vrc
                    vkey=$(cat "$LICENSE_FILE")
                    vpayload=$(nx_validate_key "$vkey" 2>/dev/null); vrc=$?
                    case $vrc in
                        0)
                            local vemail vtier vexpires vfeatures_csv vfeatures_bullets=""
                            vemail=$(_nx_json_field "$vpayload" "email")
                            vtier=$(_nx_json_field "$vpayload" "tier")
                            vexpires=$(_nx_json_field "$vpayload" "expires")
                            vfeatures_csv=$(echo "$vpayload" | grep -oP '"features":\[[^\]]*\]' | \
                                grep -oP '"[^"]*"' | tr -d '"' | tr '\n' ',' | sed 's/,$//')
                            while IFS= read -r feat; do
                                [[ -n "$feat" ]] && vfeatures_bullets+="    • ${feat}\n"
                            done < <(echo "$vfeatures_csv" | tr ',' '\n')
                            dialog --title " License Valid " --msgbox "\
\n\
  Signature:  VALID (Ed25519 verified)\n\
  Email:      ${vemail}\n\
  Tier:       ${vtier}\n\
  Expires:    ${vexpires}\n\
  Features:\n${vfeatures_bullets}" 20 65
                            ;;
                        2)
                            dialog --title " License Expired " --msgbox "\
\n\
  Signature verified — but this license has EXPIRED.\n\n\
  Renew at: https://nexus.dev/pricing\n" 10 60
                            ;;
                        *)
                            dialog --title " License Invalid " --msgbox "\
\n\
  Signature verification FAILED.\n\n\
  The key may be corrupted or tampered with.\n\
  Re-activate with a fresh key from your account.\n" 11 60
                            ;;
                    esac
                fi
                ;;
            "Remove")
                if [[ ! -f "$LICENSE_FILE" ]]; then
                    dialog --msgbox "\nNo license key is currently installed." 7 50
                else
                    if dialog --yesno "\nRemove the installed license key?\n\nThis will revert all licensed features to free tier." 10 58; then
                        rm -f "$LICENSE_FILE"
                        dialog --msgbox "\nLicense removed.\n\nFeatures reverted to free tier." 8 45
                    fi
                fi
                ;;
            "Back") return ;;
        esac
    done
}
