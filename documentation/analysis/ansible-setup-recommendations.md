# Ansible Setup.yml - Improvement Recommendations

**File:** `ansible/roles/common/playbooks/setup.yml`
**Analysis Date:** 2025-12-30
**DeployIQ Version:** v5.10

## Executive Summary

The current `setup.yml` playbook provides functional workstation onboarding but has several areas for improvement related to maintainability, security, flexibility, and user experience. This document provides prioritized recommendations for enhancement.

---

## Critical Issues (High Priority)

### 1. Hardcoded Username Throughout Playbook

**Current State:**
- Username `dgarner` appears in 11+ tasks
- User ID `1000` hardcoded in DBUS paths
- Home directory `/home/dgarner` hardcoded

**Impact:**
- Playbook cannot be used by other users without modification
- Makes playbook non-portable and error-prone

**Recommendation:**
```yaml
vars:
  target_user: "{{ ansible_user_id }}"
  target_home: "{{ ansible_env.HOME }}"
  target_uid: "{{ ansible_user_uid }}"
```

**Implementation:**
- Replace all instances of `dgarner` with `{{ target_user }}`
- Replace `/home/dgarner` with `{{ target_home }}`
- Replace `1000` with `{{ target_uid }}`
- Allow override via extra vars: `ansible-playbook setup.yml -e "target_user=john"`

**Effort:** Medium | **Benefit:** High

---

### 2. Conflicting Power Management Settings

**Current State:**
Lines 599-604 set lid close action to 'suspend', then lines 607-613 immediately overwrite to 'hibernate'

**Impact:**
- Configuration is confusing and unclear about intended behavior
- First set of tasks (suspend) is effectively dead code

**Recommendation:**
```yaml
vars:
  power_lid_close_ac_action: "hibernate"  # or "suspend" or "nothing"
  power_lid_close_battery_action: "hibernate"
  power_sleep_timeout_ac: 0  # 0 = never, or minutes
  power_sleep_timeout_battery: 0

tasks:
  - name: Configure lid close action (AC)
    command: >
      sudo -u {{ target_user }}
      gsettings set org.gnome.settings-daemon.plugins.power
      lid-close-ac-action '{{ power_lid_close_ac_action }}'
    ignore_errors: true
```

**Remove duplicate tasks and make the settings configurable via variables.**

**Effort:** Low | **Benefit:** High

---

### 3. Security Concern: Piping curl to bash (Twingate)

**Current State:**
```yaml
shell: curl -s https://binaries.twingate.com/client/linux/install.sh | sudo bash
```

**Impact:**
- Executes remote script without verification
- No checksum validation
- Security vulnerability (MITM attacks possible)
- Violates security best practices

**Recommendation:**
```yaml
- name: Download Twingate installation script
  get_url:
    url: "https://binaries.twingate.com/client/linux/install.sh"
    dest: /tmp/twingate-install.sh
    mode: '0755'
    checksum: "sha256:EXPECTED_CHECKSUM_HERE"  # Update with actual checksum
  when: twingate_check.rc != 0

- name: Review and execute Twingate installation script
  command: bash /tmp/twingate-install.sh
  when: twingate_check.rc != 0

- name: Remove Twingate installation script
  file:
    path: /tmp/twingate-install.sh
    state: absent
```

**Effort:** Low | **Benefit:** High (Security)

---

### 4. No Application Selection Mechanism

**Current State:**
- All applications are installed regardless of user needs
- No way to skip unwanted applications
- Wastes time and disk space

**Impact:**
- Users cannot customize which applications to install
- Increased installation time
- Unnecessary bloat for users who don't need all apps

**Recommendation:**

**Option A: Tags-based approach**
```yaml
- name: Install Vivaldi using Snap
  tags: ['apps', 'browsers', 'vivaldi']
  block:
    # ... existing code
```

Usage: `ansible-playbook setup.yml --tags "browsers,security"`

**Option B: Variables-based approach**
```yaml
vars:
  install_apps:
    vivaldi: true
    discord: true
    zoom: false  # Skip zoom
    # ... etc

- name: Install Vivaldi using Snap
  when: install_apps.vivaldi | default(true)
  block:
    # ... existing code
```

**Option C: Prompt user (interactive)**
```yaml
vars_prompt:
  - name: install_browsers
    prompt: "Install web browsers (Vivaldi)? [yes/no]"
    default: "yes"
    private: false
```

**Recommendation:** Combine Option A (tags) with Option B (variables) for maximum flexibility.

