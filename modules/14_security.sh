#!/bin/bash
################################################################################
# Zoolandia - Security Management Module
################################################################################
# Description: Security and authentication provider functions
# Version: 1.0.0
# Dependencies: 00_init.sh, 01_config.sh
################################################################################

show_security_menu() {
    while true; do
        local menu_items=(
            "Install Authelia" "Install Authelia 2FA authentication"
            "Install Authentik" "Install Authentik SSO"
            "Install TinyAuth" "Install TinyAuth lightweight authentication"
            "Install Google OAuth" "Install Google OAuth proxy"
            "Install CrowdSec" "Install CrowdSec threat protection"
            "Install Bitwarden" "Install Vaultwarden password manager"
            "Manage Auth" "Manage authentication providers"
            "Back" "Return to main menu"
        )

        local choice
        choice=$(dialog --clear --backtitle "$SCRIPT_NAME Security" \
            --title "Security Menu" \
            --ok-label "Select" \
            --cancel-label "Back" \
            --menu "Select an option:" 22 70 10 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Install Authelia") install_authelia ;;
            "Install Authentik") install_authentik ;;
            "Install TinyAuth") install_tinyauth ;;
            "Install Google OAuth") install_google_oauth ;;
            "Install CrowdSec") install_crowdsec ;;
            "Install Bitwarden") install_bitwarden ;;
            "Manage Auth") manage_auth ;;
            "Back") return ;;
        esac
    done
}

install_authelia() {
    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment file not found!\n\nPlease configure environment first (Prerequisites > Environment)" 10 60
        return 1
    fi

    if ! docker info &>/dev/null; then
        dialog --msgbox "Error: Docker is not running!\n\nPlease install and start Docker first." 10 60
        return 1
    fi

    # Check if Traefik and Redis are required
    if ! dialog --yesno "Install Authelia?\n\nAuthelia provides:\n- Single Sign-On (SSO)\n- Two-Factor Authentication (2FA)\n- LDAP/File-based authentication\n\nRequires:\n- Traefik (reverse proxy)\n- Redis (session storage)\n\nContinue with installation?" 18 70; then
        return
    fi

    dialog --infobox "Installing Authelia...\n\nThis may take a few moments." 8 50

    # Create directories
    mkdir -p "$DOCKER_DIR/appdata/authelia"
    mkdir -p "$DOCKER_DIR/compose"
    mkdir -p "$SECRETS_DIR"

    # Generate secrets
    local jwt_secret=$(openssl rand -base64 32)
    local session_secret=$(openssl rand -base64 64)
    local storage_key=$(openssl rand -base64 32)

    echo "$jwt_secret" > "$SECRETS_DIR/authelia_jwt_secret"
    echo "$session_secret" > "$SECRETS_DIR/authelia_session_secret"
    echo "$storage_key" > "$SECRETS_DIR/authelia_storage_encryption_key"
    chmod 600 "$SECRETS_DIR"/authelia_*

    # Copy compose file
    if [[ -f "$SCRIPT_DIR/compose/authelia.yml" ]]; then
        cp "$SCRIPT_DIR/compose/authelia.yml" "$DOCKER_DIR/compose/"
    else
        local display_authelia_path=$(display_path "$SCRIPT_DIR/compose/authelia.yml")
        dialog --msgbox "Error: Authelia compose file not found at:\n$display_authelia_path" 10 70
        return 1
    fi

    # Copy configuration files
    if [[ -d "$SCRIPT_DIR/includes/authelia" ]]; then
        cp -r "$SCRIPT_DIR/includes/authelia/"* "$DOCKER_DIR/appdata/authelia/" 2>/dev/null || true
    fi

    # Copy middleware files to Traefik rules directory
    if [[ -d "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME" ]]; then
        [[ -f "$SCRIPT_DIR/includes/authelia/middlewares-authelia.yml" ]] && \
            cp "$SCRIPT_DIR/includes/authelia/middlewares-authelia.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
        [[ -f "$SCRIPT_DIR/includes/authelia/chain-authelia.yml" ]] && \
            cp "$SCRIPT_DIR/includes/authelia/chain-authelia.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
    fi

    # Add to .env if not already present
    if ! grep -q "AUTHELIA_PORT" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# Authelia Configuration" >> "$ENV_FILE"
        echo "AUTHELIA_PORT=9091" >> "$ENV_FILE"
    fi

    # Add secrets to compose secrets section
    if [[ -f "$DOCKER_DIR/docker-compose.yml" ]]; then
        if ! grep -q "authelia_jwt_secret" "$DOCKER_DIR/docker-compose.yml"; then
            cat >> "$DOCKER_DIR/docker-compose.yml" << 'EOF'

secrets:
  authelia_jwt_secret:
    file: $DOCKERDIR/secrets/authelia_jwt_secret
  authelia_session_secret:
    file: $DOCKERDIR/secrets/authelia_session_secret
  authelia_storage_encryption_key:
    file: $DOCKERDIR/secrets/authelia_storage_encryption_key
EOF
        fi
    fi

    # Start the container
    cd "$DOCKER_DIR" || return 1

    if docker compose -f compose/authelia.yml up -d 2>&1 | tee /tmp/authelia_install.log; then
        local display_users_path=$(display_path "$DOCKER_DIR/appdata/authelia/users.yml")
        local display_config_path=$(display_path "$DOCKER_DIR/appdata/authelia/configuration.yml")
        dialog --msgbox "Authelia installed successfully!\n\nAccess at: https://authelia.$DOMAIN_1\n\nNext steps:\n1. Configure users in: $display_users_path\n2. Review configuration in: $display_config_path\n3. Restart container after config changes\n\nContainer: authelia" 18 70
    else
        dialog --msgbox "Error installing Authelia!\n\nCheck logs:\n/tmp/authelia_install.log\n\nOr run: docker logs authelia" 12 70
        return 1
    fi
}

