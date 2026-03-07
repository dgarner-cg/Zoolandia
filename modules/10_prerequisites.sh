#!/bin/bash
################################################################################
# Zoolandia v5.10 - Prerequisites Module
#
# Description: Prerequisites menu and system setup functions including package
#              installation, Docker setup, and system validation checks
################################################################################

show_prerequisites_menu() {
    while true; do
        # Get current status for each item with color codes

        # Disclaimer status - check if acknowledged
        if [[ -f "$ZOOLANDIA_CONFIG_DIR/disclaimer_acknowledged" ]]; then
            local disclaimer_status="\Z2DONE\Zn"
        else
            local disclaimer_status="\Z1NOT DONE\Zn"
        fi

        # Docker status - check if docker and docker compose are installed
        if command -v docker &>/dev/null; then
            local docker_status="\Z2DONE\Zn"
        else
            local docker_status="\Z1NOT DONE\Zn"
        fi

        # Username status
        if [[ -n "$CURRENT_USER" ]]; then
            local username_status="\Z2DONE\Zn"
        else
            local username_status="\Z1NOT DONE\Zn"
        fi

        # System Type status
        if [[ -n "$SYSTEM_TYPE" ]]; then
            local system_type_status="\Z2DONE\Zn"
        else
            local system_type_status="\Z1NOT DONE\Zn"
        fi

        # Setup Mode status
        if [[ -n "$SETUP_MODE" ]]; then
            local setup_mode_status="\Z2DONE\Zn"
        else
            local setup_mode_status="\Z1NOT DONE\Zn"
        fi

        # Docker folder status
        if [[ -n "$DOCKER_DIR" && "$DOCKER_DIR" != "/root/docker" && "$DOCKER_DIR" != "/home/*/docker" ]]; then
            local docker_folder_status="\Z2DONE\Zn"
        else
            local docker_folder_status="\Z1NOT DONE\Zn"
        fi

        # Backups folder status
        if [[ -n "$BACKUP_DIR" ]]; then
            local backups_folder_status="\Z2DONE\Zn"
        else
            local backups_folder_status="\Z1NOT DONE\Zn"
        fi

        # Environment status
        if [[ -f "$DOCKER_DIR/.env" && -d "$DOCKER_DIR/appdata" && -d "$DOCKER_DIR/compose" ]]; then
            local env_status="\Z2DONE\Zn"
        else
            local env_status="\Z1NOT DONE\Zn"
        fi

        # Server IP status
        if [[ -n "$SERVER_IP" ]]; then
            local server_ip_status="\Z2DONE\Zn"
        else
            # Try to auto-detect
            local auto_ip=$(hostname -I 2>/dev/null | awk '{print $1}' | xargs)
            if [[ -n "$auto_ip" ]]; then
                SERVER_IP="$auto_ip"
                local server_ip_status="\Z2DONE\Zn"
            else
                local server_ip_status="\Z1NOT DONE\Zn"
            fi
        fi

        # Domain status
        if [[ -n "$DOMAIN_1" ]]; then
            local domain_status="\Z2DONE\Zn"
        else
            local domain_status="\Z3NOT REQUIRED\Zn"
        fi

        # System Checks status
        if [[ $PREREQUISITES_DONE == true ]]; then
            local sys_checks_status="\Z2DONE\Zn"
        else
            local sys_checks_status="\Z1NOT DONE\Zn"
        fi

        # GitHub Username status
        if [[ -n "$GITHUB_USERNAME" ]]; then
            local github_status="\Z2$GITHUB_USERNAME\Zn"
        else
            local github_status="\Z3NOT SET\Zn"
        fi

        local menu_items=(
            "Disclaimer" "Read and Acknowledge - $disclaimer_status"
            "Username" "Primary Username - $username_status"
            "System Type" "Pick your System Type - $system_type_status"
            "Setup Mode" "Toggle how Apps are setup - $setup_mode_status"
            "Docker Folder" "Set Docker Root Folder - $docker_folder_status"
            "Backups Folder" "Set Backups Folder - $backups_folder_status"
            "Environment" "Setup Docker Environment - $env_status"
            "Server IP" "Set Server IP Address - $server_ip_status"
            "Domain 1" "Primary Domain Name - $domain_status"
            "GitHub Username" "For VS Code Tunnel, etc. - $github_status"
            "System Checks" "System and Docker Checks - $sys_checks_status"
            "Domain Checks" "IP and Domain Checks - \Z3NOT REQUIRED\Zn"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME by hack3r.gg - v$ZOOLANDIA_VERSION" \
            --title "Prerequisites" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --colors \
            --menu "Select an option..." 22 70 12 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return 1

        case "$choice" in
            "Disclaimer") show_disclaimer ;;
            "Username") set_username ;;
            "System Type") show_system_type ;;
            "Setup Mode") toggle_setup_mode ;;
            "Docker Folder") set_docker_folder ;;
            "Backups Folder") set_backups_folder ;;
            "Environment") configure_environment ;;
            "Server IP") set_server_ip ;;
            "Domain 1") set_domain ;;
            "GitHub Username") set_github_username ;;
            "System Checks") run_system_checks ;;
            "Domain Checks") run_domain_checks ;;
            "Back") return ;;
        esac
    done
}