**Effort:** Medium | **Benefit:** Very High

---

## Important Issues (Medium Priority)

### 5. Deprecated `command` Module Usage

**Current State:**
Multiple tasks use `command:` module without fully qualified collection name

**Impact:**
- Will break in future Ansible versions
- Deprecation warnings in output

**Recommendation:**
Replace `command:` with `ansible.builtin.command:` or use more specific modules:
- Use `gsettings` module if available
- Use `ansible.builtin.systemd` instead of `command: systemctl`
- Specify `ansible.builtin.command` for clarity

**Effort:** Low | **Benefit:** Medium (Future-proofing)

---

### 6. Insufficient Pre-flight Checks

**Current State:**
- No disk space verification before installation
- No network connectivity checks
- No verification of system prerequisites

**Impact:**
- Installations may fail mid-process due to insufficient space
- Users get cryptic errors without understanding root cause

**Recommendation:**
Add pre-flight validation tasks:

```yaml
- name: Pre-flight checks
  block:
    - name: Check available disk space
      shell: df -BG / | tail -1 | awk '{print $4}' | sed 's/G//'
      register: disk_space
      failed_when: false

    - name: Fail if insufficient disk space
      fail:
        msg: "Insufficient disk space. Required: 10GB, Available: {{ disk_space.stdout }}GB"
      when: disk_space.stdout | int < 10

    - name: Check internet connectivity
      uri:
        url: https://www.google.com
        timeout: 5
      register: internet_check
      failed_when: false

    - name: Warn if no internet connectivity
      debug:
        msg: "WARNING: No internet connectivity detected. Downloads may fail."
      when: internet_check.failed

    - name: Verify snap is installed
      command: which snap
      register: snap_check
      failed_when: false

    - name: Install snapd if missing
      apt:
        name: snapd
        state: present
      when: snap_check.rc != 0
```

**Effort:** Medium | **Benefit:** High (User experience)

---

### 7. Fixed Version URLs and No Version Pinning

**Current State:**
- Many downloads use "latest" or unversioned URLs
- No version verification
- Inconsistent between "stable" and "latest"

**Examples:**
- ProtonVPN: Hardcoded version `1.0.4` (may be outdated)
- Portainer: `portainer/portainer-ee:latest` (version drift)
- n8n: `n8nio/n8n:latest` (version drift)

**Impact:**
- Installations may break if URLs change
- Difficult to reproduce identical environments
- Version drift between installations
- Security concerns with always-latest

**Recommendation:**
```yaml
vars:
  app_versions:
    protonvpn_repo_version: "1.0.4"
    portainer_version: "latest"  # or specific like "2.19.4"
    n8n_version: "1.18.0"  # Specific version
    discord_version: "0.0.40"  # Track versions
    # ... etc

- name: Download Discord .deb package
  get_url:
    url: "https://discord.com/api/download/{{ app_versions.discord_version }}/discord-{{ app_versions.discord_version }}.deb"
    dest: /tmp/discord.deb
```

**Create a variables file to manage all versions in one place.**

**Effort:** High | **Benefit:** High (Maintainability, Reproducibility)

---

### 8. Minimal Post-Installation Verification

**Current State:**
- Most installations don't verify success beyond package manager return codes
- No functional verification (can the app actually run?)

**Impact:**
- Silent failures may go unnoticed
- Users may believe software is installed when it's not functional

**Recommendation:**
Add verification tasks after installation:

```yaml
- name: Verify Vivaldi installation
  command: snap info vivaldi
  register: vivaldi_verify
  failed_when: false
  changed_when: false

- name: Add to failures if Vivaldi not properly installed
  set_fact:
    failures: "{{ failures + ['Vivaldi verification failed'] }}"
  when: vivaldi_verify.rc != 0 or 'installed' not in vivaldi_verify.stdout

- name: Verify Docker is running
  systemd:
    name: docker
  register: docker_status
  failed_when: false

- name: Test Docker functionality
  command: docker run --rm hello-world
  register: docker_test
  failed_when: false
  when: docker_check.rc == 0
```

**Effort:** Medium | **Benefit:** Medium

---

### 9. Excessive Use of `ignore_errors: true`

**Current State:**
Nearly every task has `ignore_errors: true`

**Impact:**
- Masks genuine errors that should stop execution
- Makes debugging difficult
- Users may not realize critical failures occurred

**Recommendation:**
Be selective about error handling:

