---@diagnostic disable: param-type-mismatch

local param = require("una.lib.param")
local Event = require("una.lib.event")

local ROOT_MODEL = models:newPart("cardWorld","WORLD"):scale(16,16,16)
local CARD_MODEL = models.una.models.card:setVisible(false)

local SCALE = 16
local CARD_DIM = vec(12,16) / 16
local INV_SCALE = 1/SCALE
local OFFSET = vec(0,0.01,0)

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
	vec(45, 11), -- EMPTY   
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
---| "EMPTY"
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
	"EMPTY",
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

CardAPI.lastCardId = #index2color * #index2type

---converts full card id to color and type ids
---@param id number
---@return number # type
---@return number # color
function CardAPI.fullIdToColorAndTypeId(id)
   id = id - 1
   return id % #index2type + 1, math.floor(id / #index2type) + 1
end

---converts card type and color to full id
---@param cardType number
---@param color number
---@return number
function CardAPI.colorAndTypeIdToFullId(cardType, color)
   return (cardType - 1) + #index2type * (color - 1) + 1
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


CardAPI.CARD_PRESSED = Event.new()
CardAPI.CARD_HOVER = Event.new()


--[────────────────────────────────────────-< CARD OBJECT >-────────────────────────────────────────]--


---@class Card
---@field color integer
---@field type integer
---@field owner string?
---@field animMatrix Matrix4
---@field matrix Matrix4
---@field invMatrix Matrix4
---@field pos Vector3
---@field dir Vector3
---@field rot Vector3
---@field scale Vector3
---@field model ModelPart
---@field id integer
---@field PRESSED Event
---@field CARD_HOVER Event
local Card = {}
Card.__index = Card


local nextFree = 0
---@return Card
function CardAPI.new()
	nextFree = nextFree + 1
	local model = ROOT_MODEL:newPart("card" .. nextFree)

	---@type Card
	local new = {
		id = nextFree,
		color = 1,
		type = 1,
		dir = vec(0,1,0),

		pos = vec(0,0,0),
		rot = vec(0,0,0),
		scale = vec(1,1,1),

		animPos = vec(0,0,0),
		animRot = vec(0,0,0),
		animScale = vec(1,1,1),

		animMatrix = matrices.mat4(),
		matrix = matrices.mat4(),
		invMatrix = matrices.mat4(),
		model = model,
		
		PRESSED = Event.new(),
		CARD_HOVER = Event.new(),
	}
	for key, original in pairs(CARD_MODEL:getChildren()) do
		local part = original:copy(original:getName()):scale(INV_SCALE):setPos(original:getPos()+OFFSET):setRot(original:getRot())
		model:addChild(part)
	end
	setmetatable(new, Card)
	new:matrixApply()
	cards[nextFree] = new
	return new
end


---@param color integer
---@return Card
function Card:setColor(color)
	if not colorUV[color] then
		error('card color "' .. color .. '" dosent exist', 1)
	end
	self.color = color
	self.model.Background:setUV(colorUV[color] / 64)
	return self
end


---@param type integer
---@return Card
function Card:setType(type)
	if not iconUV[type] then
		error('card type "' .. type .. '" dosent exist', 1)
	end
	self.type = type
	self.model.Number:setUV(iconUV[type] / 64)
	--self.model.TopNumber:setUV(iconUV[type] / 64)
	--self.model.BottomNumber:setUV(iconUV[type] / 64)
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
	:rotateX(self.rot.x)
	:rotateY(self.rot.y)
	:rotateZ(self.rot.z)
	:scale(self.scale)
	:translate(self.pos)
	self.invMatrix = self.matrix:inverted()
	self.dir = self.matrix.c2.xyz:normalize()
	self.model:setMatrix(self.matrix * self.animMatrix)
	return self
end


function Card:animMatrixApply()
	self.animMatrix = matrices.mat4()
	:rotateZ(self.animRot.z)
	:rotateY(self.animRot.y)
	:rotateX(self.animRot.x)
	:scale(self.animScale)
	:translate(self.animPos)
	self:matrixApply()
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


---@overload fun(self:Card,pos:Vector3):Card
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


