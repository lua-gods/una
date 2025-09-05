local Card = require("una.card")
local displayMatrix = require("una.debug.lineMatrix")

local pos = vec(0, 5, 0)
local card = Card.new()

card:setPos(pos):setRot(15,123,45)

displayMatrix(card.matrix)

for i = 1, 10, 1 do
	Card.new()
	:setPos(pos.x+math.random()*3, pos.y, pos.z+math.random()*3)
	:setRot(math.random(0,360),math.random(0,360),math.random(0,360))
end