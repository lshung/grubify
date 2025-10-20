#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

main() {
    IS_SOURCED="yes"

    if [[ "${1:-}" == "gen-circular-progress" ]]; then
        IS_SOURCED="no"
        parse_arguments "$@" || return 1
    fi

    generate_circular_progress_assets || { log_failed "Failed to generate circular progress assets."; return 1; }

    if [[ "$IS_SOURCED" == "no" ]]; then
        log_info "Circular progress assets saved to '$TEMP_DIR'."
        log_info "You can list them by running command 'ls -l $TEMP_DIR/*.png'."
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
    echo "Usage: $APP_NAME_LOWER gen-circular-progress [OPTIONS]"
    echo ""
    echo "Options:"
    echo "    -h, --help        Show help"
    echo "    -v, --verbose     Verbose output"
}

generate_circular_progress_assets() {
    log_info "Generating circular progress assets..."

    mkdir -p "$TEMP_DIR"
    rm -f "$TEMP_DIR"/{center,tick,image}.png

    cp "$APP_TEMPLATES_CIRCULAR_PROGRESS_DIR"/*.svg "$TEMP_DIR"/ || return 1

    change_filled_color_for_center_and_tick || return 1
    convert_center_and_tick_to_png || return 1

    if [[ "$CIRCULAR_PROGRESS_IMAGE_VISIBLE" == "yes" ]]; then
        generate_circular_progress_image || return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated circular progress assets successfully." || true
}

change_filled_color_for_center_and_tick() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Changing filled color for 'center.svg' and 'tick.svg'..." || true

    [ -z "$CIRCULAR_PROGRESS_CENTER_COLOR" ] && CIRCULAR_PROGRESS_CENTER_COLOR="$THEME_BACKGROUND_COLOR" || true
    [ -z "$CIRCULAR_PROGRESS_TICK_COLOR" ] && CIRCULAR_PROGRESS_TICK_COLOR="$THEME_ACCENT_COLOR" || true

    sed -i "s/fill=\".*\"/fill=\"$CIRCULAR_PROGRESS_CENTER_COLOR\"/g" "$TEMP_DIR/center.svg" || return 1
    sed -i "s/fill=\".*\"/fill=\"$CIRCULAR_PROGRESS_TICK_COLOR\"/g" "$TEMP_DIR/tick.svg" || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Changing filled color successfully." || true
}

convert_center_and_tick_to_png() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Converting 'center.svg' and 'tick.svg' to png format..." || true

    parse_grub_geometry "$CIRCULAR_PROGRESS_WIDTH" "$SCREEN_WIDTH" >/dev/null \
        && PARSED_CIRCULAR_PROGRESS_WIDTH="$(parse_grub_geometry "$CIRCULAR_PROGRESS_WIDTH" "$SCREEN_WIDTH")" || return 1

    rsvg-convert -d 1000 -w "$PARSED_CIRCULAR_PROGRESS_WIDTH" "$TEMP_DIR/center.svg" -o "$TEMP_DIR/center.png" || return 1
    rsvg-convert -d 1000 -w "$CIRCULAR_PROGRESS_TICK_SIZE" "$TEMP_DIR/tick.svg" -o "$TEMP_DIR/tick.png" || return 1

    [[ "$VERBOSE" == "yes" ]] && log_ok "Converted to png format successfully." || true
}

generate_circular_progress_image() {
    [[ "$VERBOSE" == "yes" ]] && log_info "Generating circular progress image..." || true

    validate_circular_progress_image_file_path || return 1

    if [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^(.*)\.svg$ ]]; then
        convert_circular_progress_image_to_png
    elif [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^(.*)\.png$ ]]; then
        cp "$CIRCULAR_PROGRESS_IMAGE_FILE" "$TEMP_DIR/image.png" || return 1
    fi

    [[ "$VERBOSE" == "yes" ]] && log_ok "Generated circular progress image successfully." || true
}

validate_circular_progress_image_file_path() {
    [[ -n "$CIRCULAR_PROGRESS_IMAGE_FILE" ]] || { log_error "Circular progress image file is not set."; return 1; }

    if [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^icons/(.*)/(.*)\.svg$ ]]; then
        CIRCULAR_PROGRESS_IMAGE_FILE="$APP_TEMPLATES_ICONS_DIR/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}.svg"
    fi

    [[ -f "$CIRCULAR_PROGRESS_IMAGE_FILE" ]] || { log_error "Circular progress image file '$CIRCULAR_PROGRESS_IMAGE_FILE' not found."; return 1; }

    [[ "$CIRCULAR_PROGRESS_IMAGE_FILE" =~ ^(.*)\.(svg|png)$ ]] || { log_error "Circular progress image extension is invalid (accepted extensions: .svg, .png)."; return 1; }
}

convert_circular_progress_image_to_png() {
    parse_grub_geometry "$CIRCULAR_PROGRESS_IMAGE_WIDTH" "$SCREEN_WIDTH" >/dev/null \
        && PARSED_CIRCULAR_PROGRESS_IMAGE_WIDTH="$(parse_grub_geometry "$CIRCULAR_PROGRESS_IMAGE_WIDTH" "$SCREEN_WIDTH")" || return 1

    rsvg-convert -d 1000 -w "$PARSED_CIRCULAR_PROGRESS_IMAGE_WIDTH" "$CIRCULAR_PROGRESS_IMAGE_FILE" -o "$TEMP_DIR/image.png" || return 1
}

main "$@"
