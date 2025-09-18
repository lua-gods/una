local Sync = require("./sync") ---@module "una.sync"
local Card = require("./card") ---@type CardAPI

---@class UNA.Game
local Game = {
	pos = vec(1999047, 188, 1999627)
}


local test = Card.new()
:setPos(Game.pos)
:setType(Card.typeToIndex("EMPTY"))
:setLabel("test")

return Game