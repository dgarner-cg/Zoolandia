# Zoolandia Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Fixed - 2026-03-03

#### Secret Backend & CloudDNS Credential Bugfixes

- **GNOME Keyring hidden from backend menu**: `_zl_keyring_available()` previously required
  `secret-tool` to already be installed; since `libsecret-tools` is not installed by default,
  the keyring option was silently suppressed even on a GNOME desktop with a live D-Bus session.
  Fixed by splitting the check: `_zl_keyring_available()` now tests only for a D-Bus session
  (`$DBUS_SESSION_BUS_ADDRESS` or `/run/user/<uid>/bus`); a new `_zl_ensure_secret_tool()`
  helper installs `libsecret-tools` on first use and falls back to file backend on refusal.
- **`_zl_secret_read` unconditional `;&` fall-through removed**: the original implementation
  used bash `;&` to fall from `keyring` to `file`; this cannot be conditional, so when
  `secret-tool` is absent `_zl_secret_read` now uses an explicit `if command -v secret-tool`
  guard and falls back to file silently rather than crashing.
- **Client Secret dialog always empty on edit**: `configure_clouddns` used `--passwordbox`
  without passing the existing value as the init argument, so pressing OK without typing
  returned an empty string and blocked saving. Fixed by passing `"$current_secret"` to
  `--passwordbox`; the field still appears blank (by design — password boxes never display
  init text) but pressing OK without changes now preserves the existing secret.

### Added - 2026-03-02

#### Tiered Secret Backend for DNS Credentials

**New Secret Storage Backends** (`modules/13_reverse_proxy.sh`):
- GNOME Keyring (libsecret) — encrypted at rest, no plaintext file; auto-detected on GNOME desktops
- HashiCorp Vault — centralized secret server; auto-installs Vault CLI via Ansible if not present
- File fallback — `chmod 600` in `~/docker/secrets/` (always available; used on headless/server)
- Backend persisted to `~/.config/zoolandia/secret_backend`; survives session restarts

**New Helper Functions:**
- `_zl_keyring_available()` — detects usable GNOME Keyring session
- `_zl_secret_write()` / `_zl_secret_read()` / `_zl_secret_delete()` — backend-agnostic secret I/O
- `_zl_vault_write()` / `_zl_vault_read()` / `_zl_vault_delete()` — Vault KV helpers
- `ensure_vault()` — installs Vault CLI via Ansible and authenticates if needed
- `show_secret_backend_menu()` — user-facing backend selection dialog

**UX Improvements:**
- DNS credential menus now show masked display (last 4 chars visible: `****ab12`)
- Auto-prompt to run DNS API test after saving a credential
- Pre-filled edit dialog retains existing value for quick correction

**Security Fix** (`modules/11_system.sh`):
- `set_docker_folder()` now validates that `DOCKER_DIR` cannot be set to a path inside the
  Zoolandia installation directory, preventing secrets files from landing inside the git working tree

### Added - 2026-02-07

#### Monitoring Role - Full Observability Stack (Docker-Based)

**New Ansible Role: `monitoring`**
- Created complete `ansible/roles/monitoring/` role with defaults, vars, handlers, meta, tasks, and templates
- 8 Docker-based monitoring components, each with block/rescue error handling and failure tracking

**Monitoring Components:**
- **Grafana** (port 3000) - Dashboard visualization for metrics
- **Prometheus** (port 9090) - Metrics database with auto-generated scrape config template
- **InfluxDB** (port 8086) - Time-series database
- **Telegraf** (port 8125/udp) - Metrics collection agent with auto-generated config template
- **Node Exporter** (port 9100) - Host system metrics for Prometheus
- **cAdvisor** (port 8081) - Docker container metrics
- **Elasticsearch** (port 9200) - Search and analytics engine (v8.17.0)
- **Kibana** (port 5601) - Elasticsearch visualization dashboard (v8.17.0)

**New Files:**
- `ansible/roles/monitoring/defaults/main.yml` - Feature flags and port configuration
- `ansible/roles/monitoring/vars/main.yml` - Docker image names
- `ansible/roles/monitoring/handlers/main.yml` - Container restart handlers
- `ansible/roles/monitoring/meta/main.yml` - Galaxy metadata
- `ansible/roles/monitoring/tasks/main.yml` - Task orchestrator
- `ansible/roles/monitoring/tasks/{grafana,prometheus,influxdb,telegraf,node_exporter,cadvisor,elasticsearch,kibana}.yml` - Individual deployment tasks
- `ansible/roles/monitoring/templates/prometheus.yml.j2` - Prometheus scrape config (auto-discovers node-exporter & cadvisor)
- `ansible/roles/monitoring/templates/telegraf.conf.j2` - Telegraf agent config (CPU, disk, memory, Docker, StatsD)
- `ansible/playbooks/monitoring.yml` - Playbook wrapper with post-task summary

