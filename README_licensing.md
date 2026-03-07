# Zoolandia Licensing System

> Operator reference for the Ed25519 offline license key system.
> Version: 6.1.3 | Last updated: March 7, 2026

---

## Overview

Zoolandia uses **Ed25519-signed offline license keys** — no internet connection is required
to validate a license after activation. The public key is embedded in `modules/license.sh`;
the private key lives in `.signing/` (gitignored, operator-only).

```
You (operator)           User's machine
─────────────────        ──────────────────────────────────────
zl-sign.sh ──key──►  ZOOL-<payload>.<signature>
                              │
                              ▼
                     Settings > License > Activate
                              │
                              ▼
                     modules/license.sh verifies signature
                     against embedded public key (offline)
                              │
                              ▼
                     Feature gate passes or shows upgrade dialog
```

---

## License Key Format

```
ZOOL-<base64url(JSON payload)>.<base64url(Ed25519 signature)>
```

**Payload fields (JSON, compact, deterministic):**
```json
{
  "v": 1,
  "email": "user@example.com",
  "tier": "pro",
  "features": ["traefik", "authelia", "authentik", "security", "vpn"],
  "issued": "2026-03-07",
  "expires": "2027-03-07"
}
```

Base64url encoding: standard base64 with `+→-`, `/→_`, padding stripped.
The signature covers the raw JSON bytes (Ed25519 performs its own hashing — do not pre-hash).

---

## Tiers & Features

| Feature      | Starter | Pro | Enterprise |
|--------------|:-------:|:---:|:----------:|
| `traefik`    | yes     | yes | yes        |
| `authelia`   | yes     | yes | yes        |
| `authentik`  |         | yes | yes        |
| `security`   |         | yes | yes        |
| `vpn`        |         | yes | yes        |
| `ansible`    |         |     | yes        |
| `multi-node` |         |     | yes        |

---

## Operator: Issuing License Keys

All signing tools live in `.signing/` (gitignored).

### CLI — `zl-sign.sh`

```bash
cd .signing

# Standard license (365 days, tier defaults)
./zl-sign.sh --email user@example.com --tier pro --days 365

# Custom feature set
./zl-sign.sh --email user@example.com --tier pro \
  --features "traefik,authelia,authentik" --days 365

# Save key directly to a file
./zl-sign.sh --email user@example.com --tier starter --days 365 --out /tmp/key.txt

# Test: pre-expired key (negative days)
./zl-sign.sh --email test@local.dev --tier pro --days -1

# Enterprise, 2 years
./zl-sign.sh --email enterprise@client.com --tier enterprise --days 730
```

**Options:**

| Flag | Required | Description |
|------|----------|-------------|
| `--email` | yes | Licensee email |
| `--tier` | yes | `starter` \| `pro` \| `enterprise` |
| `--features` | no | Override tier defaults (comma-separated) |
| `--days` | no | Days until expiry (default: 365; negative = already expired) |
| `--key` | no | Path to private key (default: `./zoolandia_license_priv.pem`) |
| `--out` | no | Save key to file instead of printing to stdout |

---

## Debug/Test Server

The local web server lets you sign and validate keys through a browser UI —
useful for testing the full flow before connecting a payment processor.

All files are in `.signing/`:
- `license-server.py` — Python stdlib server (zero external dependencies)
- `license-server.sh` — start/stop/restart/status wrapper

### Starting and Stopping

```bash
cd .signing

# Start on default port 8765
./license-server.sh --start

# Start on a custom port
./license-server.sh --start --port 9000

# Check if running
./license-server.sh --status

# Stop the server
./license-server.sh --stop

# Restart (e.g. after updating license-server.py)
./license-server.sh --restart
```

When started, the server prints:
```
License server started
  URL:  http://localhost:8765
  PID:  12345
  Log:  /path/to/.signing/.license-server.log
```

### Web UI

Open `http://localhost:8765` in a browser. The UI has two tabs:

**Issue** — generate a new license key:
1. Enter email, select tier, adjust features/days if needed
2. Click **Generate**
3. Copy the resulting `ZOOL-...` key

**Validate** — verify an existing key:
1. Paste the `ZOOL-...` key
2. Click **Validate**
3. See decoded payload and signature status

### Server Files

