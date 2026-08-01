#!/bin/bash

WALL="$(realpath "$1")"
SDDM_BG="/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/custom.jpg"

[ -f "$WALL" ] || {
    notify-send "Wallpaper" "No existe: $WALL"
    exit 1
}

mkdir -p "$HOME/.cache"
echo "$WALL" >"$HOME/.cache/current_wallpaper"

awww img "$WALL"

wal -i "$WALL" -n -q --saturate 1.2

source "$HOME/.cache/wal/colors.sh"

hex_to_rgba() {
    local hex="${1#"#"}"
    local alpha="$2"
    echo "rgba(${hex}${alpha})"
}

get_brightness() {
    local hex="${1#"#"}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo $(((r * 299 + g * 587 + b * 114) / 1000))
}

MAIN_BG="$color0"
BRIGHTNESS=$(get_brightness "$MAIN_BG")

if [ "$BRIGHTNESS" -lt 80 ]; then
    WAL_FONT="#ffffff"
else
    WAL_FONT="#000000"
fi

# ── Rofi ──────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/rofi"

cat >"$HOME/.config/rofi/colors.rasi" <<EOF
* {
    bg:       ${color0}f2;
    bg2:      ${color1}ee;
    selected: ${color4}ff;
    fg:       ${WAL_FONT};
}
EOF

# ── Waybar ────────────────────────────────────────────────────────────────
ln -sf "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/waybar/colors.css"

# ── Kitty ─────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/kitty"
grep -qxF 'include ~/.cache/wal/colors-kitty.conf' "$HOME/.config/kitty/kitty.conf" ||
    echo 'include ~/.cache/wal/colors-kitty.conf' >>"$HOME/.config/kitty/kitty.conf"

cat >~/.config/kitty/pywal-tabs.conf <<EOF
active_tab_background $color4
active_tab_foreground $color0

inactive_tab_background $color0
# inactive_tab_foreground $foreground

tab_bar_background none
EOF

# ── Hyprlock ──────────────────────────────────────────────────────────────
sed -i "s|path = .*|path = $WALL|g" "$HOME/.config/hypr/hyprlock.conf"
sed -i "s|.*#WAL_COLOR4|    outer_color = $(hex_to_rgba "$color4" "ff") #WAL_COLOR4|g" "$HOME/.config/hypr/hyprlock.conf"
sed -i "s|.*#WAL_BACKGROUND|    inner_color = $(hex_to_rgba "$background" "99") #WAL_BACKGROUND|g" "$HOME/.config/hypr/hyprlock.conf"
sed -i "s|.*#WAL_FONT|    font_color = $(hex_to_rgba "$WAL_FONT" "ff") #WAL_FONT|g" "$HOME/.config/hypr/hyprlock.conf"
sed -i "s|.*#WAL_CLOCK|    color = $(hex_to_rgba "$WAL_FONT" "ff") #WAL_CLOCK|g" "$HOME/.config/hypr/hyprlock.conf"
sed -i "s|.*#WAL_DATE|    color = $(hex_to_rgba "$WAL_FONT" "aa") #WAL_DATE|g" "$HOME/.config/hypr/hyprlock.conf"

# ── Mako ──────────────────────────────────────────────────────────────────
printf 'font=Rubik 11\nbackground-color=%see\ntext-color=%sff\nborder-color=%sff\nwidth=340\npadding=14\nmargin=20\nborder-size=1\ndefault-timeout=4500\nanchor=top-right\nicons=1\nmax-icon-size=42\n' \
    "$color0" "$WAL_FONT" "$color4" >"$HOME/.config/mako/config"

pkill mako 2>/dev/null
sleep 0.2
mako &

# ── SDDM ──────────────────────────────────────────────────────────────────
sudo -n cp "$WALL" "$SDDM_BG" 2>/dev/null &&
    sudo -n chmod 644 "$SDDM_BG" 2>/dev/null ||
    notify-send "SDDM" "No se pudo actualizar SDDM sin sudo"

# ── Autostart ─────────────────────────────────────────────────────────────
sed -i "s|^.*swww img.*$|hl.exec_cmd(\"bash -c 'sleep 1; swww img $WALL'\")|" \
    "$HOME/.config/hypr/lua/autostart.lua"

# ── Waybar reload ─────────────────────────────────────────────────────────
pkill waybar 2>/dev/null
sleep 0.3
bash "$HOME/.config/waybar/scripts/launch.sh" &

hyprctl reload

notify-send "Wallpaper" "Todo actualizado como default" --icon="$WALL"

~/.config/mako/scripts/update-colors.sh
