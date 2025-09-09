local Sync = require('una.sync')

for name, event in pairs(Sync.events) do
   event:register(function(...)
	   print(name, ...)
   end)
end

-- Sync.addPlayer('billy')
Sync.test(function()
   -- Sync.setGameState(2)
   -- Sync.removePlayer('billy')
end)