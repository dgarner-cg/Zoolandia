#!/bin/bash
################################################################################
# Zoolandia - Reverse Proxy Management Module
################################################################################
# Description: Traefik and reverse proxy configuration functions
# Version: 2.0.0
# Dependencies: 00_init.sh, 01_config.sh
################################################################################

# Exposure mode: Simple or Advanced
EXPOSURE_MODE="${EXPOSURE_MODE:-Simple}"

# DNS Provider for ACME challenges
# Supported: cloudflare, clouddns (ManageEngine)
DNS_PROVIDER="${DNS_PROVIDER:-cloudflare}"

# Load saved DNS provider
if [[ -f "$ZOOLANDIA_CONFIG_DIR/dns_provider" ]]; then
    DNS_PROVIDER=$(cat "$ZOOLANDIA_CONFIG_DIR/dns_provider")
fi

# Load Vault address if previously persisted
[[ -f "$ZOOLANDIA_CONFIG_DIR/vault.env" ]] && source "$ZOOLANDIA_CONFIG_DIR/vault.env"

################################################################################
# Tiered Secret Backend — helper functions
################################################################################

# Detect a GNOME/graphical desktop session where keyring can work (D-Bus only)
# secret-tool does not need to be installed yet — it is installed on first use
_zl_keyring_available() {
    [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || [[ -S "/run/user/$(id -u)/bus" ]]
}

# Ensure secret-tool (libsecret-tools) is installed; prompt to install if missing
_zl_ensure_secret_tool() {
    command -v secret-tool &>/dev/null && return 0
    dialog --yesno "GNOME Keyring requires 'secret-tool' (libsecret-tools).\n\nInstall it now?" 8 55 || return 1
    apt-get install -y libsecret-tools &>/dev/null
    command -v secret-tool &>/dev/null || {
        dialog --msgbox "Installation failed. Falling back to file backend." 7 55
        _zl_save_backend "file"
        return 1
    }
}

# Return the currently saved backend (keyring | file | vault)
_zl_get_backend() {
    local f="$ZOOLANDIA_CONFIG_DIR/secret_backend"
    [[ -f "$f" ]] && cat "$f" && return
    _zl_keyring_available && echo "keyring" || echo "file"
}

# Persist the chosen backend
_zl_save_backend() { mkdir -p "$ZOOLANDIA_CONFIG_DIR"; echo "$1" > "$ZOOLANDIA_CONFIG_DIR/secret_backend"; }

# Vault KV path helper
_zl_vault_path() { echo "secret/zoolandia/dns/$1"; }

_zl_vault_write() {
    local key="$1" value="$2"
    vault kv put "$(_zl_vault_path "$key")" value="$value" 2>/dev/null
}

_zl_vault_read() {
    vault kv get -field=value "$(_zl_vault_path "$1")" 2>/dev/null
}

_zl_vault_delete() {
    vault kv delete "$(_zl_vault_path "$1")" 2>/dev/null
}

# Write a secret to the active backend
_zl_secret_write() {
    local key="$1" value="$2"
    case "$(_zl_get_backend)" in
        keyring)
            if _zl_ensure_secret_tool; then
                if printf '%s' "$value" | secret-tool store \
                        --label="Zoolandia: $key" service zoolandia username "$key" 2>/dev/null; then
                    rm -f "$SECRETS_DIR/$key"   # remove stale plaintext
                    return 0
                fi
            fi
            # secret-tool install refused or daemon locked — write to file
            mkdir -p "$SECRETS_DIR"
            printf '%s' "$value" > "$SECRETS_DIR/$key"
            chmod 600 "$SECRETS_DIR/$key"
            ;;
        file)
            mkdir -p "$SECRETS_DIR"
            printf '%s' "$value" > "$SECRETS_DIR/$key"
            chmod 600 "$SECRETS_DIR/$key"
            ;;
        vault)
            _zl_vault_write "$key" "$value"
            ;;
    esac
}

# Read a secret from the active backend; keyring falls back to file on miss or if secret-tool absent
_zl_secret_read() {
    local key="$1"
    case "$(_zl_get_backend)" in
        keyring)
            if command -v secret-tool &>/dev/null; then
                local v; v=$(secret-tool lookup service zoolandia username "$key" 2>/dev/null)
                [[ -n "$v" ]] && printf '%s' "$v" && return
            fi
            # secret-tool absent or keyring miss — fall back to file
            [[ -f "$SECRETS_DIR/$key" ]] && cat "$SECRETS_DIR/$key"
            ;;
        file)   [[ -f "$SECRETS_DIR/$key" ]] && cat "$SECRETS_DIR/$key" ;;
        vault)  _zl_vault_read "$key" ;;
    esac
}

# Delete a secret from all backends
_zl_secret_delete() {
    local key="$1"
    secret-tool clear service zoolandia username "$key" 2>/dev/null
    rm -f "$SECRETS_DIR/$key"
    _zl_vault_delete "$key" 2>/dev/null
}

# Install Vault CLI (via Ansible) and authenticate if needed
ensure_vault() {
    # 1. Install CLI if missing
    if ! command -v vault &>/dev/null; then
        dialog --yesno "HashiCorp Vault CLI is not installed.\n\nInstall it now via Ansible?" 8 55 || return 1
        clear
        echo "Installing HashiCorp Vault CLI..."
        cd "$ANSIBLE_DIR" && ansible-playbook playbooks/hashicorp.yml --tags vault
        command -v vault &>/dev/null || { dialog --msgbox "Vault installation failed." 7 45; return 1; }
    fi

    # 2. Set VAULT_ADDR if missing
    if [[ -z "${VAULT_ADDR:-}" ]]; then
        local addr
        addr=$(dialog --inputbox "Vault server address:" 8 65 "http://127.0.0.1:8200" \
            3>&1 1>&2 2>&3 3>&-) || return 1
        export VAULT_ADDR="$addr"
        echo "VAULT_ADDR=$addr" >> "$ZOOLANDIA_CONFIG_DIR/vault.env"
    fi

    # 3. Authenticate if not already
    if ! vault token lookup &>/dev/null 2>&1; then
        local method
        method=$(dialog --menu "Vault auth method:" 10 45 2 \
            "token"    "Token (direct)" \
            "userpass" "Username / Password" \
            3>&1 1>&2 2>&3 3>&-) || return 1

        if [[ "$method" == "token" ]]; then
            local tok
            tok=$(dialog --passwordbox "Vault token:" 7 50 3>&1 1>&2 2>&3 3>&-) || return 1
            export VAULT_TOKEN="$tok"
        else
            local u p
            u=$(dialog --inputbox "Vault username:" 7 50 3>&1 1>&2 2>&3 3>&-) || return 1
            p=$(dialog --passwordbox "Vault password:" 7 50 3>&1 1>&2 2>&3 3>&-) || return 1
            vault login -method=userpass username="$u" password="$p" &>/dev/null
        fi

        vault token lookup &>/dev/null 2>&1 || { dialog --msgbox "Vault auth failed." 7 40; return 1; }
    fi
    return 0
}

