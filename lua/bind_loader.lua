-- bind_loader.lua
-- Traduce las tablas de binds.lua (formato hyprlang "MODS, KEY, DISPATCHER, PARAMS")
-- a llamadas reales de hl.bind(). No modifica binds.lua.
--
-- NOTA IMPORTANTE: hl.dsp.exec_raw NO es un passthrough genérico de dispatchers.
-- Ejecuta un comando sin shell. Por eso hay que mapear dispatcher por dispatcher.

local M = {}

-- Ponlo en false cuando ya no quieras ruido en el log
local DEBUG = true

local function log(msg)
	if DEBUG then
		print("[bind_loader] " .. msg)
	end
end

-- ---------------------------------------------------------------------------
-- Parsing
-- ---------------------------------------------------------------------------

local function split_bind(str, max_splits)
	local parts = {}
	local pos = 1
	local count = 0

	while count < max_splits do
		local comma = str:find(",", pos, true)
		if not comma then
			break
		end

		parts[#parts + 1] = str:sub(pos, comma - 1)
		pos = comma + 1
		count = count + 1
	end

	parts[#parts + 1] = str:sub(pos)

	for i = 1, #parts do
		parts[i] = parts[i]:match("^%s*(.-)%s*$")
	end

	return parts
end

local function build_keys(mods, key)
	mods = mods or ""
	key = key or ""

	if mods == "" then
		return key
	end

	local out = {}

	for m in mods:gmatch("%S+") do
		out[#out + 1] = m
	end

	out[#out + 1] = key

	return table.concat(out, " + ")
end

-- ---------------------------------------------------------------------------
-- Mapeo de dispatchers
-- ---------------------------------------------------------------------------

-- CONFIRMADOS contra la wiki / example/hyprland.lua oficial
local DISPATCHERS = {
	exec = function(params)
		return hl.dsp.exec_cmd(params)
	end,

	killactive = function()
		return hl.dsp.window.close()
	end,

	togglefloating = function()
		return hl.dsp.window.float({ action = "toggle" })
	end,

	-- Estos dos son los de bindm (mouse)
	movewindow = function()
		return hl.dsp.window.drag()
	end,

	resizewindow = function()
		return hl.dsp.window.resize()
	end,
}

-- POR CONFIRMAR: descomenta conforme verifiques la firma real en
-- /usr/share/hypr/stubs/hl.meta.lua. Cada uno es una apuesta razonada,
-- NO está verificado. Pruébalos de uno en uno con hyprctl reload.
--
-- DISPATCHERS.movefocus = function(params)
-- 	return hl.dsp.window.focus({ direction = params })
-- end
--
-- DISPATCHERS.resizeactive = function(params)
-- 	-- params llega como "30 0" / "-30 0"
-- 	return hl.dsp.window.resize(params)
-- end
--
-- DISPATCHERS.workspace = function(params)
-- 	-- params: "+1", "-1", "e+1", "e-1"
-- 	return hl.dsp.workspace.change(params)
-- end
--
-- DISPATCHERS.fullscreen = function(params)
-- 	-- params: "0"
-- 	return hl.dsp.window.fullscreen(tonumber(params))
-- end
--
-- DISPATCHERS.layoutmsg = function(params)
-- 	-- params: "togglesplit", "togglepseudotile"
-- 	return hl.dsp.layout(params)
-- end
--
-- DISPATCHERS.alterzorder = function(params)
-- 	-- params: "bottom" / "top"
-- 	-- Ojo: en el namespace solo vi bring_to_top(), puede que "bottom" no exista.
-- 	return hl.dsp.window.bring_to_top()
-- end

local function build_dispatcher(dispatcher, params)
	dispatcher = tostring(dispatcher or "")
	params = tostring(params or "")

	local builder = DISPATCHERS[dispatcher]

	if builder then
		local ok, result = pcall(builder, params)

		if not ok then
			log("ERROR construyendo '" .. dispatcher .. "': " .. tostring(result))
			return nil
		end

		return result
	end

	-- Antes esto se iba a exec_raw y fallaba en silencio. Ahora deja rastro.
	log("SIN MAPEAR -> " .. dispatcher .. " (params: '" .. params .. "')")
	return nil
end

-- ---------------------------------------------------------------------------
-- Aplicación
-- ---------------------------------------------------------------------------

local function apply(tbl, opts, label)
	opts = opts or {}

	local ok_count = 0
	local skip_count = 0

	for _, entry in ipairs(tbl or {}) do
		local p = split_bind(entry, 3)
		local keys = build_keys(p[1], p[2])
		local dsp = build_dispatcher(p[3], p[4])

		if dsp then
			local ok, err = pcall(hl.bind, keys, dsp, opts)

			if ok then
				ok_count = ok_count + 1
			else
				skip_count = skip_count + 1
				log("FALLO hl.bind en '" .. keys .. "': " .. tostring(err))
			end
		else
			skip_count = skip_count + 1
		end
	end

	log(label .. ": " .. ok_count .. " ok, " .. skip_count .. " omitidos")
end

function M.apply_binds(cfg)
	apply(cfg.bind, nil, "bind")
	apply(cfg.binde, { repeating = true }, "binde")
	apply(cfg.bindm, { mouse = true }, "bindm")
end

return M
