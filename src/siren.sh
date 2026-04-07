#!/usr/bin/env bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${RED}[!] Error: Elevated privileges required.${NC}" && exit 1

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DUMPS_DIR="$(dirname "$SCRIPT_DIR")/dumps"
mkdir -p "$DUMPS_DIR"

generate_reports() {
    local file_path=$1 method=$2 hash=$3 ts=$4
    local timestamp=${ts:-$(date +%Y%m%d_%H%M%S)}
    local hostname=$(hostname)
    local kernel=$(uname -r)
    local size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")
    local json_file="$DUMPS_DIR/report_$timestamp.json"
    
    printf "{\n  \"timestamp\": \"%s\",\n  \"hostname\": \"%s\",\n  \"kernel\": \"%s\",\n  \"method\": \"%s\",\n  \"evidence\": {\n    \"file\": \"%s\",\n    \"size_bytes\": %s,\n    \"sha256\": \"%s\"\n  }\n}\n" \
        "$timestamp" "$hostname" "$kernel" "$method" "$(basename "$file_path")" "$size" "$hash" > "$json_file"
    
    local csv_file="$DUMPS_DIR/manifest.csv"
    [[ ! -f "$csv_file" ]] && echo "timestamp,hostname,method,file,size,sha256" > "$csv_file"
    echo "$timestamp,$hostname,$method,$(basename "$file_path"),$size,$hash" >> "$csv_file"
    
    echo -e "${GREEN}[+] Reports generated: JSON & CSV manifest updated.${NC}"
}

check_storage() {
    local ram_size=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
    local disk_free=$(df -B1 "$DUMPS_DIR" | awk 'NR==2 {print $4}')
    if [[ -n "$ram_size" && -n "$disk_free" && "$ram_size" -gt "$disk_free" ]]; then
        echo -e "${YELLOW}[!] WARNING: RAM size exceeds available disk space.${NC}"
        read -p "Proceed with acquisition? (y/N): " choice
        [[ "$choice" != "y" ]] && exit 1
    fi
}

map_system_ram() {
    echo -e "${CYAN}[+] Mapping Physical System RAM regions...${NC}"
    grep "System RAM" /proc/iomem | while read -r line; do
        echo -e "  --> Address: ${YELLOW}${line}${NC} [VALID]"
    done
}

stream_analysis() {
    local source=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$DUMPS_DIR/mem_dump_$timestamp.bin"
    
    echo -e "${CYAN}[*] Starting Pipeline: $source${NC}"
    
    if [[ "$source" == "/dev/mem" || "$source" == "/proc/kcore" ]]; then
        [[ "$source" == "/dev/mem" ]] && check_storage
        dd if="$source" bs=1M count=100 conv=noerror,sync status=progress > "$output_file" 2>/dev/null
    else
        cat "$source" > "$output_file"
    fi
    
    local hash=$(sha256sum "$output_file" | awk '{print $1}')
    sha256sum "$output_file" > "${output_file}.sha256"
    strings "$output_file" > "${output_file%.bin}.txt"
    
    generate_reports "$output_file" "Live Extraction ($source)" "$hash" "$timestamp"
    echo -e "${GREEN}[+] Pipeline completed successfully.${NC}"
}

automated_extraction() {
    check_storage
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$DUMPS_DIR/full_scan_$timestamp.bin"
    local source="/dev/mem"
    local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local ram_mb=$((ram_kb / 1024))
    
    if [[ -f "/proc/kcore" ]]; then
        echo -e "${YELLOW}[!] /proc/kcore detected (Bypass attempt). Use it? (y/N): ${NC}"
        read -r kchoice
        [[ "$kchoice" == "y" ]] && source="/proc/kcore"
    fi
    
    echo -e "${YELLOW}[!] Initiating Automated Extraction via $source...${NC}"
    > "$output_file"
    
    if [[ "$source" == "/dev/mem" ]]; then
        grep "System RAM" /proc/iomem | while read -r line; do
            range=$(echo $line | cut -d' ' -f1)
            start_hex=$(echo $range | cut -d'-' -f1)
            end_hex=$(echo $range | cut -d'-' -f2)
            start=$((16#$start_hex))
            end=$((16#$end_hex))
            size=$((end - start))
            
            echo -e "${CYAN}[i] Extracting range: $range ($((size/1024/1024)) MB)${NC}"
            dd if=/dev/mem bs=4k skip=$((start/4096)) count=$((size/4096)) conv=noerror,sync status=none >> "$output_file"
        done
    else
        echo -e "${CYAN}[*] Limited to Physical RAM Size: ${ram_mb} MB${NC}"
        dd if=/proc/kcore bs=1M count=$ram_mb conv=noerror,sync status=progress >> "$output_file" 2>/dev/null
    fi
    
    if [[ -s "$output_file" ]]; then
        local hash=$(sha256sum "$output_file" | awk '{print $1}')
        generate_reports "$output_file" "Automated Scan ($source)" "$hash" "$timestamp"
        echo -e "${GREEN}[+] Extraction finalized.${NC}"
    else
        echo -e "${RED}[!] Error: Extraction failed.${NC}"
    fi
}

while true; do
    clear
    echo -e "\n${GREEN}🐧 S.I.R.E.N - Shell Interactive Runtime Entity Notifier${NC}"
    echo -e "${CYAN}---------------------------------------------------------${NC}"
    echo "1) Map Physical Memory (iomem)"
    echo "2) Verify Extraction Pipeline"
    echo "3) Live Memory Extraction (/dev/mem)"
    echo "4) Advanced Forensic Bypass (kcore)"
    echo "5) Exit"
    echo -e "${CYAN}---------------------------------------------------------${NC}"
    
    read -p "Select an option: " opt
    case $opt in
        1) map_system_ram ;;
        2) stream_analysis "/proc/version" ;;
        3) stream_analysis "/dev/mem" ;;
        4) automated_extraction ;;
        5) exit 0 ;;
        *) sleep 1 ;;
    esac
    
    echo -e "\n${CYAN}-- Press ENTER to return to menu --${NC}"
    read
done
