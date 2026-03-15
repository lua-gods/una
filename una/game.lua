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

	---@type {[string]: true}
	local playersCardsToUpdate = {}

	local function makeDrawCard()
		local card = Card.new()
		card:setPos(-1, 0.05, 0)
			:setRot(0, 0, 180)

		card.PRESSED:register(function(name)
			if Sync.getPlayerIndex(name) then
				Sync.drawCard(name)
			end
		end)

		return card
	end

	local drawCard = makeDrawCard()

	---@type Card[]
	local colorChoiceCards = {}

	---@param card Card
	local function removeCard(card)
		local oldScale = card.scale
		local rot = card.rot
		Tween.new{
			id = "una.card."..card.id,
			from = card.pos,
			to = card.pos + vec(0, 1, 0),
			duration = 1,
			easing = "inCubic",
			tick = function(v, t)
				card:setPos(v + vec(0, t * 0.25, 0))
				card:setScale(oldScale * (1 - t))
				card:setRot(rot + vec(0, 360 * t, 0))
			end,
			onFinish = function()
				card:free()
			end
		}
	end
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
		-- sort cards
		local cardsSorted = {}
		for i, cardId in ipairs(cardsList) do
			cardsSorted[i] = cardId * 10000 + i
		end
		table.sort(cardsSorted)
		-- update cards
		for i, cardId in ipairs(cardsSorted) do
			local k = cardId % 10000
			cardId = math.floor(cardId / 10000)
			if not inv[cardId] then
				inv[cardId] = {}
			end
			if not invI[cardId] then
				invI[cardId] = 0
			end
			invI[cardId] = invI[cardId] + 1

			local card = inv[cardId][ invI[cardId] ]
			if not card then
				card = Card.new()
				local type, color = Card.fullIdToColorAndTypeId(cardId)
					card:setType(type)
					:setColor(color)
				table.insert(invI[cardId], card)
				print("panic ", name, cardId, "missing, adding card")
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
			else
				targetPos = vec(i * 0.25, 0.5, playerIndex * 0.5)
				targetRot = vec(0, -5, -5)
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
					local topType,topColor = Card.fullIdToColorAndTypeId(topCard)
					local type,color = Card.fullIdToColorAndTypeId(cardId)
					local currentColor = Sync.getColor()
					if currentColor == 6 then
						return
					end
					if not (color == 5 or color == currentColor or topType == type) then
						return
					end
					Sync.dropCard(name, k)
					if color == 5 then
						Sync.setColor(6)
					else
						Sync.setColor(color)
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
	
		local type,color = Card.fullIdToColorAndTypeId(cardId)
		drawCard:setType(type)
			:setColor(color)

		table.insert(inv[cardId], drawCard)

		drawCard = makeDrawCard()

		requestCardUpdate(name)
	end

	Sync.events.CARD_DRAWED:register(function(name, cardId)
		drawCardToPlayer(name, cardId)
	end)

	Sync.events.CARD_DROPPED:register(function(name, cardIdx, cardId)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		-- print("CARD DROPPED", name, cardIdx, cardId)
		local inv = cardInventory[name]
		local card = nil
		if inv[cardId] then
			card = table.remove(inv[cardId])
			if #inv[cardId] == 0 then
				inv[cardId] = nil
			end
			card.PRESSED:clear()
			-- print("CARD REUSED")
		end

		if not card then
			local card = Card.new()
			local type,color = Card.fullIdToColorAndTypeId(cardId)
			card:setType(type)
			card:setColor(color)
			card:setPos(0, 1, 0)
			card:setScale(0, 0, 0)
			-- print("NO CARD FOUND")
		end
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
	end)

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
	end)

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
			local height = 0.5
			local pos = vec(-x * 0.75 * scale, 0, -y * scale) * 1.1
			card:setColor(i)
				:setType(1)
			colorChoiceCards[i] = card
			card.PRESSED:register(function(name)
				if Sync.getCurrentPlayer() ~= name then
					return
				end
				Sync.setColor(i)
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
	end)

	do
		local color = math.random(1, 4)
		local cardType = math.random(2, 11)
		Sync.drawCard(
			"!",
			Card.colorAndTypeIdToFullId(
				cardType,
				color
			)
		)
		Sync.setColor(color)
	end

	for i, name in ipairs(Sync.getPlayersOrder()) do
		for k = 1, 70, 1 do
			-- Sync.drawCard(name, Card.colorAndTypeIdToFullId(math.random(2, 11), math.random(1, 4)))
			-- Sync.drawCard(name)
		end
		Sync.drawCard(name, Card.colorAndTypeIdToFullId(1, 1))
		Sync.drawCard(name, Card.colorAndTypeIdToFullId(2, 5))
	end

	events.TICK:register(function()
		for name in pairs(playersCardsToUpdate) do
			updateCards(name)
		end
		playersCardsToUpdate = {}
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