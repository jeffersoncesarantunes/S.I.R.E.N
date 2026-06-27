# shellcheck shell=bash

check_storage() {
    local ram_size
    ram_size=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
    local disk_free
    disk_free=$(df -B1 "$BASE_DUMPS_DIR" | awk 'NR==2 {print $4}')
    if [[ -n "$ram_size" && -n "$disk_free" && "$ram_size" -gt "$disk_free" ]]; then
        echo -e "${YELLOW}[!] WARNING: RAM size exceeds available disk space.${NC}"
        read -rp "Proceed with acquisition? (y/N): " choice
        [[ "$choice" != "y" ]] && exit 1
    fi
}

validate_dump_content() {
    local file_path=$1
    local size
    size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)

    if [[ "$size" -lt 4096 ]]; then
        echo -e "${RED}[!] FAIL: Dump is too small (${size} bytes) - acquisition failed.${NC}"
        return 1
    fi

    if command -v python3 &>/dev/null; then
        PY_PATH="$file_path" python3 -c "
import os, sys
with open(os.environ['PY_PATH'], 'rb') as f:
    sample = f.read(4096)
    non_zero = sum(1 for b in sample if b != 0)
    ratio = non_zero / len(sample)
    if ratio < 0.01:
        print('FAIL: dump is >99% null bytes (acquisition returned no data)')
        sys.exit(1)
    print(f'OK: {non_zero}/4096 non-null bytes ({ratio*100:.1f}%)')
" 2>/dev/null && return 0
    fi

    head -c 4096 "$file_path" | od -A x -t x1z -v | head -4
    return 0
}

log_operation() {
    local msg=$1
    local ts
    ts=$(date --iso-8601=seconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
    echo "[$ts] $msg" | tee -a "$LOG_FILE" >&2
}