```yaml
# Don't ignore errors for critical infrastructure
- name: Install Docker prerequisites
  apt:
    name:
      - ca-certificates
      - curl
  # NO ignore_errors here - these are essential

# DO ignore errors for optional applications
- name: Install Notion (optional)
  snap:
    name: notion-snap-reborn
  ignore_errors: true
  register: notion_install

# Provide better error context
- name: Explain Notion failure
  debug:
    msg: |
      Notion installation failed. This is optional and won't affect other installations.
      Error: {{ notion_install.msg | default('Unknown error') }}
  when: notion_install.failed | default(false)
```

**Effort:** Medium | **Benefit:** Medium (Reliability)

---

### 10. No Rollback or Cleanup Mechanism

**Current State:**
- If playbook fails mid-execution, partial installations remain
- No easy way to undo changes
- Temporary files may not be cleaned up properly

**Impact:**
- System left in inconsistent state
- Re-running playbook may encounter conflicts

**Recommendation:**

**Option A: Add cleanup handlers**
```yaml
handlers:
  - name: cleanup temp files
    file:
      path: "{{ item }}"
      state: absent
    loop:
      - /tmp/discord.deb
      - /tmp/zoom_amd64.deb
      - /tmp/Termius.deb
      # ... etc

tasks:
  - name: Download Discord
    get_url:
      url: "..."
      dest: /tmp/discord.deb
    notify: cleanup temp files
```

**Option B: Use block-rescue-always**
```yaml
- name: Install Discord
  block:
    - name: Download Discord
      get_url:
        url: "..."
        dest: /tmp/discord.deb

    - name: Install Discord
      apt:
        deb: /tmp/discord.deb
  rescue:
    - name: Log Discord installation failure
      set_fact:
        failures: "{{ failures + ['Discord: ' + ansible_failed_result.msg] }}"
  always:
    - name: Clean up Discord .deb
      file:
        path: /tmp/discord.deb
        state: absent
```

**Effort:** Medium | **Benefit:** Medium

---

## Enhancement Opportunities (Low Priority)

### 11. Improve Progress Reporting

**Current State:**
- Limited user feedback during long-running installations
- No progress indicators
- Failure summary only at end

**Recommendation:**
```yaml
- name: Print installation progress
  debug:
    msg: |
      ========================================
      Installation Progress: {{ app_counter | default(0) }} / {{ total_apps }}
      Current: Installing {{ current_app_name }}
      Elapsed time: {{ installation_start_time | ansible_date_time_elapsed }}
      ========================================
  tags: ['always']

- name: Installation progress notification
  command: notify-send "DeployIQ Setup" "Installing {{ current_app_name }}..."
  become_user: "{{ target_user }}"
  when: ansible_env.DISPLAY is defined
  ignore_errors: true
```

**Effort:** Low | **Benefit:** Low (UX improvement)

---

### 12. Modularize into Separate Role Files

**Current State:**
- Single monolithic 659-line playbook
- Difficult to maintain and read
- NOTE: `setup_all.yml` exists but appears to reference incorrect paths

**Impact:**
- Hard to find specific application installations
- Difficult to reuse individual components
- Challenging to test individual applications

**Recommendation:**
The existing modular structure in `setup_all.yml` is the right approach, but needs fixes:

**Current (broken paths):**
```yaml
- name: Install Vivaldi
  include_tasks: ../../../../compose/vivaldi.yml  # Wrong path
```

**Corrected structure:**
```
ansible/
├── roles/
│   └── common/
│       ├── tasks/
│       │   ├── apps/
│       │   │   ├── vivaldi.yml
│       │   │   ├── discord.yml
│       │   │   ├── docker.yml
│       │   │   └── ...
│       │   ├── system/
│       │   │   ├── power_management.yml
│       │   │   ├── touchpad_settings.yml
│       │   │   └── package_update.yml
│       │   └── main.yml
│       └── playbooks/
│           ├── setup.yml (orchestrator)
│           └── setup_individual.yml
```

**Fixed setup.yml:**
```yaml
- name: Install Vivaldi
  include_tasks: ../tasks/apps/vivaldi.yml
  tags: ['apps', 'browsers', 'vivaldi']
```

**Effort:** High | **Benefit:** Very High (Maintainability)

---

### 13. Add Desktop Environment Detection

**Current State:**
- Assumes GNOME desktop environment
- Uses `gsettings` without checking if GNOME is installed
- May fail on KDE, XFCE, or other DEs

**Impact:**
- Playbook fails or has no effect on non-GNOME systems

