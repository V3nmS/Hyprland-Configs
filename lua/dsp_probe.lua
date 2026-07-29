-- dsp_probe.lua — temporal, solo para probar formas de argumento
local candidates = {
	{
		'focus("l")',
		function()
			return hl.dsp.focus("l")
		end,
	},
	{
		'focus({direction="l"})',
		function()
			return hl.dsp.focus({ direction = "l" })
		end,
	},
	{
		'workspace.change_id("+1")',
		function()
			return hl.dsp.workspace.change_id("+1")
		end,
	},
	{
		'workspace.change_id({id="+1"})',
		function()
			return hl.dsp.workspace.change_id({ id = "+1" })
		end,
	},
	{
		'window.resize("30 0")',
		function()
			return hl.dsp.window.resize("30 0")
		end,
	},
	{
		"window.resize({x=30,y=0})",
		function()
			return hl.dsp.window.resize({ x = 30, y = 0 })
		end,
	},
	{
		"window.fullscreen(0)",
		function()
			return hl.dsp.window.fullscreen(0)
		end,
	},
	{
		"window.fullscreen({mode=0})",
		function()
			return hl.dsp.window.fullscreen({ mode = 0 })
		end,
	},
	{
		'layout("togglesplit")',
		function()
			return hl.dsp.layout("togglesplit")
		end,
	},
	{
		'window.alter_zorder("bottom")',
		function()
			return hl.dsp.window.alter_zorder("bottom")
		end,
	},
	{
		'window.alter_zorder({z="bottom"})',
		function()
			return hl.dsp.window.alter_zorder({ z = "bottom" })
		end,
	},
	-- control: esta sabemos que es correcta
	{
		'window.float({action="toggle"})',
		function()
			return hl.dsp.window.float({ action = "toggle" })
		end,
	},
}

for _, c in ipairs(candidates) do
	local ok, res = pcall(c[2])
	print("[probe] " .. c[1] .. " -> " .. (ok and ("OK (" .. type(res) .. ")") or ("ERR: " .. tostring(res))))
end
