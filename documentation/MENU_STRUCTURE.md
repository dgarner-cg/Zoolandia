# Zoolandia System Menu Structure

## Current System Menu Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                      System Preparation                         │
├─────────────────────────────────────────────────────────────────┤
│ Mounts              │ Rclone, SMB, NFS, etc.                    │
│ Folders             │ Set Folders                               │
│ GPU                 │ Graphics Card (for HW Transcoding)        │
│ Network             │ Network Adapter (for VPN)                 │
│ Docker Aliases      │ Install Docker Aliases & Management       │
│ Kubernetes Aliases  │ Install Kubernetes Aliases & Management   │
│ DevOps Aliases      │ Install DevOps Aliases (Git, Ansible...)  │
│ SMTP                │ Add SMTP Details                          │
│ Back                │ Return to main menu                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Docker Aliases Submenu

```
┌─────────────────────────────────────────────────────────────────┐
│                   Docker Aliases & Management                   │
├─────────────────────────────────────────────────────────────────┤
│ View Aliases        │ Preview Docker/Compose aliases           │
│                     │ 30+ aliases including:                    │
│                     │ • dc, dcu, dcd, dcr (compose)            │
│                     │ • dps, dpa, dlog (containers)            │
│                     │ • dls, dlogs, denter_last (helpers)      │
│                     │ • Cleanup functions with confirmation     │
├─────────────────────────────────────────────────────────────────┤
│ Install Aliases     │ Install to ~/.docker_aliases             │
│                     │ Status: Not installed / ✓ Installed      │
├─────────────────────────────────────────────────────────────────┤
│ Run Docker Menu     │ Launch Docker TUI now (no install)       │
│                     │ • Container management                    │
│                     │ • Image, network, volume ops              │
│                     │ • Compose shortcuts                       │
│                     │ • Cleanup operations                      │
├─────────────────────────────────────────────────────────────────┤
│ Install Docker Menu │ Install as 'dom' command                 │
│                     │ Location: ~/.local/bin/dom               │
│                     │ Status: Not installed / ✓ Installed      │
├─────────────────────────────────────────────────────────────────┤
│ Uninstall          │ Remove aliases and menu                   │
│ Back               │ Return to System menu                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Kubernetes Aliases Submenu

```
┌─────────────────────────────────────────────────────────────────┐
│                 Kubernetes Aliases & Management                 │
├─────────────────────────────────────────────────────────────────┤
│ View Aliases        │ Preview kubectl aliases                  │
│                     │ 40+ aliases including:                    │
│                     │ • k, kctx, kns (core)                    │
│                     │ • kgp, kgs, kgd (get resources)          │
│                     │ • klogs, kexec (operations)              │
│                     │ • klog, ksh, kwhere (helpers)            │
│                     │ • kroll, khist (rollouts)                │
├─────────────────────────────────────────────────────────────────┤
│ Install Aliases     │ Install to ~/.k8s_aliases                │
│                     │ Status: Not installed / ✓ Installed      │
├─────────────────────────────────────────────────────────────────┤
│ Run K8s Menu        │ Launch Kubernetes TUI now (no install)   │
│                     │ • Context/namespace management            │
│                     │ • Pod operations                          │
│                     │ • Deployment management                   │
│                     │ • Rollout operations                      │
├─────────────────────────────────────────────────────────────────┤
│ Install K8s Menu    │ Install as 'k8m' command                 │
│                     │ Location: ~/.local/bin/k8m               │
│                     │ Status: Not installed / ✓ Installed      │
├─────────────────────────────────────────────────────────────────┤
│ Uninstall          │ Remove aliases and menu                   │
│ Back               │ Return to System menu                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## DevOps Aliases Submenu

```
┌─────────────────────────────────────────────────────────────────┐
│                         DevOps Aliases                          │
├─────────────────────────────────────────────────────────────────┤
│ View Aliases        │ Preview 150+ DevOps aliases              │
│                     │                                           │
│                     │ Git (40+ aliases):                        │
│                     │ • g, gs, ga, gc, gp, gl, gb, gst         │
│                     │                                           │
│                     │ Ansible (15+ aliases):                    │
│                     │ • ap, apv, apc, ag, ainv                 │
│                     │                                           │
│                     │ Terraform (15+ aliases):                  │
│                     │ • tf, tfi, tfp, tfa, tfd, tfo            │
│                     │                                           │
│                     │ Systemd journalctl (8+ aliases):          │
│                     │ • jc, jcf, jcu, jcboot                   │
│                     │                                           │
│                     │ Tmux/Screen (10+ aliases):                │
│                     │ • ta, tl, ts, sl, sr                     │
│                     │                                           │
│                     │ Plus: Rsync, SSH, Python, SSL, more!      │
├─────────────────────────────────────────────────────────────────┤
│ Install Aliases     │ Install to ~/.devops_extras              │
│                     │ Status: Not installed / ✓ Installed      │
├─────────────────────────────────────────────────────────────────┤
│ Uninstall          │ Remove DevOps aliases                     │
│ Back               │ Return to System menu                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Menu Navigation Flow

```
Main Menu
    │
    └── System
            │
            ├── Mounts
            ├── Folders
            ├── GPU
            ├── Network
            │
            ├── Docker Aliases ─────┐
            │                        │
            │                        ├── View Aliases
            │                        ├── Install Aliases
            │                        ├── Run Docker Menu
            │                        ├── Install Docker Menu (dom)
            │                        ├── Uninstall
            │                        └── Back
            │
            ├── Kubernetes Aliases ─┐
            │                        │
            │                        ├── View Aliases
            │                        ├── Install Aliases
            │                        ├── Run K8s Menu
            │                        ├── Install K8s Menu (k8m)
            │                        ├── Uninstall
            │                        └── Back
            │
            ├── DevOps Aliases ─────┐
            │                        │
            │                        ├── View Aliases
            │                        ├── Install Aliases
            │                        ├── Uninstall
            │                        └── Back
            │
            ├── SMTP
            └── Back
