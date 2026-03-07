# Action Plan: Ansible Menu Restructure & Enhancement

## Date: January 13, 2026
## Status: PENDING REVIEW

---

## 📋 Executive Summary

This action plan outlines comprehensive changes to the Ansible menu structure including:
1. New "System Config" submenu for configuration files
2. New "CX" (Customer Experience) submenu for custom applications
3. Top-level "Install All" option showing ALL available packages
4. Audit of existing menu entries

---

## 🔍 Current State Analysis

### Existing Roles
```
ansible/roles/
├── common/         - Base system tools (26+ packages)
├── dbserver/       - Database servers (10 packages)
├── hashicorp/      - HashiCorp stack (8 tools)
├── webtier/        - Web servers (9 packages)
└── workstation/    - Desktop apps + system config
```

### Existing Workstation Configuration Files
```
roles/workstation/tasks/system/
├── nautilus_sort.yml        - File manager configuration
├── power_management.yml     - Power settings
└── touchpad_settings.yml    - Touchpad configuration
```

### Existing Workstation Applications (21 items)
**Snap Apps:**
- vivaldi, bitwarden, notepad-plus-plus, notion, mailspring
- icloud (disabled by default), claude-code, chatgpt, discord
- zoom, termius

**Deb Apps:**
- onlyoffice

**Complex Apps (require configuration):**
- docker, portainer, twingate, protonvpn, ulauncher, n8n

**System Configs:**
- power, touchpad, nautilus