install_authentik() {
    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment file not found!\n\nPlease configure environment first (Prerequisites > Environment)" 10 60
        return 1
    fi

    if ! docker info &>/dev/null; then
        dialog --msgbox "Error: Docker is not running!\n\nPlease install and start Docker first." 10 60
        return 1
    fi

    if ! dialog --yesno "Install Authentik?\n\nAuthentik provides:\n- Identity Provider (IdP)\n- Single Sign-On (SSO)\n- LDAP/OAuth/SAML support\n- User management\n\nRequires:\n- Traefik (reverse proxy)\n- PostgreSQL (database)\n- Redis (cache)\n\nContinue with installation?" 20 70; then
        return
    fi

    dialog --infobox "Installing Authentik...\n\nThis may take a few moments." 8 50

    # Create directories
    mkdir -p "$DOCKER_DIR/appdata/authentik/media"
    mkdir -p "$DOCKER_DIR/appdata/authentik/custom-templates"
    mkdir -p "$DOCKER_DIR/compose"
    mkdir -p "$SECRETS_DIR"

    # Generate secrets
    local pg_password=$(openssl rand -base64 32)
    local secret_key=$(openssl rand -base64 50)

    echo "authentik" > "$SECRETS_DIR/authentik_postgresql_user"
    echo "$pg_password" > "$SECRETS_DIR/authentik_postgresql_password"
    echo "$secret_key" > "$SECRETS_DIR/authentik_secret_key"
    chmod 600 "$SECRETS_DIR"/authentik_*

    # Copy compose files
    if [[ -f "$SCRIPT_DIR/compose/authentik.yml" ]]; then
        cp "$SCRIPT_DIR/compose/authentik.yml" "$DOCKER_DIR/compose/"
    else
        dialog --msgbox "Error: Authentik compose file not found!" 10 60
        return 1
    fi

    # Copy worker compose if exists
    [[ -f "$SCRIPT_DIR/compose/authentik-worker.yml" ]] && \
        cp "$SCRIPT_DIR/compose/authentik-worker.yml" "$DOCKER_DIR/compose/"

    # Copy middleware files
    if [[ -d "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME" ]]; then
        [[ -f "$SCRIPT_DIR/includes/authentik/middlewares-authentik.yml" ]] && \
            cp "$SCRIPT_DIR/includes/authentik/middlewares-authentik.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
        [[ -f "$SCRIPT_DIR/includes/authentik/chain-authentik.yml" ]] && \
            cp "$SCRIPT_DIR/includes/authentik/chain-authentik.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
    fi

    # Add to .env
    if ! grep -q "AUTHENTIK_PORT" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# Authentik Configuration" >> "$ENV_FILE"
        echo "AUTHENTIK_PORT=9000" >> "$ENV_FILE"
        echo "AUTHENTIK_REDIS__HOST=redis" >> "$ENV_FILE"
        echo "AUTHENTIK_POSTGRESQL__HOST=postgresql" >> "$ENV_FILE"
        echo "AUTHENTIK_POSTGRESQL__NAME=authentik" >> "$ENV_FILE"
        echo "AUTHENTIK_POSTGRESQL__USER=authentik" >> "$ENV_FILE"
        echo "AUTHENTIK_POSTGRESQL__PASSWORD=$pg_password" >> "$ENV_FILE"
        echo "AUTHENTIK_SECRET_KEY=$secret_key" >> "$ENV_FILE"
    fi

    # Start the container
    cd "$DOCKER_DIR" || return 1

    if docker compose -f compose/authentik.yml up -d 2>&1 | tee /tmp/authentik_install.log; then
        dialog --msgbox "Authentik installed successfully!\n\nAccess at: https://authentik.$DOMAIN_1\n\nInitial setup:\n1. Wait 30-60 seconds for initialization\n2. Create admin account on first visit\n3. Configure applications and providers\n\nContainer: authentik\nWorker: authentik-worker" 18 70
    else
        dialog --msgbox "Error installing Authentik!\n\nCheck logs:\n/tmp/authentik_install.log\n\nOr run: docker logs authentik" 12 70
        return 1
    fi
}

