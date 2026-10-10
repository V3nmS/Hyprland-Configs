-- windowrules.lua
hl.window_rule({
	name = "suppress_maximize_events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

-- Yazi como scratchpad flotante (SUPER+E en binds.lua).
-- La clase "yazi-float" se la pone el propio kitty al lanzarlo con --class,
-- para poder distinguirlo de tus terminales normales.
--
-- Vive en un special workspace: así SUPER+E lo esconde sin matar el proceso y
-- al volver sigues en el mismo directorio. Medido: 960x756 en tu 1920x1080.
hl.window_rule({
	name = "yazi-scratchpad",
	match = { class = "yazi-float" },
	float = true,
	center = true,
	size = { "(monitor_w*0.5)", "(monitor_h*0.7)" },
	workspace = "special:yazi",
})

-- Mezclador wiremix como scratchpad (SUPER+A, o clic derecho al volumen en
-- waybar). Mismo truco que yazi: kitty le pone la clase "wiremix-float" y el
-- special workspace deja esconderlo sin matar el proceso.
-- El toggle vive en ~/.config/waybar/scripts/wiremix-toggle.sh.
hl.window_rule({
	name = "mixer-scratchpad",
	match = { class = "wiremix-float" },
	float = true,
	center = true,
	size = { "(monitor_w*0.45)", "(monitor_h*0.55)" },
	workspace = "special:mixer",
})
