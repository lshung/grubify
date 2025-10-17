#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    parse_arguments "$@" || return 1
    check_required_commands_exist || return 1
    declare_variables || { log_failed "Failed to declare variables."; return 1; }
    parse_config_values || { log_failed "Failed to parse config values."; return 1; }
    clean_temporary_directory || { log_failed "Failed to clean temporary directory."; return 1; }
    download_background_image_if_not_set || { log_failed "Failed to download background image."; return 1; }
    generate_background_image || { log_failed "Failed to generate background image."; return 1; }
    generate_selected_item_pixmap || { log_failed "Failed to generate selected item pixmap."; return 1; }
    generate_menu_item_icons || { log_failed "Failed to generate menu item icons."; return 1; }
    download_and_convert_fonts || { log_failed "Failed to download and convert fonts."; return 1; }
    substitute_variables_in_theme_txt || { log_failed "Failed to substitute variables in theme.txt."; return 1; }
    copy_assets_to_theme_dir || { log_failed "Failed to copy assets to theme directory."; return 1; }
    edit_file_etc_default_grub || { log_failed "Failed to edit file '/etc/default/grub'."; return 1; }
    update_grub_configuration || { log_failed "Failed to update GRUB configuration."; return 1; }
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

    check_command_exists "ffmpeg" || { log_error "Command 'ffmpeg' not found."; return 1; }
    check_command_exists "grub-mkfont" || { log_error "Command 'grub-mkfont' not found."; return 1; }
    check_command_exists "curl" || { log_error "Command 'curl' not found."; return 1; }
    check_command_exists "envsubst" || { log_error "Command 'envsubst' not found."; return 1; }
    check_command_exists "tar" || { log_error "Command 'tar' not found."; return 1; }
    check_one_of_commands_exists "update-grub" "grub-mkconfig" "grub2-mkconfig" || { log_error "Command 'update-grub', 'grub-mkconfig' or 'grub2-mkconfig' not found."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "All required commands exist." || true
}

declare_variables() {
    log_info "Declaring variables..."

    if get_grub_themes_dir >/dev/null 2>&1; then
        GRUB_THEMES_DIR="$(get_grub_themes_dir)"
    else
        log_error "Failed to get GRUB themes directory."
        return 1
    fi

    GRUB_THEME_DIR="$GRUB_THEMES_DIR/$APP_NAME_LOWER"

    [[ "$VERBOSE" == "yes" ]] && log_info "Setting default config values..." || true

    [ -z "$CONTAINER_COLOR" ] && CONTAINER_COLOR="$THEME_BACKGROUND_COLOR" || true
    [ -z "$ITEM_COLOR" ] && ITEM_COLOR="$THEME_TEXT_COLOR" || true
    [ -z "$SELECTED_ITEM_COLOR" ] && SELECTED_ITEM_COLOR="$THEME_BACKGROUND_COLOR" || true
    [ -z "$SELECTED_ITEM_BACKGROUND_COLOR" ] && SELECTED_ITEM_BACKGROUND_COLOR="$THEME_ACCENT_COLOR" || true
    [ -z "$COUNTDOWN_COLOR" ] && COUNTDOWN_COLOR="$THEME_TEXT_COLOR" || true
    [ -z "$PROGRESS_BAR_FOREGROUND_COLOR" ] && PROGRESS_BAR_FOREGROUND_COLOR="$THEME_ACCENT_COLOR" || true
    [ -z "$PROGRESS_BAR_BACKGROUND_COLOR" ] && PROGRESS_BAR_BACKGROUND_COLOR="$THEME_BACKGROUND_COLOR" || true
    [ -z "$PROGRESS_BAR_BORDER_COLOR" ] && PROGRESS_BAR_BORDER_COLOR="$THEME_BACKGROUND_COLOR" || true

    [[ "$VERBOSE" == "yes" ]] && log_ok "Declared variables successfully." || true
}

parse_config_values() {
    log_info "Parsing config values..."

    PARSED_CONTAINER_WIDTH="$CONTAINER_WIDTH"
    if [[ "$CONTAINER_WIDTH" =~ ^[0-9]+%$ ]]; then
        PARSED_CONTAINER_WIDTH="$(( $SCREEN_WIDTH * ${CONTAINER_WIDTH%\%} / 100 ))"
    fi

    PARSED_CONTAINER_HEIGHT="$CONTAINER_HEIGHT"
    if [[ "$CONTAINER_HEIGHT" =~ ^[0-9]+%$ ]]; then
        PARSED_CONTAINER_HEIGHT="$(( $SCREEN_HEIGHT * ${CONTAINER_HEIGHT%\%} / 100 ))"
    fi

    PARSED_CONTAINER_TOP="$CONTAINER_TOP"
    if [[ "$CONTAINER_TOP" =~ ^[0-9]+%$ ]]; then
        PARSED_CONTAINER_TOP="$(( $SCREEN_HEIGHT * ${CONTAINER_TOP%\%} / 100 ))"
    fi

    PARSED_CONTAINER_LEFT="$CONTAINER_LEFT"
    if [[ "$CONTAINER_LEFT" =~ ^[0-9]+%$ ]]; then
        PARSED_CONTAINER_LEFT="$(( $SCREEN_WIDTH * ${CONTAINER_LEFT%\%} / 100 ))"
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Parsed config values successfully." || true
}