install_tinyauth() {
    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment file not found!\n\nPlease configure environment first (Prerequisites > Environment)" 10 60
        return 1
    fi

    if ! docker info &>/dev/null; then
        dialog --msgbox "Error: Docker is not running!\n\nPlease install and start Docker first." 10 60
        return 1
    fi

    if ! dialog --yesno "Install TinyAuth?\n\nTinyAuth provides:\n- Lightweight SSO and 2FA\n- OAuth integration\n- Simple file-based user management\n\nRequires:\n- Traefik (reverse proxy)\n\nContinue with installation?" 16 70; then
        return
    fi

    dialog --infobox "Installing TinyAuth...\n\nThis may take a few moments." 8 50

    # Create directories
    mkdir -p "$DOCKER_DIR/appdata/tinyauth"
    mkdir -p "$DOCKER_DIR/compose"
    mkdir -p "$SECRETS_DIR"

    # Generate secret
    local secret=$(openssl rand -base64 32)
    echo "$secret" > "$SECRETS_DIR/tinyauth_secret"
    chmod 600 "$SECRETS_DIR/tinyauth_secret"

    # Copy compose file
    if [[ -f "$SCRIPT_DIR/compose/tinyauth.yml" ]]; then
        cp "$SCRIPT_DIR/compose/tinyauth.yml" "$DOCKER_DIR/compose/"
    else
        dialog --msgbox "Error: TinyAuth compose file not found!" 10 60
        return 1
    fi

    # Copy or create users file
    if [[ -f "$SCRIPT_DIR/includes/tinyauth/users_file" ]]; then
        cp "$SCRIPT_DIR/includes/tinyauth/users_file" "$DOCKER_DIR/appdata/tinyauth/"
    else
        # Create default users file
        cat > "$DOCKER_DIR/appdata/tinyauth/users_file" << 'EOF'
# TinyAuth Users File
# Format: username:bcrypt_hashed_password
# Generate password: htpasswd -nbB username password
# Or use online bcrypt generator

# Example (password: changeme):
# admin:$2y$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
EOF
    fi

    # Copy middleware files
    if [[ -d "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME" ]]; then
        [[ -f "$SCRIPT_DIR/includes/tinyauth/middlewares-tinyauth.yml" ]] && \
            cp "$SCRIPT_DIR/includes/tinyauth/middlewares-tinyauth.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
        [[ -f "$SCRIPT_DIR/includes/tinyauth/chain-tinyauth.yml" ]] && \
            cp "$SCRIPT_DIR/includes/tinyauth/chain-tinyauth.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
    fi

    # Add to .env
    if ! grep -q "TINYAUTH_PORT" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# TinyAuth Configuration" >> "$ENV_FILE"
        echo "TINYAUTH_PORT=3000" >> "$ENV_FILE"
    fi

    # Start the container
    cd "$DOCKER_DIR" || return 1

    if docker compose -f compose/tinyauth.yml up -d 2>&1 | tee /tmp/tinyauth_install.log; then
        local display_tinyauth_users=$(display_path "$DOCKER_DIR/appdata/tinyauth/users_file")
        dialog --msgbox "TinyAuth installed successfully!\n\nAccess at: https://tinyauth.$DOMAIN_1\n\nNext steps:\n1. Edit users file: $display_tinyauth_users\n2. Generate bcrypt passwords using:\n   htpasswd -nbB username password\n3. Restart container after adding users\n\nContainer: tinyauth" 18 70
    else
        dialog --msgbox "Error installing TinyAuth!\n\nCheck logs:\n/tmp/tinyauth_install.log\n\nOr run: docker logs tinyauth" 12 70
        return 1
    fi
}

