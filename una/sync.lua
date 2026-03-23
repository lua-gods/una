---@class SyncAPI
local Sync = {}

local Event = require("una.lib.event")
local Card = require("una.card")

local gameState = 0 -- 0 - not playing, 1 - waiting for players, 2 - playing

-- SYNC_TESTING.lua (in main.lua :3)
local gamePos = vec(0, 0, 0)

-- hard limit of 255 players because of syncing
-- position -1 - temporary, position -2 - meta
---@type {[string]: {position: number, cards: number[], rot: number}}
local players = {}
local playersOrder = {}
local currentPlayer = nil
local currentColor = 0
local playerDroppingCard = ''
local lastCardIndexDropped = 0
local nextCard = math.random(Card.lastCardId)
local drawCardsCount = 0

local lastSyncedGameData = ''
local syncNeeded = false

Sync.events = {
   -- player name
   PLAYER_JOIN = Event.new(),
   -- player name
   PLAYER_LEAVE = Event.new(),
   -- player name, playersOrder index
   PLAYER_CURRENT_CHANGE = Event.new(),
   -- game state, last game state
   GAME_STATE_CHANGE = Event.new(),
   -- position
   POSITION_CHANGE = Event.new(),
   -- color number
   COLOR_CHANGE = Event.new(),
   -- name, card type
   CARD_DRAWED = Event.new(), -- card added
   -- name, card index, card type
   CARD_DROPPED = Event.new(), -- card moved to meta player
   -- name, card type
   CARD_REMOVED = Event.new(),
   -- new count, old count
   DRAW_CARDS_COUNT_CHANGE = Event.new(),
}

local function resetGame()
   players = {
      ['!'] = { -- meta player
         position = -2, -- meta position
         rot = 0,
         cards = {},
      },
   }
   playersOrder = {}
   currentPlayer = nil
   currentColor = 0
   playerDroppingCard = ''
   lastCardIndexDropped = 0
   gamePos = vec(0, 0, 0)
   drawCardsCount = 0
end

resetGame()

---encodes short between 0 to 65535
---@param n number
local function encodeShort(n)
   n = math.clamp(n, 0, 65535)
   return string.char(math.floor(n / 256), n % 256)
end

---decodes short number between 0 to 65536
---@param str string
local function decodeShort(str)
   return str:byte(1) * 256 + str:byte(2)
end

---@param playerPos number
---@param pos number
---@return number
local function encodePos(playerPos, pos)
   local offset = 0
   if math.abs(playerPos % 128 - 64) > 32 then
      offset = 64
   end
   local pRounded = math.floor((playerPos - offset) / 128) * 128
   return pos - pRounded + offset * 32 -- (64 * 32 == 2048)
end

---@param playerPos number
---@param pos number
---@return number
local function decodePos(playerPos, pos)
   local offset = 0
   if pos > 1024 then
      offset = 64
      pos = pos - 2048
   end
   local pRounded = math.floor((playerPos - offset) / 128) * 128
   -- local x = pos % 128
   return pos + pRounded
end


---sets game state
---@param n number
---@param noSync boolean? # used internally by library
function Sync.setGameState(n, noSync)
   if gameState == n then
      return
   end
   if not noSync then
      syncNeeded = true
   end
	local lastGameState = gameState
   gameState = n
   if gameState == 0 then
      resetGame()
   end
   Sync.events.GAME_STATE_CHANGE(gameState,lastGameState)
end

---sets game state to 1 when its 0
local function updateGameState()
   if gameState == 0 then
      Sync.setGameState(1)
   end
end

---gets current game state
function Sync.getGameState()
   return gameState
end

---resets everything to default state
function Sync.resetGame()
   Sync.setGameState(0)
end

---returns player order
---@return string[]
function Sync.getPlayersOrder()
   return playersOrder
end

---sets players order, missing players will be added at end
---@param order string[]
function Sync.setPlayersOrder(order)
   updateGameState()
   for _, v in pairs(players) do
      v.position = -1
   end
   players['!'].position = -2
   playersOrder = order
   for i, name in pairs(playersOrder) do
      players[name].position = i
   end
   for name, v in pairs(players) do
      if v.position == -1 then
         table.insert(playersOrder, name)
         v.position = #playersOrder
      end
   end
   syncNeeded = true
end

