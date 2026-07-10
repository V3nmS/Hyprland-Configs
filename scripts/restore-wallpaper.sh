#!/bin/bash

sleep 1

WALL=$(cat ~/.cache/current_wallpaper)

[ -f "$WALL" ] || exit 1

awww img "$WALL"

wal -R

pkill waybar 2>/dev/null
bash ~/.config/waybar/scripts/launch.sh &

pkill mako 2>/dev/null
mako &
