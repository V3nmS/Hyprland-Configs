-- bind_loader.lua

local M = {}

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

local function build_dispatcher(dispatcher, params)
	dispatcher = tostring(dispatcher or "")
	params = tostring(params or "")

	if dispatcher == "exec" then
		return hl.dsp.exec_cmd(params)
	end

	if params == "" then
		return hl.dsp.exec_raw(dispatcher)
	end

	return hl.dsp.exec_raw(("%s %s"):format(dispatcher, params))
end

local function apply(tbl, opts)
	opts = opts or {}

	for _, entry in ipairs(tbl or {}) do
		local p = split_bind(entry, 3)

		print(build_keys(p[1], p[2]))
		print(p[3], p[4])

		hl.bind(build_keys(p[1], p[2]), build_dispatcher(p[3], p[4]), opts)
	end
end

function M.apply_binds(cfg)
	apply(cfg.bind)
	apply(cfg.binde, { repeating = true })
	apply(cfg.bindm, { mouse = true })
end

return M
