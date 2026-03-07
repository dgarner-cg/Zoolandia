# Changelog

All notable changes to Zoolandia will be documented in this file.

## Current Release

**Total Supported Apps:** 176 (160 Docker + 16 System)
**Version:** 6.1.3

---

## [v6.1.3] - March 7, 2026

### License Tooling Consolidated into `.signing/`

Since `.signing/` is already gitignored and is the designated operator-only directory,
all license-related tooling now lives there rather than splitting across `.signing/` and `.admin/`.

**Files moved from `.admin/` back to `.signing/`:**
- `license-server.py` — debug/test web server
- `license-server.sh` — start/stop/restart/status wrapper

**Path updates in `license-server.sh`:**
- `ADMIN_DIR` variable renamed to `SCRIPT_DIR`
- `SIGNING_DIR` variable removed — keys are now co-located in the same directory
- `PRIVATE_KEY`, `PUBLIC_KEY`, `SERVER_SCRIPT`, `PID_FILE`, `LOG_FILE` all use `$SCRIPT_DIR`
- PID and log files write to `.signing/.license-server.pid` / `.signing/.license-server.log`

**`.signing/` now contains the complete signing suite:**
```
.signing/
├── zoolandia_license_priv.pem    — Ed25519 private key (operator only)
├── zoolandia_public.pem          — Ed25519 public key
├── zl-sign.sh                    — CLI signing tool
├── license-server.py             — debug/test web server
└── license-server.sh             — server start/stop wrapper
```

All files in `.signing/` remain gitignored via the existing `.signing/` entry in `.gitignore`.

---

## [v6.1.2] - March 7, 2026

### Signing Infrastructure Reorganization & `.admin/` Workspace Isolation

**`.signing/` cleanup — only operational files remain:**
- `license-server.py` (debug/test web server) moved from `.signing/` to `.admin/`
- `.signing/` now contains only: private key, public key, `zl-sign.sh` (signing tool)
- Clear separation: `.signing/` = key material + signing tool; `.admin/` = operator workspace

**New: `.admin/license-server.sh`** — bash wrapper around `license-server.py`:
- `--start [--port PORT]` — starts server in background, writes PID to `.admin/.license-server.pid`, logs to `.admin/.license-server.log`; verifies process started successfully
- `--stop` — kills process by PID, cleans up PID file; handles stale PID gracefully
- `--restart` — stop + start in sequence
- `--status` — reports running/not-running with PID and URL
- Key paths passed explicitly from `../.signing/` — no hardcoded relative assumptions
- Server logs accumulated in `.admin/.license-server.log` for debugging

**`.gitignore` update:**
- Added `.admin/` — entire admin workspace is now gitignored
- `.admin/` is the owner-only workspace intended to become a separate repo when signing is productionized

---

## [v6.1.1] - March 7, 2026

### GitHub Username Storage Relocation & Documentation Consolidation

**Config Path Change — `modules/00_core.sh` / `modules/10_prerequisites.sh`:**
- GitHub username moved from `~/.config/zoolandia/github_username` (system-wide config dir)
  to `${SCRIPT_DIR}/.config/github` (project-local, alongside `.license/`)
- Introduced `ZL_PROJECT_CONFIG_DIR="${SCRIPT_DIR}/.config"` variable in `00_core.sh`
  for consistency with future project-local runtime config files
- `set_github_username()` now writes to `${ZL_PROJECT_CONFIG_DIR}/github` and uses
  `mkdir -p "$ZL_PROJECT_CONFIG_DIR"` instead of `$ZOOLANDIA_CONFIG_DIR`
- On-startup load in `00_core.sh` updated to match new path
- `.config/` directory created at project root (chmod 700); added to `.gitignore`

**Documentation Consolidation — `README.md`:**
- `documentation/GITHUB_USERNAME.md` content merged into `README.md` as a dedicated section
  (validation rules, menu path, manual CLI commands, Ansible usage, updated storage path)
- Recent changelog entries embedded inline in `README.md` with link to full `documentation/CHANGELOG.md`
- Reduces standalone documentation file count; `README.md` is now the primary reference

---

## [v6.1.0] - March 7, 2026

### License System — Ed25519 Offline License Keys, Settings UI & Feature Gating

This release introduces a complete cryptographic licensing system: key signing infrastructure,
offline Ed25519 signature verification, a Settings-integrated activation/validation UI, feature
gating in the reverse proxy module, and a local web server for testing the full flow without
requiring a payment processor.

#### License Key Format

```
ZOOL-<base64url(json_payload)>.<base64url(ed25519_signature)>
```

Payload fields: schema version (`v`), email, tier, features list, issued date, expires date.
Keys are offline-verifiable — no internet required after activation. The Ed25519 public key is
embedded directly in `modules/license.sh`.

#### Tier → Feature Mapping

| Feature    | Starter | Pro | Enterprise |
|------------|:-------:|:---:|:----------:|
| traefik    | yes     | yes | yes        |
| authelia   | yes     | yes | yes        |
| authentik  |         | yes | yes        |
| security   |         | yes | yes        |
| vpn        |         | yes | yes        |
| ansible    |         |     | yes        |
| multi-node |         |     | yes        |

#### New Module: `modules/license.sh`

- `zl_validate_key KEY` — decodes payload, verifies Ed25519 signature with embedded public key,
  checks expiry; returns 0 (valid), 1 (invalid/missing), or 2 (expired, distinct code)
- `zl_check_license FEATURE` — reads active license file, validates, and checks feature presence
- `zl_require_license FEATURE [LABEL]` — gates any function with a contextual dialog prompt:
  distinguishes no-license, expired, and wrong-tier with specific messages and upgrade URLs
- `zl_activate_license [KEY]` — prompts via dialog inputbox (or accepts argument), validates
  signature before saving; shows decoded email/tier/expiry on success
- `zl_license_status` — one-line summary used in Settings menu label

#### License Storage: `.license/` Directory

- Key stored at `${SCRIPT_DIR}/.license/license.key` (chmod 600; directory chmod 700)
- Path derived from `$SCRIPT_DIR` (set by `00_core.sh`) — portable with the installation
- `.license/` added to `.gitignore` — never committed to version control

#### Signing Infrastructure: `.signing/`

`.signing/` is gitignored and holds the private key and tooling for the operator only.

**`.signing/zl-sign.sh`** — CLI license signing tool:
- `--email`, `--tier`, `--features`, `--days`, `--key`, `--out`
- Tier defaults: starter → `traefik,authelia`; pro → `+authentik,security,vpn`;
  enterprise → `+ansible,multi-node`
- Negative `--days` issues pre-expired keys for testing the expired path
- Signs with `openssl pkeyutl -rawin` (Ed25519); base64url encodes both parts (no padding)

**`.signing/license-server.py`** — local web test server (Python stdlib, zero dependencies):
- `python3 license-server.py [--port 8765] [--key ...] [--pub ...]`
- Dark-themed UI at `http://localhost:8765`
- **Issue tab**: email / tier / features / days presets → Generate → copy key or send to validator
- **Validate tab**: paste any key → shows signature pass/fail, decoded payload, expiry status
- **REST API**: `POST /api/sign`, `POST /api/validate`
- Identical signing logic to `zl-sign.sh` — same keys work in both; ready to wrap with a
  payment processor webhook when moving to production

#### Feature Gate: `modules/13_reverse_proxy.sh`

- `configure_dns_provider()` now opens with:
  ```bash
  zl_require_license "traefik" "Reverse Proxy / DNS Provider" || return 0
  ```
- Unlicensed users see the upgrade prompt; the function exits cleanly without entering the menu

#### Settings > License Menu: `modules/40_settings.sh`

Replaced the previous stub `show_license_info()` with a full interactive `show_license_menu()`:

- **Live status header** on every visit — Status, Email, Tier, Expires, Features, file path
- **Activate** — dialog inputbox; validates Ed25519 signature before writing to disk; shows
  decoded details on success; specific error for expired vs. invalid
- **Validate** — re-reads and re-verifies current key; displays full decoded payload on success
  or targeted error message (expired / tampered / corrupt)
- **Remove** — confirmation prompt; deletes `.license/license.key`; features revert to free tier
- Settings top-level menu entry shows a live one-line license summary next to "License"

#### Application Wiring

- `zoolandia.sh` — `modules/license.sh` sourced immediately after `00_core.sh` so all subsequent
  modules have access to `zl_require_license` and `zl_check_license`

#### Local Test Flow (no payment processor required)

```bash
# 1. Start the web UI
python3 .signing/license-server.py
# open http://localhost:8765 — fill form, generate key, copy

# 2. Activate from the key file directly
echo "ZOOL-..." > .license/license.key

# 3. Validate without launching the full TUI
source modules/license.sh && zl_license_status

# 4. Test the feature gate
source modules/license.sh && zl_require_license "traefik" "Reverse Proxy / DNS Provider"

# 5. Or test interactively: Settings > License > Validate
```

#### Files Added / Modified

| File | Change |
|---|---|
| `modules/license.sh` | New — full license validation and activation module |
| `modules/40_settings.sh` | Updated — replaced stub with full `show_license_menu()` |
| `modules/13_reverse_proxy.sh` | Updated — `configure_dns_provider()` gated |
| `zoolandia.sh` | Updated — sources `license.sh` after `00_core.sh` |
| `.signing/zl-sign.sh` | New — CLI signing tool (gitignored directory) |
| `.signing/license-server.py` | New — local test web server (gitignored directory) |
| `.license/` | New directory — runtime license key storage (gitignored) |
| `.gitignore` | Updated — added `.license/` entry |

---

## [v6.0.25] - March 3, 2026

### Fixed — Secret Backend & CloudDNS Credential Bugfixes

- **GNOME Keyring hidden from backend menu**: `_zl_keyring_available()` previously required `secret-tool` to be installed before detecting GNOME Keyring availability. Since `libsecret-tools` is not installed by default, the keyring option was silently suppressed even on a live GNOME desktop with a D-Bus session. Fixed by splitting the check: `_zl_keyring_available()` now tests only for a D-Bus session (`$DBUS_SESSION_BUS_ADDRESS` or `/run/user/<uid>/bus`); a new `_zl_ensure_secret_tool()` helper installs `libsecret-tools` on first use and falls back to file backend on refusal.
- **`_zl_secret_read` unconditional `;&` fall-through removed**: the original implementation used bash `;&` to fall from `keyring` to `file`; this cannot be conditional, so when `secret-tool` is absent `_zl_secret_read` now uses an explicit `if command -v secret-tool` guard and falls back to file silently rather than crashing.
- **Client Secret dialog always empty on edit**: `configure_clouddns` used `--passwordbox` without passing the existing value as the init argument, so pressing OK without typing returned an empty string and blocked saving. Fixed by passing `"$current_secret"` to `--passwordbox`; the field still appears blank (by design — password boxes never display init text) but pressing OK without changes now preserves the existing secret.

---

## [v6.0.24] - March 2, 2026

### Added — Tiered Secret Backend for DNS Credentials

**New Secret Storage Backends** (`modules/13_reverse_proxy.sh`):
- GNOME Keyring (libsecret) — encrypted at rest, no plaintext file; auto-detected on GNOME desktops
- HashiCorp Vault — centralized secret server; auto-installs Vault CLI via Ansible if not present
- File fallback — `chmod 600` in `~/docker/secrets/` (always available; used on headless/server installs)
- Backend selection persisted to `~/.config/zoolandia/secret_backend`; survives session restarts

**New Helper Functions:**
- `_zl_keyring_available()` — detects usable GNOME Keyring session (D-Bus only, no tool required)
- `_zl_secret_write()` / `_zl_secret_read()` / `_zl_secret_delete()` — backend-agnostic secret I/O
- `_zl_vault_write()` / `_zl_vault_read()` / `_zl_vault_delete()` — Vault KV helpers
- `ensure_vault()` — installs Vault CLI via Ansible and authenticates if needed
- `show_secret_backend_menu()` — user-facing backend selection dialog

**UX Improvements:**
- DNS credential menus now show masked display (last 4 chars visible: `****ab12`)
- Auto-prompt to run DNS API test after saving a credential
- Pre-filled edit dialog retains existing value for quick correction

**Security Fix** (`modules/11_system.sh`):
- `set_docker_folder()` now validates that `DOCKER_DIR` cannot be set to a path inside the Zoolandia installation directory, preventing secrets files from landing inside the git working tree

---

## [v6.0.23] - February 23, 2026

### Added — Secret Menu: Personal Project Launcher with Optional RSA Auth Gate

**New Module: `modules/60_personal.sh`**
- Added a **Secret** menu item to the main home screen (between Ansible and Tools)
- Auto-discovers projects from `ansible/roles/secret/` — no manual registration needed
- Supports two project layouts:
  - Directory-based: `ansible/roles/secret/<project-name>/site.yml` (or `main.yml`)
  - Standalone: `ansible/roles/secret/<name>.yml`
- Prompts for inventory/host if none is bundled; auto-detects bundled `inventory`, `hosts`, `inventory.yml`, `inventory.ini`, or `hosts.yml`
- Optional extra vars prompt before each run
- Prints run summary (playbook path, inventory, extra vars) and confirms before executing
- "Run Custom" option lets you run any playbook by full path without placing it in the secret directory

**Optional RSA Key Auth Gate:**
- Three variables at the top of `modules/60_personal.sh` control access:
  - `SECRET_AUTH_ENABLED=false` — set to true to enable the gate
  - `SECRET_KEY_PATH="${HOME}/.ssh/id_rsa"` — path to RSA private key
  - `SECRET_KEY_FINGERPRINT=""` — expected SHA256 fingerprint (leave empty to skip fingerprint check)
- Key-exists-only mode: confirms key file exists at `SECRET_KEY_PATH`
- Fingerprint-verified mode: runs `ssh-keygen -lf` and compares SHA256 fingerprint against `SECRET_KEY_FINGERPRINT`

**Files Changed:**
- `modules/60_personal.sh` — New module
- `modules/02_main_menu.sh` — Added "Secret" menu item; bumped dialog item count to 13
- `zoolandia.sh` — Added source for `modules/60_personal.sh`
- `ansible/roles/secret/` — New directory for personal/secret Ansible projects

---

## [v6.0.22] - February 7, 2026

### Added — Full Observability Monitoring Stack + App Server & Common Role Expansion

#### Monitoring Role (Docker-Based)

**New Ansible Role: `monitoring`**
- Complete `ansible/roles/monitoring/` role with defaults, vars, handlers, meta, tasks, and templates
- 8 Docker-based monitoring components with block/rescue error handling and failure tracking

**Monitoring Components:**
- Grafana (port 3000) — dashboard visualization
- Prometheus (port 9090) — metrics database with auto-generated scrape config
- InfluxDB (port 8086) — time-series database
- Telegraf (port 8125/udp) — metrics collection agent
- Node Exporter (port 9100) — host system metrics
- cAdvisor (port 8081) — Docker container metrics
- Elasticsearch (port 9200) — search and analytics engine (v8.17.0)
- Kibana (port 5601) — Elasticsearch visualization (v8.17.0)

**New Files:**
- `ansible/roles/monitoring/defaults/main.yml`, `vars/main.yml`, `handlers/main.yml`, `meta/main.yml`, `tasks/main.yml`
- `ansible/roles/monitoring/tasks/{grafana,prometheus,influxdb,telegraf,node_exporter,cadvisor,elasticsearch,kibana}.yml`
- `ansible/roles/monitoring/templates/prometheus.yml.j2` — auto-discovers node-exporter & cadvisor
- `ansible/roles/monitoring/templates/telegraf.conf.j2` — CPU, disk, memory, Docker, StatsD
- `ansible/playbooks/monitoring.yml` — playbook wrapper with post-task summary
- `compose/elasticsearch.yml`, `compose/kibana.yml`, `compose/telegraf.yml`, `compose/jenkins.yml`

**Tags:** `monitoring`, `grafana`, `prometheus`, `influxdb`, `telegraf`, `node-exporter`, `cadvisor`, `elk`, `elasticsearch`, `kibana`

#### App Server Role Expansion — Jenkins & Kubernetes

**Jenkins CI/CD (Docker-based):**
- Creates Jenkins appdata directory, adds compose/jenkins.yml, deploys and verifies container
- Tags: `['appserver', 'jenkins', 'cicd']`

**Kubernetes CLI Tools (Native APT):**
- Downloads Kubernetes GPG key from pkgs.k8s.io
- Adds Kubernetes v1.31 APT repository
- Installs kubectl, kubeadm, kubelet
- Tags: `['appserver', 'kubernetes', 'k8s']`

**Modified Files:**
- `ansible/roles/appserver/defaults/main.yml` — Added `install_jenkins`, `install_kubernetes`, `docker_dir`
- `ansible/roles/appserver/vars/main.yml` — Added Kubernetes GPG URL and repo
- `ansible/roles/appserver/handlers/main.yml` — Added Jenkins restart handler
- `ansible/roles/appserver/tasks/main.yml` — Added Jenkins and Kubernetes task blocks
- `ansible/playbooks/appserver.yml` — Updated post-tasks summary

#### Common Role Expansion — Node.js & Yarn

**Node.js (via NodeSource v20.x LTS):** Downloads GPG key, adds APT repo, installs nodejs
**Yarn (via Yarn vendor repo):** Downloads GPG key, adds APT repo, installs yarn
**Tags:** `['nodejs', 'development']`, `['yarn', 'development']`

