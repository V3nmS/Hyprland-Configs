#!/bin/bash
# lid.sh — gestión de monitores según estado de tapa y HDMI
#
# Migrado a la API Lua de Hyprland 0.55+.
#   hyprctl keyword  -> MUERTO con config Lua
#   hyprctl dispatch -> MUERTO con config Lua
#   hyprctl eval     -> la vía actual
#
# OJO: dos formas de argumento están SIN VERIFICAR (marcadas abajo).
# Si el comportamiento es raro, empieza por ahí.

LAPTOP="eDP-1"
EXTERNAL="HDMI-A-1"

# Helper: ejecuta una expresión Lua en Hyprland.
# Devuelve el output para poder detectar errores.
hypr_eval() {
    local expr="$1"
    local out

    out=$(hyprctl eval "$expr" 2>&1)

    if [ "$out" != "ok" ]; then
        echo "[lid.sh] eval falló: $expr" >&2
        echo "[lid.sh]   -> $out" >&2
        return 1
    fi

    return 0
}

lid_closed() {
    grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null
}

external_connected() {
    for status in /sys/class/drm/*-"$EXTERNAL"/status; do
        [ -f "$status" ] && grep -q connected "$status" && return 0
    done
    return 1
}

# --- Helpers de monitor -----------------------------------------------------

# ⚠️ SIN VERIFICAR: la llave para desactivar. Si 'disabled = true' no jala,
# prueba con mode = "disable" y cambia esta función.
monitor_disable() {
    local output="$1"
    hypr_eval "hl.monitor({ output = \"$output\", disabled = true })"
}

monitor_enable() {
    local output="$1"
    local mode="$2"
    local position="$3"

    hypr_eval "hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$position\", scale = 1 })"
}

# ⚠️ SIN VERIFICAR: forma de hl.dsp.workspace.move.
# El nombre del dispatcher sí está confirmado en el stub; las llaves no.
move_workspaces_to() {
    local target="$1"
    local ws

    for ws in 1 2 3 4 5 6 7 8 9; do
        hypr_eval "hl.dispatch(hl.dsp.workspace.move({ workspace = $ws, monitor = \"$target\" }))" >/dev/null 2>&1
    done
}

# --- Escenarios -------------------------------------------------------------

laptop_only_setup() {
    monitor_disable "$EXTERNAL"
    monitor_enable "$LAPTOP" "1920x1080@120" "0x0"
    move_workspaces_to "$LAPTOP"
}

external_only_setup() {
    monitor_disable "$LAPTOP"
    monitor_enable "$EXTERNAL" "1920x1080@60" "0x0"
    move_workspaces_to "$EXTERNAL"
}

dual_setup() {
    monitor_enable "$EXTERNAL" "1920x1080@60" "0x0"
    monitor_enable "$LAPTOP" "1920x1080@120" "0x1080"
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
