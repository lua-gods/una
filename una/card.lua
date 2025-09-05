
local param = require("una.lib.param")


local ROOT_MODEL = models:newPart("cardWorld","WORLD"):scale(16,16,16)
local CARD_MODEL = models.una.models.card:setVisible(false)

local SCALE = 16
local INV_SCALE = 1/SCALE

local cards = {} ---@type Card[]


---@class CardAPI
local CardAPI = {}

---@alias CardColor
---| "RED"
---| "YELLOW"
---| "GREEN"
---| "BLUE"
---| "BLACK"

local colorUV = {
	RED    = vec(0, 0),
	YELLOW = vec(10, 0),
	GREEN  = vec(20, 0),
	BLUE   = vec(30, 0),
	BLACK  = vec(40, 0),
}

local iconUV = {
	ZERO    = vec(0, 0),
	ONE     = vec(9, 0),
	TWO     = vec(18, 0),
	THREE   = vec(27, 0),
	FOUR    = vec(36, 0),
	FIVE    = vec(0, 11),
	SIX     = vec(9, 11),
	SEVEN   = vec(18, 11),
	EIGHT   = vec(27, 11),
	NINE    = vec(36, 11),
	REVERSE = vec(0, 22),
	SKIP    = vec(9, 22),
	DRAW2   = vec(18, 22),
	DRAW4   = vec(27, 22),
	WILD    = vec(36, 22),
	UNKNOWN = vec(45, 0),
}
---@alias CardType
---| "ZERO"
---| "ONE"
---| "TWO"
---| "THREE"
---| "FOUR"
---| "FIVE"
---| "SIX"
---| "SEVEN"
---| "EIGHT"
---| "NINE"
---| "REVERSE"
---| "SKIP"
---| "DRAW2"
---| "DRAW4"
---| "WILD"

local colorIndex = {
	"RED",
	"YELLOW",
	"GREEN",
	"BLUE",
	"BLACK",
}

local typeIndex = {
	"ZERO",
	"ONE",
	"TWO",
	"THREE",
	"FOUR",
	"FIVE",
	"SIX",
	"SEVEN",
	"EIGHT",
	"NINE",
	"REVERSE",
	"SKIP",
	"DRAW2",
	"DRAW4",
	"WILD",
}

---@class Card
---@field color CardColor
---@field type CardType
---@field matrix Matrix4
---@field invMatrix Matrix4
---@field pos Vector3
---@field dir Vector3
---@field rot Vector3
---@field model ModelPart
local Card = {}
Card.__index = Card

local nextFree = 0
---@return Card
function CardAPI.new()
	nextFree = nextFree + 1
	local model = ROOT_MODEL:newPart("card" .. nextFree)

	---@type Card
	local new = {
		color = "RED",
		type = "ONE",
		scale = vec(1,1,1),
		pos = vec(0,0,0),
		dir = vec(0,1,0),
		rot = vec(0,0,0),
		matrix = matrices.mat4(),
		invMatrix = matrices.mat4():scale(INV_SCALE),
		model = model,
	}
	for key, value in pairs(CARD_MODEL:getChildren()) do
		local part = value:copy(value:getName()):scale(INV_SCALE)
		model:addChild(part)
	end
	setmetatable(new, Card)
	new:matrixApply()
	cards[nextFree] = new
	return new
end

---@param color CardColor
---@return Card
function Card:setColor(color)
	if not colorUV[color] then
		error('card color "' .. color .. '" dosent exist', 1)
	end
	self.color = color
	self.model.Background:setUV(colorUV[color] / 64)
	return self
end


---@param type CardType
---@return Card
function Card:setSymbol(type)
	self.type = type
	if not iconUV[type] then
		error('card type "' .. type .. '" dosent exist', 1)
	end
	self.model.Number:setUV(iconUV[type] / 64)
	self.model.TopNumber:setUV(iconUV[type] / 64)
	self.model.BottomNumber:setUV(iconUV[type] / 64)
	return self
end

