#!/usr/bin/env bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Error: This script must be run as root.${NC}"
   exit 1
fi

check_storage() {
    local ram_size=$(free -b | awk '/^Mem:/ {print $2}')
    local disk_free=$(df -B1 . | awk 'NR==2 {print $4}')

    if [[ -n "$ram_size" && -n "$disk_free" ]]; then
        if [ "$ram_size" -gt "$disk_free" ]; then
            echo -e "${RED}[!] WARNING: Potential insufficient disk space.${NC}"
            echo -e "Required (RAM): $(free -h | awk '/^Mem:/ {print $2}')"
            echo -e "Available (Disk): $(df -h . | awk 'NR==2 {print $4}')"
            read -p "Proceed anyway? (y/N): " choice
            [[ "$choice" != "y" ]] && exit 1
        fi
    fi
}

map_system_ram() {
    echo -e "${GREEN}[+] Mapping safe System RAM regions...${NC}"
    echo "--------------------------------------------------------"
    grep "System RAM" /proc/iomem | while read -r line; do
        range=$(echo $line | cut -d' ' -f1)
        echo -e "Address: ${YELLOW}$range${NC} [SAFE RANGE]"
    done
    echo "--------------------------------------------------------"
}

stream_analysis() {
    local source=$1
    local output_dir="../dumps"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$output_dir"
    
    echo -e "${YELLOW}[!] Starting acquisition from:${NC} $source"
    
    if [[ "$source" == "/dev/mem" ]]; then
        check_storage
        echo -e "${RED}[!] WARNING: Reading physical RAM. System freeze possible.${NC}"
        dd if="$source" bs=1M count=100 2>/dev/null | tee >(sha256sum > "$output_dir/mem_dump_$timestamp.sha256") \
                                                   | strings > "$output_dir/mem_strings_$timestamp.txt"
    else
        cat "$source" | tee >(sha256sum > "$output_dir/dump_$timestamp.sha256") \
                      | strings > "$output_dir/strings_$timestamp.txt"
    fi

    echo -e "${GREEN}[+] Pipeline completed successfully.${NC}"
}

automated_extraction() {
    check_storage
    local output_dir="../dumps"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$output_dir/full_mem_scan_$timestamp.bin"
    mkdir -p "$output_dir"

    echo -e "${YELLOW}[!] Starting Automated Safe Range Extraction...${NC}"
    
    grep "System RAM" /proc/iomem | while read -r line; do
        range=$(echo $line | cut -d' ' -f1)
        start_hex=$(echo $range | cut -d'-' -f1)
        end_hex=$(echo $range | cut -d'-' -f2)
        
        start_dec=$((16#$start_hex))
        end_dec=$((16#$end_hex))
        size=$((end_dec - start_dec))
        
        echo -n -e "${GREEN}[+] Extracting: $start_hex ($size bytes)... ${NC}"
        
        if dd if=/dev/mem bs=1 skip=$start_dec count=$size 2>/dev/null >> "$output_file"; then
            echo -e "${GREEN}[OK]${NC}"
        else
            echo -e "${RED}[DENIED BY KERNEL]${NC}"
        fi
    done

    if [[ -s "$output_file" ]]; then
        echo -e "${YELLOW}[*] Generating strings and hash for collected data...${NC}"
        sha256sum "$output_file" > "${output_file%.bin}.sha256"
        strings "$output_file" > "${output_file%.bin}.txt"
        echo -e "${GREEN}[+] Automated scan finished. Results in $output_dir${NC}"
    else
        echo -e "${RED}[!] Error: No data could be collected. Check 'iomem=relaxed' boot parameter.${NC}"
        rm "$output_file"
    fi
}

remote_forensic_stream() {
    echo -e "${YELLOW}[!] Remote Forensic Exfiltration Mode${NC}"
    read -p "Enter Target IP: " target_ip
    read -p "Enter Target Port (default 4444): " target_port
    target_port=${target_port:-4444}

    if [[ -z "$target_ip" ]]; then
        echo -e "${RED}[!] Error: Target IP is required.${NC}"
        return
    fi

    echo -ne "${YELLOW}[*] Checking connection to $target_ip:$target_port... ${NC}"
    if ! nc -z -w 3 "$target_ip" "$target_port" 2>/dev/null; then
        echo -e "${RED}[FAILED]${NC}"
        echo -e "${RED}[!] Error: Destination unreachable. Start the listener (nc -l) first.${NC}"
        return
    fi
    echo -e "${GREEN}[READY]${NC}"

    local compressor="cat"
    if command -v zstd >/dev/null 2>&1; then
        compressor="zstd -1 --threads=0"
        echo -e "${GREEN}[+] Using ZSTD compression (High Speed)${NC}"
    elif command -v gzip >/dev/null 2>&1; then
        compressor="gzip -1"
        echo -e "${YELLOW}[+] Using GZIP compression (Fallback)${NC}"
    else
        echo -e "${RED}[!] No compressor found. Sending raw data.${NC}"
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_dir="../dumps"
    mkdir -p "$output_dir"

    echo -e "${GREEN}[+] Streaming memory to $target_ip:$target_port...${NC}"
    echo -e "${YELLOW}[*] Calculating local integrity hash (SHA256) during stream...${NC}"

    if dd if=/dev/mem bs=1M count=100 2>/dev/null | \
       tee >(sha256sum > "$output_dir/remote_stream_$timestamp.sha256") | \
       $compressor | nc "$target_ip" "$target_port"; then
        echo -e "${GREEN}[+] Remote stream finished successfully.${NC}"
    else
        echo -e "${RED}[!] Stream interrupted. Potential Kernel restriction (STRICT_DEVMEM).${NC}"
        echo -e "${YELLOW}[i] Hint: Try booting with 'iomem=relaxed'.${NC}"
    fi
}

while true; do
    clear
    echo -e "${GREEN}🐧 S.I.R.E.N. - Shell Interactive Runtime Entity Notifier${NC}"
    echo "---------------------------------------------------------"
    echo -e "1) Map Memory (iomem)"
    echo -e "2) Test Pipeline (/proc/version)"
    echo -e "3) Live Memory Extraction (DANGEROUS)"
    echo -e "4) Automated Safe Scan (BETA)"
    echo -e "5) Remote Forensic Stream (Netcat)"
    echo -e "6) Exit"
    echo "---------------------------------------------------------"
    read -p "Select an option: " opt

    case $opt in
        1) map_system_ram ;;
        2) stream_analysis "/proc/version" ;;
        3)
            echo -e "${RED}⚠️  ACTION REQUIRED: Bypass reserved ranges?${NC}"
            read -p "Continue with 100MB sample from /dev/mem? (y/n): " confirm
            [[ $confirm == "y" ]] && stream_analysis "/dev/mem"
            ;;
        4) automated_extraction ;;
        5) remote_forensic_stream ;;
        6) 
            echo -e "${YELLOW}Exiting SIREN...${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Invalid option.${NC}" 
            sleep 1
            continue
            ;;
    esac

    echo -e "\n${YELLOW}-- Press ENTER to return to menu --${NC}"
    read
done