install_google_oauth() {
    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment file not found!\n\nPlease configure environment first (Prerequisites > Environment)" 10 60
        return 1
    fi

    if ! docker info &>/dev/null; then
        dialog --msgbox "Error: Docker is not running!\n\nPlease install and start Docker first." 10 60
        return 1
    fi

    if ! dialog --yesno "Install Google OAuth?\n\nGoogle OAuth provides:\n- SSO using Google accounts\n- OAuth 2.0 forward authentication\n- Domain/email whitelist support\n\nRequires:\n- Traefik (reverse proxy)\n- Google Cloud OAuth credentials\n\nYou'll need:\n1. Google Cloud Project\n2. OAuth 2.0 Client ID and Secret\n\nContinue with installation?" 20 70; then
        return
    fi

    # Prompt for OAuth credentials
    local client_id
    local client_secret
    local whitelist

    client_id=$(dialog --inputbox "Enter Google OAuth Client ID:\n\n(From Google Cloud Console > APIs & Services > Credentials)" 12 70 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$client_id" ]]; then
        dialog --msgbox "Installation cancelled: Client ID is required." 8 50
        return
    fi

    client_secret=$(dialog --passwordbox "Enter Google OAuth Client Secret:" 10 70 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$client_secret" ]]; then
        dialog --msgbox "Installation cancelled: Client Secret is required." 8 50
        return
    fi

    whitelist=$(dialog --inputbox "Enter allowed email domains or addresses:\n(Comma-separated, e.g., example.com,user@domain.com)\n\nLeave empty to allow all Google accounts." 12 70 3>&1 1>&2 2>&3 3>&-)

    dialog --infobox "Installing Google OAuth...\n\nThis may take a few moments." 8 50

    # Create directories
    mkdir -p "$DOCKER_DIR/compose"
    mkdir -p "$SECRETS_DIR"

    # Generate secret and create config
    local oauth_secret=$(openssl rand -base64 16)

    cat > "$SECRETS_DIR/oauth_secrets" << EOF
providers.google.client-id=$client_id
providers.google.client-secret=$client_secret
secret=$oauth_secret
EOF

    if [[ -n "$whitelist" ]]; then
        echo "whitelist=$whitelist" >> "$SECRETS_DIR/oauth_secrets"
    fi

    chmod 600 "$SECRETS_DIR/oauth_secrets"

    # Copy compose file
    if [[ -f "$SCRIPT_DIR/compose/oauth.yml" ]]; then
        cp "$SCRIPT_DIR/compose/oauth.yml" "$DOCKER_DIR/compose/"
    else
        dialog --msgbox "Error: OAuth compose file not found!" 10 60
        return 1
    fi

    # Copy middleware files
    if [[ -d "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME" ]]; then
        [[ -f "$SCRIPT_DIR/includes/oauth/middlewares-oauth.yml" ]] && \
            cp "$SCRIPT_DIR/includes/oauth/middlewares-oauth.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
        [[ -f "$SCRIPT_DIR/includes/oauth/chain-oauth.yml" ]] && \
            cp "$SCRIPT_DIR/includes/oauth/chain-oauth.yml" "$DOCKER_DIR/appdata/traefik3/rules/$HOSTNAME/"
    fi

    # Add to .env
    if ! grep -q "OAUTH_PORT" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# Google OAuth Configuration" >> "$ENV_FILE"
        echo "OAUTH_PORT=4181" >> "$ENV_FILE"
    fi

    # Start the container
    cd "$DOCKER_DIR" || return 1

    if docker compose -f compose/oauth.yml up -d 2>&1 | tee /tmp/oauth_install.log; then
        local display_oauth_secrets=$(display_path "$SECRETS_DIR/oauth_secrets")
        dialog --msgbox "Google OAuth installed successfully!\n\nAccess at: https://oauth.$DOMAIN_1\n\nImportant:\n1. Add redirect URI to Google Cloud Console:\n   https://oauth.$DOMAIN_1/_oauth\n2. Update whitelist in: $display_oauth_secrets\n3. Restart container after config changes\n\nContainer: oauth" 18 70
    else
        dialog --msgbox "Error installing Google OAuth!\n\nCheck logs:\n/tmp/oauth_install.log\n\nOr run: docker logs oauth" 12 70
        return 1
    fi
}

install_crowdsec() {
    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment file not found!\n\nPlease configure environment first (Prerequisites > Environment)" 10 60
        return 1
    fi

    if ! docker info &>/dev/null; then
        dialog --msgbox "Error: Docker is not running!\n\nPlease install and start Docker first." 10 60
        return 1
    fi

    if ! dialog --yesno "Install CrowdSec?\n\nCrowdSec provides:\n- Intrusion Prevention System (IPS)\n- Threat detection and blocking\n- Community threat intelligence\n- Traefik integration\n\nRequires:\n- Traefik (for bouncer integration)\n\nOptional components:\n- Traefik Bouncer\n- Cloudflare Bouncer\n\nContinue with installation?" 20 70; then
        return
    fi

    dialog --infobox "Installing CrowdSec...\n\nThis may take a few moments." 8 50

    # Create directories
    mkdir -p "$DOCKER_DIR/appdata/crowdsec/data"
    mkdir -p "$DOCKER_DIR/appdata/crowdsec/config"
    mkdir -p "$DOCKER_DIR/logs/$HOSTNAME"
    mkdir -p "$DOCKER_DIR/compose"

    # Copy compose file
    if [[ -f "$SCRIPT_DIR/compose/crowdsec.yml" ]]; then
        cp "$SCRIPT_DIR/compose/crowdsec.yml" "$DOCKER_DIR/compose/"
    else
        dialog --msgbox "Error: CrowdSec compose file not found!" 10 60
        return 1
    fi

    # Copy configuration files
    if [[ -d "$SCRIPT_DIR/includes/crowdsec" ]]; then
        cp -r "$SCRIPT_DIR/includes/crowdsec/"*.yaml "$DOCKER_DIR/appdata/crowdsec/config/" 2>/dev/null || true
    fi

    # Add to .env
    if ! grep -q "CROWDSEC_PORT" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# CrowdSec Configuration" >> "$ENV_FILE"
        echo "CROWDSEC_PORT=8080" >> "$ENV_FILE"
        echo "HOSTNAME=$HOSTNAME" >> "$ENV_FILE"
    fi

    # Start the container
    cd "$DOCKER_DIR" || return 1

    if docker compose -f compose/crowdsec.yml up -d 2>&1 | tee /tmp/crowdsec_install.log; then
        sleep 3

        # Ask about Traefik bouncer
        if dialog --yesno "CrowdSec installed successfully!\n\nWould you like to install the Traefik Bouncer?\n\nThis integrates CrowdSec with Traefik to automatically block malicious IPs." 12 70; then
            if [[ -f "$SCRIPT_DIR/compose/traefik-bouncer.yml" ]]; then
                cp "$SCRIPT_DIR/compose/traefik-bouncer.yml" "$DOCKER_DIR/compose/"

                # Generate bouncer API key
                local api_key
                api_key=$(docker exec crowdsec cscli bouncers add traefik-bouncer 2>&1 | grep -oP 'API key.*:\s*\K[a-zA-Z0-9]+' || echo "")

                if [[ -n "$api_key" ]]; then
                    echo "CROWDSEC_BOUNCER_KEY=$api_key" >> "$ENV_FILE"
                    docker compose -f compose/traefik-bouncer.yml up -d 2>&1 | tee -a /tmp/crowdsec_install.log
                    dialog --msgbox "CrowdSec and Traefik Bouncer installed!\n\nContainers:\n- crowdsec\n- traefik-bouncer\n\nNext steps:\n1. Register on CrowdSec Hub (optional):\n   docker exec crowdsec cscli console enroll [key]\n2. View metrics: http://$SERVER_IP:6060\n3. Check decisions:\n   docker exec crowdsec cscli decisions list" 18 70
                else
                    dialog --msgbox "CrowdSec installed but failed to generate bouncer key.\n\nManually add bouncer:\ndocker exec crowdsec cscli bouncers add traefik-bouncer\n\nThen update .env with the API key." 12 70
                fi
            fi
        else
            dialog --msgbox "CrowdSec installed successfully!\n\nContainer: crowdsec\n\nNext steps:\n1. Register on CrowdSec Hub (optional):\n   docker exec crowdsec cscli console enroll [key]\n2. View metrics: http://$SERVER_IP:$CROWDSEC_PORT\n3. Install bouncer from Security menu later\n4. Check decisions:\n   docker exec crowdsec cscli decisions list" 18 70
        fi
    else
        dialog --msgbox "Error installing CrowdSec!\n\nCheck logs:\n/tmp/crowdsec_install.log\n\nOr run: docker logs crowdsec" 12 70
        return 1
    fi
}

install_bitwarden() {
    # Check prerequisites
    if [[ ! -f "$ENV_FILE" ]]; then
        dialog --msgbox "Error: Environment file not found!\n\nPlease configure environment first (Prerequisites > Environment)" 10 60
        return 1
    fi

    if ! docker info &>/dev/null; then
        dialog --msgbox "Error: Docker is not running!\n\nPlease install and start Docker first." 10 60
        return 1
    fi

    if ! dialog --yesno "Install Vaultwarden (Bitwarden)?\n\nVaultwarden provides:\n- Self-hosted password manager\n- Bitwarden-compatible server\n- Secure password vault\n- Browser extensions support\n- Mobile app support\n\nRequires:\n- Traefik (reverse proxy) - optional\n\nContinue with installation?" 18 70; then
        return
    fi

    # Prompt for subdomain
    local subdomain
    subdomain=$(dialog --inputbox "Enter subdomain for Vaultwarden:\n(e.g., 'bitwarden' for bitwarden.$DOMAIN_1)" 10 70 "bitwarden" 3>&1 1>&2 2>&3 3>&-)
    if [[ -z "$subdomain" ]]; then
        dialog --msgbox "Installation cancelled: Subdomain is required." 8 50
        return
    fi

    # Ask if they want to set admin token
    local admin_token=""
    if dialog --yesno "Set up admin panel access?\n\nThe admin panel allows you to:\n- Manage users\n- View server statistics\n- Configure server settings\n\nRecommended: Yes" 12 70; then
        admin_token=$(openssl rand -base64 32)
    fi

    dialog --infobox "Installing Vaultwarden...\n\nThis may take a few moments." 8 50

    # Create directories
    mkdir -p "$DOCKER_DIR/appdata/vaultwarden/data"
    mkdir -p "$DOCKER_DIR/compose"

    # Copy compose file
    if [[ -f "$SCRIPT_DIR/compose/vaultwarden.yml" ]]; then
        cp "$SCRIPT_DIR/compose/vaultwarden.yml" "$DOCKER_DIR/compose/"

        # Update subdomain placeholder
        sed -i "s|SUBDOMAIN-PLACEHOLDER|$subdomain|g" "$DOCKER_DIR/compose/vaultwarden.yml"

        # Update admin token if set
        if [[ -n "$admin_token" ]]; then
            sed -i "s|# - ADMIN_TOKEN=ADMIN-TOKEN-PLACEHOLDER|- ADMIN_TOKEN=$admin_token|g" "$DOCKER_DIR/compose/vaultwarden.yml"
        fi
    else
        dialog --msgbox "Error: Vaultwarden compose file not found!" 10 60
        return 1
    fi

    # Add to .env
    if ! grep -q "VAULTWARDEN_PORT" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# Vaultwarden Configuration" >> "$ENV_FILE"
        echo "VAULTWARDEN_PORT=8087" >> "$ENV_FILE"
    fi

    # Start the container
    cd "$DOCKER_DIR" || return 1

    if docker compose -f compose/vaultwarden.yml up -d 2>&1 | tee /tmp/vaultwarden_install.log; then
        local access_info="Access at: https://$subdomain.$DOMAIN_1"
        if [[ -z "$DOMAIN_1" ]]; then
            access_info="Access at: http://$SERVER_IP:8087"
        fi

        local admin_info=""
        if [[ -n "$admin_token" ]]; then
            admin_info="\n\nAdmin Panel:\n- URL: https://$subdomain.$DOMAIN_1/admin\n- Token: $admin_token\n\nSave this token - it's shown only once!"
        fi

        dialog --msgbox "Vaultwarden installed successfully!\n\n$access_info\n\nNext steps:\n1. Create your first account (becomes admin)\n2. Install Bitwarden browser extension\n3. Configure server URL in extension\n4. Start storing passwords!$admin_info\n\nContainer: vaultwarden" 22 75
    else
        dialog --msgbox "Error installing Vaultwarden!\n\nCheck logs:\n/tmp/vaultwarden_install.log\n\nOr run: docker logs vaultwarden" 12 70
        return 1
    fi
}

manage_auth() {
    while true; do
        # Detect installed auth providers
        local authelia_status="\Z1Not Installed\Zn"
        local authentik_status="\Z1Not Installed\Zn"
        local tinyauth_status="\Z1Not Installed\Zn"
        local oauth_status="\Z1Not Installed\Zn"
        local vaultwarden_status="\Z1Not Installed\Zn"

        # Check if containers are running
        if docker ps --format '{{.Names}}' | grep -q "^authelia$"; then
            authelia_status="\Z2Running\Zn"
        elif docker ps -a --format '{{.Names}}' | grep -q "^authelia$"; then
            authelia_status="\Z3Stopped\Zn"
        fi

        if docker ps --format '{{.Names}}' | grep -q "^authentik$"; then
            authentik_status="\Z2Running\Zn"
        elif docker ps -a --format '{{.Names}}' | grep -q "^authentik$"; then
            authentik_status="\Z3Stopped\Zn"
        fi

        if docker ps --format '{{.Names}}' | grep -q "^tinyauth$"; then
            tinyauth_status="\Z2Running\Zn"
        elif docker ps -a --format '{{.Names}}' | grep -q "^tinyauth$"; then
            tinyauth_status="\Z3Stopped\Zn"
        fi

        if docker ps --format '{{.Names}}' | grep -q "^oauth$"; then
            oauth_status="\Z2Running\Zn"
        elif docker ps -a --format '{{.Names}}' | grep -q "^oauth$"; then
            oauth_status="\Z3Stopped\Zn"
        fi

        if docker ps --format '{{.Names}}' | grep -q "^vaultwarden$"; then
            vaultwarden_status="\Z2Running\Zn"
        elif docker ps -a --format '{{.Names}}' | grep -q "^vaultwarden$"; then
            vaultwarden_status="\Z3Stopped\Zn"
        fi

        local menu_items=(
            "Authelia" "Status: $authelia_status"
            "Authentik" "Status: $authentik_status"
            "TinyAuth" "Status: $tinyauth_status"
            "Google OAuth" "Status: $oauth_status"
            "Vaultwarden" "Status: $vaultwarden_status"
            "View Configs" "View authentication configuration files"
            "Regenerate Secrets" "Regenerate authentication secrets"
            "Back" "Return to Security menu"
        )

        local choice
        choice=$(dialog --clear --colors --backtitle "$SCRIPT_NAME - Manage Authentication" \
            --title "Authentication Provider Management" \
            --menu "Select a provider to manage:" 20 70 10 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3 3>&-) || return

        case "$choice" in
            "Authelia")
                manage_auth_provider "authelia" "Authelia" "$DOCKER_DIR/appdata/authelia"
                ;;
            "Authentik")
                manage_auth_provider "authentik" "Authentik" "$DOCKER_DIR/appdata/authentik"
                ;;
            "TinyAuth")
                manage_auth_provider "tinyauth" "TinyAuth" "$DOCKER_DIR/appdata/tinyauth"
                ;;
            "Google OAuth")
                manage_auth_provider "oauth" "Google OAuth" "$SECRETS_DIR/oauth_secrets"
                ;;
            "Vaultwarden")
                manage_auth_provider "vaultwarden" "Vaultwarden" "$DOCKER_DIR/appdata/vaultwarden"
                ;;
            "View Configs")
                view_auth_configs
                ;;
            "Regenerate Secrets")
                regenerate_auth_secrets
                ;;
            "Back")
                return
                ;;
        esac
    done
}

