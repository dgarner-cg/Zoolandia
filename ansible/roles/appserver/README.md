# App Server Role

Ansible role for installing application development tools and services.

## Components

### VS Code Tunnel

Enables persistent VS Code remote development access via browser. Access your development environment from any device at `https://vscode.dev/tunnel/<hostname>`.

**Features:**
- Automatic VS Code installation (ARM64 and AMD64)
- Systemd service for persistent tunnel connections
- Auto-restart on failure
- GitHub authentication integration

## Requirements

- Ubuntu 20.04+ / Debian 11+
- GitHub account (for VS Code Tunnel authentication)
- Internet connectivity

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `vscode_tunnel_user` | `{{ ansible_user_id }}` | User to run the tunnel service |
| `vscode_tunnel_group` | `{{ ansible_user_id }}` | Group for the tunnel service |
| `github_username` | `""` | GitHub username for authentication guidance |

## Dependencies

None.

## Installation

### Via Zoolandia Menu

1. **Set GitHub Username** (recommended):
   ```
   Prerequisites > GitHub Username
   ```

2. **Install VS Code Tunnel**:
   ```
   Ansible > App Server > vscode-tunnel
   ```
   Or browse via:
   ```
   Ansible > All Applications > vscode-tunnel
   ```

### Via Command Line

```bash
# Basic installation
ansible-playbook playbooks/appserver.yml

# With GitHub username
ansible-playbook playbooks/appserver.yml -e "github_username=your-github-username"

# With custom user
ansible-playbook playbooks/appserver.yml -e "vscode_tunnel_user=myuser" -e "vscode_tunnel_group=myuser"

# Only VS Code Tunnel (skip other components)
ansible-playbook playbooks/appserver.yml --tags "vscode-tunnel"

# Dry run
ansible-playbook playbooks/appserver.yml --check
```

## First-Time Setup

After installation, you must authenticate with GitHub:

```bash
# 1. Run the tunnel command to authenticate
code tunnel --accept-server-license-terms

# 2. Follow the device login prompts:
#    - Open https://github.com/login/device
#    - Enter the code displayed in terminal
#    - Authorize the application

# 3. Press Ctrl+C after authentication completes

# 4. Start the systemd service
sudo systemctl start code-tunnel

# 5. Access your tunnel
#    Open in browser: https://vscode.dev/tunnel/<your-hostname>
```

## Service Management

```bash
# Check service status
sudo systemctl status code-tunnel

# Start service
sudo systemctl start code-tunnel

# Stop service
sudo systemctl stop code-tunnel

# Restart service
sudo systemctl restart code-tunnel

# View logs
sudo journalctl -u code-tunnel -f

# Disable service (prevent auto-start)
sudo systemctl disable code-tunnel

# Enable service (auto-start on boot)
sudo systemctl enable code-tunnel
```

## Systemd Service Configuration

The service is installed at `/etc/systemd/system/code-tunnel.service`:

```ini
[Unit]
Description=VSCode Tunnel as Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/code tunnel
User=<your-user>
Group=<your-group>
Restart=on-failure
RestartSec=10
Environment=HOME=/home/<your-user>

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

### Tunnel not connecting

1. Check if the service is running:
   ```bash
   sudo systemctl status code-tunnel
   ```

2. Check logs for errors:
   ```bash
   sudo journalctl -u code-tunnel -n 50
   ```

3. Verify GitHub authentication:
   ```bash
   code tunnel --accept-server-license-terms
   ```

### Permission denied errors

Ensure the user has proper permissions:
```bash
# Check user exists
id <username>

# Verify home directory
ls -la /home/<username>
```

### Service fails to start

1. Check if VS Code is installed:
   ```bash
   which code
   code --version
   ```

2. Reinstall VS Code:
   ```bash
   ansible-playbook playbooks/appserver.yml --tags "vscode-tunnel"
   ```

## Security Considerations

- The tunnel requires GitHub authentication
- Access is restricted to authenticated GitHub users
- Consider using GitHub organization restrictions for team environments
- The service runs as a non-root user

## Tags

- `vscode` - VS Code installation only
- `vscode-tunnel` - Full VS Code Tunnel setup
- `development` - All development tools
- `appserver` - All app server components
- `application` - Alias for appserver

## Example Playbook

```yaml
---
- name: Setup development server
  hosts: devservers
  become: yes

  vars:
    vscode_tunnel_user: developer
    vscode_tunnel_group: developer
    github_username: mycompany-dev

  roles:
    - role: appserver
      tags: ['appserver']
```

## License

MIT

## Author

Zoolandia by hack3r.gg