# Dialog menu for choosing the secret storage backend
show_secret_backend_menu() {
    local current; current=$(_zl_get_backend)
    local options=("file" "File — chmod 600 in ~/docker/secrets/ (always available)")
    _zl_keyring_available && options+=("keyring" "GNOME Keyring — encrypted, no plaintext file")
    options+=("vault" "HashiCorp Vault — centralized secrets server")

    local choice
    choice=$(dialog --default-item "$current" \
        --menu "Choose secret storage backend:\n\nCurrent: $current" 14 70 3 \
        "${options[@]}" 3>&1 1>&2 2>&3 3>&-) || return

    if [[ "$choice" == "vault" ]]; then
        ensure_vault || return
    fi
    _zl_save_backend "$choice"
    dialog --msgbox "Backend set to: $choice" 6 40
}

################################################################################

show_reverse_proxy_menu() {
    while true; do
        # Get Traefik preparation status
        local prep_status="\Z1NOT DONE\Zn"
        if [[ -f "$ZOOLANDIA_CONFIG_DIR/traefik_done" ]]; then
            prep_status="\Z2DONE\Zn"
        fi

        # Count apps by exposure type
        local internal_count=0
        local external_count=0
        local both_count=0

        if [[ -d "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME" ]]; then
            internal_count=$(grep -l "internal" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"/*.yml 2>/dev/null | wc -l)
            external_count=$(grep -l "external" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"/*.yml 2>/dev/null | wc -l)
            # Count files that have both
            both_count=$(grep -l "internal\|external" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"/*.yml 2>/dev/null | xargs grep -l "internal" 2>/dev/null | xargs grep -l "external" 2>/dev/null | wc -l)
        fi

        # Get DNS provider display name
        local dns_display="Cloudflare"
        case "$DNS_PROVIDER" in
            "cloudflare") dns_display="Cloudflare" ;;
            "clouddns") dns_display="ManageEngine CloudDNS" ;;
            "route53") dns_display="AWS Route53" ;;
            "digitalocean") dns_display="DigitalOcean" ;;
            "godaddy") dns_display="GoDaddy" ;;
            *) dns_display="$DNS_PROVIDER" ;;
        esac

        local menu_items=(
            "Exposure Mode" "Toggle how apps are exposed - $EXPOSURE_MODE"
            "DNS Provider" "ACME DNS Challenge Provider - $dns_display"
            "Preparation" "Traefik Preparation - $prep_status"
            "Staging" "Setup Traefik Staging"
            "Production" "Setup Traefik Production"
            "Manage Exposure" "Change app exposure (Internal: $internal_count; External: $external_count; Both: $both_count)"
            "Traefikify" "Put an App Behind Traefik"
            "Un-Traefikify" "Remove a Traefik File Provider"
            "Domain Passthrough" "To Another Traefik Instance"
            "Auth Bypass" "Set Traefik Forward Auth Bypass Key"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --colors --backtitle "$SCRIPT_NAME - Reverse Proxy" \
            --title "Reverse Proxy" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "HOW TO USE: Check About for recommendations on the order of steps. See\nSettings to hide this notification.\n\nSelect an action..." 22 78 10 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Exposure Mode") toggle_exposure_mode ;;
            "DNS Provider") configure_dns_provider ;;
            "Preparation") traefik_preparation ;;
            "Staging") setup_traefik_staging ;;
            "Production") setup_traefik_production ;;
            "Manage Exposure") manage_exposure ;;
            "Traefikify") traefikify_app ;;
            "Un-Traefikify") un_traefikify_app ;;
            "Domain Passthrough") domain_passthrough ;;
            "Auth Bypass") set_auth_bypass ;;
            "Back") return ;;
        esac
    done
}

################################################################################
# Exposure Mode Functions
################################################################################

toggle_exposure_mode() {
    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Exposure Mode" \
        --title "Exposure Mode" \
        --ok-label "Select" \
        --cancel-label "Cancel" \
        --radiolist "Select how apps are exposed through Traefik:\n\nCurrent mode: $EXPOSURE_MODE" 14 70 2 \
        "Simple" "Basic exposure with minimal configuration" $([ "$EXPOSURE_MODE" = "Simple" ] && echo "on" || echo "off") \
        "Advanced" "Full control over internal/external exposure" $([ "$EXPOSURE_MODE" = "Advanced" ] && echo "on" || echo "off") \
        3>&1 1>&2 2>&3 3>&-) || return

    if [[ -n "$choice" ]]; then
        EXPOSURE_MODE="$choice"
        echo "$EXPOSURE_MODE" > "$ZOOLANDIA_CONFIG_DIR/exposure_mode"
        dialog --msgbox "Exposure mode set to: $EXPOSURE_MODE" 8 50
    fi
}

################################################################################
# DNS Provider Configuration
################################################################################

