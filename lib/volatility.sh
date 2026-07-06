# shellcheck shell=bash

detect_volatility() {
    if command -v volatility &>/dev/null; then
        VOLATILITY_BIN="volatility"
        VOLATILITY_MAJOR=2
    elif command -v vol &>/dev/null; then
        VOLATILITY_BIN="vol"
        VOLATILITY_MAJOR=3
    else
        VOLATILITY_BIN=""
        VOLATILITY_MAJOR=0
    fi
}

match_volatility_profile() {
    local dump_path=$1
    VOLATILITY_PROFILE=""
    VOLATILITY_PLATFORM=""

    detect_volatility

    if [[ -z "$VOLATILITY_BIN" ]]; then
        echo -e "${YELLOW}[!] Volatility not found, skipping profile matching${NC}"
        return 1
    fi

    # shellcheck disable=SC2034
    VOLATILITY_PLATFORM="linux"
    local timeout_bin
    timeout_bin=$(command -v timeout 2>/dev/null || echo "")

    if [[ "$VOLATILITY_MAJOR" -eq 2 ]]; then
        local cmd
        if [[ -n "$timeout_bin" ]]; then
            cmd="$timeout_bin 120 $VOLATILITY_BIN -f \"$dump_path\" imageinfo 2>/dev/null"
        else
            cmd="$VOLATILITY_BIN -f \"$dump_path\" imageinfo 2>/dev/null"
        fi
        local out
        out=$(eval "$cmd") || {
            echo -e "${YELLOW}[!] volatility imageinfo failed or timed out${NC}"
            return 1
        }
        VOLATILITY_PROFILE=$(echo "$out" | grep "Suggested Profile(s)" | sed 's/.*: //' | head -1)
    elif [[ "$VOLATILITY_MAJOR" -eq 3 ]]; then
        local cmd
        if [[ -n "$timeout_bin" ]]; then
            cmd="$timeout_bin 60 $VOLATILITY_BIN -f \"$dump_path\" linux.info 2>/dev/null"
        else
            cmd="$VOLATILITY_BIN -f \"$dump_path\" linux.info 2>/dev/null"
        fi
        local out
        out=$(eval "$cmd") || {
            echo -e "${YELLOW}[!] volatility linux.info failed${NC}"
            return 1
        }
        VOLATILITY_PROFILE=$(echo "$out" | grep -i "Distro\|Profile\|Platform" | head -1 | awk -F': ' '{print $2}')
    fi

    if [[ -n "$VOLATILITY_PROFILE" ]]; then
        echo -e "${GREEN}[+] Volatility profile: $VOLATILITY_PROFILE${NC}"
    else
        echo -e "${YELLOW}[!] Could not determine Volatility profile${NC}"
        return 1
    fi
}
