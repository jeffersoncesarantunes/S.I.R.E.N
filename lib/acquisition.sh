# shellcheck shell=bash
# Memory acquisition functions

map_system_ram() {
    echo -e "${CYAN}[+] Mapping Physical System RAM regions...${NC}"
    if [[ ! -f /proc/iomem ]]; then
        echo -e "${RED}[!] /proc/iomem not found${NC}"
        return 1
    fi
    if [[ "$AUDIT_KPTR" -eq 0 ]]; then
        echo -e "${YELLOW}[!] Kernel Pointers Leaking: Sensitive addresses might be visible in mapping.${NC}"
    fi
    grep "System RAM" /proc/iomem | while read -r line; do
        echo -e "  --> ${YELLOW}${line}${NC} [VALID]"
    done
}

# Quick triage: grab first 100MB of kcore via dd (fast, useful for strings/hex)
quick_triage_kcore() {
    local output_file=$1
    echo -e "${CYAN}[*] Starting Pipeline: /proc/kcore${NC}"
    dd if=/proc/kcore bs=1M count=100 conv=noerror,sync status=progress > "$output_file" 2>/dev/null
    local sz
    sz=$(stat -c%s "$output_file" 2>/dev/null || echo 0)
    echo -e "${GREEN}[+] Read ${sz} bytes${NC}"
}

# Full acquisition: use Python ELF extractor on /proc/kcore
full_acquisition_kcore() {
    local output_file=$1
    local tool_dir
    tool_dir=$(dirname "$SCRIPT_DIR")/tools

    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}[!] python3 is required for ELF segment extraction${NC}"
        echo -e "${YELLOW}[i] Falling back to dd-based kcore read${NC}"
        local ram_kb
        ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        [[ "$ram_kb" =~ ^[0-9]+$ ]] || ram_kb=0
        local ram_mb=$((ram_kb / 1024))
        [[ "$ram_mb" -gt 0 && "$ram_mb" -lt 1048576 ]] || ram_mb=1024
        echo -e "${YELLOW}[!] Initiating Automated Extraction via /proc/kcore (dd fallback)...${NC}"
        dd if=/proc/kcore bs=1M count="$ram_mb" conv=noerror,sync status=progress > "$output_file" 2>/dev/null
        return
    fi

    if [[ -x "$tool_dir/kcore_extract.py" ]]; then
        echo -e "${YELLOW}[!] Initiating Automated Extraction via /proc/kcore (ELF-aware)...${NC}"
        python3 "$tool_dir/kcore_extract.py" "$output_file"
    else
        echo -e "${YELLOW}[!] Initiating Automated Extraction via /proc/kcore (dd fallback)...${NC}"
        local ram_kb
        ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        [[ "$ram_kb" =~ ^[0-9]+$ ]] || ram_kb=0
        local ram_mb=$((ram_kb / 1024))
        [[ "$ram_mb" -gt 0 && "$ram_mb" -lt 1048576 ]] || ram_mb=1024
        dd if=/proc/kcore bs=1M count="$ram_mb" conv=noerror,sync status=progress > "$output_file" 2>/dev/null
    fi
}

# Verify pipeline: read /proc/version and validate
verify_pipeline() {
    local output_file=$1
    echo -e "${CYAN}[*] Starting Pipeline: /proc/version${NC}"
    dd if=/proc/version bs=4096 count=1 conv=noerror,sync status=none > "$output_file" 2>/dev/null
    local sz
    sz=$(stat -c%s "$output_file" 2>/dev/null || echo 0)
    if [[ "$sz" -gt 0 ]]; then
        echo -e "${GREEN}[+] Pipeline completed successfully.${NC}"
        return 0
    else
        echo -e "${RED}[!] Pipeline FAILED: could not read from /proc${NC}"
        return 1
    fi
}
