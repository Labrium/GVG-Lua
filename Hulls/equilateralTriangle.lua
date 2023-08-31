-- GVG 0.4 Copyright (c) 2023 Labrium.

local tau = 6.28318530717958647692528

local GVG = require("GVG")

return function (name, uniforms)
	local outr = (2/3) * math.sqrt(3)
	local verts = {}
	for i = 1, 3 do
		local a = (i / 3) * tau
		table.insert(verts, {math.sin(a) * outr, math.cos(a) * outr})
	end

	return GVG.generateVertexOffsets(verts), "triangles" -- there's only one, so...
end
