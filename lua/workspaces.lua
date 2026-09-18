-- workspaces.lua
-- Reparto fijo de workspaces por monitor. Decidido 2026-09-18.
--
--   1..4   -> HDMI-A-1  (monitor de trabajo)
--   5..8   -> eDP-1     (panel de la laptop)
--
-- Son 4 por monitor porque ése es el diseño de la waybar. Si lo cambias,
-- cambia también PER_MONITOR en ~/.config/waybar/scripts/gen-config.py:
-- los dos números tienen que ser el mismo o la barra y Hyprland se desfasan.
--
-- POR QUÉ POR NOMBRE Y NO POR CANTIDAD:
-- Waybar sabe generar workspaces "persistentes" dándole un número, pero los
-- numera como (monitorId * cantidad) + i + 1, y el monitorId de Hyprland
-- CAMBIA cada vez que una salida se apaga y se vuelve a prender (se ve como
-- monitorremoved/monitoradded en el socket de eventos). O sea que el reparto
-- se recorría solo al cerrar y abrir la tapa. Amarrado por nombre, no se mueve.
--
-- Si el monitor de una regla no está presente, Hyprland manda ese workspace al
-- que sí existe: con solo la laptop, los 10 caen ahí. Esa es la degradación
-- que queremos y por eso las reglas pueden ser estáticas.

local LAPTOP = "eDP-1"
local EXTERNAL = "HDMI-A-1"

for i = 1, 4 do
	hl.workspace_rule({ workspace = tostring(i), monitor = EXTERNAL })
end

for i = 5, 8 do
	hl.workspace_rule({ workspace = tostring(i), monitor = LAPTOP })
end
