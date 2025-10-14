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
    local url="https://unifoundry.com/pub/unifont/unifont-17.0.01/font-builds/unifont-17.0.01.otf"

    curl -L -s -o "$TEMP_DIR/fonts/unifont.otf" "$url" || return 1
}

download_font_terminus() {
    local url="https://sourceforge.net/projects/terminus-font/files/terminus-font-4.49/terminus-font-4.49.1.tar.gz/download"

    curl -L -s -o "$TEMP_DIR/fonts/terminus.tar.gz" "$url" || return 1
}

convert_font_to_pf2_format() {
    local font_name="$1"

    if [[ "$font_name" == "unifont" ]]; then
        convert_unifont_to_pf2_format || return 1
    elif [[ "$font_name" == "terminus" ]]; then
        convert_terminus_to_pf2_format || return 1
    fi
}

convert_unifont_to_pf2_format() {
    local sizes=(16 18 20 22 24 26 28 30 32)

    for size in "${sizes[@]}"; do
        grub-mkfont -o "$TEMP_DIR/fonts/unifont-${size}.pf2" -s "$size" "$TEMP_DIR/fonts/unifont.otf"
    done
}

convert_terminus_to_pf2_format() {
    local sizes=(12 14 16 18 20 22 24 28 32)

    tar -xzf "$TEMP_DIR/fonts/terminus.tar.gz" -C "$TEMP_DIR/fonts" || return 1
    local extracted_dir=$(find "$TEMP_DIR/fonts" -maxdepth 1 -mindepth 1 -type d | head -n 1)

    for size in "${sizes[@]}"; do
        grub-mkfont -o "$TEMP_DIR/fonts/terminus-${size}.pf2" -s "$size" "$extracted_dir/ter-u${size}n.bdf"
        grub-mkfont -o "$TEMP_DIR/fonts/terminus-bold-${size}.pf2" -s "$size" "$extracted_dir/ter-u${size}b.bdf"
    done
}
