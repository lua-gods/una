do return end -- quick toggle

local Sync = require('una.sync')

local debugEvents = false
local eventLogPrefix = nil

for name, event in pairs(Sync.events) do
   event:register(function(...)
      if not debugEvents then
         return
      end
      if eventLogPrefix then
         print(eventLogPrefix)
         eventLogPrefix = nil
      end
      print(name, ...)
   end)
end

Sync.addPlayer('billy')
Sync.addPlayer('cat')
Sync.setCards('cat', {34, 88, 128})
Sync.test(function()
   debugEvents = true
   eventLogPrefix = '--< start >--'
   ---[[
   Sync.addPlayer('GNUI')
   Sync.setCurrentPlayer('billy')
   Sync.removePlayer('billy')
   Sync.drawCard('GNUI', 64)
   Sync.dropCard('cat', 3)
   Sync.setColor(4)
   Sync.setGamePos(vec(16, 16, 16))
   Sync.removeCard('cat', 2)
   --]]
   --[[
   Sync.resetGame()
   --]]
   eventLogPrefix = '--< synced >--'
end)