--- snippet by @PenguinEncounter
---@param mat Matrix4|Matrix3
---@return Vector3
local function mat2eulerZYX(mat)
	---@type number, number, number
	local x, y, z
	local query = mat.v31 -- are we in Gimbal Lock?
	if math.abs(query) < 0.9999 then
		y = math.asin(-mat.v31)
		z = math.atan2(mat.v21, mat.v11)
		x = math.atan2(mat.v32, mat.v33)
	elseif query < 0 then -- approx -1, gimbal lock
		y = math.pi / 2
		z = -math.atan2(-mat.v23, mat.v22)
		x = 0
	else -- approx 1, gimbal lock
		y = -math.pi / 2
		z = math.atan2(-mat.v23, mat.v22)
		x = 0
	end
	return vec(x, y, z):toDeg()
end


---Updates the Matrix from the pos,rot,scale data.
---@return Card
function Card:matrixApply()
	self.matrix = matrices.mat4()
	:translate(self.pos)
	:scale(self.scale)
	:rotate(self.rot)
	self.invMatrix = self.matrix:invert()
	self.model:setMatrix(self.matrix)
	return self
end


---Updates the pos,rot,scale data from the Matrix.
---@return Card
function Card:matrixUnfold()
	self.pos = self.matrix.c4.xyz
	self.dir = self.matrix.c2.xyz:normalize()
	self.rot = mat2eulerZYX(self.matrix)
	return self
end


---@overload fun(pos:Vector3):Card
---@param x number
---@param y number
---@param z number
---@return Card
function Card:setPos(x, y, z)
	self.pos = param.vec3(x, y, z)
	self:matrixApply()
	return self
end


---@overload fun(pos:Vector3):Card
---@param x number
---@param y number
---@param z number
---@return Card
function Card:setRot(x, y, z)
	self.rot = param.vec3(x, y, z)
	self:matrixApply()
	return self
end


---@overload fun(scale:Vector3):Card
---@param x number
---@param y number
---@param z number
---@return Card
function Card:setScale(x, y, z)
	self.scale = param.vec3(x, y, z)
	self:matrixApply()
	return self
end



function Card:free()
	self.model:getParent():removeChild(self.model)
end


---@param id integer?
---@return string
function CardAPI.indexToType(id)
	if not id then
		id = math.random(1, #typeIndex)
	end
	return typeIndex[id]
end


---@param id integer?
function CardAPI.indexToColor(id)
	if not id then
		id = math.random(1, #colorIndex)
	end
	return colorIndex[id]
end


---@param pos Vector3
---@param dir Vector3
---@param planeDir Vector3
---@param planePos Vector3
---@return Vector3?
local function ray2PlaneIntersection(pos,dir,planePos,planeDir)
	local dn = dir:normalized()
	local pdn = planeDir:normalized()
	
	local dot = dn:dot(pdn)
	if math.abs(dot) < 1e-6 then return nil end
	local dtp = pdn:dot(planePos - pos) / dot
	local ip = pos + dn * dtp
	return ip
end

events.WORLD_RENDER:register(function (delta)
	local benchmark = avatar:getCurrentInstructions() -- START OF BENCHMARK
	local viewer = client:getViewer()
	if viewer:isLoaded() then
		local ppos,pdir = viewer:getPos():add(0,viewer:getEyeHeight()),viewer:getLookDir()
		for _, card in pairs(cards) do
			local pos = card.pos
			local hitPos = ray2PlaneIntersection(ppos, pdir, pos, card.dir)
			if hitPos and (hitPos-pos):lengthSquared() < 0.31^2 then
				local lpos = card.invMatrix:apply(hitPos)
				if math.abs(lpos.x) < 6 and math.abs(lpos.z) < 8 then
					particles.end_rod:pos(hitPos):lifetime(0):scale(0.1):spawn()
				end
			end
		end
	end
	host:setActionbar(avatar:getCurrentInstructions()-benchmark-5) -- END OF BENCHMARK
end)


return CardAPI