**New Compose Files:**
- `compose/elasticsearch.yml` - Elasticsearch 8.17.0 single-node with security disabled for homelab
- `compose/kibana.yml` - Kibana 8.17.0 connected to Elasticsearch
- `compose/telegraf.yml` - Telegraf with Docker socket and host proc/sys mounts
- `compose/jenkins.yml` - Jenkins LTS with agent port

**Tags:** `monitoring`, `grafana`, `prometheus`, `influxdb`, `telegraf`, `node-exporter`, `cadvisor`, `elk`, `elasticsearch`, `kibana`

#### App Server Role Expansion - Jenkins & Kubernetes

**Jenkins CI/CD (Docker-based):**
- Creates Jenkins appdata directory
- Adds compose/jenkins.yml to Docker stack include
- Deploys and verifies Jenkins container
- Tags: `['appserver', 'jenkins', 'cicd']`

**Kubernetes CLI Tools (Native APT):**
- Downloads Kubernetes GPG key from pkgs.k8s.io
- Adds Kubernetes v1.31 APT repository
- Installs kubectl, kubeadm, kubelet
- Tags: `['appserver', 'kubernetes', 'k8s']`

**Modified Files:**
- `ansible/roles/appserver/defaults/main.yml` - Added `install_jenkins`, `install_kubernetes`, `docker_dir`
- `ansible/roles/appserver/vars/main.yml` - Added Kubernetes GPG URL and repo
- `ansible/roles/appserver/handlers/main.yml` - Added Jenkins restart handler
- `ansible/roles/appserver/tasks/main.yml` - Added Jenkins and Kubernetes task blocks
- `ansible/playbooks/appserver.yml` - Updated post-tasks summary

#### Common Role Expansion - Node.js & Yarn

**Node.js (via NodeSource vendor repo):**
- Downloads NodeSource GPG key and dearmors it
- Adds NodeSource APT repository (Node 20.x LTS)
- Installs nodejs package
- Tags: `['nodejs', 'development']`

**Yarn (via Yarn vendor repo):**
- Downloads Yarn GPG key and dearmors it
- Adds Yarn APT repository
- Installs yarn package
- Tags: `['yarn', 'development']`

**Modified Files:**
- `ansible/roles/common/vars/main.yml` - Added NodeSource and Yarn repo URLs
- `ansible/roles/common/tasks/main.yml` - Added Node.js and Yarn installation sections

#### Workstation Role Expansion - Sublime Text

**Sublime Text (via vendor APT repo):**
- Downloads Sublime Text GPG key and dearmors it
- Adds Sublime Text APT repository
- Installs sublime-text package
- Full block/rescue error handling with audit trail logging
- Tags: `['applications', 'sublime-text', 'editor', 'complex']`

**New File:**
- `ansible/roles/workstation/tasks/applications/complex/sublime_text.yml`

**Modified Files:**
- `ansible/roles/workstation/defaults/main.yml` - Added `install_sublime_text` flag
- `ansible/roles/workstation/tasks/main.yml` - Added Sublime Text include

#### Menu Integration Updates (`modules/41_ansible.sh`)

**New Functions:**
- `detect_installed_monitoring()` - Detects 8 monitoring containers via `docker ps -a`
- `show_monitoring_menu()` - Full checklist menu with "Install All" + individual tag-based installation

**Updated Functions:**
- `detect_installed_common()` - Added Node.js (`node`) and Yarn (`yarn`) detection
- `detect_installed_apps()` - Added Sublime Text (`subl`) detection
- `show_ansible_menu()` - Added "Monitoring Stack" entry between HashiCorp and Advanced Options
- `show_common_menu()` - Added `nodejs` and `yarn` checklist items
- `show_workstation_menu()` - Added `sublime-text` checklist item
- `show_appserver_menu()` - Added `jenkins` and `kubernetes` checklist items with detection
- `show_all_applications_menu()` - Added all new items (monitoring, Jenkins, Kubernetes, Node.js, Yarn, Sublime Text) with detection

#### Site Playbook Update

- `ansible/site.yml` - Added `import_playbook: monitoring.yml`

---

### Added - 2026-01-25

#### Reverse Proxy Menu - DNS Provider Configuration

**DNS Provider Selection:**
- New "DNS Provider" option in reverse proxy menu
- Supports multiple DNS providers for ACME DNS-01 challenges:
  - Cloudflare (recommended) - with API token configuration and testing
  - ManageEngine CloudDNS - full OAuth2 API integration
  - AWS Route53 - Access Key, Secret Key, Region configuration
  - DigitalOcean - API token configuration and testing
  - GoDaddy - API key and secret configuration
  - Manual - for manual DNS record creation

