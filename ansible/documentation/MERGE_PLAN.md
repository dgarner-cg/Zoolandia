# Merge Plan: ansible_production → ./ansible

**Date:** 2026-01-07
**Goal:** Merge production-ready workstation role into existing ./ansible structure

---

## 📋 Comparison Analysis

### Applications in Both Versions

| Application | Old Location | New Location | Status |
|-------------|--------------|--------------|--------|
| Vivaldi | setup.yml:20-37 | defaults (snap_apps) | ✅ Migrated (loop-based) |
| Discord | setup.yml:39-83 | defaults (deb_apps) | ✅ Migrated (loop-based) |
| Notepad++ | setup.yml:85-103 | defaults (snap_apps) | ✅ Migrated (loop-based) |
| Notion | setup.yml:105-123 | defaults (snap_apps) | ✅ Migrated (loop-based) |
| Bitwarden | setup.yml:125-142 | defaults (snap_apps) | ✅ Migrated (loop-based) |
| Mailspring | setup.yml:185-202 | defaults (snap_apps) | ✅ Migrated (loop-based) |
| Termius | setup.yml:204-238 | defaults (deb_apps) | ✅ Migrated (loop-based) |
| Zoom | setup.yml:240-281 | defaults (deb_apps) | ✅ Migrated (loop-based) |
| OnlyOffice | setup.yml:283-316 | defaults (deb_apps) | ✅ Migrated (loop-based) |
| Twingate | setup.yml:318-341 | complex/twingate.yml | ✅ Migrated (SECURITY FIX) |
| iCloud | setup.yml:343-361 | defaults (snap_apps) | ✅ Migrated (loop-based) |
| Docker | setup.yml:425-508 | complex/docker.yml | ✅ Migrated |
| Portainer | setup.yml:510-545 | complex/portainer.yml | ✅ Migrated |

### Applications in Old Only (NEED TO ADD)

| Application | Old Location | Type | Priority | Action Required |
|-------------|--------------|------|----------|-----------------|
| ProtonVPN | setup.yml:144-183 | Complex (PPA) | HIGH | Create complex/protonvpn.yml |
| Ulauncher | setup.yml:363-423 | Complex (PPA) | HIGH | Create complex/ulauncher.yml |
| n8n | setup.yml:547-589 | Complex (Docker) | MEDIUM | Create complex/n8n.yml |

### System Configurations in Old Only (NEED TO ADD)

| Configuration | Old Location | Type | Priority | Action Required |
|---------------|--------------|------|----------|-----------------|
| Power Management | setup.yml:591-613 | System | HIGH | Create system/power_management.yml |
| Touchpad Settings | setup.yml:619-653 | System | HIGH | Create system/touchpad_settings.yml |

### New Features in ansible_production

| Feature | Location | Status |
|---------|----------|--------|
| Claude Code | defaults (snap_apps) | ✅ New addition |
| ChatGPT Desktop | defaults (snap_apps) | ✅ New addition |
| Nautilus Sort | system/nautilus_sort.yml | ✅ New addition |
| Pre-flight Checks | preflight/checks.yml | ✅ New feature |
| Comprehensive Logging | Throughout | ✅ New feature |
| Loop-based Architecture | simple/apps.yml | ✅ New pattern |

---

## 🔧 Configuration Files

### ansible.cfg Merge

**Old ./ansible/ansible.cfg:**
```ini
[defaults]
inventory = ./inventories/production/hosts
roles_path = ./roles
host_key_checking = False

[ssh_connection]
pipelining = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = True
```

