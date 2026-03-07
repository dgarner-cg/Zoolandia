# Ansible Applications & Configurations Enumeration

## Overview
This document enumerates all applications and configurations defined in the DeployIQ Ansible setup, primarily from `ansible/roles/common/playbooks/setup.yml`.

**Source File**: `ansible/roles/common/playbooks/setup.yml`
**Lines**: 659 lines
**Hosts**: All
**Python Interpreter**: `/usr/bin/python3.12`

---

## 📱 Desktop Applications (Snap-based)

### 1. **Vivaldi Browser**
- **Package**: `vivaldi` (Snap)
- **Type**: Web Browser
- **Installation Method**: Snap
- **Check Command**: `snap list | grep vivaldi`
- **Lines**: 20-37

### 2. **Notepad++**
- **Package**: `notepad-plus-plus` (Snap)
- **Type**: Text Editor
- **Installation Method**: Snap
- **Check Command**: `snap list | grep notepad-plus-plus`
- **Lines**: 85-103

### 3. **Notion**
- **Package**: `notion-snap-reborn` (Snap)
- **Type**: Note-taking & Collaboration
- **Installation Method**: Snap
- **Check Command**: `snap list | grep notion-snap-reborn`
- **Lines**: 105-123

### 4. **Bitwarden**
- **Package**: `bitwarden` (Snap)
- **Type**: Password Manager
- **Installation Method**: Snap
- **Check Command**: `snap list | grep bitwarden`
- **Lines**: 125-142

### 5. **Mailspring**
- **Package**: `mailspring` (Snap)
- **Type**: Email Client
- **Installation Method**: Snap
- **Check Command**: `snap list | grep mailspring`
- **Lines**: 185-202

### 6. **iCloud for Linux**
- **Package**: `icloud-for-linux` (Snap)
- **Type**: Cloud Storage Integration
- **Installation Method**: Snap
- **Check Command**: `snap list | grep icloud-for-linux`
- **Lines**: 343-361

---

## 📦 Desktop Applications (.deb packages)

### 7. **Discord**
- **Package**: `discord` (Direct download)
- **Type**: Communication Platform
- **Installation Method**: Downloaded .deb package
- **Download URL**: `https://discord.com/api/download?platform=linux&format=deb`
- **Timeout**: 1200 seconds (20 minutes)
- **Check Command**: `dpkg -l | grep discord`
- **Lines**: 39-83
- **Post-install**: Fixes missing dependencies

### 8. **Proton VPN**
- **Package**: `proton-vpn-gnome-desktop`
- **Type**: VPN Client
- **Installation Method**: Repository + .deb package
- **Repository Package**: `protonvpn-stable-release_1.0.4_all.deb`
- **Repository URL**: `https://repo.protonvpn.com/debian/dists/stable/main/binary-all/`
- **Check Command**: `dpkg -l | grep protonvpn`
- **Lines**: 144-183

### 9. **Termius**
- **Package**: `Termius` (Direct download)
- **Type**: SSH Client
- **Installation Method**: Downloaded .deb package
- **Download URL**: `https://www.termius.com/download/linux/Termius.deb`
- **Check Command**: `dpkg -l | grep Termius`
- **Lines**: 204-238

### 10. **Zoom**
- **Package**: `zoom` (Direct download)
- **Type**: Video Conferencing
- **Installation Method**: Downloaded .deb package
- **Download URL**: `https://zoom.us/client/latest/zoom_amd64.deb`
- **Dependencies**: `wget`, `libxcb-xtest0`
- **Check Command**: `dpkg -l | grep zoom`
- **Lines**: 240-281

### 11. **ONLYOFFICE Desktop Editors**
- **Package**: `onlyoffice-desktopeditors` (Direct download)
- **Type**: Office Suite
- **Installation Method**: Downloaded .deb package
- **Download URL**: `https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb`
- **Check Command**: `dpkg -l | grep onlyoffice-desktopeditors`
- **Lines**: 283-316