show_packages_menu() {
    while true; do
        # Check status for each tier using dpkg-query

        # Required packages check
        local required_status="\Z2PRE-INSTALLED\Zn"
        if ! command -v dialog &>/dev/null || ! command -v curl &>/dev/null || ! command -v git &>/dev/null || ! command -v jq &>/dev/null; then
            required_status="\Z1MISSING\Zn"
        fi

        # Recommended packages check (count installed)
        local rec_pkgs=("htop" "net-tools" "dnsutils" "openssl" "ca-certificates" "gnupg" "lsb-release" "rsync" "unzip" "smartmontools" "netcat-traditional")
        local rec_count=0
        for pkg in "${rec_pkgs[@]}"; do
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                ((rec_count++))
            fi
        done
        local recommended_status="\Z1$rec_count/11 INSTALLED\Zn"
        if [ $rec_count -eq 11 ]; then
            recommended_status="\Z2ALL INSTALLED\Zn"
        elif [ $rec_count -gt 0 ]; then
            recommended_status="\Z3$rec_count/11 INSTALLED\Zn"
        fi

        # Enhanced packages check (dev + security + filesystems + build tools)
        local enh_pkgs=("libssl-dev" "libffi-dev" "python3-dev" "python3-pip" "python3-venv" "apt-transport-https" "apache2-utils" "acl" "pwgen" "argon2" "libnss-resolve" "exfat-fuse" "exfatprogs" "ntfs-3g" "build-essential" "cmake")
        local enh_count=0
        for pkg in "${enh_pkgs[@]}"; do
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                ((enh_count++))
            fi
        done
        local enhanced_status="\Z1$enh_count/16 INSTALLED\Zn"
        if [ $enh_count -eq 16 ]; then
            enhanced_status="\Z2ALL INSTALLED\Zn"
        elif [ $enh_count -gt 0 ]; then
            enhanced_status="\Z3$enh_count/16 INSTALLED\Zn"
        fi

        # Advanced packages check (desktop enhancements)
        local adv_pkgs=("neofetch" "gnome-tweaks" "gnome-shell-extensions" "gnome-extensions-app" "gparted")
        local adv_count=0
        for pkg in "${adv_pkgs[@]}"; do
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                ((adv_count++))
            fi
        done
        local advanced_status="\Z1$adv_count/5 INSTALLED\Zn"
        if [ $adv_count -eq 5 ]; then
            advanced_status="\Z2ALL INSTALLED\Zn"
        elif [ $adv_count -gt 0 ]; then
            advanced_status="\Z3$adv_count/5 INSTALLED\Zn"
        fi

        # Security packages check
        local sec_pkgs=("yubikey-manager")
        local sec_count=0
        for pkg in "${sec_pkgs[@]}"; do
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                ((sec_count++))
            fi
        done
        local security_status="\Z1$sec_count/1 INSTALLED\Zn"
        if [ $sec_count -eq 1 ]; then
            security_status="\Z2ALL INSTALLED\Zn"
        fi

        # Power packages check
        local power_pkgs=("vlc")
        local power_count=0
        for pkg in "${power_pkgs[@]}"; do
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                ((power_count++))
            fi
        done
        local power_status="\Z1$power_count/1 INSTALLED\Zn"
        if [ $power_count -eq 1 ]; then
            power_status="\Z2ALL INSTALLED\Zn"
        fi

        # Optional packages check
        local opt_pkgs=("nano" "zip" "html2text")
        local opt_count=0
        for pkg in "${opt_pkgs[@]}"; do
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
                ((opt_count++))
            fi
        done
        local optional_status="\Z1$opt_count/3 INSTALLED\Zn"
        if [ $opt_count -eq 3 ]; then
            optional_status="\Z2ALL INSTALLED\Zn"
        elif [ $opt_count -gt 0 ]; then
            optional_status="\Z3$opt_count/3 INSTALLED\Zn"
        fi

        # Check Docker status
        local docker_pkg_status="\Z1NOT INSTALLED\Zn"
        if command -v docker &>/dev/null; then
            docker_pkg_status="\Z2INSTALLED\Zn"
        fi

        # Check Terraform status
        local terraform_status="\Z1NOT INSTALLED\Zn"
        if command -v terraform &>/dev/null; then
            terraform_status="\Z2INSTALLED\Zn"
        fi

        # Check Ansible status
        local ansible_status="\Z1NOT INSTALLED\Zn"
        if command -v ansible-playbook &>/dev/null; then
            ansible_status="\Z2INSTALLED\Zn"
        fi

        # Check Flatpak status
        local flatpak_status="\Z1NOT INSTALLED\Zn"
        if command -v flatpak &>/dev/null; then
            flatpak_status="\Z2INSTALLED\Zn"
        fi

        local menu_items=(
            "Required" "Pre-installed essentials - $required_status"
            "Recommended" "Server utilities and networking tools - $recommended_status"
            "Enhanced" "Dev tools, security, and system libs - $enhanced_status"
            "Advanced" "Desktop enhancements and system info - $advanced_status"
            "Security" "Hardware security and authentication - $security_status"
            "Power" "Power user applications - $power_status"
            "Optional" "Basic utilities and converters - $optional_status"
            "All Packages" "Install all installable tiers at once"
            "" ""
            "Install Ansible" "Install Ansible automation engine - $ansible_status"
            "Install Docker" "Install Docker & Docker Compose - $docker_pkg_status"
            "Install Terraform" "Install Terraform IaC tool - $terraform_status"
            "Install Flatpak" "Install Flatpak package manager - $flatpak_status"
            "" ""
            "Info" "View detailed package information"
            "Back" "Return to prerequisites menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME by hack3r.gg - v$ZOOLANDIA_VERSION" \
            --title "Software Packages" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --colors \
            --menu "Select package tier to install:" 24 70 12 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Required") view_required_packages ;;
            "Recommended") install_recommended_packages ;;
            "Enhanced") install_enhanced_packages ;;
            "Advanced") install_advanced_packages ;;
            "Security") install_security_packages ;;
            "Power") install_power_packages ;;
            "Optional") install_optional_packages ;;
            "All Packages") install_all_packages ;;
            "Install Ansible") install_ansible ;;
            "Install Docker") install_docker ;;
            "Install Terraform") install_terraform ;;
            "Install Flatpak") install_flatpak ;;
            "Info") show_packages_info ;;
            "Back") return ;;
            "") continue ;;
        esac
    done
}