configure_dns_provider() {
    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - DNS Provider" \
        --title "ACME DNS Challenge Provider" \
        --ok-label "Select" \
        --cancel-label "Cancel" \
        --radiolist "Select DNS provider for Let's Encrypt ACME challenges:\n\nCurrent: $DNS_PROVIDER" 18 75 6 \
        "cloudflare" "Cloudflare DNS (recommended)" $([ "$DNS_PROVIDER" = "cloudflare" ] && echo "on" || echo "off") \
        "clouddns" "ManageEngine CloudDNS" $([ "$DNS_PROVIDER" = "clouddns" ] && echo "on" || echo "off") \
        "route53" "AWS Route53" $([ "$DNS_PROVIDER" = "route53" ] && echo "on" || echo "off") \
        "digitalocean" "DigitalOcean DNS" $([ "$DNS_PROVIDER" = "digitalocean" ] && echo "on" || echo "off") \
        "godaddy" "GoDaddy DNS" $([ "$DNS_PROVIDER" = "godaddy" ] && echo "on" || echo "off") \
        "manual" "Manual DNS (no automation)" $([ "$DNS_PROVIDER" = "manual" ] && echo "on" || echo "off") \
        3>&1 1>&2 2>&3 3>&-) || return

    if [[ -n "$choice" ]]; then
        DNS_PROVIDER="$choice"
        mkdir -p "$ZOOLANDIA_CONFIG_DIR"
        echo "$DNS_PROVIDER" > "$ZOOLANDIA_CONFIG_DIR/dns_provider"

        # Configure the selected provider
        case "$DNS_PROVIDER" in
            "cloudflare") configure_cloudflare_dns ;;
            "clouddns") configure_clouddns ;;
            "route53") configure_route53_dns ;;
            "digitalocean") configure_digitalocean_dns ;;
            "godaddy") configure_godaddy_dns ;;
            "manual") dialog --msgbox "Manual DNS selected.\n\nYou will need to manually create TXT records\nfor ACME challenges." 10 55 ;;
        esac
    fi
}

configure_cloudflare_dns() {
    local cf_token_file="$SECRETS_DIR/cf_dns_api_token"
    local cf_email_file="$SECRETS_DIR/cf_email"

    while true; do
        local current_token=""
        local current_email=""
        local token_display="Not set"
        local email_display="Not set"

        if [[ -f "$cf_token_file" ]]; then
            current_token=$(cat "$cf_token_file")
            token_display="(set)"
        fi
        if [[ -f "$cf_email_file" ]]; then
            current_email=$(cat "$cf_email_file")
            email_display="$current_email"
        fi

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Cloudflare DNS" \
            --title "Cloudflare DNS Configuration" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure Cloudflare DNS API credentials:\n\nEmail: ${email_display}\nAPI Token: ${token_display}" 18 70 5 \
            "API Token" "Set Cloudflare DNS API Token (recommended)" \
            "Email" "Set Cloudflare account email" \
            "Test" "Test Cloudflare API connection" \
            "Clear" "Clear all Cloudflare credentials" \
            "Back" "Return to DNS provider menu" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "API Token")
                local token
                token=$(dialog --inputbox "Enter Cloudflare DNS API Token:\n\nCreate at: https://dash.cloudflare.com/profile/api-tokens\nPermissions needed: Zone:DNS:Edit" 14 70 "$current_token" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$token" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$token" > "$cf_token_file"
                    chmod 600 "$cf_token_file"
                fi
                ;;
            "Email")
                local email
                email=$(dialog --inputbox "Enter Cloudflare account email:" 10 60 "$current_email" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$email" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$email" > "$cf_email_file"
                    chmod 600 "$cf_email_file"
                fi
                ;;
            "Test")
                test_cloudflare_api
                ;;
            "Clear")
                if dialog --yesno "Clear all Cloudflare credentials?" 8 45; then
                    rm -f "$cf_token_file" "$cf_email_file"
                fi
                ;;
            "Back")
                return
                ;;
        esac
    done
}

test_cloudflare_api() {
    local cf_token_file="$SECRETS_DIR/cf_dns_api_token"

    if [[ ! -f "$cf_token_file" ]]; then
        dialog --msgbox "Cloudflare API token not configured." 8 50
        return 1
    fi

    dialog --infobox "Testing Cloudflare API connection..." 5 50

    local token
    token=$(cat "$cf_token_file")

    local response
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" 2>&1)

    if echo "$response" | grep -q '"success":true'; then
        dialog --msgbox "Cloudflare API connection successful!\n\nToken is valid." 10 50
    else
        local error
        error=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1)
        dialog --msgbox "Cloudflare API connection failed!\n\n$error" 12 60
    fi
}

configure_clouddns() {
    while true; do
        local current_id current_secret id_display secret_display
        current_id=$(_zl_secret_read "clouddns_client_id")
        current_secret=$(_zl_secret_read "clouddns_client_secret")

        if [[ -n "$current_id" ]]; then
            id_display="****${current_id: -4}"
        else
            id_display="Not set"
        fi
        if [[ -n "$current_secret" ]]; then
            secret_display="****${current_secret: -4}"
        else
            secret_display="Not set"
        fi

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - ManageEngine CloudDNS" \
            --title "ManageEngine CloudDNS Configuration" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure ManageEngine CloudDNS API credentials:\n\nClient ID: ${id_display}\nClient Secret: ${secret_display}\nBackend: $(_zl_get_backend)" 20 75 6 \
            "Client ID" "Set CloudDNS Client ID" \
            "Client Secret" "Set CloudDNS Client Secret" \
            "Test" "Test CloudDNS API connection" \
            "Clear" "Clear all CloudDNS credentials" \
            "Storage Backend" "Current: $(_zl_get_backend) (change)" \
            "Back" "Return to DNS provider menu" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Client ID")
                local client_id
                client_id=$(dialog --inputbox "Enter ManageEngine CloudDNS Client ID:" 10 70 "$current_id" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$client_id" ]]; then
                    _zl_secret_write "clouddns_client_id" "$client_id"
                    dialog --yesno "Saved. Run API test now?" 7 40 && test_clouddns_api
                fi
                ;;
            "Client Secret")
                local client_secret
                client_secret=$(dialog --passwordbox "Enter ManageEngine CloudDNS Client Secret:" 10 70 "$current_secret" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$client_secret" ]]; then
                    _zl_secret_write "clouddns_client_secret" "$client_secret"
                    dialog --yesno "Saved. Run API test now?" 7 40 && test_clouddns_api
                fi
                ;;
            "Test")
                test_clouddns_api
                ;;
            "Clear")
                if dialog --yesno "Clear all CloudDNS credentials?" 8 45; then
                    _zl_secret_delete "clouddns_client_id"
                    _zl_secret_delete "clouddns_client_secret"
                fi
                ;;
            "Storage Backend")
                show_secret_backend_menu
                ;;
            "Back")
                return
                ;;
        esac
    done
}

