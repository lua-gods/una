local Card = require("una.card")
local Tween = require("una.lib.tween")

---@param card Card
Card.CARD_PRESSED:register(function (card)
	sounds:playSound("minecraft:item.book.page_turn", Card.ROOT_MODEL:getPos() / 16 + card.pos, 0.5, 1.5)
	Tween.new{
		from = 1.1,
		to = 1,
		duration = 0.3,
		easing = "outBack",
		tick = function (v, t)
			card:setAnimScale(v,v,v)
		end,
		id=card.id
	}
end)

--[[
local lastCard
Card.CARD_HOVER:register(function(card)
	if lastCard then
		local myCard = lastCard
		Tween.new{
			from = 0.1,
			to = 0,
			duration = 0.3,
			easing = "outBack",
			tick = function (v, t)
				myCard:setAnimPos(0, 0, v)
			end,
			id=myCard.id
		}
	end
	lastCard = card
	if card then
		Tween.new{
			from = 0,
			to = 0.1,
			duration = 0.3,
			easing = "outBack",
			tick = function (v, t)
				card:setAnimPos(0, 0, v)
			end,
			id=card.id
		}
	end
end)
--]]