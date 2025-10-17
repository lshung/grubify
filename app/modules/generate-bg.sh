#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "generate-bg" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
        check_required_commands_exist || return 1
    fi

    set_default_config_values || { log_failed "Failed to set default config values."; return 1; }
    parse_config_values || { log_failed "Failed to parse config values."; return 1; }
    download_background_image_if_not_set || { log_failed "Failed to download background image."; return 1; }
    generate_background_image || { log_failed "Failed to generate background image."; return 1; }
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
    echo "Usage: $APP_NAME_LOWER generate-bg [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

check_required_commands_exist() {
    log_info "Checking required commands exist..."

    check_command_exists "ffmpeg" || { log_error "Command 'ffmpeg' not found."; return 1; }
    check_command_exists "curl" || { log_error "Command 'curl' not found."; return 1; }

    [[ "$VERBOSE" == "yes" ]] && log_ok "All required commands exist." || true
}

set_default_config_values() {
    log_info "Setting default config values..."

    [ -z "$CONTAINER_COLOR" ] && CONTAINER_COLOR="$THEME_BACKGROUND_COLOR" || true

    [[ "$VERBOSE" == "yes" ]] && log_ok "Set default config values successfully." || true
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

download_background_image_if_not_set() {
    mkdir -p "$TEMP_DIR"

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

    overlay_container_on_background || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated background image successfully." || true

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Background image saved to '$TEMP_DIR/background.png'."
        log_info "You can preview it by running command 'xdg-open $TEMP_DIR/background.png'."
        log_ok "Done."
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

overlay_container_on_background() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Overlaying container on background image..." || true

    if ! overlay_image "$TEMP_DIR/background.png" "$TEMP_DIR/container.png" "$TEMP_DIR/background.png" "$PARSED_CONTAINER_LEFT" "$PARSED_CONTAINER_TOP"; then
        log_error "Failed to overlay container on background image."
        return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Overlayed container on background image successfully." || true
}

main "$@"
