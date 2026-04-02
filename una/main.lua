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
		id="click."..card.idx
	}
end)

--[[ -- DEBUG
function pings.run(code)
   local func, syntaxErr = load(code)
   if host:isHost() then
      if syntaxErr then
         print(syntaxErr)
      else
         local success, err = pcall(func)
         if not success then
            print(err)
         end
      end
   else
      pcall(func)
   end
end

function events.tick()
	for _, entity in pairs(world.getPlayers()) do
		if entity:getSwingTime() == 1 then
			local camPos = client.getCameraPos()
			local pos = entity:getPos() + vec(0, entity:getEyeHeight(), 0)
			local _, hitPos = entity:getTargetedBlock(true)
			local a = (camPos - pos):length() < 0.2 and 1 or 0
			---@diagnostic disable-next-line: count-down-loop
			for i = a, 1, 0.1 do
				particles['end_rod']
					:lifetime(40)
					:gravity(0)
					:pos(math.lerp(pos, hitPos, i))
					:spawn()
			end
		end
	end
end
--]]

---@type table<string, fun(card: Card, t: number)>
local hoverAnims = {
	up = function(card, t)
		card:setAnimPos(0, 0, t * 0.1)
	end
}

---@param card Card
---@param hovered boolean
local function hoverCardAnim(card, hovered)
	local anim = hoverAnims[card.hoverAnim]
	if not anim then return end
	local from = hovered and 0 or 1
	local to = 1 - from
	Tween.new{
		from = from,
		to = to,
		duration = 0.3,
		easing = "outBack",
		tick = function (v, t)
			anim(card, v)
		end,
		id="hover."..card.idx
	}
end

local lastCard
Card.CARD_HOVER:register(function(card)
	if lastCard then
		hoverCardAnim(lastCard, false)
	end
	lastCard = card
	if card then
		hoverCardAnim(card, true)
	end
end)