**Cloudflare Integration:**
- Configure API token with proper permissions (Zone:DNS:Edit)
- Set account email
- Test API connection to verify token validity
- Secure storage in secrets directory with 600 permissions

**ManageEngine CloudDNS Integration:**
- OAuth2 authentication with Client ID and Client Secret
- Automatic access token retrieval from `https://clouddns.manageengine.com/oauth2/token/`
- Zone lookup with exact and suffix matching
- Full TXT record creation, update, and deletion for ACME challenges
- API test function to verify credentials and list zones

**DNS Record Management Functions:**
- `create_acme_txt_record()` - Create TXT records for ACME challenges
- `delete_acme_txt_record()` - Clean up TXT records after challenge
- Full Cloudflare and CloudDNS implementations
- Helper functions: `get_clouddns_token()`, `get_clouddns_zone_id()`

**UX Improvements:**
- All credential input fields pre-populate with saved values for easy editing
- "Clear" option added to each provider menu to remove credentials
- Menus loop back after entering information (no need to re-navigate)
- Status display shows "(set)" or "Not set" for each credential

**Configuration Storage:**
- DNS provider selection saved to `$ZOOLANDIA_CONFIG_DIR/dns_provider`
- API credentials stored in `$SECRETS_DIR/` with secure permissions (chmod 600)
- Provider-specific credential files:
  - Cloudflare: `cf_dns_api_token`, `cf_email`
  - CloudDNS: `clouddns_client_id`, `clouddns_client_secret`
  - Route53: `aws_access_key_id`, `aws_secret_access_key`, `aws_region`
  - DigitalOcean: `digitalocean_token`
  - GoDaddy: `godaddy_api_key`, `godaddy_api_secret`

#### Ansible Workstation Role - Chrome Extensions

**New Chrome Extensions Installer:**
- Added `chrome_extensions.yml` task for installing browser extensions
- Extensions installed as unpacked extensions to `~/.local/share/chrome-extensions/`
- Supports Chrome, Chromium, Vivaldi, Brave, and other Chromium-based browsers

**AI Chat Exporter Extension (gpt-xptr v1.2.2):**
- Export AI chat conversations to PDF, HTML, and Markdown
- Supports multiple AI platforms:
  - ChatGPT (chat.openai.com, chatgpt.com)
  - Claude (claude.ai)
  - Google Gemini (gemini.google.com)
  - Microsoft Copilot (copilot.microsoft.com)
  - Perplexity AI (perplexity.ai)
- Beautiful formatting with syntax highlighting

**Configuration:**
- `install_chrome_extensions: true` - Enable/disable feature
- Individual extension enable/disable via `chrome_extensions.extensions[].enabled`
- Extensions categorized under "productivity" and "extensions" tags

#### Ansible Role Reorganization

**New Security Role (`ansible/roles/security/`):**
- Created dedicated `security` role for security tools
- Moved from common role: fail2ban, auditd
- Added new: clamav (antivirus with freshclam updates)
- Services auto-enabled and started after installation

**New Configs Role (`ansible/roles/configs/`):**
- Created dedicated `configs` role for system configurations
- Consolidated configuration tasks:
  - `power_management.yml` - Lid close actions, sleep timeouts
  - `touchpad_settings.yml` - Speed, tap-to-click, natural scrolling
  - `mouse_settings.yml` - Speed, acceleration profile (NEW)
  - `nautilus_sort.yml` - File manager sort order, view settings
  - `ntfs_automount.yml` - NTFS/exFAT filesystem support
  - `razer_grub.yml` - Intel GPU fixes for Razer laptops (NEW)
- All configs selectable from All Applications menu

**Package Distribution:**
- Workstation role now includes: tmux, fzf, ripgrep, bat (development tools)
- Common role retains: rclone, glances (plus other essential tools)
- Security role contains: fail2ban, clamav, auditd
- Configs role contains: power, touchpad, mouse, nautilus, ntfs, razer

**All Applications Menu Updates:**
- Added "Chrome Extensions (AI Chat Exporter)" to interactive menu
- Added "─── SYSTEM CONFIGS ───" separator section
- Added new config options:
  - Mouse Settings (speed, acceleration)
  - NTFS/exFAT Filesystem Support
  - Razer Laptop GRUB Config (Intel GPU fix)
- Detection for all config states (installed/configured)

#### System Menu UX Improvements