manage_auth_provider() {
    local container_name="$1"
    local display_name="$2"
    local config_path="$3"

    # Check if container exists
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        dialog --msgbox "$display_name is not installed.\n\nInstall it from the Security menu first." 10 60
        return
    fi

    # Get container status
    local status="Stopped"
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        status="Running"
    fi

    local action_menu=(
        "Start" "Start the $display_name container"
        "Stop" "Stop the $display_name container"
        "Restart" "Restart the $display_name container"
        "View Logs" "View container logs"
        "Edit Config" "Edit configuration files"
        "Remove" "Remove $display_name completely"
        "Back" "Return to auth management"
    )

    local action
    action=$(dialog --clear --backtitle "$SCRIPT_NAME - $display_name Management" \
        --title "$display_name (Status: $status)" \
        --menu "Select an action:" 18 70 8 \
        "${action_menu[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$action" in
        "Start")
            docker start "$container_name" 2>&1 | tee /tmp/auth_action.log
            if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
                dialog --msgbox "$display_name started successfully!" 8 50
            else
                dialog --msgbox "Failed to start $display_name.\n\nCheck: /tmp/auth_action.log" 10 60
            fi
            ;;
        "Stop")
            docker stop "$container_name" 2>&1 | tee /tmp/auth_action.log
            dialog --msgbox "$display_name stopped." 8 50
            ;;
        "Restart")
            dialog --infobox "Restarting $display_name..." 5 40
            docker restart "$container_name" 2>&1 | tee /tmp/auth_action.log
            sleep 2
            dialog --msgbox "$display_name restarted." 8 50
            ;;
        "View Logs")
            docker logs --tail 100 "$container_name" 2>&1 | dialog --programbox "$display_name Logs" 24 80
            ;;
        "Edit Config")
            if [[ -d "$config_path" ]]; then
                local config_files=$(find "$config_path" -type f -name "*.yml" -o -name "*.yaml" -o -name "*.conf" -o -name "*_file" 2>/dev/null | head -20)
                if [[ -n "$config_files" ]]; then
                    dialog --msgbox "Configuration files location:\n$config_path\n\nEdit files with your preferred editor:\n\n$config_files\n\nAfter editing, restart the container from this menu." 20 75
                else
                    dialog --msgbox "No configuration files found in:\n$config_path" 10 60
                fi
            else
                dialog --msgbox "Configuration directory not found:\n$config_path" 10 60
            fi
            ;;
        "Remove")
            if dialog --yesno "Remove $display_name?\n\nThis will:\n- Stop the container\n- Remove the container\n- Keep configuration files\n\nConfiguration in: $config_path\n\nContinue?" 14 70; then
                docker stop "$container_name" 2>/dev/null
                docker rm "$container_name" 2>/dev/null
                dialog --msgbox "$display_name container removed.\n\nConfiguration files preserved in:\n$config_path\n\nTo fully remove, manually delete the directory." 12 70
            fi
            ;;
        "Back")
            return
            ;;
    esac
}

