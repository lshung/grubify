#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    parse_arguments "$@" || return 1
    clean_temporary_directory || { log_failed "Failed to clean temporary directory."; return 1; }
    source "$APP_MODULES_DIR/gen-background.sh" || return 1
    source "$APP_MODULES_DIR/gen-selected-item.sh" || return 1
    source "$APP_MODULES_DIR/gen-distro-icons.sh" || return 1
    source "$APP_MODULES_DIR/gen-fonts.sh" || return 1
    source "$APP_MODULES_DIR/gen-theme-file.sh" || return 1
    [[ "$CIRCULAR_PROGRESS_VISIBLE" == "yes" ]] && { source "$APP_MODULES_DIR/gen-circular-progress.sh" || return 1; } || true
    copy_assets_to_theme_dir || { log_failed "Failed to copy assets to theme directory."; return 1; }
    edit_file_etc_default_grub || { log_failed "Failed to edit file '/etc/default/grub'."; return 1; }
    update_grub_configuration || { log_failed "Failed to update GRUB configuration."; return 1; }
    [[ "$MENU_VALIGN_CENTER" == "yes" ]] && { source "$APP_MODULES_DIR/menu-valign-center.sh" || return 1; } || true
    cleanup || { log_failed "Failed to cleanup."; return 1; }

    log_ok "Done."
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
    echo "Usage: $APP_NAME_LOWER install [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

clean_temporary_directory() {
    log_info "Cleaning temporary directory..."

    rm -rf "$TEMP_DIR"/{*,.[!.]*}
    mkdir -p "$TEMP_DIR"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Cleaned temporary directory successfully." || true
}

copy_assets_to_theme_dir() {
    log_info "Copying assets to theme directory..."

    [[ -d "$GRUB_THEME_DIR" ]] && sudo rm -rf "$GRUB_THEME_DIR" || true
    sudo mkdir -p "$GRUB_THEME_DIR"

    sudo cp "$TEMP_DIR/theme.txt" "$GRUB_THEME_DIR"/ || return 1
    sudo cp "$TEMP_DIR/background.png" "$GRUB_THEME_DIR"/ || return 1
    sudo cp "$TEMP_DIR"/select_*.png "$GRUB_THEME_DIR"/ || return 1
    sudo cp -r "$TEMP_DIR/icons" "$GRUB_THEME_DIR"/ || return 1
    sudo cp "$TEMP_DIR/fonts"/*.pf2 "$GRUB_THEME_DIR"/ || return 1

    [[ -f "$TEMP_DIR"/center.png ]] && { sudo cp "$TEMP_DIR"/center.png "$GRUB_THEME_DIR"/ || return 1; } || true
    [[ -f "$TEMP_DIR"/tick.png ]] && { sudo cp "$TEMP_DIR"/tick.png "$GRUB_THEME_DIR"/ || return 1; } || true
    [[ -f "$TEMP_DIR"/image.png ]] && { sudo cp "$TEMP_DIR"/image.png "$GRUB_THEME_DIR"/ || return 1; } || true

    [[ "$VERBOSE" == "yes" ]] && log_ok "Copied assets to theme directory successfully." || true
}

edit_file_etc_default_grub() {
    log_info "Editing file '/etc/default/grub'..."

    update_value_in_etc_default_grub "GRUB_THEME" "\"${GRUB_THEME_DIR}/theme.txt\"" || return 1
    update_value_in_etc_default_grub "GRUB_GFXMODE" "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_COLOR_DEPTH}" || return 1
    update_value_in_etc_default_grub "GRUB_GFXPAYLOAD_LINUX" "keep" || return 1
    update_value_in_etc_default_grub "GRUB_TIMEOUT" "$GRUB_TIMEOUT" || return 1

    uncomment_setting_in_etc_default_grub "GRUB_THEME" || return 1
    uncomment_setting_in_etc_default_grub "GRUB_GFXMODE" || return 1
    uncomment_setting_in_etc_default_grub "GRUB_GFXPAYLOAD_LINUX" || return 1
    uncomment_setting_in_etc_default_grub "GRUB_TIMEOUT" || return 1

    comment_setting_in_etc_default_grub "GRUB_TERMINAL_OUTPUT" || return 1
    comment_setting_in_etc_default_grub "GRUB_BACKGROUND" || return 1
    comment_setting_in_etc_default_grub "GRUB_COLOR_NORMAL" || return 1
    comment_setting_in_etc_default_grub "GRUB_COLOR_HIGHLIGHT" || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Edited file '/etc/default/grub' successfully." || true
}

update_grub_configuration() {
    log_info "Updating GRUB configuration..."

    update_grub_config >/dev/null 2>&1 || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Updated GRUB configuration successfully." || true
}

cleanup() {
    log_info "Cleaning up..."

    rm -rf "$TEMP_DIR"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Cleaned up successfully." || true
}

main "$@"
