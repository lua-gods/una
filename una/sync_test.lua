local Sync = require('una.sync')

for name, event in pairs(Sync.events) do
   event:register(function(...)
	   print(name, ...)
   end)
end

-- Sync.addPlayer('billy')
Sync.test(function()
   -- Sync.setGamePos(vec(64, 32, 64))
   -- Sync.setGameState(2)
   -- Sync.setPlayersOrder{
      -- 'cat'
   -- }
   -- Sync.setCurrentPlayer('GNUI')
   -- Sync.removePlayer('billy')
end)