---

## 🔒 Security & Network Applications

### 12. **Twingate**
- **Package**: `twingate` (curl install script)
- **Type**: Zero Trust Network Access
- **Installation Method**: Curl script installation
- **Install Command**: `curl -s https://binaries.twingate.com/client/linux/install.sh | sudo bash`
- **Check Command**: `command -v twingate`
- **Post-install Note**: "Please run `sudo twingate setup` to complete the configuration."
- **Distribution**: Ubuntu only
- **Lines**: 318-341

---

## 🚀 System Utilities (APT)

### 13. **ulauncher**
- **Package**: `ulauncher` (PPA)
- **Type**: Application Launcher
- **Installation Method**: PPA + APT
- **Repository**: `ppa:agornostal/ulauncher`
- **Additional Package**: `wmctrl` (for Wayland support)
- **Prerequisites**: Universe repository
- **Check Command**: `dpkg -l | grep ulauncher`
- **Lines**: 363-424
- **Post-install Note**: Configuration instructions for Wayland support
  1. Open Ulauncher Preferences and set hotkey to something you'll never use
  2. Open Settings > Keyboard > Customize Shortcuts > Custom Shortcuts > +
  3. Set Command: `ulauncher-toggle`, add name and shortcut, then click Add

---

## 🐳 Docker-based Applications

### 14. **Docker Engine & Docker Compose**
- **Packages**:
  - `docker-ce`
  - `docker-ce-cli`
  - `containerd.io`
  - `docker-buildx-plugin`
  - `docker-compose-plugin`
- **Type**: Container Runtime
- **Installation Method**: Official Docker repository
- **Prerequisites**: `ca-certificates`, `curl`, `gnupg`, `lsb-release`
- **GPG Key**: `https://download.docker.com/linux/ubuntu/gpg`
- **Repository**: `https://download.docker.com/linux/ubuntu`
- **User Added to Group**: `dgarner` (added to `docker` group)
- **Service**: Enabled and started via systemd
- **Check Command**: `command -v docker`
- **Lines**: 425-508

### 15. **Portainer Business Edition**
- **Package**: `portainer/portainer-ee:latest` (Docker)
- **Type**: Container Management UI
- **Installation Method**: Docker container
- **Ports**:
  - `8000:8000`
  - `9443:9443`
- **Volume**: `portainer_data`
- **Mounts**: `/var/run/docker.sock:/var/run/docker.sock`
- **Restart Policy**: Always
- **Access URL**: `https://localhost:9443`
- **Check Command**: `docker ps -a | grep portainer`
- **Post-install Note**: "You'll need to create an admin account on first access."
- **Lines**: 510-545

### 16. **n8n**
- **Package**: `n8nio/n8n:latest` (Docker)
- **Type**: Workflow Automation
- **Installation Method**: Docker container
- **Port**: `5678:5678`
- **Environment Variables**:
  - `N8N_HOST=localhost`
  - `N8N_PORT=5678`
  - `N8N_PROTOCOL=http`
  - `WEBHOOK_URL=http://localhost:5678/`
- **Data Directory**: `/home/dgarner/.n8n`
- **Volume Mount**: `/home/dgarner/.n8n:/home/node/.n8n`
- **Restart Policy**: Always
- **Access URL**: `http://localhost:5678`
- **Check Command**: `docker ps -a | grep n8n`
- **Post-install Note**: "You'll need to create an account on first access."
- **Lines**: 547-589

---

## ⚙️ System Configurations

### Power Management Settings

#### Sleep & Hibernation (Lines 591-613)
1. **Disable Sleep (AC Power)**
   - Setting: `org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout`
   - Value: `0` (disabled)

2. **Disable Sleep (Battery)**
   - Setting: `org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout`
   - Value: `0` (disabled)

