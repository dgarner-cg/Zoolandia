#!/bin/bash
################################################################################
# Zoolandia v5.10 - Main Menu Module
#
# Description: Main menu interface and quick search functionality
################################################################################

show_main_menu() {
    while true; do
        local license_type="Free"
        local mode="Standard"
        local system_health="Not Applicable (until Prerequisites are completed)"

        if [[ $PREREQUISITES_DONE == true ]]; then
            system_health="OK"
        fi

        # Get packages status for main menu
        local packages_status="\Z2DONE\Zn"
        if ! command -v dialog &>/dev/null; then
            packages_status="\Z1NOT DONE\Zn"
        fi

        local menu_items=(
            "Search" "🔍 Quick Search Apps (Ctrl+K)"
            "Prerequisites" "Required Steps - $([ $PREREQUISITES_DONE == true ] && echo '\Z2DONE\Zn' || echo '\Z1NOT DONE\Zn')"
            "Software Packages" "Package Installation Options - $packages_status"
            "System" "System Preparation, Folders, etc."
            "Docker Settings" "Socket Proxy, Maintenance, etc."
            "Reverse Proxy" "Traefik Setup and Management"
            "Security" "Authelia, Google OAuth, CrowdSec, etc."
            "Apps" "Install Docker Apps (150+ Available)"
            "Ansible" "System Onboarding, Apps, Power, Touchpad, Updates"
            "Secret" "Secret Projects and Custom Playbooks"
            "Tools" "Stack Manager, Backups, Diagnostics, etc."
            "Settings" "Zoolandia Mode, Status, Logs, Reset, and Remove"
            "About" "Licenses, Offers, Feedback, Changelog, etc."
        )

        local choice
        choice=$(dialog --clear --colors --backtitle "$SCRIPT_NAME by hack3r.gg - v$ZOOLANDIA_VERSION" \
            --title "Main Menu (Hostname: $HOSTNAME | License: $license_type | Mode: $mode)" \
            --ok-label "Select" \
            --cancel-label "Quit" \
            --menu "\nSystem Health: $system_health\n\nPress 's' for Quick Search | Select an option:" 24 80 13 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return 1

        case "$choice" in
            "Search") spotlight_search ;;
            "Prerequisites") show_prerequisites_menu ;;
            "Software Packages") show_packages_menu ;;
            "System") show_system_menu ;;
            "Docker Settings") show_docker_menu ;;
            "Reverse Proxy") show_reverse_proxy_menu ;;
            "Security") show_security_menu ;;
            "Apps") show_apps_menu ;;
            "Ansible") show_ansible_menu ;;
            "Secret") show_secret_menu ;;
            "Tools") show_tools_menu ;;
            "Settings") show_settings_menu ;;
            "About") show_about_menu ;;
        esac
    done
}