---@overload fun(pos:Vector3):Card
---@param x number
---@param y number
---@param z number
---@return Card
function Card:setAnimPos(x,y,z)
	self.animPos = param.vec3(x,y,z)
	self:animMatrixApply()
	return self
end


---@overload fun(pos:Vector3):Card
---@param x number
---@param y number
---@param z number
---@return Card
function Card:setAnimRot(x,y,z)
	self.animRot = param.vec3(x,y,z)
	self:animMatrixApply()
	return self
end


---@overload fun(pos:Vector3):Card
---@param x number
---@param y number
---@param z number
---@return Card
function Card:setAnimScale(x,y,z)
	self.animScale = param.vec3(x,y,z)
	self:animMatrixApply()
	return self
end


---The given name will be the only one able to click the card
---@param name string
function Card:setOwner(name)
	self.owner = name
end


---Returns the position of the card in global space
---@overload fun(self: Card ,pos : Vector3): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Card:toGlobal(x,y,z)
	local pos = param.vec3(x,y,z)
	return self.matrix:apply(pos*CARD_DIM_HALF.x_y)
end


---Returns the position of the card in local space
---@overload fun(self: Card ,pos : Vector3): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Card:toLocal(x,y,z)
	local pos = param.vec3(x,y,z)
	return self.invMatrix:apply(pos*CARD_DIM_HALF.x_y)
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

---@param pos Vector3
---@param dir Vector3
---@param name string
---@return Card?
---@return Vector3?
local function raycastCard(pos,dir,name)
	local closest = math.huge
	local chosenHitPos
	local hitCard
	
	for _, card in pairs(cards) do
		if card.owner and card.owner ~= name then
			goto continue
		end
		local cardPos = card.pos
		local hitPos = ray2PlaneIntersection(pos, dir, cardPos, card.dir)
		
		if hitPos then
			local distToCam = (hitPos-pos):lengthSquared()
				
			if closest > distToCam and (hitPos-cardPos):lengthSquared() < CARD_RADIUS_SQ then
				local lpos = card.invMatrix:apply(hitPos)
				
				if math.abs(lpos.x) < CARD_DIM_HALF.x and math.abs(lpos.z) < CARD_DIM_HALF.y then
					hitCard = card
					card.hitPos = lpos.xz
					closest = distToCam
					chosenHitPos = hitPos
				end
			end
		end
		::continue::
	end
	return hitCard, chosenHitPos
end


if host:isHost() then
	local lastSelectedCard = {}
	events.TICK:register(function ()
		for i, player in pairs(world.getPlayers()) do
			local ppos,pdir = player:getPos():add(0,player:getEyeHeight()),player:getLookDir()
			local hitCard, hitPos = raycastCard(ppos,pdir,player:getName())
			if lastSelectedCard[i] ~= hitCard then
				if lastSelectedCard[i] then lastSelectedCard[i].CARD_HOVER:invoke(false) end
				if hitCard then hitCard.CARD_HOVER:invoke(true) end
				CardAPI.CARD_HOVER:invoke(hitCard, lastSelectedCard[i], player:getName())
				lastSelectedCard[i] = hitCard
			end
			if player:getSwingTime() == 0 and player:getSwingArm() and hitCard then
				CardAPI.CARD_PRESSED:invoke(hitCard)
				hitCard.PRESSED:invoke()
			end
		end
	end)
else --[────────────────────────-< Non Host >-────────────────────────]--
	local lsCard
	local sCard
	
	events.TICK:register(function ()
		local viewer = client:getViewer()
		local name = viewer:getName()
		
		if viewer:isLoaded() then
			lsCard = sCard
			sCard = nil
	
			local ppos,pdir = viewer:getPos():add(0,viewer:getEyeHeight()),viewer:getLookDir()
			sCard = raycastCard(ppos,pdir,name)
		end
	
		if lsCard ~= sCard then
			if lsCard then lsCard.CARD_HOVER:invoke(false) end
			if sCard then sCard.CARD_HOVER:invoke(true) end
			CardAPI.CARD_HOVER:invoke(sCard, lsCard, name)
		end
		if viewer:getSwingTime() == 0 and viewer:getSwingArm() and sCard then
			CardAPI.CARD_PRESSED:invoke(sCard)
			sCard.PRESSED:invoke()
		end
	end)
end


return CardAPI
