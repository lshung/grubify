#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    parse_arguments "$@" || return 1
    check_required_commands_exist || return 1
    declare_variables || { log_failed "Failed to declare variables."; return 1; }
    clean_temporary_directory || { log_failed "Failed to clean temporary directory."; return 1; }
    call_module_generate_background || return 1
    generate_selected_item_pixmap || { log_failed "Failed to generate selected item pixmap."; return 1; }
    generate_circular_progress_assets || { log_failed "Failed to generate circular progress assets."; return 1; }
    generate_menu_item_icons || { log_failed "Failed to generate menu item icons."; return 1; }
    call_module_generate_fonts || return 1
    call_module_generate_theme_file || return 1
    copy_assets_to_theme_dir || { log_failed "Failed to copy assets to theme directory."; return 1; }
    edit_file_etc_default_grub || { log_failed "Failed to edit file '/etc/default/grub'."; return 1; }
    update_grub_configuration || { log_failed "Failed to update GRUB configuration."; return 1; }
    call_module_menu_valign_center || return 1
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

check_required_commands_exist() {
    log_info "Checking required commands exist..."

    check_commands_exist "grub-mkfont" "envsubst" "tar" || return 1
    check_command_exists "ffmpeg" || return 1
    check_command_exists "rsvg-convert" || return 1
    check_one_of_commands_exists "curl" "wget" || { log_error "Command 'curl' or 'wget' not found."; return 1; }
    check_one_of_commands_exists "update-grub" "grub-mkconfig" "grub2-mkconfig" || { log_error "Command 'update-grub', 'grub-mkconfig' or 'grub2-mkconfig' not found."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "All required commands exist." || true
}

declare_variables() {
    log_info "Declaring variables..."

    parse_grub_geometry "$CIRCULAR_PROGRESS_WIDTH" "$SCREEN_WIDTH" >/dev/null \
        && PARSED_CIRCULAR_PROGRESS_WIDTH="$(parse_grub_geometry "$CIRCULAR_PROGRESS_WIDTH" "$SCREEN_WIDTH")" || return 1

    parse_grub_geometry "$CIRCULAR_PROGRESS_IMAGE_WIDTH" "$SCREEN_WIDTH" >/dev/null \
        && PARSED_CIRCULAR_PROGRESS_IMAGE_WIDTH="$(parse_grub_geometry "$CIRCULAR_PROGRESS_IMAGE_WIDTH" "$SCREEN_WIDTH")" || return 1

    [ -z "$SELECTED_ITEM_BACKGROUND_COLOR" ] && SELECTED_ITEM_BACKGROUND_COLOR="$THEME_ACCENT_COLOR" || true
    [ -z "$CIRCULAR_PROGRESS_CENTER_COLOR" ] && CIRCULAR_PROGRESS_CENTER_COLOR="$THEME_BACKGROUND_COLOR" || true
    [ -z "$CIRCULAR_PROGRESS_TICK_COLOR" ] && CIRCULAR_PROGRESS_TICK_COLOR="$THEME_ACCENT_COLOR" || true

    [[ "$VERBOSE" == "yes" ]] && log_ok "Declared variables successfully." || true
}

clean_temporary_directory() {
    log_info "Cleaning temporary directory..."

    rm -rf "$TEMP_DIR"/{*,.[!.]*}
    mkdir -p "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/icons"
    mkdir -p "$TEMP_DIR/fonts"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Cleaned temporary directory successfully." || true
}

call_module_generate_background() {
    source "$APP_MODULES_DIR/gen-background.sh" || return 1
}

generate_selected_item_pixmap() {
    log_info "Generating selected item pixmap..."

    cp "$APP_TEMPLATES_SELECT_DIR"/select_*.svg "$TEMP_DIR"/ || return 1

    for file_name in "select_c" "select_w" "select_e"; do
        sed -i "s/fill=\".*\"/fill=\"$SELECTED_ITEM_BACKGROUND_COLOR\"/g" "$TEMP_DIR/$file_name.svg" || return 1
        rsvg-convert -d 1000 -h "$ITEM_HEIGHT" "$TEMP_DIR/$file_name.svg" -o "$TEMP_DIR/$file_name.png" || return 1
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated selected item pixmap successfully." || true
}

generate_circular_progress_assets() {
    if [[ "$CIRCULAR_PROGRESS_VISIBLE" == "yes" ]]; then
        log_info "Generating circular progress assets..."

        cp "$APP_TEMPLATES_CIRCULAR_PROGRESS_DIR"/*.svg "$TEMP_DIR"/ || return 1

        sed -i "s/fill=\".*\"/fill=\"$CIRCULAR_PROGRESS_CENTER_COLOR\"/g" "$TEMP_DIR/center.svg" || return 1
        sed -i "s/fill=\".*\"/fill=\"$CIRCULAR_PROGRESS_TICK_COLOR\"/g" "$TEMP_DIR/tick.svg" || return 1

        rsvg-convert -d 1000 -w "$PARSED_CIRCULAR_PROGRESS_WIDTH" "$TEMP_DIR/center.svg" -o "$TEMP_DIR/center.png" || return 1
        rsvg-convert -d 1000 -w "$CIRCULAR_PROGRESS_TICK_SIZE" "$TEMP_DIR/tick.svg" -o "$TEMP_DIR/tick.png" || return 1

        generate_circular_progress_image

        [[ "$VERBOSE" == "yes" ]] && log_ok "Generated circular progress assets successfully." || true
    fi
}

generate_circular_progress_image() {
    if [[ "$CIRCULAR_PROGRESS_IMAGE_VISIBLE" == "yes" ]]; then
        [[ "$VERBOSE" == "yes" ]] && log_info "Generating circular progress image..." || true

        if [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^icons/(.*)/(.*)\.svg$ ]]; then
            CIRCULAR_PROGRESS_IMAGE_FILE="$APP_TEMPLATES_ICONS_DIR/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}.svg"
        fi

        [[ -f "$CIRCULAR_PROGRESS_IMAGE_FILE" ]] || { log_error "Circular progress image file '$CIRCULAR_PROGRESS_IMAGE_FILE' not found."; return 1; }

        if [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^(.*)\.svg$ ]]; then
            rsvg-convert -d 1000 -w "$PARSED_CIRCULAR_PROGRESS_IMAGE_WIDTH" "$CIRCULAR_PROGRESS_IMAGE_FILE" -o "$TEMP_DIR/image.png" || return 1
        elif [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^(.*)\.png$ ]]; then
            cp "$CIRCULAR_PROGRESS_IMAGE_FILE" "$TEMP_DIR/image.png" || return 1
        else
            log_error "Invalid circular progress image extension (accepted extensions: .svg, .png)."
            return 1
        fi

        [[ "$VERBOSE" == "yes" ]] && log_ok "Generated circular progress image successfully." || true
    fi
}

generate_menu_item_icons() {
    log_info "Generating menu item icons..."

    for file in "$APP_TEMPLATES_ICONS_DIR/$ICON_THEME"/*.svg; do
        rsvg-convert -d 1000 -w "$ICON_SIZE" -h "$ICON_SIZE" "$file" -o "$TEMP_DIR/icons/$(basename "$file" .svg).png" || return 1
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated menu item icons successfully." || true
}

call_module_generate_fonts() {
    source "$APP_MODULES_DIR/gen-fonts.sh" || return 1
}

call_module_generate_theme_file() {
    source "$APP_MODULES_DIR/gen-theme-file.sh" || return 1
}

copy_assets_to_theme_dir() {
    log_info "Copying assets to theme directory..."

    [[ -d "$GRUB_THEME_DIR" ]] && sudo rm -rf "$GRUB_THEME_DIR" || true
    sudo mkdir -p "$GRUB_THEME_DIR"

    sudo cp "$TEMP_DIR/theme.txt" "$GRUB_THEME_DIR"/ || return 1
    sudo cp "$TEMP_DIR/background.png" "$GRUB_THEME_DIR"/ || return 1
    sudo cp "$TEMP_DIR"/select_*.png "$GRUB_THEME_DIR"/ || return 1
    [[ -f "$TEMP_DIR"/center.png ]] && { sudo cp "$TEMP_DIR"/center.png "$GRUB_THEME_DIR"/ || return 1; } || true
    [[ -f "$TEMP_DIR"/tick.png ]] && { sudo cp "$TEMP_DIR"/tick.png "$GRUB_THEME_DIR"/ || return 1; } || true
    [[ -f "$TEMP_DIR"/image.png ]] && { sudo cp "$TEMP_DIR"/image.png "$GRUB_THEME_DIR"/ || return 1; } || true
    sudo cp -r "$TEMP_DIR/icons" "$GRUB_THEME_DIR"/ || return 1
    sudo cp "$TEMP_DIR/fonts"/*.pf2 "$GRUB_THEME_DIR"/ || return 1

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

call_module_menu_valign_center() {
    if [[ "$MENU_VALIGN_CENTER" == "yes" ]]; then
        source "$APP_MODULES_DIR/menu-valign-center.sh" || return 1
    fi
}

cleanup() {
    log_info "Cleaning up..."

    rm -rf "$TEMP_DIR"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Cleaned up successfully." || true
}

main "$@"
