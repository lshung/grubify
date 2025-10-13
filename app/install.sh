#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    declare_variables || { log_failed "Failed to declare variables."; exit 1; }
    clean_temporary_directory || { log_failed "Failed to clean temporary directory."; exit 1; }
    parse_config_values || { log_failed "Failed to parse config values."; exit 1; }
    generate_background_image || { log_failed "Failed to generate background image."; exit 1; }
    generate_selected_item_pixmap || { log_failed "Failed to generate selected item pixmap."; exit 1; }
    generate_menu_item_icons || { log_failed "Failed to generate menu item icons."; exit 1; }
    copy_assets_to_theme_dir || { log_failed "Failed to copy assets to theme directory."; exit 1; }
    set_grub_theme || { log_failed "Failed to set GRUB theme."; exit 1; }
    update_grub_configuration || { log_failed "Failed to update GRUB configuration."; exit 1; }
    cleanup || { log_failed "Failed to cleanup."; exit 1; }

    log_ok "Done."
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
}

clean_temporary_directory() {
    log_info "Cleaning temporary directory..."

    rm -rf "$TEMP_DIR"/{*,.[!.]*}
    mkdir -p "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/icons"
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
    if ! scale_image_to_fit_screen "$BACKGROUND_FILE" "$TEMP_DIR/background.png" "$SCREEN_WIDTH" "$SCREEN_HEIGHT"; then
        log_error "Failed to scale image to fit screen."
        return 1
    fi
}

create_solid_color_background() {
    if ! create_solid_color_image "$TEMP_DIR/background.png" "$BACKGROUND_COLOR" "$SCREEN_WIDTH" "$SCREEN_HEIGHT"; then
        log_error "Failed to create solid color image for background."
        return 1
    fi
}

create_blurred_image_container() {
    if ! crop_image "$TEMP_DIR/background.png" "$TEMP_DIR/container.png" "$PARSED_CONTAINER_WIDTH" "$PARSED_CONTAINER_HEIGHT" "$PARSED_CONTAINER_LEFT" "$PARSED_CONTAINER_TOP"; then
        log_error "Failed to crop image to create container."
        return 1
    fi

    if ! blur_image "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" "$CONTAINER_BLUR_SIGMA" "$CONTAINER_BLUR_BRIGHTNESS" "$CONTAINER_BLUR_CONTRAST"; then
        log_error "Failed to make container blurred."
        return 1
    fi
}

create_solid_color_container() {
    if ! create_solid_color_image "$TEMP_DIR/container.png" "$CONTAINER_COLOR" "$PARSED_CONTAINER_WIDTH" "$PARSED_CONTAINER_HEIGHT"; then
        log_error "Failed to create solid color image for container."
        return 1
    fi
}

create_border_radius_for_container() {
    if ! scale_image_by_factor "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" 10; then
        log_error "Failed to scale image up to avoid aliasing."
        return 1
    fi

    if ! create_rounded_corners "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" "$(( $CONTAINER_BORDER_RADIUS * 10 ))"; then
        log_error "Failed to create rounded corners for container."
        return 1
    fi

    if ! scale_image_by_factor "$TEMP_DIR/container.png" "$TEMP_DIR/container.png" 0.1; then
        log_error "Failed to scale image down as original size."
        return 1
    fi
}

generate_selected_item_pixmap() {
    log_info "Generating selected item pixmap..."

    scale_image_with_values "$APP_TEMPLATES_SELECT_DIR/select_c.svg" "$TEMP_DIR/select_c.png" -1 40
    scale_image_with_values "$APP_TEMPLATES_SELECT_DIR/select_w.svg" "$TEMP_DIR/select_w.png" -1 40
    scale_image_with_values "$APP_TEMPLATES_SELECT_DIR/select_e.svg" "$TEMP_DIR/select_e.png" -1 40
}

generate_menu_item_icons() {
    log_info "Generating menu item icons..."

    for file in "$APP_TEMPLATES_ICONS_DIR"/tela-circle/*.svg; do
        export_menu_item_icon "$file" "$TEMP_DIR/icons/$(basename "$file" .svg).png" -1 32
    done
}

copy_assets_to_theme_dir() {
    log_info "Copying assets to theme directory..."

    [[ -d "$GRUB_THEME_DIR" ]] && sudo rm -rf "$GRUB_THEME_DIR" || true
    sudo mkdir -p "$GRUB_THEME_DIR"

    sudo cp "$APP_TEMPLATES_DIR/theme.txt" "$GRUB_THEME_DIR"/
    sudo cp "$TEMP_DIR/background.png" "$GRUB_THEME_DIR"/
    sudo cp "$TEMP_DIR"/select_*.png "$GRUB_THEME_DIR"/
    sudo cp -r "$TEMP_DIR/icons" "$GRUB_THEME_DIR"/
}

set_grub_theme() {
    log_info "Setting GRUB theme..."

    if grep "GRUB_THEME=" /etc/default/grub >/dev/null 2>&1; then
        sudo sed -i "s|.*GRUB_THEME=.*|GRUB_THEME=\"${GRUB_THEME_DIR}/theme.txt\"|" /etc/default/grub
    else
        sudo echo "GRUB_THEME=\"${GRUB_THEME_DIR}/theme.txt\"" >> /etc/default/grub
    fi
}

update_grub_configuration() {
    log_info "Updating GRUB configuration..."

    update_grub_config >/dev/null 2>&1 || return 1
}

cleanup() {
    log_info "Cleaning up..."

    rm -rf "$TEMP_DIR"
}

main "$@"
