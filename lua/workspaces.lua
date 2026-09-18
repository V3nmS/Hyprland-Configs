-- workspaces.lua
-- Reparto fijo de workspaces por monitor. Decidido 2026-09-18.
--
--   1..5   -> HDMI-A-1  (monitor de trabajo)
--   6..10  -> eDP-1     (panel de la laptop)
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

for i = 1, 5 do
	hl.workspace_rule({ workspace = tostring(i), monitor = EXTERNAL })
end

for i = 6, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = LAPTOP })
end
