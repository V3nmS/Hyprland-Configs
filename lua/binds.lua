-- binds.lua
-- API nativa Lua de Hyprland (0.55+). Ver los binds activos con: hyprctl binds

-- =============================================================================
-- HELPERS SCROLLING
-- =============================================================================
-- El layout scrolling se prende por workspace, no global. Aquí llevamos la
-- cuenta de cuáles lo traen activo, porque los layoutmsg de scrolling
-- (colresize, move +col, etc.) TRUENAN si los mandas estando en dwindle:
--   "Unknown dwindle layoutmsg: colresize +0.02"
-- Por eso los binds compartidos preguntan primero en qué layout estás.
--
-- Ojo: este estado vive en memoria. Al recargar la config se vacía y todos los
-- workspaces regresan a dwindle, que es el default de general.layout.

local scrolling_ws = {}

local function active_ws_id()
	local ws = hl.get_active_workspace()
	return ws and ws.id or nil
end

local function is_scrolling()
	local id = active_ws_id()
	return id ~= nil and scrolling_ws[id] == true
end

-- Prende o apaga scrolling en el workspace donde estés parado.
local function set_scrolling(on)
	return function()
		local id = active_ws_id()
		if not id then
			return
		end

		scrolling_ws[id] = on

		hl.workspace_rule({
			workspace = tostring(id),
			layout = on and "scrolling" or "dwindle",
		})

		hl.notification.create({
			text = "ws " .. id .. ": " .. (on and "scrolling" or "dwindle"),
			time = 1200,
		})
	end
end

-- Manda un layoutmsg solo si el workspace actual está en scrolling.
local function scroll_msg(msg)
	return function()
		if is_scrolling() then
			hl.dispatch(hl.dsp.layout(msg))
		end
	end
end

-- =============================================================================
-- APLICACIONES
-- =============================================================================
hl.bind("ALT+Return", hl.dsp.exec_cmd("kitty"))
hl.bind("ALT+S", hl.dsp.exec_cmd("spotify"))
hl.bind("ALT+F", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER+E", hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER+SHIFT+D", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -theme ~/.config/rofi/style-3.rasi"))
hl.bind("SUPER+W", hl.dsp.exec_cmd("bash /home/v3nom/.config/hypr/scripts/wallrofi.sh"))

-- =============================================================================
-- GESTIÓN DE VENTANAS
-- =============================================================================
hl.bind("ALT+W", hl.dsp.window.close())
hl.bind("ALT+P", hl.dsp.window.pseudo())
hl.bind("ALT+V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT+F11", hl.dsp.window.fullscreen()) -- sin args = toggle fullscreen
hl.bind("ALT+SPACE", hl.dsp.layout("togglesplit")) -- dwindle only, inerte en scrolling
hl.bind("ALT+R", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))
hl.bind("ALT+SHIFT+R", hl.dsp.exec_cmd("~/.config/hypr/scripts/reload.sh"))

-- =============================================================================
-- SCROLLING LAYOUT (core desde Hyprland 0.54, NO es plugin)
-- =============================================================================
-- Ventanas sobre una cinta horizontal infinita: cada columna mide column_width
-- (ver layouts.lua) y las que no caben se salen de vista sin cerrarse.
-- Se activa por workspace: los demás siguen en dwindle sin enterarse.

hl.bind("SUPER+SPACE", set_scrolling(true), { description = "activar scrolling en este workspace" })
hl.bind("SUPER+BackSpace", set_scrolling(false), { description = "regresar este workspace a dwindle" })

-- Recorrer la cinta SIN cambiar de ventana, como arrastrarla con la mano.
-- Para cambiar el foco usa ALT+h/l: en scrolling brincan de columna y, con
-- follow_focus = true, la vista se recorre sola.
hl.bind("SUPER+X", scroll_msg("move +col"), { repeating = true }) -- derecha
hl.bind("SUPER+less", scroll_msg("move -col"), { repeating = true }) -- izquierda

-- Reordenar la cinta: intercambia tu columna con la vecina.
hl.bind("SUPER+SHIFT+X", scroll_msg("swapcol r"))
hl.bind("SUPER+SHIFT+less", scroll_msg("swapcol l"))

-- Una columna puede llevar varias ventanas apiladas.
hl.bind("SUPER+Return", scroll_msg("promote")) -- sacar la ventana a su propia columna
hl.bind("SUPER+C", scroll_msg("consume_or_expel next")) -- apilarla en la columna vecina

-- Encajar columnas en la pantalla.
hl.bind("SUPER+F", scroll_msg("fit_into_view")) -- la activa completa a la vista
hl.bind("SUPER+SHIFT+F", scroll_msg("fit expand")) -- estirarla al espacio que sobra

-- Ciclar los anchos de explicit_column_widths (layouts.lua): 33% -> 50% -> 66% -> 100%
hl.bind("SUPER+P", scroll_msg("colresize +conf"))

-- Congelar la vista para que no se recorra sola al cambiar de foco.
hl.bind("SUPER+I", scroll_msg("inhibit_scroll"))

-- =============================================================================
-- FOCUS
-- =============================================================================
-- Sirven igual en dwindle y en scrolling: allá brincan entre columnas.
hl.bind("ALT+h", hl.dsp.focus({ direction = "left" }))
hl.bind("ALT+l", hl.dsp.focus({ direction = "right" }))
hl.bind("ALT+k", hl.dsp.focus({ direction = "up" }))
hl.bind("ALT+j", hl.dsp.focus({ direction = "down" }))

