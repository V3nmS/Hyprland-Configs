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
# Posición temporal, a la derecha de todo. Se usa para encender una salida
# SIN que se traslape con la que ya está viva: Hyprland tira
# "detected overlap with layout" si dos monitores comparten coordenadas.
STAGE_POS="3840x0"
LAPTOP_POS_DUAL="0x1080"
LAPTOP_POS_SOLO="0x0"

PIDFILE="/tmp/lid-${UID:-$(id -u)}.pid"
LOCKFILE="/tmp/lid-${UID:-$(id -u)}.lock"

DEBOUNCE=0.35      # s. los eventos llegan en ráfaga; se coalescen
QUIET=1.2          # s. de sordera tras aplicar, para no oír nuestro propio eco
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

mon_pos() {
    monitors_json | jq -r --arg n "$1" '.[] | select(.name == $n) | "\(.x)x\(.y)"' 2>/dev/null
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

# OJO — VERIFICADO 2026-09-18 contra Hyprland 0.56.2:
# una salida marcada `disabled = true` NO revive pasándole mode/position.
# Se queda apagada para siempre hasta que se le manda `disabled = false`
# EXPLÍCITO. Ese era el otro medio bug de la pantalla negra: al abrir la tapa
# el script "reencendía" el eDP con mode+position y no pasaba absolutamente
# nada. Por eso aquí `disabled = false` va SIEMPRE, no solo cuando creemos
# que hace falta.
monitor_enable() {
    local out="$1" mode="$2" pos="$3"
    hypr_eval "hl.monitor({ output = \"$out\", disabled = false, mode = \"$mode\", position = \"$pos\", scale = 1 })" || return 1
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

# Nunca se enciende una salida encima de otra. Hyprland acepta el traslape
# pero lo reporta como ERROR y el arreglo queda indefinido; de ahí el
# "Monitor HDMI-A-1: detected overlap with layout".
laptop_only_setup() {
    if mon_enabled "$LAPTOP"; then
        # Ya hay pantalla viva: se puede apagar el externo sin riesgo, y al
        # quedar solo el eDP su posición final ya no traslapa con nada.
        monitor_disable "$EXTERNAL"
        monitor_enable "$LAPTOP" "$LAPTOP_MODE" "$LAPTOP_POS_SOLO" || return 1
    else
        # El eDP está apagado (venimos de tapa cerrada). Se enciende lejos,
        # se apaga el externo, y hasta entonces se trae a 0x0.
        monitor_enable "$LAPTOP" "$LAPTOP_MODE" "$STAGE_POS" || {
            log "no pude prender $LAPTOP; no apago nada"
            return 1
        }
        monitor_disable "$EXTERNAL"
        monitor_enable "$LAPTOP" "$LAPTOP_MODE" "$LAPTOP_POS_SOLO"
    fi
    move_workspaces_to "$LAPTOP"
}

external_only_setup() {
    # GUARDIA: el externo se prende y se VERIFICA antes de apagar el panel de
    # la laptop. Se prende en STAGE_POS para no traslaparse con el eDP, que
    # en este momento todavía está vivo en 0x0.
    if ! monitor_enable "$EXTERNAL" "$EXTERNAL_MODE" "$STAGE_POS"; then
        log "$EXTERNAL no levantó; me quedo en solo-laptop"
        laptop_only_setup
        return
    fi

    move_workspaces_to "$EXTERNAL"
    monitor_disable "$LAPTOP"

    # Ya sin el eDP encendido, 0x0 quedó libre.
    monitor_enable "$EXTERNAL" "$EXTERNAL_MODE" "$EXTERNAL_POS" \
        || log "aviso: $EXTERNAL no llegó a $EXTERNAL_POS"
}

dual_setup() {
    # Primero se baja el eDP a 0x1080 para liberar 0x0, y hasta entonces se
    # mete el externo ahí. Al revés se traslapan durante el paso intermedio.
    monitor_enable "$LAPTOP" "$LAPTOP_MODE" "$LAPTOP_POS_DUAL" \
        || log "aviso: $LAPTOP no reposicionó"

    if ! monitor_enable "$EXTERNAL" "$EXTERNAL_MODE" "$EXTERNAL_POS"; then
        log "$EXTERNAL no levantó; me quedo en solo-laptop"
        laptop_only_setup
        return
    fi
}

# ¿La pantalla YA está como la quiere este escenario? Si sí, apply_state no
# toca absolutamente nada.
#
# Esto no es una optimización: es corrección. Sin este guardia, CADA evento
# re-ejecutaba move_workspaces_to, que arrastra todos los workspaces al
# monitor destino. Con acpi_listen escupiendo eventos de batería y CPU cada
# pocos segundos, los workspaces se reacomodaban solos todo el tiempo — el
# "bug raro de workspaces".
layout_ok() {
    case "$1" in
    laptop)
        mon_enabled "$LAPTOP" || return 1
        [ "$(mon_pos "$LAPTOP")" = "$LAPTOP_POS_SOLO" ] || return 1
        mon_enabled "$EXTERNAL" && return 1
        return 0
        ;;
    external)
        mon_enabled "$EXTERNAL" || return 1
        mon_enabled "$LAPTOP" && return 1
        [ "$(mon_pos "$EXTERNAL")" = "$EXTERNAL_POS" ] || return 1
        return 0
        ;;
    dual)
        mon_enabled "$EXTERNAL" || return 1
        mon_enabled "$LAPTOP" || return 1
        [ "$(mon_pos "$EXTERNAL")" = "$EXTERNAL_POS" ] || return 1
        [ "$(mon_pos "$LAPTOP")" = "$LAPTOP_POS_DUAL" ] || return 1
        return 0
        ;;
    esac
    return 1
}