show_packages_info() {
    local info_text="ZOOLANDIA PACKAGE TIERS\n\n"
    info_text+="=== REQUIRED (Pre-installed) ===\n"
    info_text+="These are installed before Zoolandia runs:\n"
    info_text+="• dialog - Interactive menus\n"
    info_text+="• curl, wget - Download utilities\n"
    info_text+="• git - Version control\n"
    info_text+="• jq - JSON processor\n\n"

    info_text+="=== RECOMMENDED ===\n"
    info_text+="Server utilities and networking tools:\n"
    info_text+="• htop - Process monitor\n"
    info_text+="• net-tools - Network utilities (ifconfig, netstat)\n"
    info_text+="• dnsutils - DNS troubleshooting (dig, nslookup)\n"
    info_text+="• openssl - Encryption and SSL tools\n"
    info_text+="• ca-certificates - SSL/TLS certificate support\n"
    info_text+="• gnupg - Package verification and encryption\n"
    info_text+="• lsb-release - OS detection and info\n"
    info_text+="• rsync - File synchronization\n"
    info_text+="• unzip - Archive extraction\n"
    info_text+="• smartmontools - Disk monitoring and SMART analysis\n"
    info_text+="• netcat-traditional - Network testing and debugging\n\n"

    info_text+="=== ENHANCED ===\n"
    info_text+="Development tools, security utilities, and system libraries:\n"
    info_text+="Development:\n"
    info_text+="• libssl-dev - OpenSSL development libraries\n"
    info_text+="• libffi-dev - FFI development libraries\n"
    info_text+="• python3-dev - Python development headers\n"
    info_text+="• python3-pip - Python package installer\n"
    info_text+="• python3-venv - Python virtual environments\n"
    info_text+="• apt-transport-https - HTTPS transport for APT\n"
    info_text+="Build Tools:\n"
    info_text+="• build-essential - Compiler and build tools (gcc, g++, make)\n"
    info_text+="• cmake - Cross-platform build system generator\n"
    info_text+="Security & Admin:\n"
    info_text+="• apache2-utils - Web utilities (htpasswd)\n"
    info_text+="• acl - Advanced file permissions\n"
    info_text+="• pwgen - Password generator\n"
    info_text+="• argon2 - Password hashing\n"
    info_text+="System Libraries & Filesystems:\n"
    info_text+="• libnss-resolve - Name resolution library\n"
    info_text+="• exfat-fuse - exFAT filesystem support\n"
    info_text+="• exfatprogs - exFAT filesystem utilities\n"
    info_text+="• ntfs-3g - NTFS filesystem support\n\n"

    info_text+="=== ADVANCED ===\n"
    info_text+="Desktop enhancements and system info:\n"
    info_text+="• neofetch - System information display\n"
    info_text+="• gnome-tweaks - GNOME desktop customization\n"
    info_text+="• gnome-shell-extensions - GNOME Shell extensions\n"
    info_text+="• gnome-extensions-app - Extensions management app\n"
    info_text+="• gparted - Disk partitioning tool (GUI)\n\n"

    info_text+="=== SECURITY ===\n"
    info_text+="Hardware security and authentication tools:\n"
    info_text+="• yubikey-manager - YubiKey management and configuration\n\n"

    info_text+="=== POWER ===\n"
    info_text+="Power user applications and media tools:\n"
    info_text+="• vlc - VLC media player\n\n"

    info_text+="=== OPTIONAL ===\n"
    info_text+="Basic utilities and converters:\n"
    info_text+="• nano - Text editor\n"
    info_text+="• zip - Archive creation\n"
    info_text+="• html2text - HTML to text conversion\n\n"

    info_text+="=== ALL PACKAGES ===\n"
    info_text+="Installs all installable tiers in one operation.\n"
    info_text+="(Excludes Required - already pre-installed)"

    dialog --title "Package Information" \
        --msgbox "$info_text" 56 75
}

view_required_packages() {
    local msg="REQUIRED PACKAGES (Pre-installed)\n\n"
    msg+="These packages are installed before Zoolandia runs and are required for basic functionality.\n\n"
    msg+="Pre-installed packages:\n"
    msg+="• dialog - Interactive menus\n"
    msg+="• curl, wget - Download utilities\n"
    msg+="• git - Version control\n"
    msg+="• jq - JSON processor\n\n"

    # Check status of each
    local status_msg="Current Status:\n"
    if command -v dialog &>/dev/null; then
        status_msg+="✓ dialog - Installed\n"
    else
        status_msg+="✗ dialog - Missing\n"
    fi

    if command -v curl &>/dev/null; then
        status_msg+="✓ curl - Installed\n"
    else
        status_msg+="✗ curl - Missing\n"
    fi

    if command -v wget &>/dev/null; then
        status_msg+="✓ wget - Installed\n"
    else
        status_msg+="✗ wget - Missing\n"
    fi

    if command -v git &>/dev/null; then
        status_msg+="✓ git - Installed\n"
    else
        status_msg+="✗ git - Missing\n"
    fi

    if command -v jq &>/dev/null; then
        status_msg+="✓ jq - Installed\n"
    else
        status_msg+="✗ jq - Missing\n"
    fi

    dialog --title "Required Packages (View Only)" \
        --msgbox "$msg$status_msg\n\nNote: These packages should already be installed.\nNo installation option available." 24 70
}

