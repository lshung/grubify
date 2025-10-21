#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "gen-fonts" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
    fi

    parse_font_config_values || { log_failed "Failed to parse font config values."; return 1; }
    download_required_fonts || { log_failed "Failed to download required fonts."; return 1; }
    convert_fonts || { log_failed "Failed to convert fonts."; return 1; }

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Fonts saved to '$TEMP_DIR/fonts'."
        log_info "You can list them by running command 'ls -l $TEMP_DIR/fonts/*.pf2'."
        log_ok "Done."
    fi
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
    echo "Usage: $APP_NAME_LOWER gen-fonts [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
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
    add_font_size_to_array_if_not_exists "$CIRCULAR_PROGRESS_COUNTDOWN_FONT_NAME" "$CIRCULAR_PROGRESS_COUNTDOWN_FONT_SIZE"

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
    mkdir -p "$APP_DATA_DIR/fonts"

    if [[ "${#UNIFONT_REGULAR_SIZES[@]}" -gt 0 ]]; then
        download_font_unifont_if_not_exists || return 1
    fi

    if [[ "${#TERMINUS_REGULAR_SIZES[@]}" -gt 0 || "${#TERMINUS_BOLD_SIZES[@]}" -gt 0 ]]; then
        download_font_terminus_if_not_exists || return 1
        extract_font_terminus || return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded required fonts successfully." || true
}

download_font_unifont_if_not_exists() {
    [[ -f "$APP_DATA_DIR/fonts/unifont.otf" ]] && return 0 || true

    [[ "$VERBOSE" == "yes" ]] && log_info "Downloading font 'Unifont'..." || true

    local url="https://raw.githubusercontent.com/lshung/grubify-assets/master/fonts/unifont.otf"

    download_with_retry "$url" "$APP_DATA_DIR/fonts/unifont.otf" || { log_failed "Failed to download font 'Unifont'."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded font 'Unifont' successfully." || true
}

download_font_terminus_if_not_exists() {
    [[ -f "$APP_DATA_DIR/fonts/terminus.tar.gz" ]] && return 0 || true

    [[ "$VERBOSE" == "yes" ]] && log_info "Downloading font 'Terminus'..." || true

    local url="https://raw.githubusercontent.com/lshung/grubify-assets/master/fonts/terminus.tar.gz"

    download_with_retry "$url" "$APP_DATA_DIR/fonts/terminus.tar.gz" || { log_failed "Failed to download font 'Terminus'."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded font 'Terminus' successfully." || true
}

extract_font_terminus() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Extracting file 'terminus.tar.gz'..." || true

    rm -rf "$APP_DATA_DIR/fonts/terminus"/*
    mkdir -p "$APP_DATA_DIR/fonts/terminus"

    tar -xzf "$APP_DATA_DIR/fonts/terminus.tar.gz" -C "$APP_DATA_DIR/fonts/terminus" || { log_failed "Failed to extract file 'terminus.tar.gz'."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Extracted file 'terminus.tar.gz' successfully." || true
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

    [[ "$VERBOSE" == "yes" ]] && log_ok "Converted fonts successfully." || true
}

convert_font_to_pf2_format() {
    local font_name="$1"

    if [[ "$font_name" != "unifont-regular" ]] && [[ "$font_name" != "terminus-regular" ]] && [[ "$font_name" != "terminus-bold" ]]; then
        log_error "Invalid font name '$font_name'."
        return 1
    fi

    shift
    local sizes=("$@")
    local font_name_capitalized=$(echo "$font_name" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')

    for size in "${sizes[@]}"; do
        [[ "$VERBOSE" == "yes" ]] && log_info "Converting font '$font_name_capitalized ${size}' to PF2 format..." || true

        if [[ "$font_name" == "unifont-regular" ]]; then
            local input_file="$APP_DATA_DIR/fonts/unifont.otf"
        elif [[ "$font_name" == "terminus-regular" ]]; then
            local input_file="$APP_DATA_DIR/fonts/terminus/ter-u${size}n.bdf"
        elif [[ "$font_name" == "terminus-bold" ]]; then
            local input_file="$APP_DATA_DIR/fonts/terminus/ter-u${size}b.bdf"
        fi

        local output_file="$TEMP_DIR/fonts/${font_name}-${size}.pf2"

        if grub-mkfont -o "$output_file" -s "$size" "$input_file" 2>&1 | grep -i "error\|failed"; then
            log_failed "Failed to convert font '$font_name_capitalized ${size}'."
            return 1
        fi

        [[ "$VERBOSE" == "yes" ]] && log_ok "Converted font '$font_name_capitalized ${size}' successfully." || true
    done
}

main "$@"
