local Card = require("una.card")
local Tween = require("una.lib.tween")

---@param card Card
Card.CARD_CLICKED:register(function (card)
	sounds:playSound("minecraft:item.book.page_turn", card.pos, 1, 1.5)
	Tween.new{
		from = 1.1,
		to = 1,
		duration = 0.3,
		easing = "outBack",
		tick = function (v, t)
			card:setScale(v,v,v)
		end,
		id=card.id
	}
end)


local card = Card.new()
:setPos(299777.5, 78, 300121.5)

function pings.cardClick(pos)
	Tween.new{
			from = pos,
			to = pos+vec(0,0.1,0),
			duration = 0.2,
			easing = "linear",
			tick=function (v, t)
				card:setPos(v)
			end,
			id=card.id.."ee"
		}
end

if host:isHost() then
	card.CARD_CLICKED:register(function ()
		pings.cardClick(card.pos)
	end)
end
