-- GVG 0.4 Copyright (c) 2023 Labrium.

local tau = 6.28318530717958647692528

local DEBUG = false

local class = require("30log")
local uuid = require("uuid")
local json = require("dkjson")

local lg = love.graphics
local lf = love.filesystem

local errorPrefix = "GVG Error: "
local warningPrefix = "GVG Warning: "


-- UTILITY FUNCTIONS
local function capitalize(str)
	return (str:gsub("^%l", string.upper))
end

local function trim(s) -- trim12: http://lua-users.org/wiki/StringTrim
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

local function copy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
	return res --setmetatable(res, getmetatable(obj))
end

--[[local function ArrayRemove(t, fnKeep) -- https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
	local j, n = 1, #t;
	for i=1,n do
		if (fnKeep(t, i, j)) then
			-- Move i's kept value to j's position, if it's not already there.
			if (i ~= j) then
				t[j] = t[i];
				t[i] = nil;
			end
			j = j + 1; -- Increment position of where we'll place the next kept value.
		else
			t[i] = nil;
		end
	end
	return t;
end]]

local function removeValue(t, v)
	local j, n = 1, #t
	for i = 1, n do
		if t[i] ~= v then
			if i ~= j then
				t[j] = t[i]
				t[i] = nil
			end
			j = j + 1
		else
			t[i] = nil
		end
	end
	return t
end

local function filterInPlace(arr, func)
	local newIndex = 1
	local sizeOrig = #arr
	for oldIndex, v in ipairs(arr) do
		if func(v, oldIndex) then
			arr[newIndex] = v
			newIndex = newIndex + 1
		end
	end
	for i = newIndex, sizeOrig do arr[i] = nil end
end

local function rotate(x, y, a)
	return x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
end

local function dot(x1, y1, x2, y2)
	return x1 * x2 + y1 * y2
end

local function normalize(x, y)
	local l = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
	return x / l, y / l
end

local function pow2(n)
	return n * n
end

local function clamp(v, l, h)
	return math.min(math.max(v, l), h)
end




-- GVG
local GVG = {
	version = "GVG 0.4 Beta",
	vertexFormat = {
		{"VertexPosition", "float", 2},
		{"VertexTexCoord", "float", 2},
		{"VertexOffset", "float", 2}
	},
	shapeTypes = {},
	hullTypes = {},
	elements = {},
	ids = {},
	baseF = "",
	baseV = ""
}

function GVG.init(fs, vs)
	pcall(function ()
		local tmps = lf.read(fs)
		assert(tmps)
		fs = tmps
	end)
	pcall(function ()
		local tmps = lf.read(vs)
		assert(tmps)
		vs = tmps
	end)
	GVG.baseF = fs
	GVG.baseV = vs
end

function GVG.registerHullType(name, func)
	GVG.hullTypes[name:lower()] = func
	--print("Registered hullType " .. name:lower())
end

function GVG.registerShapeType(name, shaderCode)
	local shapeType = {
		name = name:lower(),
		codeF = "",
		codeV = "",
		uniforms = {},
		uniformCode = "",
		parameterCode = "",
		hull = ""
	}

	local header, codeBody = shaderCode:match("^([^\n]*)\n(.*)")

	-- header parsing
	shapeType.hull, header = header:match("//(.*)!(.*)")
	shapeType.hull = shapeType.hull:lower()

	-- uniform parsing
	for u in header:gmatch("[^|]+") do
		local utype, uname, udefault = u:match("(.*):(.*):(.*)")
		shapeType.uniformCode = shapeType.uniformCode .. "uniform " .. utype .. " " .. uname .. ";\n"
		shapeType.parameterCode = shapeType.parameterCode .. ", " .. uname
		shapeType.uniforms[uname] = json.decode("[" .. udefault .. "]") -- extra brackets required for array parameters
	end

	-- code parsing
	codeBody = codeBody:gsub("/%*NAME%*/", capitalize(shapeType.name))
	shapeType.codeF, shapeType.codeV = codeBody:match("(.*)//SEPARATOR(.*)")

	shapeType.codeF = trim(shapeType.codeF)
	shapeType.codeV = trim(shapeType.codeV)

	GVG.shapeTypes[shapeType.name] = shapeType

	--print("Registered shapeType " .. shapeType.name)
end

