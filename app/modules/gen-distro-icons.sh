#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "gen-distro-icons" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
    fi

    generate_menu_item_icons || { log_failed "Failed to generate menu item icons."; return 1; }

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Menu item icons saved to '$TEMP_DIR/icons'."
        log_info "You can list them by running command 'ls -l $TEMP_DIR/icons/*.png'."
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
    echo "Usage: $APP_NAME_LOWER gen-distro-icons [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

generate_menu_item_icons() {
    log_info "Generating menu item icons..."

    rm -rf "$TEMP_DIR/icons"
    mkdir -p "$TEMP_DIR/icons"

    for file in "$APP_TEMPLATES_ICONS_DIR/$ICON_THEME"/*.svg; do
        rsvg-convert -d 1000 -w "$ICON_SIZE" -h "$ICON_SIZE" "$file" -o "$TEMP_DIR/icons/$(basename "$file" .svg).png" || return 1
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated menu item icons successfully." || true
}

main "$@"
