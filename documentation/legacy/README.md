# Zoolandia - Comprehensive Homelab Automation Platform

> Transform your homelab from complex to automated! Zoolandia is your all-in-one solution for deploying, configuring, and managing Docker-based homelab environments with native Linux system integration.

**Version:** 6.0.18
**Total Applications:** 167 (151 Docker + 16 System)
**Architecture:** Modular, Dialog-based TUI

---

## What is Zoolandia?

Zoolandia is a comprehensive automation platform that revolutionizes homelab deployment by combining:

- **Docker Container Management**: 151+ pre-configured containerized applications
- **Ansible System Automation**: 16 native Linux applications and system configurations
- **Intelligent Menu System**: Intuitive dialog-based interface for all operations
- **Enterprise-Grade Features**: Advanced networking, security, and monitoring built-in

Whether you're a homelab enthusiast, professional sysadmin, or developer, Zoolandia streamlines the entire process of setting up and managing your infrastructure through an elegant, menu-driven interface.

---

## Key Features

### Application Ecosystem
- **151 Docker Applications**: Pre-configured compose files for instant deployment
- **16 System Applications**: Native Linux apps installed via Ansible automation
- **20+ Categories**: Media servers, monitoring, security, AI/ML, development tools, and more
- **Detailed Descriptions**: Every app includes clear descriptions in the menu system

### Enterprise Infrastructure
- **Advanced Reverse Proxy**: Traefik with automatic SSL certificate management
- **Multiple Authentication Options**:
  - Authentik (SSO with LDAP/OAuth)
  - Authelia (2FA + Single Sign-On)
  - TinyAuth (Lightweight SSO)
  - Google OAuth 2.0
- **Security Integration**:
  - CrowdSec IPS (Intrusion Prevention System)
  - Socket Proxy protection for Docker API
  - Traefik Bouncer for threat blocking
  - Firewall bouncer integration

### Smart System Management
- **Modular Architecture**: 16 independent modules for maintainability
- **Multi-Tier Package System**: Organized package installation (Required, Recommended, Enhanced, Advanced, Security, Power, Optional)
- **Automated Prerequisites**: Auto-detection and installation of system requirements
- **Flexible Deployment Modes**:
  - **Local Mode**: Apps accessible via IP:PORT (no domain needed)
  - **Remote Mode**: Apps behind Traefik reverse proxy with SSL
  - **Hybrid Mode**: Mix of local and remote access

### Advanced Configuration
- **GPU Support**: Auto-detection for NVIDIA, AMD, and Intel GPUs
- **Network Adapters**: VPN container network interface selection
- **Remote Storage**: SMB/CIFS, NFS, and Rclone mount configuration
- **SMTP Integration**: Email notifications for monitoring
- **System Type Detection**: Automatic detection of Baremetal, VM, LXC, WSL, Laptop, Workstation
- **NTFS/exFAT Automount**: External drive compatibility configuration

### Management Tools
- **Stack Manager**: Complete Docker Compose lifecycle management
- **Backup System**: Automated timestamped backups with compression
- **Database Tools**: MariaDB and PostgreSQL database creation wizards
- **LazyDocker Integration**: Terminal UI for container management
- **Diagnostics**: Comprehensive health check reporting
- **Version Pinning**: Docker image version management
- **Secrets Management**: Secure configuration and secrets handling

---

## Quick Start

### Installation

Run the installation script:
```bash
bash -c "$(curl -fsSL https://www.github.com/hack3rgg/Zoolandia/install.sh)"
```

Or clone and run directly:
```bash
git clone https://www.github.com/hack3rgg/Zoolandia.git
cd Zoolandia
./Zoolandia.sh
```

### First-Time Setup

1. **Prerequisites Menu**:
   - System Checks (OS, ports, internet connectivity)
   - Additional Packages (select tier based on your needs)
   - Install Docker and Docker Compose
   - Configure Environment (.env file generation)

2. **System Preparation Menu**:
   - Create Folder Structure
   - Configure GPU (if applicable)
   - Setup Network Adapters for VPN containers
   - Configure Mounts (SMB, NFS, or Rclone)
   - Install Bash Aliases for Docker shortcuts
   - Setup SMTP (for email notifications)

3. **Docker Menu**:
   - Install Socket Proxy (recommended for security)

