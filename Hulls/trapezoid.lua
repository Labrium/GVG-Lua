-- GVG 0.4 Copyright (c) 2023 Labrium.

return function (name, uniforms)
	return {
		{1, 1, 0, 0, 1, 1},
		{1, -0.9, 0, 0, 1, -1},
		{0.9, -1, 0, 0, -1, -1},
		{-0.9, -1, 0, 0, -1, -1},
		{-1, -0.9, 0, 0, 1, -1},
		{-1, 1, 0, 0, 1, 1}
	}, "fan"
end
