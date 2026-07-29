-- bind_loader.lua
-- Traduce las tablas de binds.lua (formato hyprlang "MODS, KEY, DISPATCHER, PARAMS")
-- a llamadas reales de hl.bind(). No modifica binds.lua.
--
-- Firmas confirmadas contra los errores de Hyprland 0.56.1:
--   hl.focus               -> { direction = "left"|"right"|"up"|"down" }
--   hl.workspace.change_id -> { workspace = ... }  (ojo: ver nota abajo)
--   hl.window.resize       -> sin args, o { x, y, relative?, window? }
--   hl.window.alter_zorder -> { mode = ... }
--
-- NOTA PENDIENTE: no está claro que change_id sea el dispatcher para *cambiar*
-- de workspace (el nombre y su firma sugieren renumerar). Si ALT+X carga ok
-- pero no cambia de workspace, hay que buscar otro dispatcher.

local M = {}

-- VERBOSE = true loguea las 75 entradas una por una. Útil para depurar,
-- ponlo en false cuando todo jale.
local DEBUG = true
local VERBOSE = true

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
-- Helpers
-- ---------------------------------------------------------------------------

local DIRECTIONS = {
	l = "left",
	r = "right",
	u = "up",
	d = "down",
	left = "left",
	right = "right",
	up = "up",
	down = "down",
}

local function parse_xy(params)
	local x, y = params:match("^(-?%d+)%s+(-?%d+)$")
	return tonumber(x), tonumber(y)
end

-- ---------------------------------------------------------------------------
-- Mapeo hyprlang -> hl.dsp.*
-- ---------------------------------------------------------------------------

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

	movewindow = function()
		return hl.dsp.window.drag()
	end,

	resizewindow = function()
		return hl.dsp.window.resize()
	end,

	movefocus = function(params)
		local dir = DIRECTIONS[params]

		if not dir then
			error("dirección desconocida: '" .. params .. "'")
		end

		return hl.dsp.focus({ direction = dir })
	end,

	resizeactive = function(params)
		local x, y = parse_xy(params)

		if not x then
			error("no pude parsear x/y de: '" .. params .. "'")
		end

		return hl.dsp.window.resize({ x = x, y = y, relative = true })
	end,

	workspace = function(params)
		return hl.dsp.focus({ workspace = params })
	end,

	fullscreen = function(params)
		return hl.dsp.window.fullscreen(tonumber(params) or 0)
	end,

	layoutmsg = function(params)
		return hl.dsp.layout(params)
	end,

	alterzorder = function(params)
		return hl.dsp.window.alter_zorder({ mode = params })
	end,
}

local function build_dispatcher(dispatcher, params)
	dispatcher = tostring(dispatcher or "")
	params = tostring(params or "")

	local builder = DISPATCHERS[dispatcher]

	if not builder then
		log("SIN MAPEAR -> " .. dispatcher .. " (params: '" .. params .. "')")
		return nil
	end

	local ok, result = pcall(builder, params)

	if not ok then
		log("ERROR en '" .. dispatcher .. "': " .. tostring(result))
		return nil
	end

	-- Caso silencioso: no truena pero tampoco devuelve dispatcher
	if result == nil then
		log("NIL devuelto por '" .. dispatcher .. "' (params: '" .. params .. "')")
	end

	return result
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

		if VERBOSE then
			log(label .. " | " .. (dsp and "OK  " or "SKIP") .. " | " .. entry)
		end

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
			log("OMITIDO [" .. label .. "] " .. entry)
		end
	end

	log(label .. ": " .. ok_count .. " ok, " .. skip_count .. " omitidos")
end

function M.apply_binds(cfg)
	apply(cfg.bind, nil, "bind")
	apply(cfg.binde, { repeating = true }, "binde")
	apply(cfg.bindm, { mouse = true }, "bindm")
end

-- Workspaces por monitor, nativo (reemplaza a hyprsome)
-- Monitor 0 -> workspaces 1-9, monitor 1 -> 11-19, etc.
function M.apply_workspace_binds()
	local function ws_id(n)
		local mon = hl.get_active_monitor()
		return n + 10 * mon.id
	end

	for i = 1, 9 do
		-- Envueltos en function() para que ws_id se evalúe AL APRETAR,
		-- no al cargar el config (si no, el monitor queda congelado)
		hl.bind("ALT + " .. i, function()
			hl.dispatch(hl.dsp.focus({ workspace = ws_id(i) }))
		end)

		hl.bind("ALT + SHIFT + " .. i, function()
			hl.dispatch(hl.dsp.window.move({ workspace = ws_id(i), silent = true }))
		end)
	end
end

return M