install_recommended_packages() {
    local msg="RECOMMENDED PACKAGES\n\n"
    msg+="This tier includes server utilities and networking tools.\n\n"

    # Package arrays
    local packages=("htop" "net-tools" "dnsutils" "openssl" "ca-certificates" "gnupg" "lsb-release" "rsync" "unzip" "smartmontools" "netcat-traditional")
    local descriptions=("Process monitor" "Network utilities (ifconfig, netstat)" "DNS troubleshooting (dig, nslookup)" "Encryption and SSL tools" "SSL/TLS certificate support" "Package verification and encryption" "OS detection and info" "File synchronization" "Archive extraction" "Disk monitoring and SMART analysis" "Network testing and debugging")

    # Build installed and missing lists
    local installed_list=""
    local missing_list=""
    local installed_count=0
    local total_count=${#packages[@]}

    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        local desc="${descriptions[$i]}"

        # Check if package is installed using dpkg-query (more reliable)
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="  ✓ $pkg - $desc\n"
            ((installed_count++))
        else
            missing_list+="  ○ $pkg - $desc\n"
        fi
    done

    msg+="Status: $installed_count of $total_count packages installed\n\n"

    # Show installed packages if any
    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed:\n"
        msg+="$installed_list"
        msg+="\n"
    fi

    # Show missing packages if any
    if [ $installed_count -lt $total_count ]; then
        msg+="Not Installed:\n"
        msg+="$missing_list"
        msg+="\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "Recommended Packages" --msgbox "$msg" 20 75
        return
    fi

    msg+="Install missing packages now?"

    if ! dialog --title "Install Recommended Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 24 75; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing recommended packages...\n\nPlease wait, this may take a few minutes." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            htop \
            net-tools \
            dnsutils \
            openssl \
            ca-certificates \
            gnupg \
            lsb-release \
            rsync \
            unzip \
            smartmontools \
            netcat-traditional 2>&1
    } | dialog --programbox "Installing Recommended Packages..." 20 80

    dialog --msgbox "Recommended packages installed successfully!\n\nServer utilities and networking tools are now available." 10 70
}

install_enhanced_packages() {
    local msg="ENHANCED PACKAGES\n\n"
    msg+="This tier includes development tools, build tools, security utilities, and system libraries.\n\n"

    # Package arrays - development (6) + build (2) + security (4) + system libs & filesystems (4) = 16 total
    local packages=("libssl-dev" "libffi-dev" "python3-dev" "python3-pip" "python3-venv" "apt-transport-https" "build-essential" "cmake" "apache2-utils" "acl" "pwgen" "argon2" "libnss-resolve" "exfat-fuse" "exfatprogs" "ntfs-3g")
    local descriptions=("OpenSSL development libraries" "FFI development libraries" "Python development headers" "Python package installer" "Python virtual environments" "HTTPS transport for APT" "Compiler and build tools" "Cross-platform build system" "Web server utilities (htpasswd)" "Advanced file permissions (ACLs)" "Secure password generator" "Password hashing utility" "Name resolution library" "exFAT filesystem support" "exFAT filesystem utilities" "NTFS filesystem support")

    # Build installed and missing lists
    local installed_list=""
    local missing_list=""
    local installed_count=0
    local total_count=${#packages[@]}

    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        local desc="${descriptions[$i]}"

        # Check if package is installed using dpkg-query (more reliable)
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="  ✓ $pkg - $desc\n"
            ((installed_count++))
        else
            missing_list+="  ○ $pkg - $desc\n"
        fi
    done

    msg+="Status: $installed_count of $total_count packages installed\n\n"

    # Show installed packages if any
    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed:\n"
        msg+="$installed_list"
        msg+="\n"
    fi

    # Show missing packages if any
    if [ $installed_count -lt $total_count ]; then
        msg+="Not Installed:\n"
        msg+="$missing_list"
        msg+="\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "Enhanced Packages" --msgbox "$msg" 32 75
        return
    fi

    msg+="Install missing packages now?"

    if ! dialog --title "Install Enhanced Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 34 75; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing enhanced packages...\n\nPlease wait, this may take a few minutes." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            libssl-dev \
            libffi-dev \
            python3-dev \
            python3-pip \
            python3-venv \
            apt-transport-https \
            build-essential \
            cmake \
            apache2-utils \
            acl \
            pwgen \
            argon2 \
            libnss-resolve \
            exfat-fuse \
            exfatprogs \
            ntfs-3g 2>&1
    } | dialog --programbox "Installing Enhanced Packages..." 20 80

    dialog --msgbox "Enhanced packages installed successfully!\n\nDevelopment tools, build tools, security utilities, filesystems, and system libraries are now available." 10 78
}