apply_state() {
    local ext=0 lid=0 scenario
    external_connected && ext=1
    lid_closed && lid=1

    if [ "$lid" = 1 ] && [ "$ext" = 1 ]; then
        scenario=external
    elif [ "$ext" = 1 ]; then
        scenario=dual
    else
        # Sin HDMI: siempre laptop, tenga la tapa como la tenga.
        # (Tapa cerrada y sin externo = no hay a dónde mandar nada;
        #  apagar el eDP aquí es justo el bug original.)
        scenario=laptop
    fi

    if [ "${1:-}" != "--force" ] && layout_ok "$scenario"; then
        return 0
    fi

    log "aplicando escenario: $scenario (tapa=$lid externo=$ext)"
    log "  antes  mon: $(monitors_json | jq -Sc '[.[]|{name,x,y,d:(.disabled//false)}]')"
    log "  antes  ws : $(hyprctl workspaces -j | jq -Sc '[.[]|{id,mon:.monitor}]')"

    case "$scenario" in
    external) external_only_setup ;;
    dual)     dual_setup ;;
    laptop)   laptop_only_setup ;;
    esac

    log "  después mon: $(monitors_json | jq -Sc '[.[]|{name,x,y,d:(.disabled//false)}]')"
    log "  después ws : $(hyprctl workspaces -j | jq -Sc '[.[]|{id,mon:.monitor}]')"

    # Waybar se queda con la lista de workspaces persistentes del arranque y no
    # la recalcula al cambiar los monitores: de ahí la barra con workspaces de
    # más y el indicador activo trabado. Se regenera y se relanza SOLO aquí,
    # o sea únicamente cuando hubo transición de verdad — no en cada evento.
    relaunch_waybar

    # Red de seguridad final: jamás cero salidas prendidas.
    if [ "$(enabled_count)" -lt 1 ]; then
        log "QUEDARON 0 MONITORES PRENDIDOS — recuperando $LAPTOP"
        hypr_eval "hl.monitor({ output = \"$LAPTOP\", disabled = false, mode = \"$LAPTOP_MODE\", position = \"$LAPTOP_POS_SOLO\", scale = 1 })"
    fi
}

