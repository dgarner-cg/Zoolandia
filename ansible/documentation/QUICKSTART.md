# 🚀 Zoolandia Workstation Setup - Quick Start

**Get up and running in 2 minutes!**

---

## For Zoolandia Users

### Automatic Mode

Zoolandia calls this playbook automatically. No action required!

```bash
# Just run Zoolandia normally
# The playbook will be executed with all variables pre-configured
```

---

## For CLI Users

### 1. Install Ansible Collections

```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install community.docker
```

### 2. Run the Playbook

```bash
cd /home/cicero/Documents/Zoolandia/ansible_production
ansible-playbook setup.yml
```

That's it! ✅

---

## Common Usage Patterns

### Test Without Installing (Dry Run)

```bash
ansible-playbook setup.yml --check
```

### Install Only Snap Apps

```bash
ansible-playbook setup.yml --tags "snap"
```

### Install Everything Except Docker

```bash
ansible-playbook setup.yml --skip-tags "docker"
```

### Custom Configuration

```bash
ansible-playbook setup.yml -e "install_docker=false install_zoom=false"
```

### Different User

```bash
ansible-playbook setup.yml -e "workstation_user=alice"
```

---

## What Gets Installed?

### ✅ Always Installed
- System configuration
- Pre-flight checks
- Logging setup

### 📦 Enabled by Default
- Vivaldi (browser)
- Bitwarden (password manager)
- Discord (communication)
- Zoom (video conferencing)
- OnlyOffice (office suite)
- Docker CE
- Portainer

### ⏸️ Disabled by Default
- Termius (SSH client)
- iCloud for Linux
- Twingate
- ProtonVPN
- n8n

---

## Where Are My Logs?

```bash
# Audit trail
cat ~/.zoolandia/logs/setup_2026-01-06.log

# Installation manifest
cat ~/.zoolandia/manifest.yml

# Full documentation
cat ansible_production/README.md
```

---

## Need Help?

- **Full docs:** `README.md`
- **Variables:** `documentation/VARIABLES.md`
- **Architecture:** `documentation/ARCHITECTURE.md`
- **Migration:** `documentation/MIGRATION.md`

---

## Pro Tips

### View Available Tags

```bash
ansible-playbook setup.yml --list-tags
```

### View All Tasks

```bash
ansible-playbook setup.yml --list-tasks
```

### Enable Verbose Output

```bash
ansible-playbook setup.yml -v
```

### Install Specific Apps Only

```bash
# Browsers and communication only
ansible-playbook setup.yml --tags "vivaldi,discord,zoom"
```

---

**That's all you need to know to get started!**

For advanced usage, see `README.md` 📖