test_clouddns_api() {
    local client_id client_secret
    client_id=$(_zl_secret_read "clouddns_client_id")
    client_secret=$(_zl_secret_read "clouddns_client_secret")

    if [[ -z "$client_id" ]] || [[ -z "$client_secret" ]]; then
        dialog --msgbox "CloudDNS API credentials not fully configured.\n\nPlease set Client ID and Client Secret." 10 55
        return 1
    fi

    dialog --infobox "Testing ManageEngine CloudDNS API connection..." 5 55

    # OAuth2 authentication endpoint
    local auth_url="https://clouddns.manageengine.com/oauth2/token/"

    # Get OAuth2 token
    local auth_response
    auth_response=$(curl -s -X POST "$auth_url" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "client_id=$client_id" \
        --data-urlencode "client_secret=$client_secret" 2>&1)

    if echo "$auth_response" | grep -q 'access_token'; then
        local access_token
        access_token=$(echo "$auth_response" | jq -r ".access_token" 2>/dev/null)

        # Test API by listing domains
        local api_url="https://clouddns.manageengine.com/v1/dns/domain/"
        local api_response
        api_response=$(curl -s -X GET "$api_url" \
            -H "Authorization: Bearer $access_token" 2>&1)

        if echo "$api_response" | grep -qE '^\[|"zone_id"'; then
            local zone_count
            zone_count=$(echo "$api_response" | jq 'length' 2>/dev/null || echo "0")
            dialog --msgbox "CloudDNS API connection successful!\n\nAuthentication: OK\nZones found: $zone_count" 10 50
        else
            dialog --msgbox "CloudDNS authentication successful!\n\nBut could not list zones:\n${api_response:0:150}" 12 60
        fi
    else
        local error_msg
        error_msg=$(echo "$auth_response" | jq -r '.error_description // .error // "Unknown error"' 2>/dev/null || echo "$auth_response")
        dialog --msgbox "CloudDNS authentication failed!\n\n$error_msg" 10 60
    fi
}

configure_route53_dns() {
    local aws_key_file="$SECRETS_DIR/aws_access_key_id"
    local aws_secret_file="$SECRETS_DIR/aws_secret_access_key"
    local aws_region_file="$SECRETS_DIR/aws_region"

    while true; do
        local current_key=""
        local current_secret=""
        local current_region=""
        local key_display="Not set"
        local secret_display="Not set"
        local region_display="Not set"

        if [[ -f "$aws_key_file" ]]; then
            current_key=$(cat "$aws_key_file")
            key_display="(set)"
        fi
        if [[ -f "$aws_secret_file" ]]; then
            current_secret=$(cat "$aws_secret_file")
            secret_display="(set)"
        fi
        if [[ -f "$aws_region_file" ]]; then
            current_region=$(cat "$aws_region_file")
            region_display="$current_region"
        fi

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - AWS Route53" \
            --title "AWS Route53 Configuration" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure AWS Route53 credentials:\n\nAccess Key: ${key_display}\nSecret Key: ${secret_display}\nRegion: ${region_display}" 20 70 5 \
            "Access Key" "Set AWS Access Key ID" \
            "Secret Key" "Set AWS Secret Access Key" \
            "Region" "Set AWS Region (default: us-east-1)" \
            "Clear" "Clear all AWS credentials" \
            "Back" "Return to DNS provider menu" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Access Key")
                local key
                key=$(dialog --inputbox "Enter AWS Access Key ID:" 10 60 "$current_key" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$key" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$key" > "$aws_key_file"
                    chmod 600 "$aws_key_file"
                fi
                ;;
            "Secret Key")
                local secret
                secret=$(dialog --inputbox "Enter AWS Secret Access Key:" 10 70 "$current_secret" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$secret" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$secret" > "$aws_secret_file"
                    chmod 600 "$aws_secret_file"
                fi
                ;;
            "Region")
                local region
                region=$(dialog --inputbox "Enter AWS Region:" 10 50 "${current_region:-us-east-1}" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$region" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$region" > "$aws_region_file"
                    chmod 600 "$aws_region_file"
                fi
                ;;
            "Clear")
                if dialog --yesno "Clear all AWS credentials?" 8 45; then
                    rm -f "$aws_key_file" "$aws_secret_file" "$aws_region_file"
                fi
                ;;
            "Back")
                return
                ;;
        esac
    done
}

configure_digitalocean_dns() {
    local do_token_file="$SECRETS_DIR/digitalocean_token"

    while true; do
        local current_token=""
        local token_display="Not set"

        if [[ -f "$do_token_file" ]]; then
            current_token=$(cat "$do_token_file")
            token_display="(set)"
        fi

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - DigitalOcean DNS" \
            --title "DigitalOcean DNS Configuration" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure DigitalOcean DNS API:\n\nAPI Token: ${token_display}" 16 70 4 \
            "API Token" "Set DigitalOcean API Token" \
            "Test" "Test DigitalOcean API connection" \
            "Clear" "Clear DigitalOcean credentials" \
            "Back" "Return to DNS provider menu" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "API Token")
                local token
                token=$(dialog --inputbox "Enter DigitalOcean API Token:\n\nCreate at: https://cloud.digitalocean.com/account/api/tokens" 12 70 "$current_token" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$token" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$token" > "$do_token_file"
                    chmod 600 "$do_token_file"
                fi
                ;;
            "Test")
                if [[ -f "$do_token_file" ]]; then
                    dialog --infobox "Testing DigitalOcean API..." 5 45
                    local token response
                    token=$(cat "$do_token_file")
                    response=$(curl -s -X GET "https://api.digitalocean.com/v2/account" \
                        -H "Authorization: Bearer $token" 2>&1)
                    if echo "$response" | grep -q '"account"'; then
                        dialog --msgbox "DigitalOcean API connection successful!" 8 50
                    else
                        dialog --msgbox "DigitalOcean API connection failed.\n\n${response:0:200}" 12 60
                    fi
                else
                    dialog --msgbox "DigitalOcean API token not configured." 8 50
                fi
                ;;
            "Clear")
                if dialog --yesno "Clear DigitalOcean credentials?" 8 45; then
                    rm -f "$do_token_file"
                fi
                ;;
            "Back")
                return
                ;;
        esac
    done
}