---adds player to game, returns player object, syncs data in next tick
---@param name string
---@param noSync boolean? # used internally by library
function Sync.addPlayer(name, noSync)
   updateGameState()
   if not noSync then
      syncNeeded = true
   end
   if not players[name] then
      table.insert(playersOrder, name)
   end
   players[name] = {
      position = #playersOrder,
      rot = 0,
      cards = {}
   }
   Sync.events.PLAYER_JOIN(name)
   if not currentPlayer then
      Sync.setCurrentPlayer(name)
   end
end

---removes player with specific name from game, syncs data in next tick
---please remember to change current player before removing it
---@param name string
---@param noSync boolean? # used internally by library
---@param noOrderUpdate boolean? # used internally by library
function Sync.removePlayer(name, noSync, noOrderUpdate)
   local playerData = players[name]
   if not playerData then
      return
   end
   updateGameState()
   if playerData.position > 0 then
      table.remove(playersOrder, playerData.position)
   end
   players[name] = nil
   if not noSync then
      syncNeeded = true
   end
   if not noOrderUpdate then
      for i, name in pairs(playersOrder) do
         players[name].position = i
      end
   end
   Sync.events.PLAYER_LEAVE(name)
   Sync.setCurrentPlayer(Sync.getCurrentPlayer())
end

---returns index of current player
---@return number
function Sync.getCurrentPlayerIndex()
   return players[currentPlayer] and players[currentPlayer].position or 1
end

---returns name of current player
---@return string
function Sync.getCurrentPlayer()
   return currentPlayer
end

---sets current player, string will be used as name, number will be used as index and will loop around when outside of range
---@param nameI string|number
---@param noSync boolean? # used internally by library
function Sync.setCurrentPlayer(nameI, noSync)
   updateGameState()
   local new = nameI
   if #playersOrder == 0 then
      new = nil
   else
      if type(nameI) == "number" then
         nameI = (nameI - 1) % #playersOrder + 1
         new = playersOrder[nameI]
      end
   end
   if not players[new] then
      new = playersOrder[1]
   end
   if new ~= currentPlayer then
      currentPlayer = new
      if currentPlayer then
         Sync.events.PLAYER_CURRENT_CHANGE(currentPlayer, players[currentPlayer].position)
      end
   end
   if not noSync then
      syncNeeded = true
   end
end

---sets game pos
---@param pos Vector3
---@param noSync boolean? # used internally by library
function Sync.setGamePos(pos, noSync)
   pos = pos:copy()
   if gamePos == pos then
      return
   end
   updateGameState()
   gamePos = pos
   Sync.events.POSITION_CHANGE(pos)
   if not noSync then
      syncNeeded = true
   end
end

---returns game pos
---@return Vector3
function Sync.getGamePos()
   return gamePos:copy()
end

---sets color
---@param color number
---@param noSync boolean? # used internally by library
function Sync.setColor(color, noSync)
   if color == currentColor then
      return
   end
   updateGameState()
   currentColor = color
   if not noSync then
      syncNeeded = true
   end
   Sync.events.COLOR_CHANGE(color)
end

---gets current color
---@return integer
function Sync.getColor()
   return currentColor
end

---gives card to player, if card is nil it will give random card
---@param name string
---@param card number?
function Sync.drawCard(name, card)
   updateGameState()
   if not card then
      card = nextCard
      nextCard = math.random(Card.lastCardId)
   end
   table.insert(players[name].cards, card)
   Sync.events.CARD_DRAWED(name, card)
   syncNeeded = true
end

---drops card with specific index
---@param name string
---@param cardIndex number
function Sync.dropCard(name, cardIndex)
   updateGameState()
   local card = players[name].cards[cardIndex]
   table.insert(players['!'].cards, card)
   table.remove(players[name].cards, cardIndex)
   Sync.events.CARD_DROPPED(name, cardIndex, card)
   syncNeeded = true
   playerDroppingCard = name
   lastCardIndexDropped = cardIndex
end

---removes card from player
---@param name string
---@param cardIndex number
function Sync.removeCard(name, cardIndex)
   updateGameState()
   local card = table.remove(players[name].cards, cardIndex)
   Sync.events.CARD_REMOVED(name, card)
   syncNeeded = true
end

---sets next card that will be drawed when no card is specified
---@param card number
function Sync.setNextCard(card)
   nextCard = card
   syncNeeded = true
end

---generates cards difference table
---@param cards1 number[]
---@param cards2 number[]
---@return {[number]: number}
local function cardsDiff(cards1, cards2)
   local diff = {}
   for _, card in pairs(cards1) do
      diff[card] = (diff[card] or 0) + 1
   end
   for _, card in pairs(cards2) do
      diff[card] = (diff[card] or 0) - 1
   end
   return diff
end