install_security_packages() {
    local msg="SECURITY PACKAGES\n\n"
    msg+="This tier includes hardware security and authentication tools.\n\n"

    # Package arrays
    local packages=("yubikey-manager")
    local descriptions=("YubiKey management tool")

    # Build installed and missing lists
    local installed_list=""
    local missing_list=""
    local installed_count=0
    local total_count=${#packages[@]}

    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        local desc="${descriptions[$i]}"

        # Check if package is installed using dpkg-query (more reliable)
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="  ✓ $pkg - $desc\n"
            ((installed_count++))
        else
            missing_list+="  ○ $pkg - $desc\n"
        fi
    done

    msg+="Status: $installed_count of $total_count package installed\n\n"

    # Show installed packages if any
    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed:\n"
        msg+="$installed_list"
        msg+="\n"
    fi

    # Show missing packages if any
    if [ $installed_count -lt $total_count ]; then
        msg+="Not Installed:\n"
        msg+="$missing_list"
        msg+="\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "Security Packages" --msgbox "$msg" 18 75
        return
    fi

    msg+="Install missing packages now?"

    if ! dialog --title "Install Security Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 18 75; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing security packages...\n\nPlease wait, this may take a few minutes." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            yubikey-manager 2>&1
    } | dialog --programbox "Installing Security Packages..." 20 80

    dialog --msgbox "Security packages installed successfully!\n\nHardware security and authentication tools are now available." 10 75
}

install_power_packages() {
    local msg="POWER PACKAGES\n\n"
    msg+="This tier includes power user applications and media tools.\n\n"

    # Package arrays
    local packages=("vlc")
    local descriptions=("VLC media player")

    # Build installed and missing lists
    local installed_list=""
    local missing_list=""
    local installed_count=0
    local total_count=${#packages[@]}

    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        local desc="${descriptions[$i]}"

        # Check if package is installed using dpkg-query (more reliable)
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="  ✓ $pkg - $desc\n"
            ((installed_count++))
        else
            missing_list+="  ○ $pkg - $desc\n"
        fi
    done

    msg+="Status: $installed_count of $total_count package installed\n\n"

    # Show installed packages if any
    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed:\n"
        msg+="$installed_list"
        msg+="\n"
    fi

    # Show missing packages if any
    if [ $installed_count -lt $total_count ]; then
        msg+="Not Installed:\n"
        msg+="$missing_list"
        msg+="\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "Power Packages" --msgbox "$msg" 18 75
        return
    fi

    msg+="Install missing packages now?"

    if ! dialog --title "Install Power Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 18 75; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing power packages...\n\nPlease wait, this may take a few minutes." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            vlc 2>&1
    } | dialog --programbox "Installing Power Packages..." 20 80

    dialog --msgbox "Power packages installed successfully!\n\nPower user applications and media tools are now available." 10 75
}

install_optional_packages() {
    local msg="OPTIONAL PACKAGES\n\n"
    msg+="This tier includes basic utilities and converters.\n\n"

    # Package arrays
    local packages=("nano" "zip" "html2text")
    local descriptions=("Simple text editor" "Archive creation utility" "HTML to plain text converter")

    # Build installed and missing lists
    local installed_list=""
    local missing_list=""
    local installed_count=0
    local total_count=${#packages[@]}

    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        local desc="${descriptions[$i]}"

        # Check if package is installed using dpkg-query (more reliable)
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="  ✓ $pkg - $desc\n"
            ((installed_count++))
        else
            missing_list+="  ○ $pkg - $desc\n"
        fi
    done

    msg+="Status: $installed_count of $total_count packages installed\n\n"

    # Show installed packages if any
    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed:\n"
        msg+="$installed_list"
        msg+="\n"
    fi

    # Show missing packages if any
    if [ $installed_count -lt $total_count ]; then
        msg+="Not Installed:\n"
        msg+="$missing_list"
        msg+="\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "Optional Packages" --msgbox "$msg" 18 75
        return
    fi

    msg+="Install missing packages now?"

    if ! dialog --title "Install Optional Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 18 75; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing optional packages...\n\nPlease wait, this may take a few minutes." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            nano \
            zip \
            html2text 2>&1
    } | dialog --programbox "Installing Optional Packages..." 20 80

    dialog --msgbox "Optional packages installed successfully!\n\nBasic utilities and converters are now available." 10 70
}

install_advanced_packages() {
    local msg="ADVANCED PACKAGES\n\n"
    msg+="This tier includes desktop enhancements and system information tools.\n\n"

    # Package arrays
    local packages=("neofetch" "gnome-tweaks" "gnome-shell-extensions" "gnome-extensions-app" "gparted")
    local descriptions=("System information display" "GNOME desktop customization" "GNOME Shell extensions" "Extensions management app" "Disk partitioning tool")

    # Build installed and missing lists
    local installed_list=""
    local missing_list=""
    local installed_count=0
    local total_count=${#packages[@]}

    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        local desc="${descriptions[$i]}"

        # Check if package is installed using dpkg-query (more reliable)
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="  ✓ $pkg - $desc\n"
            ((installed_count++))
        else
            missing_list+="  ○ $pkg - $desc\n"
        fi
    done

    msg+="Status: $installed_count of $total_count packages installed\n\n"

    # Show installed packages if any
    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed:\n"
        msg+="$installed_list"
        msg+="\n"
    fi

    # Show missing packages if any
    if [ $installed_count -lt $total_count ]; then
        msg+="Not Installed:\n"
        msg+="$missing_list"
        msg+="\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "Advanced Packages" --msgbox "$msg" 22 75
        return
    fi

    msg+="Install missing packages now?"

    if ! dialog --title "Install Advanced Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 24 75; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing advanced packages...\n\nPlease wait, this may take a few minutes." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            neofetch \
            gnome-tweaks \
            gnome-shell-extensions \
            gnome-extensions-app \
            gparted 2>&1
    } | dialog --programbox "Installing Advanced Packages..." 20 80

    dialog --msgbox "Advanced packages installed successfully!\n\nDesktop enhancements, disk tools, and system info are now available." 10 75
}

