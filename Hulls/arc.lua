-- GVG 0.4 Copyright (c) 2023 Labrium.

local tau = 6.28318530717958647692528

local GVG = require("GVG")

local function normalize(x, y)
	local l = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
	return x / l, y / l
end

return function (name, uniforms)
	local n = 8

	local outr = 1 / math.cos(tau / (n * 2))
	local inr = 1
	local verts = {}
	for i = 0, n do
		local a = ((i / n) * tau)
		local op = {-math.sin(a) * outr, -math.cos(a) * outr}
		local ip = {-math.sin(a) * inr, -math.cos(a) * inr}
		table.insert(verts, op)
		table.insert(verts, ip)
	end

	GVG.generateVertexOffsets(verts, true)

	for i = 1, #verts do
		if i % 2 == 0 then
			local ox, oy = normalize(verts[i][1], verts[i][2])
			verts[i][5] = -ox
			verts[i][6] = -oy
		end
	end

	return verts, "strip"
end
