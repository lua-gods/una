local Card = require("una.card")
local Tween = require("una.lib.tween")

---@param card Card
Card.CARD_PRESSED:register(function (card)
	sounds:playSound("minecraft:item.book.page_turn", Card.ROOT_MODEL:getPos() / 16 + card.pos, 0.5, 1.5)
	Tween.new{
		from = 1.1,
		to = card.lastHoverAnim == "scale" and 1.05 or 1,
		duration = 0.3,
		easing = "outBack",
		tick = function (v, t)
			card:setAnimScale(v,v,v)
		end,
		id="click."..card.idx
	}
end)

---@type table<string, fun(card: Card, t: number)>
local hoverAnims = {
	up = function(card, t)
		card:setAnimPos(0, 0, t * 0.1)
	end,
	scale = function(card, t)
		local s = 1 + t * 0.05
		card:setAnimScale(s, s, s)
	end,
	none = function() end,
}

---@param card Card
---@param hovered boolean
local function hoverCardAnim(card, hovered)
	local animName = card.hoverAnim or "scale"
	local anim = hoverAnims[animName]
	local lastAnim = hoverAnims[card.hoverAnim]
	if not (anim or lastAnim) then return end
	if hovered then
		card.lastHoverAnim = animName
	else
		card.lastHoverAnim = nil
	end
	anim = anim or hoverAnims.none
	lastAnim = lastAnim or hoverAnims.none
	local from = hovered and 0 or 1
	local to = 1 - from
	Tween.new{
		from = from,
		to = to,
		duration = 0.3,
		easing = "outBack",
		tick = function (v, t)
			anim(card, v)
			lastAnim(card, v)
		end,
		id="hover."..card.idx
	}
end

Card.CARD_HOVER:register(function(card, lastCard)
	if lastCard then
		hoverCardAnim(lastCard, false)
	end
	if card then
		hoverCardAnim(card, true)
	end
end)