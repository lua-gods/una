local Sync = require("./sync") ---@module "una.sync"
local Card = require("./card") ---@type CardAPI
local Macro = require("./lib/macro") ---@type MacroAPI
local Tween = require("una.lib.tween")

local hostName = avatar:getEntityName()

local worldModel = models:newPart("unaGameWorld", "WORLD")

events.TICK:register(function ()
	hostName = player:getName()
	events.TICK:remove("hostNameGetter")
end,"hostNameGetter")

---@class UNA.Game
local Game = {
	pos = vec(0, 0, 0)
}

Sync.events.POSITION_CHANGE:register(function (pos)
	Card.ROOT_MODEL:setPos(pos * 16)
	worldModel:setPos(pos * 16)
	Game.pos = pos
end)

---@param card Card
local function removeCard(card)
	Tween.new{
		id = "una.card."..card.idx,
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

--[[
local scene1 = Macro.new(function (events, ...)
	
	events.ON_EXIT:register(function ()
	end)
end)
]]

local sceneIntermission = Macro.new(function (events, ...)
	local shakingCard = nil
	local shakingStrength = 0
	local oldShakingStrength = 0
	local exitBtn = Card.new()
		:setTag("joinHud")
		:setLabel("Exit",0.66)
		:setColor(1)
		:setType(1)
		:setPos(0,0,0)
		:setScale(0,0,0)
	
	local startBtn = Card.new()
		:setTag("joinHud")
		:setColor(2)
		:setType(1)
		:setLabel(host:isHost() and "Start" or "Join",0.66)
		:setScale(0,0,0)
		:setPos(0,0,0)
	
	Tween.new{
		from = 0,
		to = 1,
		duration = 0.5,
		easing = "outExpo",
		tick = function(v, t)
			startBtn:setScale(v, v, v)
				:setPos(0, (1 - v) * 0.1, 0)
			exitBtn:setScale(v, v, v)
		end
	}
	Tween.new{
		from = -0.2,
		to = 1,
		duration = 0.5,
		easing = "outCubic",
		tick = function(v, t)
			exitBtn:setPos(-v, 0, 0)
		end
	}

	local playerListCards = {}
	local function setPlayerList()
		local newCards = {}
		local players = Sync.getPlayersOrder()
		local count = #players
		local radius = count*0.25+1
		for i, name in ipairs(players) do
			local angle = ((i - 1) / count) * 360
			local rad = math.rad(angle)
			local pos = vec(math.sin(rad)*radius,1,math.cos(rad)*radius)
			local rot = vec(-90, angle, 0)
			local scale = vec(1, 1, 1)
			local card = playerListCards[name]
			if card then
				playerListCards[name] = nil
			else
				card = Card.new()
				card:setTag("playerList")
					:setColor(5)
					:setType(1)
					:setLabel(players[i],0.66)
					:setPos(pos)
					:setRot(rot)
					:setScale(0, 0, 0)
					:setOwner(hostName)

				card.PRESSED:register(function()
					if name == hostName then
						return
					end
					Sync.removePlayer(name)
					card.PRESSED:clear()
				end)
				card.CARD_HOVER:register(function(v)
					if name == hostName then
						return
					end
					if v then
						shakingCard = card
						shakingStrength = 0
						oldShakingStrength = 0
						return
					end
					if shakingCard == card then
						shakingCard = nil
					end
					local rot = card.animRot
					local pos = card.animPos
					Tween.new{
						duration = 0.2,
						from = 1,
						to = 0,
						tick = function(v, t)
							card:setAnimRot(rot * v)
								:setAnimPos(pos * v)
						end
					}
				end)
			end
			newCards[name] = card
			local oldPos = card.pos
			local oldRot = card.rot
			local oldScale = card.scale
			Tween.new{
				id = "una.card."..card.idx,
				from = 0,
				to = 1,
				duration = 0.5,
				easing = "inOutCubic",
				tick = function(v, t)
					card:setPos(math.lerp(oldPos, pos, v))
						:setRot(math.lerp(oldRot, rot, v))
						:setScale(math.lerp(oldScale, scale, v))
				end,
			}
		end
		for _, card in pairs(playerListCards) do
			removeCard(card)
		end
		playerListCards = newCards
	end
	
	Sync.events.PLAYER_JOIN:register(function (name) setPlayerList()end, 'IntermissionPlayerJoin')
	Sync.events.PLAYER_LEAVE:register(function (name)setPlayerList()end, 'IntermissionPlayerLeave')
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
   	-- Sync.addPlayer("kitty")
   	-- Sync.addPlayer("meow")
		-- local a = 0
		-- events.TICK:register(function()
		-- 	a = a + 1
		-- 	if a == 5 then
		-- 		Sync.setGameState(2)
		-- 	end
		-- end)
	end

	local timer = 0
	local targetShakingStrength = 0
	events.TICK:register(function()
		timer = timer + 1
		if timer % 10 == 0 then
			targetShakingStrength = math.random() * 0.5 + 0.5
		end
		oldShakingStrength = shakingStrength
		shakingStrength = math.lerp(shakingStrength, targetShakingStrength, 0.1)
	end)
	
	events.RENDER:register(function(delta)
		if not shakingCard then
			return
		end
		local strength = math.lerp(oldShakingStrength, shakingStrength, delta)
		local time = timer + delta
		local rot = math.cos(time * 2) * strength * 4.5
		local x = math.cos(time * 2.2) * strength * 0.015
		local y = math.cos(time * 2.4) * strength * 0.015
		shakingCard:setAnimRot(0, rot, 0)
		shakingCard:setAnimPos(x, y, 0)
	end)

	events.ON_EXIT:register(function ()
		Card.applyToCardWithTag("joinHud",function (card) removeCard(card) end)
		Card.applyToCardWithTag("playerList",function (card) removeCard(card) end)
		-- removeCard(startBtn)
		-- removeCard(exitBtn)
		Sync.events.PLAYER_JOIN:remove('IntermissionPlayerJoin')
      Sync.events.PLAYER_LEAVE:remove('IntermissionPlayerLeave')
	end)
end)


--[────────────────────────────────────────-< Game >-────────────────────────────────────────]--

local sceneGame = Macro.new(function (events, ...)
	local cardsRadius = 2
	local viewerName = client.getViewer():getName()
	local myDroppedCardI = 1
	local cardsRowLimit = 12

	---@type Card?
	local drawToMatchCard = nil

	local drawCardsCountModel = worldModel:newPart("drawCardsCount", "CAMERA")
	local drawCardsCountText = drawCardsCountModel:newText("")
	drawCardsCountModel:setPivot(-16, 4, 0)
	drawCardsCountText:setOutline(true)
		:setAlignment("CENTER")
		:setScale(0.5, 0.5, 0.5)
		:setLight(15, 15)

	---@type {[string]: {[number]: Card[]}}
	local cardInventory = {}
	-- INV = cardInventory -- DEBUG

	---@type TextTask
	local turnIndicator = nil
	local lastTurnIndicatorName = nil
	---@param name string?
	local function makeTurnIndicator(name)
		turnIndicator = worldModel:newPart('turnIndicator')
		local text = ''
		if name then
			if name == viewerName then
				text = "Your turn"
			else
				text = name.."'s turn"
			end
		end
		for i = 0, 1 do
			turnIndicator:newText('text'..i)
				:setOutline(true)
				:setLight(15, 15)
				:setText(text)
				:setRot(0, i * 180, 0)
				:setAlignment("CENTER")
				:setPos(0, 2, 0)
				:setScale(0.5, 0.5, 0.5)
		end
		turnIndicator:setPos(0, 0, 0)
			:setPos(0, 0, 0)
	end
	makeTurnIndicator()

	local cardStackHeight = 0

	---@type {[string]: true}
	local playersCardsToUpdate = {}

	local function sortPlayers()
		if not host:isHost() then
			return
		end
		local oldPlayersOrder = Sync.getPlayersOrder()
		local playersOrderData = {}
		for i, name in ipairs(oldPlayersOrder) do
			local rot = Sync.getPlayerRot(name)
			table.insert(playersOrderData, math.floor(rot * 256) * 256 + i)
		end
		table.sort(playersOrderData)
		local playersOrder = {}
		for i, v in ipairs(playersOrderData) do
			local k = v % 256
			playersOrder[i] = oldPlayersOrder[k]
		end
		Sync.setPlayersOrder(playersOrder)
	end

	---@param name string
	local function updatePlayerRotation(name)
		local gamePos = Sync.getGamePos()
		local entity = world.getPlayers()[name]
		local offset
		if entity then
			local myOffset = entity:getPos().xz - gamePos.xz
			if myOffset:length() > 0.000001 then
				offset = myOffset
			end
		end
		local rot = offset and math.deg(math.atan2(offset.y, offset.x)) or math.random(360)
		rot = rot % 360
		Sync.setPlayerRot(name, -rot)
	end

	if host:isHost() and Sync.getPlayersCount() >= 1 then
		-- set players order
		for i, name in ipairs(Sync.getPlayersOrder()) do
			updatePlayerRotation(name)
		end
		sortPlayers()
		-- randomize first player
		Sync.setCurrentPlayer(math.random(Sync.getPlayersCount()))
	end

	local function requestCardUpdate(name)
		playersCardsToUpdate[name] = true
	end

	local function updateCardsRadius()
		local new = Sync.getPlayersCount() * 0.25 + 2
		if new == cardsRadius then
			return
		end
		cardsRadius = new
		for _, name in pairs(Sync.getPlayersOrder()) do
			requestCardUpdate(name)
		end
	end
	updateCardsRadius()

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
			:setTag("gameCard")

		card.PRESSED:register(function(name)
			if Sync.getCurrentPlayer() ~= name then
				return
				end
			if Sync.getColor() == 6 then
				return
			end
			if Card.isValidCardId(Sync.getDrawToMatchCard()) then
				return
			end
			card.PRESSED:clear()
			local drawCardsCount = Sync.getDrawCardsCount()
			if drawCardsCount >= 1 then
				-- drawing multiple cards can get desynced, so its done only on hot and then sent
				if host:isHost() then
					for _ = 1, drawCardsCount do
						Sync.drawCard(name)
					end
				end
				Sync.setDrawCardsCount(0)
				nextPlayer()
				return
			end
			Sync.setDrawToMatchCard(Sync.getNextCard())
			-- nextPlayer()
		end)

		return card
	end

	local function reversePlayersOrder()
		local order = Sync.getPlayersOrder()
		local newOrder = {}
		for i = #order, 1, -1 do
			table.insert(newOrder, order[i])
		end
		Sync.setPlayersOrder(newOrder)
	end

	local drawCard = makeDrawCard()

	---@type Card[]
	local colorChoiceCards = {}

	local function updateTopCardColor()
		local inv = cardInventory["!"]
		local cardsList = Sync.getRawCards("!")
		local cardId = cardsList[#cardsList]
		if not inv or not inv[cardId] then
			return
		end
		local card = inv[cardId][#inv[cardId]]
		local type, color = Card.fullIdToTypeAndColor(cardId)
		local currentColor = Sync.getColor()
		if color == 5 and currentColor >= 1 and currentColor <= 5 then
			card:setColor(currentColor)
		end
	end

	---@param instant boolean?
	local function updateTurnIndicatorPosition(instant)
		local name = Sync.getCurrentPlayer()
		if not name then return end
		local angle = Sync.getPlayerRot(name)
		local cardCount = #Sync.getRawCards(name)
		local height = math.ceil((cardCount) / cardsRowLimit)
		height = height * 0.5 + 0.5
		local pos = vec(cardsRadius - 1, height, 0) * 16
		pos = vectors.rotateAroundAxis(angle, pos, vec(0, 1, 0))
		local rot = vec(0, angle + 90, 0)
		local myTurnIndicator = turnIndicator
		if instant then
			myTurnIndicator:setRot(rot)
				:setPos(pos)
			return
		end
		local oldPos = myTurnIndicator:getPos()
		local oldRot = myTurnIndicator:getRot()
		Tween.new{
			from = 0,
			to = 1,
			duration = 0.5,
			easing = "inOutCubic",
			tick = function(v, t)
				myTurnIndicator:setPos(math.lerp(oldPos, pos, v))
					:setRot(math.lerp(oldRot, rot, v))
			end
		}
	end

	local function updateTurnIndicator()
		local name = Sync.getCurrentPlayer()
		if lastTurnIndicatorName == name then return end
		lastTurnIndicatorName = name
		local oldIndicator = turnIndicator
		Tween.new{
			from = 1,
			to = 0,
			duration = 0.5,
			easing = "inCubic",
			tick = function(v, t)
				oldIndicator:setScale(1, v, 1)
			end,
			onFinish = function()
				oldIndicator:remove()
			end
		}
		makeTurnIndicator(name)
		if not name then return end
		local newIndicator = turnIndicator
		Tween.new{
			from = 0,
			to = 1,
			duration = 0.5,
			easing = "outBack",
			tick = function(v, t)
				newIndicator:setScale(1, v, 1)
			end,
		}
		updateTurnIndicatorPosition(true)
	end

	---this just does all effects of dropping card, you still have to drop card yourself
	---@param cardId integer
	---@return boolean?
	local function dropCard(cardId)
		local cardsStack = Sync.getRawCards("!")
		local topCard = cardsStack[#cardsStack]
		local topType,topColor = Card.fullIdToTypeAndColor(topCard)
		local cardType,color = Card.fullIdToTypeAndColor(cardId)
		local currentColor = Sync.getColor()
		if currentColor == 6 then
			return
		end
		if not (color == 5 or color == currentColor or topType == cardType) then
			return
		end
		local drawCards = 0
		if cardType == 14 then
			drawCards = 2
		elseif cardType == 15 then
			drawCards = 4
		end
		if Sync.getDrawCardsCount() >= 1 and drawCards == 0 then
			return
		end
		local isSkip = cardType == 13
		if cardType == 12 then
			if Sync.getPlayersCount() <= 2 then
				isSkip = true
			else
				reversePlayersOrder()
			end
		end
		if color == 5 then
			Sync.setColor(6)
		else
			Sync.setColor(color)
			nextPlayer()
		end
		if isSkip then
			nextPlayer()
		end
		if drawCards >= 1 then
			Sync.setDrawCardsCount(Sync.getDrawCardsCount() + drawCards)
		end

		return true
	end

	local function hasAnyCardsCheck()
		local currentPlayer = Sync.getCurrentPlayer()
		local currentColor = Sync.getColor()
		local isSpecialColor = currentColor == 5 or currentColor == 6
		for _, name in pairs(Sync.getPlayersOrder()) do
			if #Sync.getRawCards(name) == 0 then
				if currentPlayer ~= name or not isSpecialColor then
					if currentPlayer == name then
						nextPlayer()
					end
					Sync.removePlayer(name)
					playersCardsToUpdate[name] = nil
					-- print(name, "won!")
				end
			end
		end
	end

	local function updateCards(name)
		if not cardInventory[name] then
			cardInventory[name] = {}
		end
		local inv = cardInventory[name]
		local invI = {}
		local cardsList = Sync.getRawCards(name)
		local playerIndex = Sync.getPlayerIndex(name) or -1
		local playerRot = Sync.getPlayerRot(name)
		local cardsCount = #cardsList
		local lastRowStart = math.floor(cardsCount / cardsRowLimit) * cardsRowLimit
		local lastRowLength = cardsCount - lastRowStart
		-- sort cards
		local cardsSorted = {}
		for i, cardId in ipairs(cardsList) do
			cardsSorted[i] = cardId * 10000 + i
		end
		local cardHoverAnim = nil
		if name == "!" then
			cardStackHeight = 0
		else
			table.sort(cardsSorted)
			cardHoverAnim = "up"
		end
		-- update cards
		for i, cardIdRaw in ipairs(cardsSorted) do
			local k = cardIdRaw % 10000
			local cardId = math.floor(cardIdRaw / 10000)
			if not inv[cardId] then
				inv[cardId] = {}
			end
			invI[cardId] = (invI[cardId] or 0) + 1
			local myInvI = invI[cardId]

			local card = inv[cardId][ myInvI ]
			if not card then
				card = Card.new()
				card:setTag("gameCard")
				setCardStyle(name, card, cardId)
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
				targetRot.y = card.dropRot or 0
			else
				local x = (i - 1) % cardsRowLimit
				local y = math.floor((i - 1) / cardsRowLimit)
				local rowSize = i > lastRowStart and lastRowLength or cardsRowLimit
				local cardRot = (x - rowSize * 0.5 + 0.5) * 0.24
				local pos = vec(-math.cos(cardRot), 0, -math.sin(cardRot))
				pos.y = y * 0.5
				pos = vectors.rotateAroundAxis(playerRot, pos + vec(cardsRadius, 0.5, 0), vec(0, 1, 0))
				targetPos = pos
				targetRot = vec(-90, playerRot - math.deg(cardRot) - 90, 0)
				if rowSize ~= 1 then
					targetRot.y = targetRot.y - 10
				end
			end

			if not card.animTargetPos or (card.animTargetPos - targetPos):length() > 0.0001 then
				local oldScale = card.scale
				local oldRot = card.rot
				card.animTargetPos = targetPos
				Tween.new{
					id = "una.card."..card.idx,
					from = card.pos,
					to = targetPos,
					duration = 0.25,
					easing = "outCubic",
					tick = function(v, t)
						card:setPos(v)
							:setScale(math.lerp(oldScale, targetScale, t))
							:setRot(math.lerp(oldRot, targetRot, t))
					end
				}
			end

			card.hoverAnim = cardHoverAnim
			card:setId("card;"..name..';'..k)

			card.PRESSED:clear()
			if name == "!" then
				card:setOwner()
				card.PRESSED:register(function()
					local cardId = Sync.getDrawToMatchCard()
					if not Card.isValidCardId(cardId) then
						return
					end
					if not dropCard(cardId) then
						return
					end
					Sync.drawCard("!", cardId)
					Sync.setDrawToMatchCard(0)
				end)
			else
				card:setOwner(name)
				card.PRESSED:register(function()
					if Sync.getCurrentPlayer() ~= name then -- not your turn!!
						return
					end
					if Card.isValidCardId(Sync.getDrawToMatchCard()) then
						Sync.drawCard(name, Sync.getDrawToMatchCard())
						Sync.setDrawToMatchCard(0)
						nextPlayer()
						return
					end
					if not dropCard(cardId) then
						return
					end
					Sync.dropCard(name, k)
					if name == viewerName then
						myDroppedCardI = myInvI
					end
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
		--
		if name == "!" then
			updateTopCardColor()
		end
		if name == Sync.getCurrentPlayer() then
			updateTurnIndicatorPosition()
		end
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

	Sync.events.PLAYER_JOIN:register(function(name)
		updatePlayerRotation(name)
		sortPlayers()
		updateCardsRadius()
	end, 'gamePlayerJoin')
	Sync.events.PLAYER_LEAVE:register(function(name)
		updateCardsRadius()
		local myInv = cardInventory[name]
		if not myInv then
			return
		end
		for _, cards in pairs(myInv) do
			for _, card in pairs(cards) do
				removeCard(card)
			end
		end
		cardInventory[name] = nil
	end, 'gamePlayerLeave')

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
				:setScale(0, 0, 0)
				:setTag("gameCard")
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
		card.dropRot = Sync.getPlayerRot(name) - 90

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
		updateTopCardColor()
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
				:setOwner(Sync.getCurrentPlayer())
			colorChoiceCards[i] = card
			card.PRESSED:register(function(name)
				Sync.setColor(i)
				nextPlayer()
				requestCardUpdate("!")
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

	Sync.events.DRAW_CARDS_COUNT_CHANGE:register(function(new, old)
		if new >= 1 then
			drawCardsCountText:setText("+"..new)
		end
		local from, to = 0.6, 0.5
		if old == 0 then
			from = 0
		elseif new == 0 then
			from, to = 0.5, 0
		end
		Tween.new{
			from = from,
			to = to,
			duration = 0.3,
			easing = new == 0 and "inBack" or "outBack",
			id = "una.drawCardsCounter",
			tick = function(v, t)
				drawCardsCountText:setScale(v, v, v)
					:setPos(0, v * 4, 0)
			end,
			onFinish = function()
				if new == 0 then
					drawCardsCountText:setText("")
				end
			end
		}
	end, "gameDrawCardsCountChange")

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

	Sync.events.BIT_FLAG_CHANGE:register(function(bit, state)
	end, "gameBitFlagChange")

	Sync.events.DRAW_TO_MATCH_CHANGE:register(function(cardId)
		local state = Card.isValidCardId(cardId)
		if not state then
			if drawToMatchCard then
				removeCard(drawToMatchCard)
				drawToMatchCard = nil
			end
			return
		end
		local currentPlayer = Sync.getCurrentPlayer()
		if not drawToMatchCard then
			local card = drawCard
			drawCard = makeDrawCard()
			card.PRESSED:clear()
			drawToMatchCard = card
			local playerRot = Sync.getPlayerRot(currentPlayer)
			local offset = vectors.rotateAroundAxis(playerRot, vec(0, 0, cardsRadius), vec(0, 1, 0))
			local angle = math.deg(math.atan2(offset.x, offset.z + 1)) - 90
			local rot = vec(-90, angle, 0)
			Tween.new{
				duration = 0.5,
				from = 0,
				to = 1,
				easing = "inOutCubic",
				tick = function(v, t)
					card:setPos(-1, v, 0)
					card:setRot(rot * v)
					local s = 1 - v * 0.25
					card:setScale(s, s, s)
				end
			}
			card:setOwner(currentPlayer)
			card.PRESSED:register(function()
				card.PRESSED:clear()
				Sync.drawCard(currentPlayer, cardId)
				Sync.setDrawToMatchCard(0)
				nextPlayer()
			end)
		end
		local cardId = Sync.getDrawToMatchCard()
		setCardStyle(currentPlayer, drawToMatchCard, cardId)
	end, "gameDrawToMatchChange")

	if host:isHost() then
		for i, name in ipairs(Sync.getPlayersOrder()) do
			for k = 1, 7, 1 do
				Sync.drawCard(name, Card.getRandomCard())
			end
			-- Sync.drawCard(name, Card.typeAndColorToFullId(16, 5))
		end
	end

	events.TICK:register(function()
		if next(playersCardsToUpdate) then
			hasAnyCardsCheck()
		end
		for name in pairs(playersCardsToUpdate) do
			updateCards(name)
		end
		playersCardsToUpdate = {}
		updateTurnIndicator()

		-- local players = world.getPlayers()
		-- for name, inv in pairs(cardInventory) do
		-- 	local pos = vec(0, 0, 0)
		-- 	if players[name] then
		-- 		pos = players[name]:getPos() - Game.pos
		-- 	end
		-- 	for _, cards in pairs(inv) do
		-- 		for _, card in pairs(cards) do
		-- 			card:setOffset(pos)
		-- 		end
		-- 	end
		-- end
	end)

	events.ON_EXIT:register(function()
		-- removeCard(drawCard)
		Card.applyToCardWithTag("gameCard", function(card)
			removeCard(card)
		end)
		for _, card in pairs(colorChoiceCards) do
			removeCard(card)
		end
		if drawToMatchCard then
			removeCard(drawToMatchCard)
		end
		drawCardsCountModel:remove()
		turnIndicator:remove()
		Sync.events.PLAYER_JOIN:remove('gamePlayerJoin')
		Sync.events.PLAYER_LEAVE:remove('gamePlayerLeave')
		Sync.events.CARD_DRAWED:remove('gameCardDrawed')
		Sync.events.CARD_DROPPED:remove('gameCardDropped')
		Sync.events.CARD_REMOVED:remove('gameCardRemoved')
		Sync.events.COLOR_CHANGE:remove('gameColorChanged')
		Sync.events.DRAW_CARDS_COUNT_CHANGE:remove('gameDrawCardsCountChange')
		Sync.events.BIT_FLAG_CHANGE:remove('gameBitFlagChange')
		Sync.events.DRAW_TO_MATCH_CHANGE:remove('gameDrawToMatchChange')
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
	local block, hitPos = client.getViewer():getTargetedBlock(true, 5)
	local pos = block:getPos()
	pos.y = hitPos.y
	Game.start(pos)
   -- Game.start(vec(1997792, 68, 1999644))
end

function pings.unaGame_forceCard(currentPlayerI, cardI)
	if Sync.getGameState() == 0 then
		return
	end
	local name = Sync.getPlayersOrder()[currentPlayerI]
	if name ~= client.getViewer():getName() then
		return
	end
	local card = Card.getCardById('card;'..name..';'..cardI)
	if not card then
		return
	end
	Card.forceSelectedCard(card)
end

if host:isHost() then
	local selectCardDelay = 0
	local playerName, cardI = nil, nil
	Card.CARD_HOVER:register(function(newCard, oldCard, name)
		if not newCard then
			return
		end
		if Sync.getGameState() == 0 then
			return
		end
		if Sync.getCurrentPlayer() ~= name then
			return
		end
		if name == hostName then
			return
		end
		local cardId = newCard.id
		if not cardId then
			return
		end
		selectCardDelay = 5
		local name, i = cardId:match('^card;([^;]+);(%-?%d+)')
		if name and i then
			playerName, cardI = name, i
		end
	end)

	function events.tick()
		selectCardDelay = math.max(selectCardDelay - 1, 0)
		if selectCardDelay ~= 1 then
			return
		end
		if Sync.getCurrentPlayer() == playerName then
			local i = Sync.getPlayerIndex(playerName)
			if i then
				pings.unaGame_forceCard(i, cardI)
			end
		end
		playerName, cardI = nil, nil
	end
end

return Game