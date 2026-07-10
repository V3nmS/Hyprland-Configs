return [[
# =============================================================================
# MONITORS
# =============================================================================

monitor=,preferred,auto,1

# Listener permanente
exec-once=~/.config/hypr/scripts/lid.sh --daemon

# Reaplicar estado después de reload
exec=sleep 0.5 && ~/.config/hypr/scripts/lid.sh --apply
]]
