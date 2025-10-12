#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

get_image_dimensions() {
    local input_file="$1"
    local output_type="$2"

    if [[ "$output_type" == "width" ]]; then
        echo "$(ffmpeg -i "$input_file" 2>&1 | grep -oP '[0-9]+x[0-9]+' | cut -d'x' -f1)"
    elif [[ "$output_type" == "height" ]]; then
        echo "$(ffmpeg -i "$input_file" 2>&1 | grep -oP '[0-9]+x[0-9]+' | cut -d'x' -f2)"
    fi
}

execute_ffmpeg() {
    local input_file="$1"
    local output_file="$2"
    shift 2
    local filters=("$@")
    local temporary_file="$(generate_random_temporary_file)"

    if [[ ! -f "$input_file" ]]; then
        log_error "Input file '$input_file' does not exist."
        return 1
    fi

    if ! ffmpeg -i "$input_file" -filter_complex "${filters[*]}" -frames:v 1 -update 1 -y "$temporary_file" >/dev/null 2>&1; then
        log_error "Failed to execute ffmpeg."
        rm -f "$temporary_file"
        return 1
    fi

    if ! mv "$temporary_file" "$output_file"; then
        log_error "Failed to move temporary file '$temporary_file' to '$output_file'."
        return 1
    fi
}

generate_random_temporary_file() {
    echo "$TEMP_DIR/$(date +%s%N).png"
}

scale_image_by_factor() {
    local input_file="$1"
    local output_file="$2"
    local scale_factor="$3"
    local filters=("scale=iw*$scale_factor:ih*$scale_factor:force_original_aspect_ratio=increase:flags=lanczos")

    execute_ffmpeg "$input_file" "$output_file" "${filters[@]}" || return 1
}

scale_image_with_values() {
    local input_file="$1"
    local output_file="$2"
    local width="$3"
    local height="$4"
    local filters=("scale=${width}:${height}")

    execute_ffmpeg "$input_file" "$output_file" "${filters[@]}" || return 1
}

crop_image() {
    local input_file="$1"
    local output_file="$2"
    local width="$3"
    local height="$4"
    local x="$5"
    local y="$6"
    local filters=("crop=${width}:${height}:${x}:${y}")

    execute_ffmpeg "$input_file" "$output_file" "${filters[@]}" || return 1
}

create_rounded_corners() {
    local input_file="$1"
    local output_file="$2"
    local radius="$3"
    local filters=(
        "format=yuva420p,"
        "geq=lum='p(X,Y)':a='if(" \
            "gt(abs(W/2-X),W/2-${radius})*gt(abs(H/2-Y),H/2-${radius})," \
            "if(" \
                "lte(hypot(${radius}-(W/2-abs(W/2-X)),${radius}-(H/2-abs(H/2-Y))),${radius}" \
            "),255,0),255" \
        ")'"
    )

    execute_ffmpeg "$input_file" "$output_file" "${filters[@]}" || return 1
}

overlay_image() {
    local input_file="$1"
    local overlay_file="$2"
    local output_file="$3"
    local x="$4"
    local y="$5"
    local filters=("[0][1]overlay=${x}:${y}")
    local temporary_file="$(generate_random_temporary_file)"

    if [[ ! -f "$input_file" ]]; then
        log_error "Input file '$input_file' does not exist."
        return 1
    fi

    if [[ ! -f "$overlay_file" ]]; then
        log_error "Input file '$overlay_file' does not exist."
        return 1
    fi

    if ! ffmpeg -i "$input_file" -i "$overlay_file" -filter_complex "${filters[*]}" -frames:v 1 -update 1 -y "$temporary_file" >/dev/null 2>&1; then
        log_error "Failed to execute ffmpeg."
        rm -f "$temporary_file"
        return 1
    fi

    if ! mv "$temporary_file" "$output_file"; then
        log_error "Failed to move temporary file '$temporary_file' to '$output_file'."
        return 1
    fi
}

blur_image() {
    local input_file="$1"
    local output_file="$2"
    local sigma="$3"
    local brightness="$4"
    local contrast="$5"
    local filters=("gblur=sigma=$sigma,format=rgba,colorchannelmixer=aa=1,eq=brightness=$brightness:contrast=$contrast")

    execute_ffmpeg "$input_file" "$output_file" "${filters[@]}" || return 1
}

scale_image_to_fit_screen() {
    local input_file="$1"
    local output_file="$2"
    local screen_width="$3"
    local screen_height="$4"

    # Get original dimensions
    local original_width="$(get_image_dimensions "$input_file" "width")"
    local original_height="$(get_image_dimensions "$input_file" "height")"

    # Calculate aspect ratios
    local original_ratio=$(echo "scale=10; $original_width / $original_height" | bc)
    local target_ratio=$(echo "scale=10; $screen_width / $screen_height" | bc)

    if (( $(echo "$original_ratio > $target_ratio" | bc -l) )); then
        # Original is wider than target - scale by height, then crop width
        local scale_factor=$(echo "scale=10; $screen_height / $original_height" | bc)
        local scaled_width=$(echo "scale=0; $original_width * $scale_factor / 1" | bc)
        local crop_x=$(echo "scale=0; ($scaled_width - $screen_width) / 2" | bc)
        local crop_y=0
    else
        # Original is taller than target - scale by width, then crop height
        local scale_factor=$(echo "scale=10; $screen_width / $original_width" | bc)
        local scaled_height=$(echo "scale=0; $original_height * $scale_factor / 1" | bc)
        local crop_x=0
        local crop_y=$(echo "scale=0; ($scaled_height - $screen_height) / 2" | bc)
    fi

    local temporary_file="$(generate_random_temporary_file)"
    scale_image_by_factor "$input_file" "$temporary_file" "$scale_factor" || return 1
    crop_image "$temporary_file" "$output_file" "$screen_width" "$screen_height" "$crop_x" "$crop_y" || return 1
    rm -f "$temporary_file"
}

create_solid_color_image() {
    local output_file="$1"
    local color="$2"
    local width="$3"
    local height="$4"
    local filters=("color=c=$color:s=${width}x${height}:r=1")
    local temporary_file="$(generate_random_temporary_file)"

    if ! ffmpeg -filter_complex "${filters[*]}" -frames:v 1 -update 1 -y "$temporary_file" >/dev/null 2>&1; then
        log_error "Failed to execute ffmpeg."
        rm -f "$temporary_file"
        return 1
    fi

    if ! mv "$temporary_file" "$output_file"; then
        log_error "Failed to move temporary file '$temporary_file' to '$output_file'."
        return 1
    fi
}