function GVG.loadShapesFromDirectory(dname)
	local files = lf.getDirectoryItems(dname)
	filterInPlace(files, function (o, k, i) return o:sub(1, 1) ~= "." end)
	for f = 1, #files do
		--print(files[f])
		GVG.registerShapeType(files[f]:gsub("%.glsl", ""), lf.read(dname .. "/" .. files[f]))
	end
end

function GVG.loadHullsFromDirectory(dname)
	local files = lf.getDirectoryItems(dname)
	filterInPlace(files, function (o, k, i) return o:sub(1, 1) ~= "." end)
	for f = 1, #files do
		GVG.registerHullType(files[f]:gsub("%.lua", ""), require(dname .. "." .. files[f]:gsub("%.lua", "")))
	end
end

function GVG.generateVertexOffsets(v, skip)
	for i = 1, #v do
		local ni = i + (skip and 2 or 1)
		if ni > #v then ni = skip and (i % 2 == 0 and 4 or 3) or 1 end

		local oi = i - (skip and 2 or 1)
		if oi < 1 then oi = skip and (#v - (i % 2 == 0 and 2 or 3)) or #v end

		--print(oi, i, ni, #v)

		abx, aby = normalize(v[i][1] - v[oi][1], v[i][2] - v[oi][2])
		bcx, bcy = normalize(v[ni][1] - v[i][1], v[ni][2] - v[i][2])

		tx, ty = normalize(abx + bcx, aby + bcy)
		mx, my = -ty, tx

		nax, nay = -aby, abx
		d = 1 / dot(mx, my, nax, nay)

		if skip and i % 2 == 0 then d = -d end

		v[i][5] = mx * d
		v[i][6] = my * d
	end
	return v
end

function GVG.screenToWorld(x, y)
	local w, h = love.graphics.getDimensions()
	return x - (w / 2), -y + (h / 2)
end

function GVG.worldToScreen(x, y)
	local w, h = love.graphics.getDimensions()
	return x + (w / 2), -y + (h / 2)
end

function GVG.getElementByUUID(uuid)
	return GVG.elements[uuid]
end

function GVG.getElementById(id)
	return GVG.elements[GVG.ids[id]]
end

local function newId(id, uid)
	while GVG.ids[id] ~= nil do
		if id:match(" (%d+)$") then
			id = id:gsub(" (%d+)$", function (n)
				return " " .. (n + 1)
			end)
		else
			id = id .. " 2"
		end
	end
	print("Added new Id '" .. id .. "' to '" .. uid .. "'.")
	GVG.ids[id] = uid
	return id
end








-- SHAPE
GVG.Shape = class("GVGShape", {
	x = 0,
	y = 0,
	r = 0,
	s = 1,
	color = {1, 1, 1, 1},
	line = false,
	stroke = 0,
	offset = 0,
	uniforms = {},
	shader = nil,
	mesh = nil,
	type = "",
	uuid = "",
	id = nil,
	visible = true,
	uploadedUniforms = {},
	parents = {},
	userData = {}
})

function GVG.Shape:init(type, x, y, r, s, color, line, stroke, offset, uniforms, visible, id)
	assert(type, errorPrefix .. "Shape type parameter is required.")
	self.type = type:lower()
	assert(GVG.shapeTypes[self.type], errorPrefix .. "Unrecognized shape type '" .. type .. "'. Make sure to register shape types with 'GVG.registerShapeType()' before using them.")
	self.x = x ~= nil and x or self.x
	self.y = y ~= nil and y or self.y
	self.r = r ~= nil and r or self.r
	self.s = s ~= nil and s or self.s
	self.color = color or self.color
	self.line = line or self.line -- it's okay to not check only for nil because line defaults to false

	self.uniforms = uniforms or copy(GVG.shapeTypes[self.type].uniforms)
	self.visible = visible ~= nil and visible or self.visible -- here visible defaults to true
	self.uuid = uuid()
	self.id = id and newId(id, self.uuid)
	GVG.elements[self.uuid] = self
end

function GVG.Shape:removeFromParent(p)
	local pid = p
	if type(pid) ~= "string" then
		pid = p.uuid
	end
	removeValue(GVG.elements[p].children, self.uuid)
end

function GVG.Shape:removeFromParents()
	if #self.parents > 0 then
		for p = 1, #self.parents do
			self:removeFromParent(self.parents[p])
		end
		self.parents = {}
	else
		print(warningPrefix .. "Cannot remove shape '" .. self.uuid .. "' (" .. self.type .. ") from nil parent.")
	end
end

function GVG.Shape:delete()
	self:removeFromParents()
	GVG.elements[self.uuid] = nil
	GVG.ids[self.id] = nil
	if self.shader then self.shader:release() end
	if self.mesh then self.mesh:release() end
end

function GVG.Shape:compileShader(overrideBaseF, overrideBaseV)
	pcall(function ()
		local tmps = lf.read(overrideBaseF)
		assert(tmps)
		overrideBaseF = tmps
	end)
	pcall(function ()
		local tmps = lf.read(overrideBaseV)
		assert(tmps)
		overrideBaseV = tmps
	end)
	local baseF = overrideBaseF or GVG.baseF
	local baseV = overrideBaseV or GVG.baseV

	local finalF = baseF:gsub("/%*NAME%*/", capitalize(self.type))
		:gsub("/%*UNIFORMS%*/", GVG.shapeTypes[self.type].uniformCode)
		:gsub("/%*PARAMETERS%*/", GVG.shapeTypes[self.type].parameterCode)
		:gsub("/%*FUNCTION%*/", GVG.shapeTypes[self.type].codeF)
	local finalV = baseV:gsub("/%*NAME%*/", capitalize(self.type))
		:gsub("/%*UNIFORMS%*/", GVG.shapeTypes[self.type].uniformCode)
		:gsub("/%*PARAMETERS%*/", GVG.shapeTypes[self.type].parameterCode)
		:gsub("/%*FUNCTION%*/", GVG.shapeTypes[self.type].codeV)

	self.shader = lg.newShader(finalF, finalV)
end

function GVG.Shape:createMesh(usageMode, overrideFunc)
	local mFunc
	if overrideFunc then
		mFunc = overrideFunc
	else
		assert(GVG.hullTypes[GVG.shapeTypes[self.type].hull], errorPrefix .. "Unrecognized hull type '" .. GVG.shapeTypes[self.type].hull .. "'. Make sure to register hull types with 'GVG.registerHullType()' before using them.")
		mFunc = GVG.hullTypes[GVG.shapeTypes[self.type].hull]
	end

	local vertices, mode = mFunc(self.type, self.uniforms)
	local vertexMap
	if type(mode) == "table" then
		vertexMap = mode
		mode = "triangles"
	end
	self.mesh = lg.newMesh(GVG.vertexFormat, vertices, mode, usageMode or "dynamic")
	if vertexMap then
		self.mesh:setVertexMap(vertexMap)
	end
end

function GVG.Shape:compareUniforms(name, value)
	local fd = false

	if not self.uploadedUniforms[name] then return true end

	for i, _ in ipairs(value) do
		if type(value[i]) == "table" then
			for j, _ in ipairs(value[i]) do
				if self.uploadedUniforms[name][i][j] ~= value[i][j] then
					fd = true
				end
			end
		elseif self.uploadedUniforms[name][i] ~= value[i] then
			fd = true
		end
	end

	return fd
end

function GVG.Shape:setUniformDelta(name, value)
	if self:compareUniforms(name, value) then
		self.uniforms[name] = value
		return true
	end
end

function GVG.Shape:draw(x, y, r, s, color, line, stroke, offset, uniforms, visible)
	if not (visible or self.visible) then return end

	--assert(self.mesh, errorPrefix .. "Can't draw nonexistent mesh for shape '" .. self.uuid .. "' (" .. self.type .. "). Make sure to run 'shape:createMesh()' before drawing.")
	--assert(self.shader, errorPrefix .. "Can't use uncompiled shader for shape '" .. self.uuid .. "' (" .. self.type .. "). Make sure to run 'shape:compileShader()' before drawing.")

	if not self.mesh then
		print(warningPrefix .. "Mesh for shape '" .. self.uuid .. "' (" .. self.type .. ") has not been created. Creating now.")
		self:createMesh()
	end

	if not self.shader then
		print(warningPrefix .. "Shader for shape '" .. self.uuid .. "' (" .. self.type .. ") has not been compiled. Compiling now.")
		self:compileShader()
	end

	local cpos = {x ~= nil and x or self.x, y ~= nil and y or self.y}
	local crot = r ~= nil and r or self.r
	local cscl = s ~= nil and s or self.s
	local ccolor = color or self.color
	local cline = line or self.line
	local cstroke = stroke ~= nil and stroke or self.stroke
	local coffset = offset ~= nil and offset or self.offset

	--[[local fv = ((cline and 0 or coffset) * cscl) + cstroke
	if cline and fv < 1 then
		print(fv)
		cstroke = 1 - clamp(fv, 0, 1)
		ccolor = {ccolor[1], ccolor[2], ccolor[3], ccolor[4] * pow2(clamp(fv, 0, 1))}
	end]]

	if not self.uploadedUniforms["pos"] or (self.uploadedUniforms["pos"][1] ~= cpos[1] or self.uploadedUniforms["pos"][2] ~= cpos[2]) then
		self.shader:send("pos", cpos)
		self.uploadedUniforms["pos"] = copy(cpos)
	end
	if not self.uploadedUniforms["rot"] or self.uploadedUniforms["rot"] ~= crot then
		self.shader:send("rot", crot)
		self.uploadedUniforms["rot"] = copy(crot)
	end
	if not self.uploadedUniforms["scl"] or self.uploadedUniforms["scl"] ~= cscl then
		self.shader:send("scl", cscl)
		self.uploadedUniforms["scl"] = copy(cscl)
	end
	if not self.uploadedUniforms["line"] or self.uploadedUniforms["line"] ~= cline then
		self.shader:send("line", cline)
		self.uploadedUniforms["line"] = copy(cline)
	end
	if not self.uploadedUniforms["stroke"] or self.uploadedUniforms["stroke"] ~= cstroke then
		self.shader:send("stroke", cstroke)
		self.uploadedUniforms["stroke"] = copy(cstroke)
	end
	if not self.uploadedUniforms["offset"] or self.uploadedUniforms["offset"] ~= coffset then
		self.shader:send("offset", coffset)
		self.uploadedUniforms["offset"] = copy(coffset)
	end
	local takenUniforms = {}
	if uniforms then
		for n, v in pairs(uniforms) do
			if self:compareUniforms(n, v) then
				self.shader:send(n, unpack(v))
				self.uploadedUniforms[n] = copy(v)
			end
			takenUniforms[n] = true
		end
	end
	for n, v in pairs(self.uniforms) do
		if (not takenUniforms[n]) and self:compareUniforms(n, v) then
			self.shader:send(n, unpack(v))
			self.uploadedUniforms[n] = copy(v)
		end
	end

	local osh = lg.getShader()
	local oclr = {lg.getColor()}
	lg.setShader(self.shader)
	lg.setColor(ccolor)

	lg.draw(self.mesh)

	lg.setShader(osh)
	lg.setColor(oclr)
end













-- ALIAS
GVG.Alias = class("GVGAlias", {
	x = 0,
	y = 0,
	r = 0,
	s = 1,
	visible = true,
	uuid = "",
	id = nil,
	parents = {},
	reference = "",
	properties = {
		type = ""
	},
	userData = {}
})

function GVG.Alias:init(reference, x, y, r, s, visible, properties, id)
	assert(reference, errorPrefix .. "Reference parameter is required.")
	self.x = x ~= nil and x or self.x
	self.y = y ~= nil and y or self.y
	self.r = r ~= nil and r or self.r
	self.s = s ~= nil and s or self.s
	self.visible = visible ~= nil and visible or self.visible
	self.uuid = uuid()
	self.id = id and newId(id, self.uuid)
	self.reference = type(reference) == "table" and reference.uuid or reference
	GVG.elements[self.uuid] = self

	local ce = GVG.elements[self.reference]
	if self.type == "GVGShape" then
		self.properties = properties or {}
	end
	self.properties.type = ce.class.name
end

GVG.Alias.removeFromParent = GVG.Shape.removeFromParent

function GVG.Alias:removeFromParents()
	if #self.parents > 0 then
		for p = 1, #self.parents do
			self:removeFromParent(self.parents[p])
		end
		self.parents = {}
	else
		print(warningPrefix .. "Cannot remove alias '" .. self.uuid .. "' (" .. self.properties.type .. ") from parent because it has no parents.")
	end
end

function GVG.Alias:delete()
	self:removeFromParents()
	GVG.elements[self.uuid] = nil
end

function GVG.Alias:draw(x, y, r, s, properties, visible)
	local nv = (visible or self.visible)
	if not nv then return end
	assert(GVG.elements[self.reference], errorPrefix .. "Original item for alias '" .. self.uuid .. "' (" .. self.properties.type .. ") not found.")
	if self.properties.type == "GVGShape" then
		GVG.elements[self.reference]:draw(x ~= nil and x or self.x, y ~= nil and y or self.y, r ~= nil and r or self.r, s ~= nil and s or self.s, self.properties.color, self.properties.line, self.properties.stroke, self.properties.offset, self.properties.uniforms, nv)
	elseif self.properties.type == "GVGGroup" then
		GVG.elements[self.reference]:draw(x ~= nil and x or self.x, y ~= nil and y or self.y, r ~= nil and r or self.r, s ~= nil and s or self.s, nv)
	end
end














-- GROUP
GVG.Group = class("GVGGroup", {
	x = 0,
	y = 0,
	r = 0,
	s = 1,
	visible = true,
	uuid = "",
	id = nil,
	parents = {},
	children = {},
	userData = {}
})

function GVG.Group:init(children, x, y, r, s, visible, id)
	self.x = x ~= nil and x or self.x
	self.y = y ~= nil and y or self.y
	self.r = r ~= nil and r or self.r
	self.s = s ~= nil and s or self.s
	self.visible = visible ~= nil and visible or self.visible
	self.uuid = uuid()
	self.id = id and newId(id, self.uuid)
	if children then
		for c = 1, #children do
			self:add(children[c])
		end
	end
	GVG.elements[self.uuid] = self
end

function GVG.Group:add(s, index)
	local sid = type(s) == "string" and s or s.uuid
	table.insert(GVG.elements[sid].parents, self.uuid)
	if index then
		index = clamp(index, -#self.children, #self.children)
		table.insert(self.children, index > 0 and index or (#self.children + index), sid)
	else
		table.insert(self.children, sid)
	end
end

function GVG.Group:remove(s) -- index or element (or uuid)
	if type(s) == "number" then
		self.children[s]:removeFromParent(self.uuid)
	else
		local sid = type(s) == "string" and s or s.uuid
		GVG.elements[s]:removeFromParent(self.uuid)
	end
end

GVG.Group.removeFromParent = GVG.Shape.removeFromParent

function GVG.Group:removeFromParents()
	if #self.parents > 0 then
		for p = 1, #self.parents do
			self:removeFromParent(self.parents[p])
		end
		self.parents = {}
	else
		print(warningPrefix .. "Cannot remove group '" .. self.uuid .. "' from parent because it has no parents.")
	end
end

function GVG.Group:delete()
	self:removeFromParents()
	while #self.children > 0 do
		GVG.elements[self.children[1]]:delete()
	end
	GVG.elements[self.uuid] = nil
end

function GVG.Group:localToWorld(x, y, r, s, xo, yo, ro, so)
	local cs = so ~= nil and so or self.s
	local cr = ro ~= nil and ro or self.r
	local cx, cy = rotate((x ~= nil and x or 0) * cs, (y ~= nil and y or 0) * cs, -cr)
	return (xo ~= nil and xo or self.x) + cx, (yo ~= nil and yo or self.y) + cy, cr + (r ~= nil and r or 0), cs * (s ~= nil and s or 1)
end

function GVG.Group:worldToLocal(x, y, r, s, xo, yo, ro, so)
	local cs = so ~= nil and so or self.s
	local cr = ro ~= nil and ro or self.r
	local cx, cy = rotate(((x ~= nil and x or 0) - (xo ~= nil and xo or self.x)) / cs, ((y ~= nil and y or 0) - (yo ~= nil and yo or self.y)) / cs, cr)
	return cx, cy, cr + (r ~= nil and r or 0), (s ~= nil and s or 1) / cs
end

function GVG.Group:draw(x, y, r, s, visible)
	if not (visible or self.visible) then return end
	for i = 1, #self.children do
		local cc = GVG.elements[self.children[i]]
		cc:draw(self:localToWorld(cc.x, cc.y, cc.r, cc.s, x, y, r, s))
	end
end








-- IMAGE
GVG.Image = GVG.Group:extend("GVGImage", {
	x = 0,
	y = 0,
	r = 0,
	s = 1,
	visible = true,
	uuid = "",
	id = nil,
	parents = {},
	children = {},
	userData = {},
	properties = {
		version = "",
		width = 1,
		height = 1,
	}
})

local function isNumber(s)
	return s:match("^[%d%.%-]+$")
end

local function isBoolean(s)
	return s:lower() == "no" or s:lower():gsub("yes", "") == ""
end

local function toboolean(s)
	return s:lower() == "no" and false or s:lower():gsub("yes", "") == "" and true
end

local function parseType(s, filter)
	if isNumber(s) and (not filter or filter["number"]) then
		return tonumber(s)
	elseif isBoolean(s) and (not filter or filter["boolean"]) then
		return toboolean(s)
	else
		return s
	end
end

function GVG.Image:init(img, x, y, r, s, visible, id)
	pcall(function ()
		local tmps = lf.read(img)
		assert(tmps)
		img = tmps
	end)

	local header = img:match("[^\n]*")
	local body = img:match("\n.*[^\n]*"):sub(2, -1)
	if header:sub(1, 3):lower() ~= "gvg" then
		error("Invalid GVG file.")
	end
	header = header:sub(5, -1)
	for k, v in header:gmatch("(%S-):(%S+)") do
		if v:match("^[%d%.%-]+$") then
			v = tonumber(v)
		end
		self.properties[k] = v
		--print(k, v, type(self.properties[k]))
	end

	local groupStack = {}

	local lineNumber = 1 -- not 0 because header is already removed.

	for l in body:gsub("\n", "|"):gmatch("[^|]+") do
		lineNumber = lineNumber + 1
		l = trim(l):gsub("#.*", ""):gsub("<.->", ""):gsub("<.*", ""):gsub(".*>", "") -- remove comments
		if l:match("%$") then
			if #groupStack > 0 then
				table.remove(groupStack, 1)
				if DEBUG then print("End group. groupStack level: " .. #groupStack) end
			else
				print("GVG Warning: line " .. lineNumber .. ": Unmatched closing symbol '$'.")
			end
			l = l:gsub("%$", "")
		end
		local c, p = l:match("(%S+)%s*(.*)")
		--print(c, p)
		if c == "shape" then
			local st, params = p:match("(%S+)%s*(.*)")
			if DEBUG then print(st) end
			local tmps = GVG.Shape(st)
			for k, v in params:gmatch("([^%s:]+):*(%S*)") do
				if DEBUG then print("", k, v) end
				if k == "x" then
					tmps.x = tonumber(v)
				elseif k == "y" then
					tmps.y = tonumber(v)
				elseif k == "r" then
					tmps.r = (tonumber(v:sub(1, -4)) / 360) * tau
				elseif k == "s" then
					tmps.s = tonumber(v)
				elseif k == "color" then
					local r, g, b, a = v:match("([^%s,]+),([^%s,]+),([^%s,]+),*(%S*)")
					tmps.color = {tonumber(r), tonumber(g), tonumber(b), tonumber(a)}
				elseif k == "id" then
					tmps.id = newId(v, tmps.uuid)
				elseif k == "angle" then
					local ang = (tonumber(v:sub(1, -4)) / 360) * tau * 0.5
					tmps.uniforms["sinCosAperture"] = {{math.sin(ang), math.cos(ang)}}
				elseif k == "stroke" then
					tmps.stroke = tonumber(v)
				elseif k == "offset" then
					tmps.offset = tonumber(v)
				elseif k == "line" then
					tmps.line = toboolean(v)
				elseif k == "visible" then
					tmps.visible = toboolean(v)
				else
					if v:match(",") then
						local tmpt = {}
						for x in v:gmatch("([^,]+)") do
							table.insert(tmpt, parseType(x))
						end
						v = tmpt
					else
						if isNumber(v) then
							v = tonumber(v)
						elseif v:lower():match("yes") then
							v = true
						elseif v:lower():match("no") then
							v = false
						end
					end
					tmps.uniforms[k] = {v}
				end
				--print(k, v)
			end
			if #groupStack > 0 then
				groupStack[#groupStack]:add(tmps)
			else
				self:add(tmps)
			end
		elseif c == "group" then
			local cg = GVG.Group()
			for k, v in p:gmatch("([^%s:]+):*(%S*)") do
				--print(k, v)
				if k == "x" then
					cg.x = tonumber(v)
				elseif k == "y" then
					cg.y = tonumber(v)
				elseif k == "r" then
					cg.r = (tonumber(v:sub(1, -4)) / 360) * tau * 0.5
				elseif k == "s" then
					cg.s = tonumber(v)
				elseif k == "visible" then
					cg.visible = toboolean(v)
				elseif k == "id" then
					cg.id = newId(v, cg.uuid)
				end
			end
			if #groupStack > 0 then
				groupStack[#groupStack]:add(cg)
			else
				self:add(cg)
			end
			table.insert(groupStack, cg)
			if DEBUG then print("Start group. groupStack level: " .. #groupStack) end
		elseif c == "alias" then
			local aid, params = p:match("(%S+)%s*(.*)")
			if DEBUG then print(aid) end
			local na = GVG.Alias(GVG.getElementById(aid))
			for k, v in params:gmatch("([^%s:]+):*(%S*)") do
				if DEBUG then print(k, v) end
				if k == "x" then
					na.x = tonumber(v)
				elseif k == "y" then
					na.y = tonumber(v)
				elseif k == "r" then
					na.r = (tonumber(v:sub(1, -4)) / 360) * tau * 0.5
				elseif k == "s" then
					na.s = tonumber(v)
				elseif k == "visible" then
					na.visible = toboolean(v)
				elseif k == "id" then
					na.id = newId(v, na.uuid)
				else
					if v:match(",") then
						if not na.properties.uniforms then
							na.properties.uniforms = {}
						end
						local tmpt = {}
						for x in v:gmatch("([^,]+)") do
							table.insert(tmpt, parseType(x))
						end
						v = tmpt
					else
						if not na.properties.uniforms then
							na.properties.uniforms = {}
						end
						if isNumber(v) then
							v = tonumber(v)
						elseif v:lower():match("yes") then
							v = true
						elseif v:lower():match("no") then
							v = false
						end
					end
					na.properties.uniforms[k] = {v}
				end
			end
			if #groupStack > 0 then
				groupStack[#groupStack]:add(na)
			else
				self:add(na)
			end
		elseif c == "text" then
			print("GVG Warning: Text support is currently experimental and might not function as expected.")
			local str, params = p:match("`(.*)`(.*)")
			assert(str, errorPrefix .. "line " .. lineNumber .. ": Text strings must be between two '`'.")
			local nt = GVG.Text(str)
			for k, v in p:gmatch("([^%s:]+):*(%S*)") do
				--print(k, v)
				if k == "x" then
					nt.x = tonumber(v)
				elseif k == "y" then
					nt.y = tonumber(v)
				elseif k == "r" then
					nt.r = (tonumber(v:sub(1, -4)) / 360) * tau * 0.5
				elseif k == "s" then
					nt.s = tonumber(v)
				elseif k == "color" then
					local r, g, b, a = v:match("([^%s,]+),([^%s,]+),([^%s,]+),*(%S*)")
					nt.color = {tonumber(r), tonumber(g), tonumber(b), tonumber(a)}
				elseif k == "visible" then
					nt.visible = toboolean(v)
				elseif k == "id" then
					nt.id = newId(v, nt.uuid)
				elseif k == "mode" then
					nt.mode = v
				elseif k == "size" then
					nt.size = tonumber(v)
				elseif k == "alignX" then
					nt.alignX = v
				elseif k == "alignY" then
					nt.alignY = v
				elseif k == "snapToPixel" then
					nt.snapToPixel = toboolean(v)
				elseif k == "lockUpright" then
					nt.lockUpright = toboolean(v)
				end
			end
			if #groupStack > 0 then
				groupStack[#groupStack]:add(nt)
			else
				self:add(nt)
			end
		else
			if c then
				print(warningPrefix .. "line " .. lineNumber .. ": Unrecognized command '" .. c .. "'.")
			end
		end
		--print()
	end
	GVG.elements[self.uuid] = self
end








-- GLYPH
GVG.Glyph = GVG.Shape:extend("GVGGlyph", {
	-- TODO
})






-- FONT
GVG.Font = class("GVGFont", {
	glyphs = {},
	userData = {}
	-- TODO
})





-- TEXT
GVG.Text = GVG.Group:extend("GVGText", {
	x = 0,
	y = 0,
	r = 0,
	s = 1,
	visible = true,
	text = "",
	color = {1, 1, 1, 1},
	size = 14,
	mode = "bitmapsdf", -- software, bitmap, bitmapsdf, sdf
	alignX = "center",
	alignY = "center",
	snapToPixel = false,
	lockUpright = false,
	font = nil, -- default?

	-- bitmap
	bitmapProperties = nil,
	softwareProperties = nil
})

function GVG.Text:init(text, font, size, mode, x, y, r, s, visible)
	self.x = x ~= nil and x or self.x
	self.y = y ~= nil and y or self.y
	self.r = r ~= nil and r or self.r
	self.s = s ~= nil and s or self.s
	self.visible = visible ~= nil and visible or self.visible
	self.uuid = uuid()
	self.text = text or ""
	self.font = font
	self.size = size ~= nil and size or self.size
	self.mode = mode or self.mode
	GVG.elements[self.uuid] = self
end

function GVG.Text:setText(str)
	self.text = str
end

local ts = love.graphics.newShader([[
	uniform float scl;
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		//return vec4(tc, 0.5, 1.0);
		vec4 c = gammaToLinear(color);
		float d = clamp(Texel(texture, tc).a * scl - 0.5 * scl + 0.5, 0.0, 1.0);
		return linearToGamma(vec4(c.rgb, c.a * d));
	}
]])

function GVG.Text:draw(x, y, r, s, visible)
	if not (visible or self.visible) then return end
	if self.mode == "software" then
		if self.softwareProperties then
			if self.size * s < 1 and (not self.softwareProperties.scaleCorrection) then
				return
			end
		elseif self.size * s < 1 then
			return
		end
	end

	local dx, dy = x ~= nil and x or self.x, y ~= nil and y or self.y
	local dr = r ~= nil and r or self.r
	local ds = s ~= nil and s or self.s

	if self.lockUpright then
		dr = 0
	end

	local ls = love.graphics.getShader()
	local lc = {love.graphics.getColor()}

	if self.mode == "bitmap" or self.mode == "bitmapsdf" then
		if not self.bitmapProperties then
			self.bitmapProperties = {}
		end
		if not self.bitmapProperties.baseSize then
			self.bitmapProperties.baseSize = self.size
		end
		if not self.bitmapProperties.img then
			self.bitmapProperties.img = love.graphics.newText(love.graphics.newFont(self.bitmapProperties.baseSize), self.text)
		end

		local nx, ny = GVG.worldToScreen(dx, dy)

		local sf = (ds * self.size) / self.bitmapProperties.baseSize
		local ox, oy = 0, 0
		if self.alignX == "center" then
			ox = -(self.bitmapProperties.img:getWidth() * sf * 0.5)
		end
		if self.alignY == "center" then
			oy = -(self.bitmapProperties.img:getHeight() * sf * 0.5)
		end
		ox, oy = rotate(ox, oy, dr)
		nx, ny = nx + ox, ny + oy

		if self.snapToPixel then
			nx, ny = math.floor(nx + 0.5), math.floor(ny + 0.5)
		end
		if self.mode == "bitmapsdf" then
			ts:send("scl", math.max(sf, 1))
			love.graphics.setShader(ts)
		end

		love.graphics.setColor(self.color)
		love.graphics.draw(self.bitmapProperties.img, nx, ny, dr, sf, sf)
	elseif self.mode == "software" then
		if not self.softwareProperties then
			self.softwareProperties = {}
		end
		if self.softwareProperties.scaleCorrection == nil then
			self.softwareProperties.scaleCorrection = true
		end
		local nfs = math.max(math.floor(self.size * ds), 1)
		if (not (self.softwareProperties.font or self.softwareProperties.fontSize)) or (nfs ~= self.softwareProperties.fontSize) then
			self.softwareProperties.font = love.graphics.newFont(nfs, "none")
			self.softwareProperties.fontSize = nfs
		end
		local sc = 1
		if self.softwareProperties.scaleCorrection then
			sc = (self.size * ds) / nfs
		end
		love.graphics.setFont(self.softwareProperties.font)
		local nx, ny = GVG.worldToScreen(dx, dy)
		local ox, oy = 0, 0
		if self.alignX == "center" then
			ox = -(self.softwareProperties.font:getWidth(self.text) * sc * 0.5)
		end
		if self.alignY == "center" then
			oy = -(self.softwareProperties.font:getHeight() * sc * 0.5)
		end
		ox, oy = rotate(ox, oy, dr)
		nx, ny = nx + ox, ny + oy
		if self.snapToPixel then
			nx, ny = math.floor(nx + 0.5), math.floor(ny + 0.5)
		end
		love.graphics.setColor(self.color)
		love.graphics.print(self.text, nx, ny, dr, sc, sc)
	end

	love.graphics.setColor(lc)
	love.graphics.setShader(ls)
end





return GVG
