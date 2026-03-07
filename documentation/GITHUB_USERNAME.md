# GitHub Username Configuration

Zoolandia stores your GitHub username for integration with various tools and services that require GitHub authentication.

## Overview

The GitHub username is used for:
- **VS Code Tunnel**: Provides guidance during GitHub device login
- **Git Configuration**: Can be used for git user setup
- **GitHub Integrations**: Any service requiring GitHub authentication

## Setting Your GitHub Username

### Via Menu

1. Navigate to **Prerequisites** from the main menu
2. Select **GitHub Username**
3. Enter your GitHub username
4. Press **Save**

### Configuration Storage

Your GitHub username is stored in:
```
~/.config/zoolandia/github_username
```

This file contains only your username (no sensitive data).

## Validation Rules

GitHub usernames must:
- Start with a letter or number
- Contain only letters, numbers, or hyphens (-)
- Be 1-39 characters long
- Not end with a hyphen

**Valid examples:**
- `octocat`
- `john-doe`
- `company123`
- `a1b2c3`

**Invalid examples:**
- `-username` (starts with hyphen)
- `user_name` (contains underscore)
- `username-` (ends with hyphen)
- `ab` followed by 40+ characters (too long)

## Usage in Ansible

When running Ansible playbooks through Zoolandia, your GitHub username is automatically passed as a variable:

```bash
ansible-playbook playbooks/appserver.yml -e "github_username=your-username"
```

### In Playbooks

Access the variable in your Ansible tasks:

```yaml
- name: Display GitHub user info
  debug:
    msg: "Configuring for GitHub user: {{ github_username }}"
  when: github_username | default('') | length > 0
```

### In Templates

Use in Jinja2 templates:

```jinja2
{% if github_username | default('') | length > 0 %}
# GitHub User: {{ github_username }}
{% endif %}
```

## Manual Configuration

### Set via Command Line

```bash
# Create config directory
mkdir -p ~/.config/zoolandia

# Set username
echo "your-github-username" > ~/.config/zoolandia/github_username
```

### Clear Username

```bash
rm ~/.config/zoolandia/github_username
```

### View Current Username

```bash
cat ~/.config/zoolandia/github_username
```

## Environment Variable

The username is also available as a shell variable after Zoolandia loads:

```bash
echo $GITHUB_USERNAME
```

## Integration with VS Code Tunnel

When installing VS Code Tunnel via Ansible, the GitHub username provides:

1. **Pre-authentication guidance**: Shows which account to use
2. **Documentation**: Includes username in setup instructions
3. **Verification**: Confirms the correct account during setup

### Example Output

```
VS CODE TUNNEL SETUP:
  GitHub Account: your-username

  1. Run: code tunnel --accept-server-license-terms
  2. Follow device login prompts (login as your-username)
  3. Press Ctrl+C after authentication
  4. Start service: sudo systemctl start code-tunnel
```

## Troubleshooting

### Username Not Detected

If Zoolandia doesn't detect your saved username:

1. Check the file exists:
   ```bash
   ls -la ~/.config/zoolandia/github_username
   ```

2. Verify file contents:
   ```bash
   cat ~/.config/zoolandia/github_username
   ```

3. Check file permissions:
   ```bash
   chmod 644 ~/.config/zoolandia/github_username
   ```

### Invalid Username Error

If you receive a validation error:

1. Check your GitHub profile: https://github.com/settings/profile
2. Ensure you're using your username, not display name
3. Verify the username follows GitHub's rules

## Security Notes

- Your GitHub username is **not sensitive** - it's publicly visible on GitHub
- No passwords or tokens are stored
- The configuration file has standard user permissions
- Only the username string is stored, no additional metadata

## Related Documentation

- [VS Code Tunnel Setup](../ansible/roles/appserver/README.md)
- [Ansible Playbooks](../ansible/README.md)
- [Prerequisites Guide](./PREREQUISITES.md)
