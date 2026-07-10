package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypr/lua/?.lua"

local home = os.getenv("HOME")
local lua_dir = home .. "/.config/hypr/lua"
local config_dir = home .. "/.config/hypr/generated"

os.execute('mkdir -p "' .. config_dir .. '"')

local modules = {}

local handle = io.popen('find "' .. lua_dir .. '" -maxdepth 1 -name "*.lua" | sort')

for file in handle:lines() do
	local name = file:match("([^/]+)%.lua$")

	if name ~= "generate" then
		table.insert(modules, name)
	end
end

handle:close()

local function format_value(value)
	if type(value) == "boolean" then
		return value and "1" or "0"
	end

	return tostring(value)
end

local function serialize(tbl, indent)
	indent = indent or ""
	local out = ""

	for key, value in pairs(tbl) do
		if type(value) == "table" then
			local isArray = #value > 0

			if isArray then
				for _, item in ipairs(value) do
					out = out .. string.format("%s%s = %s\n", indent, key, format_value(item))
				end
			else
				out = out .. string.format("%s%s {\n", indent, key)
				out = out .. serialize(value, indent .. "    ")
				out = out .. string.format("%s}\n", indent)
			end
		else
			out = out .. string.format("%s%s = %s\n", indent, key, format_value(value))
		end
	end

	return out
end

os.execute('rm -f "' .. config_dir .. '"/*.conf')

for _, mod in ipairs(modules) do
	local ok, data = pcall(require, mod)

	if not ok then
		print("Error loading module: " .. mod)
		print(data)
	else
		local output = ""

		if type(data) == "string" then
			output = data
		elseif type(data) == "table" then
			output = serialize(data)
		else
			error("Invalid return type in " .. mod)
		end

		local filepath = config_dir .. "/" .. mod .. ".conf"
		local file, err = io.open(filepath, "w")

		if not file then
			error(err)
		end

		file:write(output)
		file:close()

		print("Generated: " .. filepath)
	end
end
