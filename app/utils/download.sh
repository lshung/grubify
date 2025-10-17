#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

readonly DOWNLOAD_MAX_RETRIES=3
readonly DOWNLOAD_TIMEOUT=30

download_with_retry() {
    local url="$1"
    local output="$2"
    local retry_count=1

    while [ $retry_count -le $DOWNLOAD_MAX_RETRIES ]; do
        [[ "$VERBOSE" == "yes" ]] && log_info "Downloading '$(basename "$output")' (attempt $retry_count/$DOWNLOAD_MAX_RETRIES)..." || true

        if check_command_exists "curl"; then
            try_to_download_via_curl "$url" "$output" && return 0 || true
        elif check_command_exists "wget"; then
            try_to_download_via_wget "$url" "$output" && return 0 || true
        else
            log_error "No command 'curl' or 'wget' found."
            return 1
        fi

        retry_count=$(( retry_count + 1 ))
        should_retry_to_download "$retry_count" || return 1
    done
}

try_to_download_via_curl() {
    local url="$1"
    local output="$2"

    curl -LsS \
        --max-time $DOWNLOAD_TIMEOUT \
        -o "$output" \
        "$url" >/dev/null 2>&1 || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded '$(basename "$output")' successfully." || true
}

try_to_download_via_wget() {
    local url="$1"
    local output="$2"

    wget --quiet \
        --timeout=$DOWNLOAD_TIMEOUT \
        -O "$output" \
        "$url" >/dev/null 2>&1 || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded '$(basename "$output")' successfully." || true
}

should_retry_to_download() {
    local retry_count="$1"

    if [ $retry_count -le $DOWNLOAD_MAX_RETRIES ]; then
        [[ "$VERBOSE" == "yes" ]] && log_warning "Download failed, retrying after 3 seconds..." || true
        sleep 3
    else
        [[ "$VERBOSE" == "yes" ]] && log_failed "Download failed after $DOWNLOAD_MAX_RETRIES attempts." || true
        return 1
    fi
}
