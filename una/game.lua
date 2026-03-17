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
   	-- Sync.addPlayer("billy")
		-- local a = 0
		-- events.TICK:register(function()
		-- 	a = a + 1
		-- 	if a == 5 then
		-- 		Sync.setGameState(2)
		-- 	end
		-- end)
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
	local viewerName = client.getViewer():getName()
	local myDroppedCardI = 1

	---@type {[string]: {[number]: Card[]}}
	local cardInventory = {}

	local cardStackHeight = 0

	---@type {[string]: true}
	local playersCardsToUpdate = {}

	local function nextPlayer()
		Sync.setCurrentPlayer(Sync.getCurrentPlayerIndex() + 1)
		-- print("next turn", Sync.getCurrentPlayer())
	end

	---sets card, hide it if its other's player
	---@param name string
	---@param card Card
	---@param cardId number
	local function setCardStyle(name, card, cardId)
		if name == viewerName or name == "!" then
			local type, color = Card.fullIdToTypeAndColor(cardId)
			card:setType(type)
				:setColor(color)
			return
		end
		card:setType(17)
			:setColor(math.random(5))
	end

	local function makeDrawCard()
		local card = Card.new()
		card:setPos(-1, 0.05, 0)
			:setRot(0, 0, 180)
			:setType(17)
			:setColor(5)

		card.PRESSED:register(function(name)
			if Sync.getCurrentPlayer() == name then
				Sync.drawCard(name)
				nextPlayer()
			end
		end)

		return card
	end

	local drawCard = makeDrawCard()

	---@type Card[]
	local colorChoiceCards = {}

	---@param card Card
	local function removeCard(card)
		Tween.new{
			id = "una.card."..card.id,
			from = card.scale,
			to = vec(0, 0, 0),
			duration = 0.5,
			easing = "inCubic",
			tick = function(v, t)
				card:setScale(v)
			end,
			onFinish = function()
				card:free()
			end
		}
	end

	local function updateCards(name)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		local inv = cardInventory[name]
		local invI = {}
		local cardsList = Sync.getCards(name)
		local playerIndex = Sync.getPlayerIndex(name) or -1
		local playerRot = 0
		local cardsRowLimit = 10
		local cardsCount = #cardsList
		local lastRowStart = math.floor(cardsCount / cardsRowLimit) * cardsRowLimit
		local lastRowLength = cardsCount - lastRowStart
		-- sort cards
		local cardsSorted = {}
		for i, cardId in ipairs(cardsList) do
			cardsSorted[i] = cardId * 10000 + i
		end
		if name == "!" then
			cardStackHeight = 0
		else
			table.sort(cardsSorted)
		end
		-- update cards
		for i, cardId in ipairs(cardsSorted) do
			local k = cardId % 10000
			cardId = math.floor(cardId / 10000)
			if not inv[cardId] then
				inv[cardId] = {}
			end
			invI[cardId] = (invI[cardId] or 0) + 1
			local myInvI = invI[cardId]

			local card = inv[cardId][ myInvI ]
			if not card then
				card = Card.new()
				local type, color = Card.fullIdToTypeAndColor(cardId)
				card:setType(type)
					:setColor(color)
				table.insert(inv[cardId], card)
			end
				-- local oldPos = card.pos
				-- local newPos = vec(i * 0.5, 0.5, 0.5)
				-- card:setPos(i * 0.5, 0.5, 0)

			local targetPos = vec(0, 0, 0)
			local targetScale = vec(0.5, 0.5, 0.5)
			local targetRot = vec(0, 0, 0)
			if name == "!" then
				targetPos = vec(0, k * 0.025, 0)
				targetScale = vec(1, 1, 1)
				cardStackHeight = math.max(cardStackHeight, targetPos.y)
			else
				local x = (i - 1) % cardsRowLimit
				local y = math.floor((i - 1) / cardsRowLimit)
				local rowSize = i > lastRowStart and lastRowLength or cardsRowLimit
				local cardRot = (x - rowSize * 0.5 + 0.5) * 0.24
				local pos = vec(-math.cos(cardRot), 0, -math.sin(cardRot))
				pos.y = y * 0.5
				pos = vectors.rotateAroundAxis(playerRot, pos + vec(2, 0.5, 0), vec(0, 1, 0))
				targetPos = pos
				targetRot = vec(-90, playerRot - math.deg(cardRot) - 90, 0)
				if rowSize ~= 1 then
					targetRot.y = targetRot.y - 10
				end
			end

			local oldScale = card.scale
			local oldRot = card.rot
			Tween.new{
				id = "una.card."..card.id,
				from = card.pos,
				to = targetPos,
				duration = 0.25,
				easing = "outCubic",
				tick = function(v, t)
					card:setPos(v)
					card:setScale(math.lerp(oldScale, targetScale, t))
					card:setRot(math.lerp(oldRot, targetRot, t))
				end
			}

			if name ~= "!" then
				card.PRESSED:clear()
				card.PRESSED:register(function(name2)
					if name2 ~= name then -- you can only click own cards
						return
					end
					if Sync.getCurrentPlayer() ~= name then -- not your turn!!
						return
					end
					local cardsStack = Sync.getCards("!")
					local topCard = cardsStack[#cardsStack]
					local topType,topColor = Card.fullIdToTypeAndColor(topCard)
					local type,color = Card.fullIdToTypeAndColor(cardId)
					local currentColor = Sync.getColor()
					if currentColor == 6 then
						return
					end
					if not (color == 5 or color == currentColor or topType == type) then
						return
					end
					if name == viewerName then
						myDroppedCardI = myInvI
					end
					Sync.dropCard(name, k)
					if color == 5 then
						Sync.setColor(6)
					else
						Sync.setColor(color)
						nextPlayer()
					end
					-- print(name, i)
				end)
			end
		end
		-- remove unused cards
		for cardId, cards in pairs(inv) do
			local maxCards = invI[cardId] or 0
			for _ = #cards, maxCards + 1, -1 do
				removeCard(table.remove(cards))
			end
			if #cards == 0 then
				inv[cardId] = nil
			end
		end
	end

	local function requestCardUpdate(name)
		playersCardsToUpdate[name] = true
	end

	local function cleanupCardsStack()
		local cardsCount = #Sync.getRawCards("!")
		local cardsToRemove = math.max(cardsCount - 10)
		for _ = 1, cardsToRemove do
			Sync.removeCard("!", 1)
		end
	end

	local function drawCardToPlayer(name, cardId)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		-- print("CARD DRAWED", name, cardId)
		local inv = cardInventory[name]
		if not inv[cardId] then
			inv[cardId] = {}
		end
		
		drawCard.PRESSED:clear()
		setCardStyle(name, drawCard, cardId)

		table.insert(inv[cardId], drawCard)

		drawCard = makeDrawCard()

		requestCardUpdate(name)
	end

	Sync.events.CARD_DRAWED:register(function(name, cardId)
		if host:isHost() then
			Sync.setNextCard(Card.getRandomCard())
		end
		drawCardToPlayer(name, cardId)
		if name == "!" then
			cleanupCardsStack()
		end
	end, "gameCardDrawed")

	Sync.events.CARD_DROPPED:register(function(name, cardIdx, cardId)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		-- print("CARD DROPPED", name, cardIdx, cardId)
		local inv = cardInventory[name]
		local card = nil
		if inv[cardId] then
			local i = #inv[cardId]
			if name == viewerName then
				i = math.clamp(myDroppedCardI, 1, i)
			end
			card = table.remove(inv[cardId], i)
			if #inv[cardId] == 0 then
				inv[cardId] = nil
			end
			card.PRESSED:clear()
			-- print("CARD REUSED")
		end

		if not card then
			card = Card.new()
			card:setPos(0, 1, 0)
			card:setScale(0, 0, 0)
		end
		setCardStyle("!", card, cardId)
		-- table.insert(cardsStack, card)
		if not cardInventory["!"] then
			cardInventory["!"] = {}
		end
		local metaInv = cardInventory["!"]
		if not metaInv[cardId] then
			metaInv[cardId] = {}
		end
		table.insert(metaInv[cardId], card)

		requestCardUpdate(name)
		requestCardUpdate("!")
		cleanupCardsStack()
	end, "gameCardDropped")

	Sync.events.CARD_REMOVED:register(function(name, cardId)
		-- print("CARD REMOVED", name, cardId)
		local inv = cardInventory[name]
		if inv and inv[cardId] then
			local card = table.remove(inv[cardId])
			if card then
				removeCard(card)
			end
			if #inv[cardId] == 0 then
				inv[cardId] = nil
			end
		end
		requestCardUpdate(name)
	end, "gameCardRemoved")

	Sync.events.COLOR_CHANGE:register(function(color)
		for _, card in pairs(colorChoiceCards) do
			card.PRESSED:clear()
			local pos = card.pos
			local scale = card.scale
			Tween.new{
				duration = 0.4,
				from = 1,
				to = 0,
				easing = "outCubic",
				tick = function(v, t)
					card:setScale(v * scale)
					card:setPos(pos.x * v, pos.y, pos.z * v)
				end,
				onFinish = function()
					card:free()
				end
			}
		end
		colorChoiceCards = {}
		if color ~= 6 then
			return
		end
		for i = 1, 4 do
			local x = i % 2 - 0.5
			local y = math.floor((i - 1) / 2) - 0.5
			local scale = 0.5
			local card = Card.new()
			local height = cardStackHeight + 0.1
			local pos = vec(-x * 0.75 * scale, 0, -y * scale) * 1.1
			card:setColor(i)
				:setType(1)
			colorChoiceCards[i] = card
			card.PRESSED:register(function(name)
				if Sync.getCurrentPlayer() ~= name then
					return
				end
				Sync.setColor(i)
				nextPlayer()
			end)
			Tween.new{
				duration = 0.5,
				from = 0,
				to = 1,
				easing = "outCubic",
				tick = function(v, t)
					local s = v * scale
					card:setScale(s, s, s)
					card:setPos(pos * v + vec(0, height, 0))
				end
			}
		end
	end, "gameColorChanged")

	if host:isHost() then
		local color = math.random(1, 4)
		local cardType = math.random(2, 11)
		Sync.drawCard(
			"!",
			Card.typeAndColorToFullId(
				cardType,
				color
			)
		)
		Sync.setColor(color)
	end

	if host:isHost() then
		for i, name in ipairs(Sync.getPlayersOrder()) do
			for k = 1, 7, 1 do
				Sync.drawCard(name, Card.getRandomCard())
			end
		end
	end

	events.TICK:register(function()
		for name in pairs(playersCardsToUpdate) do
			updateCards(name)
		end
		playersCardsToUpdate = {}
		-- Sync.drawCard("AuriaFoxGirl")
	end)

	events.ON_EXIT:register(function ()
		drawCard:free()
		for name, groups in pairs(cardInventory) do
		   for _, cards in pairs(groups) do
				for _, card in pairs(cards) do
					card:free()
				end
			end
		end
		Sync.events.CARD_DRAWED:remove('gameCardDrawed')
		Sync.events.CARD_DROPPED:remove('gameCardDropped')
		Sync.events.CARD_REMOVED:remove('gameCardRemoved')
		Sync.events.COLOR_CHANGE:remove('gameColorChanged')
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
	Game.start(client.getViewer():getTargetedBlock(true, 5):getPos():add(0, 1, 0))
   -- Game.start(vec(1997792, 68, 1999644))
end

return Game