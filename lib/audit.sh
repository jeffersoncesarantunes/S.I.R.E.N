# shellcheck shell=bash
# LinSpec audit parser.
# Reads report.json via Python3 and exports AUDIT_* variables.

load_linspec_audit() {
    LOADED_AUDIT=false
    AUDIT_KPTR=1
    AUDIT_PTRACE=1
    AUDIT_SPECTRE=1
    AUDIT_MELTDOWN=1
    AUDIT_DEVMEM=1

    [[ ! -f "$LINSPEC_REPORT" ]] && return 1

    if command -v python3 &>/dev/null; then
        local json
        json=$(python3 -c "
import json, sys
try:
    with open('$LINSPEC_REPORT') as f:
        d = json.load(f)
    print(d.get('kptr_restrict', 1))
    print(d.get('ptrace_scope', 1))
    print(d.get('spectre_v2', 1))
    print(d.get('meltdown', 1))
    print(d.get('devmem_restrict', 1))
except Exception:
    print('1\n1\n1\n1\n1')
" 2>/dev/null) || return 1

        local vals
        mapfile -t vals <<< "$json"
        [[ ${#vals[@]} -ge 5 ]] || return 1
        AUDIT_KPTR=${vals[0]}
        AUDIT_PTRACE=${vals[1]}
        AUDIT_SPECTRE=${vals[2]}
        AUDIT_MELTDOWN=${vals[3]}
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