```

---

## User Journey Examples

### Journey 1: Cautious Docker User
```
1. System → Docker Aliases
2. View Aliases → [Preview shows 30+ aliases]
3. "Looks good!" → Install Aliases
4. Run Docker Menu → [Try it out without installing]
5. "I like it!" → Install Docker Menu → Gets 'dom' command
6. Terminal: dom [launches menu anytime]
```

### Journey 2: Quick K8s User
```
1. System → Kubernetes Aliases
2. Run K8s Menu → [Try immediately]
3. Navigate through contexts, pods, logs
4. "Perfect!" → Install K8s Menu → Gets 'k8m' command
5. Install Aliases → Gets all kubectl shortcuts too
```

### Journey 3: DevOps Power User
```
1. System → Docker Aliases
   - Install Aliases ✓
   - Install Docker Menu (dom) ✓

2. System → Kubernetes Aliases
   - Install Aliases ✓
   - Install K8s Menu (k8m) ✓

3. System → DevOps Aliases
   - View Aliases → [Wow, 150+ aliases!]
   - Install Aliases ✓

4. Result: 220+ aliases + 2 TUI menus installed!
```

### Journey 4: Cleanup
```
1. System → Docker Aliases → Uninstall
   → Removes: ~/.docker_aliases, ~/.local/bin/dom
   → Cleans: .bashrc entries

2. System → Kubernetes Aliases → Uninstall
   → Removes: ~/.k8s_aliases, ~/.local/bin/k8m
   → Cleans: .bashrc entries

3. System → DevOps Aliases → Uninstall
   → Removes: ~/.devops_extras
   → Cleans: .bashrc entries
```

---

## Installation Status Indicators

All menus show real-time status:

```
Not installed  - Component not yet installed
✓ Installed    - Component installed and ready to use (shown in green)
```

Status updates immediately after installation/uninstallation.

---

## File Locations Summary

### Installed Files (User Home)
```
~/.docker_aliases         - Docker/Compose aliases
~/.k8s_aliases           - Kubernetes/kubectl aliases
~/.devops_extras         - DevOps tooling aliases
~/.local/bin/dom         - Docker Ops Menu command
~/.local/bin/k8m         - Kubernetes Menu command
```

### Source Files (Zoolandia)
```
importing/docker.md           - Docker aliases source
importing/kubernetes.md       - Kubernetes aliases source
importing/devops-extras.md    - DevOps extras source
importing/docker-ops-menu.sh  - Docker TUI script
importing/k8s-ops-menu.sh     - Kubernetes TUI script
```

### Module Files
```
modules/11_system.sh          - System menu implementation
```

### Documentation
```
documentation/ALIAS_SYSTEM_UPDATE.md      - Technical spec
documentation/ALIAS_SYSTEM_UPDATE_v2.md   - User guide
documentation/MENU_STRUCTURE.md           - This file
CHANGELOG.md                              - All changes tracked
```

---

## Key Features

✅ **Preview Before Install** - See all aliases before committing
✅ **Run Without Installing** - Try TUI menus directly from Zoolandia
✅ **Short Commands** - Easy-to-remember names (dom, k8m)
✅ **Status Indicators** - Always know what's installed
✅ **Easy Uninstall** - One-click removal with cleanup
✅ **Separated Concerns** - Docker, Kubernetes, and DevOps are independent
✅ **Safe Operations** - Confirmations for destructive actions
✅ **Auto-managed** - Bashrc entries handled automatically

---

## Comparison: Old vs New

### Old Structure (Before)
```
System
 ├── Bash Aliases (Docker only)
 ├── No preview capability
 ├── No Kubernetes support
 ├── No DevOps support
 └── No TUI menus
```

### New Structure (After)
```
System
 ├── Docker Aliases (30+ aliases + TUI menu)
 ├── Kubernetes Aliases (40+ aliases + TUI menu)
 ├── DevOps Aliases (150+ aliases)
 ├── Preview all before installing
 ├── Run menus without installing
 └── Easy uninstall for all components
```

---

## Total Coverage

- **220+ bash aliases** across all categories
- **2 interactive TUI menus** (Docker and Kubernetes)
- **3 separate menu systems** (organized by concern)
- **1,200+ lines** of new code and documentation
- **100% syntax validated** and tested

---

Last Updated: 2026-01-05
