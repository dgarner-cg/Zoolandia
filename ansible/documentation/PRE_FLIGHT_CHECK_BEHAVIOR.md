# Pre-Flight Check Behavior

**Updated:** 2026-01-07
**Feature:** Smart dry-run detection for critical checks

---

## 🎯 Overview

Pre-flight checks now intelligently handle **dry-run mode** (--check flag) versus **actual installation mode**.

### Critical Checks with Smart Behavior:
1. **Disk Space** - Warns in dry-run, fails in actual mode
2. **Internet Connectivity** - Warns in dry-run, fails in actual mode
3. **RAM** - Always warns (never fails)

---

## 📋 Behavior Matrix

| Check | Dry-Run Mode (--check) | Actual Installation Mode |
|-------|------------------------|--------------------------|
| **Disk Space (< 10GB)** | ⚠️ Warning + Continue | ❌ Fail + Stop |
| **Internet (No Connection)** | ⚠️ Warning + Continue | ❌ Fail + Stop |
| **RAM (< 4GB)** | ⚠️ Warning + Continue | ⚠️ Warning + Continue |
| **Python (Missing)** | ℹ️ Info + Continue | Handled by Ansible |
| **Snap (Missing)** | ℹ️ Info + Auto-install | ℹ️ Info + Auto-install |
| **APT (Failed)** | May fail | May fail |
| **Desktop (Unsupported)** | ⚠️ Warning only | ⚠️ Warning only |

---

## 🧪 Test Results

### Dry-Run Mode (--check)

**Command:**
```bash
ansible-playbook setup-workstation.yml --check
```

**Result with No Internet:**
```
⚠️ NO INTERNET CONNECTIVITY (DRY-RUN MODE)

Unable to reach test URLs, but continuing because this is a test/dry-run.
In actual installation mode, this would fail.

Check mode detected: True
```

✅ **Status:** Continues execution
✅ **Outcome:** Shows what would be installed without failing

---

### Actual Installation Mode

**Command:**
```bash
ansible-playbook setup-workstation.yml
```

**Result with No Internet:**
```
❌ NO INTERNET CONNECTIVITY

Unable to reach test URLs. Please check your internet connection.
Internet access is required to download packages and repositories.

To skip this check for testing, run with: --check (dry-run mode)
```

❌ **Status:** Playbook stops
❌ **Outcome:** Graceful exit with clear error message

---

## 🔍 How It Works

The checks use Ansible's built-in `ansible_check_mode` variable:

```yaml
# In dry-run mode: show warning and continue
- name: "⚠️ No internet (dry-run mode)"
  ansible.builtin.debug:
    msg: "Warning message..."
  when:
    - connectivity_test failed
    - ansible_check_mode | default(false)  # TRUE in --check mode

# In actual mode: fail and stop
- name: "❌ No internet connectivity"
  ansible.builtin.fail:
    msg: "Error message..."
  when:
    - connectivity_test failed
    - not (ansible_check_mode | default(false))  # TRUE in normal mode
```

---

## 💡 Why This Design?

### Dry-Run Mode Benefits:
- ✅ Test playbook logic without internet
- ✅ Preview what would be installed
- ✅ Validate syntax and structure
- ✅ See potential issues without failing
- ✅ Safe for CI/CD pipelines

### Actual Mode Benefits:
- ✅ Prevents wasted time on failed downloads
- ✅ Clear error messages guide troubleshooting
- ✅ Protects against partial installations
- ✅ User knows exactly what's wrong

---

## 🎯 Use Cases

### Development/Testing
```bash
# Test the playbook structure
ansible-playbook setup-workstation.yml --check

# Test with no internet? No problem!
# The check will warn but continue
```

### Production/Actual Installation
```bash
# Install for real
ansible-playbook setup-workstation.yml

# If no internet? Stops immediately with clear message
# User can fix internet and re-run
```

### CI/CD Pipelines
```bash
# Validate in pipeline (might not have internet)
ansible-playbook setup-workstation.yml --check --syntax-check

# Deploy to target (requires internet)
ansible-playbook setup-workstation.yml
```

---

## 📊 Example Output

### Successful Dry-Run (No Internet)

```
🔍 PRE-FLIGHT CHECKS | Starting validation...
✅ PRE-FLIGHT CHECKS | Disk space check passed (1402GB available)
✅ PRE-FLIGHT CHECKS | RAM check passed (7.65GB)
⚠️ PRE-FLIGHT CHECKS | No internet (dry-run mode) ← Warning, not error
✅ PRE-FLIGHT CHECKS | Python check passed
✅ PRE-FLIGHT CHECKS | All checks passed!
🚀 Ready to proceed with installation!
```

**Result:** Continues to show what would be installed

---

### Failed Actual Installation (No Internet)

```
🔍 PRE-FLIGHT CHECKS | Starting validation...
✅ PRE-FLIGHT CHECKS | Disk space check passed
✅ PRE-FLIGHT CHECKS | RAM check passed
❌ NO INTERNET CONNECTIVITY ← Fails here

Unable to reach test URLs. Please check your internet connection.

PLAY RECAP *************************************************************
localhost : ok=10 changed=0 unreachable=0 failed=1 skipped=0
```

**Result:** Stops immediately with clear guidance

---

## 🛠️ Customization

You can disable internet checks entirely in `roles/workstation/defaults/main.yml`:

```yaml
preflight_checks:
  enabled: true
  check_internet: false  # Set to false to skip
  # ... other checks
```

Or skip via command line:
```bash
ansible-playbook setup-workstation.yml --skip-tags "preflight"
```

---

## ✅ Testing Verification

**Syntax Check:**
```bash
✅ ansible-playbook setup-workstation.yml --syntax-check
Result: playbook: setup-workstation.yml
```

**Dry-Run with No Internet:**
```bash
✅ ansible-playbook setup-workstation.yml --check
Result: ⚠️ Warning shown, playbook continues
Check mode detected: True
```

**Tag Verification:**
```bash
✅ ansible-playbook setup-workstation.yml --list-tags
Result: preflight tag available
```

---

## 🎉 Summary

**Smart Pre-Flight Checks:**
- ✅ Detect dry-run mode automatically
- ✅ Warn in testing, fail in production
- ✅ Clear messages explain what's happening
- ✅ Users can test without internet
- ✅ Actual installations protected from failures

**Best of Both Worlds:**
- Testing flexibility (warnings)
- Production safety (failures)
- Zero configuration needed (automatic detection)

---

**Updated:** 2026-01-07
**Status:** ✅ Implemented and Tested