clean_temporary_directory() {
    log_info "Cleaning temporary directory..."

    rm -rf "$TEMP_DIR"/{*,.[!.]*}
    mkdir -p "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/icons"
    mkdir -p "$TEMP_DIR/fonts"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Cleaned temporary directory successfully." || true
}

download_background_image_if_not_set() {
    if [[ "$BACKGROUND_TYPE" == "file" && -z "$BACKGROUND_FILE" ]]; then
        log_info "Downloading background image..."

        local url="https://raw.githubusercontent.com/lshung/grubify-assets/master/background.jpg"
        BACKGROUND_FILE="$TEMP_DIR/background.jpg"
        curl -s -L -o "$BACKGROUND_FILE" "$url" || return 1

        [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded background image successfully." || true
    fi
}

generate_background_image() {
    log_info "Generating background image..."

    if [[ "$BACKGROUND_TYPE" == "file" ]]; then
        fit_background_image_to_screen || return 1
    elif [[ "$BACKGROUND_TYPE" == "solid" ]]; then
        create_solid_color_background || return 1
    else
        log_error "Invalid background type '$BACKGROUND_TYPE'."
        return 1
    fi

    if [[ "$CONTAINER_TYPE" == "blur" ]]; then
        create_blurred_image_container || return 1
    elif [[ "$CONTAINER_TYPE" == "solid" ]]; then
        create_solid_color_container || return 1
    else
        log_error "Invalid container type '$CONTAINER_TYPE'."
        return 1
    fi

    if [[ "$CONTAINER_BORDER_RADIUS" -gt 0 ]]; then
        create_border_radius_for_container || return 1
    fi

    if ! overlay_image "$TEMP_DIR/background.png" "$TEMP_DIR/container.png" "$TEMP_DIR/background.png" "$PARSED_CONTAINER_LEFT" "$PARSED_CONTAINER_TOP"; then
        log_error "Failed to overlay container on background image."
        return 1
    fi
}

fit_background_image_to_screen() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Scaling background image to fit screen..." || true

    if ! scale_image_to_fit_screen "$BACKGROUND_FILE" "$TEMP_DIR/background.png" "$SCREEN_WIDTH" "$SCREEN_HEIGHT"; then
        log_error "Failed to scale image to fit screen."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Scaled background image to fit screen successfully." || true
}

create_solid_color_background() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Creating solid color background..." || true

    if ! create_solid_color_image "$TEMP_DIR/background.png" "$BACKGROUND_COLOR" "$SCREEN_WIDTH" "$SCREEN_HEIGHT"; then
        log_error "Failed to create solid color image for background."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Created solid color background successfully." || true
}

create_blurred_image_container() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Cropping background image to create container..." || true

    if ! crop_image "$TEMP_DIR/background.png" "$TEMP_DIR/container.png" "$PARSED_CONTAINER_WIDTH" "$PARSED_CONTAINER_HEIGHT" "$PARSED_CONTAINER_LEFT" "$PARSED_CONTAINER_TOP"; then
        log_error "Failed to crop image to create container."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Cropped background image to create container successfully." || true

    [[ "$VERBOSE" == "yes" ]] && log_info "Making container blurred..." || true

    if ! blur_image "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" "$CONTAINER_BLUR_SIGMA" "$CONTAINER_BLUR_BRIGHTNESS" "$CONTAINER_BLUR_CONTRAST"; then
        log_error "Failed to make container blurred."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Made container blurred successfully." || true
}

create_solid_color_container() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Creating solid color container..." || true

    if ! create_solid_color_image "$TEMP_DIR/container.png" "$CONTAINER_COLOR" "$PARSED_CONTAINER_WIDTH" "$PARSED_CONTAINER_HEIGHT"; then
        log_error "Failed to create solid color image for container."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Created solid color container successfully." || true
}

create_border_radius_for_container() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Scaling container image up to avoid aliasing..." || true

    if ! scale_image_by_factor "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" 10; then
        log_error "Failed to scale image up."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Scaled image up successfully." || true

    [[ "$VERBOSE" == "yes" ]] && log_info "Creating rounded corners for container..." || true

    if ! create_rounded_corners "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" "$(( $CONTAINER_BORDER_RADIUS * 10 ))"; then
        log_error "Failed to create rounded corners for container."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Created rounded corners for container successfully." || true

    [[ "$VERBOSE" == "yes" ]] && log_info "Scaling container image down as original size..." || true

    if ! scale_image_by_factor "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" 0.1; then
        log_error "Failed to scale image down."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Scaled image down successfully." || true
}