**Streamlined System Type Selection:**
- Removed intermediate "Change/Info/View" submenu
- Options displayed directly: Unprivileged LXC, Privileged LXC, Virtual Machine, Barebones, VPS
- Current and auto-detected type shown in header
- "Info" option available at bottom of menu

**Streamlined Setup Mode Selection:**
- Removed intermediate "Change/Info/View" submenu
- Local and Hybrid options displayed directly
- Current mode shown in header
- "Info" option available at bottom of menu

---

### Added - 2026-01-24

#### Docker Menu Enhancements

**Version Display:**
- Docker menu now displays current Docker and Docker Compose versions in header
- Shows "Not Installed" if Docker/Compose is not available

**Zoolandia Dashboard:**
- New "Install Dashboard" option to deploy Homepage-based dashboard
- Uses configuration from SimpleHomelab/Deployrr repository
- Dashboard features:
  - System resource monitoring (CPU, Memory, Disk)
  - Docker container status integration
  - Customizable bookmarks and widgets
  - Dark theme with Zoolandia branding
- "View Dashboard" button appears when dashboard is running
- Opens dashboard in default browser (xdg-open)
- Default port: 3010

**Dashboard Management Menu:**
- View: Open dashboard in browser
- Start/Stop: Control dashboard container
- Restart: Restart dashboard container
- Logs: View last 100 lines of container logs
- Config: Open configuration directory
- Remove: Remove dashboard (with option to keep/delete config)

**Dashboard Configuration Files:**
- `settings.yaml` - Theme, title, appearance
- `services.yaml` - App links and widgets
- `bookmarks.yaml` - Quick links
- `widgets.yaml` - Dashboard widgets
- `docker.yaml` - Docker socket configuration (uses local socket)

**Variable Renaming:**
- Renamed `DEPLOYIQDASHBOARD_PORT` to `ZOOLANDIA_DASHBOARD_PORT`
- Updated compose file, .env, and docker module
- Removed socket_proxy dependency (uses local docker.sock directly)

---

#### Reverse Proxy Menu Overhaul

**Complete Menu Restructure (based on traefik.png reference):**

**New Menu Items:**
- **Exposure Mode** - Toggle between Simple and Advanced exposure modes
- **Preparation** - Traefik preparation with status indicator (DONE/NOT DONE)
- **Staging** - Setup Traefik with Let's Encrypt staging certificates
- **Production** - Setup Traefik with Let's Encrypt production certificates
- **Manage Exposure** - View and change app exposure (Internal/External/Both counts)
- **Traefikify** - Put an app behind Traefik with subdomain configuration
- **Un-Traefikify** - Remove a Traefik file provider
- **Domain Passthrough** - Configure passthrough to another Traefik instance
- **Auth Bypass** - Set/Generate/Remove Traefik forward auth bypass key

**New Functions:**
- `toggle_exposure_mode()` - Switch between Simple/Advanced modes
- `traefik_preparation()` - Prepare directories, middleware, and certificates
- `setup_traefik_staging()` - Configure Let's Encrypt staging server
- `setup_traefik_production()` - Configure Let's Encrypt production server
- `manage_exposure()` - List and modify app exposure settings
- `traefikify_app()` - Add Traefik routing for an app
- `un_traefikify_app()` - Remove Traefik routing for an app
- `domain_passthrough()` - Configure traffic forwarding to another Traefik
- `set_auth_bypass()` - Manage forward auth bypass key

**Menu Features:**
- Dynamic status indicators with color coding
- App exposure counts (Internal, External, Both)
- Exposure mode persistence to config file
- Auto-generated Traefik rule files
- Random bypass key generation with OpenSSL

---

**New Menu Options:**

*Disk Usage:*
- Calculate and display Docker disk usage
- Shows Docker directory breakdown (appdata, compose, logs, secrets, shared)
- Displays Docker system disk usage (images, containers, volumes, networks)
- Shows reclaimable space information
- Uses DOCKER_DIR from Prerequisites configuration

*UFW Firewall Rules:*
- "Install UFW Rules" - Configure UFW to work properly with Docker
  - Adds DOCKER-USER chain rules
  - Allows Docker bridge network traffic (172.16.0.0/12)
  - Prevents Docker from bypassing UFW
  - Creates automatic backup before changes
- "Remove UFW Rules" - Remove Docker-specific UFW rules
  - Removes DOCKER-USER chain configuration
  - Creates backup before removal
  - Reloads UFW after changes

*Docker Prune (Enhanced):*
- Now provides granular cleanup options:
  - All: Remove all unused data (containers, networks, images, cache)
  - Containers: Remove stopped containers only
  - Images: Remove unused images only
  - Volumes: Remove unused volumes (with data loss warning)
  - Networks: Remove unused networks only
  - Build Cache: Remove build cache only
