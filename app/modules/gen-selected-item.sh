#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "gen-selected-item" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
    fi

    generate_selected_item_assets || { log_failed "Failed to generate selected item assets."; return 1; }

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Selected item assets saved to '$TEMP_DIR'."
        log_info "You can list them by running command 'ls -l $TEMP_DIR/select_*.png'."
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
    echo "Usage: $APP_NAME_LOWER gen-selected-item [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

generate_selected_item_assets() {
    log_info "Generating selected item assets..."

    mkdir -p "$TEMP_DIR"
    cp "$APP_TEMPLATES_SELECT_DIR"/select_*.svg "$TEMP_DIR"/ || return 1

    [ -z "$SELECTED_ITEM_BACKGROUND_COLOR" ] && SELECTED_ITEM_BACKGROUND_COLOR="$THEME_ACCENT_COLOR" || true

    for file_name in "select_c" "select_w" "select_e"; do
        sed -i "s/fill=\".*\"/fill=\"$SELECTED_ITEM_BACKGROUND_COLOR\"/g" "$TEMP_DIR/$file_name.svg" || return 1
        rsvg-convert -d 1000 -h "$ITEM_HEIGHT" "$TEMP_DIR/$file_name.svg" -o "$TEMP_DIR/$file_name.png" || return 1
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated selected item assets successfully." || true
}

main "$@"