**Modified Files:**
- `ansible/roles/common/vars/main.yml` — Added NodeSource and Yarn repo URLs
- `ansible/roles/common/tasks/main.yml` — Added Node.js and Yarn installation sections

#### Workstation Role Expansion — Sublime Text

**Sublime Text (via vendor APT repo):** Full block/rescue error handling with audit trail logging
**New File:** `ansible/roles/workstation/tasks/applications/complex/sublime_text.yml`
**Tags:** `['applications', 'sublime-text', 'editor', 'complex']`

**Modified Files:**
- `ansible/roles/workstation/defaults/main.yml` — Added `install_sublime_text` flag
- `ansible/roles/workstation/tasks/main.yml` — Added Sublime Text include

#### Ansible Menu Integration (`modules/41_ansible.sh`)

**New Functions:**
- `detect_installed_monitoring()` — detects 8 monitoring containers via `docker ps -a`
- `show_monitoring_menu()` — full checklist menu with "Install All" + individual tag-based installation

**Updated Functions:**
- `detect_installed_common()` — added Node.js and Yarn detection
- `detect_installed_apps()` — added Sublime Text detection
- `show_ansible_menu()` — added "Monitoring Stack" entry
- `show_common_menu()` — added nodejs and yarn checklist items
- `show_workstation_menu()` — added sublime-text checklist item
- `show_appserver_menu()` — added jenkins and kubernetes checklist items
- `show_all_applications_menu()` — added all new items with detection

**Site Playbook:** `ansible/site.yml` — Added `import_playbook: monitoring.yml`

---

## [v6.0.21] - January 25, 2026

### Added — DNS Provider Configuration, Chrome Extensions & Ansible Role Reorganization

#### Reverse Proxy Menu — DNS Provider Configuration

**DNS Provider Selection:**
- New "DNS Provider" option in reverse proxy menu
- Supports Cloudflare, ManageEngine CloudDNS, AWS Route53, DigitalOcean, GoDaddy, Manual

**Cloudflare Integration:**
- Configure API token (Zone:DNS:Edit permissions) and account email
- Test API connection to verify token validity
- Secure storage in secrets directory (chmod 600)

**ManageEngine CloudDNS Integration:**
- OAuth2 authentication with Client ID and Client Secret
- Automatic access token retrieval from `https://clouddns.manageengine.com/oauth2/token/`
- Zone lookup with exact and suffix matching
- Full TXT record create/update/delete for ACME challenges
- Helper functions: `get_clouddns_token()`, `get_clouddns_zone_id()`

**DNS Record Management:**
- `create_acme_txt_record()` — create TXT records for ACME challenges
- `delete_acme_txt_record()` — clean up after challenge
- Full Cloudflare and CloudDNS implementations

**UX:**
- All credential fields pre-populate with saved values
- "Clear" option on each provider menu
- Menus loop after entering credentials
- Status shows "(set)" or "Not set" per credential

**Configuration Storage:**
- DNS provider saved to `$ZOOLANDIA_CONFIG_DIR/dns_provider`
- Cloudflare: `cf_dns_api_token`, `cf_email`
- CloudDNS: `clouddns_client_id`, `clouddns_client_secret`
- Route53: `aws_access_key_id`, `aws_secret_access_key`, `aws_region`
- DigitalOcean: `digitalocean_token`
- GoDaddy: `godaddy_api_key`, `godaddy_api_secret`

#### Ansible Workstation Role — Chrome Extensions

**New Chrome Extensions Installer:**
- `chrome_extensions.yml` task installs browser extensions as unpacked to `~/.local/share/chrome-extensions/`
- Supports Chrome, Chromium, Vivaldi, Brave, and other Chromium-based browsers

**AI Chat Exporter Extension (gpt-xptr v1.2.2):**
- Export AI chat conversations to PDF, HTML, and Markdown
- Supports ChatGPT, Claude, Google Gemini, Microsoft Copilot, Perplexity AI

#### Ansible Role Reorganization

**New Security Role (`ansible/roles/security/`):**
- Dedicated security role; moved fail2ban, auditd from common; added clamav with freshclam

**New Configs Role (`ansible/roles/configs/`):**
- Consolidated: `power_management.yml`, `touchpad_settings.yml`, `mouse_settings.yml`, `nautilus_sort.yml`, `ntfs_automount.yml`, `razer_grub.yml`

**Package Distribution:**
- Workstation: tmux, fzf, ripgrep, bat
- Common: rclone, glances
- Security: fail2ban, clamav, auditd
- Configs: power, touchpad, mouse, nautilus, ntfs, razer

#### System Menu UX Improvements

- System Type Selection: removed intermediate submenu; options displayed directly
- Setup Mode Selection: removed intermediate submenu; current mode shown in header

---

## [v6.0.20] - January 24, 2026

### Added — Docker Menu Enhancements, Reverse Proxy Overhaul, GitHub Username & VS Code Tunnel

#### Docker Menu Enhancements

- Docker and Docker Compose version display in menu header
- "Install Dashboard" option deploying Homepage-based dashboard (port 3010)
  - System resource monitoring, Docker container status, customizable bookmarks
  - View/Start/Stop/Restart/Logs/Config/Remove management menu
- Disk Usage: Docker directory breakdown + Docker system disk usage with reclaimable space
- UFW Firewall Rules: Install/Remove Docker-specific UFW rules with DOCKER-USER chain
- Enhanced Docker Prune: granular cleanup — containers, images, volumes, networks, build cache

**Variable Renaming:**
- `DEPLOYIQDASHBOARD_PORT` → `ZOOLANDIA_DASHBOARD_PORT`

#### Reverse Proxy Menu Overhaul

**New Menu Items:**
- Exposure Mode — toggle Simple/Advanced
- Preparation — Traefik prep with DONE/NOT DONE status indicator
- Staging — Let's Encrypt staging certificates
- Production — Let's Encrypt production certificates
- Manage Exposure — view/change app exposure (Internal/External/Both counts)
- Traefikify — put an app behind Traefik with subdomain configuration
- Un-Traefikify — remove a Traefik file provider
- Domain Passthrough — configure passthrough to another Traefik instance
- Auth Bypass — set/generate/remove forward auth bypass key

**New Functions:**
- `toggle_exposure_mode()`, `traefik_preparation()`, `setup_traefik_staging()`, `setup_traefik_production()`
- `manage_exposure()`, `traefikify_app()`, `un_traefikify_app()`, `domain_passthrough()`, `set_auth_bypass()`

#### Prerequisites — GitHub Username

- GitHub username input with format validation (alphanumeric + hyphens, 1–39 chars)
- Persisted to `~/.config/zoolandia/github_username`
- Passed to Ansible playbooks via `-e github_username=<value>`
- `set_github_username()` function; `GITHUB_USERNAME` global variable

#### Ansible App Server Role — VS Code Tunnel

**New Role: `appserver`**
- Automated VS Code installation for ARM64 and AMD64
- Systemd service (`code-tunnel`) for persistent browser-based remote development
- Access via `https://vscode.dev/tunnel/<hostname>`
- Auto-restart on failure; network-online dependency

**New Files:**
- `ansible/playbooks/appserver.yml`, `ansible/roles/appserver/tasks/main.yml`
- `ansible/roles/appserver/templates/code-tunnel.service.j2`
- `ansible/roles/appserver/handlers/main.yml`, `defaults/main.yml`, `vars/main.yml`, `meta/main.yml`

**Ansible Menu Integration:**
- Added "App Server" to Ansible menu; VS Code Tunnel in All Applications list
- Prompts to set GitHub username if not configured; passes `github_username` to playbook

---

## [v6.0.19] - January 5, 2026

### Added — Alias Management Overhaul

**New Menu Items (System Menu):**
- Docker Aliases — view/install/run/uninstall Docker & Compose alias collection
- Kubernetes Aliases — view/install/run/uninstall kubectl alias collection
- DevOps Aliases — view/install/uninstall Git, Ansible, Terraform, and system aliases

**Docker Aliases (`show_docker_aliases_menu`):**
- View Aliases, Install Aliases, Run Docker Menu (no install required), Install Docker Menu (`dom`), Uninstall
- Installs to `~/.docker_aliases`; menu installed as `~/.local/bin/dom`
- 30+ aliases: dc, dcu, dcd, dcr, dps, dpa, dlog, dexec, dstats, dls, dlogs, dprune_*

**Kubernetes Aliases (`show_kubernetes_aliases_menu`):**
- View Aliases, Install Aliases, Run K8s Menu, Install K8s Menu (`k8m`), Uninstall
- Installs to `~/.k8s_aliases`; menu installed as `~/.local/bin/k8m`
- 40+ aliases: k, kctx, kns, kgp, klog, ksh, kdesc, kroll, khist, kwhere

**DevOps Aliases (`show_devops_aliases_menu`):**
- View Aliases, Install Aliases, Uninstall
- Installs to `~/.devops_extras`
- 150+ aliases: Git (40+), Ansible (15+), Terraform (15+), Systemd (8+), Tmux (10+), Rsync, SSH, Python, SSL

**Source Files:**
- `importing/docker.md` — Docker/Compose helpers
- `importing/kubernetes.md` — Kubernetes/kubectl helpers
- `importing/devops-extras.md` — DevOps tooling aliases
- `importing/docker-ops-menu.sh` — Interactive Docker TUI (whiptail/dialog)
- `importing/k8s-ops-menu.sh` — Interactive Kubernetes TUI (whiptail/dialog)

### Changed — v6.1.0

- Renamed "Bash Aliases" menu item to "Docker Aliases"
- System menu height 7→8; menu reorganized to separate Docker, Kubernetes, DevOps concerns
- All alias menus show "View" first, encouraging preview before install
- Removed redundant "About" extra button from System menu

### Fixed — v6.1.0

- Moved DevOps aliases out of Docker Aliases menu (unrelated to Docker)
- Users can now preview aliases before installing
- TUI menus can be launched without installing
- Shorter, memorable command names (`dom`, `k8m`)
- Independent uninstall per component with automatic bashrc cleanup

---

## [v6.0.18] - December 30, 2025

### Ansible NTFS/exFAT Automount Configuration + Menu Improvements

**New Ansible Playbook**: NTFS/exFAT drive automount configuration
- **Purpose**: Configure system to automatically mount external NTFS and exFAT drives
- **File**: `ansible/roles/common/tasks/ntfs_automount.yml`
- **Dual execution support**: Works from both Ansible menu and command line

**Playbook Features**:
- Installs required packages:
  - **ntfs-3g**: NTFS filesystem support (read/write)
  - **exfat-fuse**: exFAT filesystem driver
  - **exfatprogs**: exFAT filesystem utilities
- Blacklists ntfs3 kernel module (forces use of ntfs-3g for better compatibility)
- Updates initramfs to apply kernel module blacklist
- Comprehensive error handling with ignore_errors for robustness
- Detailed results display showing success/failure of each step
- Graceful handling of APT repository GPG issues

**Technical Implementation**:
- **Preliminary sudo test**: Forces password prompt at start of playbook
- **Separated apt cache update**: Independent task with error handling
- **Per-task privilege escalation**: `become: yes` on all root-requiring tasks
- **Conditional initramfs update**: Only runs if blacklist config changed
- **Variable existence checks**: Prevents crashes when tasks fail but are ignored

**Ansible Menu Integration**:
- Added "NTFS Automount" menu item to Ansible menu
- Menu position: Between "Package Updates" and "Razer 12.5"
- Description: "Configure NTFS/exFAT drive automounting"
- Menu dimensions updated: 20→21 height, 8→9 items

**Enhanced run_ansible_playbook() Function**:
- **NEW function** (modules/41_ansible.sh:9-57): Universal playbook execution handler
- Ansible installation verification
- Playbook file existence validation
- User confirmation dialog
- Clear terminal display with execution details
- Password prompt handling: `--ask-become-pass` flag
- Exit code capture and display
- Manual "Press Enter to continue" prompt
- **Dual execution support**: Works from menu or CLI

**Menu Spacing Improvements** (Prerequisites Menu):
- Added empty separator line before "Info" and "Back" items
- Reduces visual clutter between package tiers and utility options
- Menu height: 25→26 lines, items: 11→12
- Added empty case handler to prevent selection errors
- Improved visual organization and readability

**Usage Examples**:

From Ansible Menu:
```bash
bash hack3r.sh
# Navigate: Ansible → NTFS Automount
# Enter sudo password when prompted
```

From Command Line:
```bash
cd ansible
ansible-playbook -i inventories/production/localhost.yml -K \
  roles/common/tasks/ntfs_automount.yml
```

With environment variable:
```bash
export ANSIBLE_BECOME_PASSWORD='password'
ansible-playbook -i inventories/production/localhost.yml \
  roles/common/tasks/ntfs_automount.yml
```

**Files Created**:
- `ansible/roles/common/tasks/ntfs_automount.yml` (83 lines) - Main playbook

**Files Modified**:
- `modules/41_ansible.sh`:
  - Added run_ansible_playbook() function (lines 9-57)
  - Added "NTFS Automount" menu item (line 64)
  - Added case handler for NTFS Automount (lines 97-99)
  - Menu dimensions updated (line 74)
- `modules/10_prerequisites.sh`:
  - Added empty separator in menu (line 264)
  - Added empty case handler (line 290)
  - Menu dimensions updated (line 275: 25→26 height, 11→12 items)

**Ansible Configuration Files Referenced**:
- `ansible/inventories/production/localhost.yml` - Target inventory
- `ansible/ansible.cfg` - Global Ansible settings (become configuration)

**User Benefits**:
- Automatic mounting of NTFS drives (Windows filesystems)
- Automatic mounting of exFAT drives (common on USB/SD cards)
- Better filesystem compatibility for external storage
- Cross-platform storage support (Windows/Mac/Linux)
- One-click configuration via menu
- Repeatable automation via Ansible
- Clear feedback on configuration status
- Reboot reminder for kernel module changes

**Technical Details**:
- Uses ntfs-3g instead of kernel ntfs3 for better stability
- Blacklist configuration: `/etc/modprobe.d/disable-ntfs3.conf`
- Initramfs update ensures blacklist active on next boot
- Handles ProtonVPN repository GPG errors gracefully
- Password prompt timing optimized for localhost execution
- Compatible with both menu and CLI workflows

**Known Issues & Solutions**:
- **APT GPG errors**: ProtonVPN repository key issues are non-critical, packages install from cache
- **Password timing**: First task forces password prompt to avoid delayed prompts
- **Localhost execution**: Uses `become: yes` on tasks instead of play-level for better control

**Validation**:
- ✓ Bash module syntax validated
- ✓ YAML playbook syntax validated
- ✓ Ansible playbook syntax check passed
- ✓ Tested with both menu and CLI execution

---

## [v6.0.17] - December 30, 2025

### Power Tier Addition - Media and Power User Applications
- **Added New Power Tier**: Dedicated tier for power user applications and media tools
  - **Total packages**: 37 (unchanged)
  - **Total tiers**: 6 → 7 package tiers

**New Power Tier** (1 package):
- **Media Applications** (1 package):
  - **vlc**: VLC media player (moved from Optional)

**Updated Package Structure**:
- **Required** (5 packages) - Pre-installed essentials (view only)
- **Recommended** (11 packages) - Server utilities and networking tools
- **Enhanced** (16 packages) - Dev tools, build tools, security, filesystems, and system libs
- **Advanced** (5 packages) - Desktop enhancements, disk tools, and system info
- **Security** (1 package) - Hardware security and authentication tools
- **Power** (1 package) - Power user applications and media tools **(NEW)**
- **Optional** (3 packages) - Basic utilities and converters (reduced from 4)

**Menu Interface Updates**:
- Added "Power" menu item with status indicator
- Menu order: Required → Recommended → Enhanced → Advanced → Security → Power → Optional → All Packages → Info
- Power tier displays "X/1 INSTALLED" status with color coding
- Optional tier updated: "4/4" → "3/3" package count
- Main menu height increased: 24 → 25 lines

**Package Reorganization**:
- **Moved from Optional to Power**:
  - vlc (VLC media player)
- **Remaining in Optional** (3 packages):
  - nano, zip, html2text

**Package Info Dialog Updated**:
- Added "=== POWER ===" section with VLC description
- Power section positioned between Security and Optional
- Removed VLC from Optional section
- Dialog height increased: 53 → 56 lines

**Installation Functions**:
- **NEW install_power_packages()** (lines 646-714):
  - Installs VLC media player
  - Follows standard package installation pattern
  - Status checking, progress display, success confirmation
  - Dialog heights: 18x75 (package dialog), 20x80 (installation progress)
- install_optional_packages():
  - Removed vlc from package arrays
  - Updated from 4 to 3 packages
  - Dialog heights adjusted: 20→18
  - Success message updated (removed media player reference)
- install_all_packages():
  - Added Power tier to breakdown (1 package: vlc)
  - Updated Optional description (4 packages → 3 packages)
  - Total remains 37 packages
  - Dialog height increased: 40 → 42

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Added Power tier check (lines 227-238), menu item, case routing (lines 260, 284)
  - show_packages_menu() - Updated Optional check (3 packages) (lines 240-253)
  - show_packages_info() - Added Power section (lines 351-353, height 56)
  - install_power_packages() - NEW function for Power tier (lines 646-714)
  - install_optional_packages() - Removed vlc, updated counts (lines 716-786, height 18)
  - install_all_packages() - Updated breakdown with Power tier (lines 920-921, height 42)