install_all_packages() {
    local msg="INSTALL ALL PACKAGES\n\n"

    # All packages across all tiers
    local all_packages=("htop" "net-tools" "dnsutils" "openssl" "ca-certificates" "gnupg" "lsb-release" "rsync" "unzip" "smartmontools" "netcat-traditional" "libssl-dev" "libffi-dev" "python3-dev" "python3-pip" "python3-venv" "apt-transport-https" "build-essential" "cmake" "apache2-utils" "acl" "pwgen" "argon2" "libnss-resolve" "exfat-fuse" "exfatprogs" "ntfs-3g" "neofetch" "gnome-tweaks" "gnome-shell-extensions" "gnome-extensions-app" "gparted" "yubikey-manager" "nano" "zip" "html2text" "vlc")

    # Count installed packages using dpkg-query
    local installed_count=0
    local total_count=${#all_packages[@]}
    local installed_list=""
    local missing_list=""

    for pkg in "${all_packages[@]}"; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_list+="$pkg "
            ((installed_count++))
        else
            missing_list+="$pkg "
        fi
    done

    msg+="Status: $installed_count of $total_count packages installed\n\n"

    if [ $installed_count -gt 0 ]; then
        msg+="Currently Installed ($installed_count packages):\n"
        msg+="$installed_list\n\n"
    fi

    if [ $installed_count -eq $total_count ]; then
        msg+="All packages are already installed!\n"
        dialog --title "All Packages" --msgbox "$msg" 20 78
        return
    fi

    if [ $installed_count -lt $total_count ]; then
        local missing_count=$((total_count - installed_count))
        msg+="Missing ($missing_count packages):\n"
        msg+="$missing_list\n\n"
    fi

    msg+="This will install all missing packages from:\n\n"
    msg+="• Recommended (11 packages)\n"
    msg+="  - htop, net-tools, dnsutils, openssl, ca-certificates,\n"
    msg+="    gnupg, lsb-release, rsync, unzip, smartmontools,\n"
    msg+="    netcat-traditional\n\n"
    msg+="• Enhanced (16 packages)\n"
    msg+="  - libssl-dev, libffi-dev, python3-dev, python3-pip,\n"
    msg+="    python3-venv, apt-transport-https, build-essential,\n"
    msg+="    cmake, apache2-utils, acl, pwgen, argon2, libnss-resolve,\n"
    msg+="    exfat-fuse, exfatprogs, ntfs-3g\n\n"
    msg+="• Advanced (5 packages)\n"
    msg+="  - neofetch, gnome-tweaks, gnome-shell-extensions,\n"
    msg+="    gnome-extensions-app, gparted\n\n"
    msg+="• Security (1 package)\n"
    msg+="  - yubikey-manager\n\n"
    msg+="• Power (1 package)\n"
    msg+="  - vlc\n\n"
    msg+="• Optional (3 packages)\n"
    msg+="  - nano, zip, html2text\n\n"
    msg+="Total: 37 packages\n"
    msg+="Note: Required packages are already pre-installed.\n\n"
    msg+="This is recommended for first-time setup.\n\n"
    msg+="Install all packages now?"

    if ! dialog --title "Install All Packages" \
        --yes-label "Install" \
        --no-label "Cancel" \
        --yesno "$msg" 42 80; then
        return
    fi

    # Show installation progress
    dialog --infobox "Installing all packages...\n\nThis may take several minutes.\nPlease wait..." 8 60

    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            htop \
            net-tools \
            dnsutils \
            openssl \
            ca-certificates \
            gnupg \
            lsb-release \
            rsync \
            unzip \
            smartmontools \
            netcat-traditional \
            libssl-dev \
            libffi-dev \
            python3-dev \
            python3-pip \
            python3-venv \
            apt-transport-https \
            build-essential \
            cmake \
            apache2-utils \
            acl \
            pwgen \
            argon2 \
            libnss-resolve \
            exfat-fuse \
            exfatprogs \
            ntfs-3g \
            neofetch \
            gnome-tweaks \
            gnome-shell-extensions \
            gnome-extensions-app \
            gparted \
            yubikey-manager \
            nano \
            zip \
            html2text \
            vlc 2>&1
    } | dialog --programbox "Installing All Packages..." 20 80

    # Check internet connectivity
    local connectivity_msg=""
    if ping -c 1 8.8.8.8 &>/dev/null || ping -c 1 1.1.1.1 &>/dev/null; then
        connectivity_msg="Internet connectivity verified."
    else
        connectivity_msg="WARNING: Internet connectivity check failed.\nPlease verify your connection."
    fi

    dialog --msgbox "All packages installed successfully!\n\n$connectivity_msg\n\nAll installable package tiers are now available." 12 60
}

