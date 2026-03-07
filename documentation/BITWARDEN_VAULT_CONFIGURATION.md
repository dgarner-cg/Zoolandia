# Bitwarden and HashiCorp Vault Configuration Guide

## Overview

Zoolandia supports triple storage for database passwords and credentials:

1. **File Storage** (MANDATORY) - `~/.zoolandia/credentials.txt`
2. **Bitwarden** (OPTIONAL) - Encrypted password vault
3. **HashiCorp Vault** (OPTIONAL) - Enterprise secret management

This guide explains how to configure Bitwarden CLI and HashiCorp Vault for use with Zoolandia.

---

## Option 1: Bitwarden CLI Configuration

### Prerequisites
- Bitwarden account (create at https://bitwarden.com)
- Bitwarden CLI installed

### Installation

#### Method 1: Snap (Recommended for Ubuntu)
```bash
sudo snap install bw
```

#### Method 2: NPM
```bash
sudo npm install -g @bitwarden/cli
```

#### Method 3: Download Binary
```bash
# Download latest release
curl -L "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o bw.zip

# Extract
unzip bw.zip

# Make executable and move to PATH
chmod +x bw
sudo mv bw /usr/local/bin/
```

### Configuration

#### Step 1: Login to Bitwarden
```bash
# If using self-hosted server
bw config server https://your-bitwarden-server.com

# Login (will prompt for password)
bw login your-email@example.com
```

#### Step 2: Unlock Vault
```bash
# Unlock vault and export session key
export BW_SESSION="$(bw unlock --raw)"

# Add to ~/.bashrc for persistence (INSECURE - not recommended for production)
echo 'export BW_SESSION="$(bw unlock --raw)"' >> ~/.bashrc
```

**IMPORTANT SECURITY NOTE:** Storing the session key in `~/.bashrc` is convenient but insecure. For production use, unlock manually each session or use a secure credential manager.

#### Step 3: Verify Configuration
```bash
# Test if Bitwarden is accessible
bw status

# Should show:
# {"serverUrl":"https://...","lastSync":"...","userEmail":"...","status":"unlocked"}

# List items (should work if configured correctly)
bw list items --search Zoolandia
```

#### Step 4: Create Zoolandia Folder (Optional)
```bash
# Create a folder for Zoolandia credentials
bw get template folder | jq '.name="Zoolandia"' | bw encode | bw create folder

# Or via web interface:
# 1. Login to https://vault.bitwarden.com
# 2. Click "New" > "Folder"
# 3. Name it "Zoolandia"
```

### Usage in Zoolandia

When Zoolandia detects `bw` command is available and you have an active session, it will automatically offer to store passwords in Bitwarden:

```
Generate password for PostgreSQL? (Y/n): y
✓ Saved to: /home/user/.zoolandia/credentials.txt

Store in Bitwarden vault? (Y/n): y
✓ Stored in Bitwarden: Zoolandia PostgreSQL
```

### Troubleshooting

**Problem:** `bw` command not found
```bash
# Check if installed
which bw

# If using snap, ensure /snap/bin is in PATH
echo 'export PATH="$PATH:/snap/bin"' >> ~/.bashrc
source ~/.bashrc
```

**Problem:** Vault is locked
```bash
# Unlock vault
bw unlock

# Then export the session key shown in the output
export BW_SESSION="your-session-key-here"
```

**Problem:** "Not logged in"
```bash
# Login again
bw login your-email@example.com
```

---

## Option 2: HashiCorp Vault Configuration

### Prerequisites
- HashiCorp Vault installed
- Vault server running (dev mode or production)

### Installation

#### Install via Zoolandia (Recommended)
```bash
# From Zoolandia menu:
./zoolandia.sh
# Navigate to: Ansible > HashiCorp Stack > Check "vault" > Install
```

#### Install via Ansible Directly
```bash
cd /home/cicero/Documents/Zoolandia/ansible
ansible-playbook playbooks/hashicorp.yml --tags "vault"
```

#### Manual Installation
```bash
# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Add HashiCorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Install Vault
sudo apt-get update && sudo apt-get install vault

# Enable autocomplete
vault -autocomplete-install
```

### Configuration

#### Option A: Dev Server (Testing Only)
```bash
# Start Vault in dev mode (NOT for production!)
vault server -dev

# In another terminal, set environment variables
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='your-root-token-from-dev-server-output'

# Test connection
vault status
```

#### Option B: Production Server

**Step 1: Start Vault Server**
```bash
# Create Vault configuration
sudo mkdir -p /etc/vault.d
sudo tee /etc/vault.d/vault.hcl <<EOF
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

api_addr = "http://127.0.0.1:8200"
ui = true
EOF

# Create data directory
sudo mkdir -p /opt/vault/data
sudo chown -R vault:vault /opt/vault

# Start Vault service
sudo systemctl enable vault
sudo systemctl start vault
```

**Step 2: Initialize Vault**
```bash
# Set Vault address
export VAULT_ADDR='http://127.0.0.1:8200'

# Initialize Vault (SAVE THE OUTPUT!)
vault operator init

# Output will show:
# Unseal Key 1: ...
# Unseal Key 2: ...
# Unseal Key 3: ...
# Unseal Key 4: ...
# Unseal Key 5: ...
#
# Initial Root Token: ...

# IMPORTANT: Save these keys securely!
```

**Step 3: Unseal Vault**
```bash
# Unseal with 3 of the 5 unseal keys
vault operator unseal <unseal-key-1>
vault operator unseal <unseal-key-2>
vault operator unseal <unseal-key-3>
```

**Step 4: Login**
```bash
# Login with root token
vault login <root-token>
```

**Step 5: Enable userpass Authentication**
```bash
# Enable userpass auth method
vault auth enable userpass

# Create a user
vault write auth/userpass/users/zoolandia \
    password=SecurePassword123 \
    policies=zoolandia-policy

# Create policy for Zoolandia
vault policy write zoolandia-policy - <<EOF
path "secret/zoolandia/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
```

**Step 6: Test Authentication**
```bash
# Login as the zoolandia user
vault login -method=userpass username=zoolandia password=SecurePassword123

# Test writing a secret
vault kv put secret/zoolandia/test username=test password=test123

# Test reading a secret
vault kv get secret/zoolandia/test
```

**Step 7: Configure for Zoolandia**
```bash
# Add to ~/.bashrc or ~/.profile
echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
source ~/.bashrc
```

### Usage in Zoolandia

When Zoolandia detects `$VAULT_ADDR` is set and `vault` command is available, it will automatically offer to store passwords in Vault:

```
Generate password for PostgreSQL? (Y/n): y
✓ Saved to: /home/user/.zoolandia/credentials.txt

Store in Bitwarden vault? (Y/n): n

Store in HashiCorp Vault? (Y/n): y
Vault authentication required...
Vault Username: zoolandia
Vault Password: [hidden]
✓ Stored in Vault: secret/zoolandia/postgresql
```

### Troubleshooting

**Problem:** "Error checking seal status: Get \"http://127.0.0.1:8200/v1/sys/seal-status\": dial tcp 127.0.0.1:8200: connect: connection refused"
```bash
# Vault server is not running
sudo systemctl status vault
sudo systemctl start vault
```

**Problem:** "Error making API request. Code: 503. Errors: * Vault is sealed"
```bash
# Unseal Vault with 3 unseal keys
vault operator unseal <key-1>
vault operator unseal <key-2>
vault operator unseal <key-3>
```

**Problem:** "permission denied"
```bash
# Login again
vault login -method=userpass username=zoolandia
```

**Problem:** "$VAULT_ADDR not set"
```bash
# Set Vault address
export VAULT_ADDR='http://127.0.0.1:8200'

# Add to ~/.bashrc for persistence
echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
source ~/.bashrc
```

---

## Security Best Practices

### For Bitwarden:
1. **Never store `$BW_SESSION` in plain text in `.bashrc`** - This is insecure
2. **Use a master password manager** - Let your OS keychain unlock Bitwarden
3. **Enable 2FA** - Add two-factor authentication to your Bitwarden account
4. **Regular backups** - Export your vault periodically
5. **Use strong master password** - At least 16 characters with mixed case, numbers, symbols

### For HashiCorp Vault:
1. **Never use dev mode in production** - Dev mode stores data in memory and uses a root token
2. **Secure unseal keys** - Store the 5 unseal keys in different secure locations
3. **Rotate tokens regularly** - Don't use the root token for daily operations
4. **Use TLS in production** - Always enable TLS (`tls_disable = 0`)
5. **Implement backup strategy** - Regularly backup Vault data
6. **Monitor audit logs** - Enable and review Vault audit logs
7. **Use Authentik/OIDC** - Integrate with Authentik for SSO (long-term goal)

---

## Credential Storage Flow

When Zoolandia generates a database password, it follows this flow:

```
1. Generate 24-character random password
   ↓
2. Save to ~/.zoolandia/credentials.txt (ALWAYS)
   ↓
3. Prompt: "Store in Bitwarden?" (if `bw` available)
   ↓ YES
   └→ Store in Bitwarden folder "Zoolandia"
   ↓
4. Prompt: "Store in HashiCorp Vault?" (if $VAULT_ADDR set)
   ↓ YES
   └→ Authenticate with userpass
   └→ Store at secret/zoolandia/{service}
```

---

## Retrieving Stored Credentials

### From File
```bash
cat ~/.zoolandia/credentials.txt | grep PostgreSQL
```

### From Bitwarden
```bash
# Unlock vault first
export BW_SESSION="$(bw unlock --raw)"

# Search for credential
bw list items --search "Zoolandia PostgreSQL"

# Get password directly
bw get password "Zoolandia PostgreSQL"
```

### From HashiCorp Vault
```bash
# Login first
vault login -method=userpass username=zoolandia

# Get credential
vault kv get secret/zoolandia/postgresql

# Get password field only
vault kv get -field=password secret/zoolandia/postgresql
```

---

## Additional Resources

### Bitwarden
- Official Documentation: https://bitwarden.com/help/
- CLI Documentation: https://bitwarden.com/help/cli/
- Self-hosting Guide: https://bitwarden.com/help/install-on-premise-linux/

### HashiCorp Vault
- Official Documentation: https://www.vaultproject.io/docs
- Getting Started: https://learn.hashicorp.com/vault
- Production Hardening: https://learn.hashicorp.com/tutorials/vault/production-hardening
- Authentik Integration (future): https://goauthentik.io/integrations/services/hashicorp-vault/

---

## Support

For issues or questions:
1. Check the troubleshooting sections above
2. Review Zoolandia logs: `~/.zoolandia/logs/`
3. Open an issue: https://github.com/[your-repo]/Zoolandia/issues