- Confirmation dialogs for each operation
- Shows cleanup results after completion

**Menu Structure:**
```
Docker Settings
├── Docker: <version> | Compose: <version>
├── Install Socket Proxy
├── Docker Info
├── Disk Usage (NEW)
├── ─────────
├── Install UFW Rules (NEW)
├── Remove UFW Rules (NEW)
├── ─────────
├── Docker Prune (ENHANCED)
└── Back
```

---

#### Prerequisites - GitHub Username

**New Prerequisite Entry:**
- Added "GitHub Username" to Prerequisites menu
- Validates GitHub username format (alphanumeric and hyphens, 1-39 chars)
- Persists username to `~/.config/zoolandia/github_username`
- Displays current username in menu status

**Integration:**
- GitHub username is passed to Ansible playbooks via `-e github_username=<value>`
- VS Code Tunnel setup displays configured GitHub account
- Provides guidance for GitHub device login during tunnel authentication

**New Function:**
- `set_github_username()` - Input dialog for GitHub username with validation

**New Variable:**
- `GITHUB_USERNAME` - Global variable loaded from config on startup

**Documentation:**
- `documentation/GITHUB_USERNAME.md` - Complete guide for GitHub username configuration

---

#### Ansible App Server Role - VS Code Tunnel Service

**New Role: `appserver`**
- Created new Ansible role for application server tools and services
- Located at: `ansible/roles/appserver/`

**VS Code Tunnel Service:**
- Automated installation of VS Code for ARM64 and AMD64 architectures
- Systemd service (`code-tunnel`) for persistent VS Code tunnel connections
- Enables browser-based remote development via `https://vscode.dev/tunnel/<hostname>`
- Auto-restart on failure with 10-second delay
- Network-online dependency for reliable startup

**New Files:**
- `ansible/playbooks/appserver.yml` - App server playbook
- `ansible/roles/appserver/tasks/main.yml` - VS Code tunnel installation tasks
- `ansible/roles/appserver/templates/code-tunnel.service.j2` - Systemd service template
- `ansible/roles/appserver/handlers/main.yml` - Service restart handlers
- `ansible/roles/appserver/defaults/main.yml` - Default variables
- `ansible/roles/appserver/vars/main.yml` - Role variables
- `ansible/roles/appserver/meta/main.yml` - Role metadata
- `ansible/roles/appserver/README.md` - Complete role documentation

**Ansible Menu Integration:**
- Added "App Server" to Ansible menu (By Role section)
- Added VS Code Tunnel to "All Applications" searchable list
- App Server menu shows GitHub username status
- Prompts to set GitHub username if not configured
- Passes `github_username` variable to Ansible playbook

**Usage:**
```bash
# Install VS Code tunnel
ansible-playbook playbooks/appserver.yml

# Install with custom user
ansible-playbook playbooks/appserver.yml -e "vscode_tunnel_user=myuser"

# First-time setup (required):
code tunnel --accept-server-license-terms
# Follow GitHub device login, then Ctrl+C

# Start the service
sudo systemctl start code-tunnel

# Access via browser
https://vscode.dev/tunnel/<your-hostname>
```

**Service Management:**
```bash
sudo systemctl status code-tunnel   # Check status
sudo systemctl start code-tunnel    # Start service
sudo systemctl stop code-tunnel     # Stop service
sudo journalctl -u code-tunnel -f   # View logs
```

---

### Added - 2026-01-05

#### System Menu - Alias Management Overhaul

**New Menu Items:**
- Added "Docker Aliases" menu item to System menu for Docker/Compose alias management
- Added "Kubernetes Aliases" menu item to System menu for kubectl alias management
- Added "DevOps Aliases" menu item to System menu for Git, Ansible, Terraform, etc.

**Docker Aliases Menu (`show_docker_aliases_menu`):**
- View Aliases - Preview 30+ Docker/Compose aliases before installation
- Install Aliases - Install Docker bash aliases to `~/.docker_aliases`
- Run Docker Menu - Launch Docker operations TUI directly (no installation required)
- Install Docker Menu - Install Docker TUI as `dom` command in `~/.local/bin/dom`
- Uninstall - Remove Docker aliases and menu with automatic bashrc cleanup
- Real-time installation status indicators (Installed/Not installed)

**Kubernetes Aliases Menu (`show_kubernetes_aliases_menu`):**
- View Aliases - Preview 40+ kubectl aliases before installation
- Install Aliases - Install Kubernetes bash aliases to `~/.k8s_aliases`
- Run K8s Menu - Launch Kubernetes operations TUI directly (no installation required)
- Install K8s Menu - Install K8s TUI as `k8m` command in `~/.local/bin/k8m`
- Uninstall - Remove Kubernetes aliases and menu with automatic bashrc cleanup
- Real-time installation status indicators (Installed/Not installed)

