#!/usr/bin/env bash

################################################################################
# Zoolandia v6.0.18 - Main Entry Point
#
# Description: Automated Docker homelab deployment and management system
# Author: D. Garner - http://hack3r.gg
# License: See LICENSE file
# Website: https://www.hack3r.gg
################################################################################

set -eo pipefail

################################################################################
# Bootstrap Functions (Must be defined before sourcing modules)
################################################################################

# Ensure required dialog utility is available
check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        echo ""
        echo "================================================"
        echo "  PREREQUISITE CHECK: dialog utility"
        echo "================================================"
        echo ""
        echo "The 'dialog' utility is required but not installed."
        echo ""

        # Try to install automatically on Debian/Ubuntu systems
        if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
            echo "Attempting automatic installation..."
            echo ""

            if [ "$EUID" -ne 0 ]; then
                if command -v sudo >/dev/null 2>&1; then
                    echo "This will require administrator privileges."
                    sudo apt-get update -qq && sudo apt-get install -y dialog || {
                        echo ""
                        echo "ERROR: Automatic installation of 'dialog' failed."
                        echo "Please install it manually with:"
                        echo "  sudo apt update && sudo apt install dialog"
                        echo ""
                        exit 1
                    }
                else
                    echo "ERROR: 'sudo' is not available."
                    echo "Please install 'dialog' manually as root:"
                    echo "  apt update && apt install dialog"
                    echo ""
                    exit 1
                fi
            else
                apt-get update -qq && apt-get install -y dialog || {
                    echo ""
                    echo "ERROR: Automatic installation of 'dialog' failed."
                    echo "Please install it manually with:"
                    echo "  apt update && apt install dialog"
                    echo ""
                    exit 1
                }
            fi

            # Verify installation
            if command -v dialog >/dev/null 2>&1; then
                echo ""
                echo "✓ Successfully installed dialog"
                echo ""
                sleep 1
            else
                echo ""
                echo "ERROR: Installation completed but dialog is still not available."
                echo "Please try installing manually: sudo apt install dialog"
                echo ""
                exit 1
            fi
        # Check for other package managers
        elif command -v dnf >/dev/null 2>&1; then
            echo "Detected Fedora/RHEL system. Attempting installation..."
            if [ "$EUID" -ne 0 ]; then
                sudo dnf install -y dialog || exit 1
            else
                dnf install -y dialog || exit 1
            fi
        elif command -v yum >/dev/null 2>&1; then
            echo "Detected CentOS/RHEL system. Attempting installation..."
            if [ "$EUID" -ne 0 ]; then
                sudo yum install -y dialog || exit 1
            else
                yum install -y dialog || exit 1
            fi
        elif command -v pacman >/dev/null 2>&1; then
            echo "Detected Arch Linux system. Attempting installation..."
            if [ "$EUID" -ne 0 ]; then
                sudo pacman -S --noconfirm dialog || exit 1
            else
                pacman -S --noconfirm dialog || exit 1
            fi
        elif command -v zypper >/dev/null 2>&1; then
            echo "Detected openSUSE system. Attempting installation..."
            if [ "$EUID" -ne 0 ]; then
                sudo zypper install -y dialog || exit 1
            else
                zypper install -y dialog || exit 1
            fi
        else
            echo ""
            echo "ERROR: Could not detect package manager."
            echo "Please install 'dialog' manually using your system's package manager:"
            echo "  - Debian/Ubuntu: sudo apt install dialog"
            echo "  - Fedora/RHEL:   sudo dnf install dialog"
            echo "  - Arch Linux:    sudo pacman -S dialog"
            echo "  - openSUSE:      sudo zypper install dialog"
            echo ""
            exit 1
        fi
    fi
}

# Check and install other essential prerequisites
check_prerequisites() {
    local missing_packages=()
    local install_cmd=""
    local update_cmd=""

    echo ""
    echo "================================================"
    echo "  CHECKING SYSTEM PREREQUISITES"
    echo "================================================"
    echo ""

    # Check for curl (needed for downloading files and APIs)
    if ! command -v curl >/dev/null 2>&1; then
        echo "⚠ curl is not installed (required for API calls)"
        missing_packages+=("curl")
    else
        echo "✓ curl is installed"
    fi

    # Check for wget (alternative download tool)
    if ! command -v wget >/dev/null 2>&1; then
        echo "⚠ wget is not installed (recommended for downloads)"
        missing_packages+=("wget")
    else
        echo "✓ wget is installed"
    fi

    # Check for git (needed for cloning repos)
    if ! command -v git >/dev/null 2>&1; then
        echo "⚠ git is not installed (required for repository management)"
        missing_packages+=("git")
    else
        echo "✓ git is installed"
    fi

    # Check for jq (JSON processor, useful for API responses)
    if ! command -v jq >/dev/null 2>&1; then
        echo "⚠ jq is not installed (recommended for JSON processing)"
        missing_packages+=("jq")
    else
        echo "✓ jq is installed"
    fi

    # If packages are missing, offer to install them
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo ""
        echo "The following packages are missing:"
        printf '  - %s\n' "${missing_packages[@]}"
        echo ""

        # Detect package manager and set commands
        if command -v apt-get >/dev/null 2>&1; then
            update_cmd="apt-get update -qq"
            install_cmd="apt-get install -y ${missing_packages[*]}"
        elif command -v dnf >/dev/null 2>&1; then
            update_cmd="true"
            install_cmd="dnf install -y ${missing_packages[*]}"
        elif command -v yum >/dev/null 2>&1; then
            update_cmd="true"
            install_cmd="yum install -y ${missing_packages[*]}"
        elif command -v pacman >/dev/null 2>&1; then
            update_cmd="pacman -Sy --noconfirm"
            install_cmd="pacman -S --noconfirm ${missing_packages[*]}"
        elif command -v zypper >/dev/null 2>&1; then
            update_cmd="zypper refresh"
            install_cmd="zypper install -y ${missing_packages[*]}"
        else
            echo "Could not detect package manager. Please install missing packages manually."
            echo ""
            return 0
        fi

        echo "Attempting to install missing packages..."
        echo ""

        if [ "$EUID" -ne 0 ]; then
            if command -v sudo >/dev/null 2>&1; then
                echo "This will require administrator privileges."
                sudo sh -c "$update_cmd && $install_cmd" || {
                    echo ""
                    echo "WARNING: Some packages failed to install."
                    echo "The script will continue, but some features may not work."
                    echo ""
                    sleep 2
                    return 0
                }
            else
                echo "WARNING: sudo is not available and you're not root."
                echo "Please install missing packages manually."
                echo ""
                sleep 2
                return 0
            fi
        else
            sh -c "$update_cmd && $install_cmd" || {
                echo ""
                echo "WARNING: Some packages failed to install."
                echo "The script will continue, but some features may not work."
                echo ""
                sleep 2
                return 0
            }
        fi

        echo ""
        echo "✓ Successfully installed missing packages"
        echo ""
        sleep 1
    else
        echo ""
        echo "✓ All essential prerequisites are installed"
        echo ""
        sleep 1
    fi
}

