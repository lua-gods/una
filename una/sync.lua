---@class SyncAPI
local Sync = {}

local Event = require("una.lib.event")
local Card = require("una.card")

local gameState = 0 -- 0 - not playing, 1 - waiting for players, 2 - playing

-- SYNC_TESTING.lua (in main.lua :3)
local gamePos = vec(64, 64, 64)

-- hard limit of 255 players because of syncing
-- position -1 - temporary, position -2 - meta
local players = {
   ['!'] = { -- meta player
      position = -2, -- meta position
      cards = {},
   },
}
local playersOrder = {}
local currentPlayer = nil
local currentColor = 0
local playerDroppingCard = ''
local lastCardIndexDropped = 0

local lastSyncedGameData = ''
local syncNeeded = false

Sync.events = {
   -- player name
   PLAYER_JOIN = Event.new(),
   -- player name
   PLAYER_LEAVE = Event.new(),
   -- player name, playersOrder index
   PLAYER_CURRENT_CHANGE = Event.new(),
   -- game state
   GAME_STATE_CHANGE = Event.new(),
   -- position
   POSITION_CHANGE = Event.new(),
   -- color number
   COLOR_CHANGE = Event.new(),
   -- name, card type
   CARD_DRAWED = Event.new(), -- card added
   -- name, card index
   CARD_DROPPED = Event.new(), -- card moved to meta player
   -- name, card type
   CARD_REMOVED = Event.new(),
}

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
   gameState = n
   Sync.events.GAME_STATE_CHANGE(gameState)
end

---gets current game state
function Sync.getGameState()
   return gameState
end

---returns player order
---@return string[]
function Sync.getPlayersOrder()
   return playersOrder
end

---sets players order, missing players will be added at end
---@param order string[]
function Sync.setPlayersOrder(order)
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
   if not noSync then
      syncNeeded = true
   end
   if not players[name] then
      table.insert(playersOrder, name)
   end
   players[name] = {
      position = #playersOrder,
      cards = {}
   }
   Sync.events.PLAYER_JOIN(name)
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
   if not card then
      card = math.random(Card.lastCardId)
   end
   table.insert(players[name].cards, card)
   Sync.events.CARD_DRAWED(name, card)
   syncNeeded = true
end

---drops card with specific index
---@param name string
---@param cardIndex number
function Sync.dropCard(name, cardIndex)
   local card = players[name].cards[cardIndex]
   table.insert(players['!'].cards, card)
   table.remove(players[name].cards, cardIndex)
   Sync.events.CARD_DROPPED(name, cardIndex)
   syncNeeded = true
   playerDroppingCard = name
   lastCardIndexDropped = cardIndex
end

---removes card from player
---@param name string
---@param cardIndex number
function Sync.removeCard(name, cardIndex)
   local card = table.remove(players[name].cards, cardIndex)
   Sync.events.CARD_REMOVED(name, card)
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

---@param encoded string
---@param newGamePos Vector3
function pings.unaGame_sync(encoded, newGamePos)
   Sync.setGamePos(newGamePos, true)
   -- prevent updates when nothing changed
   if lastSyncedGameData == encoded then
      return
   end
   lastSyncedGameData = encoded
   -- read players
   for _, v in pairs(players) do
      v.position = -1
   end
   playersOrder = {}
   local newCards = {} ---@type {[string]: number[]}
   for name, cards in encoded:sub(6, -1):gmatch('([^\0]*)\0([^\0]*)\0') do
      local playerData = players[name]
      if not playerData then
         playerData = {cards = {}} -- init player
         players[name] = playerData
         Sync.events.PLAYER_JOIN(name)
      end
      if name == '!' then
         playerData.position = -2
      else
         table.insert(playersOrder, name)
         playerData.position = #playersOrder
      end
      -- set cards
      newCards[name] = {cards:byte(1, -1)}
   end
   -- read variables
   Sync.setGameState(encoded:byte(1), true)
   Sync.setCurrentPlayer(encoded:byte(2), true)
   Sync.setColor(encoded:byte(3), true)
   playerDroppingCard = playersOrder[encoded:byte(4)] or ''
   lastCardIndexDropped = encoded:byte(5)
   -- drop card
   local dropCardEvent = false
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
            dropCardEvent = true
         end
      end
   end
   -- set cards
   for name, cards in pairs(newCards) do
      Sync.setCards(name, cards, true)
   end
   -- drop card event
   if dropCardEvent then
      Sync.events.CARD_DROPPED(playerDroppingCard, lastCardIndexDropped)
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
   for _, card in ipairs(playerData.cards) do
      table.insert(tbl, string.char(card))
   end
   table.insert(tbl, '\0') -- cards ending
end

---@return string
---@return Vector3
local function encodeSyncPing()
   local tbl = {}
   -- write variables
   table.insert(tbl, string.char(gameState))
   table.insert(tbl, string.char(Sync.getCurrentPlayerIndex()))
   table.insert(tbl, string.char(currentColor))
   table.insert(tbl, string.char(players[playerDroppingCard] and players[playerDroppingCard].position or 0))
   table.insert(tbl, string.char(lastCardIndexDropped))
   -- write players
   for i, name in ipairs(playersOrder) do
      encodePlayer(tbl, name)
   end
   encodePlayer(tbl, '!')
   -- return
   return table.concat(tbl), gamePos
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