4. **Reverse Proxy Menu** (if using Remote Mode):
   - Install Traefik
   - Configure SSL certificates (Let's Encrypt)
   - Setup domain and subdomain routing

5. **Security Menu** (optional but recommended):
   - Choose authentication provider (Authelia/Authentik/TinyAuth/OAuth)
   - Install CrowdSec IPS
   - Configure security bouncers

6. **Apps Menu**:
   - Browse 151 Docker applications across 20+ categories
   - Use checkbox interface for multi-app selection
   - Batch install with progress tracking

7. **Ansible Menu** (SysConfig):
   - Install 16 native Linux applications
   - Configure power management settings
   - Adjust touchpad settings (for laptops)
   - Setup NTFS/exFAT automounting
   - System onboarding automation

---

## System Requirements

### Supported Platforms
- **Primary**: Ubuntu 20.04+, Debian 11+, and derivatives
- **Architectures**: x86-64, ARM64
- **Deployment Types**: Baremetal, VM (VMware, VirtualBox, KVM, QEMU, Xen), LXC, WSL

### Prerequisites (Auto-Installed)

**Critical Dependencies** (installed automatically on first run):
- bash
- dialog (interactive TUI)
- curl (downloads)
- wget (alternative downloads)
- git (repository management)
- jq (JSON processing)
- sudo/root privileges

**Additional Packages** (installed via Prerequisites menu):
- Docker Engine and Docker Compose
- System utilities (htop, net-tools, dnsutils, etc.)
- Development tools (optional)
- Security tools (optional)
- Filesystem support (NTFS, exFAT - optional)

---

## Application Catalog

### Total: 167 Applications

#### Docker Applications (151 Apps)

**Reverse Proxy & Networking** (5 apps)
- Traefik, Traefik Access/Error Logs, Traefik Certs Dumper, Cloudflare Tunnel

**Media Servers** (8 apps)
- Plex, Jellyfin, Emby, Airsonic-Advanced, Navidrome, Lollypop, Funkwhale, Gonic

**Media Management** (17 apps)
- Radarr, Sonarr, Lidarr, Bazarr, Jackett, Maintainerr, Jellyseerr, Ombi, Overseerr, Tautulli, Prowlarr, Kometa, Notifiarr, Beets, Audiobookshelf, Huntarr, Cleanuparr

**Downloaders** (5 apps)
- NZBGet, SABnzbd, qBittorrent, Transmission, qBittorrent with VPN

**Network Tools** (7 apps)
- Wireguard, Gluetun, WG-Easy, DDNS Updater, Tailscale, ZeroTier, Pi-hole

**Monitoring** (11 apps)
- Uptime-Kuma, Netdata, Grafana, cAdvisor, Dozzle, Dozzle Agent, Scrutiny, Speedtest-Tracker, Smokeping, Glances, Change Detection, Node Exporter

**Security** (8 apps)
- Authentik, Authelia, Socket Proxy, OAuth, TinyAuth, CrowdSec, CrowdSec Firewall Bouncer, Traefik Bouncer

**Dashboards** (7 apps)
- Homepage, Flame, Dashy, Heimdall, Homarr, Homer, Organizr

**Reading** (6 apps)
- Kavita, Calibre-Web, Calibre, Komga, Mylar3, FreshRSS

**Databases** (9 apps)
- Prometheus, MariaDB, PostgreSQL, Redis, InfluxDB, Adminer, PgAdmin, phpMyAdmin, Redis Commander

**Smart Home & Automation** (7 apps)
- Home Assistant Core, Homebridge, Mosquitto, MQTTX Web, ESPHome, Node-RED, n8n

**Photo Management** (3 apps)
- Immich, Piwigo, DigiKam

**Docker Management** (7 apps)
- Portainer, Docker Garbage Collection, DeUnhealth, Dockwatch, What's Up Docker (WUD), DweebUI, Watchtower

**File Management** (12 apps)
- FileZilla, Nextcloud, Visual Studio Code Server, Cloud Commander, Double Commander, Stirling PDF, Paperless-NGX, Paperless-AI, Gotenberg, Tika, PdfDing, Privatebin

**Admin Tools** (5 apps)
- IT-Tools, ShellInABox, CyberChef, GPTWOL, SSHwifty

**Remote Access** (4 apps)
- Guacamole, Chromium, Kasm, Remmina

**Social** (1 app)
- The Lounge

**Password Management** (1 app)
- Vaultwarden

**Notes & Documentation** (4 apps)
- Trilium Next, WikiDocs, DokuWiki, Bookstack

**AI & Machine Learning** (6 apps)
- Flowise, Ollama, Open-WebUI, OpenHands, Weaviate, Qdrant

**Planning & Scheduling** (2 apps)
- Vikunja, Baikal

**Other Utilities** (7 apps)
- Resilio Sync, Grocy, Flaresolverr, Theme Park, SearXNG, GameVault, Wallos

[View Complete Apps List with Descriptions](APPS.md)

#### System Applications (16 Apps via Ansible)

**Desktop Applications**
- Vivaldi (privacy-focused browser)
- Discord (communication)
- Zoom (video conferencing)

**Productivity**
- Notion (workspace and notes)
- Notepad++ (text editor)
- OnlyOffice (office suite)
- Mailspring (email client)

**Security & VPN**
- Bitwarden (password manager)
- ProtonVPN (VPN client)
- Twingate (zero trust network access)

**Development & DevOps**
- Docker Engine (also available separately)
- Portainer (also available as Docker container)
- n8n (also available as Docker container)
- Termius (SSH client)

**Utilities**
- iCloud for Linux
- Ulauncher (application launcher)

---

## Package Tier System

Zoolandia features a sophisticated multi-tier package management system introduced in v6.0.5:

### Required Packages (5 packages - Pre-installed)
**View Only** - These are installed before Zoolandia runs
- dialog, curl, wget, git, jq

### Recommended Packages (11 packages)
**Server Utilities & Networking**
- htop, net-tools, dnsutils, openssl, ca-certificates, gnupg, lsb-release, rsync, unzip, smartmontools, netcat-traditional

### Enhanced Packages (16 packages)
**Development Tools, Build Tools, Security, Filesystems**
- **Development** (6): libssl-dev, libffi-dev, python3-dev, python3-pip, python3-venv, apt-transport-https
- **Build Tools** (2): build-essential, cmake
- **Security & Admin** (4): apache2-utils, acl, pwgen, argon2
- **Filesystems** (4): libnss-resolve, exfat-fuse, exfatprogs, ntfs-3g

### Advanced Packages (5 packages)
**Desktop Enhancements, Disk Tools, System Info**
- neofetch, gnome-tweaks, gnome-shell-extensions, gnome-extensions-app, gparted

### Security Packages (1 package)
**Hardware Authentication**
- yubikey-manager

### Power Packages (1 package)
**Media & Power User Tools**
- vlc

### Optional Packages (3 packages)
**Basic Utilities**
- nano, zip, html2text

**Total Installable Packages**: 37 (excluding 5 pre-installed Required packages)

### Installation Options
- **Individual Tiers**: Install specific package tiers based on your needs
- **All Packages**: Install all 37 packages at once
- **Status Indicators**: Real-time display of installed vs. missing packages
- **Smart Detection**: Accurate package detection using dpkg-query

---

## Architecture

### Modular Design (v6.0.0+)

Zoolandia uses a modular architecture with 16 independent modules:

```
Zoolandia/
├── Zoolandia.sh (11KB)              # Main entry point (336 lines)
├── modules/                       # 16 modules (~220KB total)
│   ├── 00_core.sh                # Core variables, utilities, banner
│   ├── 01_homepage.sh            # Welcome screen, version checking
│   ├── 02_main_menu.sh           # Main menu, search, navigation
│   ├── 10_prerequisites.sh       # System checks, Docker, packages
│   ├── 11_system.sh              # System configuration (22 functions)
│   ├── 12_docker.sh              # Docker management
│   ├── 13_reverse_proxy.sh       # Traefik configuration
│   ├── 14_security.sh            # Auth providers, CrowdSec (17 functions)
│   ├── 20_apps.sh                # App management, descriptions (7 functions)
│   ├── 21_docker_apps.sh         # Docker apps menu
│   ├── 22_system_apps.sh         # System apps menu (Ansible)
│   ├── 30_tools.sh               # Stack manager, utilities (14 functions)
│   ├── 31_backup.sh              # Backup functionality
│   ├── 40_settings.sh            # Settings menu
│   ├── 41_ansible.sh             # Ansible automation
│   └── 50_about.sh               # About, feedback, support (5 functions)
├── compose/                       # 151 Docker app compose files
├── sysSettings/                   # System configuration playbooks
├── ansible/                       # Ansible automation structure
│   ├── roles/common/tasks/       # Task playbooks
│   │   ├── setup_all.yml         # Modular playbook (NG)
│   │   ├── setup_full.yml        # Monolithic playbook (Legacy)
│   │   ├── setup_individual.yml  # Single app installer
│   │   └── ntfs_automount.yml    # NTFS/exFAT automount config
│   └── inventories/production/   # Inventory files
├── includes/                      # Configuration templates (78 files)
│   ├── traefik/                  # Traefik configs (23 files)
│   ├── authelia/                 # Authelia configs
│   ├── authentik/                # Authentik configs
│   ├── oauth/                    # OAuth configs
│   ├── tinyauth/                 # TinyAuth configs
│   ├── deployrr-dashboard/       # Dashboard templates
│   └── ...
└── documentation/                 # Comprehensive documentation
    ├── README.md
    ├── APPS.md
    ├── CHANGELOG.md
    ├── MODULARIZATION_SUMMARY.md
    ├── analysis/
    └── ansible/
```

### Benefits of Modular Design
- **Readable**: Each module 200-500 lines (largest 47KB)
- **Maintainable**: Clear separation of concerns
- **Extensible**: Easy to add features by editing specific modules
- **Debuggable**: Test and modify individual components

---

## Menu Structure

### Main Menu
1. **Prerequisites**
   - System Checks (OS, ports, internet)
   - Additional Packages (7-tier system)
   - Install Docker
   - Install Ansible
   - Configure Environment
   - Setup Mode (Local/Remote/Hybrid)
   - System Type (Baremetal/VM/LXC/WSL/Laptop/Workstation)

2. **System Preparation**
   - Create Folders
   - Configure Mounts (Rclone/SMB/NFS)
   - GPU Detection and Configuration
   - Network Adapter Selection
   - Bash Aliases Installation
   - SMTP Configuration

3. **Docker**
   - Socket Proxy Management
   - Docker Info and Maintenance
   - Prune Unused Resources

4. **Reverse Proxy**
   - Traefik Installation
   - SSL Configuration
   - Domain Management

5. **Security**
   - Authelia (2FA + SSO)
   - Authentik (Enterprise SSO)
   - Google OAuth
   - TinyAuth (Lightweight SSO)
   - CrowdSec IPS
   - Security Bouncer Configuration

6. **Apps** (151 Docker Apps)
   - Checklist-based multi-select
   - GPU configuration per app
   - Traefik integration per app
   - Batch installation with progress

7. **Ansible** (SysConfig)
   - System Apps Installation (16 apps)
   - Power Management Settings
   - Touchpad Configuration
   - NTFS/exFAT Automount Setup
   - Package Updates
   - Full System Onboarding

8. **Tools**
   - Stack Manager (up/down/restart/logs/recreate)
   - LazyDocker Terminal UI
   - Backup/Restore
   - Database Creation (MariaDB/PostgreSQL)
   - .env Editor
   - Secrets Editor
   - Version Pins
   - Health Diagnostics
   - Change Hostname
   - Change Server IP

9. **Settings**
   - Mode Configuration (Standard/Expert)
   - Status Viewing
   - Log Access
   - Reset Options
   - Removal Options

10. **About**
    - License Information
    - Feature Details
    - Changelog
    - Documentation Links
    - Feedback Submission
    - Support Log Generation

---

## Setup Modes

### Local Mode
- Apps accessible only on the local network
- Access via: `http://SERVER_IP:PORT`
- No domain or SSL certificates required
- Perfect for single-server homelab setups
- Minimal configuration needed

### Remote Mode
- Apps accessible via Traefik reverse proxy
- Access via: `https://subdomain.yourdomain.com`
- Automatic SSL certificate management (Let's Encrypt)
- External access with proper security
- Requires domain name and port forwarding (80/443)

### Hybrid Mode
- Mix of local and remote access
- Some apps behind Traefik, others direct access
- Flexible configuration per application
- Best of both worlds

---

## System Type Auto-Detection

Zoolandia automatically detects your environment:

- **Barebones**: Physical server/bare metal
- **VM**: Virtual Machine (VMware, VirtualBox, KVM, QEMU, Xen)
- **LXC**: Linux Container
- **WSL**: Windows Subsystem for Linux
- **Laptop**: Battery-powered device
- **Workstation**: Desktop computer

Manual override available via: `Prerequisites → System Type → Change`

---

## Configuration Files

### Created by Zoolandia

**Configuration & State**:
- `~/.config/zoolandia/zoolandia.conf` - Main configuration
- `~/.config/zoolandia/*_done` - State tracking files
- `/var/tmp/zoolandia/` - Cache directory

**Docker Environment**:
- `~/docker/.env` - Environment variables
- `~/docker/docker-compose.yml` - Main compose file
- `~/docker/compose/` - Individual app compose files
- `~/docker/secrets/` - Docker secrets directory
- `~/docker/appdata/` - Application data
- `~/docker/logs/` - Application logs

**Service Configurations**:
- `~/docker/traefik/` - Traefik configuration files
- `~/docker/authelia/` - Authelia configuration
- `~/docker/authentik/` - Authentik configuration

### Directory Structure

```
~/docker/                           # Main Docker directory
├── docker-compose.yml              # Main compose file
├── .env                            # Environment variables
├── compose/                        # Individual app compose files (151)
├── secrets/                        # Docker secrets
├── traefik/                        # Traefik configuration
│   ├── traefik.yml                # Static configuration
│   ├── file-provider/             # Dynamic configuration
│   │   ├── middlewares-*.yml     # Middleware definitions
│   │   ├── chain-*.yml           # Middleware chains
│   │   └── tls-opts.yml          # TLS configuration
│   └── acme.json                  # SSL certificates
├── authelia/                       # Authelia configuration
│   ├── configuration.yml
│   └── users.yml
├── authentik/                      # Authentik configuration
│   ├── middlewares-authentik.yml
│   └── chain-authentik.yml
├── appdata/                        # Application data
│   ├── plex/
│   ├── jellyfin/
│   ├── sonarr/
│   └── ...
└── logs/                           # Application logs
    ├── traefik/
    └── ...
```

---

## Technical Details

### Dependencies

**Required** (auto-installed):
- bash 4.0+
- dialog (ncurses-based TUI)
- curl
- wget
- git
- jq
- sudo/root privileges
- coreutils

**Auto-installed During Setup**:
- Docker Engine 20.10+
- Docker Compose V2
- Various system utilities based on selected package tiers

### Compatibility

**Operating Systems**:
- Ubuntu 20.04+, 22.04, 24.04, 25.04
- Debian 11+, 12
- Linux Mint 20+
- Pop!_OS 20.04+
- Other Debian/Ubuntu derivatives

**Architectures**:
- x86-64 (AMD64) - Primary
- ARM64 (AArch64) - Supported
- ARMv7 - Limited support

**Shell**:
- Bash 4.0+
- Dialog for TUI interface

**Docker**:
- Docker Engine 20.10+
- Docker Compose V2 (plugin)

**Ansible** (for system apps):
- Ansible 2.9+
- Python 3.8+

---

## Adding New Applications

### Docker Apps

1. Create compose file: `compose/myapp.yml`
2. Add to `modules/20_apps.sh`:
   - Add description in `get_app_description()` function
3. Test installation through Apps menu
4. Update `APPS.md` documentation

### System Apps (Ansible)

1. Create playbook: `ansible/roles/common/tasks/compose/myapp.yml`
2. Follow existing structure with installation checks
3. Add to `setup.yml` omnibus playbook
4. Add to `modules/22_system_apps.sh` menu
5. Update `APPS.md` documentation

Example Ansible playbook structure:
```yaml
---
- name: Install MyApp
  block:
    - name: Check if MyApp is installed
      shell: "command -v myapp"
      register: myapp_check
      ignore_errors: true

    - name: Download MyApp
      get_url:
        url: "download_url"
        dest: /tmp/myapp.deb
      when: myapp_check.rc != 0
      ignore_errors: true

    - name: Install MyApp
      apt:
        deb: /tmp/myapp.deb
      when: myapp_check.rc != 0
      ignore_errors: true
      register: myapp_install

    - name: Cleanup
      file:
        path: /tmp/myapp.deb
        state: absent

- name: Track installation failure
  set_fact:
    failures: "{{ failures + ['MyApp installation failed'] }}"
  when: myapp_install is defined and myapp_install.failed | default(false)
```

---

## Troubleshooting

### Check Prerequisites
```bash
# Verify dialog is installed
command -v dialog

# Check Docker status
sudo systemctl status docker

# Verify Docker Compose
docker compose version
```

### Check Installation Status
```bash
# For Snap packages
snap list | grep <package_name>

# For APT packages
dpkg -l | grep <package_name>

# For Docker containers
docker ps -a | grep <container_name>
```

### View Logs
- Access logs via Settings → View Logs
- Docker logs: `docker logs <container_name>`
- Traefik logs: `~/docker/logs/traefik/`

### Re-run Failed Installations
Since each task checks if the application is already installed, you can safely re-run installations without duplicating work.

### Reset Configuration
Use Settings → Reset Options to clear specific configurations or perform a full reset.

---

## Known Limitations

- **DNS Challenge Provider**: Currently Cloudflare-only for automatic SSL
- **Port Forwarding**: Requires ports 80/443 open for Let's Encrypt and external access
- **Database Apps**: Some apps with databases may require manual database removal
- **Hardcoded Values**: Some Ansible playbooks reference specific usernames (see documentation/analysis/)

---

## License Options

Zoolandia offers flexible licensing to suit different needs:

- **Free Tier**: Essential features for basic homelab setups
- **Paid Tiers**:
  - Basic
  - Plus
  - Pro

[View Detailed Comparison](https://www.simplehomelab.com/zoolandia/pricing/)

**Note**: Annual [website memberships](https://www.simplehomelab.com/membership-account/join-the-geek-army/) include full Zoolandia access!

---

## Support & Community

### Get Help
- [Zoolandia Docs](https://docs.zoolandia.app) - Comprehensive documentation, fixes, and guides
- [Discord Community](https://www.simplehomelab.com/discord/) - Active community support
- [YouTube Channel](https://www.youtube.com/@Simple-Homelab) - Video tutorials and walkthroughs
- [Support Log Generator](hack3r.sh → About → Feedback) - Generate diagnostic logs for troubleshooting

### Learn More
- [Official Documentation](https://www.simplehomelab.com/zoolandia/)
- [Quick Start Guide (20 min)](https://www.simplehomelab.com/go/zoolandia-v5-intro/)
- [Comprehensive Tutorial](https://www.simplehomelab.com/go/zoolandia-v5-detailed-guide/)

### Contributing
Part of Zoolandia's revenue supports open-source projects through [OpenCollective](https://opencollective.com/zoolandia).

---

## Version Information

**Current Version**: 6.0.18
**Release Date**: December 30, 2025
**Previous Branding**: DeployIQ (rebranded to Zoolandia in v6.0.6)
**Original Name**: Deployrr (rebranded to DeployIQ, then Zoolandia)

See [CHANGELOG.md](CHANGELOG.md) for complete version history and release notes.

### Recent Major Changes

**v6.0.18** (December 30, 2025)
- NTFS/exFAT automount configuration via Ansible
- Menu spacing improvements
- Universal playbook execution handler

**v6.0.17** (December 30, 2025)
- Power tier addition (VLC media player)

**v6.0.16** (December 30, 2025)
- Security tier addition (YubiKey manager)

**v6.0.15** (December 30, 2025)
- Filesystem support (NTFS, exFAT)
- Build tools (gcc, g++, cmake)
- Disk management (gparted)

**v6.0.0** (December 30, 2025)
- Complete modular architecture refactor
- 16 independent modules
- 96% size reduction in main script (6,117 → 336 lines)

---

## Migration from DeployIQ 5.x

For users upgrading from DeployIQ 5.x or Deployrr:

1. **Backup Configuration**:
   ```bash
   cp -r ~/.config/deployiq ~/.config/deployiq.backup
   ```

2. **Rename Configuration Directory**:
   ```bash
   mv ~/.config/deployiq ~/.config/zoolandia
   ```

3. **Update Environment Variables** (if any):
   - `DEPLOYIQ_MODE` → `ZOOLANDIA_MODE`
   - `DEPLOYIQ_CONFIG_DIR` → `ZOOLANDIA_CONFIG_DIR`

4. **Review Package Installation**:
   - Navigate to Prerequisites → Additional Packages
   - Review and install missing packages as needed

---

## Project Vision

Zoolandia isn't just another container manager - it's your pathway to homelab mastery. Our goals:

- **Simplify Complex Deployments**: Reduce multi-hour setups to minutes
- **Enable Experimentation**: Easy testing of new applications
- **Foster Learning**: Hands-on experience with enterprise technologies
- **Provide Recovery Options**: Quick restoration when things go wrong
- **Build Community**: Share knowledge and configurations

---

## Secret Menu

The **Secret** menu is a private project launcher on the main home screen for personal Ansible projects that should not be part of the shared application library.

### How It Works

Projects are placed in `ansible/roles/secret/`. The menu auto-discovers them at launch — no code changes needed to add or remove projects.

**Supported layouts:**

| Layout | Path |
|--------|------|
| Directory-based | `ansible/roles/secret/<name>/site.yml` |
| Directory-based (alt) | `ansible/roles/secret/<name>/main.yml` |
| Standalone playbook | `ansible/roles/secret/<name>.yml` |

### Adding a New Secret Project

```
ansible/roles/secret/
└── MyProject/
    ├── site.yml       ← main playbook (required)
    └── inventory      ← optional inventory (auto-detected)
```

On the next launch, `MyProject` will appear in the Secret menu automatically. Bundled inventory files (`inventory`, `hosts`, `inventory.yml`, `inventory.ini`, `hosts.yml`) are detected and offered automatically. If none is found, you are prompted for a host IP or inventory path before the playbook runs.

### Running a Project

1. Select **Secret** from the main menu
2. Choose your project from the list (or **Run Custom** to enter any path)
3. Confirm or change the detected inventory
4. Optionally supply extra vars (e.g. `env=production db_port=5432`)
5. Review the summary and press ENTER to run

### RSA Key Auth Gate (Optional)

The Secret menu supports an optional RSA key verification step that runs before the menu is shown. It is disabled by default.

**Configuration** — edit the top of `modules/60_personal.sh`:

```bash
SECRET_AUTH_ENABLED=false              # Set to true to enable
SECRET_KEY_PATH="${HOME}/.ssh/id_rsa"  # Path to your RSA private key
SECRET_KEY_FINGERPRINT=""              # SHA256 fingerprint (leave empty for key-exists check only)
```

**To enable with fingerprint verification:**

```bash
# Step 1 — get your key's fingerprint
ssh-keygen -lf ~/.ssh/id_rsa | awk '{print $2}'
# → SHA256:abc123xyz...

# Step 2 — set in modules/60_personal.sh
SECRET_AUTH_ENABLED=true
SECRET_KEY_FINGERPRINT="SHA256:abc123xyz..."
```

| Mode | Behavior |
|------|----------|
| `SECRET_AUTH_ENABLED=false` | No gate — menu opens immediately (default) |
| `SECRET_AUTH_ENABLED=true`, no fingerprint | Checks that `SECRET_KEY_PATH` exists |
| `SECRET_AUTH_ENABLED=true` + fingerprint set | Verifies `ssh-keygen -lf` output matches `SECRET_KEY_FINGERPRINT` |

If verification fails, an "Access Denied" dialog is shown and the user is returned to the main menu.

---

## Credits

**Created by**: D. Garner
**Website**: [hack3r.gg](http://hack3r.gg)
**Project Site**: [simplehomelab.com](https://www.simplehomelab.com/zoolandia/)
**Discord**: [Join our community](https://www.simplehomelab.com/discord/)

---

<div align="center">

**Transform Your Homelab Journey with Zoolandia**

[Get Started](https://www.simplehomelab.com/zoolandia/) | [Documentation](https://docs.zoolandia.app) | [Join Discord](https://www.simplehomelab.com/discord/) | [Watch Tutorial](https://www.simplehomelab.com/go/zoolandia-v5-intro/)

**167 Applications • Modular Architecture • Enterprise Security • Active Community**

</div>