- modules/00_core.sh - Version update to 6.0.17 (lines 10, 174)
- hack3r.sh - Version update to 6.0.17 (lines 4, 251)

**User Benefits**:
- Dedicated tier for power user and media applications
- Clear separation of media tools from basic utilities
- Better organization and categorization of packages
- VLC positioned as a power user tool rather than optional utility

**Technical Implementation**:
- Consistent package detection pattern using dpkg-query
- Real-time status indicators with color coding (green/red)
- Proper integration into "All Packages" installation workflow
- Standard error handling and progress display
- Package count remains 37 (reorganization, not addition)
- Syntax validation passed for all modified files

---

## [v6.0.16] - December 30, 2025

### Security Tier Addition - Hardware Authentication Tools
- **Added New Security Tier**: Dedicated tier for hardware security and authentication
  - **Total packages**: 36 → 37 installable packages
  - **Total tiers**: 5 → 6 package tiers

**New Security Tier** (1 package):
- **Hardware Authentication** (1 package):
  - **yubikey-manager**: YubiKey management and configuration tool

**Updated Package Structure**:
- **Required** (5 packages) - Pre-installed essentials (view only)
- **Recommended** (11 packages) - Server utilities and networking tools
- **Enhanced** (16 packages) - Dev tools, build tools, security, filesystems, and system libs
- **Advanced** (5 packages) - Desktop enhancements, disk tools, and system info
- **Security** (1 package) - Hardware security and authentication tools **(NEW)**
- **Optional** (4 packages) - Basic utilities, converters, and media

**Menu Interface Updates**:
- Added "Security" menu item with status indicator
- Menu order: Required → Recommended → Enhanced → Advanced → Security → Optional → All Packages → Info
- Security tier displays "X/1 INSTALLED" status with color coding

**Package Info Dialog Updated**:
- Added "=== SECURITY ===" section with yubikey-manager description
- Security section positioned between Advanced and Optional
- Dialog height increased: 50 → 53 lines

**Installation Functions**:
- **NEW install_security_packages()** (lines 557-625):
  - Installs yubikey-manager
  - Follows standard package installation pattern
  - Status checking, progress display, success confirmation
  - Dialog heights: 18x75 (package dialog), 20x80 (installation progress)
- install_all_packages():
  - Added yubikey-manager to installation array
  - Updated breakdown to include Security tier
  - Total updated: 36 → 37 packages
  - Dialog height increased: 38 → 40

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Added Security tier check and menu item (lines 214-225, 247, 269)
  - show_packages_info() - Added Security section (lines 332-334, height 53)
  - install_security_packages() - NEW function for Security tier (lines 557-625)
  - install_all_packages() - Added yubikey-manager, updated counts (lines 778-890, height 40)
- modules/00_core.sh - Version update to 6.0.16 (lines 10, 174)
- hack3r.sh - Version update to 6.0.16 (lines 4, 251)

**User Benefits**:
- Dedicated security tier for hardware authentication tools
- YubiKey support for two-factor authentication and credential management
- Clean separation of security tools from other package categories
- Organized menu structure for easier navigation

**Technical Implementation**:
- Consistent package detection pattern using dpkg-query
- Real-time status indicators with color coding (green/red)
- Proper integration into "All Packages" installation workflow
- Standard error handling and progress display
- Syntax validation passed for all modified files

---

## [v6.0.15] - December 30, 2025

### Package Expansion - Filesystem Support, Build Tools, and Media
- **Added 7 New Packages**: Expanded Enhanced, Advanced, and Optional tiers
  - **Total packages**: 29 → 36 installable packages

**Enhanced Tier Additions** (11 → 16 packages):
- **Filesystem Support** (3 packages):
  - **exfat-fuse**: exFAT filesystem driver for FUSE
  - **exfatprogs**: exFAT filesystem utilities (mkfs, fsck, etc.)
  - **ntfs-3g**: Read/write NTFS filesystem support
- **Build Tools** (2 packages):
  - **build-essential**: Compiler and build tools (gcc, g++, make, libc-dev)
  - **cmake**: Cross-platform build system generator

**Advanced Tier Additions** (4 → 5 packages):
- **Disk Management** (1 package):
  - **gparted**: GNOME Partition Editor (GUI disk partitioning tool)

**Optional Tier Additions** (3 → 4 packages):
- **Media** (1 package):
  - **vlc**: VLC media player (video and audio playback)

**Updated Package Structure**:
- **Required** (5 packages) - Pre-installed essentials (view only)
- **Recommended** (11 packages) - Server utilities and networking tools
- **Enhanced** (16 packages) - Dev tools, build tools, security, filesystems, and system libs
- **Advanced** (5 packages) - Desktop enhancements, disk tools, and system info
- **Optional** (4 packages) - Basic utilities, converters, and media

**Menu Interface Updates**:
- Enhanced tier status indicator: "11/11" → "16/16"
- Advanced tier status indicator: "4/4" → "5/5"
- Optional tier status indicator: "3/3" → "4/4"
- All status counters updated with correct package counts

**Package Info Dialog Updated**:
- Enhanced section reorganized into subsections:
  - Development (6 packages)
  - Build Tools (2 packages - NEW)
  - Security & Admin (4 packages)
  - System Libraries & Filesystems (4 packages - NEW)
- Advanced section: Added gparted description
- Optional section: Added vlc description
- Dialog height increased: 45 → 50 lines

**Installation Functions Updated**:
- install_enhanced_packages():
  - Added exfat-fuse, exfatprogs, ntfs-3g, build-essential, cmake
  - Updated descriptions and package arrays
  - Dialog heights adjusted: 26→32, 28→34
  - Success message updated
- install_advanced_packages():
  - Added gparted
  - Dialog heights adjusted: 20→22, 22→24
  - Success message updated
- install_optional_packages():
  - Added vlc
  - Dialog heights adjusted: 18→20
  - Success message updated
- install_all_packages():
  - Added all 7 new packages to installation array
  - Updated breakdown text with new counts
  - Total updated: 29 → 36 packages
  - Dialog height increased: 34 → 38

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Updated package counts (lines 184-227)
  - show_packages_info() - Added new packages and reorganized (lines 286-322, height 50)
  - install_enhanced_packages() - Added 5 new packages (lines 457-540)
  - install_advanced_packages() - Added gparted (lines 614-686)
  - install_optional_packages() - Added vlc (lines 542-613)
  - install_all_packages() - Added all 7 packages, updated counts (lines 688-810)
- modules/00_core.sh - Version update to 6.0.15 (line 10)
- hack3r.sh - Version update to 6.0.15 (lines 4, 251)

**User Benefits**:
- Full support for exFAT and NTFS filesystems (USB drives, external storage)
- Complete build toolchain for compiling software from source
- GUI disk partitioning tool for system management
- Media playback capability with VLC
- Better filesystem compatibility for cross-platform storage
- Development environment ready for C/C++ projects

**Technical Improvements**:
- Maintained consistent package detection across all tiers
- All status indicators updated with correct counts
- Proper integration into "All Packages" installation
- Dialog sizes adjusted for better readability

**Use Cases Enabled**:
- **Filesystem Support**: Mount and manage Windows NTFS drives, modern USB drives with exFAT
- **Build Tools**: Compile software from source, build custom applications, kernel modules
- **Disk Management**: Partition management, resize, create, delete partitions with GUI
- **Media Playback**: Play videos, music, and multimedia content

---

## [v6.0.14] - December 30, 2025

### Package Tier Naming Standardization
- **Standardized and Beautified Tier Names**: Complete tier naming overhaul for consistency
  - **Before**: Core Packages, Recommended Packages, Extended Packages, Enhanced, Additional Utilities
  - **After**: Required, Recommended, Enhanced, Advanced, Optional

**Tier Name Changes**:
1. **"Core Packages" → "Required"**: Simplified name for pre-installed essentials
2. **"Recommended Packages" → "Recommended"**: Kept simple, removed "Packages" suffix
3. **"Extended Packages" → "Enhanced"**: Better describes dev tools, security, and system libs
4. **"Enhanced" → "Advanced"**: Desktop enhancements moved to Advanced tier
5. **"Additional Utilities" → "Optional"**: Clearer purpose as optional basic utilities

**Package Reorganization**:
- **netcat-traditional moved**: Additional Utilities → Recommended
  - Reason: Fundamental networking diagnostic tool commonly used for server troubleshooting
  - Fits naturally with net-tools, dnsutils for network diagnostics
  - **Recommended packages**: 10 → 11 packages
  - **Optional packages**: 4 → 3 packages

**Updated Package Structure**:
- **Required** (5 packages) - Pre-installed essentials (view only)
  - dialog, curl, wget, git, jq
- **Recommended** (11 packages) - Server utilities and networking tools
  - htop, net-tools, dnsutils, openssl, ca-certificates, gnupg, lsb-release, rsync, unzip, smartmontools, netcat-traditional
- **Enhanced** (11 packages) - Dev tools, security, and system libs
  - libssl-dev, libffi-dev, python3-dev, python3-pip, python3-venv, apt-transport-https, apache2-utils, acl, pwgen, argon2, libnss-resolve
- **Advanced** (4 packages) - Desktop enhancements and system info
  - neofetch, gnome-tweaks, gnome-shell-extensions, gnome-extensions-app
- **Optional** (3 packages) - Basic utilities and converters
  - nano, zip, html2text

**Total Packages**: 29 installable (5 required pre-installed not counted)

**Menu Interface Updates**:
- All menu items updated with new tier names
- Menu descriptions updated for clarity:
  - Required: "Pre-installed essentials (view only)"
  - Recommended: "Server utilities and networking tools"
  - Enhanced: "Dev tools, security, and system libs"
  - Advanced: "Desktop enhancements and system info"
  - Optional: "Basic utilities and converters"
- Optional tier moved to bottom of list (before "All Packages")
- Color-coded status indicators maintained

**Function Renames**:
- view_core_packages() → view_required_packages()
- install_extended_packages() → install_enhanced_packages()
- install_enhanced_packages() → install_advanced_packages()
- install_additional_utilities() → install_optional_packages()

**Package Info Dialog Updated**:
- All tier names updated to new naming scheme
- "CORE" → "REQUIRED"
- "RECOMMENDED PACKAGES" → "RECOMMENDED"
- "EXTENDED PACKAGES" → "ENHANCED"
- "ENHANCED" → "ADVANCED"
- "ADDITIONAL UTILITIES" → "OPTIONAL"
- netcat-traditional moved to Recommended section
- Description updated: "Excludes Core" → "Excludes Required"

**All Packages Option Updated**:
- Breakdown text updated with new tier names
- Package counts updated:
  - Recommended: 10 → 11 (added netcat-traditional)
  - Enhanced: 11 (unchanged, renamed from Extended)
  - Advanced: 4 (renamed from Enhanced)
  - Optional: 4 → 3 (removed netcat-traditional)
- Note updated: "Core packages are already pre-installed" → "Required packages are already pre-installed"

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Updated all tier names and status checks (lines 163-227)
  - Menu items array - Updated all tier names and descriptions (lines 229-238)
  - Case statement - Updated all function calls (lines 250-259)
  - show_packages_info() - Updated all tier names in info dialog (lines 263-322)
  - view_required_packages() - Renamed from view_core_packages() (lines 324-367)
  - install_recommended_packages() - Added netcat-traditional (lines 369-447)
  - install_enhanced_packages() - Renamed from install_extended_packages() (lines 449-527)
  - install_optional_packages() - Renamed from install_additional_utilities(), removed netcat-traditional (lines 529-599)
  - install_advanced_packages() - Renamed from install_enhanced_packages() (lines 601-673)
  - install_all_packages() - Updated breakdown text (lines 714-731)
- modules/00_core.sh - Version update to 6.0.14 (line 10)
- hack3r.sh - Version update to 6.0.14 (lines 4, 251)

**User Benefits**:
- Cleaner, more standardized tier naming
- Easier to understand package organization
- netcat-traditional properly grouped with networking tools
- Consistent naming convention across all tiers
- Better visual hierarchy (optional at bottom)

**Technical Improvements**:
- All function names follow consistent naming pattern
- Maintained accurate package detection across all tiers
- All dialog titles updated to match new names
- Success messages updated with new terminology

---

## [v6.0.13] - December 30, 2025

### Enhanced Package Tier Added
- **New Enhanced Packages Tier**: Added desktop enhancements and system information tools
  - **Purpose**: GNOME desktop customization and system information display
  - **Total packages**: 4

**Enhanced Packages**:
- **neofetch**: System information display tool
- **gnome-tweaks**: GNOME desktop customization utility
- **gnome-shell-extensions**: GNOME Shell extensions support
- **gnome-extensions-app**: Extensions management application

**Menu Interface Updates**:
- Added "Enhanced" menu item with status indicator
- Menu description: "Desktop enhancements and system info"
- Color-coded status: Green (all installed), Yellow (partial), Red (none installed)
- Shows "X/4 INSTALLED" counter in menu

**All Packages Option Updated**:
- **New total**: 29 packages (previously 25)
- Breakdown: Recommended (10) + Extended (11) + Additional (4) + Enhanced (4)
- Updated installation descriptions and package counts
- Dialog height increased from 30 to 34 lines to accommodate new tier

**Package Info Dialog Updated**:
- Added Enhanced packages section with descriptions
- Updated dialog height from 40 to 45 lines
- Shows all 4 Enhanced packages with detailed descriptions

**New Function Added**:
- install_enhanced_packages() - Complete installation workflow
  - Shows installed/missing package lists
  - Individual package status with ✓ checkmarks and ○ markers
  - Accurate status counter
  - Installation progress with dialog --programbox
  - Success message after installation

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Added Enhanced tier check (lines 214-227)
  - show_packages_menu() - Added Enhanced menu item (line 234)
  - Case statement - Added Enhanced option (line 255)
  - show_packages_info() - Added Enhanced section (lines 309-314, dialog height 45)
  - install_enhanced_packages() - NEW FUNCTION (lines 601-672)
  - install_all_packages() - Added Enhanced packages to all_packages array (line 678)
  - install_all_packages() - Updated description text (lines 724-726)
  - install_all_packages() - Updated total count to 29 (line 727)
  - install_all_packages() - Updated dialog height to 34 (line 735)
  - install_all_packages() - Added Enhanced packages to apt-get install (lines 770-773)
- modules/00_core.sh - Version update to 6.0.13 (line 10)
- hack3r.sh - Version update to 6.0.13 (lines 4, 251)

**User Benefits**:
- GNOME desktop users can now easily install customization tools
- System information display with neofetch
- Better GNOME Shell extensions management
- All desktop enhancement tools in one organized tier

**Technical Improvements**:
- Maintained consistent package detection across all tiers
- Proper status indicators with color coding
- Complete installation workflow with progress display
- All packages included in "All Packages" option

---

## [v6.0.12] - December 30, 2025

### Package Tier Reorganization
- **Restructured Package Tiers**: Reorganized package management system for better clarity
  - **Before**: 5 separate tiers (Core, Recommended, Development, Security/Admin, Additional Utilities)
  - **After**: 4 tiers with logical grouping (Core, Recommended, Extended, Additional Utilities)

**Changes to Recommended Packages**:
- **Added smartmontools**: Disk monitoring and SMART analysis tool
- **New count**: 10 packages (previously 9)
- **Package list**: htop, net-tools, dnsutils, openssl, ca-certificates, gnupg, lsb-release, rsync, unzip, smartmontools

**New Extended Packages Tier**:
- **Merged Development + Security + System Libraries**: Combined three categories into one comprehensive tier
- **Total packages**: 11 (6 dev + 4 security + 1 system lib)
- **Development tools** (6): libssl-dev, libffi-dev, python3-dev, python3-pip, python3-venv, apt-transport-https
- **Security & Admin** (4): apache2-utils, acl, pwgen, argon2
- **System Libraries** (1): libnss-resolve (moved from Additional Utilities)
- **Menu description**: "Dev tools, security, and system libs"

**Updated Additional Utilities**:
- **Removed libnss-resolve**: Moved to Extended Packages tier
- **New count**: 4 packages (previously 5)
- **Package list**: nano, zip, html2text, netcat-traditional

**All Packages Option Updated**:
- **New total**: 25 packages (previously 24)
- Breakdown: Recommended (10) + Extended (11) + Additional (4)
- Updated installation descriptions and package counts

**Menu Interface Updates**:
- Removed "Security/Admin Tools" menu item (merged into Extended)
- Renamed "Development Packages" to "Extended Packages"
- Updated status indicators to show correct package counts
- Color-coded status: Green (all installed), Yellow (partial), Red (none installed)

**Package Info Dialog Updated**:
- Reorganized package information display
- Extended Packages section shows three subsections:
  - Development
  - Security & Admin
  - System Libraries
- Updated dialog height from 32 to 40 lines to accommodate new layout

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Updated tier checks and menu items (lines 159-243)
  - show_packages_info() - Updated package information display (lines 246-298)
  - install_recommended_packages() - Added smartmontools (lines 345-422)
  - install_development_packages() → install_extended_packages() - Merged and renamed (lines 424-502)
  - install_security_tools() - REMOVED (functionality merged into install_extended_packages)
  - install_additional_utilities() - Removed libnss-resolve (lines 504-575)
  - install_all_packages() - Updated counts and package list (lines 577-680+)
