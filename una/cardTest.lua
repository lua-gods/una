local Card = require("una.card")

local card = Card.new()

local pos = vec(0, 1, 0)

card:setPos(pos):setRot(15,123,45)

for i = 1, 10, 1 do
	Card.new()

	:setPos(pos.x+math.random(), pos.y, pos.z+math.random())
	:setRot(math.random(0,360),math.random(0,360),math.random(0,360))
end