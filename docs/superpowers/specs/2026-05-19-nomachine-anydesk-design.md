# NoMachine and AnyDesk via Ansible — Design

**Date:** 2026-05-19
**Scope:** Add NoMachine and AnyDesk remote-access clients to the Ansible workstation role and expose them in `ansible-menu.sh`.

## Goal

Allow users to opt into installing NoMachine and/or AnyDesk via the existing interactive menu, following the project's complex-app pattern (block + rescue + always, with audit logging and cleanup).

## Decisions

- **Default state:** Both `install_nomachine` and `install_anydesk` default to `false`. Users opt in via the checklist menu (matches Twingate/ProtonVPN convention for remote-access tooling).
- **Install methods:**
  - **AnyDesk** — official apt repo with GPG key (auto-updates via apt; cleanest path).
  - **NoMachine** — direct `.deb` download from `download.nomachine.com` (their only official channel; URL is version-stamped so it lives in `defaults/main.yml` as an overridable variable).

## New files

### `ansible/roles/workstation/tasks/applications/complex/nomachine.yml`
- Skip if `dpkg -l nomachine` already returns installed.
- Download `nomachine.deb_url` into `{{ temp_download_dir }}` with retries/timeout from `error_handling`.
- Install via `ansible.builtin.apt: deb: <path>`.
- Verify by re-running `dpkg -l nomachine`.
- Audit-log success/failure to `logging.audit_trail`.
- `rescue`: record failure in `workstation_failures`.
- `always`: remove the downloaded `.deb`.
- Tags: `nomachine`, `complex`, `applications`, `remote-access`.
- `when: install_nomachine | default(false)`.

### `ansible/roles/workstation/tasks/applications/complex/anydesk.yml`
- Skip if `dpkg -l anydesk` already returns installed.
- Ensure `/etc/apt/keyrings` exists.
- Fetch GPG key from `anydesk.gpg_url` and dearmor to `anydesk.keyring_path` (`/etc/apt/keyrings/anydesk.gpg`).
- Add apt repo via `ansible.builtin.apt_repository` using `anydesk.repo_line` with `signed-by={{ anydesk.keyring_path }}`.
- `apt update` then install `anydesk.package_name`.
- Audit-log success/failure; `rescue` and `always` blocks mirror ProtonVPN.
- Tags: `anydesk`, `complex`, `applications`, `remote-access`.
- `when: install_anydesk | default(false)`.

## Modified files

### `ansible/roles/workstation/tasks/main.yml`
Add two `include_tasks` entries grouped with Twingate/ProtonVPN:

```yaml
- name: Include NoMachine installation
  ansible.builtin.include_tasks: applications/complex/nomachine.yml
  when: install_nomachine | default(false)
  tags: ['applications', 'nomachine', 'remote-access', 'complex']

- name: Include AnyDesk installation
  ansible.builtin.include_tasks: applications/complex/anydesk.yml
  when: install_anydesk | default(false)
  tags: ['applications', 'anydesk', 'remote-access', 'complex']
```

### `ansible/roles/workstation/defaults/main.yml`
In the "APPLICATION SELECTION — COMPLEX APPS" block:

```yaml
install_nomachine: false
install_anydesk: false
```

Add new config blocks alongside `protonvpn:` / `twingate:`:

```yaml
# NoMachine configuration (remote-desktop client)
nomachine:
  deb_url: "https://download.nomachine.com/download/8.16/Linux/nomachine_8.16.1_1_amd64.deb"
  package_name: "nomachine"

# AnyDesk configuration (remote-desktop client)
anydesk:
  gpg_url: "https://keys.anydesk.com/repos/DEB-GPG-KEY"
  keyring_path: "/etc/apt/keyrings/anydesk.gpg"
  repo_line: "deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main"
  package_name: "anydesk"
```

> The NoMachine `deb_url` will need to be bumped when NoMachine ships a new version. The variable is exposed in defaults so it's easy to override without editing the task file.

### `ansible/ansible-menu.sh`
Three additions:

1. **`detect_installed_apps()`** — append:
   ```bash
   dpkg -l nomachine 2>/dev/null | grep -q "^ii" && installed_apps+="nomachine "
   dpkg -l anydesk 2>/dev/null | grep -q "^ii" && installed_apps+="anydesk "
   ```

2. **`show_selection_menu()`** — add two checklist entries near Twingate/ProtonVPN:
   ```bash
   "nomachine" "NoMachine Remote Desktop" $(is_installed "nomachine") \
   "anydesk"   "AnyDesk Remote Desktop"   $(is_installed "anydesk") \
   ```
   Also bump the dialog's list-height parameter (`38` → `40`) to fit the new rows.

3. **`generate_config_from_selections()`** — in the COMPLEX APPLICATIONS section:
   ```bash
   if [[ "$selections" == *"nomachine"* ]]; then echo "install_nomachine: true"  >> "$CONFIG_FILE"
   else                                          echo "install_nomachine: false" >> "$CONFIG_FILE"; fi
   if [[ "$selections" == *"anydesk"* ]]; then   echo "install_anydesk: true"    >> "$CONFIG_FILE"
   else                                          echo "install_anydesk: false"   >> "$CONFIG_FILE"; fi
   ```

## Out of scope

- No changes to system-config or security-tool sections of the menu.
- No checksum verification for the NoMachine `.deb` (the existing pattern leaves `verify_checksum` as a TODO across the repo; consistent with Twingate).
- No headless-server-mode tuning for NoMachine; this installs the standard desktop client.

## Verification

Manual smoke test after implementation:
- `ansible-playbook workstations.yml --check -e install_nomachine=true -e install_anydesk=true` — should plan without errors.
- `./ansible-menu.sh` → Custom Selection → confirm NoMachine and AnyDesk checkboxes render and toggle correctly.
- Actual install on a test box: confirm `nomachine` and `anydesk` are present in `dpkg -l`.
