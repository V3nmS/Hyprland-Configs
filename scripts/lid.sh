#!/bin/bash

LAPTOP="eDP-1"
EXTERNAL="HDMI-A-1"

lid_closed() {
    grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null
}

external_connected() {
    for status in /sys/class/drm/*-"$EXTERNAL"/status; do
        [ -f "$status" ] && grep -q connected "$status" && return 0
    done
    return 1
}

move_workspaces_to() {
    local target="$1"
    for ws in 1 2 3 4 5 6 7 8 9; do
        hyprctl dispatch moveworkspacetomonitor "$ws" "$target" >/dev/null 2>&1
    done
}

laptop_only_setup() {
    hyprctl keyword monitor "$EXTERNAL,disable"
    hyprctl keyword monitor "$LAPTOP,1920x1080@120,0x0,1"
    move_workspaces_to "$LAPTOP"
}

external_only_setup() {
    hyprctl keyword monitor "$LAPTOP,disable"
    hyprctl keyword monitor "$EXTERNAL,1920x1080@60,0x0,1"
    move_workspaces_to "$EXTERNAL"
}

dual_setup() {
    hyprctl keyword monitor "$EXTERNAL,1920x1080@60,0x0,1"
    hyprctl keyword monitor "$LAPTOP,1920x1080@120,0x1080,1"
}

apply_state() {
    if lid_closed; then
        if external_connected; then
            external_only_setup
        else
            laptop_only_setup
        fi
    else
        if external_connected; then
            dual_setup
        else
            laptop_only_setup
        fi
    fi
}

daemon() {
    LOCKFILE="/tmp/lid.lock"
    exec 9>"$LOCKFILE"
    flock -n 9 || exit 1

    apply_state

    acpi_listen | while read -r _; do
        apply_state
    done
}

case "$1" in
--daemon)
    daemon
    ;;
--apply)
    apply_state
    ;;
*)
    apply_state
    ;;
esac
