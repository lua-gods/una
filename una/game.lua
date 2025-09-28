local sync = require("./sync") ---@module "una.sync"
local Card = require("./card") ---@type CardAPI
local Macro = require("./lib/macro") ---@type MacroAPI

local hostName = ""

events.TICK:register(function ()
	hostName = player:getName()
	events.TICK:remove("hostNameGetter")
end,"hostNameGetter")

---@class UNA.Game
local Game = {
	pos = vec(299772, 79, 300105)
}

sync.events.POSITION_CHANGE:register(function (pos)
	Card.ROOT_MODEL:setPos(pos*16)
end)

sync.setGamePos(Game.pos + vec(0.5,0,0.5))


local function setPlayerList(toggle)
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
			:setColor(5)
			:setType(1)
			:setRot(-90,i/count*360,0)
			:setLabel(players[i],0.66)
		end
	end
end

--[[
local scene1 = Macro.new(function (events, ...)
	
	events.ON_EXIT:register(function ()
	end)
end)
]]

local sceneIntermission = Macro.new(function (events, ...)
	local joinBtn = Card.new()
	:setPos(1,0,0)
	:setTag("joinHud")
	:setColor(3)
	:setType(1)
	:setLabel("Join",0.66)
	
	local exitBtn = Card.new()
	:setPos(-1,0,0)
	:setTag("joinHud")
	:setColor(1)
	:setType(1)
	:setLabel("Exit",0.66)
	
	local startBtn = Card.new()
	:setPos(0,0,0)
	:setTag("joinHud")
	:setColor(2)
	:setType(1)
	:setLabel("Start",0.66)
	
	if host:isHost() then
		startBtn.PRESSED:register(function (name)
			if name == hostName then
				sync.setGameState(3)
			end
		end)
		joinBtn.PRESSED:register(function (name)
			sync.addPlayer(name)
		end)
		exitBtn.PRESSED:register(function (name)
			sync.removePlayer(name)
		end)
	end
	sync.events.PLAYER_JOIN:register(function (name) setPlayerList(true)end)
	sync.events.PLAYER_LEAVE:register(function (name)setPlayerList(true)end)
	
	events.ON_EXIT:register(function ()
		Card.applyToCardWithTag("joinHud",function (card) card:free() end)
		setPlayerList(false)
		startBtn:free()
		joinBtn:free()
		exitBtn:free()
	end)
end)


--[────────────────────────────────────────-< Game >-────────────────────────────────────────]--

local sceneGame = Macro.new(function (events, ...)
	local cardInventory = {}
	
	local stack = Card.new()
	:setPos(0,0,0)
	:setTag("stack")
	:setColor(3)
	:setType(1)
	:setLabel("Stack",0.66)
	
	local drop = Card.new()
	:setPos(1,0,0)
	:setTag("drop")
	:setColor(2)
	:setType(1)
	:setLabel("Stack",0.66)
	
	for i, name in ipairs(sync.getPlayersOrder()) do
		for i = 1, 10, 1 do
			sync.drawCard(name)
		end
	end
	
	local players = sync.getPlayersData()
	for i, name in ipairs(sync.getPlayersOrder()) do
		local inv = {}
		for i, value in ipairs(sync.getCards(name)) do
			local type,color = Card.fullIdToColorAndTypeId(value)
			inv[i] = Card.new():setPos(i,0,0):setType(type):setColor(color)
		end
		cardInventory[name] = inv
	end
	
	events.ON_EXIT:register(function ()
		stack:free()
		drop:free()
	end)
end)


sync.events.GAME_STATE_CHANGE:register(function (state, last)
	sceneIntermission:setActive(state == 2)
	sceneGame:setActive(state == 3)
end)


sync.setGameState(2)



return Game