| File | Purpose |
|------|---------|
| `.signing/.license-server.pid` | PID of running server process |
| `.signing/.license-server.log` | Accumulated server logs |

View logs: `cat .signing/.license-server.log`
Tail logs live: `tail -f .signing/.license-server.log`

### Direct Python invocation (advanced)

```bash
python3 .signing/license-server.py \
  --port 8765 \
  --key .signing/zoolandia_license_priv.pem \
  --pub .signing/zoolandia_public.pem
```

---

## User: Activating a License

### Via Settings UI (recommended)

1. Launch Zoolandia: `sudo ./zoolandia.sh`
2. Navigate: **Settings > License > Activate**
3. Paste the `ZOOL-...` key when prompted
4. Confirmation shows email, tier, expiry, and features

### Via CLI (advanced)

```bash
# Place key in the license file directly
mkdir -p .license
echo "ZOOL-<your-key>" > .license/license.key
chmod 600 .license/license.key
```

### License Storage

Active license key is stored at:
```
<zoolandia-dir>/.license/license.key
```
- Directory: `chmod 700`
- File: `chmod 600`
- Listed in `.gitignore` — never committed

---

## Settings Menu — License Management

**Settings > License** provides three options:

| Option | Action |
|--------|--------|
| **Activate** | Prompt for key, validate signature, save to `.license/license.key` |
| **Validate** | Re-read current key, show decoded details (email, tier, expiry, features) |
| **Remove** | Confirmation dialog, then deletes `.license/license.key` |

The Settings menu header always shows current license status:
- `Active (pro) — user@example.com — expires 2027-03-07`
- `No license installed`
- `Expired — user@example.com`

---

## Feature Gating

Functions are gated by adding one line at the top:

```bash
my_gated_function() {
    zl_require_license "traefik" "Reverse Proxy / DNS Provider" || return 0
    # ... rest of function
}
```

**Currently gated:**
- `configure_dns_provider()` in `modules/13_reverse_proxy.sh` — requires `traefik`

**Error dialogs shown to users:**

| Situation | Message |
|-----------|---------|
| No license | "This feature requires a Zoolandia license. Tier: Starter or higher." |
| Expired | "Your license has expired. Please renew at hack3r.gg/license" |
| Wrong tier | "Your current tier (starter) does not include this feature. Upgrade at hack3r.gg/license" |

---

## Relevant Files

```
zoolandia/
├── modules/
│   ├── license.sh              # Core validation module (embedded public key)
│   ├── 13_reverse_proxy.sh     # configure_dns_provider() — gated
│   └── 40_settings.sh          # show_license_menu()
├── .signing/                   # gitignored — operator only
│   ├── zoolandia_license_priv.pem  # Ed25519 private key (chmod 600)
│   ├── zoolandia_public.pem        # Ed25519 public key
│   ├── zl-sign.sh                  # CLI signing tool
│   ├── license-server.py           # Debug web server
│   └── license-server.sh           # Server start/stop wrapper
├── .license/                   # gitignored — runtime
│   └── license.key             # Active user license (chmod 600)
└── README_licensing.md         # This file
```

---

## Key Generation (one-time setup)

If you need to regenerate the key pair (e.g., after a security incident):

```bash
cd .signing

# Generate new Ed25519 private key
openssl genpkey -algorithm ed25519 -out zoolandia_license_priv.pem
chmod 600 zoolandia_license_priv.pem

# Extract public key
openssl pkey -in zoolandia_license_priv.pem -pubout -out zoolandia_public.pem
```

Then update the embedded public key in `modules/license.sh`:
```bash
cat .signing/zoolandia_public.pem
# Copy the contents (including -----BEGIN/END----- lines)
# Paste into the ZL_PUBLIC_KEY variable in modules/license.sh
```

> **Warning:** Rotating the key invalidates all previously issued license keys.
> All existing users would need new keys.

---

## Future: Payment Processor Integration

When connecting Gumroad, LemonSqueezy, or similar:

1. Set up a webhook endpoint on your server
2. Map product → tier in the webhook handler
3. On purchase event, call:
   ```bash
   ./zl-sign.sh --email "$BUYER_EMAIL" --tier "$TIER" --days 365 > key.txt
   ```
4. Email `key.txt` contents to the buyer (or display in post-purchase UI)

No changes are needed to `modules/license.sh` — validation is already production-ready.
