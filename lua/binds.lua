-- binds.lua
-- Migrado de hyprlang (mods, key, dispatcher, args) a la API nativa Lua de Hyprland.

-- ============ APLICACIONES ============
-- ⚠️ Originalmente estaban en tu tabla "binde" (repeat-while-held).
--    Repetir exec al mantener presionado abriría múltiples instancias
--    (ej. varios kitty si dejas ALT+Return apachurrado). Las dejo SIN
--    repeating por default -- avísame si de verdad las quieres repetibles.
hl.bind("ALT+Return", hl.dsp.exec_cmd("kitty"))
hl.bind("ALT+S", hl.dsp.exec_cmd("spotify"))
hl.bind("SUPER+E", hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER+SHIFT+D", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -theme ~/.config/rofi/style-3.rasi"))
hl.bind("SUPER+W", hl.dsp.exec_cmd("bash /home/v3nom/.config/hypr/scripts/wallrofi.sh"))
hl.bind("ALT+F", hl.dsp.exec_cmd("zen-browser"))

-- ============ GESTIÓN VENTANAS ============
hl.bind("ALT+W", hl.dsp.window.close())
hl.bind("ALT+P", hl.dsp.window.pseudo()) -- reemplaza "layoutmsg, togglepseudotile"
hl.bind("ALT+SPACE", hl.dsp.layout("togglesplit")) -- confirmado, dwindle only
hl.bind("ALT+F11", hl.dsp.window.fullscreen()) -- ⚠️ sin confirmar el mapeo exacto del param "0" (modo). Prueba y si necesitas maximize/fake-fullscreen en vez de full, lo ajustamos.
hl.bind("ALT+R", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))
hl.bind("ALT+SHIFT+R", hl.dsp.exec_cmd("~/.config/hypr/scripts/reload.sh"))

-- ============ WORKSPACES TAB ============
-- ⚠️ Sin confirmar si sigue siendo "+1"/"-1" o requiere el formato "e+1"/"e-1".
hl.bind("ALT+X", hl.dsp.focus({ workspace = "+1" }))
hl.bind("ALT+less", hl.dsp.focus({ workspace = "-1" }))

-- ============ BLUETOOTH / WIFI ============
hl.bind("SUPER+SHIFT+B", hl.dsp.exec_cmd("~/.config/rofi/scripts/bluetooth.sh"))
hl.bind(
	"SUPER+SHIFT+W",
	hl.dsp.exec_cmd("networkmanager_dmenu -dmenu 'rofi -dmenu -i -theme /home/v3nom/.config/rofi/style-3.rasi'")
)

-- ============ FOCUS ============
hl.bind("ALT+l", hl.dsp.focus({ direction = "right" }))
hl.bind("ALT+h", hl.dsp.focus({ direction = "left" }))
hl.bind("ALT+k", hl.dsp.focus({ direction = "up" }))
hl.bind("ALT+j", hl.dsp.focus({ direction = "down" }))

-- ============ RESIZE ============
hl.bind("ALT+SHIFT+l", hl.dsp.window.resize({ x = 30, y = 0 }))
hl.bind("ALT+SHIFT+h", hl.dsp.window.resize({ x = -30, y = 0 }))
hl.bind("ALT+SHIFT+k", hl.dsp.window.resize({ x = 0, y = -30 }))
hl.bind("ALT+SHIFT+j", hl.dsp.window.resize({ x = 0, y = 30 }))

-- ============ SCROLL WORKSPACES ============
hl.bind("ALT+mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT+mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ============ SCREENSHOT ============
hl.bind("Print", hl.dsp.exec_cmd("grim ~/Pictures/screenshot_$(date +%F_%T).png"))
hl.bind("SHIFT+Print", hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%F_%T).png'))

-- ============ OPACIDAD ============
hl.bind(
	"ALT+O",
	hl.dsp.exec_cmd("hyprctl keyword decoration:active_opacity 1.0 && hyprctl keyword decoration:inactive_opacity 1.0")
)
hl.bind(
	"ALT+SHIFT+O",
	hl.dsp.exec_cmd(
		"hyprctl keyword decoration:active_opacity 1.00 && hyprctl keyword decoration:inactive_opacity 0.90"
	)
)

-- ============ LOCK / LOGOUT ============
hl.bind(
	"SUPER+Escape",
	hl.dsp.exec_cmd(
		"wlogout --protocol layer-shell -b 3 --css ~/.config/wlogout/style.css --layout ~/.config/wlogout/layout"
	)
)
hl.bind("SUPER+L", hl.dsp.exec_cmd("hyprlock"))

-- ============ FLOATING ============
hl.bind("ALT+V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("CTRL+TAB", hl.dsp.exec_raw("alterzorder bottom")) -- ⚠️ no encontré equivalente nativo documentado, se queda con shim
-- hl.bind("CTRL+TAB", hl.dsp.exec_raw("alterzorder top"))

-- ============ SCREENSHOT REGIÓN ============
hl.bind("SUPER+SHIFT+S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- ============ VOLUMEN F7/F8/F9 ============
-- ⚠️ Estas SÍ te conviene que sean repeating (para subir/bajar sostenido).
--    Agrego { repeating = true } en las de sube/baja, no en la de mute.
hl.bind("F9", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("F8", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("F7", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- ============ VOLUMEN MULTIMEDIA DELL ============
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- ============ BRILLO F10/F11 ============
hl.bind("F11", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("F10", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-- ============ BRILLO MULTIMEDIA DELL ============
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-- ============ PLAYERCTL ============
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
-- hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"))

-- ============ BINDM (mouse) ============
hl.bind("ALT+mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("ALT+mouse:273", hl.dsp.window.resize(), { mouse = true })
