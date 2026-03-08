#!/bin/bash
################################################################################
# Zoolandia - License Module
#
# Description: License validation, activation, and feature gating
# Version: 1.0.0
################################################################################

# Embedded public key — matches .signing/zoolandia_public.pem
ZL_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAf+0d/vvgC7ujIuRsU9t4Pj3ZctbMNJCLJjQpxGgiNDw=
-----END PUBLIC KEY-----"

LICENSE_DIR="${SCRIPT_DIR}/.license"
LICENSE_FILE="${LICENSE_DIR}/license.key"

################################################################################
# Internal helpers
################################################################################

# base64url decode (handles missing padding)
_zl_b64url_decode() {
    local input="$1"
    # Restore standard base64: replace - with +, _ with /, add padding
    local padded
    padded=$(printf '%s' "$input" | tr -- '-_' '+/')
    local mod=$(( ${#padded} % 4 ))
    [[ $mod -eq 2 ]] && padded="${padded}=="
    [[ $mod -eq 3 ]] && padded="${padded}="
    printf '%s' "$padded" | base64 -d 2>/dev/null
}

# Extract a string field from the license JSON payload (no jq dependency)
_zl_json_field() {
    local json="$1" field="$2"
    echo "$json" | grep -oP "\"${field}\":\"[^\"]*\"" | cut -d'"' -f4
}

# Return 0 if a boolean field is true, 1 otherwise
_zl_json_bool() {
    local json="$1" field="$2"
    echo "$json" | grep -qP "\"${field}\":true"
}

# Extract a numeric field (integer, may be negative)
_zl_json_number() {
    local json="$1" field="$2"
    echo "$json" | grep -oP "\"${field}\":-?[0-9]+" | grep -oP -- '-?[0-9]+$'
}

# Check if features array contains a given feature
_zl_has_feature() {
    local json="$1" feature="$2"
    echo "$json" | grep -oP '"features":\[[^\]]*\]' | grep -q "\"${feature}\""
}

################################################################################
# Core validation
################################################################################

# zl_validate_key KEY_STRING
# Returns 0 if valid, non-zero if invalid
# Prints JSON payload to stdout on success
zl_validate_key() {
    local key="$1"

    # Sanity check format
    [[ "$key" =~ ^ZOOL-[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]] || return 1

    local b64_payload="${key#ZOOL-}"
    b64_payload="${b64_payload%%.*}"
    local b64_sig="${key##*.}"

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    # Decode payload
    local payload
    payload=$(_zl_b64url_decode "$b64_payload") || return 1
    printf '%s' "$payload" > "${tmpdir}/payload.bin"

    # Decode signature
    _zl_b64url_decode "$b64_sig" > "${tmpdir}/sig.bin" 2>/dev/null || return 1
    [[ -s "${tmpdir}/sig.bin" ]] || return 1

    # Verify Ed25519 signature
    printf '%s' "$ZL_PUBLIC_KEY" > "${tmpdir}/pub.pem"
    openssl pkeyutl -verify \
        -pubin -inkey "${tmpdir}/pub.pem" \
        -rawin \
        -in "${tmpdir}/payload.bin" \
        -sigfile "${tmpdir}/sig.bin" &>/dev/null || return 1

    # Check perpetual flag — if true, skip expiry check entirely
    if ! _zl_json_bool "$payload" "perpetual"; then
        local expires
        expires=$(_zl_json_field "$payload" "expires")
        [[ -z "$expires" ]] && return 1
        [[ "$(date +%Y-%m-%d)" > "$expires" ]] && return 2  # expired (distinct code)
    fi

    # Check machine binding — if machine_id in payload, verify against local machine
    local machine_id
    machine_id=$(_zl_json_field "$payload" "machine_id")
    if [[ -n "$machine_id" ]]; then
        local local_id
        local_id=$(cat /etc/machine-id 2>/dev/null | tr -d '[:space:]')
        [[ "$machine_id" != "$local_id" ]] && return 3  # machine mismatch (distinct code)
    fi

    echo "$payload"
    return 0
}

################################################################################
# Public API — used by feature modules
################################################################################

# zl_check_license FEATURE
# Returns 0 if the active license grants access to FEATURE
zl_check_license() {
    local feature="$1"

    [[ -f "$LICENSE_FILE" ]] || return 1
    local key
    key=$(cat "$LICENSE_FILE")
    [[ -z "$key" ]] && return 1

    local payload
    payload=$(zl_validate_key "$key") || return 1

    _zl_has_feature "$payload" "$feature" || return 1
    return 0
}

# zl_require_license FEATURE [LABEL]
# Shows upgrade prompt and returns 1 if feature is not licensed.
# Returns 0 silently if licensed.
zl_require_license() {
    local feature="$1"
    local label="${2:-$feature}"

    zl_check_license "$feature" && return 0

    # Check why it failed for a better message
    local msg
    if [[ ! -f "$LICENSE_FILE" ]]; then
        msg="No license key found.\n\nThis is a licensed feature: ${label}\n\nActivate with:\n  ./zoolandia.sh --activate"
    else
        local key rc
        key=$(cat "$LICENSE_FILE")
        zl_validate_key "$key"; rc=$?
        if [[ $rc -eq 2 ]]; then
            msg="Your license has expired.\n\nRenew at: https://zoolandia.dev/pricing"
        elif [[ $rc -eq 3 ]]; then
            msg="This license is bound to a different machine.\n\nContact support to transfer your license."
        elif [[ $rc -ne 0 ]]; then
            msg="Invalid license key.\n\nContact support or re-activate:\n  ./zoolandia.sh --activate"
        else
            msg="Your current license tier does not include: ${label}\n\nUpgrade at: https://zoolandia.dev/pricing"
        fi
    fi

    if command -v dialog &>/dev/null; then
        dialog --title " Licensed Feature " \
               --msgbox "\n${msg}\n" 12 60
    else
        echo ""
        echo "=== Licensed Feature: ${label} ==="
        echo -e "$msg"
        echo ""
    fi

    return 1
}

################################################################################
# Activation
################################################################################

# zl_activate_license [KEY]
# Interactively prompts for a key (or accepts one as argument), validates, saves.
zl_activate_license() {
    local key="${1:-}"

    if [[ -z "$key" ]]; then
        if command -v dialog &>/dev/null; then
            key=$(dialog --title " Activate Zoolandia " \
                         --inputbox "\nEnter your license key:\n(ZOOL-...)\n" \
                         10 70 3>&1 1>&2 2>&3) || return 1
        else
            echo -n "Enter license key (ZOOL-...): "
            read -r key
        fi
    fi

    key=$(echo "$key" | tr -d '[:space:]')
    [[ -z "$key" ]] && { echo "No key entered." >&2; return 1; }

    local payload rc
    payload=$(zl_validate_key "$key"); rc=$?

    case $rc in
        0)
            local email tier expires
            email=$(_zl_json_field "$payload" "email")
            tier=$(_zl_json_field "$payload" "tier")
            expires=$(_zl_json_field "$payload" "expires")

            # Build extra info lines for new fields
            local extra=""
            _zl_json_bool "$payload" "perpetual" && extra="${extra}\n  Perpetual: yes (never expires)"
            _zl_json_bool "$payload" "offline"   && extra="${extra}\n  Offline:   yes (no activation call)"
            local mid; mid=$(_zl_json_field "$payload" "machine_id")
            [[ -n "$mid" ]] && extra="${extra}\n  Machine:   ${mid}"
            local mn;  mn=$(_zl_json_number "$payload" "max_nodes")
            if [[ -n "$mn" ]]; then
                [[ "$mn" == "-1" ]] && extra="${extra}\n  Nodes:     unlimited" \
                                    || extra="${extra}\n  Max nodes: ${mn}"
            fi

            mkdir -p "$LICENSE_DIR"
            echo "$key" > "$LICENSE_FILE"
            chmod 600 "$LICENSE_FILE"

            local msg="License activated!\n\n  Email:   ${email}\n  Tier:    ${tier}\n  Expires: ${expires}${extra}"
            if command -v dialog &>/dev/null; then
                dialog --title " Activated " --msgbox "\n${msg}\n" 14 58
            else
                echo -e "\n${msg}\n"
            fi
            return 0
            ;;
        2)
            local errmsg="This license key has expired.\n\nRenew at: https://zoolandia.dev/pricing"
            if command -v dialog &>/dev/null; then
                dialog --title " Expired " --msgbox "\n${errmsg}\n" 8 55
            else
                echo -e "\n${errmsg}\n" >&2
            fi
            return 1
            ;;
        3)
            local errmsg="This license is bound to a different machine.\n\nContact support to transfer your license."
            if command -v dialog &>/dev/null; then
                dialog --title " Wrong Machine " --msgbox "\n${errmsg}\n" 8 60
            else
                echo -e "\n${errmsg}\n" >&2
            fi
            return 1
            ;;
        *)
            local errmsg="Invalid license key.\n\nCheck for typos or contact support."
            if command -v dialog &>/dev/null; then
                dialog --title " Invalid Key " --msgbox "\n${errmsg}\n" 8 55
            else
                echo -e "\n${errmsg}\n" >&2
            fi
            return 1
            ;;
    esac
}

