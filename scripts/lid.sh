#!/bin/bash
# lid.sh — gestión automática de monitores según tapa (lid) y HDMI.
#
# Reescrito 2026-09-18. Lo que estaba roto en la versión anterior:
#
#   1. external_connected() usaba `grep -q connected`, y la cadena
#      "disconnected" CONTIENE "connected" -> devolvía true SIEMPRE.
#      Con la tapa abierta eso forzaba dual_setup() (eDP clavado en 0x1080,
#      de ahí el desmadre de workspaces); con la tapa cerrada forzaba
#      external_only_setup(), que APAGABA el eDP sin HDMI real = pantalla
#      negra y apagón a la fuerza.  Ahora se usa `grep -qx`.
#
#   2. El daemon solo escuchaba acpi_listen. Conectar/desconectar HDMI NO es
#      un evento ACPI (es un uevent de DRM), así que el hotplug jamás
#      disparaba nada -> "no hace el cambio automático".  Ahora se escuchan
#      LAS DOS fuentes: acpi_listen (tapa) + el socket2 de Hyprland
#      (monitoradded / monitorremoved).
#
#   3. Nada se verificaba. Ahora cada cambio se comprueba contra
#      `hyprctl monitors all -j`, y NUNCA se apaga una salida sin haber
#      confirmado antes que la otra quedó viva.
#
# Uso:
#   lid.sh --daemon    escucha eventos y aplica (va en exec-once)
#   lid.sh --apply     aplica el estado una vez
#   lid.sh --status    diagnóstico, no toca nada

set -uo pipefail

LAPTOP="eDP-1"
EXTERNAL="HDMI-A-1"

LAPTOP_MODE="1920x1080@120"
EXTERNAL_MODE="preferred"   # "preferred" aguanta cualquier monitor ajeno

# Posiciones: externo arriba, laptop abajo.
EXTERNAL_POS="0x0"
LAPTOP_POS_DUAL="0x1080"
LAPTOP_POS_SOLO="0x0"

DEBOUNCE=0.35      # s. los eventos llegan en ráfaga; se coalescen
SETTLE=0.45        # s. de espera tras prender una salida, antes de verificar

log() { printf '[lid.sh] %s\n' "$*" >&2; }

# --- Hyprland ---------------------------------------------------------------

# hyprctl eval SIEMPRE imprime "ok" cuando el Lua corre bien, y una línea que
# empieza con "error:" cuando truena. Ese es el criterio bueno.
hypr_eval() {
    local expr="$1" out
    out=$(hyprctl eval "$expr" 2>&1)
    if printf '%s' "$out" | grep -qi '^error:'; then
        log "eval falló: $expr"
        log "  -> $out"
        return 1
    fi
    return 0
}

monitors_json() { hyprctl monitors all -j 2>/dev/null; }

# ¿Hyprland ve esa salida (aunque esté apagada)?
mon_present() {
    monitors_json | jq -e --arg n "$1" 'any(.[]; .name == $n)' >/dev/null 2>&1
}

# ¿Está prendida y renderizando?
mon_enabled() {
    monitors_json | jq -e --arg n "$1" \
        'any(.[]; .name == $n and (.disabled // false) == false)' >/dev/null 2>&1
}

enabled_count() {
    monitors_json | jq '[.[] | select((.disabled // false) == false)] | length' 2>/dev/null || echo 0
}

# --- Hardware ---------------------------------------------------------------

# -x = la línea entera debe ser "connected". Sin -x, "disconnected" matchea.
external_connected() {
    local st
    for st in /sys/class/drm/*-"$EXTERNAL"/status; do
        [ -f "$st" ] || continue
        grep -qx connected "$st" && return 0
    done
    return 1
}

lid_closed() {
    local st
    for st in /proc/acpi/button/lid/*/state; do
        [ -f "$st" ] || continue
        grep -qw closed "$st" && return 0
    done
    return 1
}

# --- Operaciones sobre monitores --------------------------------------------

monitor_enable() {
    local out="$1" mode="$2" pos="$3"
    hypr_eval "hl.monitor({ output = \"$out\", mode = \"$mode\", position = \"$pos\", scale = 1 })" || return 1
    sleep "$SETTLE"
    mon_enabled "$out"
}

# Apaga una salida y COMPRUEBA que se apagó. Si la llave `disabled` no fuera
# la buena en esta versión de Hyprland, cae al modo "disable" y vuelve a medir.
monitor_disable() {
    local out="$1"

    hypr_eval "hl.monitor({ output = \"$out\", disabled = true })"
    sleep 0.2
    mon_enabled "$out" || return 0

    log "'disabled = true' no surtió en $out; probando mode = \"disable\""
    hypr_eval "hl.monitor({ output = \"$out\", mode = \"disable\" })"
    sleep 0.2
    mon_enabled "$out" || return 0

    log "NO se pudo apagar $out; lo dejo prendido (mejor eso que pantalla negra)"
    return 1
}

# Mueve SOLO los workspaces que existen de verdad. La versión vieja iteraba
# 1..9 a ciegas, creando ruido y moviendo cosas que no estaban.
move_workspaces_to() {
    local target="$1" ids id
    mon_present "$target" || return 0

    ids=$(hyprctl workspaces -j 2>/dev/null \
          | jq -r --arg t "$target" '.[] | select(.id > 0 and .monitor != $t) | .id')

    for id in $ids; do
        hypr_eval "hl.dispatch(hl.dsp.workspace.move({ workspace = $id, monitor = \"$target\" }))" \
            >/dev/null 2>&1
    done
}