**Recommendation:**
```yaml
- name: Detect desktop environment
  shell: echo $XDG_CURRENT_DESKTOP
  register: desktop_env
  changed_when: false
  failed_when: false

- name: Configure power management (GNOME)
  command: gsettings set ...
  when: "'GNOME' in desktop_env.stdout"

- name: Configure power management (KDE)
  command: kwriteconfig5 --file powermanagementprofilesrc ...
  when: "'KDE' in desktop_env.stdout"

- name: Skip power management configuration
  debug:
    msg: "Desktop environment {{ desktop_env.stdout }} not supported for power management"
  when: desktop_env.stdout not in ['GNOME', 'KDE']
```

**Effort:** Medium | **Benefit:** Medium (Compatibility)

---

### 14. Add Logging and Audit Trail

**Current State:**
- No persistent log of what was installed
- No timestamp records
- Hard to troubleshoot past installations

**Recommendation:**
```yaml
- name: Create installation log
  file:
    path: "{{ target_home }}/.deployiq/logs"
    state: directory
    owner: "{{ target_user }}"
    mode: '0755'

- name: Log installation start
  lineinfile:
    path: "{{ target_home }}/.deployiq/logs/setup.log"
    line: "[{{ ansible_date_time.iso8601 }}] Setup started by {{ ansible_user_id }}"
    create: true

- name: Log successful app installation
  lineinfile:
    path: "{{ target_home }}/.deployiq/logs/setup.log"
    line: "[{{ ansible_date_time.iso8601 }}] SUCCESS: {{ app_name }} installed"
  when: app_install_result.rc == 0

- name: Create installation manifest
  copy:
    content: |
      # DeployIQ Installation Manifest
      # Generated: {{ ansible_date_time.iso8601 }}
      # User: {{ ansible_user_id }}
      # Hostname: {{ ansible_hostname }}

      {% for app in installed_apps %}
      - {{ app.name }}: {{ app.version }} ({{ app.method }})
      {% endfor %}
    dest: "{{ target_home }}/.deployiq/manifest.yml"
```

**Effort:** Medium | **Benefit:** Low-Medium (Debugging)

---

### 15. Parallel Installation for Independent Apps

**Current State:**
- All installations run sequentially
- Total installation time is sum of all individual installations

**Impact:**
- Longer total installation time
- User waits unnecessarily

**Recommendation:**
Use Ansible's async and poll features for independent installations:

```yaml
- name: Install Snap applications in parallel
  snap:
    name: "{{ item }}"
    state: present
  loop:
    - vivaldi
    - notepad-plus-plus
    - notion-snap-reborn
    - bitwarden
    - mailspring
  async: 600  # 10 minute timeout per task
  poll: 0     # Don't wait, run in parallel
  register: snap_installs
  ignore_errors: true

- name: Wait for Snap installations to complete
  async_status:
    jid: "{{ item.ansible_job_id }}"
  register: snap_install_results
  until: snap_install_results.finished
  retries: 60
  delay: 10
  loop: "{{ snap_installs.results }}"
  when: item.ansible_job_id is defined
```

**Effort:** High | **Benefit:** Medium (Speed)

---

### 16. Add Idempotency Token/State File

**Current State:**
- Playbook can be run multiple times, rechecking everything
- No easy way to track "already completed" state
- Checks are done per-application but not globally

**Recommendation:**
```yaml
- name: Check if full setup already completed
  stat:
    path: "{{ target_home }}/.deployiq/setup_complete"
  register: setup_complete_file

- name: Skip if already completed
  debug:
    msg: "Setup already completed on {{ setup_complete_file.stat.mtime }}. Use --extra-vars 'force=true' to re-run."
  when: setup_complete_file.stat.exists and not (force | default(false))

- name: Run setup tasks
  when: not setup_complete_file.stat.exists or (force | default(false))
  block:
    # ... all installation tasks ...

- name: Mark setup as complete
  copy:
    content: |
      Setup completed: {{ ansible_date_time.iso8601 }}
      Hostname: {{ ansible_hostname }}
      User: {{ ansible_user_id }}
    dest: "{{ target_home }}/.deployiq/setup_complete"
```

**Effort:** Low | **Benefit:** Low (Convenience)

---

### 17. Add Dry-Run / Check Mode Support

**Current State:**
- No way to preview what will be installed without actually installing

**Recommendation:**
Ensure all tasks support check mode:

```yaml
- name: Install Vivaldi using Snap
  snap:
    name: vivaldi
    state: present
  check_mode: true  # Ansible will simulate
  register: vivaldi_install

- name: Report what would be installed (check mode)
  debug:
    msg: "Would install: Vivaldi"
  when: ansible_check_mode and vivaldi_check.rc != 0
```

