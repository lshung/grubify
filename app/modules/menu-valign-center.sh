#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "menu-valign-center" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
    fi

    show_grub_menu_entries || return 1
    calculate_menu_geometry || { log_failed "Failed to calculate menu geometry."; return 1; }
    update_new_menu_top_and_height || { log_failed "Failed to update new menu top and height."; return 1; }

    if [[ "$IS_SOURCED" == "no" ]]; then
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
    echo "Usage: $APP_NAME_LOWER menu-valign-center [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

show_grub_menu_entries() {
    get_grub_menu_entries >/dev/null || return 1

    MENU_ENTRIES_COUNT="$(get_grub_menu_entries | wc -l)"
    [[ "$VERBOSE" == "yes" ]] && log_info "GRUB menu entries count: $MENU_ENTRIES_COUNT" || true

    local grub_menu_entries=()
    while IFS= read -r line; do
        grub_menu_entries+=("$line")
    done < <(get_grub_menu_entries)

    [[ "$VERBOSE" == "yes" ]] && log_info "GRUB menu entries list:" || true
    for entry in "${grub_menu_entries[@]}"; do
        [[ "$VERBOSE" == "yes" ]] && log_info "    - $entry" || true
    done
}

calculate_menu_geometry() {
    log_info "Calculating menu geometry..."

    NEW_MENU_HEIGHT=$(( (ITEM_HEIGHT * MENU_ENTRIES_COUNT) + ITEM_SPACING * (MENU_ENTRIES_COUNT - 1) ))
    [[ "$VERBOSE" == "yes" ]] && log_info "Calculated menu height: $NEW_MENU_HEIGHT" || true

    parse_grub_geometry "$CONTAINER_HEIGHT" "$SCREEN_HEIGHT" >/dev/null \
        && PARSED_CONTAINER_HEIGHT="$(parse_grub_geometry "$CONTAINER_HEIGHT" "$SCREEN_HEIGHT")" || return 1
    [[ "$VERBOSE" == "yes" ]] && log_info "Parsed container height: $PARSED_CONTAINER_HEIGHT" || true

    parse_grub_geometry "$CONTAINER_TOP" "$SCREEN_HEIGHT" >/dev/null \
        && PARSED_CONTAINER_TOP="$(parse_grub_geometry "$CONTAINER_TOP" "$SCREEN_HEIGHT")" || return 1
    [[ "$VERBOSE" == "yes" ]] && log_info "Parsed container top: $PARSED_CONTAINER_TOP" || true

    NEW_MENU_TOP=$(( PARSED_CONTAINER_TOP + (PARSED_CONTAINER_HEIGHT - NEW_MENU_HEIGHT) / 2 ))
    [[ "$VERBOSE" == "yes" ]] && log_info "Calculated new menu top: $NEW_MENU_TOP" || true

    [[ "$VERBOSE" == "yes" ]] && log_ok "Calculated menu geometry successfully." || true
}

update_new_menu_top_and_height() {
    log_info "Updating new menu top and height..."

    local theme_file="${GRUB_THEME_DIR}/theme.txt"

    sudo sed -i "/^+ boot_menu {/,/^}/ s/top = .*/top = $NEW_MENU_TOP/" "$theme_file" || {
        log_error "Failed to update menu top in theme file."
        return 1
    }

    sudo sed -i "/^+ boot_menu {/,/^}/ s/^\(\s*\)height = .*/\\1height = $NEW_MENU_HEIGHT/" "$theme_file" || {
        log_error "Failed to update menu height in theme file."
        return 1
    }

    [[ "$VERBOSE" == "yes" ]] && log_ok "Updated new menu top and height successfully." || true
}

main "$@"
