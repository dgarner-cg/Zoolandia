# NoMachine & AnyDesk — Ansible Install Options

Adds opt-in installation of two remote-desktop clients — **NoMachine** and **AnyDesk** —
to the Nexus workstation Ansible role, and exposes them in the interactive install menu.

This folder is a self-contained record of that work so it can be picked up and
modified later.

## Folder contents

| File | Purpose |
|------|---------|
| `README.md` | This file — overview, how it works, how to modify. |
| `design-spec.md` | The approved design spec (copy of `docs/superpowers/specs/2026-05-19-nomachine-anydesk-design.md`). |
| `stdout.log` | Full transcript of the chat session that produced this feature. |
| `chat_export.py` | Script that regenerates `stdout.log` from a Claude Code session transcript. |

## What changed in the repo

### New files
- `ansible/roles/workstation/tasks/applications/complex/nomachine.yml`
  Downloads the official NoMachine `.deb` and installs it via `apt`.
- `ansible/roles/workstation/tasks/applications/complex/anydesk.yml`
  Registers the official AnyDesk apt repo (signed GPG key) and installs the `anydesk` package.

### Modified files
- `ansible/roles/workstation/tasks/main.yml`
  Two `include_tasks` entries added, gated on `install_nomachine` / `install_anydesk`.
- `ansible/roles/workstation/defaults/main.yml`
  Toggles `install_nomachine: false` / `install_anydesk: false`, plus `nomachine:` and
  `anydesk:` config blocks.
- `ansible/ansible-menu.sh`
  Installed-app detection, two new checklist rows, config generation, checklist height bump.

## How it works

Both apps are **opt-in** (default `false`), matching Twingate/ProtonVPN. They are
installed only when explicitly selected, via either:

- **Interactive menu** — `./ansible/ansible-menu.sh` → *Custom Selection* → check
  *NoMachine Remote Desktop* and/or *AnyDesk Remote Desktop*.
- **Direct extra-vars** — `ansible-playbook workstations.yml -e install_nomachine=true -e install_anydesk=true`

| App | Install method | Why |
|-----|----------------|-----|
| AnyDesk | Official apt repo (`deb.anydesk.com`) with signed GPG key | Auto-updates through `apt`. |
| NoMachine | Direct `.deb` download from `download.nomachine.com` | Their only official distribution channel. |

Each task file follows the project's complex-app pattern: `block` / `rescue` / `always`,
idempotency check via `dpkg -l`, audit logging to `logging.audit_trail`, failure
collection into `workstation_failures`, and temp-file cleanup.

## How to modify

- **Bump the NoMachine version:** edit `nomachine.deb_url` in
  `ansible/roles/workstation/defaults/main.yml` (the URL is version-stamped — currently
  pinned to `8.16.1`). No task-file change needed.
- **Change the AnyDesk repo/key:** edit the `anydesk:` block in the same defaults file.
- **Make either default-on:** flip `install_nomachine` / `install_anydesk` to `true` in
  defaults so they install with "Install All".
- **Menu wording/placement:** edit the `nomachine` / `anydesk` rows in
  `show_selection_menu()` inside `ansible/ansible-menu.sh`.

## Verification

```bash
# Plan only — should report no errors
ansible-playbook ansible/workstations.yml --check \
  -e install_nomachine=true -e install_anydesk=true

# After a real run
dpkg -l nomachine anydesk
```

## Regenerating stdout.log

Session transcripts live at
`~/.claude/projects/-home-cicero-proj-zoolandia/<session-id>.jsonl`.

```bash
python3 chat_export.py <session-id>.jsonl stdout.log
```

## Status

Implementation complete; syntax-verified (`bash -n`, YAML parse). Not yet committed —
git identity was not configured at the time of writing. Run a real `--check` and an
install on a test box before relying on it.
