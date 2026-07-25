# shellcheck shell=bash

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

quick_triage_kcore() {
    local output_file=$1
    echo -e "${CYAN}[*] Starting Pipeline: /proc/kcore${NC}"
    dd if=/proc/kcore bs=1M count=100 conv=noerror,sync status=progress > "$output_file" 2>/dev/null
    local sz
    sz=$(stat -c%s "$output_file" 2>/dev/null || echo 0)
    echo -e "${GREEN}[+] Read ${sz} bytes${NC}"
}

create_temp_dir() {
    local tmpdir
    tmpdir=$(mktemp -d /tmp/siren.XXXXXX 2>/dev/null) || return 1
    SIREN_CLEANUP_DIRS+=("$tmpdir")
    printf '%s' "$tmpdir"
}

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

full_acquisition_lime() {
    local output_file=$1
    local module_path="${LIME_MODULE:-}"

    if [[ -z "$module_path" ]]; then
        local search_paths=(
            "./lime.ko"
            "/lib/modules/$(uname -r)/lime.ko"
            "/opt/lime/lime.ko"
            "/root/lime.ko"
            "/tmp/lime.ko"
        )
        for p in "${search_paths[@]}"; do
            if [[ -f "$p" ]]; then
                module_path="$p"
                break
            fi
        done
    fi

    if [[ -z "$module_path" || ! -f "$module_path" ]]; then
        echo -e "${YELLOW}[!] LiME module not found. Falling back to full kcore extraction.${NC}"
        full_acquisition_kcore "$output_file"
        return $?
    fi

    echo -e "${CYAN}[*] Loading LiME kernel module: $module_path${NC}"

    if lsmod | grep -q '^lime '; then
        echo -e "${YELLOW}[!] LiME already loaded, using existing instance${NC}"
    else
        insmod "$module_path" "path=/dev/lime format=raw" 2>/dev/null || {
            echo -e "${RED}[!] Failed to load LiME module. Falling back to kcore extraction.${NC}"
            full_acquisition_kcore "$output_file"
            return $?
        }
    fi

    local block_size=1M
    if [[ "${3:-}" =~ ^[0-9]+[kKmMgG]?$ ]]; then
        block_size="$3"
    fi
    echo -e "${CYAN}[*] Acquiring physical memory via /dev/lime...${NC}"
    dd if=/dev/lime bs="$block_size" conv=noerror,sync status=progress > "$output_file" 2>/dev/null

    rmmod lime 2>/dev/null || true

    local sz
    sz=$(stat -c%s "$output_file" 2>/dev/null || echo 0)
    echo -e "${GREEN}[+] LiME acquisition complete: ${sz} bytes${NC}"
}

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