spotlight_search() {
    local compose_dir="$SCRIPT_DIR/compose"
    local search_term=""

    # Get search input
    search_term=$(dialog --ok-label "Search" --cancel-label "Cancel" \
        --inputbox "🔍 Search for a script...\n\nEnter app name or keyword:" 10 60 3>&1 1>&2 2>&3 3>&-)

    # If cancelled or empty, return
    if [[ -z "$search_term" ]]; then
        return
    fi

    local matches=()
    local count=0
    local term_lower="${search_term,,}"

    # Search Docker compose apps
    if [[ -d "$compose_dir" ]]; then
        while IFS= read -r compose_file; do
            local app_name
            app_name=$(basename "$compose_file" .yml)
            if [[ "${app_name,,}" == *"$term_lower"* ]] || [[ "$term_lower" == *"${app_name,,}"* ]]; then
                local status="[ ]"
                if [[ -f "$DOCKER_DIR/compose/${app_name}.yml" ]]; then
                    status="[✓]"
                fi
                matches+=("$app_name" "$status [Docker] $app_name")
                ((count++))
            fi
        done < <(find "$compose_dir" -name "*.yml" -type f | sort)
    fi

    # Search Ansible apps (name|category|description)
    local ansible_apps=(
        "vivaldi|Workstation|Vivaldi Browser"
        "bitwarden|Workstation|Bitwarden Password Manager"
        "notepad|Workstation|Notepad++ Text Editor"
        "notion|Workstation|Notion Productivity App"
        "obsidian|Workstation|Obsidian Knowledge Base"
        "mailspring|Workstation|Mailspring Email Client"
        "claude-code|Workstation|Claude AI Code Assistant"
        "chatgpt|Workstation|ChatGPT Desktop Client"
        "codex|Workstation|OpenAI Codex CLI"
        "gemini|Workstation|Google Gemini CLI"
        "icloud|Workstation|iCloud for Linux"
        "discord|Workstation|Discord Communication"
        "zoom|Workstation|Zoom Video Conferencing"
        "termius|Workstation|Termius SSH Client"
        "onlyoffice|Workstation|OnlyOffice Suite"
        "chrome-ext|Workstation|Chrome Extensions"
        "docker|Workstation|Docker Container Platform"
        "portainer|Workstation|Portainer Docker Management"
        "twingate|Workstation|Twingate VPN Client"
        "protonvpn|Workstation|ProtonVPN Client"
        "ulauncher|Workstation|Ulauncher App Launcher"
        "n8n|Workstation|n8n Workflow Automation"
        "sublime-text|Workstation|Sublime Text Editor"
        "power|Config|Power Management"
        "touchpad|Config|Touchpad Settings"
        "mouse|Config|Mouse Settings"
        "nautilus|Config|Nautilus File Manager"
        "ntfs|Config|NTFS/exFAT Filesystem Support"
        "razer|Config|Razer Laptop GRUB Config"
        "fail2ban|Security|Fail2ban Intrusion Prevention"
        "clamav|Security|ClamAV Antivirus"
        "auditd|Security|Auditd System Auditing"
        "ufw|Security|UFW Firewall"
        "git|Common|Git version control"
        "curl|Common|cURL transfer tool"
        "wget|Common|Wget download tool"
        "tmux|Common|Terminal multiplexer"
        "tree|Common|Directory tree viewer"
        "htop|Common|Interactive process viewer"
        "gotop|Common|System monitor"
        "jq|Common|JSON processor"
        "fzf|Common|Fuzzy finder"
        "ripgrep|Common|Fast grep alternative"
        "ncdu|Common|Disk usage analyzer"
        "neofetch|Common|System information"
        "bat|Common|Cat with syntax highlighting"
        "rclone|Common|Cloud storage sync"
        "openssh-server|Common|OpenSSH server"
        "net-tools|Common|Network tools"
        "dnsutils|Common|DNS utilities"
        "glances|Common|System monitor"
        "nodejs|Common|Node.js runtime"
        "yarn|Common|Yarn package manager"
        "postgresql|Database|PostgreSQL server"
        "mysql|Database|MySQL server"
        "mariadb|Database|MariaDB server"
        "redis|Database|Redis in-memory DB"
        "mongodb|Database|MongoDB NoSQL"
        "pgadmin|Database|PostgreSQL admin"
        "phpmyadmin|Database|MySQL admin"
        "adminer|Database|Database admin"
        "pgbackrest|Database|PostgreSQL backup"
        "nginx|Web|Nginx web server"
        "apache2|Web|Apache web server"
        "traefik|Web|Traefik reverse proxy"
        "haproxy|Web|HAProxy load balancer"
        "certbot|Web|Let's Encrypt SSL"
        "php-fpm|Web|PHP FastCGI"
        "redis-server|Web|Redis caching"
        "memcached|Web|Memcached caching"
        "vscode-tunnel|AppServer|VS Code Tunnel"
        "jenkins|AppServer|Jenkins CI/CD"
        "kubernetes|AppServer|Kubernetes CLI tools"
        "boundary|HashiCorp|Boundary secure remote access"
        "consul|HashiCorp|Consul service networking"
        "nomad|HashiCorp|Nomad workload orchestration"
        "packer|HashiCorp|Packer image builder"
        "terraform|HashiCorp|Terraform infrastructure as code"
        "vault|HashiCorp|Vault secrets management"
        "vault-radar|HashiCorp|Vault Radar secret sprawl detection"
        "waypoint|HashiCorp|Waypoint developer platform"
        "grafana|Monitoring|Grafana Dashboard"
        "prometheus|Monitoring|Prometheus Metrics DB"
        "influxdb|Monitoring|InfluxDB Time-Series DB"
        "telegraf|Monitoring|Telegraf Metrics Agent"
        "node-exporter|Monitoring|Node Exporter system metrics"
        "cadvisor|Monitoring|cAdvisor Container Metrics"
        "elasticsearch|Monitoring|Elasticsearch"
        "kibana|Monitoring|Kibana Visualization"
    )
    for entry in "${ansible_apps[@]}"; do
        IFS='|' read -r name category desc <<< "$entry"
        if [[ "${name,,}" == *"$term_lower"* ]] || [[ "$term_lower" == *"${name,,}"* ]] || \
           [[ "${desc,,}" == *"$term_lower"* ]]; then
            matches+=("ansible:$name" "[Ansible/$category] $desc")
            ((count++))
        fi
    done

    # Show results
    if [[ $count -eq 0 ]]; then
        dialog --msgbox "No apps found matching: $search_term\n\nTry a different search term." 10 50
        return
    fi

    matches+=("Search Again" "New search")
    matches+=("Back" "Return to menu")

    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Search Results" \
        --title "Found $count apps matching '$search_term'" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --menu "Select an app to install:" 24 70 15 \
        "${matches[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$choice" in
        "Search Again")
            spotlight_search
            ;;
        "Back")
            return
            ;;
        ansible:*)
            show_ansible_menu
            ;;
        *)
            install_app "$choice"
            ;;
    esac
}

