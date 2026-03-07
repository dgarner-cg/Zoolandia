#!/bin/bash
################################################################################
# Zoolandia - Secret Projects Module
#
# Description: Secret Ansible projects and custom playbooks
#              Place projects in ansible/roles/secret/<project-name>/site.yml
#              or standalone playbooks in ansible/roles/secret/<name>.yml
#
# RSA Key Auth (optional):
#   Set SECRET_AUTH_ENABLED=true and SECRET_KEY_PATH to your private key.
#   To also verify fingerprint, set SECRET_KEY_FINGERPRINT by running:
#     ssh-keygen -lf ~/.ssh/id_rsa | awk '{print $2}'
################################################################################

SECRET_PLAYBOOKS_DIR="$SCRIPT_DIR/ansible/roles/secret"

# ── Auth configuration ────────────────────────────────────────────────────────
SECRET_AUTH_ENABLED=false
SECRET_KEY_PATH="${HOME}/.ssh/id_rsa"
SECRET_KEY_FINGERPRINT=""   # e.g. SHA256:abc123...  (leave empty to skip fingerprint check)
# ─────────────────────────────────────────────────────────────────────────────

# Verify RSA key access; returns 0 to allow, 1 to deny
_secret_verify_access() {
    [[ $SECRET_AUTH_ENABLED != true ]] && return 0

    # Check key file exists
    if [[ ! -f "$SECRET_KEY_PATH" ]]; then
        dialog --colors --msgbox "\Z1Access Denied\Zn\n\nRequired key not found:\n$SECRET_KEY_PATH" 10 60
        return 1
    fi

    # Verify fingerprint if one is configured
    if [[ -n "$SECRET_KEY_FINGERPRINT" ]]; then
        local actual_fingerprint
        actual_fingerprint=$(ssh-keygen -lf "$SECRET_KEY_PATH" 2>/dev/null | awk '{print $2}')

        if [[ -z "$actual_fingerprint" ]]; then
            dialog --colors --msgbox "\Z1Access Denied\Zn\n\nCould not read fingerprint from:\n$SECRET_KEY_PATH" 10 60
            return 1
        fi

        if [[ "$actual_fingerprint" != "$SECRET_KEY_FINGERPRINT" ]]; then
            dialog --colors --msgbox "\Z1Access Denied\Zn\n\nKey fingerprint does not match.\n\nExpected : $SECRET_KEY_FINGERPRINT\nFound    : $actual_fingerprint" 12 70
            return 1
        fi
    fi

    return 0
}

# Show the secret projects menu
show_secret_menu() {
    _secret_verify_access || return

    while true; do
        local menu_items=()
        local project_count=0

        if [[ -d "$SECRET_PLAYBOOKS_DIR" ]]; then
            # Discover project directories containing site.yml or main.yml
            while IFS= read -r project_dir; do
                local project_name
                project_name=$(basename "$project_dir")
                local playbook=""
                [[ -f "$project_dir/site.yml" ]] && playbook="site.yml"
                [[ -f "$project_dir/main.yml" ]] && playbook="main.yml"
                if [[ -n "$playbook" ]]; then
                    menu_items+=("$project_name" "Run ansible/roles/secret/$project_name/$playbook")
                    ((project_count++))
                fi
            done < <(find "$SECRET_PLAYBOOKS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

            # Discover standalone .yml files directly in secret dir
            while IFS= read -r playbook_file; do
                local playbook_name
                playbook_name=$(basename "$playbook_file" .yml)
                menu_items+=("$playbook_name" "Run ansible/roles/secret/$playbook_name.yml")
                ((project_count++))
            done < <(find "$SECRET_PLAYBOOKS_DIR" -maxdepth 1 -name "*.yml" -type f | sort)
        fi

        if [[ $project_count -eq 0 ]]; then
            menu_items+=("No Projects" "Add playbooks to ansible/roles/secret/ to get started")
        fi

        menu_items+=(
            "" ""
            "───── Options ─────" ""
            "Run Custom" "Run a playbook by entering its full path"
        )

        local choice
        choice=$(dialog --clear --colors --backtitle "$SCRIPT_NAME - Secret Projects" \
            --title "Secret Projects (Projects found: $project_count)" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "\nSecret Ansible projects.\n\nPlace projects in: ansible/roles/secret/<name>/site.yml" 24 80 13 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "No Projects"|"───── Options ─────"|"") ;;
            "Run Custom") _secret_run_custom ;;
            *) _secret_run_project "$choice" ;;
        esac
    done
}

# Run a discovered secret project by name
_secret_run_project() {
    local project_name="$1"
    local playbook_path=""

    # Directory-based project
    if [[ -d "$SECRET_PLAYBOOKS_DIR/$project_name" ]]; then
        if [[ -f "$SECRET_PLAYBOOKS_DIR/$project_name/site.yml" ]]; then
            playbook_path="$SECRET_PLAYBOOKS_DIR/$project_name/site.yml"
        elif [[ -f "$SECRET_PLAYBOOKS_DIR/$project_name/main.yml" ]]; then
            playbook_path="$SECRET_PLAYBOOKS_DIR/$project_name/main.yml"
        fi
    # Standalone playbook
    elif [[ -f "$SECRET_PLAYBOOKS_DIR/$project_name.yml" ]]; then
        playbook_path="$SECRET_PLAYBOOKS_DIR/$project_name.yml"
    fi

    if [[ -z "$playbook_path" ]]; then
        dialog --msgbox "Error: Could not find playbook for: $project_name" 8 60
        return
    fi

    _secret_run_interactive "$project_name" "$playbook_path"
}

# Run a custom playbook entered by the user
_secret_run_custom() {
    local playbook_path
    playbook_path=$(dialog --ok-label "Continue" --cancel-label "Cancel" \
        --inputbox "Enter the full path to the Ansible playbook:" 10 70 \
        3>&1 1>&2 2>&3 3>&-)

    [[ -z "$playbook_path" ]] && return

    if [[ ! -f "$playbook_path" ]]; then
        dialog --msgbox "Error: File not found:\n\n$playbook_path" 9 70
        return
    fi

    local project_name
    project_name=$(basename "$playbook_path" .yml)
    _secret_run_interactive "$project_name" "$playbook_path"
}

# Run a discovered/custom playbook using the same pattern as all other Ansible menus:
#   cd "$ANSIBLE_DIR" → ansible-playbook <path>
# ansible.cfg (inventory, become_ask_pass) is picked up automatically.
_secret_run_interactive() {
    local project_name="$1"
    local playbook_path="$2"

    # Summary and confirmation
    clear
    echo "======================================================================="
    echo "Secret Project: $project_name"
    echo "======================================================================="
    echo ""
    echo "Playbook: $playbook_path"
    echo ""
    read -rp "Press ENTER to run, or Ctrl+C to cancel..."
    echo ""

    cd "$ANSIBLE_DIR"
    ansible-playbook "$playbook_path"

    local exit_code=$?
    echo ""
    echo "======================================================================="
    if [[ $exit_code -eq 0 ]]; then
        echo "$project_name completed successfully!"
    else
        echo "$project_name completed with errors (exit code: $exit_code)"
    fi
    echo "======================================================================="
    echo ""
    read -rp "Press Enter to continue..."
}
