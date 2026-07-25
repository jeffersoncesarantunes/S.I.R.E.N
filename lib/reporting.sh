# shellcheck shell=bash

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

    local tool_dir
    tool_dir=$(dirname "$SCRIPT_DIR")/tools
    if command -v python3 &>/dev/null && [[ -f "$tool_dir/report_generator.py" ]]; then
        local json_input
        json_input=$(printf '{
  "timestamp": "%s",
  "hostname": "%s",
  "kernel": "%s",
  "method": "%s",
  "audit_aware": %s,
  "audit_kptr": %s,
  "audit_ptrace": %s,
  "audit_spectre": %s,
  "audit_meltdown": %s,
  "file": "%s",
  "size": "%s",
  "hash": "%s",
  "vol_profile": "%s",
  "vol_platform": "%s",
  "vol_major": "%s"
}' \
            "$(printf '%s' "$timestamp" | sed 's/"/\\"/g')" \
            "$(printf '%s' "$hostname" | sed 's/"/\\"/g')" \
            "$(printf '%s' "$kernel" | sed 's/"/\\"/g')" \
            "$(printf '%s' "$method" | sed 's/"/\\"/g')" \
            "${LOADED_AUDIT:-false}" \
            "${AUDIT_KPTR:-1}" \
            "${AUDIT_PTRACE:-1}" \
            "${AUDIT_SPECTRE:-1}" \
            "${AUDIT_MELTDOWN:-1}" \
            "$(printf '%s' "$(basename "$file_path")" | sed 's/"/\\"/g')" \
            "$size" \
            "$(printf '%s' "$hash" | sed 's/"/\\"/g')" \
            "$(printf '%s' "${VOLATILITY_PROFILE:-}" | sed 's/"/\\"/g')" \
            "$(printf '%s' "${VOLATILITY_PLATFORM:-}" | sed 's/"/\\"/g')" \
            "${VOLATILITY_MAJOR:-0}")
        printf '%s' "$json_input" | python3 "$tool_dir/report_generator.py" > "$json_file"
    else
        printf "{\n  \"timestamp\": \"%s\",\n  \"hostname\": \"%s\",\n  \"kernel\": \"%s\",\n  \"method\": \"%s\",\n  \"audit_aware\": %s,\n  \"evidence\": {\n    \"file\": \"%s\",\n    \"size_bytes\": %s,\n    \"sha256\": \"%s\"\n  },\n  \"volatility\": {\n    \"profile\": \"%s\",\n    \"platform\": \"%s\",\n    \"version\": %s\n  }\n}\n" \
            "$timestamp" "${hostname//\"/\\\"}" "${kernel//\"/\\\"}" "$method" \
            "$LOADED_AUDIT" "$(basename "$file_path")" "$size" "${hash//\"/\\\"}" \
            "${VOLATILITY_PROFILE:-}" "${VOLATILITY_PLATFORM:-}" "${VOLATILITY_MAJOR:-0}" > "$json_file"
    fi

    local csv_file="$REP_DIR/manifest.csv"
    if [[ ! -f "$csv_file" ]]; then
        echo "timestamp,hostname,method,file,size,sha256,volatility_profile" > "$csv_file"
    fi
    printf '%s,%s,%s,%s,%s,%s,%s\n' \
        "$timestamp" "$hostname" "$method" "$(basename "$file_path")" "$size" "$hash" "${VOLATILITY_PROFILE:-}" >> "$csv_file"

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
