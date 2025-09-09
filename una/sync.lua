---@class SyncAPI
local Sync = {}

local Event = require("una.lib.event")

local gameState = 0 -- 0 - not playing, 1 - waiting for players, 2 - playing

-- SYNC_TESTING.lua (in main.lua :3)
local gamePos = vec(64, 64, 64)

local players = { -- hard limit of 255 players because of syncing
   ['!'] = { -- meta player
      position = -2,
      cards = {},
   },
   GNUI = { -- test data
      -- stuff
      position = 1, -- this will be figured out from ping
      cards = {8, 18, 88, 68} -- card index CANNOT be 0
   },
   meow = {
      position = 2,
      cards = {95, 121, 54}
   },
   cat = {
      position = 3,
      cards = {86, 34, 18}
   },
}
local playersOrder = {
   'GNUI', -- test data
   'cat',
   'meow',
}
local currentPlayer = 2 -- (currentPlayer - 1 + dir) % #playersOrder + 1

local lastSyncedGameData = ''
local syncNeeded = false

Sync.events = {
   PLAYER_JOIN = Event.new(),
   PLAYER_LEAVE = Event.new(),
   GAME_STATE_CHANGE = Event.new(),
}

---sets game state
---@param n number
function Sync.setGameState(n)
   if gameState ~= n then
      syncNeeded = true
      gameState = n
      Sync.events.GAME_STATE_CHANGE(gameState)
   end
end

---gets current game state
function Sync.getGameState()
   return gameState
end

---adds player to game, returns player object, syncs data in next tick
---@param name string
function Sync.addPlayer(name)
   syncNeeded = true
   table.insert(playersOrder, name)
   players[name] = {
      position = #playersOrder,
      cards = {}
   }
   Sync.events.PLAYER_JOIN(name)
end

---removes player with specific name from game, syncs data in next tick
---@param name string
function Sync.removePlayer(name)
   local playerData = players[name]
   if not playerData then
      return
   end
   if playerData.position > 0 then
      table.remove(playersOrder, playerData.position)
   end
   players[name] = nil
   syncNeeded = true
   Sync.events.PLAYER_LEAVE(name)
end

---@param encoded string
---@param receivedPos Vector3
function pings.unaGame_sync(encoded, receivedPos)
   gamePos = receivedPos
   -- prevent updates when nothing changed
   if lastSyncedGameData == encoded then
      return
   end
   lastSyncedGameData = encoded
   -- read variables
   Sync.setGameState(encoded:byte(1, 1))
   currentPlayer = encoded:byte(2, 2)
   -- read players
   for _, v in pairs(players) do
      v.position = -1
   end
   playersOrder = {}
   for name, cards in encoded:sub(3, -1):gmatch('([^\0]*)\0([^\0]*)\0') do
      local playerData = players[name]
      if not playerData then
         playerData = {} -- init player
         players[name] = playerData
         Sync.events.PLAYER_JOIN(name)
      end
      if name == '!' then
         playerData.position = -2
      else
         table.insert(playersOrder, name)
         playerData.position = #playersOrder
      end
      playerData.cards = {}
      for i = 1, #cards do
         playerData.cards[i] = cards:byte(i, i)
      end
   end
   -- unload players
   for name, v in pairs(players) do
      if v.position == -1 then
         Sync.removePlayer(name)
      end
   end
   -- test data
   printTable(playersOrder)
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
   table.insert(tbl, string.char(currentPlayer))
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

---@param value any
---@return any
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
   -- sync
   pings.unaGame_sync(table.unpack(encoded))
end
--

return Sync