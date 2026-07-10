#!/bin/bash
# ~/.config/hypr/scripts/reload.sh

CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Genera los archivos y recarga
hypygen && hyprctl reload

sleep 0.3

# Re-establece el foco
hyprctl dispatch workspace "$CURRENT_WS"
hyprctl dispatch movefocus l
hyprctl dispatch movefocus r
