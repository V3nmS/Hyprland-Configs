-- probe2.lua — temporal
local tries = {
	{
		"focus({})",
		function()
			return hl.dsp.focus({})
		end,
	},
	{
		"workspace.move({})",
		function()
			return hl.dsp.workspace.move({})
		end,
	},
	{
		"workspace.change_id({})",
		function()
			return hl.dsp.workspace.change_id({})
		end,
	},
}

for _, t in ipairs(tries) do
	local ok, res = pcall(t[2])
	print("[probe2] " .. t[1] .. " -> " .. (ok and ("ret=" .. tostring(res)) or ("ERR: " .. tostring(res))))
end

local ok, res = pcall(function()
	return hl.dsp.window.move({})
end)

local f = io.open("/tmp/probe_window_move.txt", "w")
f:write("[probe] window.move({}) -> " .. (ok and tostring(res) or ("ERR: " .. tostring(res))) .. "\n")
f:close()
