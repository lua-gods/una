---@diagnostic disable: param-type-mismatch
local CARD_MODEL = models.one.Card

local c = {}
CARD_MODEL:setVisible(false)
---@alias CardColor
---| "RED"
---| "YELLOW"
---| "GREEN"
---| "BLUE"
---| "BLACK"

local colorUV = {
   RED=vectors.vec2(0,0),
   YELLOW=vectors.vec2(10,0),
   GREEN=vectors.vec2(20,0),
   BLUE=vectors.vec2(30,0),
   BLACK=vectors.vec2(40,0),
}

local iconUV = {
   ZERO = vectors.vec2(0,0),
   ONE = vectors.vec2(9,0),
   TWO = vectors.vec2(18,0),
   THREE = vectors.vec2(27,0),
   FOUR = vectors.vec2(36,0),
   FIVE = vectors.vec2(0,11),
   SIX = vectors.vec2(9,11),
   SEVEN = vectors.vec2(18,11),
   EIGHT = vectors.vec2(27,11),
   NINE = vectors.vec2(36,11),
   REVERSE = vectors.vec2(0,22),
   SKIP = vectors.vec2(9,22),
   DRAW2 = vectors.vec2(18,22),
   DRAW4 = vectors.vec2(27,22),
   WILD = vectors.vec2(36,22),
   UNKNOWN = vectors.vec2(45,0),
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

---@class Card
---@field color CardColor
---@field type CardType
---@field model ModelPart
local Card = {}
Card.__index = Card

local colorLookup = {
   "RED",
   "YELLOW",
   "GREEN",
   "BLUE",
   "BLACK"
}

local typeLookup = {
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

local i = 0
---@return Card
function c.newCard()
   i = i + 1
   local model = models:newPart("card" .. i):setParentType("World")

   ---@type Card
   local compose = {
      color="RED",
      type="ONE",
      model = model
   }
   for key, value in pairs(CARD_MODEL:getChildren()) do
      local part = value:copy("cardP"..i.."z"..key)
      model:addChild(part)
      compose.model[value:getName()] = part
   end
   setmetatable(compose,Card)
   model:setScale(0.3,0.3,0.3)
   return compose
end


---@param color CardColor
---@return Card
function Card:setColorType(color)
   if not colorUV[color] then
      error('card color "'..color..'" dosent exist',1)
   end
   self.color = color
   self.model.Background:setUV(colorUV[color]/64)
   return self
end


---@param type CardType
---@return Card
function Card:setSymbolType(type)
   self.type = type
   if not iconUV[type] then
      error('card type "'..type..'" dosent exist',1)
   end
   self.model.Number:setUV(iconUV[type]/64)
   self.model.TopNumber:setUV(iconUV[type]/64)
   self.model.BottomNumber:setUV(iconUV[type]/64)
   return self
end

---@overload fun(pos:Vector3):Card
---@param x number
---@param y number?
---@param z number?
---@return Card
function Card:setPos(x,y,z)
   if type(x) == "Vector3" then
      self.model.root:setPos(x * 16)
   else
      self.model.root:setPos(x * 16,y * 16,z * 16)
   end
   return self
end

---@return Vector3
function Card:getPos()
   return (self.model.root:getPos() / 16)
end

---@param rot_x number|Vector3
---@param y number
---@param z number
---@return Card
function Card:setRot(rot_x,y,z)
   if type(rot_x) == "Vector3" then
      self.model.root:setRot(rot_x)
   else
      self.model.root:setRot(rot_x,y,z)
   end
   return self
end

---@return Vector3
function Card:getRot()
   return self.model:getRot()
end

---@param mat Matrix4
---@return Card
function Card:setMatrix(mat)
   self.model.root:setMatrix(mat:copy())
   return self
end

---@return unknown
function Card:getMatrix()
   return self.model:getMatrix()
end


---@param scale_x number|Vector3
---@param y number
---@param z number
---@return Card
function Card:setScale(scale_x,y,z)
   if type(scale_x) == "Vector3" then
      self.model.root:setScale(scale_x * 0.3)
   else
      self.model.root:setScale(scale_x * 0.3,y * 0.3,z * 0.3)
   end
   return self
end

-- Deletes the card
function Card:free()
   self.model.root:getParent():removeChild(self.model.root)
   for key, value in pairs(self.model.root:getChildren()) do
      self.model.root:removeChild(value)
   end
end

function Card:getScale()
   return self.model.root:getScale() / 16
end



---@param id integer?
---@return string
function c.indexToType(id)
   if not id then
      id = math.random(1,#typeLookup)
   end
   return typeLookup[id]
end

---@param id integer?
function c.indexToColor(id)
   if not id then
      id = math.random(1,#colorLookup)
   end
   return colorLookup[id]
end

return c