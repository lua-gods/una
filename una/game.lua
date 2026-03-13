local Sync = require("./sync") ---@module "una.sync"
local Card = require("./card") ---@type CardAPI
local Macro = require("./lib/macro") ---@type MacroAPI
local Tween = require("una.lib.tween")

local hostName = avatar:getEntityName()

events.TICK:register(function ()
	hostName = player:getName()
	events.TICK:remove("hostNameGetter")
end,"hostNameGetter")

---@class UNA.Game
local Game = {
	pos = vec(0, 0, 0)
}

Sync.events.POSITION_CHANGE:register(function (pos)
	Card.ROOT_MODEL:setPos(pos*16)
end)


local function setPlayerList(toggle)
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
	:setLabel(host:isHost() and "Start" or "Join",0.66)
	
	Sync.events.PLAYER_JOIN:register(function (name) setPlayerList(true)end, 'IntermissionPlayerJoin')
	Sync.events.PLAYER_LEAVE:register(function (name)setPlayerList(true)end, 'IntermissionPlayerLeave')
	if host:isHost() then
		startBtn.PRESSED:register(function (name)
			if name == hostName then
				Sync.setGameState(2)
			else -- join instead
   			Sync.addPlayer(name)
			end
		end)
		exitBtn.PRESSED:register(function (name)
   		if name == hostName then
            Sync.resetGame()
			else
			   Sync.removePlayer(name)
         end
		end)

   	Sync.addPlayer(hostName)
	end

	events.ON_EXIT:register(function ()
		Card.applyToCardWithTag("joinHud",function (card) card:free() end)
		setPlayerList(false)
		startBtn:free()
		exitBtn:free()
		Sync.events.PLAYER_JOIN:remove('IntermissionPlayerJoin')
      Sync.events.PLAYER_LEAVE:remove('IntermissionPlayerLeave')
	end)
end)


--[────────────────────────────────────────-< Game >-────────────────────────────────────────]--