# Placeholder for the remaining large functions - these are complex and would need separate implementation
view_auth_configs() {
    dialog --msgbox "Feature: View Auth Configs\n\nTo be implemented - this is a complex function with ~200 lines" 10 70
}

view_crowdsec_configs() {
    dialog --msgbox "Feature: View CrowdSec Configs\n\nTo be implemented" 10 70
}

manage_traefik_bouncer() {
    dialog --msgbox "Feature: Manage Traefik Bouncer\n\nTo be implemented - this is a complex function with ~120 lines" 10 70
}

manage_firewall_bouncer() {
    dialog --msgbox "Feature: Manage Firewall Bouncer\n\nTo be implemented - this is a complex function with ~160 lines" 10 70
}

view_provider_configs() {
    dialog --msgbox "Feature: View Provider Configs\n\nTo be implemented" 10 70
}

view_secrets_configs() {
    dialog --msgbox "Feature: View Secrets Configs\n\nTo be implemented" 10 70
}

edit_config_file() {
    dialog --msgbox "Feature: Edit Config File\n\nTo be implemented - this is a complex function with ~100 lines" 10 70
}

restart_related_container() {
    local file_path="$1"
    local container_name=""

    # Determine which container to restart based on file path
    if [[ "$file_path" == *"/authelia/"* ]]; then
        container_name="authelia"
    elif [[ "$file_path" == *"/authentik/"* ]]; then
        container_name="authentik"
    elif [[ "$file_path" == *"/tinyauth/"* ]]; then
        container_name="tinyauth"
    elif [[ "$file_path" == *"oauth"* ]]; then
        container_name="oauth"
    elif [[ "$file_path" == *"/vaultwarden/"* ]]; then
        container_name="vaultwarden"
    elif [[ "$file_path" == *"/traefik/"* ]]; then
        container_name="traefik"
    fi

    if [[ -n "$container_name" ]]; then
        dialog --infobox "Restarting $container_name container...\n\nPlease wait..." 6 50

        if docker restart "$container_name" 2>&1 | tee /tmp/container_restart.log; then
            sleep 2
            dialog --msgbox "Container '$container_name' restarted successfully!\n\nChanges should now be active." 10 60
        else
            dialog --msgbox "Failed to restart '$container_name'!\n\nCheck logs:\ndocker logs $container_name\n\nOr see: /tmp/container_restart.log" 12 70
        fi
    else
        dialog --msgbox "Could not determine which container to restart.\n\nPlease manually restart the appropriate container:\ndocker restart <container_name>" 12 70
    fi
}

