#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "gen-theme-file" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
        check_required_commands_exist || return 1
    fi

    remove_invisible_components_from_theme_txt || { log_failed "Failed to remove invisible components from 'theme.txt'."; return 1; }
    substitute_variables_in_theme_txt || { log_failed "Failed to substitute variables in theme.txt."; return 1; }

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Theme file saved to '$TEMP_DIR/theme.txt'."
        log_info "You can preview it by running command 'cat $TEMP_DIR/theme.txt'."
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
    echo "Usage: $APP_NAME_LOWER gen-theme-file [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

check_required_commands_exist() {
    log_info "Checking required commands exist..."

    check_command_exists "awk" || return 1
    check_command_exists "envsubst" || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "All required commands exist." || true
}

remove_invisible_components_from_theme_txt() {
    log_info "Removing invisible components from 'theme.txt'..."

    mkdir -p "$TEMP_DIR"
    cp "$APP_TEMPLATES_DIR/theme.txt" "$TEMP_DIR/theme.txt"

    if [[ "$PROGRESS_BAR_VISIBLE" == "no" ]]; then
        awk '/^+ progress_bar {/{f=1} !f; /^}/&&f{f=0}' "$TEMP_DIR/theme.txt" > "$TEMP_DIR/theme.tmp"
        mv "$TEMP_DIR/theme.tmp" "$TEMP_DIR/theme.txt"
    fi

    if [[ "$COUNTDOWN_VISIBLE" == "no" ]]; then
        remove_label_block_with_search_pattern "\\\$COUNTDOWN_" || return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Removed invisible components from 'theme.txt' successfully." || true
}

remove_label_block_with_search_pattern() {
    local search_pattern="$1"

    awk '
        /^+ label {/ { found = 1; block = "" }
        found { block = block $0 ORS }
        /^}/ && found {
            if (block ~ /'"$search_pattern"'/) { found = 0 }
            else { printf "%s", block; found = 0 }
            next
        }
        !found
    ' "$TEMP_DIR/theme.txt" > "$TEMP_DIR/theme.tmp"
    mv "$TEMP_DIR/theme.tmp" "$TEMP_DIR/theme.txt"
}

substitute_variables_in_theme_txt() {
    log_info "Substituting variables in file 'theme.txt'..."

    export TERMINAL_FONT_NAME TERMINAL_FONT_SIZE
    export MENU_WIDTH MENU_HEIGHT MENU_LEFT MENU_TOP
    export ITEM_COLOR SELECTED_ITEM_COLOR ITEM_HEIGHT ITEM_PADDING ITEM_SPACING
    export ITEM_FONT_NAME ITEM_FONT_SIZE SELECTED_ITEM_FONT_NAME SELECTED_ITEM_FONT_SIZE
    export ICON_SIZE ITEM_ICON_SPACE
    export COUNTDOWN_FONT_NAME COUNTDOWN_FONT_SIZE COUNTDOWN_TEXT COUNTDOWN_WIDTH
    export COUNTDOWN_LEFT COUNTDOWN_TOP COUNTDOWN_ALIGN COUNTDOWN_COLOR
    export PROGRESS_BAR_WIDTH PROGRESS_BAR_LEFT PROGRESS_BAR_TOP PROGRESS_BAR_HEIGHT
    export PROGRESS_BAR_ALIGN PROGRESS_BAR_FOREGROUND_COLOR PROGRESS_BAR_BACKGROUND_COLOR PROGRESS_BAR_BORDER_COLOR

    envsubst < "$TEMP_DIR/theme.txt" > "$TEMP_DIR/theme.tmp"
    mv "$TEMP_DIR/theme.tmp" "$TEMP_DIR/theme.txt"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Substituted variables in file 'theme.txt' successfully." || true
}

main "$@"
