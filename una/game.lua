local Sync = require("./sync") ---@module "una.sync"
local Card = require("./card") ---@type CardAPI

---@class UNA.Game
local Game = {
	pos = vec(-8, 1, -1)
}

Sync.events.POSITION_CHANGE:register(function (pos)
	Card.ROOT_MODEL:setPos(pos*16)
end)

Sync.setGamePos(Game.pos + vec(0.5,0,0.5))


local function togglePlayerList(toggle)
	Card.applyToCardWithTag("playerList",function (card) card:free() end)
	if toggle then
		local players = Sync.getPlayersOrder()
		local count = #players
		local radius = count*0.25+1
		for i = 1, count, 1 do
			local e = (i / count) * math.pi * 2
			local player = Card.new()
			:setPos(math.sin(e)*radius,1,math.cos(e)*radius)
			:setTag("playerList")
			:setColor(2)
			:setType(1)
			:setRot(-90,i/count*360,0)
			:setLabel(players[i],0.66)
		end
	end
end
Sync:setCurrentPlayer()

Sync.events.GAME_STATE_CHANGE:register(function (state, last)
	if last == 2 then
		Card.applyToCardWithTag("joinHud",function (card) card:free() end)
		togglePlayerList(false)
	end
	if state == 2 then
		local joinBtn = Card.new()
		:setPos(0.5,0,0)
		:setTag("joinHud")
		:setColor(3)
		:setType(1)
		:setLabel("Join",0.66)
		
		local exitBtn = Card.new()
		:setPos(-0.5,0,0)
		:setTag("joinHud")
		:setColor(1)
		:setType(1)
		:setLabel("Exit",0.66)
		
		joinBtn.PRESSED:register(function (name)
			Sync.addPlayer(name)
			togglePlayerList(true)
		end)
		exitBtn.PRESSED:register(function (name)
			Sync.removePlayer(name)
			togglePlayerList(true)
		end)
	end
end)


Sync.setGameState(2)



return Game