Run with: `ansible-playbook setup.yml --check`

**Effort:** Low | **Benefit:** Low-Medium (Safety)

---

## Implementation Priority Matrix

| Priority | Issue | Effort | Benefit | Category |
|----------|-------|--------|---------|----------|
| 1 | Hardcoded username | Medium | High | Portability |
| 2 | Application selection mechanism | Medium | Very High | Flexibility |
| 3 | Security: curl pipe to bash | Low | High | Security |
| 4 | Conflicting power settings | Low | High | Correctness |
| 5 | Pre-flight checks | Medium | High | UX |
| 6 | Version pinning | High | High | Maintainability |
| 7 | Deprecated module usage | Low | Medium | Future-proofing |
| 8 | Post-install verification | Medium | Medium | Reliability |
| 9 | Selective error handling | Medium | Medium | Debugging |
| 10 | Cleanup/rollback mechanism | Medium | Medium | Safety |

---

## Quick Wins (Low Effort, High Benefit)

1. Fix conflicting power management settings (5 minutes)
2. Replace curl-pipe-bash with secure download (15 minutes)
3. Use ansible.builtin.command instead of command (10 minutes)
4. Add variable for target username (30 minutes)

---

## Long-term Architecture Recommendations

### Create Role Structure
```
ansible/roles/deployiq_workstation/
├── defaults/
│   └── main.yml          # All configurable variables
├── tasks/
│   ├── main.yml          # Orchestrator
│   ├── preflight.yml     # System checks
│   ├── apps.yml          # Include app tasks
│   ├── system.yml        # System configurations
│   └── apps/
│       ├── browsers.yml
│       ├── communication.yml
│       ├── productivity.yml
│       ├── security.yml
│       ├── development.yml
│       └── utilities.yml
├── handlers/
│   └── main.yml          # Cleanup handlers
├── vars/
│   └── main.yml          # Internal variables
├── files/
│   └── ...               # Static files
└── templates/
    └── ...               # Jinja2 templates
```

### Configuration File Example
```yaml
# defaults/main.yml
---
# Target user configuration
deployiq_target_user: "{{ ansible_user_id }}"
deployiq_target_home: "{{ ansible_env.HOME }}"

# Application selection
deployiq_install_apps:
  browsers:
    vivaldi: true
  communication:
    discord: true
    zoom: true
    mailspring: false
  productivity:
    notion: true
    onlyoffice: false
  security:
    bitwarden: true
    protonvpn: false
  development:
    docker: true
    portainer: true
    n8n: false

# Application versions
deployiq_app_versions:
  protonvpn_repo: "1.0.4"
  portainer: "2.19.4"
  n8n: "1.18.0"

# System configuration
deployiq_power_management:
  enabled: true
  lid_close_ac: "hibernate"
  lid_close_battery: "hibernate"
  sleep_timeout_ac: 0
  sleep_timeout_battery: 0

deployiq_touchpad:
  enabled: true
  speed: 0.5
  click_method: "fingers"

# Docker configuration
deployiq_docker:
  add_user_to_group: true
  enable_service: true
  install_portainer: true
  install_n8n: false
```

---

## Testing Recommendations

1. **Create test environments:**
   - Vagrant/VirtualBox VMs for testing
   - Multiple Ubuntu versions (20.04, 22.04, 24.04)
   - Different desktop environments (GNOME, KDE, XFCE)

2. **Use Molecule for role testing:**
   ```bash
   molecule init role deployiq_workstation
   molecule test
   ```

3. **CI/CD integration:**
   - GitHub Actions for automated testing
   - Lint with ansible-lint
   - Test on multiple distributions

---

## Documentation Improvements

1. **Create README.md for playbook:**
   - Prerequisites
   - Usage instructions
   - Configuration examples
   - Troubleshooting guide

2. **Add inline comments:**
   - Explain why certain decisions were made
   - Document workarounds for known issues

3. **Create CHANGELOG.md:**
   - Track playbook version changes
   - Note breaking changes

---

## Summary

The current `setup.yml` playbook is functional but would greatly benefit from:
1. **Removing hardcoded values** (username, paths)
2. **Adding user choice** (which apps to install)
3. **Improving security** (curl-to-bash antipattern)
4. **Better error handling** (selective ignore_errors)
5. **Version management** (track and pin versions)

These changes would transform the playbook from a personal script to a reusable, maintainable automation tool suitable for team use or public distribution.