relaunch_waybar() {
    local sh="$HOME/.config/waybar/scripts/launch.sh"
    [ -x "$sh" ] || return 0
    setsid nohup bash "$sh" >/dev/null 2>&1 </dev/null &
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
    exec 9>"$LOCKFILE"
    flock -n 9 || { log "ya hay un daemon corriendo"; exit 1; }
    echo "$$" > "$PIDFILE"

    FIFO=$(mktemp -u "/tmp/lid-events-${UID}-XXXXXX")
    mkfifo "$FIFO" || exit 1

    # Abrir en lectura+escritura (<>) mantiene el FIFO vivo: nunca da EOF
    # aunque un escritor muera, y no bloquea al abrirlo.
    exec 8<>"$FIFO"
    rm -f "$FIFO"          # ya no hace falta el nodo en disco

    CHILDREN=()
    # Matar solo al subshell deja huérfanos a acpi_listen y socat (se
    # reparentan a init y siguen vivos). Hay que bajar por el árbol.
    kill_tree() {
        local pid="$1" kid
        for kid in $(pgrep -P "$pid" 2>/dev/null); do
            kill_tree "$kid"
        done
        kill "$pid" 2>/dev/null
    }
    cleanup() {
        local p
        for p in "${CHILDREN[@]:-}"; do
            [ -n "$p" ] && kill_tree "$p"
        done
    }
    trap cleanup EXIT INT TERM

    # Fuente 1: tapa (ACPI).
    # SOLO eventos de tapa. acpi_listen escupe además batería, CPU, wmi y el
    # jack de audio cada pocos segundos; sin este filtro el daemon despierta
    # constantemente sin que nada relacionado con monitores haya cambiado.
    ( acpi_listen 2>/dev/null \
        | grep --line-buffered -iE 'button/lid' \
        | sed -u 's/^/acpi /' >&8 ) &
    CHILDREN+=("$!")

    # Fuente 2: hotplug de monitores, vía el socket de eventos de Hyprland.
    # ESTO es lo que le faltaba al script viejo: el HDMI no genera evento ACPI.
    (
        while :; do
            sock=$(sock2_path)
            if [ -n "$sock" ]; then
                socat -U - "UNIX-CONNECT:$sock" 2>/dev/null \
                    | grep --line-buffered -E '^monitor(added|removed)' \
                    | sed -u 's/^/hypr /'
            fi
            sleep 2   # el socket se recrea si Hyprland reinicia
        done >&8
    ) &
    CHILDREN+=("$!")

    apply_state

    # Coalesce: tras el primer evento se drena la ráfaga y se aplica una sola vez.
    # El -t 60 no es cosmético: sin timeout, bash se queda dentro del builtin
    # `read` y NO procesa el trap de TERM, así que el daemon se vuelve
    # inmatable y se acumulan instancias. Con timeout el loop respira cada
    # minuto y los traps corren.
    while :; do
        if read -r -t 60 ev <&8; then
            # Ráfaga: los eventos llegan de a montones por un solo cambio.
            while read -r -t "$DEBOUNCE" _ <&8; do :; done

            log "evento: $ev -> re-aplicando"
            apply_state

            # MUTE — imprescindible. Encender o apagar una salida hace que
            # Hyprland emita monitoradded / monitorremoved, o sea que nuestra
            # propia reconfiguración nos vuelve a despertar y apply_state se
            # re-ejecuta en bucle. Cada vuelta llamaba a move_workspaces_to,
            # que arrastra todos los workspaces de monitor: ése era el
            # "bug raro de workspaces".
            #
            # Aquí se tragan los ecos que generamos nosotros mismos.
            while read -r -t "$QUIET" _ <&8; do :; done
        fi
    done
}

# --- Diagnóstico ------------------------------------------------------------

status() {
    echo "tapa            : $(lid_closed && echo cerrada || echo abierta)"
    echo "$EXTERNAL       : $(external_connected && echo conectado || echo desconectado)"
    echo "monitores vivos : $(enabled_count)"
    echo "socket2         : $(sock2_path || echo '(no encontrado)')"
    echo "daemon          : $(daemon_running && echo "vivo (pid $(cat "$PIDFILE"))" || echo 'NO corre')"
    echo
    monitors_json | jq -r '.[] | "  \(.name)  pos=\(.x)x\(.y)  disabled=\(.disabled // false)"'
}

# Apaga el daemon vivo y todo lo que colgaba de él.
#
# Va por PID file, NO por `pgrep -f 'lid.sh --daemon'`: pgrep -f compara
# contra la línea de comando COMPLETA de todo proceso, así que una shell que
# simplemente mencione esa cadena (un grep, un echo, este propio script)
# matchea y se autodestruye. Ya pasó.
#
# Tampoco se borra el lockfile: borrarlo rompe flock, porque el proceso viejo
# se queda con el inode y el nuevo crea un archivo distinto -> dos daemons.
stop_daemon() {
    local pid kid gk

    [ -f "$PIDFILE" ] || { log "no hay PID file; nada que detener"; return 0; }
    pid=$(cat "$PIDFILE" 2>/dev/null)

    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$PIDFILE"
        return 0
    fi

    # De abajo hacia arriba: nietos (acpi_listen, socat, grep, sed), hijos
    # (los dos subshells) y al final el padre.
    for kid in $(pgrep -P "$pid" 2>/dev/null); do
        for gk in $(pgrep -P "$kid" 2>/dev/null); do
            kill "$gk" 2>/dev/null
        done
        kill "$kid" 2>/dev/null
    done
    kill "$pid" 2>/dev/null

    sleep 0.7

    # Escalada: un daemon atorado en `read` puede ignorar el TERM.
    if kill -0 "$pid" 2>/dev/null; then
        for kid in $(pgrep -P "$pid" 2>/dev/null); do
            for gk in $(pgrep -P "$kid" 2>/dev/null); do kill -9 "$gk" 2>/dev/null; done
            kill -9 "$kid" 2>/dev/null
        done
        kill -9 "$pid" 2>/dev/null
    fi

    rm -f "$PIDFILE"
    return 0
}

daemon_running() {
    local pid
    [ -f "$PIDFILE" ] || return 1
    pid=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

case "${1:-}" in
--daemon) daemon ;;
--stop)   stop_daemon; echo "daemon detenido" ;;
--restart) stop_daemon; sleep 0.5
           setsid nohup "$0" --daemon >/tmp/lid-daemon.log 2>&1 </dev/null &
           sleep 2; echo "daemon reiniciado"; status ;;
--apply)  apply_state ;;
--status) status ;;
*)        apply_state ;;
esac
