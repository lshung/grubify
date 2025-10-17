#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

download_font() {
    local font_name="$1"

    if [[ "$font_name" == "unifont" ]]; then
        download_font_unifont || return 1
    elif [[ "$font_name" == "terminus" ]]; then
        download_font_terminus || return 1
    fi
}

download_font_unifont() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Downloading font 'Unifont'..." || true

    local url="https://unifoundry.com/pub/unifont/unifont-17.0.01/font-builds/unifont-17.0.01.otf"
    download_with_retry "$url" "$TEMP_DIR/fonts/unifont.otf" || { log_failed "Failed to download font 'Unifont'."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded font 'Unifont' successfully." || true
}

download_font_terminus() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Downloading font 'Terminus'..." || true

    local url="https://sourceforge.net/projects/terminus-font/files/terminus-font-4.49/terminus-font-4.49.1.tar.gz/download"
    download_with_retry "$url" "$TEMP_DIR/fonts/terminus.tar.gz" || { log_failed "Failed to download font 'Terminus'."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded font 'Terminus' successfully." || true

    [[ "$VERBOSE" == "yes" ]] && log_info "Extracting file 'terminus.tar.gz'..." || true

    tar -xzf "$TEMP_DIR/fonts/terminus.tar.gz" -C "$TEMP_DIR/fonts" || { log_failed "Failed to extract file 'terminus.tar.gz'."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Extracted file 'terminus.tar.gz' successfully." || true
}

convert_font_to_pf2_format() {
    local font_name="$1"
    shift
    local font_sizes=("$@")

    if [[ "$font_name" == "unifont-regular" ]]; then
        convert_unifont_regular_to_pf2_format "${font_sizes[@]}" || return 1
    elif [[ "$font_name" == "terminus-regular" ]]; then
        convert_terminus_regular_to_pf2_format "${font_sizes[@]}" || return 1
    elif [[ "$font_name" == "terminus-bold" ]]; then
        convert_terminus_bold_to_pf2_format "${font_sizes[@]}" || return 1
    fi
}

convert_unifont_regular_to_pf2_format() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Converting font 'Unifont Regular' to PF2 format..." || true

    local sizes=("$@")

    for size in "${sizes[@]}"; do
        [[ "$VERBOSE" == "yes" ]] && log_info "Converting font 'Unifont Regular' size '${size}'..." || true

        if ! grub-mkfont -o "$TEMP_DIR/fonts/unifont-regular-${size}.pf2" -s "$size" "$TEMP_DIR/fonts/unifont.otf"; then
            log_failed "Failed to convert font 'Unifont Regular' size '${size}'."
            return 1
        fi
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Converted font 'Unifont Regular' successfully." || true
}

convert_terminus_regular_to_pf2_format() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Converting font 'Terminus Regular' to PF2 format..." || true

    local sizes=("$@")
    local extracted_dir=$(find "$TEMP_DIR/fonts" -maxdepth 1 -mindepth 1 -type d | head -n 1)

    for size in "${sizes[@]}"; do
        [[ "$VERBOSE" == "yes" ]] && log_info "Converting font 'Terminus Regular' size '${size}'..." || true

        if ! grub-mkfont -o "$TEMP_DIR/fonts/terminus-regular-${size}.pf2" -s "$size" "$extracted_dir/ter-u${size}n.bdf"; then
            log_failed "Failed to convert font 'Terminus Regular' size '${size}'."
            return 1
        fi
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Converted font 'Terminus Regular' successfully." || true
}

convert_terminus_bold_to_pf2_format() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Converting font 'Terminus Bold' to PF2 format..." || true

    local sizes=("$@")
    local extracted_dir=$(find "$TEMP_DIR/fonts" -maxdepth 1 -mindepth 1 -type d | head -n 1)

    for size in "${sizes[@]}"; do
        [[ "$VERBOSE" == "yes" ]] && log_info "Converting font 'Terminus Bold' size '${size}'..." || true

        if ! grub-mkfont -o "$TEMP_DIR/fonts/terminus-bold-${size}.pf2" -s "$size" "$extracted_dir/ter-u${size}b.bdf"; then
            log_failed "Failed to convert font 'Terminus Bold' size '${size}'."
            return 1
        fi
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Converted font 'Terminus Bold' successfully." || true
}