run_system_checks() {
    dialog --infobox "Running system checks..." 5 50
    sleep 1

    local checks_passed=true
    local check_results=""

    # Check OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        check_results+="OS: $PRETTY_NAME\n"
    else
        check_results+="OS: Unknown\n"
        checks_passed=false
    fi

    # Check internet connectivity
    if ping -c 1 1.1.1.1 &> /dev/null; then
        check_results+="Internet: Connected\n"
    else
        check_results+="Internet: Not Connected\n"
        checks_passed=false
    fi

    # Check ports 80 and 443
    if ! ss -tuln | grep -q ":80 "; then
        check_results+="Port 80: Available\n"
    else
        check_results+="Port 80: In Use\n"
        checks_passed=false
    fi

    if ! ss -tuln | grep -q ":443 "; then
        check_results+="Port 443: Available\n"
    else
        check_results+="Port 443: In Use\n"
        checks_passed=false
    fi

    if [[ $checks_passed == true ]]; then
        touch "$ZOOLANDIA_CONFIG_DIR/prerequisites_done"
        PREREQUISITES_DONE=true
        dialog --msgbox "System Checks Passed!\n\n$check_results" 15 60
    else
        dialog --msgbox "System Checks Failed!\n\n$check_results\n\nPlease resolve the issues before continuing." 15 60
    fi
}

install_docker() {
    if command -v docker &> /dev/null; then
        dialog --msgbox "Docker is already installed.\n\nVersion: $(docker --version)" 10 60
        return
    fi

    dialog --infobox "Installing Docker..." 5 50

    # Install Docker using official script
    curl -fsSL https://get.docker.com | sudo sh
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add user to docker group
    sudo usermod -aG docker "$CURRENT_USER"

    # Install Docker Compose
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    touch "$ZOOLANDIA_CONFIG_DIR/docker_setup_done"
    DOCKER_SETUP_DONE=true

    dialog --msgbox "Docker installed successfully!\n\nVersion: $(docker --version)\nDocker Compose: $(docker compose version)" 12 60
}

install_ansible() {
    # Check if Ansible is already installed
    if command -v ansible-playbook &>/dev/null; then
        local ansible_version=$(ansible --version | head -n1)
        dialog --msgbox "Ansible is already installed!\n\n$ansible_version\n\nNo action needed." 12 60
        return 0
    fi

    # Confirm installation
    if ! dialog --yesno "Install Ansible and required packages?\n\nThis will install:\n- ansible (automation engine)\n- python3 (required runtime)\n- python3-pip (package manager)\n- sshpass (SSH password support)\n- software-properties-common (PPA support)\n\nContinue?" 16 70; then
        dialog --msgbox "Installation cancelled." 8 50
        return 1
    fi

    # Show installation progress
    dialog --infobox "Installing Ansible and dependencies...\n\nThis may take a few minutes." 8 60
    sleep 2

    # Update package list and install
    {
        sudo apt-get update 2>&1
        sudo apt-get install -y \
            ansible \
            python3 \
            python3-pip \
            sshpass \
            software-properties-common 2>&1
    } | dialog --programbox "Installing Ansible..." 20 80

    # Verify installation
    if command -v ansible-playbook &>/dev/null; then
        local ansible_version=$(ansible --version | head -n1)
        dialog --msgbox "Ansible installed successfully!\n\n$ansible_version\n\nYou can now use Ansible playbooks from the Ansible menu." 12 60
        return 0
    else
        dialog --msgbox "Error: Ansible installation failed!\n\nPlease check your internet connection and try again.\n\nYou can also install manually:\nsudo apt install ansible" 12 60
        return 1
    fi
}

install_flatpak() {
    # Check if Flatpak is already installed
    if command -v flatpak &>/dev/null; then
        local flatpak_version=$(flatpak --version)
        dialog --msgbox "Flatpak is already installed!\n\n$flatpak_version\n\nNo action needed." 12 60
        return 0
    fi

    # Confirm installation
    if ! dialog --yesno "Install Flatpak and add Flathub repository?\n\nThis will:\n- Install flatpak package manager\n- Add Flathub remote repository\n- Enable system-wide Flatpak applications\n\nContinue?" 14 70; then
        dialog --msgbox "Installation cancelled." 8 50
        return 1
    fi

    # Show installation progress
    dialog --infobox "Installing Flatpak...\n\nThis may take a few minutes." 8 60
    sleep 2

    # Install Flatpak
    {
        sudo apt-get update 2>&1
        sudo apt-get install -y flatpak 2>&1
    } | dialog --programbox "Installing Flatpak..." 20 80

    # Verify installation
    if ! command -v flatpak &>/dev/null; then
        dialog --msgbox "Error: Flatpak installation failed!\n\nPlease check your internet connection and try again.\n\nYou can also install manually:\nsudo apt install flatpak" 12 60
        return 1
    fi

    # Show Flatpak version and remotes
    local flatpak_version=$(flatpak --version)
    local flatpak_remotes=$(flatpak remotes --show-details 2>&1 || echo "No remotes configured yet")

    # Add Flathub remote
    dialog --infobox "Adding Flathub remote repository...\n\nPlease wait..." 8 60
    sleep 1

    {
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1
    } | dialog --programbox "Adding Flathub Remote..." 20 80

    # Get updated remotes list
    local updated_remotes=$(flatpak remotes --show-details 2>&1)

    dialog --msgbox "Flatpak installed successfully!\n\n$flatpak_version\n\nFlathub remote has been added.\n\nYou can now install Flatpak applications using:\nflatpak install flathub <app-name>" 16 70
    return 0
}

