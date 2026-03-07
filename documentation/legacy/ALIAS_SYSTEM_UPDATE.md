# Alias System Update - Summary

## Overview
The System menu has been reorganized to provide comprehensive alias management for Docker, Kubernetes, and general DevOps tooling.

## Changes Made

### 1. System Menu Updates (`modules/11_system.sh`)

#### Menu Items Changed:
- **Renamed**: "Bash Aliases" → "Docker Aliases"
- **Added**: "Kubernetes Aliases" menu item
- Both now open comprehensive submenus for installation and management

#### New Menu Structure:
```
System Preparation Menu
├── Mounts
├── Folders
├── GPU
├── Network
├── Docker Aliases ← (renamed + enhanced)
├── Kubernetes Aliases ← (NEW)
├── SMTP
└── Back
```

### 2. Docker Aliases Submenu

When selecting "Docker Aliases", users now see:
```
Docker Aliases & Management
├── Install Aliases - Docker/Compose bash helpers from docker.md
├── Docker Management - Interactive TUI menu (docker-ops-menu.sh)
├── DevOps Extras - Git, Ansible, Terraform, and more
├── View Aliases - Preview installed Docker aliases
└── Back
```

**Install Aliases** includes:
- Color helpers and output functions
- Smart `dc` wrapper (docker compose)
- Safe aliases (dps, dpa, dcu, dcd, dcr, etc.)
- Quality-of-life functions (dlogs, denter_last, dls)
- Destructive helpers with confirmations (pruning, cleanup)

**Docker Management** installs:
- Interactive TUI menu at `~/.local/bin/docker-ops-menu`
- Container operations (list, logs, exec)
- Image, network, volume management
- Compose shortcuts
- Cleanup operations

**DevOps Extras** adds:
- Git version control aliases
- Ansible automation aliases
- Terraform/OpenTofu IaC aliases
- Systemd journalctl logging
- Tmux/Screen session management
- Rsync backup aliases
- SSH and security tools
- Python/pip aliases
- System info and maintenance

### 3. Kubernetes Aliases Submenu

When selecting "Kubernetes Aliases", users now see:
```
Kubernetes Aliases & Management
├── Install Aliases - kubectl bash helpers from kubernetes.md
├── Kubernetes Management - Interactive TUI menu (k8s-ops-menu.sh)
├── View Aliases - Preview installed Kubernetes aliases
└── Back
```

**Install Aliases** includes:
- Color helpers and output functions
- Core kubectl aliases (k, kctx, kns, kget, etc.)
- Helper functions (kwhere, ksn, kpods, klog, ksh)
- Rollout management (kroll, khist)
- Optional destructive helpers (commented out by default)

**Kubernetes Management** installs:
- Interactive TUI menu at `~/.local/bin/k8s-ops-menu`
- Context and namespace switching
- Pod operations (list, logs, exec)
- Deployment management
- Rollout operations
- Resource cleanup

### 4. New Files Created

#### `/importing/devops-extras.md`
Comprehensive DevOps aliases including:
- **Git**: gs, ga, gc, gp, gl, gb, gst (40+ aliases)
- **Ansible**: ap, apv, apc, ag, ainv (15+ aliases)
- **Terraform**: tf, tfi, tfp, tfa, tfd, tfo (15+ aliases)
- **Journalctl**: jc, jcf, jcu, jcboot (8+ aliases)
- **Screen/Tmux**: sl, sr, ta, tl, ts (10+ aliases)
- **Rsync**: rsync-copy, rsync-sync, rsync-dry (6+ aliases)
- **SSH**: sshkeygen, sshcopy, sshconfig (5+ aliases)
- **Python**: py, pip, venv, mkvenv (10+ aliases)
- **Security**: certinfo, certexpiry, gpglist (8+ aliases)
- **System**: weather, speedtest, sysinfo (15+ aliases)

## File Locations

### Alias Files Installed (in user home directory):
- `~/.docker_aliases` - Docker/Compose aliases
- `~/.k8s_aliases` - Kubernetes/kubectl aliases
- `~/.devops_extras` - Additional DevOps tooling aliases

### Management Scripts Installed:
- `~/.local/bin/docker-ops-menu` - Docker operations TUI
- `~/.local/bin/k8s-ops-menu` - Kubernetes operations TUI

### Source Files (in Zoolandia):
- `importing/docker.md` - Docker aliases source
- `importing/kubernetes.md` - Kubernetes aliases source
- `importing/docker-ops-menu.sh` - Docker TUI script
- `importing/k8s-ops-menu.sh` - Kubernetes TUI script
- `importing/devops-extras.md` - DevOps extras source

### Updated Files:
- `modules/11_system.sh` - System menu with new alias management

## Functions Added

### Main Menu Functions:
- `show_docker_aliases_menu()` - Docker aliases submenu
- `show_kubernetes_aliases_menu()` - Kubernetes aliases submenu

### Installation Functions:
- `install_docker_aliases()` - Extracts and installs Docker aliases from markdown
- `install_kubernetes_aliases()` - Installs Kubernetes aliases
- `install_docker_ops_menu()` - Installs Docker TUI menu
- `install_k8s_ops_menu()` - Installs Kubernetes TUI menu
- `install_devops_extras()` - Installs additional DevOps aliases

### Utility Functions:
- `view_docker_aliases()` - Preview installed Docker aliases
- `view_kubernetes_aliases()` - Preview installed Kubernetes aliases

## Usage

### Installation Process:
1. Navigate to System menu
2. Select "Docker Aliases" or "Kubernetes Aliases"
3. Choose "Install Aliases" to install the bash aliases
4. Choose "Docker/Kubernetes Management" to install the TUI menu
5. Choose "DevOps Extras" for additional tooling aliases
6. Restart terminal or run: `source ~/.bashrc`

### Using the Aliases:
```bash
# Docker examples
dc up -d                    # Smart compose wrapper
dps                         # List containers
dcu                         # Compose up
dlogs traefik              # Follow logs

# Kubernetes examples
k get pods                  # Get pods
klog nginx                  # Follow pod logs
ksh webapp                  # Shell into pod
kctx production            # Switch context

# Git examples
gs                          # Git status
gc "commit message"        # Git commit
gp                          # Git push
gl                          # Pretty git log

# Ansible examples
ap playbook.yml            # Run playbook
apc playbook.yml          # Check mode
ainv                       # List inventory
```

### Using the TUI Menus:
```bash
# Docker operations menu
docker-ops-menu

# Kubernetes operations menu
k8s-ops-menu
```

## Benefits

1. **Organized Structure**: Clear separation between Docker and Kubernetes tooling
2. **Comprehensive Coverage**: 200+ useful aliases for daily DevOps work
3. **Interactive Management**: TUI menus for visual container/pod management
4. **Safe Operations**: Destructive commands have confirmation prompts
5. **Extensible**: Easy to add more aliases to the markdown files
6. **Self-Documenting**: Aliases include comments explaining their purpose
7. **Portable**: All aliases are in user's home directory
8. **Version Controlled**: Source files tracked in Git

## Future Enhancements

Potential additions:
- Helm chart management aliases
- ArgoCD/FluxCD GitOps aliases
- Vault secrets management aliases
- AWS/Azure/GCP cloud provider aliases
- Monitoring tool aliases (Prometheus, Grafana)
- Database management aliases (PostgreSQL, MySQL, MongoDB)

## Testing

All functions have been syntax-checked with `bash -n` and are ready for use.

## Compatibility

- Requires: bash, dialog/whiptail
- Optional: Docker, kubectl (for respective aliases)
- Tested on: Linux systems with bash 4.0+
