# shellcheck shell=bash

load_linspec_audit() {
    LOADED_AUDIT=false
    AUDIT_KPTR=1
    AUDIT_PTRACE=1
    AUDIT_SPECTRE=1
    AUDIT_MELTDOWN=1
    AUDIT_DEVMEM=1

    [[ ! -f "$LINSPEC_REPORT" ]] && return 1

    local tool_dir
    tool_dir=$(dirname "$SCRIPT_DIR")/tools
    if command -v python3 &>/dev/null && [[ -f "$tool_dir/audit_loader.py" ]]; then
        local json
        json=$(python3 "$tool_dir/audit_loader.py" "$LINSPEC_REPORT" 2>/dev/null) || return 1

        local vals
        mapfile -t vals <<< "$json"
        [[ ${#vals[@]} -ge 5 ]] || return 1
        # shellcheck disable=SC2034
        AUDIT_KPTR=${vals[0]}
        # shellcheck disable=SC2034
        AUDIT_PTRACE=${vals[1]}
        # shellcheck disable=SC2034
        AUDIT_SPECTRE=${vals[2]}
        # shellcheck disable=SC2034
        AUDIT_MELTDOWN=${vals[3]}
        # shellcheck disable=SC2034
        AUDIT_DEVMEM=${vals[4]}
    else
        return 1
    fi

    LOADED_AUDIT=true
    return 0
}

print_audit_status() {
    if $LOADED_AUDIT; then
        echo -e "${GREEN}[Audit Loaded from LinSpec]${NC}"
    else
        echo -e "${YELLOW}[i] No LinSpec audit loaded (defaulting to safe params)${NC}"
    fi
}