install_terraform() {
    # Check if Terraform is already installed
    if command -v terraform &>/dev/null; then
        local terraform_version=$(terraform version | head -n1)
        dialog --msgbox "Terraform is already installed!\n\n$terraform_version\n\nNo action needed." 12 60
        return 0
    fi

    # Confirm installation
    if ! dialog --yesno "Install Terraform?\n\nThis will:\n- Add HashiCorp GPG key\n- Add HashiCorp APT repository\n- Install terraform package\n\nContinue?" 14 70; then
        dialog --msgbox "Installation cancelled." 8 50
        return 1
    fi

    # Show installation progress
    dialog --infobox "Installing Terraform...\n\nThis may take a few minutes." 8 60
    sleep 2

    # Install Terraform using HashiCorp's official method
    {
        # Install prerequisites
        sudo apt-get update 2>&1
        sudo apt-get install -y gnupg software-properties-common curl 2>&1

        # Add HashiCorp GPG key
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>&1

        # Add HashiCorp repository
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list 2>&1

        # Install Terraform
        sudo apt-get update 2>&1
        sudo apt-get install -y terraform 2>&1
    } | dialog --programbox "Installing Terraform..." 20 80

    # Verify installation
    if command -v terraform &>/dev/null; then
        local terraform_version=$(terraform version | head -n1)
        dialog --msgbox "Terraform installed successfully!\n\n$terraform_version\n\nYou can now use Terraform for infrastructure as code." 12 60
        return 0
    else
        dialog --msgbox "Error: Terraform installation failed!\n\nPlease check your internet connection and try again.\n\nYou can also install manually from:\nhttps://developer.hashicorp.com/terraform/downloads" 12 70
        return 1
    fi
}

install_required_packages() {
    clear
    echo ""
    echo "############# Install Required Packages #############"
    echo ""
    echo "This step will install some packages required for Zoolandia, and for a well-functioning Docker server."
    echo ""
    echo -n "Press Y/y to continue or any other key to go back: "
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return
    fi

    echo ""
    echo "[INFO] Installing required packages..."

    sudo apt-get update
    sudo apt-get install -y \
        curl \
        wget \
        git \
        ansible \
        htop \
        net-tools \
        dnsutils \
        openssl \
        ca-certificates \
        gnupg \
        lsb-release \
        dialog \
        rsync \
        unzip \
        acl \
        software-properties-common \
        ufw \
        zip \
        nano \
        apache2-utils \
        apt-transport-https \
        argon2 \
        html2text \
        libnss-resolve \
        netcat-traditional \
        pwgen

    echo ""
    echo ""
    echo "Checking internet connectivity..."

    if ping -c 1 8.8.8.8 &>/dev/null || ping -c 1 1.1.1.1 &>/dev/null; then
        echo "[INFO] Internet connectivity verified."
    else
        echo "[WARN] Internet connectivity check failed. Please verify your connection."
    fi

    echo ""
    echo "Going back to the menu in 60 seconds. Or, press OK to go back now..."

    # Show dialog with 60 second timeout
    dialog --timeout 60 --msgbox "Package installation complete!\n\nInternet connectivity verified.\n\nReturning to menu..." 10 60
}

show_disclaimer() {
    dialog --title "Disclaimer" --msgbox "ZOOLANDIA DISCLAIMER\n\nThis software is provided 'as is' without warranty of any kind.\n\nBy using Zoolandia, you acknowledge that:\n- You are responsible for your server and data\n- Zoolandia automates Docker container deployment\n- You should review configurations before deploying\n- Backup your data regularly\n\nPress OK to acknowledge." 16 70

    # Mark disclaimer as acknowledged
    touch "$ZOOLANDIA_CONFIG_DIR/disclaimer_acknowledged"
}

set_github_username() {
    local current_value=""
    if [[ -n "$GITHUB_USERNAME" ]]; then
        current_value="$GITHUB_USERNAME"
    fi

    local new_username
    new_username=$(dialog --clear --backtitle "$SCRIPT_NAME by hack3r.gg - v$ZOOLANDIA_VERSION" \
        --title "GitHub Username" \
        --ok-label "Save" \
        --cancel-label "Cancel" \
        --inputbox "Enter your GitHub username.\n\nThis is used for:\n- VS Code Tunnel authentication\n- Git configuration\n- Other GitHub integrations\n\nCurrent: ${current_value:-Not set}" 16 60 "$current_value" \
        3>&1 1>&2 2>&3 3>&-)

    # Check if cancelled
    if [[ $? -ne 0 ]]; then
        return
    fi

    # Validate username (GitHub usernames: alphanumeric and hyphens, 1-39 chars)
    if [[ -n "$new_username" ]]; then
        if [[ ! "$new_username" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$ ]]; then
            dialog --msgbox "Invalid GitHub username format.\n\nGitHub usernames must:\n- Start with a letter or number\n- Contain only letters, numbers, or hyphens\n- Be 1-39 characters long\n- Not end with a hyphen" 14 60
            return
        fi

        # Save the username
        GITHUB_USERNAME="$new_username"
        mkdir -p "$ZOOLANDIA_CONFIG_DIR"
        echo "$GITHUB_USERNAME" > "$ZOOLANDIA_CONFIG_DIR/github_username"

        dialog --msgbox "GitHub username saved!\n\nUsername: $GITHUB_USERNAME\n\nThis will be used for VS Code Tunnel and other GitHub integrations." 12 60
    else
        # Clear the username if empty
        GITHUB_USERNAME=""
        rm -f "$ZOOLANDIA_CONFIG_DIR/github_username"
        dialog --msgbox "GitHub username cleared." 8 50
    fi
}