# zl_license_status
# Prints current license info (used in Settings menu)
zl_license_status() {
    if [[ ! -f "$LICENSE_FILE" ]]; then
        echo "No license — Free tier"
        return
    fi

    local key payload rc
    key=$(cat "$LICENSE_FILE")
    payload=$(zl_validate_key "$key"); rc=$?

    case $rc in
        0)
            local email tier expires flags=""
            email=$(_zl_json_field "$payload" "email")
            tier=$(_zl_json_field "$payload" "tier")
            expires=$(_zl_json_field "$payload" "expires")
            _zl_json_bool "$payload" "perpetual"  && flags="${flags}perpetual "
            _zl_json_bool "$payload" "offline"    && flags="${flags}offline "
            local mid; mid=$(_zl_json_field "$payload" "machine_id")
            [[ -n "$mid" ]] && flags="${flags}machine-bound "
            local mn; mn=$(_zl_json_number "$payload" "max_nodes")
            [[ "$mn" == "-1" ]] && flags="${flags}unlimited-nodes "
            local status="Licensed — ${tier} | ${email} | expires ${expires}"
            [[ -n "$flags" ]] && status="${status} | ${flags% }"
            echo "$status"
            ;;
        2) echo "License EXPIRED — renew at https://zoolandia.dev/pricing" ;;
        3) echo "License WRONG MACHINE — contact support to transfer" ;;
        *) echo "License INVALID — re-activate with ./zoolandia.sh --activate" ;;
    esac
}
