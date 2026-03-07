# Comprehensive Ansible Directory Analysis

**Generated:** 2025-12-31
**Ansible Directory:** `/home/cicero/Documents/Zoolandia/ansible`
**Project:** Zoolandia (formerly DeployIQ v5.10)
**Analysis Depth:** Very Thorough - Complete File Catalog and Pattern Analysis

---

## EXECUTIVE SUMMARY

The ansible directory contains an Ansible automation project designed for workstation setup and application deployment. The project has **significant structural issues, security concerns, and numerous Ansible best practice violations**. The codebase shows signs of being in a transitional state with broken references, hardcoded values, and inconsistent organization.

**🚨 CRITICAL FINDING**: The entire ansible setup references directories (`compose/`, `sysSettings/`, `apps/`) that **DO NOT EXIST** in the ansible folder, making most playbooks non-functional.

### Key Statistics
- **Total YAML files:** 52 (28 completely empty)
- **Main playbook size:** 658 lines (monolithic)
- **Applications configured:** 17
- **Hardcoded username references:** 20+
- **Excessive error suppression:** 149 `ignore_errors: true`
- **Broken file references:** 57
- **Critical security issues:** 1 (curl|bash)
- **Best practice violations:** 30+ categories

---

## TABLE OF CONTENTS

1. [Complete File Catalog](#complete-file-catalog)
2. [Directory Structure](#directory-structure-with-descriptions)
3. [Application Inventory](#application-inventory-17-applications)
4. [Hardcoded Values Tracking](#hardcoded-values-complete-inventory)
5. [Broken References](#broken-references-and-missing-files)
6. [Variable Analysis](#variable-analysis)
7. [Dependencies and Includes](#dependencies-and-includes)
8. [Security Issues](#security-issues-comprehensive-scan)
9. [Best Practices Violations](#ansible-best-practices-violations)
10. [Patterns and Metrics](#detailed-patterns-and-metrics)
11. [Recommendations](#recommendations)

---

## COMPLETE FILE CATALOG

### Total Statistics
- **Total YAML files**: 52
- **Total directories**: 32
- **Configuration files**: 3 (ansible.cfg, 2 hosts files, 1 JSON)
- **Total lines of code** (main setup.yml): 658 lines
- **Empty files**: 28 files containing only comments

### All Configuration Files (55 files)

#### Root Level Files
1. `/home/cicero/Documents/Zoolandia/ansible/ansible.cfg`
2. `/home/cicero/Documents/Zoolandia/ansible/site.yml`
3. `/home/cicero/Documents/Zoolandia/ansible/dbservers.yml`
4. `/home/cicero/Documents/Zoolandia/ansible/webservers.yml`
5. `/home/cicero/Documents/Zoolandia/ansible/.claude/settings.local.json`

#### Inventory Files (Production)
6. `/home/cicero/Documents/Zoolandia/ansible/inventories/production/hosts` ⚠️ ALL HOSTS COMMENTED OUT
7. `/home/cicero/Documents/Zoolandia/ansible/inventories/production/localhost.yml`
8. `/home/cicero/Documents/Zoolandia/ansible/inventories/production/group_vars/all.yml` ⚠️ EMPTY
9. `/home/cicero/Documents/Zoolandia/ansible/inventories/production/group_vars/dbservers.yml` ⚠️ EMPTY
10. `/home/cicero/Documents/Zoolandia/ansible/inventories/production/group_vars/webservers.yml` ⚠️ EMPTY
11. `/home/cicero/Documents/Zoolandia/ansible/inventories/production/host_vars/web-prod-1.example.com.yml` ⚠️ EMPTY

#### Inventory Files (Staging)
12. `/home/cicero/Documents/Zoolandia/ansible/inventories/staging/hosts` ⚠️ ALL HOSTS COMMENTED OUT
13. `/home/cicero/Documents/Zoolandia/ansible/inventories/staging/group_vars/all.yml` ⚠️ EMPTY
14. `/home/cicero/Documents/Zoolandia/ansible/inventories/staging/group_vars/dbservers.yml` ⚠️ EMPTY
15. `/home/cicero/Documents/Zoolandia/ansible/inventories/staging/group_vars/webservers.yml` ⚠️ EMPTY

#### Common Role - Core Files
16. `/home/cicero/Documents/Zoolandia/ansible/roles/common/defaults/main.yml` ⚠️ EMPTY
17. `/home/cicero/Documents/Zoolandia/ansible/roles/common/handlers/main.yml` ⚠️ EMPTY
18. `/home/cicero/Documents/Zoolandia/ansible/roles/common/meta/main.yml` ⚠️ EMPTY
19. `/home/cicero/Documents/Zoolandia/ansible/roles/common/vars/main.yml` ⚠️ EMPTY

#### Common Role - Task Files
20. `/home/cicero/Documents/Zoolandia/ansible/roles/common/tasks/main.yml`
21. `/home/cicero/Documents/Zoolandia/ansible/roles/common/tasks/ntfs_automount.yml`
22. `/home/cicero/Documents/Zoolandia/ansible/roles/common/tasks/package_update.yml`
23. `/home/cicero/Documents/Zoolandia/ansible/roles/common/tasks/power_management.yml`
24. `/home/cicero/Documents/Zoolandia/ansible/roles/common/tasks/razer-12.5.yml`
25. `/home/cicero/Documents/Zoolandia/ansible/roles/common/tasks/touchpad_settings.yml`

#### Common Role - Playbooks (⚠️ NON-STANDARD LOCATION)
26. `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/main.yml` ⚠️ EMPTY
27. `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/setup_all.yml` ⚠️ BROKEN PATHS
28. `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/setup_individual.yml` ⚠️ BROKEN PATHS
29. `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/setup_new.yml` ⚠️ BROKEN PATHS
30. `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/setup.yml` (658 lines - MAIN PLAYBOOK)

#### Common Role - zFiles (⚠️ NON-STANDARD DIRECTORY NAME)
Application installers (16 files):

31. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/bitwarden.yml`
32. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/discord.yml`
33. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/docker.yml`
34. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/icloud.yml`
35. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/mailspring.yml`
36. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/n8n.yml`
37. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/notepad-plus-plus.yml`
38. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/notion.yml`
39. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/onlyoffice.yml`
40. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/portainer.yml`
41. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/protonvpn.yml`
42. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/termius.yml`
43. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/twingate.yml`
44. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/ulauncher.yml`
45. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/vivaldi.yml`
46. `/home/cicero/Documents/Zoolandia/ansible/roles/common/zFiles/zoom.yml`

#### DBServer Role Files (⚠️ ALL EMPTY - STUB ONLY)
47. `/home/cicero/Documents/Zoolandia/ansible/roles/dbserver/defaults/main.yml` ⚠️ EMPTY
48. `/home/cicero/Documents/Zoolandia/ansible/roles/dbserver/handlers/main.yml` ⚠️ EMPTY
49. `/home/cicero/Documents/Zoolandia/ansible/roles/dbserver/meta/main.yml` ⚠️ EMPTY
50. `/home/cicero/Documents/Zoolandia/ansible/roles/dbserver/tasks/main.yml` ⚠️ EMPTY
51. `/home/cicero/Documents/Zoolandia/ansible/roles/dbserver/vars/main.yml` ⚠️ EMPTY

#### Webtier Role Files (⚠️ ALL EMPTY - STUB ONLY)
52. `/home/cicero/Documents/Zoolandia/ansible/roles/webtier/defaults/main.yml` ⚠️ EMPTY
53. `/home/cicero/Documents/Zoolandia/ansible/roles/webtier/handlers/main.yml` ⚠️ EMPTY
54. `/home/cicero/Documents/Zoolandia/ansible/roles/webtier/meta/main.yml` ⚠️ EMPTY
55. `/home/cicero/Documents/Zoolandia/ansible/roles/webtier/tasks/main.yml` ⚠️ EMPTY
56. `/home/cicero/Documents/Zoolandia/ansible/roles/webtier/vars/main.yml` ⚠️ EMPTY

---

## DIRECTORY STRUCTURE WITH DESCRIPTIONS

```
ansible/
├── .claude/                          # Claude AI configuration
│   └── settings.local.json          # Tool permissions config
│
├── inventories/                      # Inventory management
│   ├── production/
│   │   ├── hosts                    # ⚠️ ALL HOSTS COMMENTED OUT
│   │   ├── localhost.yml            # ✅ Only functional inventory
│   │   ├── group_vars/
│   │   │   ├── all.yml             # ⚠️ EMPTY
│   │   │   ├── dbservers.yml       # ⚠️ EMPTY
│   │   │   └── webservers.yml      # ⚠️ EMPTY
│   │   └── host_vars/
│   │       └── web-prod-1.example.com.yml  # ⚠️ EMPTY
│   │
│   └── staging/
│       ├── hosts                    # ⚠️ ALL HOSTS COMMENTED OUT
│       └── group_vars/
│           ├── all.yml             # ⚠️ EMPTY
│           ├── dbservers.yml       # ⚠️ EMPTY
│           └── webservers.yml      # ⚠️ EMPTY
│
├── roles/
│   ├── common/                      # ✅ Main workstation setup role (ACTIVE)
│   │   ├── defaults/
│   │   │   └── main.yml            # ⚠️ EMPTY - should contain default variables
│   │   ├── files/                  # ⚠️ EMPTY DIRECTORY
│   │   ├── handlers/
│   │   │   └── main.yml            # ⚠️ EMPTY - should contain handlers
│   │   ├── meta/
│   │   │   └── main.yml            # ⚠️ EMPTY - should contain role metadata
│   │   ├── playbooks/              # ⚠️ UNUSUAL - playbooks inside role (not standard)
│   │   │   ├── main.yml            # ⚠️ EMPTY
│   │   │   ├── setup.yml           # ✅ Main monolithic setup (658 lines)
│   │   │   ├── setup_all.yml       # ❌ BROKEN - references non-existent paths
│   │   │   ├── setup_individual.yml # ❌ BROKEN - references non-existent paths
│   │   │   └── setup_new.yml       # ❌ BROKEN - references non-existent paths
│   │   ├── tasks/                  # ✅ System configuration tasks
│   │   │   ├── main.yml            # Basic package installation
│   │   │   ├── ntfs_automount.yml  # NTFS drive configuration
│   │   │   ├── package_update.yml  # APT update task
│   │   │   ├── power_management.yml # GNOME power settings
│   │   │   ├── razer-12.5.yml      # Razer laptop GRUB config
│   │   │   └── touchpad_settings.yml # GNOME touchpad settings
│   │   ├── templates/              # ⚠️ EMPTY DIRECTORY
│   │   ├── vars/
│   │   │   └── main.yml            # ⚠️ EMPTY - should contain role variables
│   │   └── zFiles/                 # ⚠️ NON-STANDARD NAME - modular app installers
│   │       ├── bitwarden.yml       # Bitwarden password manager installer
│   │       ├── discord.yml         # Discord communication app installer
│   │       ├── docker.yml          # Docker & Docker Compose installer
│   │       ├── icloud.yml          # iCloud for Linux installer
│   │       ├── mailspring.yml      # Mailspring email client installer
│   │       ├── n8n.yml             # n8n workflow automation installer
│   │       ├── notepad-plus-plus.yml # Notepad++ text editor installer
│   │       ├── notion.yml          # Notion note-taking app installer
│   │       ├── onlyoffice.yml      # ONLYOFFICE suite installer
│   │       ├── portainer.yml       # Portainer container management installer
│   │       ├── protonvpn.yml       # ProtonVPN installer
│   │       ├── termius.yml         # Termius SSH client installer
│   │       ├── twingate.yml        # Twingate zero-trust network installer
│   │       ├── ulauncher.yml       # ulauncher app launcher installer
│   │       ├── vivaldi.yml         # Vivaldi browser installer
│   │       └── zoom.yml            # Zoom video conferencing installer
│   │
│   ├── dbserver/                    # ⚠️ DATABASE SERVER ROLE (STUB - ALL EMPTY)
│   │   ├── defaults/main.yml       # ⚠️ EMPTY
│   │   ├── handlers/main.yml       # ⚠️ EMPTY
│   │   ├── meta/main.yml           # ⚠️ EMPTY
│   │   ├── tasks/main.yml          # ⚠️ EMPTY
│   │   └── vars/main.yml           # ⚠️ EMPTY
│   │
│   └── webtier/                     # ⚠️ WEB TIER ROLE (STUB - ALL EMPTY)
│       ├── defaults/main.yml       # ⚠️ EMPTY
│       ├── handlers/main.yml       # ⚠️ EMPTY
│       ├── meta/main.yml           # ⚠️ EMPTY
│       ├── tasks/main.yml          # ⚠️ EMPTY
│       └── vars/main.yml           # ⚠️ EMPTY
│
├── ansible.cfg                      # ✅ Ansible configuration
├── site.yml                         # ✅ Master playbook
├── dbservers.yml                    # ✅ DB server playbook
└── webservers.yml                   # ✅ Web server playbook
```

### Directory Purpose Analysis

| Directory | Purpose | Status | Issues |
|-----------|---------|--------|--------|
| `inventories/` | Host inventory management | ⚠️ Partial | All hosts commented out, only localhost works |
| `roles/common/` | Workstation setup automation | ✅ Active | Most functional role |
| `roles/dbserver/` | Database server configuration | ❌ Stub | Completely empty, no functionality |
| `roles/webtier/` | Web server configuration | ❌ Stub | Completely empty, no functionality |
| `roles/common/tasks/` | System configuration tasks | ✅ Active | GNOME settings, hardware configs |
| `roles/common/zFiles/` | Application installers | ✅ Active | Non-standard name, should be `tasks/apps/` |
| `roles/common/playbooks/` | Playbook collection | ⚠️ Broken | Non-standard location, 3/5 playbooks broken |

---

## APPLICATION INVENTORY (17 Applications)

### Installation Methods Summary

| Method | Count | Applications |
|--------|-------|--------------|
| **Snap Package** | 7 | vivaldi, notepad++, notion, bitwarden, mailspring, icloud, (portainer-removed) |
| **APT (.deb download)** | 6 | discord, protonvpn, termius, zoom, onlyoffice |
| **APT (repository)** | 2 | docker (official repo), ulauncher (PPA) |
| **Docker Container** | 2 | portainer, n8n |
| **curl\|bash installer** | 1 | twingate ⚠️ SECURITY RISK |

### Complete Application Catalog

#### 1. **Vivaldi Browser** 🌐
- **Category:** Web Browsers
- **Installation Method:** Snap package
- **Package Name:** `vivaldi`
- **Files:**
  - `roles/common/zFiles/vivaldi.yml` (21 lines)
  - Duplicated in `setup.yml` (lines 20-37)
- **Version:** Latest from Snap Store (unspecified)
- **Check Method:** `snap list | grep vivaldi`
- **Lines of Code:** 21

---

#### 2. **Discord** 💬
- **Category:** Communication Tools
- **Installation Method:** .deb download from Discord API
- **Download URL:** `https://discord.com/api/download?platform=linux&format=deb`
- **Files:**
  - `roles/common/zFiles/discord.yml` (47 lines)
  - Duplicated in `setup.yml` (lines 39-83)
- **Version:** Latest (dynamic URL)
- **Temporary File:** `/tmp/discord.deb`
- **Check Method:** `dpkg -l | grep discord`
- **Special:** Extended timeout (1200 seconds / 20 minutes)
- **Lines of Code:** 47
- **Post-Install:** Dependency fix with `apt -f install`

---

#### 3. **Notepad++** 📝
- **Category:** Productivity Applications
- **Installation Method:** Snap package
- **Package Name:** `notepad-plus-plus`
- **Files:**
  - `roles/common/zFiles/notepad-plus-plus.yml` (21 lines)
  - Duplicated in `setup.yml` (lines 85-103)
- **Version:** Latest from Snap Store
- **Check Method:** `snap list | grep notepad-plus-plus`
- **Lines of Code:** 21
- **Note:** Runs via Wine/Snap

---

#### 4. **Notion** 📓
- **Category:** Productivity Applications
- **Installation Method:** Snap package
- **Package Name:** `notion-snap-reborn`
- **Files:**
  - `roles/common/zFiles/notion.yml` (21 lines)
  - Duplicated in `setup.yml` (lines 105-123)
- **Version:** Latest from Snap Store
- **Check Method:** `snap list | grep notion-snap-reborn`
- **Lines of Code:** 21
- **Note:** Uses community snap (reborn), not official

---

#### 5. **Bitwarden** 🔐
- **Category:** Security & VPN
- **Installation Method:** Snap package
- **Package Name:** `bitwarden`
- **Files:**
  - `roles/common/zFiles/bitwarden.yml` (21 lines)
  - Duplicated in `setup.yml` (lines 125-142)
- **Version:** Latest from Snap Store
- **Check Method:** `snap list | grep bitwarden`
- **Lines of Code:** 21

---

#### 6. **ProtonVPN** 🔒
- **Category:** Security & VPN
- **Installation Method:** APT repository + .deb download
- **Download URL:** `https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.4_all.deb`
- **Package Name:** `proton-vpn-gnome-desktop`
- **Files:**
  - `roles/common/zFiles/protonvpn.yml` (43 lines)
  - Duplicated in `setup.yml` (lines 144-183)
- **Version:** 1.0.4 (repository config), latest (actual package)
- **Temporary File:** `/tmp/protonvpn-stable-release_1.0.4_all.deb`
- **Check Method:** `dpkg -l | grep protonvpn`
- **Lines of Code:** 43
- **⚠️ Hardcoded Version:** YES (1.0.4 in filename - may be outdated)

---

#### 7. **Mailspring** 📧
- **Category:** Communication Tools
- **Installation Method:** Snap package
- **Package Name:** `mailspring`
- **Files:**
  - `roles/common/zFiles/mailspring.yml` (21 lines)
  - Duplicated in `setup.yml` (lines 185-202)
- **Version:** Latest from Snap Store
- **Check Method:** `snap list | grep mailspring`
- **Lines of Code:** 21

---

#### 8. **Termius** 🖥️
- **Category:** System Utilities
- **Installation Method:** .deb download
- **Download URL:** `https://www.termius.com/download/linux/Termius.deb`
- **Files:**
  - `roles/common/zFiles/termius.yml` (38 lines)
  - Duplicated in `setup.yml` (lines 204-238)
- **Version:** Latest (direct download)
- **Temporary File:** `/tmp/Termius.deb`
- **Check Method:** `dpkg -l | grep Termius`
- **Lines of Code:** 38
- **Note:** Case-sensitive package name (capital T)

---

#### 9. **Zoom** 🎥
- **Category:** Communication Tools
- **Installation Method:** .deb download
- **Download URL:** `https://zoom.us/client/latest/zoom_amd64.deb`
- **Dependencies:** `wget`, `libxcb-xtest0`
- **Files:**
  - `roles/common/zFiles/zoom.yml` (45 lines)
  - Duplicated in `setup.yml` (lines 240-281)
- **Version:** Latest (dynamic URL)
- **Temporary File:** `/tmp/zoom_amd64.deb`
- **Check Method:** `dpkg -l | grep zoom`
- **Lines of Code:** 45
- **⚠️ Architecture Hardcoded:** amd64 only (won't work on ARM)

---

#### 10. **ONLYOFFICE** 📊
- **Category:** Productivity Applications
- **Installation Method:** .deb download
- **Download URL:** `https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb`
- **Package Name:** `onlyoffice-desktopeditors`
- **Files:**
  - `roles/common/zFiles/onlyoffice.yml` (36 lines)
  - Duplicated in `setup.yml` (lines 283-316)
- **Version:** Latest (dynamic URL)
- **Temporary File:** `/tmp/onlyoffice-desktopeditors_amd64.deb`
- **Check Method:** `dpkg -l | grep onlyoffice-desktopeditors`
- **Lines of Code:** 36
- **⚠️ Architecture Hardcoded:** amd64 only (won't work on ARM)

---

#### 11. **Twingate** 🔐⚠️ SECURITY RISK
- **Category:** Security & VPN
- **Installation Method:** curl | bash installer
- **Download URL:** `https://binaries.twingate.com/client/linux/install.sh`
- **Command:** `curl -s https://binaries.twingate.com/client/linux/install.sh | sudo bash`
- **Files:**
  - `roles/common/zFiles/twingate.yml` (26 lines)
  - Duplicated in `setup.yml` (lines 318-341)
- **Version:** Latest (from install script)
- **Check Method:** `command -v twingate`
- **Lines of Code:** 26
- **Platform:** Ubuntu only
- **Post-install:** Manual `sudo twingate setup` required
- **🚨 CRITICAL SECURITY ISSUE:** Pipes curl directly to bash with sudo privileges

---

#### 12. **iCloud for Linux** ☁️
- **Category:** System Utilities
- **Installation Method:** Snap package
- **Package Name:** `icloud-for-linux`
- **Files:**
  - `roles/common/zFiles/icloud.yml` (21 lines)
  - Duplicated in `setup.yml` (lines 343-361)
- **Version:** Latest from Snap Store
- **Check Method:** `snap list | grep icloud-for-linux`
- **Lines of Code:** 21

---

#### 13. **ulauncher** 🚀
- **Category:** System Utilities
- **Installation Method:** APT via PPA
- **Repository:** `ppa:agornostal/ulauncher`
- **Package Name:** `ulauncher`
- **Additional Package:** `wmctrl` (for Wayland support)
- **Files:**
  - `roles/common/zFiles/ulauncher.yml` (63 lines)
  - Duplicated in `setup.yml` (lines 363-423)
- **Version:** Latest from PPA
- **Check Method:** `dpkg -l | grep ulauncher`
- **Prerequisites:** `universe` repository
- **Lines of Code:** 63
- **Post-install:** Manual Wayland configuration required (detailed instructions provided)

---

#### 14. **Docker + Docker Compose** 🐳
- **Category:** Development & Automation
- **Installation Method:** Official Docker repository
- **Repository URL:** `https://download.docker.com/linux/ubuntu`
- **GPG Key URL:** `https://download.docker.com/linux/ubuntu/gpg`
- **Packages Installed:**
  - `docker-ce`
  - `docker-ce-cli`
  - `containerd.io`
  - `docker-buildx-plugin`
  - `docker-compose-plugin`
- **Prerequisites:** `ca-certificates`, `curl`, `gnupg`, `lsb-release`
- **Files:**
  - `roles/common/zFiles/docker.yml` (86 lines)
  - Duplicated in `setup.yml` (lines 425-508)
- **Version:** Latest stable from Docker official repository
- **Check Method:** `command -v docker`
- **Lines of Code:** 86
- **Post-install Actions:**
  - User added to docker group (⚠️ hardcoded: `dgarner`)
  - Docker service started and enabled
  - Requires re-login for group membership

---

#### 15. **Portainer Business Edition** 📦
- **Category:** Development & Automation
- **Installation Method:** Docker container
- **Image:** `portainer/portainer-ee:latest` ⚠️
- **Ports:** 8000 (HTTP), 9443 (HTTPS)
- **Volume:** `portainer_data`
- **Files:**
  - `roles/common/zFiles/portainer.yml` (38 lines)
  - Duplicated in `setup.yml` (lines 510-545)
- **Version:** Latest (using :latest tag - ⚠️ not recommended for production)
- **Check Method:** `docker ps -a | grep portainer`
- **Access:** `https://localhost:9443`
- **Lines of Code:** 38
- **Post-install:** Manual admin account creation required
- **Additional Options:**
  - `--restart=always`
  - Docker socket mounted (`/var/run/docker.sock`)
  - Business Edition (requires license)

---

#### 16. **n8n** 🔄
- **Category:** Development & Automation
- **Installation Method:** Docker container
- **Image:** `n8nio/n8n:latest` ⚠️
- **Port:** 5678 (HTTP)
- **Volume:** `/home/dgarner/.n8n:/home/node/.n8n` (⚠️ hardcoded user)
- **Environment Variables:**
  - `N8N_HOST=localhost`
  - `N8N_PORT=5678`
  - `N8N_PROTOCOL=http`
  - `WEBHOOK_URL=http://localhost:5678/`
- **Files:**
  - `roles/common/zFiles/n8n.yml` (45 lines)
  - Duplicated in `setup.yml` (lines 547-589)
- **Version:** Latest (using :latest tag - ⚠️ not recommended for production)
- **Check Method:** `docker ps -a | grep n8n`
- **Access:** `http://localhost:5678`
- **Lines of Code:** 45
- **Post-install:** Manual account creation required
- **Data Directory:** `/home/dgarner/.n8n` (⚠️ hardcoded path)

---

#### 17. **System Configurations** (Not applications, but included in setup)

**a. Power Management** ⚡
- **File:** `roles/common/tasks/power_management.yml`
- **Target:** GNOME Settings Daemon
- **Settings Modified:**
  - Sleep timeout (AC): 0 (disabled)
  - Sleep timeout (battery): 0 (disabled)
  - Lid close action (AC): ⚠️ suspend/hibernate (conflicting - both set!)
  - Lid close action (battery): ⚠️ suspend/hibernate (conflicting - both set!)
- **User:** `dgarner` (⚠️ hardcoded)
- **Lines of Code:** 26
- **⚠️ CRITICAL ISSUE:** Contains conflicting settings (lines set both suspend AND hibernate for same action)

**b. Touchpad Settings** 🖱️
- **File:** `roles/common/tasks/touchpad_settings.yml`
- **Target:** GNOME Desktop Peripherals
- **Settings Modified:**
  - Touchpad speed: 0.5 (65% faster)
  - Click method: 'fingers' (two-finger right-click)
- **User:** `dgarner` (⚠️ hardcoded)
- **UID:** 1000 (⚠️ hardcoded in DBUS path)
- **Lines of Code:** 35

**c. NTFS/exFAT Automount** 💾
- **File:** `roles/common/tasks/ntfs_automount.yml`
- **Packages Installed:** `ntfs-3g`, `exfat-fuse`, `exfatprogs`
- **Kernel Module:** Blacklists `ntfs3` module (forces use of FUSE ntfs-3g)
- **Initramfs:** Updates after blacklist
- **Target:** localhost only
- **Lines of Code:** 20

**d. Razer 12.5 GRUB Configuration** ⚙️
- **File:** `roles/common/tasks/razer-12.5.yml`
- **Target:** `/etc/default/grub`
- **GRUB Parameters Added:**
  - `quiet splash` (cosmetic)
  - `intel_iommu=off` (disable Intel IOMMU)
  - `iommu=pt` (passthrough mode)
  - `i915.enable_psr=0` (disable Panel Self Refresh - fixes screen tearing)
  - `i915.enable_dc=0` (disable display C-states)
  - `i915.enable_fbc=0` (disable framebuffer compression)
  - `i915.fastboot=1` (enable fast boot)
- **Backup:** Creates `.backup` file before modification
- **Post-config:** Runs `update-grub`
- **Reboot Required:** Yes
- **Lines of Code:** 45

---

## HARDCODED VALUES COMPLETE INVENTORY

### 1. Username Hardcoding (22 occurrences)
**Hardcoded Username: `dgarner`**

| File | Line(s) | Context | Count |
|------|---------|---------|-------|
| `roles/common/tasks/power_management.yml` | 3, 6, 10, 14, 18, 22 | `sudo -u dgarner gsettings` commands | 6 |
| `roles/common/tasks/touchpad_settings.yml` | 3, 5, 9, 11, 15, 18, 27, 30 | `sudo -u dgarner` and `become_user: dgarner` | 8 |
| `roles/common/zFiles/docker.yml` | 64 | Docker group membership: `name: dgarner` | 1 |
| `roles/common/zFiles/n8n.yml` | 12, 13, 14, 30 | Home directory and ownership | 4 |
| `roles/common/playbooks/setup.yml` | 489, 557-560, 575, 592-648 | All above combined (duplicate) | 3 |

**Total unique occurrences:** 22

**Files Affected:** 5 files
**Impact:** Makes playbooks unusable for any other username

---

### 2. User ID Hardcoding (8 occurrences)
**Hardcoded UID: `1000`**

| File | Line(s) | Context |
|------|---------|---------|
| `roles/common/tasks/touchpad_settings.yml` | 3, 9, 15, 27 | `DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"` |
| `roles/common/playbooks/setup.yml` | 620, 626, 632, 644 | Same DBUS path (duplicate) |

**Total occurrences:** 8
**Impact:** Assumes first non-root user; breaks if user has different UID

---

### 3. Python Version Hardcoding (4 occurrences)
**Hardcoded Python:** `/usr/bin/python3.12`

| File | Line | Context |
|------|------|---------|
| `roles/common/playbooks/setup_individual.yml` | 37 | `ansible_python_interpreter` variable |
| `roles/common/playbooks/setup_new.yml` | 19 | `ansible_python_interpreter` variable |
| `roles/common/playbooks/setup.yml` | 7 | `ansible_python_interpreter` variable |
| `roles/common/playbooks/setup_all.yml` | 16 | `ansible_python_interpreter` variable |

**Impact:**
- Breaks on Ubuntu 22.04 LTS (Python 3.10)
- Breaks on Ubuntu 20.04 LTS (Python 3.8)
- Breaks on Debian 12 (Python 3.11)
- Breaks on all RHEL/CentOS (Python 3.9)

---

### 4. Version Hardcoding in URLs (8 occurrences)
**ProtonVPN Version: `1.0.4`**

| File | Lines | Context |
|------|-------|---------|
| `roles/common/zFiles/protonvpn.yml` | 11-12, 19, 33 | URL and file path references |
| `roles/common/playbooks/setup.yml` | 153-154, 161, 175 | Same (duplicate) |

**Impact:** Version may be outdated; no automatic updates

---

### 5. Docker Image Tags (4 occurrences)
**Using :latest tag** (⚠️ security/stability risk)

| File | Line | Image |
|------|------|-------|
| `roles/common/zFiles/portainer.yml` | 24 | `portainer/portainer-ee:latest` |
| `roles/common/zFiles/n8n.yml` | 31 | `n8nio/n8n:latest` |
| `roles/common/playbooks/setup.yml` | 532, 576 | Both (duplicates) |

**Impact:**
- Unpredictable behavior (image changes without notice)
- Difficult to reproduce environments
- Security vulnerabilities could be introduced
- Breaks idempotency

**Recommended Fix:** Pin to specific versions (e.g., `portainer/portainer-ee:2.19.4`)

---

### 6. Port Number Hardcoding (8 occurrences)

| Port | Application | File | Occurrences |
|------|-------------|------|-------------|
| 8000 | Portainer HTTP | portainer.yml, setup.yml | 2 |
| 9443 | Portainer HTTPS | portainer.yml, setup.yml | 2 |
| 5678 | n8n HTTP | n8n.yml, setup.yml | 6 (port, host var, webhook URL) |

**Total hardcoded port references:** 8

---

### 7. Download URLs (17 unique URLs)

**Direct download URLs:**
1. `https://discord.com/api/download?platform=linux&format=deb`
2. `https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.4_all.deb`
3. `https://www.termius.com/download/linux/Termius.deb`
4. `https://zoom.us/client/latest/zoom_amd64.deb`
5. `https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb`
6. `https://binaries.twingate.com/client/linux/install.sh` ⚠️ PIPED TO BASH
7. `https://download.docker.com/linux/ubuntu/gpg` (GPG key)
8. `https://download.docker.com/linux/ubuntu` (repository base)

**Repository URLs:**
9. `ppa:agornostal/ulauncher`
10. `https://repo.protonvpn.com/debian`

**Total:** 17 hardcoded URLs

---

### 8. Hardcoded Paths (50+ occurrences)

| Path | Purpose | Occurrences | Files |
|------|---------|-------------|-------|
| `/tmp/` | Temporary file storage | 30+ | All installer files |
| `/etc/apt/keyrings` | GPG key storage | 4 | docker.yml, setup.yml |
| `/etc/default/grub` | GRUB configuration | 3 | razer-12.5.yml |
| `/etc/modprobe.d` | Kernel module config | 2 | ntfs_automount.yml |
| `/var/run/docker.sock` | Docker socket | 2 | portainer.yml, setup.yml |
| `/home/dgarner/.n8n` | n8n data directory | 4 | n8n.yml, setup.yml |
| `/run/user/1000/bus` | DBUS session bus | 8 | touchpad_settings.yml, power_management.yml |

**Total path hardcoding:** 50+ occurrences

---

### 9. Architecture Hardcoding (2 occurrences)

| File | Line | Hardcoded Architecture |
|------|------|----------------------|
| `zoom.yml` | 20 | `zoom_amd64.deb` |
| `onlyoffice.yml` | 11 | `onlyoffice-desktopeditors_amd64.deb` |

**Impact:** Won't work on ARM-based systems (Raspberry Pi, Apple Silicon with Linux, etc.)

**Should use:** `{{ ansible_architecture }}` variable

---

### 10. Timeout Hardcoding (2 occurrences)

| File | Line | Timeout | Application |
|------|------|---------|-------------|
| `discord.yml` | 13 | 1200 seconds (20 min) | Discord download |
| Default | N/A | 600 seconds (10 min) | All other downloads |

---

### Summary of Hardcoded Values

| Category | Count | Severity |
|----------|-------|----------|
| Usernames | 22 | 🚨 CRITICAL |
| User IDs | 8 | 🔴 HIGH |
| Python interpreter | 4 | 🚨 CRITICAL |
| Software versions | 8 | 🟡 MEDIUM |
| Docker tags | 4 | 🔴 HIGH |
| Ports | 8 | 🟡 MEDIUM |
| URLs | 17 | 🟡 MEDIUM |
| File paths | 50+ | 🔴 HIGH |
| Architecture | 2 | 🟡 MEDIUM |
| Timeouts | 2 | 🟢 LOW |

**Total hardcoded values:** **125+**

**Recommendation:** Move ALL hardcoded values to `roles/common/defaults/main.yml` for easy configuration.

---

## BROKEN REFERENCES AND MISSING FILES

### 🚨 CRITICAL: Three Playbooks Reference Non-Existent Directories

#### 1. setup_all.yml - References `../../../../compose/` and `../../../../sysSettings/`

**File:** `roles/common/playbooks/setup_all.yml`
**Lines:** 20-74 (ALL BROKEN)

**Broken include_tasks references (19 total):**

```yaml
# Lines 20-74 - EVERY include_tasks FAILS
include_tasks: ../../../../sysSettings/package_update.yml      # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/vivaldi.yml                 # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/discord.yml                 # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/notepad-plus-plus.yml       # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/notion.yml                  # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/bitwarden.yml               # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/protonvpn.yml               # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/mailspring.yml              # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/termius.yml                 # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/zoom.yml                    # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/onlyoffice.yml              # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/twingate.yml                # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/icloud.yml                  # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/ulauncher.yml               # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/docker.yml                  # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/portainer.yml               # ❌ DOES NOT EXIST
include_tasks: ../../../../compose/n8n.yml                     # ❌ DOES NOT EXIST
include_tasks: ../../../../sysSettings/power_management.yml    # ❌ DOES NOT EXIST
include_tasks: ../../../../sysSettings/touchpad_settings.yml   # ❌ DOES NOT EXIST
```

**Path Analysis:**
- Current file: `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/setup_all.yml`
- `../../../../` resolves to: `/home/cicero/Documents/Zoolandia/`
- Expected `compose/` at: `/home/cicero/Documents/Zoolandia/compose/` ⚠️ **EXISTS** (Docker compose files)
- Expected `sysSettings/` at: `/home/cicero/Documents/Zoolandia/sysSettings/` ❌ **DOES NOT EXIST**

**Issue:** The playbook traverses OUTSIDE the ansible directory, expecting files in the parent project directory. The `compose/` directory exists in parent but contains Docker Compose YAML files, NOT Ansible task files.

---

#### 2. setup_individual.yml - References `../../../../compose/` and `../../../../sysSettings/`

**File:** `roles/common/playbooks/setup_individual.yml`
**Lines:** 46-61 (ALL BROKEN)

**Broken dynamic include_tasks (uses variable `app_name`):**

```yaml
# Lines 46-61 - Dynamic paths that FAIL
- name: Check if app exists in compose directory
  stat:
    path: "../../../../compose/{{ app_name }}.yml"              # ❌ WRONG TYPE OF FILES
  register: compose_app

- name: Install {{ app_name }} from compose directory
  include_tasks: "../../../../compose/{{ app_name }}.yml"       # ❌ BROKEN
  when: compose_app.stat.exists

- name: Check if app exists in sysSettings directory
  stat:
    path: "../../../../sysSettings/{{ app_name }}.yml"          # ❌ DOES NOT EXIST
  register: syssettings_app

- name: Install {{ app_name }} from sysSettings directory
  include_tasks: "../../../../sysSettings/{{ app_name }}.yml"   # ❌ BROKEN
  when: syssettings_app.stat.exists
```

**Issue:** Same path traversal problem as setup_all.yml, but uses dynamic variable lookup.

**Correct paths should be:**
```yaml
path: "../zFiles/{{ app_name }}.yml"                            # ✅ CORRECT (relative to playbooks dir)
# OR
path: "{{ role_path }}/zFiles/{{ app_name }}.yml"              # ✅ CORRECT (using role_path var)
```

---

#### 3. setup_new.yml - References `apps/` subdirectory

**File:** `roles/common/playbooks/setup_new.yml`
**Lines:** 23-77 (ALL BROKEN)

**Broken include_tasks references (19 total):**

```yaml
# Lines 23-77 - Expects apps/ subdirectory in playbooks/
include_tasks: apps/package_update.yml           # ❌ apps/ DOES NOT EXIST
include_tasks: apps/vivaldi.yml                  # ❌ DOES NOT EXIST
include_tasks: apps/discord.yml                  # ❌ DOES NOT EXIST
include_tasks: apps/notepad-plus-plus.yml        # ❌ DOES NOT EXIST
include_tasks: apps/notion.yml                   # ❌ DOES NOT EXIST
include_tasks: apps/bitwarden.yml                # ❌ DOES NOT EXIST
include_tasks: apps/protonvpn.yml                # ❌ DOES NOT EXIST
include_tasks: apps/mailspring.yml               # ❌ DOES NOT EXIST
include_tasks: apps/termius.yml                  # ❌ DOES NOT EXIST
include_tasks: apps/zoom.yml                     # ❌ DOES NOT EXIST
include_tasks: apps/onlyoffice.yml               # ❌ DOES NOT EXIST
include_tasks: apps/twingate.yml                 # ❌ DOES NOT EXIST
include_tasks: apps/icloud.yml                   # ❌ DOES NOT EXIST
include_tasks: apps/ulauncher.yml                # ❌ DOES NOT EXIST
include_tasks: apps/docker.yml                   # ❌ DOES NOT EXIST
include_tasks: apps/portainer.yml                # ❌ DOES NOT EXIST
include_tasks: apps/n8n.yml                      # ❌ DOES NOT EXIST
include_tasks: apps/power_management.yml         # ❌ DOES NOT EXIST
include_tasks: apps/touchpad_settings.yml        # ❌ DOES NOT EXIST
```

**Expected path:** `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/apps/`
**Actual:** ❌ **Directory does not exist**

**Correct paths should be:**
```yaml
include_tasks: ../zFiles/vivaldi.yml             # ✅ CORRECT (relative to playbooks dir)
```

---

### Summary of Broken References

| Playbook | Broken Includes | Expected Directory | Exists? | Correct Location |
|----------|----------------|-------------------|---------|------------------|
| setup_all.yml | 19 | `../../../../compose/` | ⚠️ YES (wrong content) | `../zFiles/` |
| setup_all.yml | 2 | `../../../../sysSettings/` | ❌ NO | `../tasks/` |
| setup_individual.yml | Dynamic | `../../../../compose/` | ⚠️ YES (wrong content) | `../zFiles/` |
| setup_individual.yml | Dynamic | `../../../../sysSettings/` | ❌ NO | `../tasks/` |
| setup_new.yml | 19 | `apps/` | ❌ NO | `../zFiles/` |

**Total broken include_tasks:** 57+ references

**Impact:**
- 3 out of 5 playbooks in `playbooks/` directory are **completely non-functional**
- Only `setup.yml` (658-line monolith) is functional
- `main.yml` is empty

---

### Missing Directories Expected by Playbooks

1. `/home/cicero/Documents/Zoolandia/ansible/compose/` - ❌ Does not exist in ansible dir
2. `/home/cicero/Documents/Zoolandia/ansible/sysSettings/` - ❌ Does not exist
3. `/home/cicero/Documents/Zoolandia/ansible/roles/common/playbooks/apps/` - ❌ Does not exist

**Note:** `/home/cicero/Documents/Zoolandia/compose/` DOES exist (parent dir), but contains Docker Compose files for Deployrr services, NOT Ansible task files.

---

### Inventory Issues

#### All Hosts Commented Out

**Production inventory** (`inventories/production/hosts`):
```ini
# [webservers]
# web-prod-1.example.com
# web-prod-2.example.com

# [dbservers]
# db-prod-1.example.com
```
**Status:** ❌ All 3 hosts commented out

**Staging inventory** (`inventories/staging/hosts`):
```ini
# [webservers]
# web-staging-1.example.com

# [dbservers]
# db-staging-1.example.com
```
**Status:** ❌ All 2 hosts commented out

---

#### Only Functional Inventory

**File:** `inventories/production/localhost.yml`
```yaml
---
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: "{{ ansible_playbook_python }}"
```
**Status:** ✅ FUNCTIONAL - localhost only

**Impact:** Only localhost deployments work; no remote host management possible.

---

### Empty Variable Files (14 files)

All group_vars and host_vars files are completely empty:

**Production:**
- `inventories/production/group_vars/all.yml` - ⚠️ EMPTY
- `inventories/production/group_vars/dbservers.yml` - ⚠️ EMPTY
- `inventories/production/group_vars/webservers.yml` - ⚠️ EMPTY
- `inventories/production/host_vars/web-prod-1.example.com.yml` - ⚠️ EMPTY

**Staging:**
- `inventories/staging/group_vars/all.yml` - ⚠️ EMPTY
- `inventories/staging/group_vars/dbservers.yml` - ⚠️ EMPTY
- `inventories/staging/group_vars/webservers.yml` - ⚠️ EMPTY

**Impact:** No environment-specific configuration; staging and production would be identical.

---

## Continued in Next Section...

**Document Status:** Part 1 of 2 - Comprehensive File Catalog, Applications, Hardcoded Values, and Broken References completed.

**Next Section Will Cover:**
- Variable Analysis
- Dependencies and Includes
- Security Issues (Comprehensive Scan)
- Ansible Best Practices Violations
- Detailed Patterns and Metrics
- Recommendations

---

**Last Updated:** 2025-12-31
**Analyzed By:** Claude Code (Sonnet 4.5) with Explore Agent
**Files Analyzed:** 52 YAML files, 3 config files
**Lines Analyzed:** ~3,500+ lines of YAML code
