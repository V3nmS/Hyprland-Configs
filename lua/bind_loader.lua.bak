-- bind_loader.lua
-- Traductor: toma las tablas de binds.lua (formato hyprlang "MODS, KEY, DISPATCHER, PARAMS")
-- y las convierte en llamadas reales a hl.bind(). No modifica binds.lua.

local M = {}

-- Separa "MODS, KEY, DISPATCHER, PARAMS" en máximo `max_splits` partes,
-- dejando el resto (params) intacto aunque tenga espacios.
local function split_bind(str, max_splits)
	local parts, pos, count = {}, 1, 0
	while count < max_splits do
		local comma_pos = str:find(",", pos, true)
		if not comma_pos then
			break
		end
		table.insert(parts, str:sub(pos, comma_pos - 1))
		pos = comma_pos + 1
		count = count + 1
	end
	table.insert(parts, str:sub(pos)) -- lo que sobra (params)
	for i, v in ipairs(parts) do
		parts[i] = v:match("^%s*(.-)%s*$") -- trim
	end
	return parts
end

-- "SUPER SHIFT" + "D" -> "SUPER + SHIFT + D"
local function build_keys(mods, key)
	if mods == "" then
		return key
	end
	local out = {}
	for m in mods:gmatch("%S+") do
		table.insert(out, m)
	end
	table.insert(out, key)
	return table.concat(out, " + ")
end

-- exec usa hl.dsp.exec_cmd (pasa por sh -c, igual que el "exec" viejo de hyprlang).
-- Cualquier otro dispatcher (movefocus, resizeactive, layoutmsg, workspace, etc.)
-- usa hl.dsp.exec_raw como passthrough genérico del dispatcher crudo.
local function build_dispatcher(dispatcher, params)
	if dispatcher == "exec" then
		return hl.dsp.exec_cmd(params)
	elseif params ~= "" then
		return hl.dsp.exec_raw(dispatcher .. " " .. params)
	else
		return hl.dsp.exec_raw(dispatcher)
	end
end

-- Aplica las tres tablas (bind, binde, bindm) de un cfg tipo binds.lua
function M.apply_binds(cfg)
	for _, entry in ipairs(cfg.bind or {}) do
		local p = split_bind(entry, 3)
		hl.bind(build_keys(p[1], p[2]), build_dispatcher(p[3], p[4]))
	end

	for _, entry in ipairs(cfg.binde or {}) do
		local p = split_bind(entry, 3)
		hl.bind(build_keys(p[1], p[2]), build_dispatcher(p[3], p[4]), { repeating = true })
	end

	for _, entry in ipairs(cfg.bindm or {}) do
		local p = split_bind(entry, 3)
		hl.bind(build_keys(p[1], p[2]), build_dispatcher(p[3], p[4]), { mouse = true })
	end
end

return M
