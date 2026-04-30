local Game = require("una.game")

local function init()
   local page = action_wheel:getCurrentPage()
   if not page then
      page = action_wheel:newPage()
      action_wheel:setPage(page)
   end
   page:setAction(-1, Game.actionWheelAction)

   events.TICK:remove(init)
end
events.TICK:register(init)