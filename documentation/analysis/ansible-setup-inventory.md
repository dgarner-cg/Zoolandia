# Ansible Setup.yml - Application and Configuration Inventory

**File:** `ansible/roles/common/playbooks/setup.yml`
**Analysis Date:** 2025-12-30
**DeployIQ Version:** v5.10

## Overview

This playbook provides automated installation and configuration of desktop applications, development tools, and system settings for Ubuntu-based systems. It's designed for personal workstation onboarding and standardization.

## System Requirements

- **Target OS:** Ubuntu (primary), Linux distributions with apt package manager
- **Python Interpreter:** Python 3.12
- **Privileges:** Requires root/sudo access (`become: true`)
- **Target User:** `dgarner` (hardcoded in several tasks)

---

## Applications Installed

### Web Browsers

| Application | Method | Package Source | Notes |
|------------|--------|----------------|-------|
| **Vivaldi** | Snap | snapcraft.io | Modern web browser with customization features |

### Communication Tools

| Application | Method | Package Source | Notes |
|------------|--------|----------------|-------|
| **Discord** | APT (.deb) | discord.com | Voice, video, and text communication platform |
| **Zoom** | APT (.deb) | zoom.us | Video conferencing software |
| **Mailspring** | Snap | snapcraft.io | Email client |

### Productivity Applications

| Application | Method | Package Source | Notes |
|------------|--------|----------------|-------|
| **Notepad++** | Snap | snapcraft.io | Text editor (via Wine/Snap) |
| **Notion** | Snap | snapcraft.io | Note-taking and project management (notion-snap-reborn) |
| **ONLYOFFICE** | APT (.deb) | onlyoffice.com | Office suite (word processing, spreadsheets, presentations) |

### Security & VPN

| Application | Method | Package Source | Notes |
|------------|--------|----------------|-------|
| **Bitwarden** | Snap | snapcraft.io | Password manager |
| **Proton VPN** | APT + Repository | repo.protonvpn.com | VPN client (proton-vpn-gnome-desktop) |
| **Twingate** | Shell Script | binaries.twingate.com | Zero Trust network access client |

### Development & Automation

| Application | Method | Package Source | Notes |
|------------|--------|----------------|-------|
| **Docker CE** | APT + Repository | download.docker.com | Container platform (includes Docker Engine, CLI, containerd) |
| **Docker Compose** | APT Plugin | download.docker.com | Multi-container orchestration (docker-compose-plugin) |
| **Docker Buildx** | APT Plugin | download.docker.com | Extended build capabilities (docker-buildx-plugin) |
| **Portainer BE** | Docker Container | hub.docker.com | Container management UI (Business Edition) |
| **n8n** | Docker Container | hub.docker.com | Workflow automation platform |

### System Utilities

| Application | Method | Package Source | Notes |
|------------|--------|----------------|-------|
| **Termius** | APT (.deb) | termius.com | SSH/SFTP client |
| **iCloud for Linux** | Snap | snapcraft.io | iCloud integration for Linux |
| **ulauncher** | APT + PPA | ppa:agornostal/ulauncher | Application launcher with Wayland support |
| **wmctrl** | APT | Ubuntu repositories | Window management utility (for ulauncher Wayland support) |

---

## System Configurations Applied

### Power Management Settings

| Configuration | Setting | Applied To | Value |
|--------------|---------|------------|-------|
| Sleep timeout (AC power) | Disabled | GNOME gsettings | 0 (never sleep) |
| Sleep timeout (Battery) | Disabled | GNOME gsettings | 0 (never sleep) |
| Lid close action (AC) | Hibernate | GNOME gsettings | 'hibernate' |
| Lid close action (Battery) | Hibernate | GNOME gsettings | 'hibernate' |

**Note:** The playbook contains conflicting configurations:
- Lines 599-604: Configure lid close to 'suspend'
- Lines 607-613: Overwrite to 'hibernate'

### Touchpad Settings

| Configuration | Setting | User | Value |
|--------------|---------|------|-------|
| Touchpad speed | Increased | dgarner | 0.5 (65% speed) |
| Secondary click method | Two-finger tap | dgarner | 'fingers' |

### Docker Configuration

| Configuration | Setting | Details |
|--------------|---------|---------|
| User group membership | docker group | User `dgarner` added to docker group |
| Service state | Started & Enabled | Docker daemon configured to start on boot |
| Portainer data | Docker volume | `portainer_data` volume created |
| Portainer ports | 8000, 9443 | Management and HTTPS UI ports |
| n8n data directory | `/home/dgarner/.n8n` | Persistent workflow storage |
| n8n port | 5678 | HTTP access port |

