#!/bin/bash

# Exportar env necesario para Wayland/rofi cuando se lanza desde Hyprland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export HOME="${HOME:-/home/v3nom}"

WALL_DIR="$HOME/Downloads/Wallpapers"
SETWALL="$HOME/.config/hypr/scripts/setwall.sh"
ROFI_THEME="$HOME/.config/rofi/style-3.rasi"

# Verifica que el directorio exista
[ -d "$WALL_DIR" ] || {
    notify-send "wallrofi" "Directorio no encontrado: $WALL_DIR"
    exit 1
}

WALL=$(find "$WALL_DIR" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" \
    \) | rofi \
    -dmenu \
    -i \
    -theme "$ROFI_THEME" \
    -p "󰉔 Wallpaper")

[ -z "$WALL" ] && exit 0

[ -x "$SETWALL" ] || chmod +x "$SETWALL"
bash "$SETWALL" "$WALL"

~/.config/mako/scripts/update-colors.sh
