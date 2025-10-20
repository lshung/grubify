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

    log_error "No GRUB themes directory found at '/boot/grub/themes' or '/boot/grub2/themes'."
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

get_grub_config_file() {
    if [[ -f /boot/grub/grub.cfg ]]; then
        echo "/boot/grub/grub.cfg"
        return 0
    fi

    if [[ -f /boot/grub2/grub.cfg ]]; then
        echo "/boot/grub2/grub.cfg"
        return 0
    fi

    log_error "No GRUB config file found at '/boot/grub/grub.cfg' or '/boot/grub2/grub.cfg'."
    return 1
}

get_grub_menu_entries() {
    get_grub_config_file >/dev/null || return 1

    local grub_config_file="$(get_grub_config_file)"

    awk '
        /^menuentry \x27/ {
            match($0, /^menuentry \x27([^\x27]*)\x27/, arr);
            print arr[1];
            next
        }
        /^submenu \x27/ {
            match($0, /^submenu \x27([^\x27]*)\x27/, arr);
            print arr[1];
            next
        }
        /\s*menuentry \x27UEFI Firmware Settings\x27/ { print "UEFI Firmware Settings" }
    ' "$grub_config_file" || { log_error "Cannot get GRUB menu entries."; return 1; }
}
