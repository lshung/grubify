#!/bin/bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo -e "[\033[31m ERRO \033[0m] This script cannot be executed directly." 1>&2; exit 1; }

set -euo pipefail

get_grub_themes_dir() {
    if [[ -d /boot/grub/themes ]]; then
        echo "/boot/grub/themes"
        return 0
    fi

    if [[ -d /boot/grub2/themes ]]; then
        echo "/boot/grub2/themes"
        return 0
    fi

    return 1
}

update_grub_config() {
    if command -v update-grub >/dev/null 2>&1; then
        sudo update-grub
    elif command -v grub-mkconfig >/dev/null 2>&1; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif command -v grub2-mkconfig >/dev/null 2>&1; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    else
        log_error "No command available to update GRUB config."
        return 1
    fi
}

update_value_in_etc_default_grub() {
    local key="$1"
    local value="$2"
    local file="/etc/default/grub"

    if grep -E "^#?\\s*$key=" "$file" >/dev/null 2>&1; then
        sudo sed -i "s|^\(#\\s*\)\?$key=.*|\\1$key=$value|g" "$file" || { log_error "Failed to update '$key=$value' in '$file'"; return 1; }
    else
        sudo sh -c "echo '$key=$value' >> '$file'" || { log_error "Failed to append '$key=$value' in '$file'"; return 1; }
    fi
}

comment_setting_in_etc_default_grub() {
    local key="$1"
    local file="/etc/default/grub"

    if grep -E "^\\s*$key=" "$file" >/dev/null 2>&1; then
        sudo sed -i "s|^\\s*$key=\(.*\)|#$key=\\1|g" "$file" || { log_error "Failed to comment '$key' in '$file'"; return 1; }
    fi
}

uncomment_setting_in_etc_default_grub() {
    local key="$1"
    local file="/etc/default/grub"

    if grep -E "^#\\s*$key=" "$file" >/dev/null 2>&1; then
        sudo sed -i "s|^#\\s*$key=\(.*\)|$key=\\1|g" "$file" || { log_error "Failed to uncomment '$key' in '$file'"; return 1; }
    fi
}
