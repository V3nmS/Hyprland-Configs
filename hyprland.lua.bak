-- =============================================================================
-- HYPRLAND CONFIG - Base funcional para personalización (migrado a Lua)
-- =============================================================================
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypr/lua/?.lua"

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

-- Binds (bind / binde / bindm, vía el traductor)
local bind_loader = require("bind_loader")
bind_loader.apply_binds(require("binds"))

-- Autostart (al final, para que si algo de arriba truena no te quedes
-- sin terminal/waybar/mako a medias)
require("autostart")