**DevOps Aliases Menu (`show_devops_aliases_menu`):**
- View Aliases - Preview 150+ DevOps aliases before installation
- Install Aliases - Install DevOps bash aliases to `~/.devops_extras`
- Uninstall - Remove DevOps aliases with automatic bashrc cleanup
- Real-time installation status indicator (Installed/Not installed)

**New Functions Added:**

*Menu Functions:*
- `show_docker_aliases_menu()` - Docker aliases and management menu
- `show_kubernetes_aliases_menu()` - Kubernetes aliases and management menu
- `show_devops_aliases_menu()` - DevOps aliases menu

*View Functions (Preview Before Install):*
- `view_docker_aliases()` - Display preview of Docker aliases from source
- `view_kubernetes_aliases()` - Display preview of Kubernetes aliases from source
- `view_devops_extras()` - Display preview of DevOps extras aliases from source

*Run Functions (Execute Without Installing):*
- `run_docker_ops_menu()` - Execute Docker TUI menu from source directory
- `run_k8s_ops_menu()` - Execute Kubernetes TUI menu from source directory

*Install Functions:*
- `install_docker_aliases()` - Extract and install Docker aliases from docker.md
- `install_kubernetes_aliases()` - Install Kubernetes aliases from kubernetes.md
- `install_docker_ops_menu()` - Install Docker TUI as `dom` command
- `install_k8s_ops_menu()` - Install Kubernetes TUI as `k8m` command
- `install_devops_extras()` - Extract and install DevOps aliases from devops-extras.md

*Uninstall Functions:*
- `uninstall_docker_components()` - Remove Docker aliases and menu, clean bashrc
- `uninstall_k8s_components()` - Remove Kubernetes aliases and menu, clean bashrc
- `uninstall_devops_components()` - Remove DevOps aliases, clean bashrc

**New Source Files:**

*Alias Collections:*
- `importing/docker.md` - Docker/Compose bash helpers and functions (30+ aliases)
  - Smart docker compose wrapper
  - Safe Docker commands (dps, dpa, dlog, dexec, etc.)
  - Safe Compose commands (dcu, dcd, dcr, dcps, etc.)
  - Helper functions (dls, dlogs, denter_last)
  - Cleanup functions with confirmations (dprune_containers, dprune_images, etc.)

- `importing/kubernetes.md` - Kubernetes/kubectl bash helpers (40+ aliases)
  - Core kubectl shortcuts (k, kctx, kns, kget, etc.)
  - Get resource aliases (kgp, kgs, kgd, kgn, kgi, etc.)
  - Operation aliases (kdesc, klogs, kexec, kapp, kdel, etc.)
  - Helper functions (kwhere, ksn, kpods, klog, ksh)
  - Rollout management (kroll, khist)

- `importing/devops-extras.md` - Additional DevOps tooling aliases (150+ aliases)
  - Git version control (40+ aliases: g, gs, ga, gc, gp, gl, gb, gst, etc.)
  - Ansible automation (15+ aliases: ap, apv, apc, ag, ainv, etc.)
  - Terraform/OpenTofu (15+ aliases: tf, tfi, tfp, tfa, tfd, tfo, etc.)
  - Systemd journalctl (8+ aliases: jc, jcf, jcu, jcboot, etc.)
  - Tmux/Screen sessions (10+ aliases: ta, tl, ts, sl, sr, etc.)
  - Rsync operations (6+ aliases: rsync-copy, rsync-sync, rsync-dry, etc.)
  - SSH utilities (5+ aliases: sshkeygen, sshcopy, sshconfig, etc.)
  - Python/pip (10+ aliases: py, pip, venv, mkvenv, etc.)
  - SSL/TLS certificates (8+ aliases: certinfo, certexpiry, gencert, etc.)
  - Process management, text processing, system info utilities

*Interactive TUI Menus:*
- `importing/docker-ops-menu.sh` - Interactive Docker operations menu
  - Container management (list, logs, exec shell)
  - Image, network, volume operations
  - Docker Compose shortcuts (up, down, logs)
  - Cleanup operations with confirmations
  - Whiptail/dialog-based interface

- `importing/k8s-ops-menu.sh` - Interactive Kubernetes operations menu
  - Context and namespace management
  - Pod operations (list, logs, exec shell)
  - Deployment management and rollout operations
  - Resource cleanup
  - Whiptail/dialog-based interface