generate_selected_item_pixmap() {
    log_info "Generating selected item pixmap..."

    cp "$APP_TEMPLATES_SELECT_DIR"/select_*.svg "$TEMP_DIR"/ || return 1

    for file_name in "select_c" "select_w" "select_e"; do
        sed -i "s/fill=\".*\"/fill=\"$SELECTED_ITEM_BACKGROUND_COLOR\"/g" "$TEMP_DIR/$file_name.svg" || return 1
        scale_image_with_values "$TEMP_DIR/$file_name.svg" "$TEMP_DIR/$file_name.png" -1 "$ITEM_HEIGHT" || return 1
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated selected item pixmap successfully." || true
}

generate_menu_item_icons() {
    log_info "Generating menu item icons..."

    for file in "$APP_TEMPLATES_ICONS_DIR/$ICON_THEME"/*.svg; do
        export_menu_item_icon "$file" "$TEMP_DIR/icons/$(basename "$file" .svg).png" -1 "$ICON_SIZE" || return 1
    done

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated menu item icons successfully." || true
}

download_and_convert_fonts() {
    log_info "Downloading and converting fonts..."

    download_font "unifont" || return 1
    download_font "terminus" || return 1
    convert_font_to_pf2_format "unifont" || return 1
    convert_font_to_pf2_format "terminus" || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Downloaded and converted fonts successfully." || true
}

substitute_variables_in_theme_txt() {
    log_info "Substituting variables in file 'theme.txt'..."

    cp "$APP_TEMPLATES_DIR/theme.txt" "$TEMP_DIR/theme.tmp"

    export TERMINAL_FONT_NAME TERMINAL_FONT_SIZE
    export MENU_WIDTH MENU_HEIGHT MENU_LEFT MENU_TOP
    export ITEM_COLOR SELECTED_ITEM_COLOR ITEM_HEIGHT ITEM_PADDING ITEM_SPACING
    export ITEM_FONT_NAME ITEM_FONT_SIZE SELECTED_ITEM_FONT_NAME SELECTED_ITEM_FONT_SIZE
    export ICON_SIZE ITEM_ICON_SPACE
    export COUNTDOWN_FONT_NAME COUNTDOWN_FONT_SIZE COUNTDOWN_TEXT COUNTDOWN_WIDTH
    export COUNTDOWN_LEFT COUNTDOWN_TOP COUNTDOWN_ALIGN COUNTDOWN_COLOR
    export PROGRESS_BAR_WIDTH PROGRESS_BAR_LEFT PROGRESS_BAR_TOP PROGRESS_BAR_HEIGHT
    export PROGRESS_BAR_ALIGN PROGRESS_BAR_FOREGROUND_COLOR PROGRESS_BAR_BACKGROUND_COLOR PROGRESS_BAR_BORDER_COLOR

    envsubst < "$TEMP_DIR/theme.tmp" > "$TEMP_DIR/theme.txt"

    [[ "$VERBOSE" == "yes" ]] && log_ok "Substituted variables in file 'theme.txt' successfully." || true
}

copy_assets_to_theme_dir() {
    log_info "Copying assets to theme directory..."

    [[ -d "$GRUB_THEME_DIR" ]] && sudo rm -rf "$GRUB_THEME_DIR" || true
    sudo mkdir -p "$GRUB_THEME_DIR"

    sudo cp "$TEMP_DIR/theme.txt" "$GRUB_THEME_DIR"/
    sudo cp "$TEMP_DIR/background.png" "$GRUB_THEME_DIR"/
    sudo cp "$TEMP_DIR"/select_*.png "$GRUB_THEME_DIR"/
    sudo cp -r "$TEMP_DIR/icons" "$GRUB_THEME_DIR"/
    sudo cp "$TEMP_DIR/fonts"/*.pf2 "$GRUB_THEME_DIR"/ || true

    [[ "$VERBOSE" == "yes" ]] && log_ok "Copied assets to theme directory successfully." || true
}

edit_file_etc_default_grub() {
    log_info "Editing file '/etc/default/grub'..."

    update_value_in_etc_default_grub "GRUB_THEME" "\"${GRUB_THEME_DIR}/theme.txt\"" || return 1
    update_value_in_etc_default_grub "GRUB_GFXMODE" "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_COLOR_DEPTH}" || return 1
    update_value_in_etc_default_grub "GRUB_GFXPAYLOAD_LINUX" "keep" || return 1
    update_value_in_etc_default_grub "GRUB_TIMEOUT" "$COUNTDOWN_TIMEOUT" || return 1

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