# --- Escenarios -------------------------------------------------------------

laptop_only_setup() {
    monitor_enable "$LAPTOP" "$LAPTOP_MODE" "$LAPTOP_POS_SOLO" || {
        log "no pude prender $LAPTOP; no apago nada"
        return 1
    }
    monitor_disable "$EXTERNAL"
    move_workspaces_to "$LAPTOP"
}

external_only_setup() {
    # GUARDIA: primero se prende el externo y se VERIFICA. Solo si quedó vivo
    # se apaga el panel de la laptop. Esto es lo que vuelve imposible el
    # apagón a ciegas de la versión anterior.
    if ! monitor_enable "$EXTERNAL" "$EXTERNAL_MODE" "$EXTERNAL_POS"; then
        log "$EXTERNAL no levantó; me quedo en solo-laptop"
        laptop_only_setup
        return
    fi

    move_workspaces_to "$EXTERNAL"
    monitor_disable "$LAPTOP"
}

dual_setup() {
    if ! monitor_enable "$EXTERNAL" "$EXTERNAL_MODE" "$EXTERNAL_POS"; then
        log "$EXTERNAL no levantó; me quedo en solo-laptop"
        laptop_only_setup
        return
    fi
    monitor_enable "$LAPTOP" "$LAPTOP_MODE" "$LAPTOP_POS_DUAL" \
        || log "aviso: $LAPTOP no reposicionó"
}

apply_state() {
    local ext=0 lid=0
    external_connected && ext=1
    lid_closed && lid=1

    if [ "$lid" = 1 ] && [ "$ext" = 1 ]; then
        external_only_setup
    elif [ "$ext" = 1 ]; then
        dual_setup
    else
        # Sin HDMI: siempre laptop, tenga la tapa como la tenga.
        # (Tapa cerrada y sin externo = no hay a dónde mandar nada;
        #  apagar el eDP aquí es justo el bug que se está arreglando.)
        laptop_only_setup
    fi

    # Red de seguridad final: jamás cero salidas prendidas.
    if [ "$(enabled_count)" -lt 1 ]; then
        log "QUEDARON 0 MONITORES PRENDIDOS — recuperando $LAPTOP"
        hypr_eval "hl.monitor({ output = \"$LAPTOP\", mode = \"$LAPTOP_MODE\", position = \"$LAPTOP_POS_SOLO\", scale = 1 })"
    fi
}

# --- Daemon -----------------------------------------------------------------

sock2_path() {
    local sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
    local base="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
    if [ -n "$sig" ] && [ -S "$base/$sig/.socket2.sock" ]; then
        printf '%s\n' "$base/$sig/.socket2.sock"
        return 0
    fi
    # Fallback: la instancia más reciente.
    local d
    d=$(ls -td "$base"/*/ 2>/dev/null | head -1)
    [ -n "$d" ] && [ -S "${d}.socket2.sock" ] && printf '%s\n' "${d}.socket2.sock"
}

daemon() {
    local LOCKFILE="/tmp/lid-${UID}.lock"
    exec 9>"$LOCKFILE"
    flock -n 9 || { log "ya hay un daemon corriendo"; exit 1; }

    local FIFO
    FIFO=$(mktemp -u "/tmp/lid-events-${UID}-XXXXXX")
    mkfifo "$FIFO" || exit 1
    # shellcheck disable=SC2064
    trap "rm -f '$FIFO'; kill 0" EXIT INT TERM

    # Fuente 1: tapa (ACPI).
    ( acpi_listen 2>/dev/null | sed -u 's/^/acpi /' > "$FIFO" ) &

    # Fuente 2: hotplug de monitores, vía el socket de eventos de Hyprland.
    # ESTO es lo que le faltaba al script viejo.
    (
        local sock
        while :; do
            sock=$(sock2_path)
            if [ -n "$sock" ]; then
                socat -U - "UNIX-CONNECT:$sock" 2>/dev/null \
                    | grep --line-buffered -E '^monitor(added|removed)' \
                    | sed -u 's/^/hypr /'
            fi
            sleep 2   # el socket se recrea si Hyprland reinicia
        done > "$FIFO"
    ) &

    apply_state

    # Coalesce: tras el primer evento se drena la ráfaga y se aplica una vez.
    local ev
    while read -r ev < "$FIFO"; do
        while read -r -t "$DEBOUNCE" _ < "$FIFO"; do :; done
        apply_state
    done
}

# --- Diagnóstico ------------------------------------------------------------

status() {
    echo "tapa            : $(lid_closed && echo cerrada || echo abierta)"
    echo "$EXTERNAL       : $(external_connected && echo conectado || echo desconectado)"
    echo "monitores vivos : $(enabled_count)"
    echo "socket2         : $(sock2_path || echo '(no encontrado)')"
    echo
    monitors_json | jq -r '.[] | "  \(.name)  pos=\(.x)x\(.y)  disabled=\(.disabled // false)"'
}

case "${1:-}" in
--daemon) daemon ;;
--apply)  apply_state ;;
--status) status ;;
*)        apply_state ;;
esac