**Documentation:**
- `documentation/ALIAS_SYSTEM_UPDATE.md` - Original technical specification
- `documentation/ALIAS_SYSTEM_UPDATE_v2.md` - User-friendly update documentation
- `CHANGELOG.md` - This file, tracking all project changes

**Installation Locations:**

*User Home Directory:*
- `~/.docker_aliases` - Installed Docker/Compose aliases
- `~/.k8s_aliases` - Installed Kubernetes/kubectl aliases
- `~/.devops_extras` - Installed DevOps tooling aliases
- `~/.local/bin/dom` - Docker Ops Menu command (short for docker-ops-menu)
- `~/.local/bin/k8m` - Kubernetes Menu command (short for k8s-ops-menu)

*Bashrc Entries (auto-managed):*
```bash
# Load Docker bash aliases
[[ -f ~/.docker_aliases ]] && source ~/.docker_aliases

# Load Kubernetes bash aliases
[[ -f ~/.k8s_aliases ]] && source ~/.k8s_aliases

# Load additional DevOps aliases
[[ -f ~/.devops_extras ]] && source ~/.devops_extras

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Changed - 2026-01-05

#### System Menu Structure
- Renamed "Bash Aliases" menu item to "Docker Aliases"
- Updated System menu height from 7 to 8 items to accommodate new DevOps Aliases menu
- Reorganized menu to separate Docker, Kubernetes, and DevOps concerns
- All alias menus now show "View" option first, encouraging users to preview before installing
- Removed redundant "About" extra button from System menu (About is already a menu item)

#### Improved User Experience
- **Preview Before Install**: All alias collections can be viewed before installation
- **Run Without Installing**: Management menus can be launched directly from Zoolandia
- **Shorter Commands**: Installed menus use concise names (`dom`, `k8m`) instead of long names
- **Installation Status**: Menus show real-time indicators of what's installed
- **Easy Uninstall**: One-click uninstallation with automatic bashrc cleanup

#### Modified Functions
- `show_system_menu()` - Added DevOps Aliases menu item, updated menu height
- Menu reorganization separates concerns: Docker, Kubernetes, and DevOps are now independent

### Fixed - 2026-01-05

**Organization Issues:**
- Moved DevOps aliases out of Docker Aliases menu (they're unrelated to Docker)
- Created dedicated DevOps Aliases menu for better organization
- Separated uninstall functions so Docker, Kubernetes, and DevOps can be removed independently

**User Experience Issues:**
- Fixed issue where users had to install aliases to see what they contained
- Fixed issue where TUI menus required installation to try them
- Fixed issue with long, hard-to-remember command names
- Fixed issue where users couldn't easily uninstall components

### Security

**Safe Installation Practices:**
- All installations ask for user confirmation
- Preview functionality allows inspection before installation
- Uninstall functions clean up all traces including bashrc entries
- No automatic modifications to user's shell configuration without explicit consent

**Safe Aliases:**
- All destructive operations (prune, delete, remove) require confirmation prompts
- Helper functions use `_confirm()` for dangerous actions
- Color-coded output warnings for destructive operations

---

## Usage Examples

### Installing Docker Aliases
```bash
1. Navigate to System menu
2. Select "Docker Aliases"
3. Choose "View Aliases" to preview
4. Choose "Install Aliases" to install
5. Restart terminal or: source ~/.bashrc
6. Use aliases: dc up -d, dps, dlogs nginx
```

### Using Docker Management Menu
```bash
# Option 1: Run directly from Zoolandia (no install)
System → Docker Aliases → Run Docker Menu

# Option 2: Install as 'dom' command
System → Docker Aliases → Install Docker Menu
# Then in terminal:
dom
```

### Installing Kubernetes Aliases
```bash
1. Navigate to System menu
2. Select "Kubernetes Aliases"
3. Choose "View Aliases" to preview
4. Choose "Install Aliases" to install
5. Restart terminal or: source ~/.bashrc
6. Use aliases: k get pods, klog webapp, ksh nginx
```

### Installing DevOps Extras
```bash
1. Navigate to System menu
2. Select "DevOps Aliases"
3. Choose "View Aliases" to preview 150+ aliases
4. Choose "Install Aliases" if desired
5. Restart terminal or: source ~/.bashrc
6. Use aliases: gs, gc "message", ap playbook.yml, tf plan
```

### Uninstalling Components
```bash
# Uninstall Docker components
System → Docker Aliases → Uninstall

# Uninstall Kubernetes components
System → Kubernetes Aliases → Uninstall

# Uninstall DevOps components
System → DevOps Aliases → Uninstall
```

---

## Alias Quick Reference

### Docker Aliases (30+)
```bash
# Compose
dc up -d, dcu, dcd, dcr, dcl, dcp

