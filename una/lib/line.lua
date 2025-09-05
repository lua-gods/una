--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNlineLib v2.1.0
/ /_/ / /|  /  desc: Allows you to draw lines in the world at ease.
\____/_/ |_/ source: https://github.com/lua-gods/GNs-Avatar-4/blob/main/lib/line.lua ]]
---@diagnostic disable: param-type-mismatch
--[────────────────────────────────────────-< CONFIG >-────────────────────────────────────────]--
local MODEL = models:newPart("gnlinelibline", "WORLD"):scale(16, 16, 16)
local TEXTURE = textures["1x1white"] or textures:newTexture("1x1white", 1, 1):setPixel(0, 0,
	vec(1, 1, 1))
local MAX_MS = 1000 / 200 -- replace 60 with max fps cap process
--[────────────────────────────────────────-< END OF CONFIG >-────────────────────────────────────────]--

local lines = {} ---@type Line[]
local queueUpdate = {} ---@type Line[]

local cpos = client:getCameraPos()

---@overload fun(pos : Vector3)
---@param x number
---@param y number
---@param z number
---@return Vector3
local function vec3(x, y, z)
	local t = type(x)
	if t == "Vector3" then
		return x:copy()
	elseif t == "number" then
		return vec(x, y, z)
	end
end

---@class Line # A straight path from point A to B
---@field id integer
---@field visible boolean
---@field a Vector3? # First end of the line
---@field b Vector3? # Second end of the line
---@field dir Vector3? # The difference between the first and second ends position
---@field dir_override Vector3? # Overrides the dir of the line, useful for non world parent parts
---@field length number # The distance between the first and second ends
---@field width number # The width of the line in meters
---@field color Vector4 # The color of the line in RGBA
---@field depth number # The offset depth of the line. 0 is normal, 0.5 is farther and -0.5 is closer
---@field package _queue_update boolean # Whether or not the line should be updated in the next frame
---@field model SpriteTask
local Line = {}
Line.__index = Line
Line.__type = "gn.line"
Line._VERSION = "2.0.2"

---Creates a new line.
---@param preset Line?
---@return Line
function Line.new(preset)
	preset = preset or {}
	local next_free = #lines + 1
	local new = setmetatable({}, Line)
	new.visible = true
	new.a = preset.a and preset.a:copy() or vec(0, 0, 0)
	new.b = preset.a and preset.b:copy() or vec(0, 0, 0)
	new.width = preset.width or 0.125
	new.width = preset.width or 0.125
	new.color = preset.color and preset.color:copy() or vec(1, 1, 1)
	new.depth = preset.depth or 1
	new.model = MODEL:newSprite("line" .. next_free):setTexture(TEXTURE, 1, 1):setRenderType(
	"EMISSIVE_SOLID"):setScale(0, 0, 0)
	new.id = next_free
	lines[next_free] = new
	return new
end

---Sets both points of the line.
---@overload fun(self : Line, from : Vector3, to :Vector3): Line
---@param x1 number|Vector3
---@param y1 number|Vector3
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return Line
function Line:setAB(x1, y1, z1, x2, y2, z2)
	if type(x1) == "Vector3" and type(y1) == "Vector3" then
		self.a = x1:copy()
		self.b = y1:copy()
		self.a = x1:copy()
		self.b = y1:copy()
	else
		self.a = vec(x1, y1, z1)
		self.b = vec(x2, y2, z2)
		self.a = vec(x1, y1, z1)
		self.b = vec(x2, y2, z2)
	end
	self.dir = (self.b - self.a)
	self.length = self.dir:length()
	self:update()
	return self
end

---Sets the first point of the line.
---@overload fun(self: Line ,pos : Vector3): Line
---@param x number
---@param y number
---@param z number
---@return Line
function Line:setA(x, y, z)
	self.a = vec3(x, y, z)
	self.dir = (self.b - self.a)
	self.length = self.dir:length()
	self:update()
	return self
end

---Sets the second point of the line.
---@overload fun(self: Line ,pos : Vector3): Line
---@param x number
---@param y number
---@param z number
---@return Line
function Line:setB(x, y, z)
	self.b = vec3(x, y, z)
	self.dir = (self.b - self.a)
	self.length = self.dir:length()
	self:update()
	return self
end

---Sets the width of the line.
---Note: This is in minecraft blocks/meters.
---@param w number
---@return Line
function Line:setWidth(w)
	self.width = w
	self:update()
	return self
end

---Sets the render type of the line.
---by default this is "CUTOUT_EMISSIVE_SOLID".
---@param render_type ModelPart.renderType
---@return Line
function Line:setRenderType(render_type)
	self.model:setRenderType(render_type)
	return self
end

---Sets the color of the line.
---@overload fun(self : Line, rgb : Vector3): Line
---@overload fun(self : Line, rgb : Vector4): Line
---@overload fun(self : Line, string : string): Line
---@param r number
---@param g number
---@param b number
---@param a number
---@return Line
function Line:setColor(r, g, b, a)
	local rt, yt, bt = type(r), type(g), type(b)
	if rt == "number" and yt == "number" and bt == "number" then
		self.color = vectors.vec4(r, g, b, a or 1)
	elseif rt == "Vector3" then
		self.color = r:augmented()
	elseif rt == "Vector4" then
		self.color = r
	elseif rt == "string" then
		self.color = vectors.hexToRGB(r):augmented(1)
	else
		error(
		"Invalid Color parameter, expected Vector3, (number, number, number) or Hexcode, instead got (" ..
		rt .. ", " .. yt .. ", " .. bt .. ")")
	end
	self.model:setColor(self.color)
	return self
end

---Sets the depth of the line.
---Note: this is an offset to the depth of the object. meaning 0 is normal, `0.5` is farther and `-0.5` is closer
---@param z number
---@return Line
function Line:setDepth(z)
	self.depth = 1 + z
	return self
end

---Frees the line from memory.
function Line:free()
	lines[self.id] = nil
	self.model:remove()
	self._queue_update = false
	self = nil
end

---@param visible boolean
---@return Line
function Line:setVisible(visible)
	self.visible = visible
	self.model:setVisible(visible)
	if visible then
		self:immediateUpdate()
	end
	return self
end

---Queues itself to be updated in the next frame.
---@return Line
function Line:update()
	if self.visible then
		queueUpdate[self.id] = self
	end
	return self
end

---Immediately updates the line without queuing it.
---@return Line
function Line:immediateUpdate()
	local a = self.a
	local offset = a - cpos
	local w, d = self.width, self.dir:normalized()
	local p = (offset - d * offset:copy():dot(d)):normalize()
	local c = p:copy():cross(d) * w
	local mat = matrices.mat3(
		(p:cross(d) * w),
		(-d * (self.length + w)),
		p
	):augmented():translate(a + c * 0.5 - d * w * 0.5)
	self.model:setMatrix(mat * self.depth)
	return self
end

local lk
MODEL:setPreRender(function()
	local c = client:getCameraPos()
	if (c - cpos):lengthSquared() > 0.5 then
		cpos = c
		for _, l in pairs(lines) do
			l:update()
		end
	end
	local time = client:getSystemTime() -- gets the starting time
	for i = 1, 1000, 1 do
		local k, l = next(queueUpdate, lk)
		lk = k
		if l then
			if client:getSystemTime() - time > MAX_MS then -- checks if the update took too long
				break
			end
			l:immediateUpdate()
			queueUpdate[k] = nil
		else
			break
		end
	end
end)


return Line
