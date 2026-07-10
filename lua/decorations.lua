return [[
# =============================================================================
# LOOK & FEEL
# =============================================================================

general {
    gaps_in          = 8 
    gaps_out         = 10
    border_size      = 0
    layout           = dwindle
    allow_tearing    = false
    resize_on_border = true
}

decoration {
    rounding = 10
    rounding_power = 10

    active_opacity = 1.0
    inactive_opacity = 1.0

    blur {
        enabled  = true
        size     = 8
        passes   = 1
        vibrancy = 0.1696
    }

    shadow {
        enabled      = true
        range        = 4
        render_power = 3
        color        = rgba(1a1a1aee)
    }
}

plugin {
    hyprlux {
        vibrance   = 0.4
        brightness = 0.1
        contrast   = 0.0
    }

    hyprexpo {
        columns = 3
        gap_size = 24
        bg_col = rgba(050505ee)
        workspace_method = center current
        enable_gesture = false
    }
}
]]