configure_godaddy_dns() {
    local godaddy_key_file="$SECRETS_DIR/godaddy_api_key"
    local godaddy_secret_file="$SECRETS_DIR/godaddy_api_secret"

    while true; do
        local current_key=""
        local current_secret=""
        local key_display="Not set"
        local secret_display="Not set"

        if [[ -f "$godaddy_key_file" ]]; then
            current_key=$(cat "$godaddy_key_file")
            key_display="(set)"
        fi
        if [[ -f "$godaddy_secret_file" ]]; then
            current_secret=$(cat "$godaddy_secret_file")
            secret_display="(set)"
        fi

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME - GoDaddy DNS" \
            --title "GoDaddy DNS Configuration" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Configure GoDaddy DNS API:\n\nAPI Key: ${key_display}\nAPI Secret: ${secret_display}" 18 70 4 \
            "API Key" "Set GoDaddy API Key" \
            "API Secret" "Set GoDaddy API Secret" \
            "Clear" "Clear all GoDaddy credentials" \
            "Back" "Return to DNS provider menu" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "API Key")
                local key
                key=$(dialog --inputbox "Enter GoDaddy API Key:\n\nCreate at: https://developer.godaddy.com/keys" 12 70 "$current_key" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$key" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$key" > "$godaddy_key_file"
                    chmod 600 "$godaddy_key_file"
                fi
                ;;
            "API Secret")
                local secret
                secret=$(dialog --inputbox "Enter GoDaddy API Secret:" 10 70 "$current_secret" \
                    3>&1 1>&2 2>&3 3>&-)
                if [[ -n "$secret" ]]; then
                    mkdir -p "$SECRETS_DIR"
                    echo "$secret" > "$godaddy_secret_file"
                    chmod 600 "$godaddy_secret_file"
                fi
                ;;
            "Clear")
                if dialog --yesno "Clear all GoDaddy credentials?" 8 45; then
                    rm -f "$godaddy_key_file" "$godaddy_secret_file"
                fi
                ;;
            "Back")
                return
                ;;
        esac
    done
}

################################################################################
# DNS Record Management (for ACME challenges)
################################################################################

# Create TXT record for ACME challenge
create_acme_txt_record() {
    local domain="$1"
    local record_name="$2"
    local record_value="$3"

    case "$DNS_PROVIDER" in
        "cloudflare")
            create_cloudflare_txt_record "$domain" "$record_name" "$record_value"
            ;;
        "clouddns")
            create_clouddns_txt_record "$domain" "$record_name" "$record_value"
            ;;
        "route53")
            create_route53_txt_record "$domain" "$record_name" "$record_value"
            ;;
        "digitalocean")
            create_digitalocean_txt_record "$domain" "$record_name" "$record_value"
            ;;
        "godaddy")
            create_godaddy_txt_record "$domain" "$record_name" "$record_value"
            ;;
        *)
            echo "Unsupported DNS provider: $DNS_PROVIDER"
            return 1
            ;;
    esac
}

# Delete TXT record after ACME challenge
delete_acme_txt_record() {
    local domain="$1"
    local record_name="$2"

    case "$DNS_PROVIDER" in
        "cloudflare")
            delete_cloudflare_txt_record "$domain" "$record_name"
            ;;
        "clouddns")
            delete_clouddns_txt_record "$domain" "$record_name"
            ;;
        "route53")
            delete_route53_txt_record "$domain" "$record_name"
            ;;
        "digitalocean")
            delete_digitalocean_txt_record "$domain" "$record_name"
            ;;
        "godaddy")
            delete_godaddy_txt_record "$domain" "$record_name"
            ;;
        *)
            echo "Unsupported DNS provider: $DNS_PROVIDER"
            return 1
            ;;
    esac
}

# Cloudflare TXT record functions
create_cloudflare_txt_record() {
    local domain="$1"
    local record_name="$2"
    local record_value="$3"

    local token zone_id
    token=$(cat "$SECRETS_DIR/cf_dns_api_token" 2>/dev/null)

    # Get zone ID
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Create TXT record
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"TXT\",\"name\":\"$record_name\",\"content\":\"$record_value\",\"ttl\":120}"
}

delete_cloudflare_txt_record() {
    local domain="$1"
    local record_name="$2"

    local token zone_id record_id
    token=$(cat "$SECRETS_DIR/cf_dns_api_token" 2>/dev/null)

    # Get zone ID
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Get record ID
    record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=TXT&name=$record_name" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Delete record
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json"
}

# ManageEngine CloudDNS TXT record functions (placeholder - to be updated with your script)
# Authenticate with CloudDNS and get access token
get_clouddns_token() {
    local client_id client_secret auth_url auth_response

    client_id=$(cat "$SECRETS_DIR/clouddns_client_id" 2>/dev/null)
    client_secret=$(cat "$SECRETS_DIR/clouddns_client_secret" 2>/dev/null)

    if [[ -z "$client_id" ]] || [[ -z "$client_secret" ]]; then
        echo "CloudDNS credentials not configured" >&2
        return 1
    fi

    auth_url="https://clouddns.manageengine.com/oauth2/token/"

    auth_response=$(curl -s -X POST "$auth_url" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "client_id=$client_id" \
        --data-urlencode "client_secret=$client_secret")

    if echo "$auth_response" | grep -q 'access_token'; then
        echo "$auth_response" | jq -r ".access_token"
        return 0
    else
        echo "CloudDNS authentication failed" >&2
        return 1
    fi
}