# Display splash screen with ASCII art (with timeout)
display_splash() {
    clear
    cat << "EOF"

 ███████╗ ██████╗  ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ ██╗ █████╗
 ╚══███╔╝██╔═══██╗██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗██║██╔══██╗
   ███╔╝ ██║   ██║██║   ██║██║     ███████║██╔██╗ ██║██║  ██║██║███████║
  ███╔╝  ██║   ██║██║   ██║██║     ██╔══██║██║╚██╗██║██║  ██║██║██╔══██║
 ███████╗╚██████╔╝╚██████╔╝███████╗██║  ██║██║ ╚████║██████╔╝██║██║  ██║
 ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═╝

                         by D.Garner -  http://hack3r.gg

                   Automated Docker Homelab Deployment System
                              Version 6.0.18

EOF
    echo ""
    echo "  Loading..."
    sleep 2
}

# Display banner (ASCII art that stays on screen during checks)
display_banner() {
    clear
    cat << "EOF"

 ███████╗ ██████╗  ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ ██╗ █████╗
 ╚══███╔╝██╔═══██╗██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗██║██╔══██╗
   ███╔╝ ██║   ██║██║   ██║██║     ███████║██╔██╗ ██║██║  ██║██║███████║
  ███╔╝  ██║   ██║██║   ██║██║     ██╔══██║██║╚██╗██║██║  ██║██║██╔══██║
 ███████╗╚██████╔╝╚██████╔╝███████╗██║  ██║██║ ╚████║██████╔╝██║██║  ██║
 ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═╝

                         by D.Garner -  http://hack3r.gg

EOF
    echo ""
}

################################################################################
# Source All Modules (in dependency order)
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/modules"

# Source modules in order
source "${MODULE_DIR}/00_core.sh"           # Core variables and utilities
source "${MODULE_DIR}/01_homepage.sh"       # Homepage and configuration
source "${MODULE_DIR}/02_main_menu.sh"      # Main menu
source "${MODULE_DIR}/10_prerequisites.sh"  # Prerequisites menu
source "${MODULE_DIR}/11_system.sh"         # System preparation
source "${MODULE_DIR}/12_docker.sh"         # Docker management
source "${MODULE_DIR}/13_reverse_proxy.sh"  # Reverse proxy (Traefik)
source "${MODULE_DIR}/14_security.sh"       # Security and authentication
source "${MODULE_DIR}/20_apps.sh"           # Application management
source "${MODULE_DIR}/21_docker_apps.sh"    # Docker applications menu
source "${MODULE_DIR}/22_system_apps.sh"    # System applications menu
source "${MODULE_DIR}/30_tools.sh"          # Tools and utilities
source "${MODULE_DIR}/31_backup.sh"         # Backup functionality
source "${MODULE_DIR}/40_settings.sh"       # Settings menu
source "${MODULE_DIR}/41_ansible.sh"        # Ansible menu
source "${MODULE_DIR}/50_about.sh"          # About and feedback
source "${MODULE_DIR}/60_personal.sh"       # Personal projects

################################################################################
# Main Script Execution
################################################################################

main() {
    # Ensure dialog utility is available (must be first!)
    check_dialog

    # Display splash screen with timeout (ASCII art + wait)
    display_splash

    # Display banner (ASCII art that stays on screen)
    display_banner

    # Check and install other system prerequisites (runs under the banner)
    check_prerequisites

    # Check if root
    check_root "$@"

    # Check version
    check_version

    # Create directories
    create_directories

    # Load configuration
    load_config

    # Show welcome/homepage splash screen
    show_homepage

    # Main loop
    while true; do
        show_main_menu || break
    done

    # Cleanup
    clear
    echo ""
    echo "Thank you for using $SCRIPT_NAME Script from hack3r.gg."
    echo ""
}

# Run main function
main "$@"