**New ansible_production/ansible.cfg:**
```ini
[defaults]
inventory = ./inventories/production/localhost.yml
host_key_checking = False
interpreter_python = auto_silent
roles_path = ./roles
stdout_callback = yaml
bin_ansible_callbacks = True
display_skipped_hosts = False
display_ok_hosts = True
forks = 5
gathering = smart
fact_caching = memory
fact_caching_timeout = 86400
retry_files_enabled = False
force_color = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = True

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

**Merge Strategy:** Combine both - keep all settings from new, preserve inventory path from old

---

## 📁 Directory Structure After Merge

```
./ansible/
├── ansible.cfg                           # MERGED (both configs combined)
├── site.yml                              # KEEP existing
├── webservers.yml                        # KEEP existing
├── dbservers.yml                         # KEEP existing
├── README.md                             # ADD from ansible_production
├── QUICKSTART.md                         # ADD from ansible_production
├── CHANGELOG.md                          # ADD from ansible_production
├── APPS.md                               # ADD from ansible_production
├── CHANGES_TRACKING.csv                  # ADD from ansible_production
├── CONVERSATION_STATUS.json              # ADD from ansible_production
├── inventories/
│   ├── production/
│   │   ├── hosts                         # KEEP existing
│   │   ├── localhost.yml                 # ADD from ansible_production
│   │   ├── group_vars/                   # KEEP existing
│   │   └── host_vars/                    # KEEP existing
│   └── staging/                          # KEEP existing
└── roles/
    ├── workstation/                      # NEW - from ansible_production
    │   ├── defaults/
    │   │   └── main.yml                  # Smart defaults, auto-detection
    │   ├── handlers/
    │   │   └── main.yml                  # Service handlers
    │   ├── tasks/
    │   │   ├── main.yml                  # 5-phase orchestrator
    │   │   ├── preflight/
    │   │   │   └── checks.yml            # 7-step validation
    │   │   ├── system/
    │   │   │   ├── nautilus_sort.yml     # ✅ Implemented
    │   │   │   ├── power_management.yml  # ⚠️ TO ADD
    │   │   │   └── touchpad_settings.yml # ⚠️ TO ADD
    │   │   └── applications/
    │   │       ├── simple/
    │   │       │   └── apps.yml          # Loop-based installer
    │   │       └── complex/
    │   │           ├── docker.yml        # ✅ Implemented
    │   │           ├── twingate.yml      # ✅ Implemented
    │   │           ├── portainer.yml     # ✅ Implemented
    │   │           ├── protonvpn.yml     # ⚠️ TO ADD
    │   │           ├── ulauncher.yml     # ⚠️ TO ADD
    │   │           └── n8n.yml           # ⚠️ TO ADD
    │   ├── templates/                    # Empty for now
    │   ├── files/                        # Empty for now
    │   └── vars/                         # Empty for now
    ├── common/                           # KEEP for backward compatibility
    │   └── [existing structure]          # DEPRECATED but functional
    ├── webtier/                          # KEEP existing
    └── dbserver/                         # KEEP existing
```

---

## ✅ Merge Execution Plan

### Phase 1: Preparation
1. ✅ Create MERGE_PLAN.md (this file)
2. ⚠️ Create missing complex app files (ProtonVPN, Ulauncher, n8n)
3. ⚠️ Create missing system config files (Power Management, Touchpad)
4. ⚠️ Update defaults/main.yml to include new apps
5. ⚠️ Update tasks/main.yml to include new system configs

### Phase 2: File Migration
6. ⚠️ Copy workstation role to ./ansible/roles/workstation/
7. ⚠️ Merge ansible.cfg files
8. ⚠️ Copy documentation files to ./ansible/ root
9. ⚠️ Create setup-workstation.yml playbook in ./ansible/

### Phase 3: Interactive Menu
10. ⚠️ Create menu system script (Bash + dialog)
11. ⚠️ Add "Install All" option
12. ⚠️ Add checkbox selection for individual apps
13. ⚠️ Generate YAML config from user selections
14. ⚠️ Integrate menu into Zoolandia (if applicable)

### Phase 4: Testing & Validation
15. ⚠️ Test standalone CLI execution
16. ⚠️ Test with Zoolandia platform
17. ⚠️ Validate all tags work correctly
18. ⚠️ Verify documentation accuracy

---

## 🚨 Critical Issues to Fix

### Issue 1: Hardcoded Username
**Old:** Hardcoded "dgarner" in multiple places (line 488, 557, etc.)
**Fix:** ✅ Already fixed in new role with `workstation_user` variable

### Issue 2: Twingate curl|bash Vulnerability
**Old:** `curl -s URL | sudo bash` (line 327)
**Fix:** ✅ Already fixed in complex/twingate.yml with download-verify-execute

### Issue 3: Excessive ignore_errors
**Old:** ignore_errors: true everywhere
**Fix:** ✅ Already fixed with block/rescue/always pattern

### Issue 4: No Modularity
**Old:** 659-line monolithic setup.yml
**Fix:** ✅ Already fixed with modular structure

---

## 📊 Code Reduction Statistics

| Metric | Old | New | Improvement |
|--------|-----|-----|-------------|
| Setup Playbook | 659 lines | 100 lines (loop-based) | 85% reduction |
| Individual App Files | 16 files × ~50 lines | Loop (8 snap + 4 deb) | 87% reduction |
| Complex Apps | Inline | Modular files | Maintainable |
| Error Handling | ignore_errors everywhere | block/rescue/always | Professional |
| Hardcoded Values | "dgarner" hardcoded | Smart variables | Flexible |
| Security Vulnerabilities | 1 (Twingate) | 0 | Fixed |

---

## 🔄 Variable Mapping

| Old Variable/Value | New Variable | Notes |
|-------------------|--------------|-------|
| Hardcoded "dgarner" | `workstation_user` | Auto-detects or accepts from env |
| Hardcoded "/home/dgarner" | `workstation_home` | Auto-detects based on user |
| Hardcoded paths | `docker_dir`, `backup_dir` | Configurable with smart defaults |
| N/A | `CURRENT_USER` env | Zoolandia integration |
| N/A | `DOCKER_DIR` env | Zoolandia integration |

---

## 🎯 Next Steps

1. Create missing complex app files (ProtonVPN, Ulauncher, n8n)
2. Create missing system config files (Power Management, Touchpad)
3. Execute file migration
4. Create interactive menu system
5. Test and validate

---

**Status:** Ready to begin Phase 1
**Estimated Completion:** All phases within current session
