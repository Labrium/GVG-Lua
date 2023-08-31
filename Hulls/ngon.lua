-- GVG 0.4 Copyright (c) 2023 Labrium.

local tau = 6.28318530717958647692528

local GVG = require("GVG")

local nameToSideCount = {
	pentagon = 5,
	hexagon = 6,
	octagon = 8,
	circle = 8
}

return function (name, uniforms)
	local n = 6

	if uniforms["points"] then
		n = uniforms["points"][1]
	elseif nameToSideCount[name] then
		n = nameToSideCount[name]
	end

	local outr = name == "nstar" and 1 or 1 / math.cos(tau / (n * 2))

	local verts = {}
	for i = 1, n do
		local a = (((n - i) - (name == "nstar" and 0 or 0.5)) / n) * tau
		table.insert(verts, {math.sin(a) * outr, -math.cos(a) * outr})
	end

	return GVG.generateVertexOffsets(verts), "fan"
end
