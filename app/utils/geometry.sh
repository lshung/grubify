#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

parse_grub_geometry() {
    local input_value="$1"
    local total_pixels="$2"

    validate_geometry_inputs "$input_value" "$total_pixels" || return 1

    parse_pure_pixels "$input_value" && return 0 || true
    parse_percentage "$input_value" "$total_pixels" && return 0 || true
    parse_percentage_with_offset "$input_value" "$total_pixels" "+" && return 0 || true
    parse_percentage_with_offset "$input_value" "$total_pixels" "-" && return 0 || true

    log_error "Invalid GRUB geometry format '$input_value'. Valid formats are 'x', 'p%', 'p%+x', 'p%-x'."
    return 1
}

validate_geometry_inputs() {
    local input_value="$1"
    local total_pixels="$2"

    if [[ -z "$input_value" || -z "$total_pixels" ]]; then
        log_error "Both input value and total pixels are required."
        return 1
    fi

    if ! [[ "$total_pixels" =~ ^[0-9]+$ ]]; then
        log_error "Total pixels must be a positive integer."
        return 1
    fi
}

parse_pure_pixels() {
    local input_value="$1"

    if [[ "$input_value" =~ ^[0-9]+$ ]]; then
        echo "$input_value"
        return 0
    fi
    return 1
}

parse_percentage() {
    local input_value="$1"
    local total_pixels="$2"

    if [[ "$input_value" =~ ^([0-9]+)%$ ]]; then
        local percent="${BASH_REMATCH[1]}"
        local result=$(( total_pixels * percent / 100 ))
        echo "$result"
        return 0
    fi
    return 1
}

parse_percentage_with_offset() {
    local input_value="$1"
    local total_pixels="$2"
    local operation="$3"

    local pattern="^([0-9]+)%\\${operation}([0-9]+)$"
    if [[ "$input_value" =~ $pattern ]]; then
        local percent="${BASH_REMATCH[1]}"
        local pixels="${BASH_REMATCH[2]}"
        local base=$(( total_pixels * percent / 100 ))
        local result=$(( base $operation pixels ))
        echo "$result"
        return 0
    fi
    return 1
}