---sets cards
---@param name string
---@param cards number[]
---@param noSync boolean? # used internally by library
function Sync.setCards(name, cards, noSync)
   updateGameState()
   local playerData = players[name]
   -- call events
   for card, count in pairs(cardsDiff(cards, playerData.cards)) do
      if count >= 1 then -- cards added
         for _ = 1, count do
            Sync.events.CARD_DRAWED(name, card)
         end
      elseif count <= -1 then -- cards removed
         for _ = 1, -count do
            Sync.events.CARD_REMOVED(name, card)
         end
      end
   end
   -- set cards
   playerData.cards = cards
   -- sync
   if not noSync then
      syncNeeded = true
   end
end

---returns cards of specific player
---@param name string
---@return number[]
function Sync.getCards(name)
   local cards = {}
   for i, card in pairs(players[name].cards) do
      cards[i] = card
   end
   return cards
end

---returns orginal cards table of specific player, uses less instructions but shouldn't be edited
---@param name string
---@return number[]
function Sync.getRawCards(name)
   return players[name].cards
end

---returns internal player data, please dont edit it manually
---@return {[string]: table}
function Sync.getPlayersData()
   return players
end

---gets player's index in players order
---@param name string
---@return number?
function Sync.getPlayerIndex(name)
   return players[name] and players[name].position
end

---gets player rot
---@param name string
---@return number
function Sync.getPlayerRot(name)
   return players[name] and players[name].rot or 0
end

---sets player rot
---@param name string
---@param rot number
---@param noSync boolean? # used internally by library
function Sync.setPlayerRot(name, rot, noSync)
   if players[name] then
      players[name].rot = rot % 360
      if not noSync then
         syncNeeded = true
      end
   end
end

---@return integer
function Sync.getPlayersCount()
   return #playersOrder
end

---@return integer
function Sync.getDrawCardsCount()
   return drawCardsCount
end

---comment
---@param count any
---@param noSync any
function Sync.setDrawCardsCount(count, noSync)
   local old = drawCardsCount
   if old == count then
      return
   end
   drawCardsCount = count
   Sync.events.DRAW_CARDS_COUNT_CHANGE(count, old)
   if not noSync then
      syncNeeded = true
   end
end

