#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

check_command_exists() {
    local command="$1"

    if ! command -v "$command" >/dev/null 2>&1; then
        log_error "Command '$command' not found."
        return 1
    fi
}

check_one_of_commands_exists() {
    local commands=("$@")

    for command in "${commands[@]}"; do
        check_command_exists "$command" >/dev/null 2>&1 && return 0 || true
    done

    return 1
}