- modules/00_core.sh - Version update to 6.0.12 (line 10)
- hack3r.sh - Version update to 6.0.12 (lines 4, 251)

**User Benefits**:
- Simpler package tier structure (4 instead of 5)
- Logical grouping of development, security, and system packages
- Better organization reduces menu clutter
- smartmontools included in recommended tier for disk health monitoring
- More intuitive package categorization

**Technical Improvements**:
- Eliminated duplicate Security/Admin function
- Consolidated related packages into single tier
- Maintained accurate package detection across all tiers
- Updated all package counts and descriptions

---

## [v6.0.11] - December 30, 2025

### Package Detection System Refactored
- **Fixed Package Installation Status Counting**: Completely refactored package detection logic
  - **Problem**: Package status showing "0 of X packages installed" when packages were actually installed
  - **Root Cause**: `dpkg -l | grep` pattern was unreliable for package detection
  - **Solution**: Replaced with `dpkg-query -W -f='${Status}'` for accurate detection

**New Package Detection Features**:
- **Separate "Currently Installed" and "Not Installed" Lists**: Each package menu now shows:
  - Currently Installed section with ✓ checkmarks
  - Not Installed section with ○ markers
  - Accurate status counter (e.g., "Status: 5 of 9 packages installed")

- **Enhanced Menu Status Indicators**: Package menu now shows:
  - Real-time package counts (e.g., "3/9 INSTALLED" in yellow)
  - "ALL INSTALLED" in green when tier is complete
  - "0/9 INSTALLED" in red when none installed
  - Proper color coding: \Z2 (green), \Z3 (yellow), \Z1 (red)

- **All Packages Function Updated**:
  - Shows comprehensive list of installed packages
  - Shows list of missing packages
  - Displays counts for both categories
  - Returns early if all 24 packages already installed

**Implementation Details**:
- Replaced `dpkg -l | grep -q "^ii  $pkg "` with `dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"`
- More reliable detection that works with all package names
- Handles missing packages gracefully (2>/dev/null)
- Consistent detection method across all 5 package functions

**Files Modified**:
- modules/10_prerequisites.sh:
  - show_packages_menu() - Updated menu status detection (lines 159-227)
  - install_recommended_packages() - Refactored with installed/missing lists (lines 320-369)
  - install_development_packages() - Refactored with installed/missing lists (lines 398-449)
  - install_security_tools() - Refactored with installed/missing lists (lines 475-524)
  - install_additional_utilities() - Refactored with installed/missing lists (lines 548-597)
  - install_all_packages() - Refactored with comprehensive lists (lines 622-662)

**User Benefits**:
- Accurate package status display
- Clear visibility of what's installed vs. missing
- No more confusion about package installation state
- Better decision-making before installing packages
- Prevents unnecessary installation attempts

**Technical Improvements**:
- More robust package detection
- Consistent checking method across all functions
- Proper error handling with 2>/dev/null
- Cleaner code structure with separate installed/missing lists

---

## [v6.0.10] - December 30, 2025

### Session Logging
- **Added Comprehensive stdout.log**: Created detailed session log in `documentation/stdout/`
  - Documents all changes made in this development session
  - Includes task descriptions, implementations, and validations
  - Tracks version increments and decision rationale
  - Provides complete audit trail for v6.0.0 release cycle

**Files Added**:
- documentation/stdout/stdout.log

---

## [v6.0.9] - December 30, 2025

### Package Menu Status Enhancement
- **Added Installation Status Counters**: All package menus now show "Status: X of Y packages installed"
  - Provides immediate visibility of what's already installed before choosing to install
  - Helps users understand current package state on their system
  - Individual package status with checkmarks (✓) for installed packages
  - Applied to all package tiers:
    - Recommended Packages (9 packages)
    - Development Packages (6 packages)
    - Security/Admin Tools (4 packages)
    - Additional Utilities (5 packages)
    - All Packages (24 packages total)

**Implementation Details**:
- Each package menu counts installed vs total packages
- Displays status counter at top (e.g., "Status: 5 of 9 packages installed")
- Shows individual package descriptions
- Clear indication of what will be installed vs. what's already present

**Files Modified**:
- modules/10_prerequisites.sh:
  - install_recommended_packages()
  - install_development_packages()
  - install_security_tools()
  - install_additional_utilities()
  - install_all_packages()

---

## [v6.0.8] - December 30, 2025

### Colored Status Indicators
- **Added Color Coding**: Prerequisites status in main menu now uses colors
  - "DONE" displays in GREEN (\Z2)
  - "NOT DONE" displays in RED (\Z1)
  - Added `--colors` flag to dialog command for color support
  - Improved visual feedback for completion status

**Files Modified**:
- modules/02_main_menu.sh (lines 20, 33)

**Technical Details**:
- Dialog color codes: \Z2 (green), \Z1 (red), \Zn (reset)
- Color support enabled with --colors flag

---

## [v6.0.7] - December 30, 2025

### ASCII Art Branding Fix
- **Fixed Old DeployIQ ASCII Art**: Replaced remaining old branding with Zoolandia
  - Updated display_splash() and display_banner() functions in modules/00_core.sh
  - Functions were being called but contained old DeployIQ ASCII art
  - New Zoolandia ASCII art now displays correctly in all locations
  - Maintains attribution: "by D.Garner - http://hack3r.gg"

**New ASCII Art**:
```
 ███████╗ ██████╗  ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ ██╗ █████╗
 ╚══███╔╝██╔═══██╗██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗██║██╔══██╗
   ███╔╝ ██║   ██║██║   ██║██║     ███████║██╔██╗ ██║██║  ██║██║███████║
  ███╔╝  ██║   ██║██║   ██║██║     ██╔══██║██║╚██╗██║██║  ██║██║██╔══██║
 ███████╗╚██████╔╝╚██████╔╝███████╗██║  ██║██║ ╚████║██████╔╝██║██║  ██║
 ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═╝
```

**Files Modified**:
- modules/00_core.sh (display_banner, display_splash functions)
- hack3r.sh (header comments, website references)

---

## [v6.0.6] - December 30, 2025

### Complete Project Rebranding
- **Project Name Change**: Complete rebranding from "DeployIQ" to "Zoolandia"
  - Script Name: DeployIQ → Zoolandia
  - Variable Prefix: DEPLOYIQ_* → ZOOLANDIA_*
  - Configuration Directory: ~/.config/deployiq → ~/.config/zoolandia
  - Cache Directory: /var/tmp/deployiq → /var/tmp/zoolandia
  - Script Mode Variable: DEPLOYIQ_MODE → ZOOLANDIA_MODE

