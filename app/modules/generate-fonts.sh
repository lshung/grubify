#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "generate-fonts" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
        check_required_commands_exist || return 1
    fi

    parse_font_config_values || { log_failed "Failed to parse font config values."; return 1; }
    download_required_fonts || { log_failed "Failed to download required fonts."; return 1; }
    convert_fonts || { log_failed "Failed to convert fonts."; return 1; }
}

parse_arguments() {
    log_info "Parsing arguments..."

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE="yes"
                ;;
            *)
                log_error "Invalid option '$1'."
                show_usage
                exit 1
                ;;
        esac
        shift
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Parsed arguments successfully." || true
}

show_usage() {
    echo "Usage: $APP_NAME_LOWER generate-fonts [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

check_required_commands_exist() {
    log_info "Checking required commands exist..."

    check_command_exists "grub-mkfont" || return 1
    check_one_of_commands_exists "curl" "wget" || { log_error "Command 'curl' or 'wget' not found."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "All required commands exist." || true
}

parse_font_config_values() {
    log_info "Parsing font config values..."

    UNIFONT_REGULAR_SIZES=()
    TERMINUS_REGULAR_SIZES=()
    TERMINUS_BOLD_SIZES=()

    add_font_size_to_array_if_not_exists "$TERMINAL_FONT_NAME" "$TERMINAL_FONT_SIZE"
    add_font_size_to_array_if_not_exists "$ITEM_FONT_NAME" "$ITEM_FONT_SIZE"
    add_font_size_to_array_if_not_exists "$SELECTED_ITEM_FONT_NAME" "$SELECTED_ITEM_FONT_SIZE"
    add_font_size_to_array_if_not_exists "$COUNTDOWN_FONT_NAME" "$COUNTDOWN_FONT_SIZE"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Parsed font config values successfully." || true
}

add_font_size_to_array_if_not_exists() {
    local font_name="$1"
    local font_size="$2"

    if [[ "$font_name" =~ "Unifont Regular" ]] && [[ ! "${UNIFONT_REGULAR_SIZES[@]}" =~ "$font_size" ]]; then
        UNIFONT_REGULAR_SIZES+=("$font_size")
    elif [[ "$font_name" =~ "Terminus Regular" ]] && [[ ! "${TERMINUS_REGULAR_SIZES[@]}" =~ "$font_size" ]]; then
        TERMINUS_REGULAR_SIZES+=("$font_size")
    elif [[ "$font_name" =~ "Terminus Bold" ]] && [[ ! "${TERMINUS_BOLD_SIZES[@]}" =~ "$font_size" ]]; then
        TERMINUS_BOLD_SIZES+=("$font_size")
    fi
}

download_required_fonts() {
    log_info "Downloading required fonts..."

    rm -rf "$TEMP_DIR/fonts"
    mkdir -p "$TEMP_DIR/fonts"

    if [[ "${#UNIFONT_REGULAR_SIZES[@]}" -gt 0 ]]; then
        download_font "unifont" || return 1
    fi

    if [[ "${#TERMINUS_REGULAR_SIZES[@]}" -gt 0 || "${#TERMINUS_BOLD_SIZES[@]}" -gt 0 ]]; then
        download_font "terminus" || return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded required fonts successfully." || true
}

convert_fonts() {
    log_info "Converting fonts..."

    if [[ "${#UNIFONT_REGULAR_SIZES[@]}" -gt 0 ]]; then
        convert_font_to_pf2_format "unifont-regular" "${UNIFONT_REGULAR_SIZES[@]}" || return 1
    fi

    if [[ "${#TERMINUS_REGULAR_SIZES[@]}" -gt 0 ]]; then
        convert_font_to_pf2_format "terminus-regular" "${TERMINUS_REGULAR_SIZES[@]}" || return 1
    fi

    if [[ "${#TERMINUS_BOLD_SIZES[@]}" -gt 0 ]]; then
        convert_font_to_pf2_format "terminus-bold" "${TERMINUS_BOLD_SIZES[@]}" || return 1
    fi

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Converted fonts saved to '$TEMP_DIR/fonts'."
        log_info "You can list them by running command 'ls -l $TEMP_DIR/fonts/*.pf2'."
        log_ok "Done."
    fi
}

main "$@"