---

## Installation Methods Summary

| Method | Count | Applications |
|--------|-------|-------------|
| **Snap** | 7 | Vivaldi, Notepad++, Notion, Bitwarden, Mailspring, iCloud for Linux, ulauncher (partial) |
| **APT (.deb download)** | 5 | Discord, Termius, Zoom, ONLYOFFICE, Proton VPN |
| **APT + Repository** | 2 | Proton VPN, Docker |
| **APT + PPA** | 1 | ulauncher |
| **Docker Container** | 2 | Portainer BE, n8n |
| **Shell Script** | 1 | Twingate |

---

## Dependencies Installed

### Docker Prerequisites
- ca-certificates
- curl
- gnupg
- lsb-release

### Zoom Dependencies
- wget
- libxcb-xtest0

### ulauncher Dependencies
- wmctrl (for Wayland support)

---

## Package Repositories Added

1. **Docker Official Repository**
   - GPG Key: `/etc/apt/keyrings/docker.gpg`
   - Source: `https://download.docker.com/linux/ubuntu`

2. **Proton VPN Repository**
   - Package: `protonvpn-stable-release_1.0.4_all.deb`
   - Source: `https://repo.protonvpn.com/debian`

3. **ulauncher PPA**
   - Repository: `ppa:agornostal/ulauncher`
   - Requires universe repository

---

## Post-Installation Actions Required

The following applications require manual configuration after installation:

1. **Portainer Business Edition**
   - Access: `https://localhost:9443`
   - Action: Create admin account on first access

2. **n8n**
   - Access: `http://localhost:5678`
   - Action: Create user account on first access

3. **Twingate**
   - Action: Run `sudo twingate setup` to complete configuration

4. **ulauncher (Wayland users)**
   - Configure hotkey in Ulauncher Preferences
   - Add custom keyboard shortcut in GNOME Settings
   - Command: `ulauncher-toggle`

5. **Docker**
   - Action: Re-login required for docker group membership to take effect

---

## Error Handling

The playbook implements comprehensive error tracking:

- **Failure List Variable:** `failures[]` array collects all installation failures
- **Ignore Errors:** All tasks use `ignore_errors: true` to prevent playbook termination
- **Idempotency Checks:** Applications check if already installed before proceeding
- **Summary Report:** Final task prints all failures at completion

### Installation Checks

Each application performs pre-installation checks:
- **Snap packages:** `snap list | grep <package>`
- **APT packages:** `dpkg -l | grep <package>`
- **Docker containers:** `docker ps -a | grep <container>`
- **Binaries:** `command -v <binary>`

---

## Hardcoded Values

The following values are hardcoded and may need customization:

1. **Username:** `dgarner` (appears in 11+ tasks)
2. **User ID:** `1000` (DBUS session bus path)
3. **Home Directory:** `/home/dgarner`
4. **Python Interpreter:** `/usr/bin/python3.12`
5. **n8n Data Path:** `/home/dgarner/.n8n`
6. **Touchpad Speed:** `0.5`
7. **Portainer Ports:** `8000`, `9443`
8. **n8n Port:** `5678`

---

## Network Downloads

The playbook downloads packages from the following external sources:

1. discord.com
2. termius.com
3. zoom.us
4. onlyoffice.com
5. download.docker.com
6. repo.protonvpn.com
7. binaries.twingate.com
8. hub.docker.com (Docker images)

**Timeout Configuration:**
- Discord download: 1200 seconds (20 minutes)
- Default: Ansible default timeout

---

## File System Modifications

### Directories Created
- `/etc/apt/keyrings` (for Docker GPG keys)
- `/home/dgarner/.n8n` (for n8n data)

### Files Created/Modified
- `/etc/apt/keyrings/docker.gpg` (Docker GPG key)
- `/etc/apt/sources.list.d/docker.list` (Docker repository)
- Various temporary `.deb` files in `/tmp/` (cleaned up after installation)

### Docker Volumes Created
- `portainer_data` (Portainer configuration and data)

---

## Summary Statistics

- **Total Applications:** 17
- **System Configurations:** 6 (power management + touchpad)
- **Docker Containers:** 2 (Portainer, n8n)
- **External Repositories:** 3 (Docker, Proton VPN, ulauncher PPA)
- **Lines of Code:** 659
- **Installation Blocks:** 15
- **Failure Tracking Points:** 15
