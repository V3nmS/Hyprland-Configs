-- monitors.lua
-- output vacío = todos los monitores (comportamiento equivalente a "monitor=,preferred,auto,1")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- exec-once (una sola vez al iniciar sesión)
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/lid.sh --daemon")
end)

-- exec plano (se repetía en cada reload, no solo al inicio):
-- como este módulo se vuelve a ejecutar cada vez que Hyprland recarga config
-- (por el require), basta con dejarlo top-level, fuera del hl.on("hyprland.start")
hl.exec_cmd("sleep 0.5 && ~/.config/hypr/scripts/lid.sh --apply")
