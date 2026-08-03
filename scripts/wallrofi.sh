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

# Rutas completas en un array (null-delimited para aguantar espacios/raros)
mapfile -d '' -t WALLS < <(find "$WALL_DIR" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" \
    \) -print0 | sort -z)

[ ${#WALLS[@]} -eq 0 ] && {
    notify-send "wallrofi" "No hay imágenes en $WALL_DIR"
    exit 1
}

# Solo los nombres a rofi; -format i devuelve el índice de la selección
IDX=$(printf '%s\n' "${WALLS[@]##*/}" | rofi \
    -dmenu \
    -i \
    -format i \
    -theme "$ROFI_THEME" \
    -p "󰉔 Wallpaper")

# Vacío = ESC, -1 = texto custom que no matchea ninguna entrada
[ -z "$IDX" ] || [ "$IDX" -lt 0 ] && exit 0

WALL="${WALLS[$IDX]}"

[ -x "$SETWALL" ] || chmod +x "$SETWALL"
bash "$SETWALL" "$WALL"

~/.config/mako/scripts/update-colors.sh
