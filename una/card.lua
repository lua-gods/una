
local param = require("una.lib.param")
local Event = require("una.lib.event")

local ROOT_MODEL = models:newPart("cardWorld","WORLD"):scale(16,16,16)
local CARD_MODEL = models.una.models.card:setVisible(false)

local SCALE = 16
local CARD_DIM = vec(12,16) / 16
local INV_SCALE = 1/SCALE


local CARD_RADIUS_SQ = CARD_DIM:lengthSquared() / 2
local CARD_DIM_HALF = CARD_DIM / 2

local cards = {} ---@type Card[]

--[────────────────────────────────────────-< CARD API >-────────────────────────────────────────]--

---@class CardAPI
local CardAPI = {}

---@alias CardColor
---| "RED"
---| "YELLOW"
---| "GREEN"
---| "BLUE"
---| "BLACK"

local colorUV = {
	vec( 0, 0), -- RED
	vec(10, 0), -- YELLOW
	vec(20, 0), -- GREEN
	vec(30, 0), -- BLUE
	vec(40, 0), -- BLACK
}

local iconUV = {
	vec( 0,  0), -- ZERO    
	vec( 9,  0), -- ONE     
	vec(18,  0), -- TWO     
	vec(27,  0), -- THREE   
	vec(36,  0), -- FOUR    
	vec(0,  11), -- FIVE    
	vec(9,  11), -- SIX     
	vec(18, 11), -- SEVEN   
	vec(27, 11), -- EIGHT   
	vec(36, 11), -- NINE    
	vec( 0, 22), -- REVERSE 
	vec( 9, 22), -- SKIP    
	vec(18, 22), -- DRAW2   
	vec(27, 22), -- DRAW4   
	vec(36, 22), -- WILD    
	vec(45,  0), -- UNKNOWN 
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

local index2color = {
	"RED",
	"YELLOW",
	"GREEN",
	"BLUE",
	"BLACK",
}

local index2type = {
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

local color2index = {}
local type2index = {}
for i, color in ipairs(index2color) do
	color2index[i] = color
end
for i, type in ipairs(index2type) do
	type2index[i] = type
end



---@param id integer?
---@return string
function CardAPI.indexToType(id)
	if not id then
		id = math.random(1, #index2type)
	end
	return index2type[id]
end


---@param id integer?
function CardAPI.indexToColor(id)
	if not id then
		id = math.random(1, #index2color)
	end
	return index2color[id]
end


function CardAPI.colorToIndex(clr)
	return color2index[clr]
end


function CardAPI.typeToIndex(type)
	return type2index[type]
end


CardAPI.CARD_CLICKED = Event.new()
CardAPI.CARD_HOVER_STATE = Event.new()


--[────────────────────────────────────────-< CARD OBJECT >-────────────────────────────────────────]--


---@class Card
---@field color integer
---@field type integer
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
		color = 1,
		type = 1,
		scale = vec(1,1,1),
		pos = vec(0,0,0),
		dir = vec(0,1,0),
		rot = vec(0,0,0),
		matrix = matrices.mat4(),
		invMatrix = matrices.mat4(),
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
	local color = CardAPI.colorToIndex(color)
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
	local type = CardAPI.typeToIndex(type)
	if not iconUV[type] then
		error('card type "' .. type .. '" dosent exist', 1)
	end
	self.type = type
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
	:rotate(self.rot)
	:scale(self.scale)
	:translate(self.pos)
	self.invMatrix = self.matrix:inverted()
	self.dir = self.matrix.c2.xyz:normalize()
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


--[────────────────────────────────────────-< CARD SERVICE >-────────────────────────────────────────]--

local lsCard
local sCard

events.TICK:register(function ()
	local viewer = client:getViewer()
	
	if viewer:isLoaded() then
		lsCard = sCard
		sCard = nil
		
		local ppos,pdir = viewer:getPos():add(0,viewer:getEyeHeight()),viewer:getLookDir()
		local closest = math.huge
		local chosenHitPos
		
		for _, card in pairs(cards) do
			local cardPos = card.pos
			local hitPos = ray2PlaneIntersection(ppos, pdir, cardPos, card.dir)
		
			if hitPos then
				local distToCam = (hitPos-ppos):lengthSquared()
		
				if closest > distToCam and (hitPos-cardPos):lengthSquared() < CARD_RADIUS_SQ then
					local lpos = card.invMatrix:apply(hitPos)
		
					if math.abs(lpos.x) < CARD_DIM_HALF.x and math.abs(lpos.z) < CARD_DIM_HALF.y then
						sCard = card
						closest = distToCam
						chosenHitPos = hitPos
					end
				end
			end
		end
		if sCard then
			particles.end_rod:pos(chosenHitPos):lifetime(0):scale(1):spawn()
		end
	end
	
	if lsCard ~= sCard then
		CardAPI.CARD_HOVER_STATE:invoke(sCard, lsCard)
	end
	if viewer:getSwingTime() == 1 and sCard then
		CardAPI.CARD_CLICKED:invoke(sCard)
	end
end)


return CardAPI