3. **Lid Close Action (AC) - Suspend**
   - Setting: `org.gnome.settings-daemon.plugins.power lid-close-ac-action`
   - Value: `suspend`

4. **Lid Close Action (Battery) - Suspend**
   - Setting: `org.gnome.settings-daemon.plugins.power lid-close-battery-action`
   - Value: `suspend`

5. **Lid Close Action (AC) - Hibernate**
   - Setting: `org.gnome.settings-daemon.plugins.power lid-close-ac-action`
   - Value: `hibernate`

6. **Lid Close Action (Battery) - Hibernate**
   - Setting: `org.gnome.settings-daemon.plugins.power lid-close-battery-action`
   - Value: `hibernate`

**Note**: Lines 607-613 appear to override lines 599-605, setting hibernate instead of suspend for lid close actions.

### Touchpad Settings (Lines 619-653)

#### Touchpad Speed
- **User**: `dgarner`
- **Setting**: `org.gnome.desktop.peripherals.touchpad speed`
- **Value**: `0.5` (65% speed increase)
- **DBUS Session**: `unix:path=/run/user/1000/bus`
- **Lines**: 619-642

#### Two-Finger Secondary Click
- **User**: `dgarner`
- **Setting**: `org.gnome.desktop.peripherals.touchpad click-method`
- **Value**: `fingers` (enables two-finger tap for right-click)
- **DBUS Session**: `unix:path=/run/user/1000/bus`
- **Lines**: 625-653

---

## 🔧 Error Handling & Reporting

### Failure Tracking System
The playbook implements a comprehensive failure tracking system:

**Variables**:
- `failures: []` - Array to track failed installations

**Tracked Failures**:
1. Package list update failure
2. Vivaldi installation failure
3. Discord installation/download failure
4. Notepad++ installation failure
5. Notion installation failure
6. Bitwarden installation failure
7. Proton VPN installation/download failure
8. Mailspring installation failure
9. Termius installation/download failure
10. Zoom installation/download failure
11. ONLYOFFICE installation/download failure
12. Twingate installation failure
13. iCloud for Linux installation failure
14. ulauncher installation/PPA/wmctrl failure
15. Docker installation failure
16. Portainer Business Edition installation failure
17. n8n installation failure

**Final Report** (Lines 655-658):
- Prints summary of all failed tasks at the end
- Condition: `when: failures`
- Message: "The following tasks failed: {{ failures }}"

---

## 📊 Installation Summary by Category

### By Installation Method
| Method | Count | Applications |
|--------|-------|--------------|
| Snap | 6 | Vivaldi, Notepad++, Notion, Bitwarden, Mailspring, iCloud for Linux |
| .deb (Direct) | 5 | Discord, Termius, Zoom, ONLYOFFICE, Proton VPN |
| curl/script | 1 | Twingate |
| APT/PPA | 1 | ulauncher |
| Docker Official | 1 | Docker Engine & Compose |
| Docker Container | 2 | Portainer BE, n8n |

### By Category
| Category | Count | Applications |
|----------|-------|--------------|
| Browsers | 1 | Vivaldi |
| Communication | 3 | Discord, Zoom, Mailspring |
| Editors/Productivity | 3 | Notepad++, Notion, ONLYOFFICE |
| Security | 3 | Bitwarden, Proton VPN, Twingate |
| Cloud/Storage | 1 | iCloud for Linux |
| Terminal/SSH | 1 | Termius |
| System Utilities | 1 | ulauncher |
| Container Platform | 1 | Docker |
| Container Management | 2 | Portainer BE, n8n |

### Total Applications: **16**

---

## 🎯 Key Features

### 1. **Idempotency**
- All installations check if the application is already installed before attempting installation
- Prevents duplicate installations and reduces execution time

### 2. **Error Resilience**
- All tasks use `ignore_errors: true`
- Failures are tracked but don't stop the playbook execution
- Comprehensive error reporting at the end

