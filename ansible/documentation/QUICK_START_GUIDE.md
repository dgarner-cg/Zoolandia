# Quick Start Guide - Zoolandia Workstation Setup

**🚀 Ready to use in 2 minutes!**

---

## 🎯 Three Ways to Run

### 1. Interactive Menu (Recommended for First Time)

```bash
cd /home/cicero/Documents/Zoolandia/ansible
./ansible-menu.sh
```

**Features:**
- ✅ Easy checkbox selection (spacebar to toggle)
- ✅ "Install All" quick option
- ✅ Dry run to preview changes
- ✅ Built-in documentation viewer

---

### 2. Command Line (Full Control)

```bash
cd /home/cicero/Documents/Zoolandia/ansible

# Install everything with defaults
ansible-playbook setup-workstation.yml

# Preview what would happen (dry run)
ansible-playbook setup-workstation.yml --check

# Install only browsers and communication apps
ansible-playbook setup-workstation.yml --tags "snap,deb"

# Install Docker and containers only
ansible-playbook setup-workstation.yml --tags "docker,portainer"

# Skip Docker installation
ansible-playbook setup-workstation.yml --skip-tags "docker"

# Disable specific apps
ansible-playbook setup-workstation.yml -e "install_zoom=false install_twingate=false"
```

---

### 3. Zoolandia Platform (Automatic)

No action needed! Zoolandia will call the playbook automatically with the correct variables.

---

## 📋 What Gets Installed (Default)

**Applications (13):**
- Vivaldi, Bitwarden, Notepad++, Notion, Mailspring
- Claude Code, ChatGPT Desktop
- Discord, Zoom, OnlyOffice
- Docker CE, Portainer, Ulauncher

**System Configs (3):**
- Power management (disable auto-sleep)
- Touchpad settings (speed + two-finger tap)
- Nautilus (sort by file type)

---

## 🔍 Preview First?

```bash
# See what would be installed
ansible-playbook setup-workstation.yml --list-tasks

# See all available options
ansible-playbook setup-workstation.yml --list-tags

# Dry run (no changes made)
ansible-playbook setup-workstation.yml --check
```

---

## 📚 Need More Details?

- **README.md** - Comprehensive documentation (500+ lines)
- **APPS.md** - Complete list of all 23 apps & configs
- **MERGE_COMPLETE.md** - What changed in the merge

---

## ⚠️ Important Notes

1. **Sudo Password:** You'll be prompted for your sudo password
2. **Docker Group:** Log out and back in after Docker installation
3. **GNOME Only:** Some system configs only work on GNOME desktop
4. **Internet Required:** Downloads packages from the internet

---

## 🆘 Troubleshooting

**Problem:** Snap apps fail to install
**Solution:** Run `sudo apt install snapd && sudo systemctl enable --now snapd`

**Problem:** Docker group doesn't work
**Solution:** Log out and back in, or run `newgrp docker`

**Problem:** GNOME settings skip
**Solution:** Normal if not using GNOME desktop

---

## 🎉 After Installation

**Check Logs:**
- Audit trail: `~/.zoolandia/logs/setup_2026-01-07.log`
- Manifest: `~/.zoolandia/manifest.yml`

**Installed Apps:**
- Docker: `docker --version`
- Portainer: `https://localhost:9443`
- Ulauncher: Press `Ctrl+Space` (or configured hotkey)

---

**That's it! Pick a method and start installing! 🚀**