-- =============================================================================
-- RESIZE
-- =============================================================================
-- repeating = true -> jala manteniendo la tecla apachurrada.
-- El paso bajó de 30 a 12 px porque con repeat_rate = 50 (input.lua) son
-- 50 disparos por segundo: a 30 px volaba a 1500 px/s y se pasaba de largo.
-- En scrolling el resize por píxeles no aplica; ahí se cambia el ancho de la
-- columna con colresize, así que el bind decide según el layout del workspace.

local RESIZE_STEP = 12 -- px por disparo (dwindle)
local COL_STEP = 0.015 -- fracción de pantalla por disparo (scrolling)

local function resize_horizontal(px, frac)
	return function()
		if is_scrolling() then
			hl.dispatch(hl.dsp.layout("colresize " .. frac))
		else
			hl.dispatch(hl.dsp.window.resize({ x = px, y = 0, relative = true }))
		end
	end
end

hl.bind("ALT+SHIFT+l", resize_horizontal(RESIZE_STEP, "+" .. COL_STEP), { repeating = true })
hl.bind("ALT+SHIFT+h", resize_horizontal(-RESIZE_STEP, "-" .. COL_STEP), { repeating = true })

-- Vertical: en scrolling no hay alto de columna que mover, se queda tal cual.
hl.bind("ALT+SHIFT+k", hl.dsp.window.resize({ x = 0, y = -RESIZE_STEP, relative = true }), { repeating = true })
hl.bind("ALT+SHIFT+j", hl.dsp.window.resize({ x = 0, y = RESIZE_STEP, relative = true }), { repeating = true })

-- =============================================================================
-- MOVER VENTANAS (tiled)
-- =============================================================================
hl.bind("CTRL+SUPER+h", hl.dsp.window.move({ direction = "left" }))
hl.bind("CTRL+SUPER+l", hl.dsp.window.move({ direction = "right" }))
hl.bind("CTRL+SUPER+k", hl.dsp.window.move({ direction = "up" }))
hl.bind("CTRL+SUPER+j", hl.dsp.window.move({ direction = "down" }))

-- =============================================================================
-- WORKSPACES
-- =============================================================================
-- "e+1" / "e-1" pasa por los workspaces vacíos; "+1" / "-1" los salta.
-- Antes el teclado usaba "+1"/"-1" y el scroll del mouse "e+1"/"e-1".
-- Unificado a e±1 para que ambos se sientan igual.
hl.bind("ALT+X", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT+less", hl.dsp.focus({ workspace = "e-1" }))

hl.bind("ALT+mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT+mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Ir al workspace N
for i = 1, 9 do
	hl.bind("ALT+" .. i, hl.dsp.focus({ workspace = i }))
end
hl.bind("ALT+0", hl.dsp.focus({ workspace = 10 })) -- 0 mapea a ws 10

-- Mandar la ventana al workspace N sin seguirla (follow = false)
for i = 1, 9 do
	hl.bind("ALT+SHIFT+" .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind("ALT+SHIFT+0", hl.dsp.window.move({ workspace = 10, follow = false }))

-- =============================================================================
-- MOUSE
-- =============================================================================
hl.bind("ALT+mouse:272", hl.dsp.window.drag(), { mouse = true }) -- LMB: mover
hl.bind("ALT+mouse:273", hl.dsp.window.resize(), { mouse = true }) -- RMB: redimensionar

-- =============================================================================
-- SCREENSHOTS
-- =============================================================================
hl.bind("Print", hl.dsp.exec_cmd("grim ~/Pictures/screenshot_$(date +%F_%T).png"))
hl.bind("SHIFT+Print", hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%F_%T).png'))
hl.bind("SUPER+SHIFT+S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy')) -- región al portapapeles

-- =============================================================================
-- OPACIDAD
-- =============================================================================
-- ANTES usaban `hyprctl keyword decoration:active_opacity ...`, que desde la
-- migración a Lua contesta: "keyword can't work with non-legacy parsers. Use eval."
-- O sea llevaban rotos desde entonces. `hyprctl eval` sí evalúa Lua en caliente.
hl.bind(
	"ALT+O",
	hl.dsp.exec_cmd("hyprctl eval 'hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 1.0 } })'")
)
hl.bind(
	"ALT+SHIFT+O",
	hl.dsp.exec_cmd("hyprctl eval 'hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 0.90 } })'")
)

-- =============================================================================
-- LOCK / LOGOUT
-- =============================================================================
hl.bind("SUPER+L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(
	"SUPER+Escape",
	hl.dsp.exec_cmd(
		"wlogout --protocol layer-shell -b 3 --css ~/.config/wlogout/style.css --layout ~/.config/wlogout/layout"
	)
)

-- =============================================================================
-- BLUETOOTH / WIFI
-- =============================================================================
hl.bind("SUPER+SHIFT+B", hl.dsp.exec_cmd("~/.config/rofi/scripts/bluetooth.sh"))
hl.bind(
	"SUPER+SHIFT+W",
	hl.dsp.exec_cmd("networkmanager_dmenu -dmenu 'rofi -dmenu -i -theme /home/v3nom/.config/rofi/style-3.rasi'")
)

-- =============================================================================
-- VOLUMEN / BRILLO / MULTIMEDIA
-- =============================================================================
-- locked = true -> siguen respondiendo con hyprlock en pantalla.

-- Teclas F pelonas
hl.bind("F9", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("F8", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("F7", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
hl.bind("F10", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })

-- Teclas multimedia Dell (XF86)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, locked = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })

-- Playerctl
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
