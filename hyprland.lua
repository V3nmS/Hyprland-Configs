-- =============================================================================
-- HYPRLAND CONFIG - Base funcional para personalización (migrado a Lua)
-- =============================================================================
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypr/lua/?.lua"

hl.config({
	debug = {
		disable_logs = false,
	},
})

-- DSP_DUMP
require("dsp_dump")

-- Monitors + su exec-once/exec asociado
require("monitors")

-- Variables (terminal, fileManager, menu) — hoy inertes, nadie las consume aún
-- local programs = require("programs")

-- Environment + cursor
require("env")

-- Decorations (general + decoration; plugin{} pendiente de resolver aparte)
require("decorations")

-- Animations (curves + leaves)
require("animations")

-- Window rules
require("windowrules")

-- Layouts (dwindle + master)
require("layouts")

-- Misc (ya estaba nativo en Lua)
require("misc")

-- Input (kb_layout, touchpad, gestos, mouse)
require("input")

-- Reparto de workspaces por monitor (antes de binds: binds.lua también
-- escribe workspace_rule, para el layout scrolling, y debe poder pisar encima)
require("workspaces")

-- Binds (bind / binde / bindm, vía el traductor)
require("binds")

-- Autostart (al final, para que si algo de arriba truena no te quedes
-- sin terminal/waybar/mako a medias)
require("autostart")
