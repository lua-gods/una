local Line = require("../lib/line") ---@type Line

---@param matrix Matrix4
local function displayMatrix(matrix)
	local origin = matrix:apply(0,0,0)
	Line.new()
	:setAB(origin,matrix:apply(1,0,0))
	:setColor(1,0,0)
	:setWidth(0.02)
	
	Line.new()
	:setAB(origin,matrix:apply(0,1,0))
	:setColor(0,1,0)
	:setWidth(0.02)
	
	Line.new()
	:setAB(origin,matrix:apply(0,0,1))
	:setColor(0,0,1)
	:setWidth(0.02)
	
end

return displayMatrix