-- GVG 0.4 Copyright (c) 2023 Labrium.

local tau = 6.28318530717958647692528

local GVG = require("GVG")

return function (name, uniforms)
	local v = {
		{-0.2, 1, 0, 0, -1, 0},
		{0.2, 1, 0, 0, 1, 0},
		{1, -0.8, 0, 0, -2, 0},
		{0.8, -1, 0, 0, 2, 0},
		{-0.8, -1, 0, 0, -3, 0},
		{-1, -0.8, 0, 0, 3, 0}
	}
	return v, "fan"
end
