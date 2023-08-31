-- GVG 0.4 Copyright (c) 2023 Labrium.

local GVG = require("GVG")

return function (name, uniforms)
	return GVG.generateVertexOffsets({{1, 1}, {1, -1}, {-1, -1}, {-1, 1}}), "fan"
end
