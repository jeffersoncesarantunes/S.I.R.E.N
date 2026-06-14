# shellcheck shell=bash
# Report generation: JSON, CSV, SHA256, strings

generate_reports() {
    local file_path=$1 method=$2 hash=$3 ts=$4
    local timestamp=${ts:-$(date +%Y%m%d_%H%M%S)}
    local hostname
    hostname=$(hostname 2>/dev/null || echo "unknown")
    local kernel
    kernel=$(uname -r 2>/dev/null || echo "unknown")
    local size
    size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")
    local json_file="$REP_DIR/report_$timestamp.json"

    if command -v python3 &>/dev/null; then
        PY_TS="$timestamp" PY_HOST="$hostname" PY_KERNEL="$kernel" \
        PY_METHOD="$method" PY_FILE="$(basename "$file_path")" \
        PY_SIZE="$size" PY_HASH="$hash" \
        PY_AUDIT="$LOADED_AUDIT" \
        PY_AUDIT_KPTR="$AUDIT_KPTR" PY_AUDIT_PTRACE="$AUDIT_PTRACE" \
        PY_AUDIT_SPECTRE="$AUDIT_SPECTRE" PY_AUDIT_MELTDOWN="$AUDIT_MELTDOWN" \
        python3 -c "
import json, os
data = {
    'timestamp': os.environ['PY_TS'],
    'hostname': os.environ['PY_HOST'],
    'kernel': os.environ['PY_KERNEL'],
    'method': os.environ['PY_METHOD'],
    'audit_aware': os.environ.get('PY_AUDIT', 'false') == 'true',
    'audit_params': {
        'kptr_restrict': int(os.environ.get('PY_AUDIT_KPTR', '1')),
        'ptrace_scope': int(os.environ.get('PY_AUDIT_PTRACE', '1')),
        'spectre_v2': int(os.environ.get('PY_AUDIT_SPECTRE', '1')),
        'meltdown': int(os.environ.get('PY_AUDIT_MELTDOWN', '1')),
    },
    'evidence': {
        'file': os.environ['PY_FILE'],
        'size_bytes': int(os.environ.get('PY_SIZE', '0')),
        'sha256': os.environ['PY_HASH'],
    }
}
json.dump(data, sys.stdout, indent=2)
" > "$json_file"
    else
        printf "{\n  \"timestamp\": \"%s\",\n  \"hostname\": \"%s\",\n  \"kernel\": \"%s\",\n  \"method\": \"%s\",\n  \"audit_aware\": %s,\n  \"evidence\": {\n    \"file\": \"%s\",\n    \"size_bytes\": %s,\n    \"sha256\": \"%s\"\n  }\n}\n" \
            "$timestamp" "${hostname//\"/\\\"}" "${kernel//\"/\\\"}" "$method" \
            "$LOADED_AUDIT" "$(basename "$file_path")" "$size" "${hash//\"/\\\"}" > "$json_file"
    fi

    local csv_file="$REP_DIR/manifest.csv"
    if [[ ! -f "$csv_file" ]]; then
        echo "timestamp,hostname,method,file,size,sha256" > "$csv_file"
    fi
    printf '%s,%s,%s,%s,%s,%s\n' \
        "$timestamp" "$hostname" "$method" "$(basename "$file_path")" "$size" "$hash" >> "$csv_file"

    echo -e "${GREEN}[+] Reports generated in $REP_DIR${NC}"
}

compute_hashes() {
    local file_path=$1
    local chk_dir=$2
    local base_name=$3
    local hash
    hash=$(sha256sum "$file_path" | awk '{print $1}')
    sha256sum "$file_path" > "${chk_dir}/${base_name}.sha256"
    echo "$hash"
}

extract_strings() {
    local file_path=$1
    local out_path=$2
    if command -v strings &>/dev/null; then
        strings "$file_path" > "$out_path" 2>/dev/null
        local n
        n=$(wc -l < "$out_path" 2>/dev/null || echo 0)
        echo -e "${GREEN}[+] Extracted $n strings -> $out_path${NC}"
    else
        echo -e "${YELLOW}[!] strings not found, skipping${NC}"
    fi
}