regenerate_auth_secrets() {
    local provider_menu=(
        "Authelia" "Regenerate Authelia secrets"
        "Authentik" "Regenerate Authentik secrets"
        "TinyAuth" "Regenerate TinyAuth secret"
        "Google OAuth" "Regenerate OAuth secret"
        "Back" "Return to auth management"
    )

    local provider
    provider=$(dialog --clear --backtitle "$SCRIPT_NAME - Regenerate Secrets" \
        --title "Regenerate Authentication Secrets" \
        --menu "WARNING: This will generate new secrets!\nYou must restart containers after regeneration.\n\nSelect provider:" 18 70 6 \
        "${provider_menu[@]}" \
        3>&1 1>&2 2>&3 3>&-) || return

    case "$provider" in
        "Authelia")
            if dialog --yesno "Regenerate Authelia secrets?\n\nThis will create new:\n- JWT secret\n- Session secret\n- Storage encryption key\n\nYou MUST restart Authelia after this.\n\nContinue?" 14 70; then
                echo "$(openssl rand -base64 32)" > "$SECRETS_DIR/authelia_jwt_secret"
                echo "$(openssl rand -base64 64)" > "$SECRETS_DIR/authelia_session_secret"
                echo "$(openssl rand -base64 32)" > "$SECRETS_DIR/authelia_storage_encryption_key"
                chmod 600 "$SECRETS_DIR"/authelia_*
                dialog --msgbox "Authelia secrets regenerated!\n\nRestart Authelia:\ndocker restart authelia" 10 60
            fi
            ;;
        "Authentik")
            if dialog --yesno "Regenerate Authentik secrets?\n\nThis will create new:\n- PostgreSQL password\n- Secret key\n\nWARNING: This may break existing setup!\n\nContinue?" 14 70; then
                echo "$(openssl rand -base64 32)" > "$SECRETS_DIR/authentik_postgresql_password"
                echo "$(openssl rand -base64 50)" > "$SECRETS_DIR/authentik_secret_key"
                chmod 600 "$SECRETS_DIR"/authentik_*
                dialog --msgbox "Authentik secrets regenerated!\n\nUpdate .env file with new values and restart:\ndocker restart authentik authentik-worker" 12 70
            fi
            ;;
        "TinyAuth")
            if dialog --yesno "Regenerate TinyAuth secret?\n\nYou MUST restart TinyAuth after this.\n\nContinue?" 10 70; then
                echo "$(openssl rand -base64 32)" > "$SECRETS_DIR/tinyauth_secret"
                chmod 600 "$SECRETS_DIR/tinyauth_secret"
                dialog --msgbox "TinyAuth secret regenerated!\n\nRestart TinyAuth:\ndocker restart tinyauth" 10 60
            fi
            ;;
        "Google OAuth")
            if dialog --yesno "Regenerate OAuth secret?\n\nThis will only regenerate the internal secret.\nClient ID and Secret remain unchanged.\n\nYou MUST restart OAuth container after this.\n\nContinue?" 12 70; then
                local oauth_secret=$(openssl rand -base64 16)
                if [[ -f "$SECRETS_DIR/oauth_secrets" ]]; then
                    sed -i "s|^secret=.*|secret=$oauth_secret|g" "$SECRETS_DIR/oauth_secrets"
                    dialog --msgbox "OAuth secret regenerated!\n\nRestart OAuth:\ndocker restart oauth" 10 60
                else
                    dialog --msgbox "OAuth secrets file not found!\n\nReinstall Google OAuth from Security menu." 10 60
                fi
            fi
            ;;
        "Back")
            return
            ;;
    esac
}