local sceneGame = Macro.new(function (events, ...)
	---@type {[string]: {[number]: Card[]}}
	local cardInventory = {}
	---@type Card[]
	local cardsStack = {}

	---@type {[string]: true}
	local playersCardsToUpdate = {}

	local drawCard = Card.new()
	drawCard:setPos(-1, 0, 0)
		:setLabel("draw", 0.66)

	drawCard.PRESSED:register(function(name)
		if Sync.getPlayerIndex(name) then
			Sync.drawCard(name)
		end
	end)
	--  Card.new()
	-- :setPos(0,0,0)
	-- :setTag("stack")
	-- :setColor(3)
	-- :setType(1)
	-- :setLabel("Stack",0.66)

	-- local drop = Card.new()
	-- :setPos(1,0,0)
	-- :setTag("drop")
	-- :setColor(2)
	-- :setType(1)
	-- :setLabel("drop",0.66)

	local function updateCards(name)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		local inv = cardInventory[name]
		local invI = {}
		local cardsList = Sync.getCards(name)
		local playerIndex = Sync.getPlayerIndex(name) or -1
		for i, cardId in ipairs(cardsList) do
			if not inv[cardId] then
				inv[cardId] = {}
			end
			if not invI[cardId] then
				invI[cardId] = 0
			end
			invI[cardId] = invI[cardId] + 1

			local card = inv[cardId][ invI[cardId] ]
			if card then
				-- local oldPos = card.pos
				-- local newPos = vec(i * 0.5, 0.5, 0.5)
				-- card:setPos(i * 0.5, 0.5, 0)
				card:setScale(0.5, 0.5, 0.5)

				Tween.new{
					id = "una.card."..card.id,
					from = card.pos,
					to = vec(i * 0.5, 0.5, playerIndex * 0.5),
					duration = 0.25,
					easing = "outCubic",
					tick = function(v, t)
						card:setPos(v)
					end
				}

				card.PRESSED:clear()
				card.PRESSED:register(function(name2)
					if name2 ~= name then -- you can only click own cards
						return
					end
					if Sync.getCurrentPlayer() ~= name then -- not your turn!!
						-- return
					end
					-- print(name, i)
					Sync.dropCard(name, i)
				end)
			else
				print("panic ", name, cardId, "missing")
			end
		end
	end

	local function requestCardUpdate(name)
		playersCardsToUpdate[name] = true
	end

	Sync.events.CARD_DRAWED:register(function(name, cardId)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		print("CARD DRAWED", name, cardId)
		local inv = cardInventory[name]
		if not inv[cardId] then
			inv[cardId] = {}
		end
		local card = Card.new()
		local type,color = Card.fullIdToColorAndTypeId(cardId)
		card:setType(type)
			:setColor(color)

		table.insert(inv[cardId], card)

		requestCardUpdate(name)
	end)

	Sync.events.CARD_DROPPED:register(function(name, cardIdx, cardId)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		print("CARD DROPPED", name, cardIdx, cardId)
		local inv = cardInventory[name]
		local card = nil
		if inv[cardId] then
			card = table.remove(inv[cardId])
			if #inv[cardId] == 0 then
				inv[cardId] = nil
			end
			card.PRESSED:clear()
			print("CARD REUSED")
		end
		requestCardUpdate(name)

		if not card then
			local card = Card.new()
			local type,color = Card.fullIdToColorAndTypeId(cardId)
			card:setType(type)
			card:setColor(color)
			card:setPos(0, 1, 0)
			card:setScale(0, 0, 0)
			print("NO CARD FOUND")
		end
		table.insert(cardsStack, card)

		local oldScale = card.scale
		local targetScale = vec(1, 1, 1)
		Tween.new{
			id = "una.card."..card.id,
			from = card.pos,
			to = vec(0, #cardsStack * 0.1, 0),
			duration = 0.5,
			easing = "outQuint",
			tick = function(v, t)
				local y = 1 - (2 * t - 1) ^ 2
				card:setPos(v + vec(0, y * 0.5, 0))
				card:setScale(math.lerp(oldScale, targetScale, t))
			end
		}
	end)

	Sync.events.CARD_REMOVED:register(function(name, cardId)
		print("CARD REMOVED", name, cardId)
		local inv = cardInventory[name]
		if inv and inv[cardId] then
			local card = table.remove(inv[cardId])
			if card then
				card:free()
			end
			if #inv[cardId] == 0 then
				inv[cardId] = nil
			end
		end
		requestCardUpdate(name)
	end)
	
	for i, name in ipairs(Sync.getPlayersOrder()) do
		for i = 1, 7, 1 do
			Sync.drawCard(name)
		end
		Sync.removeCard(name, 1)
	end

	events.TICK:register(function()
		for name in pairs(playersCardsToUpdate) do
			updateCards(name)
		end
		playersCardsToUpdate = {}
	end)

	-- local players = sync.getPlayersData()
	-- for i, name in ipairs(sync.getPlayersOrder()) do
	-- 	local inv = {}
	-- 	for k, value in ipairs(sync.getCards(name)) do
	-- 		local type,color = Card.fullIdToColorAndTypeId(value)
	-- 		local card = Card.new()
	-- 		card:setPos(k * 0.5,i * 0.5,0)
	-- 			:setType(type)
	-- 			:setColor(color)
	-- 			:setScale(0.5, 0.5, 0.5)
	-- 		inv[k] = card
	-- 	end
	-- 	cardInventory[name] = inv
	-- end

	events.ON_EXIT:register(function ()
		drawCard:free()
		for _, card in pairs(cardsStack) do
			card:free()
		end
		for name, groups in pairs(cardInventory) do
		   for _, cards in pairs(groups) do
				for _, card in pairs(cards) do
					card:free()
				end
			end
		end
	end)
end)


Sync.events.GAME_STATE_CHANGE:register(function (state, last)
	sceneIntermission:setActive(state == 1)
	sceneGame:setActive(state == 2)
end)

---@param pos Vector3
function Game.start(pos)
   Sync.setGamePos(pos + vec(0.5, 0, 0.5))
   Sync.setGameState(1)
end

if host:isHost() then
	Game.start(client.getViewer():getTargetedBlock():getPos():add(0, 1, 0))
   -- Game.start(vec(1997792, 68, 1999644))
end

return Game