-- code goes here frfr

local gameState = 0 -- 0 - not playing, 1 - waiting for players, 2 - playing

-- SYNC_TESTING.lua (in main.lua :3)
local gamePos = vec(64, 64, 64)

local players = { -- hard limit of 255 players because of syncing
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

---sets game state
---@param n number
local function setGameState(n)
   syncNeeded = true
   gameState = n
end

---adds player to game, returns player object, syncs data in next tick
---@param name string
---@return table
local function addPlayer(name)
   syncNeeded = true
   table.insert(playersOrder, name)
   players[name] = {
      position = #playersOrder,
      cards = {}
   }
   return players[name]
end

---removes player with specific name from game, syncs data in next tick
---@param name string
local function removePlayer(name)
   local playerData = players[name]
   if playerData.position > 0 then
      table.remove(playersOrder, playerData.position)
   end
   players[name] = nil
   syncNeeded = true
   -- remove all player stuff here like cards
   print('removed player', name)
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
   gameState = encoded:byte(1, 1)
   currentPlayer = encoded:byte(2, 2)
   -- read players
   for _, v in pairs(players) do
      v.position = -1
   end
   playersOrder = {}
   for name, cards in encoded:sub(3, -1):gmatch('([^\0]*)\0([^\0]*)\0') do
      table.insert(playersOrder, name)
      local playerData = players[name]
      if not playerData then
         playerData = {} -- init player
         players[name] = playerData
      end
      playerData.position = #playersOrder
      playerData.cards = {}
      for i = 1, #cards do
         playerData.cards[i] = cards:byte(i, i)
      end
   end
   -- unload players
   for name, v in pairs(players) do
      if v.position == -1 then
         removePlayer(name)
      end
   end
   -- test data
   -- printTable(playersOrder)
   -- printTable(players, 2)
   -- print('size', #encoded)
end

local function sendSyncPing()
   local tbl = {}
   -- write variables
   table.insert(tbl, string.char(gameState))
   table.insert(tbl, string.char(currentPlayer))
   -- write players
   for i, name in ipairs(playersOrder) do
      table.insert(tbl, name)
      table.insert(tbl, '\0') -- string ending
      local playerData = players[name]
      for _, card in ipairs(playerData.cards) do
         table.insert(tbl, string.char(card))
      end
      table.insert(tbl, '\0') -- cards ending
   end
   -- destroy data for testing
   -- currentPlayer = 1
   -- playersOrder = {}
   -- players = {}
   -- send
   pings.unaGame_sync(
      table.concat(tbl),
      gamePos -- position could be encoded like in my (auria's) patpat but i dont feel like its worth it
   )
end

sendSyncPing()

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
         sendSyncPing()
      end
   end
end