# Get zone ID for a domain from CloudDNS
get_clouddns_zone_id() {
    local domain="$1"
    local token="$2"
    local api_url="https://clouddns.manageengine.com/v1/dns/domain/"

    local response zone_id zone_name length

    response=$(curl -s -X GET "$api_url" -H "Authorization: Bearer $token")

    length=$(echo "$response" | jq 'length' 2>/dev/null)

    # First try exact match
    for ((i = 0; i < length; i++)); do
        zone_name=$(echo "$response" | jq -r ".[$i].zone_name")
        if [[ "$domain." == "$zone_name" ]] || [[ "$domain" == "$zone_name" ]]; then
            zone_id=$(echo "$response" | jq -r ".[$i].zone_id")
            echo "$zone_id"
            return 0
        fi
    done

    # Try suffix match (find longest matching zone)
    local best_len=0 best_zone_id=""
    for ((i = 0; i < length; i++)); do
        zone_name=$(echo "$response" | jq -r ".[$i].zone_name")
        local zone_len=${#zone_name}
        if [[ "$domain." == *"$zone_name" ]] && [[ $zone_len -gt $best_len ]]; then
            best_len=$zone_len
            best_zone_id=$(echo "$response" | jq -r ".[$i].zone_id")
        fi
    done

    if [[ -n "$best_zone_id" ]]; then
        echo "$best_zone_id"
        return 0
    fi

    echo "Zone not found for domain: $domain" >&2
    return 1
}

create_clouddns_txt_record() {
    local domain="$1"
    local record_name="$2"
    local record_value="$3"

    local token zone_id api_url spf_txt_api response
    local acme_domain="${record_name}."

    # Get OAuth token
    token=$(get_clouddns_token) || return 1

    # Get zone ID
    zone_id=$(get_clouddns_zone_id "$domain" "$token") || return 1

    api_url="https://clouddns.manageengine.com/v1/dns/domain/"
    spf_txt_api="${api_url}${zone_id}/records/SPF_TXT/"

    # Check if record already exists
    response=$(curl -s -X GET "$spf_txt_api" -H "Authorization: Bearer $token")

    local record_length txt_domain_id=""
    record_length=$(echo "$response" | jq 'length' 2>/dev/null || echo "0")

    for ((i = 0; i < record_length; i++)); do
        local subdomain_name
        subdomain_name=$(echo "$response" | jq -r ".[$i].domain_name")
        if [[ "$subdomain_name" == "$acme_domain" ]]; then
            txt_domain_id=$(echo "$response" | jq -r ".[$i].spf_txt_domain_id")
            break
        fi
    done

    local json_data="[{\"domain_name\": \"$acme_domain\", \"record_type\": \"TXT\", \"records\": [{\"value\": [\"$record_value\"]}]}]"

    if [[ -z "$txt_domain_id" ]]; then
        # Create new record
        response=$(curl -s -X POST "$spf_txt_api" \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            -H "Authorization: Bearer $token" \
            --data-urlencode "config=$json_data")
        echo "Created TXT record for $record_name"
    else
        # Update existing record - add new value
        local existing_record new_json
        existing_record=$(echo "$response" | jq -r ".[] | select(.spf_txt_domain_id == \"$txt_domain_id\")")
        new_json=$(echo "[$existing_record]" | jq ".[0].records[0].value += [\"$record_value\"]")

        response=$(curl -s -X PUT "${spf_txt_api}${txt_domain_id}/" \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            -H "Authorization: Bearer $token" \
            --data-urlencode "config=$new_json")
        echo "Updated TXT record for $record_name"
    fi
}

delete_clouddns_txt_record() {
    local domain="$1"
    local record_name="$2"

    local token zone_id api_url spf_txt_api response
    local acme_domain="${record_name}."

    # Get OAuth token
    token=$(get_clouddns_token) || return 1

    # Get zone ID
    zone_id=$(get_clouddns_zone_id "$domain" "$token") || return 1

    api_url="https://clouddns.manageengine.com/v1/dns/domain/"
    spf_txt_api="${api_url}${zone_id}/records/SPF_TXT/"

    # Find the record
    response=$(curl -s -X GET "$spf_txt_api" -H "Authorization: Bearer $token")

    local record_length txt_domain_id=""
    record_length=$(echo "$response" | jq 'length' 2>/dev/null || echo "0")

    for ((i = 0; i < record_length; i++)); do
        local subdomain_name
        subdomain_name=$(echo "$response" | jq -r ".[$i].domain_name")
        if [[ "$subdomain_name" == "$acme_domain" ]]; then
            txt_domain_id=$(echo "$response" | jq -r ".[$i].spf_txt_domain_id")
            break
        fi
    done

    if [[ -n "$txt_domain_id" ]]; then
        response=$(curl -s -X DELETE "${spf_txt_api}${txt_domain_id}/" \
            -H "Authorization: Bearer $token")
        echo "Deleted TXT record for $record_name"
    else
        echo "TXT record not found for $record_name"
    fi
}

# Route53, DigitalOcean, GoDaddy placeholder functions
create_route53_txt_record() { echo "Route53 TXT record creation - not yet implemented"; }
delete_route53_txt_record() { echo "Route53 TXT record deletion - not yet implemented"; }
create_digitalocean_txt_record() { echo "DigitalOcean TXT record creation - not yet implemented"; }
delete_digitalocean_txt_record() { echo "DigitalOcean TXT record deletion - not yet implemented"; }
create_godaddy_txt_record() { echo "GoDaddy TXT record creation - not yet implemented"; }
delete_godaddy_txt_record() { echo "GoDaddy TXT record deletion - not yet implemented"; }

################################################################################
# Traefik Preparation
################################################################################

traefik_preparation() {
    local traefik_rules_dir="$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"
    local traefik_acme_dir="$DOCKER_DIR/appdata/traefik3/acme"

    # Check if Socket Proxy is installed
    if [[ ! -f "$DOCKER_DIR/compose/socket-proxy.yml" ]]; then
        if dialog --yesno "Socket Proxy is not installed.\n\nIt is recommended to install Socket Proxy first for security.\n\nInstall Socket Proxy now?" 12 60; then
            install_socket_proxy
        fi
    fi

    # Create Traefik directories
    dialog --infobox "Preparing Traefik...\n\nCreating directories..." 6 50
    mkdir -p "$traefik_rules_dir"
    mkdir -p "$traefik_acme_dir"

    # Copy Traefik middleware and configuration files from includes
    if [[ -d "$SCRIPT_DIR/includes/traefik" ]]; then
        dialog --infobox "Preparing Traefik...\n\nCopying middleware files..." 6 50

        # Copy middleware files to rules directory
        for file in "$SCRIPT_DIR/includes/traefik"/*.yml; do
            local filename=$(basename "$file")
            # Skip template files
            if [[ "$filename" != *"-template.yml" ]] && [[ "$filename" != "traefik-static-config-example.yml" ]]; then
                cp "$file" "$traefik_rules_dir/"
            fi
        done
    fi

    # Create acme.json with proper permissions
    touch "$traefik_acme_dir/acme.json"
    chmod 600 "$traefik_acme_dir/acme.json"

    # Set ownership
    chown -R "$PRIMARY_USERNAME:$PRIMARY_USERNAME" "$DOCKER_DIR/appdata/traefik3" 2>/dev/null || true

    # Check if Cloudflare DNS API token is configured
    local cf_token_file="$SECRETS_DIR/cf_dns_api_token"
    if [[ ! -f "$cf_token_file" ]]; then
        if dialog --yesno "Cloudflare DNS API Token not found.\n\nDo you want to configure it now?\n\n(Required for Let's Encrypt SSL certificates)" 12 60; then
            local cf_token
            cf_token=$(dialog --inputbox "Enter your Cloudflare DNS API Token:" 10 60 3>&1 1>&2 2>&3 3>&-)
            if [[ -n "$cf_token" ]]; then
                mkdir -p "$SECRETS_DIR"
                echo "$cf_token" > "$cf_token_file"
                chmod 600 "$cf_token_file"
            fi
        fi
    fi

    # Mark Traefik preparation as done
    TRAEFIK_DONE=true
    touch "$ZOOLANDIA_CONFIG_DIR/traefik_done"

    dialog --msgbox "Traefik preparation complete!\n\nMiddleware files copied to:\n$traefik_rules_dir\n\nNext steps:\n1. Setup Staging or Production\n2. Configure your .env file\n3. Set up Cloudflare DNS" 16 70
}

################################################################################
# Staging and Production Setup
################################################################################

setup_traefik_staging() {
    if ! dialog --yesno "Setup Traefik Staging?\n\nThis will:\n- Configure Traefik to use Let's Encrypt staging certificates\n- Useful for testing without hitting rate limits\n- Certificates will show as 'not trusted' in browser\n\nContinue?" 14 65; then
        return
    fi

    dialog --infobox "Setting up Traefik Staging..." 5 45

    # Install Traefik with staging configuration
    install_app "traefik"

    # Update environment to use staging
    if [[ -f "$DOCKER_DIR/.env" ]]; then
        # Check if ACME_CASERVER exists, if not add it
        if grep -q "^ACME_CASERVER=" "$DOCKER_DIR/.env"; then
            sed -i 's|^ACME_CASERVER=.*|ACME_CASERVER=https://acme-staging-v02.api.letsencrypt.org/directory|' "$DOCKER_DIR/.env"
        else
            echo "ACME_CASERVER=https://acme-staging-v02.api.letsencrypt.org/directory" >> "$DOCKER_DIR/.env"
        fi
    fi

    dialog --msgbox "Traefik Staging setup complete!\n\nUsing Let's Encrypt staging server.\n\nNote: Certificates will show as untrusted.\nSwitch to Production when ready." 12 60
}

setup_traefik_production() {
    if ! dialog --yesno "Setup Traefik Production?\n\nThis will:\n- Configure Traefik to use Let's Encrypt production certificates\n- Certificates will be fully trusted\n- Be careful of rate limits (5 certs/domain/week)\n\nContinue?" 14 65; then
        return
    fi

    dialog --infobox "Setting up Traefik Production..." 5 45

    # Install Traefik with production configuration
    install_app "traefik"

    # Update environment to use production
    if [[ -f "$DOCKER_DIR/.env" ]]; then
        # Check if ACME_CASERVER exists
        if grep -q "^ACME_CASERVER=" "$DOCKER_DIR/.env"; then
            sed -i 's|^ACME_CASERVER=.*|ACME_CASERVER=https://acme-v02.api.letsencrypt.org/directory|' "$DOCKER_DIR/.env"
        else
            echo "ACME_CASERVER=https://acme-v02.api.letsencrypt.org/directory" >> "$DOCKER_DIR/.env"
        fi
    fi

    dialog --msgbox "Traefik Production setup complete!\n\nUsing Let's Encrypt production server.\n\nCertificates will be fully trusted." 12 60
}

################################################################################
# Manage Exposure
################################################################################

manage_exposure() {
    local rules_dir="$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"

    if [[ ! -d "$rules_dir" ]]; then
        dialog --msgbox "No Traefik rules directory found.\n\nRun 'Preparation' first." 10 50
        return
    fi

    # Get list of app rule files (exclude middleware files)
    local apps=()
    for file in "$rules_dir"/*.yml; do
        local filename=$(basename "$file" .yml)
        # Skip middleware and chain files
        if [[ "$filename" != "middlewares-"* ]] && [[ "$filename" != "chain-"* ]] && [[ "$filename" != "tls-"* ]]; then
            local exposure="unknown"
            if grep -q "internal" "$file" 2>/dev/null; then
                exposure="internal"
            fi
            if grep -q "external" "$file" 2>/dev/null; then
                if [[ "$exposure" == "internal" ]]; then
                    exposure="both"
                else
                    exposure="external"
                fi
            fi
            apps+=("$filename" "[$exposure]")
        fi
    done

    if [[ ${#apps[@]} -eq 0 ]]; then
        dialog --msgbox "No app rules found.\n\nUse 'Traefikify' to add apps behind Traefik." 10 50
        return
    fi

    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Manage Exposure" \
        --title "Manage App Exposure" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --menu "Select an app to change its exposure:" 20 70 12 \
        "${apps[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    if [[ -n "$choice" ]]; then
        local new_exposure
        new_exposure=$(dialog --clear --backtitle "$SCRIPT_NAME - Change Exposure" \
            --title "Change Exposure for: $choice" \
            --ok-label "Apply" \
            --cancel-label "Cancel" \
            --radiolist "Select exposure type:" 12 60 3 \
            "internal" "Only accessible internally" off \
            "external" "Accessible from internet" off \
            "both" "Both internal and external" off \
            3>&1 1>&2 2>&3 3>&-) || return

        if [[ -n "$new_exposure" ]]; then
            dialog --msgbox "Exposure for '$choice' would be changed to: $new_exposure\n\n(Full implementation pending)" 10 60
        fi
    fi
}

################################################################################
# Traefikify / Un-Traefikify
################################################################################

traefikify_app() {
    # Get list of installed apps that aren't yet behind Traefik
    local compose_dir="$DOCKER_DIR/compose"
    local rules_dir="$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"

    if [[ ! -d "$compose_dir" ]]; then
        dialog --msgbox "No compose directory found.\n\nInstall some apps first." 10 50
        return
    fi

    local apps=()
    for file in "$compose_dir"/*.yml; do
        local app_name=$(basename "$file" .yml)
        # Check if already has a Traefik rule
        if [[ ! -f "$rules_dir/${app_name}.yml" ]]; then
            apps+=("$app_name" "Add Traefik routing")
        fi
    done

    if [[ ${#apps[@]} -eq 0 ]]; then
        dialog --msgbox "All installed apps are already behind Traefik,\nor no apps are installed." 10 55
        return
    fi

    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Traefikify" \
        --title "Put an App Behind Traefik" \
        --ok-label "Traefikify" \
        --cancel-label "Back" \
        --menu "Select an app to put behind Traefik:" 20 70 12 \
        "${apps[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    if [[ -n "$choice" ]]; then
        # Get app subdomain
        local subdomain
        subdomain=$(dialog --inputbox "Enter subdomain for $choice:\n\n(e.g., 'app' for app.yourdomain.com)" 12 60 "$choice" \
            3>&1 1>&2 2>&3 3>&-) || return

        if [[ -n "$subdomain" ]]; then
            dialog --infobox "Creating Traefik rule for $choice..." 5 50

            # Create basic Traefik rule file
            mkdir -p "$rules_dir"
            cat > "$rules_dir/${choice}.yml" << EOF
http:
  routers:
    ${choice}-rtr:
      rule: "Host(\`${subdomain}.\${DOMAIN_1}\`)"
      entryPoints:
        - websecure
      service: ${choice}-svc
      tls:
        certResolver: dns-cloudflare

  services:
    ${choice}-svc:
      loadBalancer:
        servers:
          - url: "http://${choice}:80"
EOF

            dialog --msgbox "Traefik rule created for $choice!\n\nSubdomain: ${subdomain}.\${DOMAIN_1}\nRule file: $rules_dir/${choice}.yml\n\nRestart Traefik to apply changes." 14 65
        fi
    fi
}

un_traefikify_app() {
    local rules_dir="$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME"

    if [[ ! -d "$rules_dir" ]]; then
        dialog --msgbox "No Traefik rules directory found." 8 50
        return
    fi

    # Get list of app rule files (exclude middleware files)
    local apps=()
    for file in "$rules_dir"/*.yml; do
        local filename=$(basename "$file" .yml)
        # Skip middleware and chain files
        if [[ "$filename" != "middlewares-"* ]] && [[ "$filename" != "chain-"* ]] && [[ "$filename" != "tls-"* ]]; then
            apps+=("$filename" "Remove Traefik routing")
        fi
    done

    if [[ ${#apps[@]} -eq 0 ]]; then
        dialog --msgbox "No app rules found to remove." 8 50
        return
    fi

    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Un-Traefikify" \
        --title "Remove a Traefik File Provider" \
        --ok-label "Remove" \
        --cancel-label "Back" \
        --menu "Select an app to remove from Traefik:" 20 70 12 \
        "${apps[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    if [[ -n "$choice" ]]; then
        if dialog --yesno "Remove Traefik routing for '$choice'?\n\nThis will delete:\n$rules_dir/${choice}.yml" 12 60; then
            rm -f "$rules_dir/${choice}.yml"
            dialog --msgbox "Traefik rule removed for $choice.\n\nRestart Traefik to apply changes." 10 55
        fi
    fi
}

################################################################################
# Domain Passthrough
################################################################################

domain_passthrough() {
    local msg="Domain Passthrough\n\n"
    msg+="This feature allows you to forward traffic from one Traefik\n"
    msg+="instance to another (e.g., from a VPS to your home server).\n\n"
    msg+="Use cases:\n"
    msg+="- VPS as a proxy to home server\n"
    msg+="- Multiple Traefik instances\n"
    msg+="- Split horizon DNS setups\n\n"

    if ! dialog --yesno "${msg}Configure domain passthrough?" 18 65; then
        return
    fi

    local target_host
    target_host=$(dialog --inputbox "Enter the target Traefik host:\n\n(IP address or hostname of the other Traefik instance)" 12 60 \
        3>&1 1>&2 2>&3 3>&-) || return

    local target_port
    target_port=$(dialog --inputbox "Enter the target port:\n\n(Usually 443 for HTTPS)" 10 50 "443" \
        3>&1 1>&2 2>&3 3>&-) || return

    if [[ -n "$target_host" ]] && [[ -n "$target_port" ]]; then
        dialog --msgbox "Domain passthrough configuration:\n\nTarget: ${target_host}:${target_port}\n\n(Full implementation pending - manual config required)" 12 60
    fi
}

################################################################################
# Auth Bypass
################################################################################

set_auth_bypass() {
    local msg="Auth Bypass Key\n\n"
    msg+="Set a secret key that can be used to bypass forward authentication\n"
    msg+="(e.g., Authelia, Authentik) for specific requests.\n\n"
    msg+="This is useful for:\n"
    msg+="- API access without SSO\n"
    msg+="- Webhooks and callbacks\n"
    msg+="- Service-to-service communication\n\n"

    local current_key=""
    local bypass_file="$SECRETS_DIR/traefik_auth_bypass_key"
    if [[ -f "$bypass_file" ]]; then
        current_key=$(cat "$bypass_file")
        msg+="Current key is set (hidden for security).\n"
    else
        msg+="No bypass key is currently set.\n"
    fi

    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME - Auth Bypass" \
        --title "Traefik Forward Auth Bypass Key" \
        --ok-label "Select" \
        --cancel-label "Back" \
        --menu "$msg" 20 70 3 \
        "Set Key" "Enter a new bypass key" \
        "Generate" "Generate a random bypass key" \
        "Remove" "Remove the bypass key" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$choice" in
        "Set Key")
            local new_key
            new_key=$(dialog --inputbox "Enter the auth bypass key:" 10 60 \
                3>&1 1>&2 2>&3 3>&-) || return
            if [[ -n "$new_key" ]]; then
                mkdir -p "$SECRETS_DIR"
                echo "$new_key" > "$bypass_file"
                chmod 600 "$bypass_file"
                dialog --msgbox "Auth bypass key saved!\n\nFile: $bypass_file" 10 55
            fi
            ;;
        "Generate")
            local generated_key
            generated_key=$(openssl rand -hex 32)
            mkdir -p "$SECRETS_DIR"
            echo "$generated_key" > "$bypass_file"
            chmod 600 "$bypass_file"
            dialog --msgbox "Generated auth bypass key:\n\n$generated_key\n\nSaved to: $bypass_file" 14 70
            ;;
        "Remove")
            if [[ -f "$bypass_file" ]]; then
                rm -f "$bypass_file"
                dialog --msgbox "Auth bypass key removed." 8 45
            else
                dialog --msgbox "No bypass key to remove." 8 45
            fi
            ;;
    esac
}
