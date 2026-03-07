# Ansible Workstation Role - Available Tags

This document lists all available tags in the Zoolandia Workstation Setup role.

## Usage

Run playbook with specific tags:
```bash
# Install only snap applications
ansible-playbook setup-workstation.yml --tags "snap"

# Install Docker and related services
ansible-playbook setup-workstation.yml --tags "docker,portainer"

# Skip power management configuration
ansible-playbook setup-workstation.yml --skip-tags "power"

# Run only system configuration (no apps)
ansible-playbook setup-workstation.yml --tags "system,config"
```

## Available Tags

### Core Tags

| Tag | Description | Used For |
|-----|-------------|----------|
| `always` | Always runs (cannot be skipped) | Pre-flight checks, initialization, final summary |
| `workstation` | Main workstation role | All tasks in the workstation role |
| `preflight` | Pre-flight validation checks | System checks before installation |
| `verification` | Post-installation verification | Verify installations completed |
| `cleanup` | Cleanup and finalization | Remove temporary files, finalize logs |

### Application Categories

| Tag | Description | Includes |
|-----|-------------|----------|
| `applications` | All applications | Snap, deb, and complex apps |
| `simple` | Simple applications | Snap and deb packages installed via loops |
| `complex` | Complex applications | Apps requiring special handling (Docker, Twingate, etc.) |
| `snap` | Snap applications | Vivaldi, Bitwarden, Notepad++, Notion, etc. |
| `deb` | Debian packages | Discord, Zoom, Termius, OnlyOffice |
| `docker` | Docker and containers | Docker Engine, Portainer, n8n |

### Specific Applications

| Tag | Description | Application |
|-----|-------------|-------------|
| `ulauncher` | Ulauncher application launcher | PPA-based launcher for Linux |
| `portainer` | Portainer container manager | Docker management UI |
| `n8n` | n8n workflow automation | Workflow automation platform |
| `twingate` | Twingate VPN client | Zero-trust network access |
| `protonvpn` | ProtonVPN client | VPN client for privacy |

### System Configuration

| Tag | Description | Configures |
|-----|-------------|-----------|
| `system` | All system configuration | Power, touchpad, Nautilus, etc. |
| `config` | Configuration tasks | System settings and preferences |
| `power` | Power management settings | Sleep/hibernate behavior |
| `touchpad` | Touchpad configuration | Speed, click method |
| `nautilus` | Nautilus file manager | Sort order, default view |
| `gnome` | GNOME-specific settings | Power, touchpad (requires GNOME) |

### Infrastructure

| Tag | Description | Used For |
|-----|-------------|----------|
| `apt` | APT package manager | Update cache, install packages |
| `launcher` | Application launchers | Ulauncher |
| `vpn` | VPN clients | ProtonVPN, Twingate |
| `automation` | Automation tools | n8n |

## Tag Combinations

### Common Use Cases

**Install only browsers and productivity apps:**
```bash
ansible-playbook setup-workstation.yml --tags "snap" \
  -e "snap_apps=[{name: vivaldi, enabled: true}, {name: notion-snap-reborn, enabled: true}]"
```

**Install Docker ecosystem:**
```bash
ansible-playbook setup-workstation.yml --tags "docker,portainer,n8n"
```

**Configure system only (no apps):**
```bash
ansible-playbook setup-workstation.yml --tags "system,power,touchpad,nautilus"
```

**Skip GNOME-specific settings:**
```bash
ansible-playbook setup-workstation.yml --skip-tags "gnome"
```

**Quick test (preflight checks only):**
```bash
ansible-playbook setup-workstation.yml --tags "preflight" --check
```

**Install everything except VPNs:**
```bash
ansible-playbook setup-workstation.yml --skip-tags "vpn,protonvpn,twingate"
```

## Tag Hierarchy

```
workstation (all tasks)
├── always (pre-flight, summary)
├── applications
│   ├── simple
│   │   ├── snap (Vivaldi, Bitwarden, Notepad++, Notion, etc.)
│   │   └── deb (Discord, Zoom, Termius, OnlyOffice)
│   └── complex
│       ├── docker (+ portainer, n8n)
│       ├── ulauncher (+ launcher)
│       ├── twingate (+ vpn)
│       └── protonvpn (+ vpn)
└── system (+ config)
    ├── power (+ gnome)
    ├── touchpad (+ gnome)
    └── nautilus (+ gnome)
```

## Notes

- Tags marked with `always` cannot be skipped with `--skip-tags`
- Tags marked with `gnome` require GNOME desktop environment
- Multiple tags can be combined with commas: `--tags "tag1,tag2,tag3"`
- Use `--list-tags` to see all tags in a playbook:
  ```bash
  ansible-playbook setup-workstation.yml --list-tags
  ```

## Examples by Scenario

### Scenario 1: Fresh Workstation Setup
```bash
# Install everything with defaults
ansible-playbook setup-workstation.yml
```

### Scenario 2: Add Docker to Existing Setup
```bash
# Install only Docker and Portainer
ansible-playbook setup-workstation.yml --tags "docker,portainer"
```

### Scenario 3: Reconfigure System Settings
```bash
# Update power and touchpad settings only
ansible-playbook setup-workstation.yml --tags "power,touchpad"
```

### Scenario 4: Test Before Installation
```bash
# Dry run to see what would change
ansible-playbook setup-workstation.yml --check
```

### Scenario 5: Skip Long-Running Tasks
```bash
# Install everything except complex apps
ansible-playbook setup-workstation.yml --skip-tags "complex"
```