# Containers
dps, dpa, dlog, dexec, dstats, dtop

# Helper Functions
dls, dlogs <name>, denter_last

# Cleanup (with confirmations)
dprune_containers, dprune_images, dprune_volumes
```

### Kubernetes Aliases (40+)
```bash
# Core
k, kctx, kns, kget, kga

# Pods
kgp, klog <pod>, ksh <pod>

# Resources
kgs, kgd, kgn, kgi, kdesc

# Helpers
kwhere, ksn <namespace>, kroll, khist
```

### DevOps Aliases (150+)
```bash
# Git (40+)
g, gs, ga, gc, gp, gl, gco, gb, gst

# Ansible (15+)
ap, apv, apc, ag, ainv

# Terraform (15+)
tf, tfi, tfp, tfa, tfd, tfo

# System (30+)
jc, jcf, ta, tl, rsync-copy, py, certinfo
```

---

## Breaking Changes

None. All changes are additive and backward compatible.

---

## Migration Guide

No migration needed. This is a new feature set. Existing installations are unaffected.

---

## Contributors

- System menu reorganization and alias management system
- Interactive TUI menus for Docker and Kubernetes operations
- Comprehensive alias collections for DevOps workflows
- User-friendly preview and installation system

---

## Notes

- All changes tested and syntax-validated with `bash -n`
- Installation requires: bash, dialog/whiptail
- Optional requirements: docker (for Docker aliases), kubectl (for K8s aliases)
- Aliases are sourced automatically on shell startup after installation
- Uninstallation removes all files and cleans up bashrc entries automatically

---

---

### Added - 2026-02-23

#### Secret Menu - Personal Project Launcher with Optional RSA Auth Gate

**New Module: `modules/60_personal.sh`**
- Added a **Secret** menu item to the main home screen (between Ansible and Tools)
- Auto-discovers projects from `ansible/roles/secret/` — no manual registration needed
- Supports two project layouts:
  - **Directory-based**: `ansible/roles/secret/<project-name>/site.yml` (or `main.yml`)
  - **Standalone**: `ansible/roles/secret/<name>.yml`
- Prompts for inventory/host if none is bundled with the project; auto-detects bundled `inventory`, `hosts`, `inventory.yml`, `inventory.ini`, or `hosts.yml`
- Optional extra vars prompt before each run
- Prints a run summary (playbook path, inventory, extra vars) and confirms before executing
- "Run Custom" option lets you run any playbook by full path without placing it in the secret directory

**Optional RSA Key Auth Gate:**
- Three variables at the top of `modules/60_personal.sh` control access:
  ```bash
  SECRET_AUTH_ENABLED=false           # Set to true to enable the gate
  SECRET_KEY_PATH="${HOME}/.ssh/id_rsa"  # Path to your RSA private key
  SECRET_KEY_FINGERPRINT=""           # Expected SHA256 fingerprint (leave empty to skip fingerprint check)
  ```
- When `SECRET_AUTH_ENABLED=true`, access is verified once on menu entry before the while loop
- **Key-exists-only mode** (fingerprint empty): confirms the key file exists at `SECRET_KEY_PATH`
- **Fingerprint-verified mode** (fingerprint set): runs `ssh-keygen -lf` on the key and compares the SHA256 fingerprint against `SECRET_KEY_FINGERPRINT`; access denied if they don't match

**How to enable RSA auth:**

1. Get your key fingerprint:
   ```bash
   ssh-keygen -lf ~/.ssh/id_rsa | awk '{print $2}'
   # Example output: SHA256:abc123xyz...
   ```

2. Edit `modules/60_personal.sh` and set:
   ```bash
   SECRET_AUTH_ENABLED=true
   SECRET_KEY_FINGERPRINT="SHA256:abc123xyz..."
   ```

**How to add a new secret project:**

Create a directory under `ansible/roles/secret/` with a `site.yml` entrypoint:
```
ansible/roles/secret/
└── MyProject/
    ├── site.yml       ← main playbook (required)
    └── inventory      ← optional, auto-detected
```

The project will appear automatically in the Secret menu on next launch. No code changes required.

**Files Changed:**
- `modules/60_personal.sh` - New module (Secret menu, auth gate, project runner)
- `modules/02_main_menu.sh` - Added "Secret" menu item and case handler; bumped dialog item count to 13
- `zoolandia.sh` - Added `source` for `modules/60_personal.sh`
- `ansible/roles/secret/` - New directory for personal/secret Ansible projects

---

[Unreleased]: https://github.com/SimpleHomelab/Zoolandia/compare/v5.10...HEAD
