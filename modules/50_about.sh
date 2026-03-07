#!/bin/bash
################################################################################
# Zoolandia v5.10 - About Module
#
# Description: About menu with documentation, changelog, support logs, and
#              cache management
################################################################################

# About menu
show_about_menu() {
    while true; do
        local menu_items=(
            "License Information" "View license types and info"
            "View Changelog" "View version history"
            "View Online Changelog" "View latest changelog from GitHub"
            "API Data" "View Community Scripts API Data"
            "Documentation" "Open documentation links"
            "Feedback" "Submit a Review/Feedback"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME About" \
            --title "About Menu" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Select an option:" 22 70 10 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "License Information") show_license_info ;;
            "View Changelog") view_changelog ;;
            "View Online Changelog") view_online_changelog ;;
            "API Data") view_api_data ;;
            "Documentation") show_documentation ;;
            "Feedback") show_feedback ;;
            "Back") return ;;
        esac
    done
}

# Feedback
show_feedback() {
    dialog --msgbox "Thank you for using Zoolandia!\n\nTo submit feedback, please visit:\nhttps://www.simplehomelab.com/zoolandia/feedback/" 12 60
}

# Show documentation
show_documentation() {
    dialog --msgbox "Documentation:\n\nhttps://docs.zoolandia.app\nhttps://www.simplehomelab.com/zoolandia/" 12 60
}

# Generate sanitized log for support
generate_sanitized_log() {
    local log_file="${HOME}/zoolandia-support-$(date +%Y%m%d-%H%M%S).log"
    local temp_file="/tmp/zoolandia_log_temp.txt"

    # Show info dialog
    dialog --infobox "Generating sanitized support log...\n\nPlease wait..." 5 50

    # Start log file
    {
        echo "========================================="
        echo "Zoolandia Support Log"
        echo "Generated: $(date)"
        echo "========================================="
        echo ""

        echo "=== System Information ==="
        echo "OS: $(lsb_release -d 2>/dev/null | cut -f2- || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Hostname: [REDACTED]"
        echo ""

        echo "=== Zoolandia Configuration ==="
        echo "Version: ${ZOOLANDIA_VERSION}"
        echo "System Type: ${SYSTEM_TYPE:-Not Set}"
        echo "Setup Mode: ${SETUP_MODE:-Not Set}"
        echo "Docker Directory: ${DOCKER_DIR}"
        echo "Telemetry: ${TELEMETRY_ENABLED}"
        echo "Intro Messages: ${SHOW_INTRO_MESSAGES}"
        echo "Mode: ${ZOOLANDIA_MODE}"
        echo ""

        echo "=== Docker Information ==="
        if command -v docker &>/dev/null; then
            echo "Docker Version: $(docker --version 2>/dev/null || echo 'Not available')"
            echo "Docker Compose Version: $(docker compose version 2>/dev/null || echo 'Not available')"
            echo ""
            echo "Running Containers:"
            docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -n 20 || echo "Unable to retrieve container list"
        else
            echo "Docker: Not installed"
        fi
        echo ""

        echo "=== Disk Space ==="
        df -h "${DOCKER_DIR}" 2>/dev/null || echo "Unable to check disk space"
        echo ""

        echo "=== Recent Errors (Last 50 lines) ==="
        if [ -f "${DOCKER_DIR}/logs/zoolandia.log" ]; then
            tail -n 50 "${DOCKER_DIR}/logs/zoolandia.log" 2>/dev/null | sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[IP-REDACTED]/g' || echo "No log file found"
        else
            echo "No log file found"
        fi
        echo ""

        echo "=== Configuration Summary ==="
        if [ -f "$ZOOLANDIA_CONFIG_DIR/zoolandia.conf" ]; then
            cat "$ZOOLANDIA_CONFIG_DIR/zoolandia.conf" | \
                sed 's/SMTP_PASS=.*/SMTP_PASS="[REDACTED]"/' | \
                sed 's/SMTP_USER=.*/SMTP_USER="[REDACTED]"/' | \
                sed 's/SERVER_IP=.*/SERVER_IP="[REDACTED]"/' | \
                sed 's/DOMAIN_1=.*/DOMAIN_1="[REDACTED]"/'
        else
            echo "No configuration file found"
        fi
        echo ""

        echo "========================================="
        echo "End of Support Log"
        echo "========================================="

    } > "$log_file" 2>&1

    # Compress log
    if gzip "$log_file" 2>/dev/null; then
        log_file="${log_file}.gz"
    fi

    # Success message
    dialog --msgbox "Support log generated successfully!\n\nLocation:\n$log_file\n\nThis log contains sanitized system information.\nSensitive data (passwords, IPs, domains) has been removed.\n\nYou can safely share this file with support." 14 70
}

# Clear Zoolandia cache
clear_zoolandia_cache() {
    local cache_size
    local cache_files

    # Check cache directory
    if [ ! -d "$ZOOLANDIA_CACHE_DIR" ]; then
        dialog --msgbox "Cache directory does not exist.\n\nNothing to clear." 8 50
        return
    fi

    # Get cache info
    cache_files=$(find "$ZOOLANDIA_CACHE_DIR" -type f 2>/dev/null | wc -l)
    cache_size=$(du -sh "$ZOOLANDIA_CACHE_DIR" 2>/dev/null | cut -f1 || echo "Unknown")

    # Confirm deletion
    local msg="Zoolandia Cache Information:\n\n"
    msg+="Location: $ZOOLANDIA_CACHE_DIR\n"
    msg+="Files: $cache_files\n"
    msg+="Size: $cache_size\n\n"
    msg+="The cache contains:\n"
    msg+="• Temporary app status data\n"
    msg+="• Downloaded app icons\n"
    msg+="• Installation state tracking\n\n"
    msg+="Clearing cache will:\n"
    msg+="• Free up disk space\n"
    msg+="• Reset app status checks\n"
    msg+="• Force fresh data on next run\n\n"
    msg+="Cache will be rebuilt automatically as needed."

    if ! dialog --title "Clear Zoolandia Cache" \
        --yes-label "Clear Cache" \
        --no-label "Cancel" \
        --yesno "$msg" 22 70; then
        return
    fi

    # Clear cache
    dialog --infobox "Clearing cache...\n\nPlease wait..." 5 40

    if sudo rm -rf "${ZOOLANDIA_CACHE_DIR:?}"/* 2>/dev/null; then
        dialog --msgbox "Cache cleared successfully!\n\nFreed: $cache_size\nRemoved: $cache_files files\n\nCache will be rebuilt as needed." 10 50
    else
        dialog --msgbox "Error clearing cache.\n\nSome files may require manual deletion." 8 50
    fi
}
