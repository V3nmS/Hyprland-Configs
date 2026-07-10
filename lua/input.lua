return [[
# =============================================================================
# INPUT
# =============================================================================
input {
    kb_layout    = latam
    follow_mouse = 1
    sensitivity  = 0

    repeat_rate = 50
    repeat_delay = 300

    touchpad {
        natural_scroll = true 
    }
}

gesture = 3, horizontal, workspace

device {
	name = epic-mouse-v1
	sensitivity = -0.5
}

]]
