# Application Categories and Server Status

## Common (Base System)
**Server Status:** All servers, workstations, and development environments

### Essential Tools
- git
- curl
- wget
- gotop
- tmux
- tree
- jq
- rsync
- rclone
- fzf
- ripgrep
- ncdu
- neofetch
- bash-completion

### Network Tools
- openssh-server
- net-tools
- iproute2
- dnsutils

### System Monitoring
- htop
- gotop
- glances
- iotop
- sysstat (iostat, sar)
- netdata

### Desktop (Workstation Only)
- gnome-tweaks
- gnome-shell-extensions
- vlc

### Build Tools
- build-essential

### Time Sync
- ntp
- chrony

### Maintenance
- cron
- anacron
- logrotate

---

## Web Servers / Reverse Proxies
**Server Status:** Web servers, application servers

### Web Servers
- nginx
- apache2

### Reverse Proxies / Load Balancers
- traefik
- haproxy

### SSL/TLS
- certbot
- openssl

### PHP Runtime
- php-fpm

### Caching
- redis
- redis-server
- memcached

---

## Security
**Server Status:** All servers (mandatory)

### Firewall & Access Control
- ufw
- fail2ban
- ssh-hardening

### Authentication
- authentik
- wazuh
- auditd

### Antivirus & Auditing
- clamav
- lynis
- AIDE

### Mandatory Access Control
- app-armor
- selinux

### Password Policy
- libpam-pwquality

### System Updates
- unattended-upgrades

---

## Monitoring & Observability
**Server Status:** All production servers, homelab

### Metrics & Dashboards
- Prometheus
- Grafana
- Node Exporter
- Alertmanager

### Logging
- ELK stack
  - Elasticsearch
  - Logstash
  - Kibana
- Fluentd
- Fluent-Bit
- Loki

### System Dashboards
- cockpit
- netdata

---

## Language Runtimes / Package Managers
**Server Status:** Development servers, CI/CD servers

### Python
- python3
- python3-venv
- pip
- pipx

### Node.js
- nodejs
- npm
- yarn

### Java
- openjdk (8/11/17)

### Go
- golang

### Rust
- rust
- rustup

---

## Database Servers
**Server Status:** Database servers

### Relational Databases
- postgresql
- postgresql-contrib
- mysql
- mariadb
- mariadb-server

### NoSQL Databases
- redis
- mongodb
- Cassandra (docker only)

### Database Admin Tools
- pgAdmin (docker)
- Adminer (docker)
- phpMyAdmin
- pgbackrest
- wal-g

---

## CI/CD & Development Tools
**Server Status:** CI/CD servers, development servers

### Container Runtime
- docker.io
- docker-compose-plugin
- podman

### CI/CD Platforms
- Jenkins (docker)
- GitLab Runner (docker)
- Gitea (docker)
- Drone CI
- Harbor Registry (docker)
- ArgoCD (kubernetes)

### Development Tools
- code-server (VS Code server)

### Version Control
- git

---

## Media / Homelab Stack
**Server Status:** Homelab servers

### Media Servers
- Jellyfin (docker)
- Plex (docker)

### Media Management
- Sonarr (docker)
- Radarr (docker)
- Lidarr (docker)
- Overseerr (docker)

### Download Clients
- SABnzbd (docker)
- qBittorrent (docker)

### Network Services
- Pi-hole (docker)
- AdGuard Home (docker)

### Remote Access
- Tailscale
- WireGuard
- wireguard-tools
- OpenVPN
- StrongSwan

### Home Automation
- Home Assistant (docker)

### Personal Cloud
- Nextcloud
- MinIO (S3-compatible storage)

### File Systems
- zfsutils-linux
- samba

---

## Orchestration & Infrastructure
**Server Status:** Advanced/enterprise deployments

### Container Orchestration
- Kubernetes
- microk8s
- LXD

### Distributed Storage
- Ceph
- GlusterFS

### Message Queuing
- Kafka
- RabbitMQ

---

## Ansible Roles (External)
**Server Status:** Configuration management

### Community Roles
- geerlingguy.nginx
- geerlingguy.certbot
- geerlingguy.php
- geerlingguy.gitlab
- robertdebock.ansible-role-gitlab

---

## Install Method Mapping

### APT Install (Native)
Recommended for:
- Critical OS services (ssh, ufw, fail2ban, chrony)
- Databases in simple deployments
- Server daemons maintained by Ubuntu

### Docker Install
Recommended for:
- Services that change versions often
- Homelab/media services
- CI/CD runners
- Databases needing isolation
- Quick restore/portability

### Snap Install
Recommended for:
- Desktop/workstation apps
- Isolated runtime requirements
- Rarely required for server deployments

---

## Platform Detection Categories

### All Hosts
- common_hardened role applies

### Web Servers
- nginx or apache2 detected
- web_common role applies

### Database Servers
- postgresql or mariadb detected
- db_common role applies

### CI/CD Servers
- docker detected
- cicd_common role applies

### Homelab Servers
- media stack detected
- homelab_common role applies

### Workstation Detection
- ubuntu-desktop package present
- GUI-specific configuration skipped on servers

### Cloud/VPS Detection
- Amazon, DigitalOcean, Microsoft system vendor
- Cloud-specific optimizations applied

### VM Detection
- ansible_virtualization_role == 'guest'
- VM-specific tuning applied

### WSL Detection
- Kernel search for 'WSL'
- WSL-specific configuration (swap handling)

---

## Backup Targets

### PostgreSQL
- Location: /opt/backups/postgres/
- Method: pg_dumpall | gzip
- Retention: 7 days (configurable)

### Media Stack
- Location: /opt/backups/media/
- Target: /opt/media/configs
- Method: tar.gz

### Home Assistant
- Location: /opt/backups/homeassistant/
- Target: /opt/homeassistant/config
- Method: tar.gz

### Cleanup
- Automated removal of backups older than retention period
- Default: 7 days
