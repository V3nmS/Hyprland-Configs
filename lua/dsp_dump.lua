-- dsp_dump.lua — temporal, solo para introspección
local function dump(t, prefix)
	for k, v in pairs(t) do
		local path = prefix .. "." .. tostring(k)
		if type(v) == "table" then
			dump(v, path)
		else
			print(path .. "  [" .. type(v) .. "]")
		end
	end
end

dump(hl.dsp, "hl.dsp")
