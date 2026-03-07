# Applications & Configurations Reference

**Zoolandia Ansible Workstation Setup - Production Edition**
**Version:** 1.0.0
**Last Updated:** 2026-01-06

This document provides a complete enumeration of all applications, system configurations, and features included in this Ansible role.

---

## 📑 Table of Contents

- [Snap Applications](#snap-applications)
- [DEB Package Applications](#deb-package-applications)
- [Complex Applications](#complex-applications)
- [System Configurations](#system-configurations)
- [Pre-Flight Checks](#pre-flight-checks)
- [Feature Flags](#feature-flags)
- [Tags Reference](#tags-reference)
- [Enable/Disable Reference](#enabledisable-reference)

---

## 📦 Snap Applications

**Installation Method:** Loop-based (single file handles all)
**File:** `roles/workstation/tasks/applications/simple/apps.yml`
**Total:** 8 applications

| # | Application | Package Name | Category | Default | Description |
|---|-------------|--------------|----------|---------|-------------|
| 1 | **Vivaldi** | `vivaldi` | Browser | ✅ Enabled | Modern Chromium-based web browser with extensive customization |
| 2 | **Bitwarden** | `bitwarden` | Security | ✅ Enabled | Open-source password manager and vault |
| 3 | **Notepad++** | `notepad-plus-plus` | Development | ✅ Enabled | Advanced text and source code editor |
| 4 | **Notion** | `notion-snap-reborn` | Productivity | ✅ Enabled | All-in-one workspace for notes and collaboration |
| 5 | **Mailspring** | `mailspring` | Communication | ✅ Enabled | Beautiful, fast email client with modern features |
| 6 | **Claude Code** | `claude-code` | Development | ✅ Enabled | Claude AI code assistant CLI tool |
| 7 | **ChatGPT Desktop** | `chatgpt-desktop-client` | Productivity | ✅ Enabled | ChatGPT desktop application interface |
| 8 | **iCloud for Linux** | `icloud-for-linux` | Cloud | ❌ Disabled | iCloud Drive integration (experimental) |

### Installation Command
```bash
# Installed automatically via loop
sudo snap install <package-name>
```

### Tags
- `--tags "snap"` - Install all snap applications
- `--tags "applications"` - Install all applications (snap + deb + complex)

### Enable/Disable
Edit `roles/workstation/defaults/main.yml`:
```yaml
snap_apps:
  - name: vivaldi
    enabled: true  # Set to false to skip
```

---

## 📥 DEB Package Applications

**Installation Method:** Loop-based with download + install
**File:** `roles/workstation/tasks/applications/simple/apps.yml`
**Total:** 4 applications

| # | Application | Download URL | Category | Default | Description |
|---|-------------|--------------|----------|---------|-------------|
| 1 | **Discord** | discord.com API | Communication | ✅ Enabled | Voice, video, and text chat for communities |
| 2 | **Zoom** | zoom.us | Communication | ✅ Enabled | Video conferencing and collaboration platform |
| 3 | **Termius** | termius.com | Development | ❌ Disabled | Modern SSH client with sync capabilities |
| 4 | **OnlyOffice** | onlyoffice.com | Productivity | ✅ Enabled | Free office suite (docs, spreadsheets, presentations) |

### Installation Process
1. Download .deb package to `/tmp/zoolandia_ansible_downloads/`
2. Install via `apt` with dependency resolution
3. Cleanup downloaded files (optional)

### Retry Logic
- **Retries:** 3 attempts
- **Delay:** 5 seconds between retries
- **Timeout:** 1200 seconds (20 minutes)

### Tags
- `--tags "deb"` - Install all DEB applications
- `--tags "applications"` - Install all applications

### Enable/Disable
Edit `roles/workstation/defaults/main.yml`:
```yaml
deb_apps:
  - name: discord
    enabled: true  # Set to false to skip
```

---

## 🔧 Complex Applications

**Installation Method:** Individual task files
**Location:** `roles/workstation/tasks/applications/complex/`
**Total:** 6 applications (6 implemented)

### Implemented Applications

#### 1. Docker CE
**Status:** ✅ Implemented
**File:** `applications/complex/docker.yml`
**Default:** Enabled
**Complexity:** HIGH

**What Gets Installed:**
- Docker Engine (docker-ce)
- Docker CLI (docker-ce-cli)
- containerd.io (container runtime)
- Docker Buildx Plugin
- Docker Compose Plugin

**Additional Configuration:**
- Adds Docker APT repository
- Installs GPG key
- Adds current user to `docker` group
- Enables Docker service

**Variable:** `install_docker: true`
**Tags:** `docker`, `complex`, `applications`

**Post-Installation:**
- Requires logout/login for group membership
- Verify with: `docker --version`

---

#### 2. Portainer
**Status:** ✅ Implemented
**File:** `applications/complex/portainer.yml`
**Default:** Enabled
**Complexity:** MEDIUM

**What Gets Installed:**
- Portainer container (CE or EE edition)
- Docker volume: `portainer_data`

**Configuration:**
- HTTP Port: 8000
- HTTPS Port: 9443
- Auto-restart: always
- Health checks: enabled

**Variable:** `install_portainer: true`
**Tags:** `portainer`, `docker`, `complex`, `applications`
**Requires:** Docker must be installed first

**Access:**
- HTTPS: `https://localhost:9443`
- HTTP: `http://localhost:8000`

---

#### 3. Twingate
**Status:** ✅ Implemented (with security fix)
**File:** `applications/complex/twingate.yml`
**Default:** Disabled
**Complexity:** HIGH

**Security Fix:**
- ❌ OLD: `curl -s URL | sudo bash` (DANGEROUS)
- ✅ NEW: Download → Verify → Execute (SECURE)

**What Gets Installed:**
- Twingate VPN client

**Installation Process:**
1. Download installation script
2. Display checksum for verification
3. Execute script securely

**Variable:** `install_twingate: false`
**Tags:** `twingate`, `complex`, `applications`

**Post-Installation:**
- Run: `sudo twingate setup`
- Follow prompts to connect to network

---

#### 4. ProtonVPN
**Status:** ✅ Implemented
**File:** `applications/complex/protonvpn.yml`
**Default:** Disabled
**Complexity:** HIGH

**What Gets Installed:**
- ProtonVPN GNOME desktop client
- ProtonVPN repository configuration

**Installation Process:**
1. Download ProtonVPN repository .deb package
2. Install repository configuration
3. Update APT cache
4. Install proton-vpn-gnome-desktop

**Variable:** `install_protonvpn: false`
**Tags:** `protonvpn`, `vpn`, `complex`, `applications`

**Configuration Variables:**
```yaml
protonvpn:
  repo_deb_url: "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.4_all.deb"
  package_name: "proton-vpn-gnome-desktop"
```

---

#### 5. Ulauncher
**Status:** ✅ Implemented
**File:** `applications/complex/ulauncher.yml`
**Default:** Enabled
**Complexity:** MEDIUM

**What Gets Installed:**
- Ulauncher application launcher
- Ulauncher PPA
- wmctrl (for Wayland support)

**Installation Process:**
1. Add universe repository
2. Add Ulauncher PPA
3. Update APT cache
4. Install ulauncher and wmctrl

**Variable:** `install_ulauncher: true`
**Tags:** `ulauncher`, `launcher`, `complex`, `applications`

**Wayland Configuration:**
For Wayland users, manual keyboard shortcut configuration is required:
1. Open Ulauncher Preferences, set hotkey to unused combination
2. Go to Settings > Keyboard > Customize Shortcuts > Custom Shortcuts > +
3. Set Command: `ulauncher-toggle`, add name and shortcut

**Configuration Variables:**
```yaml
ulauncher:
  ppa: "ppa:agornostal/ulauncher"
  install_wmctrl: true
```

---

#### 6. n8n
**Status:** ✅ Implemented
**File:** `applications/complex/n8n.yml`
**Default:** Disabled
**Complexity:** MEDIUM

**What Gets Installed:**
- n8n workflow automation Docker container
- Data directory at `~/.n8n`

**Installation Process:**
1. Create n8n data directory
2. Deploy n8n container with persistent volume
3. Wait for container health check

**Configuration:**
- Port: 5678
- Protocol: HTTP
- Host: localhost
- Auto-restart: always
- Data directory: `~/.n8n`

**Variable:** `install_n8n: false`
**Tags:** `n8n`, `docker`, `automation`, `complex`, `applications`
**Requires:** Docker must be installed first

**Access:**
- URL: `http://localhost:5678`
- On first access, create an account

**Configuration Variables:**
```yaml
n8n:
  port: 5678
  data_dir: "{{ workstation_home }}/.n8n"
  protocol: "http"
  host: "localhost"
```

---

## ⚙️ System Configurations

**Total:** 5 configurations (3 implemented, 2 planned)

### Implemented Configurations

#### 1. Nautilus File Manager
**Status:** ✅ Implemented
**File:** `roles/workstation/tasks/system/nautilus_sort.yml`
**Default:** Enabled

**What Gets Configured:**
- Default sort order: `type` (sorts files by type/extension)
- Show hidden files: configurable
- Default view: list-view

**Applies To:** GNOME desktop environment only
**Variable:** `nautilus.enabled: true`
**Tags:** `system`, `nautilus`, `gnome`

**Configuration:**
```yaml
nautilus:
  enabled: true
  sort_order: "type"  # Options: name, size, type, mtime
  show_hidden_files: false
  default_view: "list-view"  # Options: icon-view, list-view
```

---

#### 2. Power Management
**Status:** ✅ Implemented
**File:** `roles/workstation/tasks/system/power_management.yml`
**Default:** Enabled

**What Gets Configured:**
- Automatic sleep disabled (AC and battery)
- Lid close behavior (AC power): hibernate
- Lid close behavior (battery): hibernate

**Installation Process:**
1. Check if GNOME gsettings is available
2. Set sleep-inactive timeout to 0 (disabled)
3. Configure lid-close actions
4. Verify settings

**Applies To:** GNOME desktop environment only
**Variable:** `power_management.enabled: true`
**Tags:** `system`, `power`, `gnome`

**Configuration Variables:**
```yaml
power_management:
  enabled: true
  lid_close_ac_action: "hibernate"  # Options: hibernate, suspend, nothing
  lid_close_battery_action: "hibernate"
  sleep_timeout_ac: 0  # 0 = never sleep
  sleep_timeout_battery: 0
```

---

#### 3. Touchpad Settings
**Status:** ✅ Implemented
**File:** `roles/workstation/tasks/system/touchpad_settings.yml`
**Default:** Enabled

**What Gets Configured:**
- Touchpad movement speed
- Click method (two-finger tap for right-click)

**Installation Process:**
1. Check if GNOME gsettings is available
2. Set touchpad speed
3. Configure click method to "fingers"
4. Verify settings

**Applies To:** GNOME desktop environment only
**Variable:** `touchpad.enabled: true`
**Tags:** `system`, `touchpad`, `gnome`

**Configuration Variables:**
```yaml
touchpad:
  enabled: true
  speed: 0.5  # Range: -1.0 to 1.0
  click_method: "fingers"  # Options: fingers, areas
```

---

### Planned Configurations

#### 4. NTFS/exFAT Support
**Status:** ⏸️ Planned (Phase 2)
**Source:** Original `ansible/roles/common/tasks/touchpad_settings.yml`

**What Will Be Configured:**
- Tap to click
- Natural scrolling
- Two-finger scrolling
- Touchpad speed
- Click method

**Variable:** `touchpad_settings.enabled: true`
**Tags:** `system`, `touchpad`

**Configuration:**
```yaml
touchpad_settings:
  enabled: true
  tap_to_click: true
  natural_scrolling: true
  two_finger_scrolling: true
  speed: 0.5  # 0.0 to 1.0
  click_method: "fingers"  # fingers or areas
```

---

#### 4. NTFS/exFAT Support
**Status:** ⏸️ Planned (Phase 2)
**Source:** Original `ansible/roles/common/tasks/ntfs_automount.yml`

**What Will Be Configured:**
- NTFS filesystem support
- exFAT filesystem support
- Automatic mounting
- Force ntfs-3g over kernel ntfs3

**Variable:** `ntfs_support.enabled: true`
**Tags:** `system`, `filesystems`

**Configuration:**
```yaml
ntfs_support:
  enabled: true
  blacklist_ntfs3: true  # Use ntfs-3g
  install_exfat: true
```

---

#### 5. Razer GRUB Settings
**Status:** ⏸️ Planned (Phase 2)
**Source:** Original `ansible/roles/common/tasks/razer-12.5.yml`

**What Will Be Configured:**
- Custom GRUB kernel parameters
- Specific to Razer 12.5 hardware

**Variable:** `razer_grub.enabled: false`
**Tags:** `system`, `grub`, `razer`

**Configuration:**
```yaml
razer_grub:
  enabled: false  # Only enable for Razer hardware
  kernel_params:
    - "quiet splash"
    - "intel_iommu=off"
    - "iommu=pt"
    - "i915.enable_psr=0"
    - "i915.enable_dc=0"
    - "i915.enable_fbc=0"
    - "i915.fastboot=1"
```

---

## 🔍 Pre-Flight Checks

**File:** `roles/workstation/tasks/preflight/checks.yml`
**Default:** Enabled
**Total Checks:** 7

### Checks Performed

| # | Check | Requirement | Failure Action |
|---|-------|-------------|----------------|
| 1 | **Disk Space** | Minimum 10GB free | Fail playbook |
| 2 | **RAM** | Minimum 4GB total | Warn only |
| 3 | **Internet** | Test URLs reachable | Fail playbook |
| 4 | **Python** | Python 3 installed | Fail playbook |
| 5 | **Snap** | snapd available | Warn if missing |
| 6 | **APT** | Package manager works | Fail playbook |
| 7 | **Desktop** | Detect environment | Info only |

### Configuration
```yaml
preflight_checks:
  enabled: true
  min_disk_space_gb: 10
  check_internet: true
  connectivity_urls:
    - "https://www.google.com"
    - "https://github.com"
  min_ram_gb: 4
  check_python: true
  check_snap: true
  check_apt: true
  detect_desktop: true
```

### Output Example
```
🔍 PRE-FLIGHT CHECKS | Step 1/7 - Checking disk space...
✅ PRE-FLIGHT CHECKS | Disk space check passed
   Available disk space: 45.2GB (required: 10GB)
```

---

## 🏁 Feature Flags

**File:** `roles/workstation/defaults/main.yml`

Control entire feature sets:

```yaml
features:
  install_snap_apps: true          # Enable/disable all snap apps
  install_deb_apps: true           # Enable/disable all DEB apps
  install_complex_apps: true       # Enable/disable complex apps
  configure_system: true           # Enable/disable system configs
  configure_power: true            # Enable/disable power management
  configure_touchpad: true         # Enable/disable touchpad settings
  configure_ntfs: true             # Enable/disable NTFS support
  configure_nautilus: true         # Enable/disable Nautilus config
  run_preflight_checks: true       # Enable/disable pre-flight checks
  run_post_verification: true      # Enable/disable post-install verification
  generate_manifest: true          # Enable/disable manifest generation
  create_backups: false            # Enable/disable backups (planned)
```

---

## 🏷️ Tags Reference

### Category Tags

| Tag | Description | What It Installs |
|-----|-------------|------------------|
| `snap` | All snap applications | Vivaldi, Bitwarden, Notepad++, Notion, Mailspring, Claude Code, ChatGPT, iCloud |
| `deb` | All DEB applications | Discord, Zoom, Termius, OnlyOffice |
| `docker` | Docker and containers | Docker CE, Portainer, n8n |
| `applications` | All applications | Everything above |
| `complex` | Complex apps only | Docker, Portainer, Twingate, ProtonVPN, Ulauncher, n8n |
| `simple` | Simple apps only | All snap + DEB apps |
| `system` | System configurations | Nautilus, power, touchpad, NTFS, GRUB |
| `preflight` | Pre-flight checks only | Validation before installation |
| `always` | Always runs | Pre-flight, initialization, summary |

### Individual App Tags

| Tag | Application |
|-----|-------------|
| `vivaldi` | Vivaldi browser |
| `discord` | Discord |
| `docker` | Docker CE |
| `portainer` | Portainer |
| `twingate` | Twingate |
| `nautilus` | Nautilus configuration |
| `power` | Power management |
| `touchpad` | Touchpad settings |

### Usage Examples

```bash
# Install only snap applications
ansible-playbook setup.yml --tags "snap"

# Install snap + DEB apps
ansible-playbook setup.yml --tags "snap,deb"

# Install everything except Docker
ansible-playbook setup.yml --skip-tags "docker"

# Install specific apps
ansible-playbook setup.yml --tags "vivaldi,discord,portainer"

# System configuration only
ansible-playbook setup.yml --tags "system"
```

---

## 🔘 Enable/Disable Reference

### Individual Snap Apps

**File:** `roles/workstation/defaults/main.yml`
**Location:** Lines 66-95

```yaml
snap_apps:
  - name: vivaldi
    enabled: true  # Set to false to disable
```

### Individual DEB Apps

**File:** `roles/workstation/defaults/main.yml`
**Location:** Lines 98-133

```yaml
deb_apps:
  - name: discord
    enabled: true  # Set to false to disable
```

### Complex Apps

**File:** `roles/workstation/defaults/main.yml`
**Location:** Lines 142-149

```yaml
# Repository-based applications
install_docker: true          # Set to false to disable
install_protonvpn: false
install_ulauncher: true
install_twingate: false

# Docker container applications
install_portainer: true       # Set to false to disable
install_n8n: false
```

### System Configurations

**File:** `roles/workstation/defaults/main.yml`

```yaml
nautilus:
  enabled: true               # Set to false to disable

power_management:
  enabled: true               # Set to false to disable

touchpad_settings:
  enabled: true               # Set to false to disable

ntfs_support:
  enabled: true               # Set to false to disable

razer_grub:
  enabled: false              # Set to true to enable (Razer hardware only)
```

---

## 📊 Summary Statistics

| Category | Total | Implemented | Planned | Default Enabled |
|----------|-------|-------------|---------|-----------------|
| **Snap Apps** | 8 | 8 | 0 | 7 |
| **DEB Apps** | 4 | 4 | 0 | 3 |
| **Complex Apps** | 6 | 6 | 0 | 3 |
| **System Configs** | 5 | 3 | 2 | 3 |
| **TOTAL** | **23** | **21** | **2** | **16** |

---

## 🎯 Quick Reference

### What's Enabled by Default?

**Applications (13):**
- ✅ Vivaldi, Bitwarden, Notepad++, Notion, Mailspring
- ✅ Claude Code, ChatGPT Desktop Client
- ✅ Discord, Zoom, OnlyOffice
- ✅ Docker CE, Portainer, Ulauncher

**System Configs (3):**
- ✅ Nautilus sort order
- ✅ Power management
- ✅ Touchpad settings

### What's Disabled by Default?

**Applications (5):**
- ❌ iCloud for Linux (experimental)
- ❌ Termius
- ❌ Twingate
- ❌ ProtonVPN
- ❌ n8n

**System Configs (2):**
- ❌ NTFS/exFAT support
- ❌ Razer GRUB settings (hardware-specific)

### What's Planned for Phase 2?

**System Configs (2):**
- NTFS/exFAT support
- Razer GRUB settings

---

## 📞 Support

For questions about specific applications or configurations:

- **Main documentation:** `README.md`
- **Quick start:** `QUICKSTART.md`
- **Variables:** `roles/workstation/defaults/main.yml`
- **Change tracking:** `CHANGES_TRACKING.csv`

---

**Last Updated:** 2026-01-07
**Version:** 1.0.0
**Total Apps & Configs:** 23 items (21 implemented, 2 planned)
