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

-- ============================================
-- Preview de markdown en chromium
-- ============================================
-- Lo lanza nvim con <leader>mp (ver ~/.config/nvim/lua/plugins/markdown-preview.lua).
--
-- El match NO puede ser "mdpreview" a secas: chromium ignora --class en Wayland,
-- esa flag es de X11. El app_id que sí publica tiene la forma
--     chrome-<host>_<path>-<perfil>
-- donde el perfil sale de --profile-directory. Medido con `hyprctl clients`:
--     chrome-localhost__page_1-mdpreview
--
-- Por eso es regex y no un string literal: el `page_1` del medio viene del path
-- de la URL (/page/1) y CAMBIA de número con cada buffer que previsualizas.
-- Anclar al sufijo `-mdpreview` es lo único estable, porque el perfil sí lo
-- controlamos nosotros desde nvim. Si cambias el --profile-directory allá,
-- este match deja de pegar.
--
-- Cae a la derecha por `force_split = 2` en layouts.lua.
hl.window_rule({
	name = "mdpreview",
	match = { class = "^chrome-.*-mdpreview$" },
	tile = true,
	-- Lo importante: que NO robe el foco al abrirse. Sin esto, cada <leader>mp
	-- te manda el teclado a chromium y acabas escribiendo la nota en el navegador.
	no_initial_focus = true,
})
