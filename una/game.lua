local sync = require("./sync") ---@module "una.sync"
local Card = require("./card") ---@type CardAPI

---@class UNA.Game
local Game = {
	pos = vec(299766, 80, 300109)
}

sync.events.POSITION_CHANGE:register(function (pos)
	Card.ROOT_MODEL:setPos(pos*16)
end)

sync.setGamePos(Game.pos + vec(0.5,0,0.5))


local function togglePlayerList(toggle)
	Card.applyToCardWithTag("playerList",function (card) card:free() end)
	if toggle then
		local players = sync.getPlayersOrder()
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
sync:setCurrentPlayer()

sync.events.GAME_STATE_CHANGE:register(function (state, last)
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
		
		if host:isHost() then
			joinBtn.PRESSED:register(function (name)
				sync.addPlayer(name)
				togglePlayerList(true)
			end)
			exitBtn.PRESSED:register(function (name)
				sync.removePlayer(name)
				togglePlayerList(true)
			end)
		else
			sync.events.PLAYER_JOIN:register(function (name) togglePlayerList(true)end)
			sync.events.PLAYER_LEAVE:register(function (name)togglePlayerList(true)end)
		end
	end
end)


sync.setGameState(2)



return Game