### 3. **User Configuration**
- Hardcoded user: `dgarner`
- Used for Docker group membership and GNOME settings
- DBUS sessions configured for user-specific settings

### 4. **Network Timeouts**
- Discord download has extended timeout (1200 seconds / 20 minutes)
- Handles slow network connections gracefully

### 5. **Cleanup**
- All downloaded .deb files are removed after installation
- Prevents disk space waste from temporary files

### 6. **Post-Install Reminders**
- Twingate: Run `sudo twingate setup`
- ulauncher: Wayland configuration steps
- Portainer: Create admin account at `https://localhost:9443`
- n8n: Create account at `http://localhost:5678`

---

## 📁 Related Files

Based on the ansible structure, there are additional component files:

### Individual Application Playbooks (zFiles/)
Located in `ansible/roles/common/zFiles/`:
- `vivaldi.yml`
- `discord.yml`
- `notepad-plus-plus.yml`
- `notion.yml`
- `bitwarden.yml`
- `protonvpn.yml`
- `mailspring.yml`
- `termius.yml`
- `zoom.yml`
- `icloud.yml`
- `ulauncher.yml`
- `docker.yml`
- `portainer.yml`
- `twingate.yml`

### Task Files
Located in `ansible/roles/common/tasks/`:
- `main.yml` - Main task entry point
- `package_update.yml` - Package update tasks
- `power_management.yml` - Power management configurations
- `touchpad_settings.yml` - Touchpad configuration tasks
- `razer-12.5.yml` - Razer-specific configurations

### Other Playbooks
Located in `ansible/roles/common/playbooks/`:
- `main.yml` - Main playbook entry point
- `setup_all.yml` - Setup all applications
- `setup_individual.yml` - Setup individual applications
- `setup_new.yml` - Setup new applications
- `setup.yml` - **This file** (comprehensive setup)

---

## 🔍 Notable Configuration Details

### GNOME Settings Application
- Uses `gsettings` command-line tool
- Settings applied via `sudo -u dgarner` to ensure correct user context
- DBUS session bus specified: `unix:path=/run/user/1000/bus`
- Confirms settings were applied by reading them back

### Docker Setup
- Official Docker repository used (not snap or outdated APT packages)
- Includes all modern plugins (buildx, compose plugin)
- User added to docker group for non-root access
- Service enabled for automatic startup

### Package Manager Detection
- Supports multiple Linux distributions
- Fallback mechanisms for unsupported package managers
- Warning messages guide manual installation when needed

---

## 📈 Execution Flow

```
1. Update package list
2. Install Snap applications (6 apps)
3. Install .deb applications (5 apps)
4. Install Twingate (curl script)
5. Install ulauncher (PPA + APT)
6. Install Docker Engine & Compose
7. Deploy Portainer Business Edition (Docker)
8. Deploy n8n (Docker)
9. Configure power management settings
10. Configure touchpad settings
11. Print completion message
12. Print failure summary (if any)
```

---

## 💡 Usage Recommendations

1. **Review user-specific configurations**: Change `dgarner` to appropriate username
2. **Test in stages**: Run individual application blocks before full playbook
3. **Monitor failures**: Check the failures array output for troubleshooting
4. **Verify DBUS session**: Ensure `/run/user/1000/bus` exists for GNOME settings
5. **Check Docker permissions**: Verify user is in docker group post-installation
6. **Post-install tasks**: Follow printed reminders for applications requiring setup

---

## 🏷️ Version Information

- **Ansible Python Interpreter**: `/usr/bin/python3.12`
- **Docker Compose**: Plugin-based (not standalone binary)
- **Portainer**: Business Edition (latest)
- **n8n**: Latest
- **All other applications**: Latest versions from respective sources

---

**Generated**: 2025-12-28
**Source**: `ansible/roles/common/playbooks/setup.yml`
**Total Lines Analyzed**: 659
