#!/usr/bin/env bash
set -euo pipefail
umask 022

# ============================================================
# S.I.R.E.N — Shell Interactive Runtime Entity Notifier
# Audit-aware memory acquisition for Linux forensic triage.
# ============================================================

RED='\033[0;31m'; YELLOW='\033[1;33m'
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${RED}[!] Error: Elevated privileges required.${NC}" && exit 1

# --- Paths ---------------------------------------------------
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
BASE_DUMPS_DIR="$PROJECT_ROOT/dumps"
BIN_DIR="$BASE_DUMPS_DIR/binaries"
REP_DIR="$BASE_DUMPS_DIR/reports"
CHK_DIR="$BASE_DUMPS_DIR/checksums"
LOG_FILE="$BASE_DUMPS_DIR/siren.log"
LINSPEC_REPORT="${LINSPEC_REPORT:-$(dirname "$PROJECT_ROOT")/LinSpec/reports/report.json}"

mkdir -p "$BIN_DIR" "$REP_DIR" "$CHK_DIR"

# --- Lib sources ---------------------------------------------
# shellcheck source=../lib/audit.sh
source "$PROJECT_ROOT/lib/audit.sh"
# shellcheck source=../lib/safety.sh
source "$PROJECT_ROOT/lib/safety.sh"
# shellcheck source=../lib/acquisition.sh
source "$PROJECT_ROOT/lib/acquisition.sh"
# shellcheck source=../lib/reporting.sh
source "$PROJECT_ROOT/lib/reporting.sh"

# --- State ---------------------------------------------------
LOADED_AUDIT=false
AUDIT_KPTR=1; AUDIT_PTRACE=1; AUDIT_SPECTRE=1
AUDIT_MELTDOWN=1; AUDIT_DEVMEM=1
INTERACTIVE=true
OUTPUT_DIR=""

# ------------------------------------------------------------
# CLI
# ------------------------------------------------------------
usage() {
    cat <<EOF
Usage: sudo ./src/siren.sh [OPTION]

Options:
  --quick        Quick triage dump (first 100MB via /proc/kcore)
  --full         Full acquisition (ELF-aware /proc/kcore extraction)
  --test         Test acquisition pipeline
  --map          Display System RAM regions from /proc/iomem
  --output DIR   Custom output directory (default: ./dumps/)
  --help         Show this help

Without options, starts the interactive menu.
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) INTERACTIVE=false; MODE="quick"; shift ;;
        --full)  INTERACTIVE=false; MODE="full"; shift ;;
        --test)  INTERACTIVE=false; MODE="test"; shift ;;
        --map)   INTERACTIVE=false; MODE="map"; shift ;;
        --output) shift; OUTPUT_DIR="$1"; shift ;;
        --help)  usage ;;
        *) echo -e "${RED}[!] Unknown option: $1${NC}"; usage ;;
    esac
done

if [[ -n "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
    BIN_DIR="$OUTPUT_DIR"
    REP_DIR="$OUTPUT_DIR/reports"
    CHK_DIR="$OUTPUT_DIR/checksums"
    mkdir -p "$REP_DIR" "$CHK_DIR"
    LOG_FILE="$OUTPUT_DIR/siren.log"
fi

# ------------------------------------------------------------
# Core run function
# ------------------------------------------------------------
run_acquisition() {
    local method=$1 source_desc=$2
    local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$BIN_DIR/${method}_${timestamp}.bin"

    log_operation "Starting $method acquisition ($source_desc)"

    case "$method" in
        quick)
            quick_triage_kcore "$output_file"
            ;;
        full)
            full_acquisition_kcore "$output_file"
            ;;
        test)
            test_pipeline "$output_file"
            ;;
        *)
            echo -e "${RED}[!] Unknown method: $method${NC}"
            return 1
            ;;
    esac

    log_operation "Acquisition complete: $output_file"

    if [[ ! -s "$output_file" ]]; then
        echo -e "${RED}[!] Acquisition produced empty output${NC}"
        log_operation "FAILED: empty output"
        return 1
    fi

    echo -e "${CYAN}[*] Validating dump content...${NC}"
    validate_dump_content "$output_file" || log_operation "WARNING: content validation failed"

    local hash
    hash=$(compute_hashes "$output_file" "$CHK_DIR" "${method}_${timestamp}.bin")
    echo -e "${GREEN}[+] SHA256: $hash${NC}"

    local strings_file="$BIN_DIR/${method}_${timestamp}.txt"
    extract_strings "$output_file" "$strings_file"

    generate_reports "$output_file" "$source_desc" "$hash" "$timestamp"

    if [[ -f "${output_file}.meta.json" ]]; then
        echo -e "${GREEN}[+] Segment metadata: ${output_file}.meta.json${NC}"
    fi

    log_operation "Completed $method acquisition"
}

# ------------------------------------------------------------
# Non-interactive mode
# ------------------------------------------------------------
if ! $INTERACTIVE; then
    load_linspec_audit || true
    print_audit_status

    case "$MODE" in
        map)
            map_system_ram
            ;;
        test)
            run_acquisition test "/proc/cpuinfo"
            ;;
        quick)
            run_acquisition quick "/proc/kcore (quick triage)"
            ;;
        full)
            run_acquisition full "/proc/kcore (ELF extraction)"
            ;;
    esac
    exit 0
fi

# ------------------------------------------------------------
# Interactive menu
# ------------------------------------------------------------
trap 'echo -e "${RED}[!] Interrupted.${NC}"; exit 1' INT TERM

while true; do
    clear
    load_linspec_audit || true

    echo -e "\n${GREEN}S.I.R.E.N - Shell Interactive Runtime Entity Notifier${NC}"
    print_audit_status
    echo -e "${CYAN}---------------------------------------------------------${NC}"
    echo "1) Map Physical RAM (iomem)"
    echo "2) Test Acquisition Pipeline"
    echo "3) Quick Triage Dump (100MB via /proc/kcore)"
    echo "4) Full Memory Acquisition (/proc/kcore ELF)"
    echo "5) Exit"
    echo -e "${CYAN}---------------------------------------------------------${NC}"

    read -rp "Select an option: " opt
    case $opt in
        1) map_system_ram ;;
        2) run_acquisition test "/proc/cpuinfo" ;;
        3) check_storage; run_acquisition quick "/proc/kcore (quick triage)" ;;
        4) check_storage; run_acquisition full "/proc/kcore (ELF extraction)" ;;
        5)
            log_operation "Session ended"
            exit 0
            ;;
        *) sleep 1 ;;
    esac

    echo -e "\n${CYAN}-- Press ENTER to return to menu --${NC}"
    read -r
done