# View local changelog
view_changelog() {
    if [[ -f "$SCRIPT_DIR/documentation/CHANGELOG.md" ]]; then
        dialog --textbox "$SCRIPT_DIR/documentation/CHANGELOG.md" 24 80
    else
        dialog --msgbox "Changelog not found!" 8 50
    fi
}

# View online changelog from GitHub
view_online_changelog() {
    dialog --infobox "Fetching changelog from GitHub...\n\nPlease wait..." 6 50

    local changelog_url="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/CHANGELOG.md"
    local temp_file="/tmp/zoolandia_online_changelog.md"

    # Fetch changelog
    if curl -fsSL "$changelog_url" -o "$temp_file" 2>/dev/null; then
        dialog --title "Community Scripts Changelog" \
            --textbox "$temp_file" 24 80
        rm -f "$temp_file"
    else
        dialog --msgbox "Error: Failed to fetch changelog from GitHub.\n\nPlease check your internet connection.\n\nURL: $changelog_url" 12 70
    fi
}

# View API data
view_api_data() {
    dialog --infobox "Fetching API data...\n\nPlease wait..." 6 50

    local api_url="https://community-scripts.github.io/ProxmoxVE/data"
    local temp_file="/tmp/zoolandia_api_data.txt"

    # Fetch API data
    if curl -fsSL "$api_url" -o "$temp_file" 2>/dev/null; then
        # Check if it's HTML and extract useful information
        if grep -q "<html" "$temp_file"; then
            # It's HTML, let's extract text content
            local text_file="/tmp/zoolandia_api_data_text.txt"

            # Use lynx if available, otherwise sed
            if command -v lynx &>/dev/null; then
                lynx -dump -nolist "$temp_file" > "$text_file"
                dialog --title "Community Scripts API Data" \
                    --textbox "$text_file" 24 80
                rm -f "$text_file"
            elif command -v w3m &>/dev/null; then
                w3m -dump "$temp_file" > "$text_file"
                dialog --title "Community Scripts API Data" \
                    --textbox "$text_file" 24 80
                rm -f "$text_file"
            else
                # Fallback: Show HTML with basic formatting
                dialog --title "Community Scripts API Data" \
                    --textbox "$temp_file" 24 80
            fi
        else
            # It's plain text or JSON
            dialog --title "Community Scripts API Data" \
                --textbox "$temp_file" 24 80
        fi
        rm -f "$temp_file"
    else
        dialog --msgbox "Error: Failed to fetch API data.\n\nPlease check your internet connection.\n\nURL: $api_url" 12 70
    fi
}
