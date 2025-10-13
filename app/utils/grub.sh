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