**Files Updated** (comprehensive rebrand):
- All 16 module files (modules/*.sh)
- All documentation files (documentation/*.md)
- All configuration files (*.yml, *.yaml)
- README, CHANGELOG, and all analysis documents
- Package information screens
- Dialog headers and messages
- Welcome screen and all menu titles

**Variables Updated**:
- ZOOLANDIA_VERSION (formerly DEPLOYIQ_VERSION)
- ZOOLANDIA_CONFIG_DIR (formerly DEPLOYIQ_CONFIG_DIR)
- ZOOLANDIA_CACHE_DIR (formerly DEPLOYIQ_CACHE_DIR)
- ZOOLANDIA_MODE (formerly DEPLOYIQ_MODE)
- SCRIPT_NAME="Zoolandia" (formerly "DeployIQ")

**File Paths Updated**:
- Configuration: ~/.config/zoolandia/
- Cache: /var/tmp/zoolandia/
- Logs: .zoolandia/logs/
- State files: .zoolandia/setup_complete
- Temp files: /tmp/zoolandia_*

**Website Updates**:
- Changed from deployiq.app to simplehomelab.com
- Maintained attribution to D. Garner - http://hack3r.gg

**Validation**:
- All 16 modules tested with `bash -n` - PASSED
- 100+ files affected
- 200+ occurrences of DeployIQ replaced with Zoolandia

---

## [v6.0.5] - December 30, 2025

### Package Installation System Overhaul
- **Multi-Tier Package System**: Complete restructure with 5 distinct tiers
  - **Before**: Single "Packages" menu installing all packages at once
  - **After**: Organized into Core, Recommended, Development, Security/Admin, and Additional Utilities

**Package Tiers**:

1. **Core Packages (Pre-installed - View Only)**:
   - View-only mode with no installation option
   - Clearly states "These packages are installed before Zoolandia runs"
   - Shows installation status with checkmarks (✓)
   - Packages: dialog, curl, wget, git, jq (5 total)
   - Status indicator: PRE-INSTALLED / MISSING

2. **Recommended Packages (Server Utilities)**:
   - Server utilities and monitoring tools
   - Packages (9 total): htop, net-tools, dnsutils, openssl, ca-certificates, gnupg, lsb-release, rsync, unzip
   - Individual checkmarks for installed packages

3. **Development Packages (Recommended)**:
   - Python development and build tools
   - Packages (6 total): libssl-dev, libffi-dev, python3-dev, python3-pip, python3-venv, apt-transport-https
   - Note: ca-certificates is in Recommended Packages tier

4. **Security/Admin Tools**:
   - Security and system administration utilities
   - Packages (4 total): apache2-utils, acl, pwgen, argon2
   - ufw removed per user request (firewall better handled separately)

5. **Additional Utilities**:
   - Text editing and network utilities
   - Packages (5 total): nano, zip, html2text, libnss-resolve, netcat-traditional

**All Packages Option**:
- Installs all tiers except Core (already pre-installed)
- Total: 24 packages across all tiers
- Displays complete breakdown before installation

**UX Improvements**:
- Status indicators across all tiers
- Each package displays ✓ if installed, blank if not
- Users see exactly what needs installation before proceeding
- Enhanced installation dialogs with live progress
- Package lists with descriptions shown before installation
- Install/Cancel buttons for user confirmation
- Live installation progress with `dialog --programbox`
- Success messages with tier-specific completion notes
- Users remain in Zoolandia menu system throughout (no terminal drops)

**Files Modified**:
- modules/10_prerequisites.sh (complete package system rewrite)

---

## [v6.0.4] - December 30, 2025

### Ansible Analysis - Recommendations
- **Created ansible-setup-recommendations.md**: Comprehensive improvement recommendations
  - 862 lines, 22KB of detailed analysis
  - 17 prioritized improvement recommendations
  - Critical issues (hardcoded username, security concerns, conflicting settings)
  - Important issues (deprecated modules, version pinning, error handling)
  - Enhancement opportunities (progress reporting, modularization, testing)
  - Implementation priority matrix
  - Quick wins section (low effort, high benefit)
  - Long-term architecture recommendations
  - Code examples for each recommendation
  - Testing and CI/CD recommendations

**Files Added**:
- documentation/analysis/ansible-setup-recommendations.md

---

## [v6.0.3] - December 30, 2025

### Ansible Analysis - Inventory
- **Created ansible-setup-inventory.md**: Complete catalog of Ansible setup.yml
  - 256 lines, 8.3KB of documentation
  - Complete catalog of 17 applications installed by setup.yml
  - System configurations (power management, touchpad settings)
  - Installation methods breakdown (Snap, APT, Docker, Shell scripts)
  - Dependencies and prerequisites listing
  - Package repositories added
  - Post-installation actions required
  - Hardcoded values documentation
  - Summary statistics

**Applications Cataloged**:
- Web browsers, Communication tools, Productivity apps
- Security & VPN tools, Development & Automation tools
- System utilities

**Files Added**:
- documentation/analysis/ansible-setup-inventory.md

---

## [v6.0.2] - December 30, 2025

### Documentation Organization
- **Centralized Documentation Structure**: All documentation moved to `documentation/` folder
  - Moved files: CHANGELOG.md, README.md, APPS.md, latest-version
  - Updated .gitignore patterns to track documentation properly
  - Updated module references to point to new locations
  - Creates clear separation between code and documentation

**Module Updates**:
- Updated view_changelog() function to point to $SCRIPT_DIR/documentation/CHANGELOG.md
- All documentation references updated throughout modules

**Files Modified**:
- .gitignore (added documentation patterns)
- modules/50_about.sh (changelog path update)

**Files Moved**:
- CHANGELOG.md → documentation/CHANGELOG.md
- README.md → documentation/README.md
- APPS.md → documentation/APPS.md
- latest-version → documentation/latest-version

---

## [v6.0.1] - December 30, 2025

### Menu Reorganization
- **Feedback Menu Relocation**: Moved "Feedback" menu item from Main Menu to About submenu
  - **Before**: Main Menu → Feedback (top-level menu item)
  - **After**: Main Menu → About → Feedback
  - Consolidates feedback with other informational items (License, Changelog, Documentation)
  - Reduces main menu clutter
  - Better organization of user-facing documentation and support features

**Files Modified**:
- modules/02_main_menu.sh (removed Feedback from main menu items)
- modules/50_about.sh (added Feedback to About submenu)

---

## [v6.0.0] - December 30, 2025

### MAJOR RELEASE - Modular Architecture

This is a major version release reflecting the complete modular refactoring of the codebase.

**Architecture Changes**:
- **Modular Code Structure**: Complete refactoring to modular architecture
  - All functionality split into 16 independent modules (modules/*.sh)
  - Main entry point: hack3r.sh
  - Core module: modules/00_core.sh (sourced first)
  - Functional modules: 01-50 series
  - Clean separation of concerns and improved maintainability

**Module Structure**:
- 00_core.sh - Core variables and functions
- 01_homepage.sh - Welcome screen
- 02_main_menu.sh - Main menu interface
- 10_prerequisites.sh - Prerequisites and packages
- 11_system.sh - System preparation
- 12_docker.sh - Docker management
- 13_reverse_proxy.sh - Reverse proxy (Traefik)
- 14_security.sh - Security and authentication
- 20_apps.sh - Application management
- 21_docker_apps.sh - Docker applications menu
- 22_system_apps.sh - System applications menu
- 30_tools.sh - Tools and utilities
- 31_backup.sh - Backup functionality
- 40_settings.sh - Settings menu
- 41_ansible.sh - Ansible menu
- 50_about.sh - About and feedback

**Technical Improvements**:
- Syntax validation for all modules
- Improved error handling
- Dialog-based interactions keep users in menu system
- Code quality improvements for maintainability

---

## [v5.10.7] - December 30, 2025

### Menu Restructure
- **Feedback Menu Relocated**: Moved "Feedback" menu item from Main Menu to About submenu
  - **Before**: Main Menu → Feedback (top-level menu item)
  - **After**: Main Menu → About → Feedback
  - Consolidates feedback with other informational items (License, Changelog, Documentation)
  - Reduces main menu clutter
  - Better organization of user-facing documentation and support features

### Documentation Organization
- **Documentation Folder Structure**: Centralized all documentation files into `documentation/` folder
  - **Moved files**: CHANGELOG.md, README.md, APPS.md, latest-version
  - **Updated .gitignore**: Added `!documentation/*` and `!documentation/*/*` patterns to track documentation
  - **Updated module references**: `view_changelog()` now points to `$SCRIPT_DIR/documentation/CHANGELOG.md`
  - Creates clear separation between code and documentation
  - Easier to find and maintain project documentation

- **Ansible Analysis Documentation**: Created comprehensive Ansible setup.yml analysis in `documentation/analysis/`
  - **ansible-setup-inventory.md** (256 lines, 8.3KB):
    - Complete catalog of 17 applications installed by setup.yml
    - System configurations (power management, touchpad settings)
    - Installation methods breakdown (Snap, APT, Docker, Shell scripts)
    - Dependencies and prerequisites listing
    - Package repositories added
    - Post-installation actions required
    - Hardcoded values that need attention
    - Summary statistics
  - **ansible-setup-recommendations.md** (862 lines, 22KB):
    - 17 prioritized improvement recommendations
    - Critical issues (hardcoded username, security concerns, conflicting settings)
    - Important issues (deprecated modules, version pinning, error handling)
    - Enhancement opportunities (progress reporting, modularization, testing)
    - Implementation priority matrix
    - Quick wins section (low effort, high benefit)
    - Long-term architecture recommendations
    - Code examples for each recommendation
    - Testing and CI/CD recommendations

### Package Installation System Overhaul
- **Multi-Tier Package System**: Completely restructured package installation with 5 distinct tiers
  - **Before**: Single "Packages" menu installing all packages at once
  - **After**: Organized into Core, Recommended, Development, Security/Admin, and Additional Utilities tiers

- **Core Packages (Pre-installed - View Only)**:
  - Changed to view-only mode with no installation option
  - Clearly states "These packages are installed before DeployIQ runs"
  - Shows installation status with checkmarks (✓) for each package
  - Packages: dialog, curl, wget, git, jq (5 total)
  - Status: PRE-INSTALLED / MISSING

- **Recommended Packages (Server Utilities)**:
  - Server utilities and monitoring tools
  - Shows installation status with ✓ for installed packages
  - Packages: htop, net-tools, dnsutils, openssl, ca-certificates, gnupg, lsb-release, rsync, unzip (9 total)
  - Moved from Core: openssl, ca-certificates, gnupg, lsb-release
  - Removed: apt-transport-https (moved to Development)

- **Development Packages (Recommended for Python Development)**:
  - Marked as "(Recommended)" in both title and menu
  - Completely revised to focus on Python development and build tools
  - Shows installation status with ✓ for installed packages
  - **New packages** (6 total):
    - libssl-dev (OpenSSL development libraries)
    - libffi-dev (FFI development libraries)
    - python3-dev (Python development headers)
    - python3-pip (Python package installer)
    - python3-venv (Python virtual environments)
    - apt-transport-https (HTTPS transport for APT)
  - **Removed packages**:
    - git (moved to Core as pre-installed)
    - ansible (removed - specialized use case)
    - software-properties-common (removed)
    - sshpass (removed)
  - Note displayed: "ca-certificates is in Recommended Packages tier"

- **Security/Admin Tools**:
  - Security and system administration utilities
  - Shows installation status with ✓ for installed packages
  - Packages: apache2-utils, acl, pwgen, argon2 (4 total)
  - **Removed**: ufw (per user request - firewall configuration better handled separately)

- **Additional Utilities**:
  - Text editing and network utilities
  - Shows installation status with ✓ for installed packages
  - Packages: nano, zip, html2text, libnss-resolve, netcat-traditional (5 total)

- **All Packages Option**:
  - Installs all tiers except Core (already pre-installed)
  - Total: 24 packages (9+6+4+5)
  - Shows package count for each tier
  - Displays breakdown before installation

### Package Installation UX Improvements
- **Status Indicators Across All Tiers**: All package installation dialogs now show current status
  - Each package displays ✓ if installed, blank if not installed
  - Users can see exactly what needs to be installed before proceeding
  - Matches Core Packages view-only interface style
  - Prevents unnecessary reinstallation of existing packages

- **Enhanced Installation Dialogs**: All package tier dialogs improved
  - Package lists with descriptions shown before installation
  - Current installation status visible for each package
  - Install/Cancel buttons for user confirmation
  - Live installation progress with `dialog --programbox`
  - Success message with tier-specific completion note
  - Users remain in DeployIQ menu system throughout (no terminal drops)

- **Menu Status Tracking Updated**:
  - Core: Checks dialog, curl, git, jq
  - Recommended: Checks htop, rsync
  - Development: Checks python3-dev, python3-pip (updated from ansible)
  - Security: Checks pwgen, apache2-utils (updated, no longer checks ufw)
  - Utilities: Checks nano, html2text

### Prerequisites Menu Updates
- **Package Menu Rename**: "Packages" → "Additional Packages"
  - Better reflects that Core packages are pre-installed
  - Description: "Package Installation Options"
  - Opens submenu with 8 options (5 tiers + All + Info + Back)

- **Info Screen**: Comprehensive package information dialog
  - Lists all packages in each tier with descriptions
  - Explains purpose of each tier
  - Notes which packages are pre-installed
  - Clarifies package placement (e.g., ca-certificates location)

### Benefits
- **Better Organization**: Logical grouping of packages by purpose (server, development, security, utilities)
- **User Choice**: Install only what's needed instead of all-or-nothing approach
- **Status Visibility**: See what's installed before making decisions
- **Python Focus**: Development tier specifically targets Python development needs
- **Reduced Bloat**: Security tier streamlined by removing ufw
- **Clear Documentation**: Comprehensive analysis of existing Ansible automation
- **Professional Structure**: Centralized documentation folder follows industry standards

---

## [v5.10.6] - December 28, 2025

### Ansible Execution Improvements
- **Real-Time Playbook Progress**: Ansible playbook execution now shows live output during installation
  - **Before**: Showed "This may take a while..." with no progress indication, output only shown after completion
  - **After**: Uses `dialog --programbox` to display real-time task execution and progress
  - Users can now see:
    - Which packages/apps are being installed
    - Current task being executed
    - Installation progress and status
    - Any warnings or errors as they occur
  - Affected functions:
    - `run_ansible_playbook()`: Main playbook execution (Onboarding, Power Management, Touchpad, etc.)
    - `install_ansible_app()`: System app installations (Discord, Docker, Notion, etc.)
  - Exit status properly captured using `${PIPESTATUS[0]}` to determine success/failure
  - Better user experience with visibility into long-running operations

### Path Display Improvements
- **Display Path Helper Function**: Added `display_path()` function to convert absolute paths to user-friendly display formats
  - Replaces home directory paths with `~` for cleaner display
  - Replaces script directory paths with `./` for relative display
  - Prevents exposure of usernames in dialog messages

- **Dialog Message Updates**: Fixed all dialog messages that previously displayed absolute paths
  - **Ansible playbook dialogs**: Now show relative paths instead of `/home/username/Documents/...`
  - **Docker folder creation**: Shows `~/docker` instead of `/home/username/docker`
  - **Configuration paths**: Authentication, secrets, and config file paths now display with `~`
  - **Backup operations**: Backup source/destination paths use relative display
  - **Error messages**: All error dialogs now show user-friendly paths
  - Affected functions:
    - `run_ansible_playbook()`: Playbook and inventory paths
    - `create_docker_env()`: Docker environment creation
    - `install_authelia()`, `install_tinyauth()`, `install_google_oauth()`: Authentication setup paths
    - `view_crowdsec_configs()`, `view_provider_configs()`, `view_secrets_configs()`: Configuration file browsers
    - `show_backup_menu()`: Backup operations
    - `check_permissions()`: Permission check results

- **Benefits**:
  - Cleaner, more professional UI
  - No username exposure in screenshots or shared output
  - Paths are more portable and easier to read
  - Consistent display format across all dialogs

---

## [v5.10.5] - December 26, 2025

### Menu Improvements
- **Ansible Menu**: Added "Install Ansible" as first menu option
  - Checks if Ansible is already installed and shows version
  - Installs Ansible with recommended packages: python3, python3-pip, sshpass, software-properties-common
  - Shows installation progress with programbox dialog
  - Verifies successful installation before completing
  - Makes it easier for new users to get started with Ansible automation

### Project Structure Changes
- **Ansible Reorganization**: Moved `setup.yml` from `./ansible/roles/common/tasks/` to `./ansible/roles/common/playbooks/`
  - Better organization separating playbooks from tasks
  - Aligns with Ansible best practices for project structure
  - Updated "New System Onboarding" menu item to reference new location

- **Compose Directory Cleanup**: Removed system applications from `./compose` directory
  - **Affected apps**: Bitwarden, Discord, Docker, iCloud, Mailspring, n8n, Notepad++, Notion, ONLYOFFICE, Portainer, Proton VPN, Termius, Twingate, ulauncher, Vivaldi, Zoom
  - These 16 applications are managed via Ansible playbooks (in `setup.yml`), not Docker Compose
  - Keeps `./compose` directory exclusively for Docker containerized applications
  - Apps menu automatically reflects available services based on compose files
  - System apps remain accessible through Ansible installation workflows

---

## [v5.10.4] - December 25, 2025

### Major Fixes
- **Prerequisites Menu - Package Status Bug**: Fixed critical bug where "Packages" status would always show "NOT DONE" even after successful installation
  - Root cause: Status check was looking for both `dialog` AND `docker`, but `install_required_packages()` only installed dialog
  - Solution: Separated Packages and Docker into two distinct menu items with independent status checks
  - **Packages** now checks only for `dialog` installation
  - **Docker** is now a separate menu item that checks for Docker and Docker Compose installation

- **Path References - Hardcoded Paths Fixed**: Fixed all hardcoded absolute paths to use `$SCRIPT_DIR` variable
  - Onboarding menu items now work regardless of script installation location
  - SysConfig menu playbook paths now relative to script directory
  - System Apps menu now uses relative paths for compose files
  - Affected paths:
    - `setup_full.yml`: `/media/cicero/ONN/proj-dev/DeployIQ/ansible/...` → `$SCRIPT_DIR/ansible/...`
    - `setup_all.yml`: `/media/cicero/ONN/proj-dev/DeployIQ/ansible/...` → `$SCRIPT_DIR/ansible/...`
    - `razer-12.5.yml`: `/home/cicero/Documents/DeployIQ/onboarding/...` → `$SCRIPT_DIR/onboarding/...`
    - `power_management.yml`: `/media/cicero/ONN/proj-dev/DeployIQ/sysSettings/...` → `$SCRIPT_DIR/sysSettings/...`
    - `touchpad_settings.yml`: `/media/cicero/ONN/proj-dev/DeployIQ/sysSettings/...` → `$SCRIPT_DIR/sysSettings/...`
    - `package_update.yml`: `/media/cicero/ONN/proj-dev/DeployIQ/sysSettings/...` → `$SCRIPT_DIR/sysSettings/...`
    - System apps compose directory: `/media/cicero/ONN/proj-dev/DeployIQ/compose/` → `$SCRIPT_DIR/compose/`

- **App Installation - Cancellation Handling**: Fixed issue where cancelled installations showed "successful" instead of "cancelled"
  - `run_ansible_playbook()`: Now returns error code 1 and displays "Operation cancelled." when user selects "No" or presses Ctrl+C
  - Docker Apps menu: Tracks successful vs failed/cancelled installations separately
  - System Apps menu: Tracks successful vs failed/cancelled installations separately
  - Completion messages now accurately reflect results:
    - All succeeded: "Installation complete! X app(s) installed successfully."
    - All cancelled/failed: "Installation cancelled or failed. No apps were installed."
    - Mixed results: "Installation partially complete. Successful: X, Failed/Cancelled: Y"

- **System Apps - Ansible Installation Fixed**: Fixed critical bug where System Apps weren't actually installing
  - **Affected apps**: 16 system applications installed via Ansible (bitwarden, discord, docker, icloud, mailspring, n8n, notepad-plus-plus, notion, onlyoffice, portainer, protonvpn, termius, twingate, ulauncher, vivaldi, zoom)
  - Root cause: `install_ansible_app()` was calling `ansible-playbook` without elevated privileges
  - When Ansible tried to use `become: true`, it would hang waiting for a password that couldn't be provided through the dialog interface
  - Solution: Use `pkexec ansible-playbook` which shows a graphical password prompt
  - Changed Python interpreter from hardcoded `/usr/bin/python3.12` to `/usr/bin/python3` for compatibility
  - Added prerequisite check for `pkexec` (part of policykit-1 package)
  - Added informational dialog before installation starts
  - Apps now properly install to the system as desktop applications
  - Function now returns proper exit codes (0=success, 1=failure) for accurate tracking

- **Docker Apps - Return Code Fixed**: Fixed `install_app()` and `install_app_batch()` to return explicit exit codes
  - **Affected apps**: All 151 Docker containerized apps (plex, jellyfin, sonarr, radarr, etc.)
  - Both functions now return `return 0` on successful completion
  - Previously relied on implicit return code from last command, which could be unpredictable
  - Ensures accurate success/failure tracking in menu completion messages
  - No functional change to installation process (Docker apps were already working, just needed proper exit codes)

- **Docker Apps - Container Auto-Start**: Docker apps can now be started immediately after installation
  - **Critical for barebones systems**: Apps are now actually running after installation, not just configured
  - Single app installation (`install_app()`):
    - After configuration, user is prompted: "Do you want to start the container now?"
    - If yes, runs `docker compose up -d <app_name>` to start the container
    - Checks if Docker daemon is running first
    - Verifies container started successfully
    - Shows appropriate error messages if issues occur
  - Batch installation (`install_app_batch()`):
    - After all apps are configured, user is prompted to start all containers at once
    - Runs `docker compose up -d` to start all configured services
    - More efficient than starting containers one-by-one
  - Eliminates need for manual Stack Manager interaction on fresh installations
  - Docker daemon status check prevents confusing errors
  - User still has option to start containers later if preferred

- **Permissions - Docker Directory Access Fixed**: Fixed critical permission issues preventing user access to Docker files
  - **Root cause**: `.env` file was created with `sudo chmod 600` without changing ownership from root
  - **Impact**: Users couldn't view logs, edit .env file, start containers, or access Docker resources
  - **Ownership Configuration**: All Docker files and directories are owned by the username configured in Prerequisites > Primary Username
    - By default, this is automatically set to the username running the script
    - Can be changed by user in Prerequisites menu to any valid system user
    - Uses `$PRIMARY_USERNAME` variable throughout (not hardcoded usernames)
    - Ensures consistency: files owned by same user configured in .env file
  - **Environment Creation** (`setup_new_docker_environment()`):
    - `.env` file now owned by `$PRIMARY_USERNAME:$PRIMARY_USERNAME` (was root:root) with permissions 640 (was 600)
    - `secrets` directory now has 750 permissions (was 700) for user access while maintaining security
    - All files created during environment setup properly owned by `$PRIMARY_USERNAME`
  - **Permission Checker** (`check_fix_permissions()`):
    - Now detects files not owned by `$PRIMARY_USERNAME` in Docker directory (including root-owned files)
    - Added specific checks for critical files: `.env` and `secrets` directory
    - CRITICAL issue type for .env file with special handling
    - SECRETS issue type for overly restrictive secrets directory
    - Increased scan depth from 20 to 50 items for more thorough checking
    - Automatically fixes ownership: changes all files to be owned by `$PRIMARY_USERNAME:$PRIMARY_USERNAME`
    - `.env` gets 640 permissions (user read/write, group read, world none)
    - `secrets` directory gets 750 permissions (user full access, group read/execute, world none)
  - **Auto-Fix on Container Start**: Container startup now detects and fixes .env permission issues automatically
    - Before attempting `docker compose up`, checks if .env file is readable
    - If permission denied, prompts user: "Would you like to fix this now?"
    - If yes, uses `pkexec chown $PRIMARY_USERNAME:$PRIMARY_USERNAME` to fix ownership and `chmod 640` for permissions
    - Prevents cryptic "permission denied" errors during container startup
    - Works for both single app installation and batch installation
    - User can also defer and manually run Tools > Permissions
  - **Security maintained**: Files still protected from other users while being accessible to the owner
  - **Fixes access to**: Docker logs, .env editor, Stack Manager, container operations, all Tools menu items

- **Ownership Consistency - Uses Configured Username**: All file ownership operations now consistently use `$PRIMARY_USERNAME` variable
  - **Previous behavior**: Mixed use of `$CURRENT_USER` (auto-detected) and `$PRIMARY_USERNAME` (configured in Prerequisites)
  - **New behavior**: All `chown` operations use `$PRIMARY_USERNAME` for consistency
  - **Why this matters**:
    - `$PRIMARY_USERNAME` is the username configured in Prerequisites > Primary Username menu
    - By default, auto-set to the user running the script
    - Can be changed by user to any valid system username
    - Matches the username stored in .env file (`PRIMARY_USERNAME=$PRIMARY_USERNAME`)
    - Ensures Docker files are owned by the same user configured throughout the system
  - **Updated functions**:
    - `setup_new_docker_environment()`: Uses `$PRIMARY_USERNAME` for all created files
    - `install_app()` and `install_app_batch()`: Uses `$PRIMARY_USERNAME` for compose files and includes
    - `check_fix_permissions()`: Checks ownership against `$PRIMARY_USERNAME`, fixes to `$PRIMARY_USERNAME`
    - `setup_traefik()`: Uses `$PRIMARY_USERNAME` for traefik config files
    - Auto-fix on container start: Uses `pkexec chown $PRIMARY_USERNAME:$PRIMARY_USERNAME`
  - **Result**: Consistent ownership across entire Docker directory structure, no hardcoded usernames

- **Stack Manager - Complete Rewrite with Service Selection**: Completely rewrote Stack Manager to fix "no service selected" errors and add granular service control
  - **Root Cause of "No Service Selected"**: Stack Manager was looking for single `docker-compose.yml` file, but DeployIQ uses individual `.yml` files in `compose/` directory
    - Previous approach: `docker compose up -d` (failed - no compose file specified)
    - New approach: `docker compose -f compose/app1.yml -f compose/app2.yml up -d` (works correctly)
  - **Service Selection Interface**: Added interactive checklist for selecting which services to operate on
    - **Up**: Select specific services to start (none pre-selected)
    - **Start**: Select specific stopped services to start (none pre-selected)
    - **Stop**: Select specific running services to stop (none pre-selected)
    - **Restart**: Select specific services to restart (none pre-selected)
    - **Recreate**: Select specific services to recreate (none pre-selected)
    - **Pull**: Select services to update images (all pre-selected by default)
    - **Down**: Stops ALL services (no selection - always operates on all)
    - **Logs/List/Remove**: Operate on all services
  - **New Helper Functions**:
    - `get_available_services()`: Scans `compose/` directory for all `.yml` files
    - `select_services()`: Displays dialog checklist for service selection with customizable pre-selection
    - `build_compose_command()`: Builds `docker compose` command with `--env-file .env` and `-f` flags for each selected service
  - **Fixed .env File Format**: Removed single quotes from all variables in .env template
    - Docker Compose .env files treat quotes as literal characters
    - Previous format: `DOCKERDIR='/home/user/docker'` (quotes included in value, causing "invalid spec: :/data:" errors)
    - New format: `DOCKERDIR=/home/user/docker` (raw value, works correctly)
    - Fixed variables: PUID, PGID, PRIMARY_USERNAME, TZ, USERDIR, DOCKERDIR, HOSTNAME, DOMAINNAME_1, all version pins
  - **Explicit .env File Loading**: All docker compose commands now include `--env-file .env`
    - Ensures environment variables are loaded correctly regardless of compose file locations
    - Prevents "variable not set" warnings
  - **Enhanced User Feedback**:
    - **Clear checklist instructions**: All prompts now say "Use SPACE to select, ENTER to continue"
    - **Helpful error messages**: If no services selected, reminds user "Press SPACE to check boxes, then ENTER to continue"
    - **Prevents confusion**: Users were highlighting items but not checking them (common dialog checklist issue)
    - Operation progress shows which services are being operated on: "Starting services: traefik, vscode"
    - Success messages list affected services: "Services started successfully! Started: traefik, vscode"
    - Title bar shows service count: "Stack Manager - 2 services available"
    - Detailed output only shown on errors for troubleshooting
  - **Improved Error Handling**: All operations show detailed error output via `--textbox` when failures occur
  - **No More Spam Output**: Operations capture output to temp files instead of streaming to screen
  - **User Control**: Users have full control over which services to start/stop/restart instead of all-or-nothing operations
  - **Fixed Missing VSCODE_PORT**: Added `VSCODE_PORT=8443` to `.env` template to prevent warnings

### Menu Restructuring
- **Ansible Menu - Unified Automation Interface**: Merged "SysConfig" and "Onboarding" menus into single "Ansible" menu
  - **New Menu Structure**:
    - Main Menu: "Ansible" replaces both "SysConfig" and "Onboarding"
    - Submenu items:
      1. **New System Onboarding**: Full system setup (replaces "Full, Legacy" and "Full, NG")
      2. **System Apps**: Install desktop applications
      3. **Power Management**: Configure GNOME power settings
      4. **Touchpad Settings**: Configure touchpad
      5. **Package Updates**: Update system packages
      6. **Razer 12.5**: GRUB configuration for Razer laptop
  - **Ansible Configuration Standardized**:
    - All playbooks now located in: `./ansible/roles/common/tasks/`
    - Default inventory: `./ansible/inventories/production/localhost.yml`
    - Playbook renamed: `setup_full.yml` → `setup.yml`
    - All ansible-playbook commands now use `-i` flag with localhost inventory
  - **run_ansible_playbook() Enhanced**:
    - Added inventory parameter (3rd parameter, optional)
    - Defaults to `./ansible/inventories/production/localhost.yml`
    - Validates inventory file exists before running
    - Shows inventory path in confirmation dialog
  - **Improved Organization**: Groups all Ansible automation tasks in one logical location
  - **Cleaner Main Menu**: Reduced from 13 to 12 menu items

### New Features
- **Prerequisites Menu - Docker Installation**: Added new "Docker" menu item (between Packages and Username)
  - Menu label: "Install Docker & Docker Compose"
  - Calls existing `install_docker()` function which installs:
    - Docker via official get.docker.com script
    - Docker Compose plugin (latest version)
    - Adds user to docker group
    - Enables and starts Docker service
  - Shows independent status: DONE (green) when Docker is installed, NOT DONE (red) otherwise
  - Fixes issue where Docker installation was never accessible from the UI

### Removals
- **Main Menu - SysConfig and Onboarding**: Removed separate menu items, merged into "Ansible" menu
  - **SysConfig menu**: Removed from main menu (functionality moved to Ansible menu)
  - **Onboarding menu**: Removed from main menu (functionality moved to Ansible menu)
  - **Onboarding options removed**:
    - "Full, Legacy" (setup_full.yml) - replaced by "New System Onboarding" (setup.yml)
    - "Full, NG" (setup_all.yml) - consolidated into single onboarding option
  - Main menu reduced from 13 to 12 items for better organization
  - Old menu functions remain in code but are no longer called

- **Prerequisites Menu - Verify/License Tab**: Removed "Verify" menu item
  - License verification and subscription features removed from Prerequisites menu
  - Simplified menu from 15 to 14 items
  - `verify_license()` function remains in codebase but is no longer accessible from UI

### Enhancements
- **App Menus - Installation Status Indicators**: Apps now display visual installation status in menus
  - Docker Apps menu: Shows " - INSTALLED" in green for apps that have compose files already copied
  - System Apps menu: Shows " - INSTALLED" in green for system apps already detected on the system
  - Added `check_system_app_installed()` helper function that checks across multiple package managers:
    - Checks `command -v` for binaries in PATH
    - Checks `dpkg -l` for Debian packages
    - Checks `snap list` for Snap packages
  - Supports all 16 system apps: bitwarden, discord, docker, icloud, mailspring, n8n, notepad-plus-plus, notion, onlyoffice, portainer, protonvpn, termius, twingate, ulauncher, vivaldi, zoom
  - Dialog menus use `--colors` flag to render green status indicators
  - Provides instant visual feedback on what's already installed vs what needs installation
  - Apps are NOT pre-selected, giving users full control over what to install

- **Prerequisites Menu - Complete Status Overhaul**: All menu items now show clear "- DONE" or "- NOT DONE" status indicators
  - Previous behavior: Most items showed values in cyan (usernames, IPs, paths) without clear completion status
  - New behavior: All configured items show "\Z2DONE\Zn" in green, unconfigured items show "\Z1NOT DONE\Zn" in red
  - Status checks added/updated for all 14 menu items:

    1. **Disclaimer**: Tracks acknowledgment via flag file (`$DEPLOYIQ_CONFIG_DIR/disclaimer_acknowledged`)
       - Shows "NOT DONE" until user clicks OK
       - Shows "DONE" after acknowledgment is saved

    2. **Packages**: Checks if `dialog` is installed
       - Shows "DONE" when `command -v dialog` succeeds

    3. **Docker**: Checks if Docker is installed (NEW ITEM)
       - Shows "DONE" when `command -v docker` succeeds

    4. **Username**: Checks if username is set
       - Shows "DONE" when `$CURRENT_USER` is populated (auto-detected, always DONE)

    5. **System Type**: Checks if system type is selected
       - Shows "DONE" when `$SYSTEM_TYPE` is set (auto-detected, always DONE)

    6. **Setup Mode**: Checks if mode is configured
       - Shows "DONE" when `$SETUP_MODE` is set (defaults to "Local", always DONE)

    7. **Docker Folder**: Validates folder is properly configured
       - Shows "DONE" when folder is set and not default placeholder values
       - Shows "NOT DONE" for `/root/docker` or `/home/*/docker` (unconfigured)

    8. **Backups Folder**: Checks if backup folder is set
       - Shows "DONE" when `$BACKUP_DIR` is populated

    9. **Environment**: Verifies Docker environment is configured
       - Shows "DONE" when .env file, appdata folder, and compose folder all exist

    10. **Server IP**: Checks if IP is configured
        - Auto-detects IP via `hostname -I` if not manually set
        - Auto-saves detected IP to `$SERVER_IP` variable
        - Shows "DONE" when IP is set (manual or auto-detected)

    11. **Domain 1**: Checks if domain is configured
        - Shows "DONE" when domain is set
        - Shows "NOT REQUIRED" in yellow when not set (optional item)

    12. **System Checks**: Checks if prerequisite validation passed
        - Shows "DONE" when `$PREREQUISITES_DONE == true`

    13. **Domain Checks**: Always shows "NOT REQUIRED" (optional validation)

    14. **Telemetry**: Checks if telemetry preference is set
        - Shows "DONE" when `$TELEMETRY_ENABLED` is set (defaults to "minimum", always DONE)

- **Prerequisites Menu - Updated Descriptions**: All menu item descriptions now use consistent, clearer formatting
  - "Username" → "Primary Username - DONE"
  - "System Type" → "Pick your System Type - DONE"
  - "Setup Mode" → "Toggle how Apps are setup - DONE"
  - "Docker Folder" → "Set Docker Root Folder - DONE"
  - "Backups Folder" → "Set Backups Folder - DONE"
  - "Server IP" → "Set Server IP Address - DONE"
  - "Domain 1" → "Primary Domain Name - DONE"
  - "Telemetry" → "Set Usage Data Sharing - DONE"

- **Prerequisites Menu - Menu Size**: Now contains 14 items (added Docker, removed Verify)

### Technical Details

**App Installation Architecture**:
DeployIQ supports two fundamentally different types of applications with distinct installation methods:

1. **Docker Apps (151 apps)** - Accessed via "Apps" menu
   - Examples: plex, jellyfin, sonarr, radarr, vscode (code-server), portainer, etc.
   - Installation method: Copies Docker Compose files from `$SCRIPT_DIR/compose/*.yml` to `$DOCKER_DIR/compose/`
   - Function: `install_app()` and `install_app_batch()`
   - No elevated privileges needed (just file copying)
   - Apps run as Docker containers (need to be started via Stack Manager or `docker compose up`)
   - Status indicator: Shows "INSTALLED" when compose file exists in `$DOCKER_DIR/compose/`
   - Now returns explicit `return 0` on success for proper tracking

2. **System Apps (16 apps)** - Accessed via "SysConfig > System Applications" menu
   - Complete list: bitwarden, discord, docker, icloud, mailspring, n8n, notepad-plus-plus, notion, onlyoffice, portainer, protonvpn, termius, twingate, ulauncher, vivaldi, zoom
   - Installation method: Runs Ansible playbooks to install desktop applications to the OS
   - Function: `install_ansible_app()`
   - Requires elevated privileges (uses `pkexec` for graphical sudo prompt)
   - Apps install as native desktop applications (accessible from application menu)
   - Status indicator: Shows "INSTALLED" when `check_system_app_installed()` detects the app via `command -v`, `dpkg -l`, or `snap list`
   - Now returns explicit exit codes (0=success, 1=failure)

**Separation of Concerns**:
- Docker Apps menu explicitly filters out the 16 Ansible playbooks (lines 1198-1203)
- System Apps menu only lists the 16 Ansible-based applications
- Total compose directory files: 167 (151 Docker + 16 Ansible)

**Prerequisites**:
- Added disclaimer acknowledgment tracking via flag file
- Server IP now auto-saves when auto-detected (previously only displayed)
- Separated status logic from display logic for all menu items
- All status variables follow consistent naming: `{item}_status` (e.g., `packages_status`, `docker_status`)
- Color codes remain consistent:
  - \Z2 = Green (DONE)
  - \Z1 = Red (NOT DONE, NOT SET)
  - \Z3 = Yellow (NOT REQUIRED)
  - \Z6 = Cyan (values/settings when displayed)

### User Experience Impact
This update dramatically improves the Prerequisites menu UX by:
1. Making it crystal clear which steps are complete vs. incomplete
2. Fixing the confusing "Packages NOT DONE" bug that frustrated users
3. Providing a dedicated Docker installation option (previously hidden)
4. Creating visual consistency across all menu items
5. Tracking actual completion state rather than just displaying values

Additional UX improvements across the application:
- **Menu Organization**: Unified Ansible menu provides single location for all automation tasks (system onboarding, configuration, app installation)
- **Simplified Navigation**: Main menu reduced from 13 to 12 items - less clutter, clearer organization
- **Path Portability**: Script now works from any installation directory, not just hardcoded paths
- **Installation Feedback**: Users now see accurate feedback when cancelling operations instead of misleading "successful" messages
- **Visual Status Indicators**: Green "INSTALLED" labels help users quickly identify which apps are already on their system
- **Actual App Installation**: System Apps (16 Ansible-based) now properly install as desktop applications via Ansible using `pkexec` for privilege elevation
- **User Control**: Apps are not pre-selected, giving users explicit control over what gets installed
- **All Apps Work**: Both System Apps (16) and Docker Apps (151) now install correctly with proper status tracking
- **Clear App Categories**: Apps menu shows 151 Docker containerized services; Ansible > System Applications shows 16 desktop apps
- **Barebones System Support**: Docker apps can now be started immediately after installation, perfect for fresh system setups
- **One-Click Installation**: No need to manually use Stack Manager after app installation - containers start automatically if desired
- **Standardized Ansible**: All Ansible playbooks use consistent inventory and directory structure

### Bug Fixes Summary
- Fixed Packages status check (was checking for docker incorrectly)
- Fixed missing Docker installation UI access
- Fixed disclaimer not tracking acknowledgment state
- Fixed Server IP not persisting auto-detected value
- Fixed inconsistent status display across menu items
- Fixed hardcoded paths preventing onboarding/sysconfig menus from working
- Fixed cancelled operations showing "successful" instead of "cancelled"
- Fixed app installation completion messages not accurately reflecting results
- Fixed System Apps (16 Ansible-based apps) not actually installing (ansible-playbook privilege escalation issue)
- Fixed Docker Apps (151 containerized apps) return codes for accurate success/failure tracking
- Fixed Docker Apps not starting containers after installation (barebones system issue)
- Fixed permission issues preventing access to logs, .env file, and Docker operations (root-owned files issue)
- Fixed ownership to use configured PRIMARY_USERNAME instead of auto-detected user (consistency across all operations)
- Fixed Stack Manager "no service selected" error (was looking for single docker-compose.yml instead of individual compose files)
- Fixed Stack Manager confusing checklist interface (users were highlighting items but not checking them - now has clear SPACE/ENTER instructions)
- Fixed Stack Manager .env file format (removed quotes that Docker Compose treats as literal characters)
- Fixed Stack Manager verbose output spam during operations (image extraction flooding screen)
- Fixed Stack Manager operations showing "VSCODE_PORT variable not set" warnings
- Fixed Stack Manager lack of granular control (now can select specific services instead of all-or-nothing)

---

## [v5.10.3] - December 25, 2025

### New Features - v5.0 Alignment
This release adds missing v5.0 standard features while preserving all DeployIQ improvements.

### Fixes
- **Package Installation**: Corrected "Deployrr" → "DeployIQ" branding in package installation message
- **Package Installation**: Added missing packages (apache2-utils, apt-transport-https, argon2, html2text, libnss-resolve, netcat-traditional, pwgen, acl, software-properties-common, ufw, zip, nano)
- **Package Installation**: Added confirmation dialog before installation
- **Package Installation**: Added internet connectivity verification after installation
- **Package Installation**: Added 60-second timeout dialog before returning to menu
- **System Type Selection**: Updated to display OS version in dialog (e.g., "Ubuntu 24.04.4 LTS")
- **System Type Selection**: Updated system type names to match v5.0 standard:
  - VM → Virtual Machine
  - LXC → Unprivileged LXC / Privileged LXC (auto-detected)
  - Added VPS (Virtual Private Server) option with cloud provider detection
  - Laptop/Workstation removed from selection (not in v5.0 standard)
- **System Type Selection**: Dialog title changed to "Pick your System Type" (matching v5.0)
- **System Type Selection**: Cancel button now labeled "Skip" instead of "Cancel"
- **Setup Mode**: Updated terminology from "Remote" to "Hybrid" throughout
- **Setup Mode**: Menu-based selection with Change/Info/View options
- **Setup Mode**: Local mode - apps accessible only on internal network, no reverse proxy
- **Setup Mode**: Hybrid mode - apps accessible via Traefik reverse proxy with SSL
- **Setup Mode**: Mode properly saved to configuration and persists across sessions
- **Setup Mode**: Comprehensive help information available via Info option
- **Environment Setup**: Complete rewrite with enhanced functionality
  - First-run check: Validates Docker folder is set before allowing setup
  - Automatic folder structure creation (appdata, secrets, compose, etc.)
  - ACL permissions automatically configured for Docker root folder
  - Comprehensive .env file generation with all required variables
  - Smart re-run detection with three options:
    - Recreate: Full backup and fresh start
    - Reuse: Backup and recreate while preserving appdata, .env, secrets, custom.yml
    - Exit: Cancel without changes
  - Automatic backup creation using tar before any destructive operations
  - Docker Compose starter file (docker-compose-{hostname}.yml) created automatically
  - Custom.yml template copied to compose/{hostname}/ folder
  - Version pins for all major services (Traefik, Authentik, Authelia, Immich, etc.)
  - Secure secrets folder with 700 permissions
  - Status messages and 60-second timeout dialog for user convenience

#### Prerequisites Menu
- **Telemetry**: Toggle usage data sharing preferences (minimum/standard/full/off)
  - Control what anonymous usage data is shared to help improve DeployIQ
  - Options range from essential error reports to full usage analytics
  - All data collection is transparent with detailed explanations

#### Tools Menu
- **Permissions**: Scan and fix Docker folder permissions automatically
  - Detects incorrect file ownership and restrictive permissions
  - Offers one-click fix for common permission issues
  - Runs comprehensive scan across Docker directory

#### Settings Menu
- **Intro Messages**: Toggle informational messages on menus (ON/OFF)
  - Hide or show "HOW TO USE" guidance on each menu
  - Provides cleaner interface for experienced users
  - Can be toggled anytime from Settings
- **DeployIQ Mode**: Switch between Normal and Expert modes
  - Normal mode: Safety warnings, confirmations, guided experience
  - Expert mode: Skip confirmations, show advanced options, technical details
  - Warning dialogs explain implications of each mode
- **Generate Log**: Create sanitized debug log for support (removes sensitive data)
  - Collects system info, Docker status, and error logs
  - Automatically redacts passwords, tokens, IPs, and domains
  - Compressed output file safe to share with support
- **Clear Cache**: Remove temporary files and cached data
  - Shows cache size and file count before deletion
  - Frees up disk space
  - Cache rebuilds automatically as needed

### Enhancements
- **Prerequisites Menu**: Complete color-coded status system for easy progress tracking
  - Green (\Z2): Completed items (DONE status)
  - Cyan (\Z6): Active values (usernames, IPs, domains, paths, settings)
  - Red (\Z1): Incomplete items (NOT DONE, NOT SET)
  - Yellow (\Z3): Optional items (NOT REQUIRED)
  - Smart status detection for all menu items:
    - Disclaimer: Always shows as DONE
    - Packages: Checks if dialog and docker are installed
    - Username: Shows current username in cyan
    - System Type: Displays "OS version is on [Type]" with cyan highlighting
    - Setup Mode: Shows current mode (Local/Hybrid) in cyan
    - Docker Folder: Shows path in cyan or "NOT SET" in red
    - Backups Folder: Shows path in cyan or "NOT SET" in red
    - Environment: Checks for .env, appdata, and compose folders
    - Server IP: Auto-detects IP and shows in cyan
    - Domain 1: Shows domain in cyan or "NOT REQUIRED" in yellow
    - System Checks: Shows DONE/NOT DONE status
    - Domain Checks: Always shows "NOT REQUIRED" in yellow
    - Telemetry: Shows current setting in cyan
    - Verify: Shows license status in cyan
- **System menu**: Updated "Anand's Bash Aliases" to "Docker Bash Aliases" for generic branding
- **Settings menu**: Reorganized for better UX (8 items, logically ordered)
- **Configuration**: Added persistence for UI preferences and operation mode
  - TELEMETRY_ENABLED: Tracks data sharing preference
  - SHOW_INTRO_MESSAGES: Controls menu intro text display
  - DEPLOYIQ_MODE: Stores Normal/Expert mode selection
  - PRIMARY_USERNAME: Alias for CURRENT_USER for compatibility

### Technical Details
- Added 6 new utility functions (~840 lines):
  - `toggle_telemetry()` - Manage data sharing preferences
  - `check_fix_permissions()` - Scan and repair file permissions
  - `toggle_intro_messages()` - Control menu intro text
  - `toggle_deployiq_mode()` - Switch operation modes
  - `generate_sanitized_log()` - Create safe debug logs
  - `clear_deployiq_cache()` - Remove temporary files
- 3 new configuration variables with defaults
- Updated `save_config()` to persist new settings
- All v5.0 standard menu items now present

### Menu Updates Summary
- **Prerequisites**: 14 → 15 items (added Telemetry)
- **Tools**: 12 → 13 items (added Permissions)
- **Settings**: 5 → 9 items (added Intro, Mode, Logs, Refresh; reordered for better UX)

### Philosophy
This release follows the "v5.0 base + improvements" approach:
- ✅ All v5.0 standard features included
- ✅ All DeployIQ enhancements preserved (SysConfig, Onboarding, extended Tools)
- ✅ DeployIQ branding maintained
- ✅ Additive-only changes (no removals)
- ✅ Backward compatible
- ✅ No breaking changes

---

## [v5.10.2] - December 21, 2025 (Development Build)

### Major Changes

#### New SysConfig Menu
- **NEW MENU**: Added dedicated "SysConfig" tab to main menu for system configuration
- Moved System Apps from Apps menu to SysConfig for better organization
- Consolidated system settings in one place: Apps, Power, Touchpad, Updates

#### File Structure Reorganization
- **MOVED**: All Ansible application files from `ansible/roles/common/tasks/apps/` → `compose/`
- **MOVED**: System settings from `ansible/roles/common/tasks/sysSettings/` → `sysSettings/`
- **REMOVED**: Empty ansible subdirectories after migration
- **UPDATED**: All playbook references to use new paths with relative paths (`../../../../`)

#### App Descriptions
- **ADDED**: Comprehensive descriptions for all 167 applications
- **REPLACED**: Generic "Install [app_name]" with specific descriptions
- Apps now organized by 20+ categories:
  - Media Servers (8 apps)
  - Media Management (15 apps)
  - Download Clients (7 apps)
  - Productivity & Documents (13 apps)
  - Development Tools (9 apps)
  - Dashboards & Monitoring (8 apps)
  - System Monitoring (14 apps)
  - Docker Management (5 apps)
  - Security & Access Control (8 apps)
  - Reverse Proxy & Networking (11 apps)
  - Databases (8 apps)
  - AI & Machine Learning (5 apps)
  - Books & Reading (6 apps)
  - Photos & Images (4 apps)
  - Home Automation (7 apps)
  - Remote Access & Management (6 apps)
  - File Management (3 apps)
  - Utilities & Tools (15+ apps)
  - And more...

### New Features

#### SysConfig Menu Options
1. **System Apps** - Install 16 desktop applications via Ansible:
   - Bitwarden (Password manager)
   - Discord (Communication)
   - Docker (Container platform)
   - iCloud (Cloud integration for Linux)
   - Mailspring (Email client)
   - n8n (Workflow automation)
   - Notepad++ (Text editor)
   - Notion (Workspace)
   - OnlyOffice (Office suite)
   - Portainer (Docker management)
   - ProtonVPN (VPN service)
   - Termius (SSH client)
   - Twingate (Zero trust network)
   - Ulauncher (Application launcher)
   - Vivaldi (Web browser)
   - Zoom (Video conferencing)

2. **Power Management** - GNOME power settings configuration:
   - Disable automatic sleep/hibernation
   - Configure lid-close actions
   - Separate AC and battery settings

3. **Touchpad Settings** - GNOME touchpad configuration:
   - Set touchpad speed (65%)
   - Enable two-finger tap for right-click
   - Configure click methods

4. **Package Updates** - System maintenance:
   - Update APT package cache
   - Prepare system for installations

#### Apps Menu Improvements
- Streamlined to show Docker apps directly (no submenu)
- Displays 151 Docker applications (16 system apps moved to SysConfig)
- Each app shows descriptive information instead of generic text
- Better categorization and organization

##### Onboarding Menu
- **Full, Legacy**: Runs `setup_full.yml` (monolithic playbook)
- **Full, NG**: Runs `setup_all.yml` (modular playbook with new paths)
- **Razer 12.5** (NEW): Configure GRUB for Razer 12.5 laptop with Intel graphics optimization

#### Razer Laptop Support
- **NEW PLAYBOOK**: `./onboarding/razer-12.5.yml` - GRUB configuration for Razer 12.5 laptops
- **MENU INTEGRATION**: Added to Onboarding menu for easy access
- Automatically backs up original GRUB configuration
- Configures kernel parameters for optimal Intel graphics performance:
  - Disables Intel IOMMU (`intel_iommu=off`)
  - Sets IOMMU to passthrough mode (`iommu=pt`)
  - Disables power-saving features that can cause issues (PSR, DC, FBC)
  - Enables fastboot for quicker boot times
- Automatically updates GRUB after configuration changes

### Technical Details

**New Function: `get_app_description()`**
- 225+ lines of app descriptions
- Organized by category with comments
- Covers all 167 applications
- Returns meaningful descriptions for better UX

**Updated Functions:**
- `show_apps_menu()` - Now calls Docker apps directly
- `show_docker_apps_menu()` - Excludes system apps, uses descriptions
- `show_system_apps_menu()` - Updated with descriptions, moved to SysConfig
- `show_sysconfig_menu()` - New menu with 4 configuration options
- `run_ansible_playbook()` - Enhanced for running system settings

**File Path Updates:**
- `setup_all.yml` - All includes use `../../../../compose/` and `../../../../sysSettings/`
- `setup_individual.yml` - Smart detection for compose/ or sysSettings/ paths
- `hack3r.sh` - Updated all ansible_apps_dir paths to `/compose`
- `README.md` - Updated all examples and documentation

### Enhancements
- **Ansible Package**: Added Ansible to Prerequisites > Packages installation for automation and configuration management
- Main menu now has 13 items (added SysConfig)
- Better separation of concerns: Docker apps vs System apps
- Improved user experience with descriptive app information
- Cleaner file structure with apps in logical locations
- Documentation updated across all files

### Documentation Updates
- **README.md**: Updated file paths, structure, and examples
- **APPS.md**: Updated app count from 145+ to 167
- **CHANGELOG.md**: This entry
- All references to old paths updated to new structure

### Migration Notes
- Old paths: `ansible/roles/common/tasks/apps/` → New: `compose/`
- Old paths: `ansible/roles/common/tasks/sysSettings/` → New: `sysSettings/`
- No breaking changes - all functionality preserved
- Playbooks automatically use correct paths

---

## [v5.10.1] - December 10, 2025 (Development Build)

### New Features
- Automatic prerequisite detection and installation on first run - no manual setup required!
- Multi-distribution support for automatic package installation (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE)
- System type auto-detection with manual override capability
- Enhanced Setup Mode selector with clear descriptions of Local vs Remote modes
- Comprehensive system type information screen explaining each type, detection method, optimizations, and use cases
- Comprehensive setup mode information screen with detailed comparison, requirements, and recommendations
- Enhanced `check_dialog()` function with comprehensive error handling and verification
- Added `check_prerequisites()` function to automatically install essential tools (curl, wget, git, jq)
- Added `detect_system_type()` function to intelligently detect system environment (Barebones, VM, LXC, WSL, Laptop, Workstation)
- Added `select_system_type()` function allowing users to manually override detected system type

### Fixes
- Critical bug fix - removed duplicate `check_dialog()` function that was overwriting the properly implemented version
- Dialog utility now properly installed with sudo privileges before any UI elements load
- Setup Mode now shows selection dialog instead of simple toggle - users can see current mode and descriptions
- System Type menu now properly separates "Change", "Info", and "View" options - Info shows comprehensive guide instead of going to change dialog
- Setup Mode menu now properly separates "Change", "Info", and "View" options with dedicated info screen

### Enhancements
- System Type menu now displays both current and auto-detected values
- System types marked with "(default)" notation for auto-detected type in selection menu
- Setup Mode selector shows detailed explanation of each mode
- Improved user feedback during package installation with clear progress indicators
- Better error messages and fallback options for systems without recognized package managers
- Single sudo password prompt for all prerequisite installations
- `SYSTEM_TYPE` now saved in configuration and persists across sessions
- System Type Info screen provides comprehensive details on detection methods, optimizations, use cases, and implications for each system type
- Setup Mode Info screen includes detailed comparison table, pros/cons, security implications, package requirements, and recommendations
- Both configuration screens now have three distinct options: Change (modify setting), Info (learn details), View (see current only)

### Documentation
- Updated README.md with comprehensive prerequisites documentation
- Added System Type Auto-Detection section to README
- Added Setup Modes section explaining Local vs Remote configuration
- Added detailed list of all automatically installed packages at startup and during Prerequisites menu

### Technical Details

**Information Screens:**
- `show_system_type_info()` - 80+ line comprehensive guide covering all 6 system types with detection methods, optimizations, use cases, and best practices
- `show_setup_mode_info()` - 120+ line detailed comparison of Local vs Remote modes including requirements, security implications, pros/cons, and package lists
- Both screens use color-coded formatting for better readability
- Information persists in scrollable dialog boxes
- Accessible via Prerequisites menu → System Type/Setup Mode → Info

**System Type Detection Logic:**
- **VM** - Detected by checking /proc/cpuinfo for hypervisor flags (VMware, VirtualBox, KVM, QEMU, Xen)
- **LXC** - Detected by checking /proc/1/cgroup for lxc or presence of /.dockerenv
- **WSL** - Detected by checking /proc/version for microsoft or wsl keywords
- **Laptop** - Detected by presence of battery in /sys/class/power_supply/BAT*
- **Workstation** - Detected by presence of graphics card and 4+ CPU cores
- **Barebones** - Default fallback for physical servers and bare metal installations
- System type persists across sessions and can be manually overridden

**Setup Mode Options:**
- **Local** - Apps accessible only via IP:PORT, no reverse proxy, no domain required
- **Remote** - Apps accessible via Traefik reverse proxy with SSL and domain names
- Mode selection shows detailed descriptions and access examples

**Automatic Onboarding Packages (First Run):**
- dialog - Interactive text-based UI (REQUIRED)
- curl - API calls and downloads (REQUIRED)
- wget - Alternative download tool (RECOMMENDED)
- git - Repository management (REQUIRED)
- jq - JSON processing (RECOMMENDED)

**Prerequisites Menu Packages (User-Initiated):**
- curl, wget, git - Core utilities
- ansible - Automation and configuration management (required for system apps and onboarding)
- htop - System monitoring
- net-tools - Network utilities (ifconfig, netstat, etc.)
- dnsutils - DNS troubleshooting (dig, nslookup, etc.)
- openssl - SSL/TLS certificate management
- ca-certificates - Trusted certificate authorities
- gnupg - GPG encryption and signing
- lsb-release - Linux distribution identification
- dialog - Text UI (redundant check)
- rsync - Efficient file synchronization
- unzip - Archive extraction

---

## [v5.10] - July 29, 2025

### New Features
- Added Watchtower for automatic container updates
- Added Cleanuparr and Huntarr utilities
- Added CrowdSec Traefik Bouncer

### Enhancements
- Major speed improvements for Stack Manager and Apps menu by optimizing app status checks and dialog box sizing
- Moved Docker aliases to UDMS bash aliases, included migration script, and improved alias deployment
- Docker Compose pull alias (dcpull) now pulls one container at a time to not overload the CPU
- Improved dashboard descriptions for Authelia, Authentik, and Google OAuth
- Added additional ways to check internet connectivity (was failing for some users)
- Added default network to CrowdSec compose
- Added missing Docker labels placeholder in templates
- Fixed YAML syntax errors that prevented apps from being added to the dashboard
- Removed Readarr (unmaintained)

### Documentation
- Updated README and APPS.md

### Other
- Numerous other logic and reliability improvements

---

## [v5.9] - June 14, 2025

### New Features
- Added Homer - A simple static homepage for your server
- Added Change Hostname tool under Tools menu - useful when migrating to a different host

### Enhancements
- Improved SMB mount security with credentials files
- Added hostname mismatch detection to health checks
- Updated GPTWOL to use database instead of computers.txt
- Made Traefik dashboard port configurable via TRAEFIK_PORT variable
- Updated Redis configuration and compose
- Version updates (Authentik 2025.2 → 2025.6.1, Authelia 4.38.19 → 4.39.4, Traefik 3.3 → 3.4, DeployIQ Dashboard 1.2 → 1.3.2)

### Fixes
- App descriptions were not being added to DeployIQ Dashboard in some cases
- Existing Traefik SSL certs were not being respected - DeployIQ was proceeding with Traefik logs monitoring when not needed
- Fixed DeployIQ Dashboard URL not being added after Traefik setup (e.g. https://deployiq.example.com)
- Updated DeployIQ Dashboard bookmarks.yaml
- Authentik media folder permissions issue

---

## [v5.8] - May 12, 2025

**Total Supported Apps:** 140+

### New Features
- Added TinyAuth - Lightweight self-hosted Single Sign-On and OAuth solution
- Added YAML Yoda - YAML validation tool integrated into health checks
- Added SMB and NFS mount options under new Mounts menu
- Added Docker Login under Docker menu
- Redesigned Manage Auth interface for better auth provider selection

### Enhancements
- Added HTTP/3 support to Traefik (not fully tested)
- Added allowed hosts to Homepage and DeployIQ Dashboard
- Auto-add file provider for DeployIQ Dashboard after Traefik setup
- Updated transmission download path to match Arr apps
- Improved UX - Menus won't rewrite/clear terminal message history

### Fixes
- Various Docker aliases and .bashrc integration fixes
- Improved auth provider validation in Manage Auth
- Removed obsolete DeployIQ Dashboard includes
- Pin reset/reminder email was not being sent

### Visual
- Updated DeployIQ icon in dashboard

### Other
- A few other minor improvements and bug fixes

---

## [v5.7.1] - April 15, 2025

### Changes
- **DeployIQ is now DeployIQ** (finally got the spelling right!) - Many changes to reflect this
- Updated LICENSE to clarify what is open source vs proprietary
- One-line DeployIQ install/setup method - No more 3-step process to get started or manually picking the architecture

### Fixes
- Minor fix for qBittorrent VPN appdata path in compose file

---

## [v5.7] - March 5, 2025

**Total Supported Apps:** 140+

### New Features
- Added Audiobookshelf, Cloudflare Tunnel, FileZilla, Immich, Pi-Hole (v6), Trilium Next, Vikunja, and WikiDocs
- Huge focus on self-hosted AI with Flowise, n8n, Ollama, Open-WebUI, OpenHands, Qdrant, and Weaviate
- Added Audiobooks and Podcasts folders to support new media apps
- Added system health diagnostics and monitoring (Beta)
- Auto systemd-resolved configuration for Debian systems
- Official documentation now available at https://docs.deployiq.app

### Enhancements
- Enabled hardware acceleration for KASM apps (Kasm, Chromium, DigiKam, Lollypop)
- Updated Traefik to v3.3, Authentik to 2025.2, Authelia to 4.38.19
- Added Uptime Kuma to socket_proxy network
- Reduced rclone --dir-cache-time from 24h to 1h for more frequent media scans in Plex/Jellyfin
- Changed file provider IP from SERVER_LAN_IP to DOCKER0_IP
- Modified main menu UI, moved verify to prerequisites menu
- Added comment on memory overcommit warning to Redis compose
- Moved Smokeping to selfh.st icon
- Added Immich Folder setup for uploads (System→Folders)

### Fixes
- Potential fix for malformed compose file
- Debian DNS configuration issues
- Plex subdomain placeholder issues
- Changed app reachable check to IP 127.0.0.1
- Simplified resolved.conf template

### Other
- A few other minor improvements

---

## [v5.6] - January 28, 2025

**Total Supported Apps:** 125

### New Features
- Added Wallos and n8n
- .env Editor in Tools menu to edit environment variables
- Secrets Editor in Tools menu to edit secrets using nano editor
- Un-Traefikify to remove Traefik file providers

### Enhancements
- Updated Traefik to v3.3
- Changed traefik certs dumper image to: ghcr.io/kereis/traefik-certs-dumper:latest

### Fixes
- CrowdSec installation issues due to journalctl - Replaced journalctl with rsyslog
- Some deployiq dashboard links were obsolete

### Changes
- Rebranded SmartHomeBeginner to SimpleHomelab
- Moved DeployIQ resources and dependencies to www.deployiq.app

### Other
- A few other minor improvements

---

## [v5.5] - January 12, 2025

**Total Supported Apps:** 123

### New Features
- Added Paperless-NGX (+ support services Paperless-AI, Gotenberg, and Tika), Bookstack, PdfDing, Privatebin, and SSHwifty
- Tool to create PostgreSQL database from within DeployIQ

### Enhancements
- Switched DeployIQ Dashboard to use selfh.st icons
- Socket proxy install will now check for malformed docker compose and error out
- Improved handling of rclone config folder missing in some distros
- Log messages improved to share details on databases being created
- Added a note on MagicDNS and added accept-dns false option by default
- Under the hood, significant improvements to database management

### Removed
- Photoshow (domain compromised and not maintained)

### Fixes
- Xpipe-Webtop port environment variable name was wrongly specified as WEBTOP_PORT in the compose file
- CrowdSec repo error fix

### Other
- A few other minor improvements

---

## [v5.4.2] - December 30, 2024

### Fixes
- Icons of some apps were not being set on DeployIQ Dashboard
- qBittorrent VPN required manually adding stuff to configuration to allow initial login with admin/adminadmin

### Enhancements
- Modified internet connectivity check - Expert mode will allow overriding this step
- Remove yq requirement - Implemented an alternate method to manage secrets in master docker compose file
- More descriptive messages when requirements for a step are not met

### Other
- A few other minor improvements

---

## [v5.4.1] - December 24, 2024

### Enhancements
- Disabled ports in Authentik docker compose - Not needed, was causing conflict with Portainer
- Changed postgres_default_passwd to postgres_default_password - Manual change PostgreSQL docker compose required

---

## [v5.4] - December 23, 2024

**Total Supported Apps:** 115

### New Features
- Added Authentik, SearXNG, Beets, and DokuWiki

### Enhancements
- Redis added by default to Authelia, SearXNG, Nextcloud - Redis switched to alpine image and removed password
- Improved menu to pick available authentication methods - Simplified background logic
- DOCKER_HOST variable is now automatically set after installing socket proxy and used by several containers that depend on it
- Added PostgreSQL health check
- Authelia, Guacamole, Nextcloud, Redis-commander, and SearXNG now have depends_on key to enhance reliability
- Service recreation steps now do not suppress messages so error messages are visible
- Updated disclaimer to clarify data collection
- Option to reset "already setup/running" error and force install an app

### Fixes
- Socket proxy was running/requirement check was failing
- Internet connectivity check improved and now with an option to override
- Permissions fixed for Komga
- DDNS-Updater container always unhealthy for proxied domains
- Recreate option was not working in Stack Manager

### Other
- Significant standardization and simplification underneath to app installation workflow
- Several other minor UI/UX improvements

---

## [v5.3.1] - December 18, 2024

### Fixes
- Fixed "syntax error: operand expected (error token is '+')"

---

## [v5.3] - December 6, 2024

**Total Supported Apps:** 111

### New Features
- Added Dozzle Agent, Kasm, Komga, Calibre, Calibre-Web, Organizr, Home Assistant Core, Mylar3, Remmina, and Stirling PDF
- Comics folder to support the new Komga, Calibre and Calibre-Web apps
- Traefik dashboard is now exposed on port 8080 by default

### Enhancements
- Made the wait time for Traefik SSL certs more interesting
- Traefik wait time now includes DNS propagation check messages
- Improved Traefik support for existing SSL certificates with user confirmation
- License status is now intelligently extended without having to reverify every few days
- Stack Manager is now included in Basic and Plus license (previously only Pro)
- Some path changes for consistency (e.g., Books folder is now /data/books in Kavita)
- "[POST-INSTALL NOTES]" are now displayed after an app is installed when required
- Numerous AI-suggested syntax and logic improvements
- Reliability of apps dependent on MariaDB (e.g., Nextcloud, Guacamole, Speedtest-Tracker) improved

### Fixes
- Inconsistencies with MariaDB root password causing issues - Renamed mysql_root_password to mariadb_root_password (may require manual updates)
- Some Docker bash aliases were not working when using custom Docker folder
- Secrets definition in main docker compose was not working as expected causing yaml syntax errors
- OAuth container had TLS specification conflicting with Traefik's universal TLS options
- Typos and other minor improvements

### Changes
- DeployIQ development is now done via private Git repository due to addition of other contributors

---

## [v5.2] - November 7, 2024

**Total Supported Apps:** 101

### New Features
- Added DigiKam, Redis Commander, PHotoshow, Node Exporter, Funkwhale, Gonic, GPTWOL, CrowdSec, and CrowdSec Firewall Bouncer

### Enhancements
- DeployIQ PIN now saved locally and shown in About menu in case you forget

### Fixes
- DWEEBUI_SECRET not found error

### Other
- Other minor improvements and fixes
- Next few releases will focus on stability and improvements

---

## [v5.1] - October 30, 2024

**Total Supported Apps:** 91

### New Features
- Added DweebUI, Cloud Commander, Double Commander, Theme Park, Notifiarr, Flaresolverr, ESPHome, Emby, Dockwatch, Lollypop, qBittorrent without VPN, Transmission without VPN, Tailscale, What's Up Docker (WUD), and ZeroTier
- Changed Plex transcode folder path to match Jellyfin/Emby
- qBittorrent is now without VPN by default with separate menu item for VPN version

### Fixes
- Bash Aliases was not working with custom Docker Folder
- Messages after app installation were showing wrong port number in certain situations

### Enhancements
- Improved port availability check - .env will now be checked for ports already defined for other apps

---

## [v5.0.1] - September 30, 2024

### Fixes
- System checks was not being marked as done after completion
- Better Rclone remotes detection
- Rclone installation was failing due to unzip requirement
- Running the script with sudo failed on Debian due to lack of sudo package by default
- All apps that required MariaDB databases failed on migration - Existing databases will now be recognized
- Traefik will respect existing acme.json file upon migration/reinstallation
- SSL certificates (acme.json) were being emptied unnecessarily

---

## [v5.0] - September 29, 2024

**Total Supported Apps:** 76

### Major Changes
- DeployIQ logo and icon
- Local mode for installing apps for local access only (no reverse proxy) - Removes Traefik requirement and allows multi-server setups
- Traefik Exposure Modes: Simple (all apps accessible internally and externally) or Advanced (control per app)
- By default Traefik will use file providers to expose apps via reverse proxy (previously used Docker labels)
- DeployIQ Dashboard - New Homepage based dashboard that auto-populates as you install apps
- Recommended order of steps for various setups
- License changes: Three license types now available (Basic, Plus, and Pro)
- DeployIQ pin reset feature
- All apps are now exposed to Docker host using ports with suggested ports during installation
- DeployIQ will now call Cloudflare API to check the validity of the DNS API token for Traefik
- Included v4 to v5 migration instructions

### Enhancements
- Descriptive error messages when requirements are not met for specific steps
- Significant improvement in speed/responsiveness
- Menu reorganized based on past feedback

### Removed
- Traefik v2 to v3 migration
- Auto-Traefik to DeployIQ migration
- Account registration directly from the script (not needed as previous Basic features are now free)

### Other
- Over 9000 lines of code rewritten

---

## [v4.6.1] - August 7, 2024

### Fixes
- Pin creation was broken

---

## [v4.6] - August 6, 2024

**Total Supported Apps:** 75

### New Features
- Added Baikal, Piwigo, Resilio Sync, Node-RED, Homebridge, Mosquitto, Jackett, MQTTX Web, Scrutiny, and Chromium

### Fixes
- Smokeping and FreshRSS appdata folder was wrongly mapped
- Plex was calling SERVER_IP instead of SERVER_LAN_IP env

### Known Issues
- If hostname changes, DeployIQ can break until the new hostname is manually changed in various locations (applies to all versions)

### Notice
- Auto-Traefik to DeployIQ migration and Traefik v2 to v3 migration support will be removed in next release

---

## [v4.5.4] - July 15, 2024

### Fixes
- User creation was not working - Final fix

---

## [v4.5.3] - July 15, 2024

### Fixes
- User creation was not working

---

## [v4.5.2] - July 15, 2024

### New Features
- Option to Share Usage Stats
- 6-digit numerical pin to protect from unauthorized use of email
- Stack Manager: Option to pull image updates and upgrade containers

### Fixes
- 4.5.1 was complaining about upgrading to 4.5.1 when it was already the latest

### Other
- Other minor improvements

---

## [v4.5.1] - July 14, 2024

### Fixes
- Minor bug fixes

---

## [v4.5] - July 13, 2024

**Total Supported Apps:** 65

### New Features
- Added Kometa
- Rclone Remote SMB mount, Automount, Delay Media Apps, and Refresh Cache
- Reorganized menu - All prerequisite steps are now in one place

### Fixes
- Removed Plex requirement for Tautulli (wouldn't work if Plex is in a different server)

### Enhancements
- Expanded bash aliases

### Other
- Other minor improvements and fixes

---

## [v4.4.1] - July 5, 2024

### Fixes
- Bug fixes

### Enhancements
- Improved handling of passwords/strings with special characters

---

## [v4.4] - July 4, 2024

**Total Supported Apps:** 64

### New Features
- Added Flame, Kavita, Netdata, and pgAdmin
- Installing required packages is now a separate step in System Prep menu

### Fixes
- Some users downgraded from Pro to Basic
- Bash aliases was not installing properly
- Some premature/harmless error messages

### Enhancements
- Improved compatibility with Debian
- Improved compatibility with older Ubuntu (>=20.04) / Debian (>=11)

---

## [v4.3] - June 27, 2024

**Total Supported Apps:** 60

### New Features
- Added Maintainerr, CyberChef, The Lounge

### Fixes
- Feedback/Review was not working
- Some premature error messages

---

## [v4.2.1] - June 27, 2024

### New Features
- Ability to clear DeployIQ cache

### Fixes
- License check was not working

---

## [v4.2] - June 26, 2024

**Total Supported Apps:** 57

### New Features
- Added Wireguard + WebUI with WG-Easy, cAdvisor, Dashy, Docker Garbage Collection, and Traefik Certs Dumper

### Enhancements
- Revamped license checks and new user creation
- If MariaDB is running, Speedtest-Tracker will now offer to use MariaDB instead of SQLite
- If Plex is installed and Logs are found, they will be passed automatically to Tautulli

### Fixes
- Feedbacks were not being registered - Please submit or re-submit feedback
- Minor bug fixes

### Notice
- Traefik v2 remnants will be removed in next version (automatic migration won't be possible)

---

## [v4.1] - June 23, 2024

### New Features
- Added Airsonic-Advanced, Change-Detection, FreshRSS, Grocy, Heimdall, Jellyseerr, NZBGet, Ombi, Overseerr, Smokeping, and Tautulli

### Enhancements
- Changed qBittorrent from Docker Labels to File Provider for Traefik

### Fixes
- Speedtest-Tracker latest version was not working without an API Key - Added API Key feature
- Minor bug fixes

---

## [v4.0.1] - June 17, 2024

### Fixes
- Switching Authentication method was not working
- Re-registering an existing account caused account downgrade to DeployIQ Basic
- Installing MariaDB/PostgreSQL before Traefik caused errors due to improper secrets addition
- Non-critical error messages were displayed if docker folder was not set
- Update process was failing due to incorrect extension

---

## [v4.0] - June 16, 2024

**Total Supported Apps:** 40

### Major Changes
- License naming: Free (previously Unregistered), Basic (previously Starter Free), Plus (previously Auto-Traefik), and Pro (previously Auto-Traefik+)
- Auto-Traefik to DeployIQ auto migration
- Ability to register a free account from within DeployIQ to gain free Basic license

### New Features
- Added Bazarr, DeUnhealth, Gluetun VPN, Lidarr, Plex, Prowlarr, Jellyfin, qBittorrent, Radarr, Readarr, and Sonarr
- Starter config for qBittorrent with pre-configured folders and default login fix
- Gluetun VPN supports both Wireguard and OpenVPN
- Ability to get customized discount codes from About menu
- Ability to toggle Intro Messages on/off on the menus
- Key announcements right on the menu without needing to update the script

### Enhancements
- Ability to set custom data folder for Nextcloud
- customRequestHeaders and forceSTSHeader enabled by default (needed for Nextcloud)
- SABnzbd exposed via port 8090, qBittorrent via 8091
- Out of 3 media folders, only one needs to be set (previously Media Folder 1 was required)
- All menus updated with descriptive options
- System prep menu now displays all configuration info for quick verification

### Fixes
- Minor fix in IT-Tools docker labels

### Documentation
- Updated README.md

### Other
- Too many other minor changes to list

---

## [June 14, 2024]

### Announcement
- Goodbye Auto-Traefik. Hello DeployIQ!
- v3.3.3 will be the last version of Auto-Traefik

---

## [v3.3.3] - June 6, 2024

### New Features
- Added Nextcloud (not AIO version; uses existing Redis and MariaDB services) and SABnzbd
- Graphics card detection (EXPERIMENTAL)

### Fixes
- Traefik staging was failing while checking for staging certificates

### Other
- Other minor bug fixes

---

## [v3.3.2.1] - May 27, 2024

### Fixes
- Adding external app behind Traefik was broken

---

## [v3.3.2] - May 25, 2024

### New Features
- ShellInaBox added (web-based terminal)
- Authelia upgraded to v4.38.8
- Ability to set custom Docker folder and Backup folder

### Enhancements
- UI/UX improvements throughout, including a new Apps menu
- More clarity on which steps are required and which ones are not

---

## [v3.3.1] - May 23, 2024

### New Features
- Added Adminer, PostgreSQL, and Redis
- Ability to create MariaDB database using the script (from Tools menu)
- System Prep menu expanded with additional settings: SMTP Details, Downloads Folder, Media Folders, Server LAN IP, etc.
- Ability to set a Traefik Auth Bypass Key

### Enhancements
- Reverse Proxy menu improved with more context-based information
- All sensitive info used by the script are now more securely stored as docker secrets
- Apps menu now shows status (Running), image version if available, and authentication mode
- Backups menu now shows the Backup Folder, Number of Backups, and Size of Backups Folder

### Fixes
- Ability to set authentication mode while adding external apps behind Traefik was broken

### Other
- Several other minor fixes and improvements

---

## [v3.3] - May 18, 2024

### New Features
- Traefik v3 now default
- Traefik v2 to v3 migration assistant (EXPERIMENTAL)
- Traefik Access and Errors now available via Dozzle

### Enhancements
- Colors! Color coding of menu and status texts for better UX

### Fixes
- With no Authelia and with OAuth, setting authentication system during app install wasn't working properly
- Rules syntax changes for Traefik v3 compliance
- Bash Aliases Fix - was erroring out previously

### Other
- Several other minor fixes and improvements

---

## Earlier Versions (v3.2.2 - v1.0)

For complete history of versions v3.2.2 through v1.0 (2023-2024), including:
- Auto-Traefik naming and rebranding
- Initial Traefik automation features
- Stack management tools
- Authentication providers
- Early app additions
- Foundation features

See previous changelog archives or visit the official documentation.

## Breaking Changes (v6.0.0 → v6.0.10)

⚠️ **Configuration Directory Change** (v6.0.6):
- Users upgrading from DeployIQ 5.x will need to migrate their configuration
- Old location: `~/.config/deployiq/`
- New location: `~/.config/zoolandia/`
- Manual migration required for existing configurations

⚠️ **Package Structure Change** (v6.0.5):
- Package installation moved from single-tier to multi-tier system
- Core packages now view-only (pre-installed)
- Users may need to review and install recommended packages

---

## Upgrade Notes

For users upgrading from DeployIQ 5.x to Zoolandia 6.x:

1. **Backup Configuration**:
   ```bash
   cp -r ~/.config/deployiq ~/.config/deployiq.backup
   ```

2. **Rename Configuration Directory**:
   ```bash
   mv ~/.config/deployiq ~/.config/zoolandia
   ```

3. **Update Environment Variables** (if any):
   - DEPLOYIQ_MODE → ZOOLANDIA_MODE
   - DEPLOYIQ_CONFIG_DIR → ZOOLANDIA_CONFIG_DIR

4. **Review Package Installation**:
   - Navigate to Prerequisites → Additional Packages
   - Review each tier and install missing packages as needed

---

## Version History Summary

**v6.0.10** - Session logging
**v6.0.9** - Package menu status enhancement
**v6.0.8** - Colored status indicators
**v6.0.7** - ASCII art branding fix
**v6.0.6** - Complete project rebranding
**v6.0.5** - Package system overhaul
**v6.0.4** - Ansible recommendations analysis
**v6.0.3** - Ansible inventory analysis
**v6.0.2** - Documentation organization
**v6.0.1** - Menu reorganization
**v6.0.0** - Modular architecture base

---

**Total Apps:** 167 (151 Docker + 16 System)
**Current Version:** 6.0.10
**Release Date:** December 30, 2025