---@param encoded string
---@param newPosX number
---@param newPosY number
---@param newPosZ number
function pings.unaGame_sync(encoded, newPosX, newPosY, newPosZ)
   if not player:isLoaded() then
      return
   end
   if math.abs(newPosX) < 4096 and math.abs(newPosY) < 4096 and math.abs(newPosZ) < 4096 then
      local playerPos = player:getPos()
      local newGamePos = vec(
         decodePos(playerPos.x, newPosX),
         decodePos(playerPos.y, newPosY),
         decodePos(playerPos.z, newPosZ)
      )
      Sync.setGamePos(newGamePos, true)
   end
   -- prevent updates when nothing changed
   if lastSyncedGameData == encoded then
      return
   end
   lastSyncedGameData = encoded
   -- read game state
   Sync.setGameState(encoded:byte(1), true)
   if gameState == 0 then -- prevent everything from updating because reset should do that already
      return
   end
   -- read players
   for _, v in pairs(players) do
      v.position = -1
   end
   playersOrder = {}
   local newPlayers = {}
   local newCards = {} ---@type {[string]: number[]}
   for name, rot, cards in encoded:sub(10, -1):gmatch('([^\0]*)\0(..)([^\0]*)\0') do
      local playerData = players[name]
      if not playerData then
         playerData = {cards = {}} -- init player
         players[name] = playerData
         table.insert(newPlayers, name)
      end
      if name == '!' then
         playerData.position = -2
      else
         table.insert(playersOrder, name)
         playerData.position = #playersOrder
      end
      playerData.rot = (decodeShort(rot) / 65536 * 360) % 360
      -- set cards
      newCards[name] = {cards:byte(1, -1)}
   end
   -- read variables
   Sync.setCurrentPlayer(encoded:byte(2), true)
   Sync.setColor(encoded:byte(3), true)
   playerDroppingCard = playersOrder[encoded:byte(4)] or ''
   lastCardIndexDropped = decodeShort(encoded:sub(5, 6))
   nextCard = encoded:byte(7)
   Sync.setDrawCardsCount(decodeShort(encoded:sub(8, 9)), true)
   -- new players
   for _, name in ipairs(newPlayers) do
      Sync.events.PLAYER_JOIN(name)
   end
   -- drop card
   local droppedCard
   if #newCards['!'] > #players['!'].cards then
      local metaCards = newCards['!']
      local newCard = metaCards[#metaCards]
      local newPlayerCards = newCards[playerDroppingCard]
      local oldPlayerCards = players[playerDroppingCard] and players[playerDroppingCard].cards
      if (
         oldPlayerCards and newPlayerCards and
         oldPlayerCards[lastCardIndexDropped] and
         oldPlayerCards[lastCardIndexDropped] == newCard
         ) then
         local diff = cardsDiff(newPlayerCards, oldPlayerCards)
         if diff[newCard] and diff[newCard] < 0 then -- drop card
            table.remove(oldPlayerCards, lastCardIndexDropped)
            table.insert(players['!'].cards, newCard)
            droppedCard = newCard
         end
      end
   end
   -- set cards
   for name, cards in pairs(newCards) do
      Sync.setCards(name, cards, true)
   end
   -- drop card event
   if droppedCard then
      Sync.events.CARD_DROPPED(playerDroppingCard, lastCardIndexDropped, droppedCard)
   end
   -- unload players
   for name, v in pairs(players) do
      if v.position == -1 then
         Sync.removePlayer(name, true, true)
      end
   end
   -- test data
   -- printTable(playersOrder)
   -- printTable(players, 2)
   -- print('size', #encoded)
end

---@param tbl (string|number)[]
---@param name string
local function encodePlayer(tbl, name)
   table.insert(tbl, name)
   table.insert(tbl, '\0') -- string ending
   local playerData = players[name]
   table.insert(tbl, encodeShort((playerData.rot % 360) / 360 * 65536))
   for _, card in ipairs(playerData.cards) do
      table.insert(tbl, string.char(card))
   end
   table.insert(tbl, '\0') -- cards ending
end

---@return string
---@return number
---@return number
---@return number
local function encodeSyncPing()
   local tbl = {}
   -- write variables
   table.insert(tbl, string.char(gameState))
   table.insert(tbl, string.char(Sync.getCurrentPlayerIndex()))
   table.insert(tbl, string.char(currentColor))
   table.insert(tbl, string.char(players[playerDroppingCard] and players[playerDroppingCard].position or 0))
   table.insert(tbl, encodeShort(lastCardIndexDropped))
   table.insert(tbl, string.char(nextCard))
   table.insert(tbl, encodeShort(drawCardsCount))
   -- write players
   for i, name in ipairs(playersOrder) do
      encodePlayer(tbl, name)
   end
   encodePlayer(tbl, '!')
   --
   local playerPos = player:getPos()
   -- return
   return table.concat(tbl),
      encodePos(playerPos.x, gamePos.x),
      encodePos(playerPos.y, gamePos.y),
      encodePos(playerPos.z, gamePos.z)
end

function Sync.sendSyncPing()
   pings.unaGame_sync(encodeSyncPing())
end

if host:isHost() then
   local syncDelay = 100
   local syncTime = syncDelay
   function events.tick()
      if gameState >= 1 then -- sync automatically only when game is running
   	   syncTime = syncTime - 1
      end
      if syncTime <= 0 or syncNeeded then
         syncTime = syncDelay
         syncNeeded = false
         Sync.sendSyncPing()
      end
   end
end

-- testing

---@generic value any
---@param value value
---@return value
local function deepCopy(value)
   if type(value) ~= 'table' then
      return value
   end
   local tbl = {}
   for i, v in pairs(value) do
      tbl[deepCopy(i)] = deepCopy(v)
   end
   return tbl
end

---makes all sync data modified in function act like it was synced from host, events here should be called twice
---@param func function
function Sync.test(func)
   -- save data
   local _gameState = deepCopy(gameState)
   local _gamePos = deepCopy(gamePos)
   local _players = deepCopy(players)
   local _playersOrder = deepCopy(playersOrder)
   local _currentPlayer = deepCopy(currentPlayer)
   local _currentColor = deepCopy(currentColor)
   local _playerDroppingCard = deepCopy(playerDroppingCard)
   local _lastCardIndexDropped = deepCopy(lastCardIndexDropped)
   -- call function
   func()
   -- read new encoded data
   local encoded = {encodeSyncPing()}
   -- restore data
   gameState = _gameState
   gamePos = _gamePos
   players = _players
   playersOrder = _playersOrder
   currentPlayer = _currentPlayer
   currentColor = _currentColor
   playerDroppingCard = _playerDroppingCard
   lastCardIndexDropped = _lastCardIndexDropped
   -- sync
   syncNeeded = false
   pings.unaGame_sync(table.unpack(encoded))
end
--

return Sync