### Missing/Incomplete Items
- ❌ **GovDeals**: No files found (mentioned but doesn't exist)
- ❌ **CX Role**: Does not exist yet
- ⚠️ **NTFS Support**: Mentioned in workstation manifest but no task file

---

## 🎯 Proposed Changes

### 1. Create "System Config" Submenu

**Purpose**: Centralize all system configuration options

**Location**: New submenu under Ansible Automation

**Contents**:
```
System Config
├── [x] Install All System Configs
├── [ ] Touchpad Settings
├── [ ] Power Management
├── [ ] Nautilus Configuration
├── [ ] NTFS Support (NEW - needs implementation)
└── Back
```

**Implementation**:
- Create `show_system_config_menu()` function
- Link to existing task files in `roles/workstation/tasks/system/`
- Create new playbook: `playbooks/system_config.yml`
- Implement missing NTFS support task

---

### 2. Create "CX" (Customer Experience) Submenu

**Purpose**: Custom applications and configurations for specific use cases

**Location**: New submenu under Ansible Automation → Advanced Options

**Contents**:
```
CX (Customer Experience)
├── [x] Install All CX Apps
├── [ ] GovDeals Scraper/Tool (NEW - needs implementation)
└── Back
```

**Questions for Clarification**:
1. **GovDeals**: What is this application?
   - Is it a web scraper?
   - Is it a Docker container?
   - Does it need a specific configuration?
   - Where are the source files?

2. **CX Definition**: What else belongs in "CX"?
   - Customer-specific tools?
   - Business applications?
   - Industry-specific software?

**Implementation Steps**:
1. Create new role: `ansible/roles/cx/`
2. Create `show_cx_menu()` function
3. Create playbook: `playbooks/cx.yml`
4. Implement GovDeals installation (pending clarification)

---

### 3. Top-Level "Install All" Option

**Purpose**: Single option to install EVERYTHING across all roles

**Implementation**:
```bash
show_install_all_comprehensive() {
    # Display comprehensive list of ALL packages across ALL roles

    dialog --title "Install ALL Zoolandia Packages" \
        --yesno "This will install ALL packages from:

COMMON (26+ packages):
  - Essential tools: git, curl, wget, tmux, tree, jq, fzf, etc.
  - Network tools: openssh, net-tools, dnsutils
  - Monitoring: htop, gotop, glances, iotop, netdata
  - Security: ufw, fail2ban, auditd
  - Build tools: build-essential
  - Time sync: chrony
  - Go runtime
  - HashiCorp Vault

DATABASE SERVERS (10 packages):
  - PostgreSQL, MySQL/MariaDB, Redis, MongoDB
  - Admin tools: pgBackRest

WEB SERVERS (9 packages):
  - nginx, apache2
  - SSL/TLS: certbot, acme.sh
  - PHP-FPM with modules
  - Caching: redis, memcached
  - HAProxy

WORKSTATIONS (21+ apps):
  - Browsers: Vivaldi
  - Security: Bitwarden
  - Productivity: Notion, OnlyOffice, Mailspring
  - Development: Claude Code, ChatGPT, Docker, Portainer
  - Network: Twingate, ProtonVPN
  - Automation: n8n, Ulauncher

HASHICORP STACK (8 tools):
  - Boundary, Consul, Nomad, Packer
  - Terraform, Vault, Vault Radar, Waypoint

SYSTEM CONFIG (4 items):
  - Touchpad, Power Management, Nautilus, NTFS

CX (1+ apps):
  - GovDeals

TOTAL: 75+ packages/configurations

This will take 30-60 minutes depending on your system.

Continue?" 40 80
}
```

**Execution Order**:
1. Common (base system)
2. HashiCorp Stack
3. Database Servers
4. Web Servers
5. Workstations
6. System Config
7. CX

---

### 4. Audit Existing Menu Entries

#### ✅ Working Entries (Verified)
- **Common**: Has 26+ packages, fully implemented
- **Database Servers**: Has 10 packages, fully implemented with password management
- **Web Servers**: Has 9 packages, fully implemented
- **HashiCorp Stack**: Has 8 tools, fully implemented
- **Workstations**: Has 21 apps, mostly implemented

#### ⚠️ Entries Needing Attention

**Workstation Role**:
- ✅ touchpad → Links to `system/touchpad_settings.yml` (exists)
- ✅ power → Links to `system/power_management.yml` (exists)
- ✅ nautilus → Links to `system/nautilus_sort.yml` (exists)
- ❌ NTFS support → Mentioned in manifest but no task file
- ❌ GovDeals → Not found anywhere

**Tags Menu**:
- ⚠️ **Implementation**: UI exists but execution is placeholder
- **Status**: "Implementation pending playbook creation"
- **Action**: Needs full tag integration with Ansible

---

## 📁 New Files to Create

### Directory Structure
```
ansible/
├── playbooks/
│   ├── system_config.yml     (NEW)
│   ├── cx.yml                (NEW)
│   └── install_all.yml       (NEW)
├── roles/
│   ├── cx/                   (NEW ROLE)
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   ├── defaults/
│   │   │   └── main.yml
│   │   └── handlers/
│   │       └── main.yml
│   └── workstation/
│       └── tasks/
│           └── system/
│               └── ntfs_support.yml  (NEW)
```

### Module Changes
```
modules/41_ansible.sh
├── show_system_config_menu()        (NEW function)
├── show_cx_menu()                   (NEW function)
├── show_install_all_comprehensive() (NEW function)
└── show_ansible_menu()              (UPDATE - add new menu items)
```

---

## 🗂️ Updated Ansible Menu Structure

```
Ansible Automation
├── Install All ..................... Install EVERYTHING (75+ packages)
├── Common .......................... Base system tools + Vault + Go
├── Workstations .................... Desktop applications
├── Database Servers ................ PostgreSQL, MySQL, Redis, MongoDB
├── Web Servers ..................... Nginx, Apache, SSL, PHP, caching
├── System Config ................... Touchpad, Power, Nautilus, NTFS (NEW)
│
├─ ───── Advanced Options ─────
├── HashiCorp Stack ................. 8 tools (Boundary, Consul, etc.)
├── CX (Customer Experience) ........ GovDeals, custom apps (NEW)
└── Install by Tags ................. Category/Environment/Priority tags
```

---

## ⚠️ Questions Requiring User Input

### Critical Questions

1. **GovDeals Application**:
   - What is GovDeals? (web scraper, API client, Docker app?)
   - Where are the source files or installation instructions?
   - What dependencies does it require?
   - Should it be a snap, deb, docker, or from source?

2. **CX Scope**:
   - What other applications belong in "CX"?
   - Is CX for customer-specific tools or general business apps?
   - Should we anticipate more CX apps in the future?

3. **NTFS Support**:
   - Should we implement NTFS support configuration?
   - What specific NTFS functionality is needed? (mount, read/write, auto-mount?)

4. **Install All Behavior**:
   - Should "Install All" prompt for database passwords?
   - Should it skip failed packages or abort on first failure?
   - Should it generate a detailed report at the end?

---

## 🚀 Implementation Plan

### Phase 1: Foundation (1-2 hours)
1. ✅ Audit existing roles and files
2. ✅ Create action plan document
3. ⏳ Get user approval and clarification
4. ⏳ Create changelog and stdout.log files

### Phase 2: System Config Menu (30 minutes)
1. Create `show_system_config_menu()` function
2. Create `playbooks/system_config.yml`
3. Implement NTFS support task (if approved)
4. Update main Ansible menu

### Phase 3: CX Menu (30-60 minutes, pending GovDeals clarification)
1. Create `cx` role directory structure
2. Implement GovDeals installation (pending details)
3. Create `show_cx_menu()` function
4. Create `playbooks/cx.yml`
5. Update main Ansible menu

### Phase 4: Install All (30 minutes)
1. Create `show_install_all_comprehensive()` function
2. Create `playbooks/install_all.yml` that includes all other playbooks
3. Add comprehensive package list display
4. Implement progress tracking
5. Generate final installation report

### Phase 5: Testing & Documentation (30 minutes)
1. Syntax check all new playbooks
2. Test each menu individually
3. Test "Install All" in check mode
4. Update documentation
5. Create user guide

---

## 📊 Risk Assessment

### Low Risk
- Creating System Config menu (uses existing files)
- Creating menu structure changes
- Adding "Install All" option

### Medium Risk
- Creating CX role (depends on GovDeals requirements)
- NTFS support implementation (depends on requirements)

### High Risk
- None identified at this time

---

## 🔄 Rollback Plan

If issues arise:
1. All changes are in `modules/41_ansible.sh` - can revert file
2. New playbooks can be deleted without affecting existing ones
3. New roles can be removed without affecting existing roles
4. Git commit before changes allows easy rollback

---

## 📝 Success Criteria

✅ System Config menu functional with all existing config files
✅ CX menu created and GovDeals installable
✅ "Install All" displays comprehensive list and works correctly
✅ All existing functionality remains intact
✅ All playbooks pass syntax validation
✅ Documentation updated
✅ Changelog created
✅ Conversation log captured

---

## 🤝 Required User Decisions

Before proceeding, please review and provide:

1. **Approval** of overall structure and approach
2. **GovDeals details**: What it is and how to install it
3. **CX scope**: What else should go in CX menu?
4. **NTFS support**: Should we implement it? What functionality?
5. **Install All**: Any special requirements or concerns?

---

## 📅 Timeline

**Estimated Total Time**: 3-4 hours
**Can Start**: After user approval
**Completion**: Same day (if GovDeals details provided)

---

## ✍️ Approval

- [ ] User has reviewed this action plan
- [ ] User has provided answers to critical questions
- [ ] User approves proceeding with implementation
- [ ] Changelog and stdout.log requirements confirmed

---

**Next Steps**: Awaiting user review and approval to proceed.
