# Zoolandia Applications - Complete Catalog

**Total Applications:** 167
- **Docker Apps:** 151 containerized applications
- **System Apps:** 16 native Linux applications (installed via Ansible)

> All apps include detailed descriptions in the menu system for easier selection and understanding.

---

## Table of Contents

- [System Applications (16 Apps)](#system-applications-16-apps)
- [Docker Applications (151 Apps)](#docker-applications-151-apps)
  - [Reverse Proxy and Tunnels (5)](#reverse-proxy-and-tunnels)
  - [Media Servers and Players (8)](#media-servers-and-players)
  - [Media Management (17)](#media-management)
  - [Downloaders (5)](#downloaders)
  - [Network Tools (7)](#network-tools)
  - [Monitoring (11)](#monitoring)
  - [Security (8)](#security)
  - [Dashboards (7)](#dashboards)
  - [Reading (6)](#reading)
  - [Databases (9)](#databases)
  - [Smart Home and Automation (7)](#smart-home-and-automation)
  - [Photo Management (3)](#photo-management)
  - [Docker Management (7)](#docker-management)
  - [File Management (12)](#file-management)
  - [Admin Tools (5)](#admin-tools)
  - [Remote Access (5)](#remote-access)
  - [Social (1)](#social)
  - [Password Management (1)](#password-management)
  - [Notes and Documentation (4)](#notes-and-documentation)
  - [AI and Machine Learning (6)](#ai-and-machine-learning)
  - [Planning and Scheduling (2)](#planning-and-scheduling)
  - [Other Utilities (7)](#other-utilities)
  - [Utility and Custom (4)](#utility-and-custom)

---

## System Applications (16 Apps)

*Installed via Ansible - Native Linux applications accessible through SysConfig menu*

### Desktop Applications (3)

1. **Vivaldi** - Privacy-focused web browser with extensive customization options and built-in features
2. **Discord** - Voice, video, and text communication platform for communities and teams
3. **Zoom** - Video conferencing and online meetings platform

### Productivity (4)

4. **Notion** - All-in-one workspace for notes, docs, wikis, and collaboration
5. **Notepad++** - Feature-rich text and code editor with syntax highlighting
6. **OnlyOffice** - Full office suite with document, spreadsheet, and presentation editing
7. **Mailspring** - Beautiful, fast email client with unified inbox and modern interface

### Security & VPN (3)

8. **Bitwarden** - Open-source password manager and secure vault
9. **ProtonVPN** - Secure VPN service with privacy focus and no-logs policy
10. **Twingate** - Zero trust network access platform for secure remote access

### Development & DevOps (4)

11. **Docker** - Container platform engine for application deployment and management
12. **Portainer** - Web-based Docker container management interface (also available as Docker container)
13. **n8n** - Workflow automation platform for connecting apps (also available as Docker container)
14. **Termius** - Modern SSH and SFTP client with cross-platform sync

### Utilities (2)

15. **iCloud** - iCloud integration for Linux systems (file sync and access)
16. **Ulauncher** - Fast application launcher for Linux with plugin support

---

## Docker Applications (151 Apps)

*Containerized services installed through Apps menu*

### Reverse Proxy and Tunnels

1. **Traefik** (`traefik.yml`) - Modern HTTP reverse proxy and load balancer with automatic service discovery
2. **Traefik Access Logs** (`traefik-access-log.yml`) - Pass Traefik access logs to Dozzle for monitoring
3. **Traefik Error Logs** (`traefik-error-log.yml`) - Pass Traefik error logs to Dozzle for debugging
4. **Traefik Certs Dumper** (`traefik-certs-dumper.yml`) - Extract and dump Traefik SSL certificates to disk
5. **Cloudflare Tunnel** (`cloudflare-tunnel.yml`) - Secure tunnel to connect resources to Cloudflare without public IP

### Media Servers and Players

6. **Plex** (`plex.yml`) - Premium media server for organizing and streaming video, music, and photos
7. **Jellyfin** (`jellyfin.yml`) - Open-source media server for managing and streaming personal media libraries
8. **Emby** (`emby.yml`) - Media server to organize, stream, and share personal media collections
9. **Airsonic-Advanced** (`airsonic-advanced.yml`) - Free, web-based media streamer for ubiquitous music access
10. **Navidrome** (`navidrome.yml`) - Modern music server and streamer compatible with Subsonic/Airsonic clients
11. **Lollypop** (`lollypop.yml`) - Modern music player for GNOME desktop environment
12. **Funkwhale** (`funkwhale.yml`) - Modern, self-hosted, web-based music streaming server
13. **Gonic** (`gonic.yml`) - Lightweight music streaming server with Subsonic API compatibility

### Media Management

14. **Radarr** (`radarr.yml`) - Movie collection manager for Usenet and BitTorrent users with automation
15. **Sonarr** (`sonarr.yml`) - PVR for Usenet and BitTorrent users to manage and download TV series
16. **Lidarr** (`lidarr.yml`) - Music collection manager for Usenet and BitTorrent users
17. **Readarr** (`readarr.yml`) - Book and audiobook collection manager (Note: Development slowed)
18. **Bazarr** (`bazarr.yml`) - Companion app for Sonarr/Radarr that manages and downloads subtitles
19. **Jackett** (`jackett.yml`) - Proxy server translating queries from apps into tracker-specific HTTP queries
20. **Maintainerr** (`maintainerr.yml`) - Tool for managing and maintaining media libraries and Docker containers
21. **Jellyseerr** (`jellyseerr.yml`) - Request management and media discovery tool for Jellyfin
22. **Ombi** (`ombi.yml`) - Self-hosted media request and management system for Plex/Emby/Jellyfin
23. **Overseerr** (`overseerr.yml`) - Request management and media discovery tool for Plex ecosystem
24. **Tautulli** (`tautulli.yml`) - Monitoring and tracking tool for Plex Media Server usage and statistics
25. **Prowlarr** (`prowlarr.yml`) - Indexer manager/proxy for managing indexers across multiple applications
26. **Kometa** (`kometa.yml`) - Plex Meta Manager for creating automatic collections based on criteria
27. **Notifiarr** (`notifiarr.yml`) - Notification service and client for media server applications
28. **Beets** (`beets.yml`) - Music library manager and MusicBrainz tagger for organizing music
29. **Audiobookshelf** (`audiobookshelf.yml`) - Self-hosted audiobook and podcast server with mobile apps
30. **Huntarr** (`huntarr.yml`) - Missing media and upgrade utility for *arr applications
31. **Cleanuparr** (`cleanuparr.yml`) - Arr stack and media cleanup utility for managing storage

### Downloaders

32. **NZBGet** (`nzbget.yml`) - Efficient Usenet downloader optimized for performance and low resource usage
33. **SABnzbd** (`sabnzbd.yml`) - Open-source Usenet downloader with web interface and automation
34. **qBittorrent** (`qbittorrent.yml`) - Open-source BitTorrent client with web UI (no VPN integration)
35. **Transmission** (`transmission.yml`) - Fast, easy, and free BitTorrent client (no VPN integration)
36. **qBittorrent with VPN** (`qbittorrent-vpn.yml`) - qBittorrent client with integrated Gluetun VPN protection

### Network Tools

37. **Wireguard** (`wg-easy.yml`) - Fast, modern VPN using state-of-the-art cryptography (via WG-Easy)
38. **Gluetun** (`gluetun.yml`) - Universal VPN client container supporting multiple VPN providers
39. **WG-Easy** (`wg-easy.yml`) - Web UI for managing WireGuard VPN with ease
40. **DDNS Updater** (`ddns-updater.yml`) - Automatic dynamic DNS record updater for multiple providers
41. **Tailscale** (`tailscale.yml`) - Zero-config VPN using WireGuard for secure device connections
42. **ZeroTier** (`zerotier.yml`) - Software-defined networking creating secure virtual networks
43. **Pi-hole** (`pihole.yml`) - Network-wide ad blocker and DNS server for privacy and security

### Monitoring

44. **Uptime-Kuma** (`uptime-kuma.yml`) - Self-hosted monitoring tool similar to Uptime Robot
45. **Netdata** (`netdata.yml`) - Real-time performance monitoring for systems and applications
46. **Grafana** (`grafana.yml`) - Open-source platform for monitoring, visualization, and observability
47. **cAdvisor** (`cadvisor.yml`) - Container Advisor analyzing resource usage and performance of containers
48. **Dozzle** (`dozzle.yml`) - Real-time log viewer for Docker containers with web interface
49. **Dozzle Agent** (`dozzle-agent.yml`) - Remote agent enabling Dozzle to view logs from multiple hosts
50. **Scrutiny** (`scrutiny.yml`) - Web UI for smartd S.M.A.R.T monitoring of hard drives
51. **Speedtest-Tracker** (`speedtest-tracker.yml`) - Self-hosted internet speed tracking and monitoring
52. **Smokeping** (`smokeping.yml`) - Network latency monitoring tool with historical graphs
53. **Glances** (`glances.yml`) - Cross-platform system monitoring tool with web interface
54. **Change Detection** (`change-detection.yml`) - Web page change monitoring and notification tool
55. **Node Exporter** (`node-exporter.yml`) - Prometheus exporter for hardware and OS metrics

### Security

56. **Authentik** (`authentik.yml` + `authentik-worker.yml`) - Self-hosted identity provider with SSO, LDAP, and OAuth
57. **Authelia** (`authelia.yml`) - Authentication and authorization server with 2FA and SSO
58. **Socket Proxy** (`socket-proxy.yml`) - Security proxy for Docker socket with fine-grained access control
59. **OAuth** (`oauth.yml`) - OAuth authentication provider supporting Google OAuth 2.0 and others
60. **TinyAuth** (`tinyauth.yml`) - Lightweight self-hosted Single Sign-On with 2FA and OAuth
61. **CrowdSec** (`crowdsec.yml`) - Open-source collaborative security solution and intrusion prevention system
62. **CrowdSec Firewall Bouncer** (`cloudflare-bouncer.yml`) - CrowdSec bouncer for blocking malicious IPs in firewall
63. **Traefik Bouncer** (`traefik-bouncer.yml`) - Security bouncer integrating CrowdSec with Traefik reverse proxy

### Dashboards

64. **Homepage** (`homepage.yml`) - Modern, customizable application dashboard for organizing services
65. **Flame** (`flame.yml`) - Self-hosted start page with bookmark management
66. **Dashy** (`dashy.yml`) - Feature-rich dashboard for managing and accessing server applications
67. **Heimdall** (`heimdall.yml`) - Application dashboard and launcher for web applications
68. **Homarr** (`homarr.yml`) - Sleek, modern dashboard for managing home server with integrations
69. **Homer** (`homer.yml`) - Dead simple static homepage from YAML configuration
70. **Organizr** (`organizr.yml`) - HTPC/Homelab services organizer with authentication and tabs

### Reading

71. **Kavita** (`kavita.yml`) - Self-hosted digital library for comics, manga, and eBooks
72. **Calibre-Web** (`calibre-web.yml`) - Web interface for browsing, reading, and downloading eBooks
73. **Calibre** (`calibre.yml`) - Powerful and easy-to-use e-book manager and converter
74. **Komga** (`komga.yml`) - Media server for comics, manga, and BDs with web-based reader
75. **Mylar3** (`mylar3.yml`) - Automated comic book downloader for Usenet and torrents
76. **FreshRSS** (`freshrss.yml`) - Self-hosted RSS feed aggregator and reader

### Databases

77. **Prometheus** (`prometheus.yml`) - Monitoring system and time series database for metrics
78. **MariaDB** (`mariadb.yml`) - Community-developed MySQL fork remaining free under GNU GPL
79. **PostgreSQL** (`postgresql.yml`) - Powerful open-source object-relational database system
80. **Redis** (`redis.yml`) - In-memory data structure store used as database, cache, and message broker
81. **InfluxDB** (`influxdb.yml`) - Open-source time series database optimized for time-stamped data
82. **Adminer** (`adminer.yml`) - Full-featured database management tool for MySQL, PostgreSQL, and more
83. **PgAdmin** (`pgadmin.yml`) - Web-based administration and development platform for PostgreSQL
84. **phpMyAdmin** (`phpmyadmin.yml`) - Web interface for MySQL and MariaDB administration
85. **Redis Commander** (`redis-commander.yml`) - Web-based management tool for Redis databases

### Smart Home and Automation

86. **Home Assistant Core** (`home-assistant.yml`) - Open-source home automation platform (Core version, no add-ons)
87. **Homebridge** (`homebridge.yml`) - Node.js server emulating iOS HomeKit API for smart home integration
88. **Mosquitto** (`mosquitto.yml`) - Open-source MQTT message broker for IoT communication
89. **MQTTX Web** (`mqttx-web.yml`) - Web-based MQTT 5.0 client and testing tool
90. **ESPHome** (`esphome.yml`) - System for controlling ESP8266/ESP32 via configuration files
91. **Node-RED** (`node-red.yml`) - Flow-based programming tool for wiring together IoT devices
92. **n8n** (`compose/n8n.yml`) - Workflow automation tool for connecting apps and services (also available as system app)

### Photo Management

93. **Immich** (`immich.yml` + `immich-db.yml` + `immich-ml.yml`) - High-performance self-hosted photo and video backup solution
94. **Piwigo** (`piwigo.yml`) - Photo gallery software for the web with sharing features
95. **DigiKam** (`digikam.yml`) - Professional photo management application with editing tools
96. **Photoshow** (`photoshow.yml`) - Simple web-based photo gallery (Note: Project unmaintained, domain compromised)

### Docker Management

97. **Portainer** (`compose/portainer.yml`) - Lightweight management UI for Docker environments (also available as system app)
98. **Docker Garbage Collection** (`docker-gc.yml`) - Automated cleanup of unused Docker containers, images, and volumes
99. **DeUnhealth** (`deunhealth.yml`) - Monitor and manage health status of Docker containers
100. **Dockwatch** (`dockwatch.yml`) - Docker container monitoring and management tool
101. **What's Up Docker (WUD)** (`wud.yml`) - Tool to monitor and notify about Docker image updates
102. **DweebUI** (`dweebui.yml`) - Customizable web UI for managing various Docker applications
103. **Watchtower** (`watchtower.yml`) - Automated Docker container base image updates

### File Management

104. **FileZilla** (`filezilla.yml`) - Fast and reliable FTP, FTPS, and SFTP client with GUI
105. **Nextcloud** (`nextcloud.yml`) - Self-hosted file sync and share platform with collaboration features
106. **Visual Studio Code Server** (`vscode.yml`) - Cloud-hosted VS Code accessible from web browser
107. **Cloud Commander** (`cloud-commander.yml`) - Web-based file manager with console and editor
108. **Double Commander** (`double-commander.yml`) - Cross-platform file manager with dual-panel interface
109. **Stirling PDF** (`stirling-pdf.yml`) - Self-hosted web-based PDF manipulation and editing tool
110. **Paperless-NGX** (`paperless-ngx.yml`) - Document management system with OCR and search
111. **Paperless-AI** (`paperless-ai.yml`) - AI-powered document analyzer for Paperless-NGX
112. **Gotenberg** (`gotenberg.yml`) - Document conversion API server for Paperless-NGX
113. **Tika** (`tika.yml`) - Apache Tika text extraction tool for Paperless-NGX
114. **PdfDing** (`pdfding.yml`) - Web-based PDF viewing and editing tool
115. **Privatebin** (`privatebin.yml`) - Minimalist, open-source online pastebin with encryption

### Admin Tools

116. **IT-Tools** (`it-tools.yml`) - Collection of useful tools for IT professionals and developers
117. **ShellInABox** (`shellinabox.yml`) - Web-based SSH terminal accessible from browser (HTML5)
118. **CyberChef** (`cyberchef.yml`) - Web app for encryption, encoding, compression, and data analysis
119. **GPTWOL** (`gptwol.yml`) - Wake-on-LAN tool with Docker-based web GUI
120. **SSHwifty** (`sshwifty.yml`) - Web-based SSH and Telnet client

### Remote Access

121. **Guacamole** (`guacamole.yml` + `guacd.yml`) - Clientless remote desktop gateway supporting VNC, RDP, SSH
122. **Chromium** (`chromium.yml`) - Open-source web browser in Docker container
123. **Kasm** (`kasm.yml`) - Web-based workspace and remote desktop streaming solution
124. **Remmina** (`remmina.yml`) - Remote desktop client supporting RDP, VNC, SSH, and more
125. **XPipe WebTop** (`xpipe-webtop.yml`) - Web-based desktop environment with remote access

### Social

126. **The Lounge** (`thelounge.yml`) - Self-hosted web IRC client with persistent connections

### Password Management

127. **Vaultwarden** (`vaultwarden.yml`) - Lightweight, self-hosted Bitwarden-compatible password manager

### Notes and Documentation

128. **Trilium Next** (`triliumnext.yml`) - Hierarchical note-taking app for building personal knowledge bases
129. **WikiDocs** (`wikidocs.yml`) - Modern, open-source wiki software for documentation
130. **DokuWiki** (`dokuwiki.yml`) - Simple, versatile open-source wiki software without database
131. **Bookstack** (`bookstack.yml`) - Platform for creating documentation and wiki content (PHP/Laravel)

### AI and Machine Learning

132. **Flowise** (`flowise.yml`) - Drag-and-drop UI for building custom LLM flows and AI applications
133. **Ollama** (`ollama.yml`) - Run large language models locally with easy management
134. **Open-WebUI** (`open-webui.yml`) - Feature-rich web interface for Ollama and OpenAI APIs
135. **OpenHands** (`openhands.yml`) - Open-source AI coding assistant and autonomous agent
136. **Weaviate** (`weaviate.yml`) - Open-source vector database for AI applications
137. **Qdrant** (`qdrant.yml`) - High-performance vector database and similarity search engine

### Planning and Scheduling

138. **Vikunja** (`vikunja.yml`) - Open-source to-do app and project management tool
139. **Baikal** (`baikal.yml`) - Lightweight CalDAV and CardDAV server for calendars and contacts

### Other Utilities

140. **Resilio Sync** (`resilio-sync.yml`) - Fast, reliable file and folder synchronization tool
141. **Grocy** (`grocy.yml`) - Web-based self-hosted groceries and household management solution
142. **Flaresolverr** (`flaresolverr.yml`) - Proxy server to bypass Cloudflare and DDoS-GUARD protection
143. **Theme Park** (`theme-park.yml`) - Collection of themes and CSS tweaks for various applications
144. **SearXNG** (`searxng.yml`) - Privacy-respecting, hackable metasearch engine
145. **GameVault** (`gamevault.yml`) - Self-hosted gaming platform and library manager
146. **Wallos** (`wallos.yml`) - Open-source personal subscription tracker and budget manager

### Utility and Custom

147. **Custom** (`custom.yml`) - Custom application template for user-defined services
148. **Starter** (`starter.yml`) - Starter template for quick Docker Compose service creation
149. **Support** (`support.yml`) - Support container for troubleshooting and diagnostics
150. **Deployrr Dashboard** (`deployrr-dashboard.yml`) - Dashboard for Deployrr/Zoolandia management
151. **Hemmelig** (`hemmelig.yml`) - Self-hosted secret sharing service with encryption

---

## App Categories Summary

| Category | Docker Apps | System Apps | Total |
|----------|-------------|-------------|-------|
| Reverse Proxy & Tunnels | 5 | 0 | 5 |
| Media Servers | 8 | 0 | 8 |
| Media Management | 17 | 0 | 17 |
| Downloaders | 5 | 0 | 5 |
| Network Tools | 7 | 0 | 7 |
| Monitoring | 11 | 0 | 11 |
| Security | 8 | 2 | 10 |
| Dashboards | 7 | 0 | 7 |
| Reading | 6 | 0 | 6 |
| Databases | 9 | 0 | 9 |
| Smart Home | 7 | 0 | 7 |
| Photo Management | 4 | 0 | 4 |
| Docker Management | 7 | 1 | 8 |
| File Management | 12 | 0 | 12 |
| Admin Tools | 5 | 0 | 5 |
| Remote Access | 5 | 0 | 5 |
| Social | 1 | 0 | 1 |
| Password Management | 1 | 1 | 2 |
| Notes & Documentation | 4 | 1 | 5 |
| AI & Machine Learning | 6 | 0 | 6 |
| Planning & Scheduling | 2 | 0 | 2 |
| Desktop Applications | 0 | 3 | 3 |
| Productivity | 0 | 4 | 4 |
| VPN | 0 | 1 | 1 |
| Development | 0 | 3 | 3 |
| Utilities | 11 | 2 | 13 |
| **TOTAL** | **151** | **16** | **167** |

---

## Installation Methods

### Docker Applications
All Docker applications are installed through the **Apps** menu in Zoolandia:
1. Launch Zoolandia: `./hack3r.sh`
2. Navigate to Apps menu
3. Select applications using checkbox interface
4. Configure GPU and Traefik settings per app
5. Install selected apps in batch

### System Applications
System applications are installed through the **Ansible** menu (SysConfig):
1. Launch Zoolandia: `./hack3r.sh`
2. Navigate to Ansible → System Apps
3. Select applications to install
4. Ansible handles installation automatically

Alternatively, install via command line:
```bash
# Individual app
ansible-playbook setup_individual.yml -e "app_name=discord"

# All apps
ansible-playbook setup_all.yml
```

---

## Notes

- **Deprecated Apps**: Some applications (Photoshow, Readarr) are noted as unmaintained or with slowed development
- **Duplicate Entries**: Some apps available both as Docker and System apps (Portainer, n8n, Docker)
- **Multi-Container Apps**: Some apps require multiple compose files (Immich, Authentik, Guacamole)
- **Dependencies**: Many apps integrate with others (Paperless-AI with Paperless-NGX, Traefik logs with Dozzle)
- **VPN Integration**: qBittorrent available both with and without VPN integration

---

## Adding New Applications

To request new applications or contribute:
1. Open an issue on the [GitHub repository](https://github.com/SimpleHomelab/Zoolandia)
2. Join the [Discord community](https://www.simplehomelab.com/discord/)
3. Submit a pull request with the new app's compose file

---

## Version

**Document Version:** 6.0.18
**Last Updated:** December 31, 2025
**Total Applications:** 167 (151 Docker + 16 System)
