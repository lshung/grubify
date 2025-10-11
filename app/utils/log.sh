#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

readonly NC='\033[0m'           # Reset color
readonly RED='\033[0;31m'       # Red
readonly GREEN='\033[0;32m'     # Green
readonly YELLOW='\033[0;33m'    # Yellow

log_message() {
    local level="$1"
    local message="$2"

    if [[ "$LOG_TIMESTAMP_INCLUDED" == "yes" ]]; then
        local timestamp="[$(date '+%Y-%m-%d %H:%M:%S')] "
    else
        local timestamp=""
    fi

    case "$level" in
        "EMPTY")
            echo ""
            ;;
        "INFO")
            echo "$timestamp[ INFO ] $message"
            ;;
        "WARNING")
            echo -e "$timestamp[${YELLOW} WARN ${NC}] $message" 1>&2
            ;;
        "ERROR")
            echo -e "$timestamp[${RED} ERRO ${NC}] $message" 1>&2
            ;;
        "OK")
            echo -e "$timestamp[${GREEN}  OK  ${NC}] $message"
            ;;
        "FAILED")
            echo -e "$timestamp[${RED}FAILED${NC}] $message" 1>&2
            ;;
    esac
}

log_empty_line() {
    log_message "EMPTY"
}

log_info() {
    log_message "INFO" "$1"
}

log_warning() {
    log_message "WARNING" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_ok() {
    log_message "OK" "$1"
}

log_failed() {
    log_message "FAILED" "$1"
}
