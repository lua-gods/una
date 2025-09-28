--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / discord: @gn68s
 / / __/  |/ / name: Macros Library
/ /_/ / /|  /  desc: lets you contain Figura events and toggle them
\____/_/ |_/ Source: https://github.com/lua-gods/GNs-Figura-Avatar-4/blob/main/lib/macros.lua  ]]
---@class MacroAPI
local MacrosAPI = {}

-- DEPENDENCIES
local Event = require("./event")


local randomID = function ()
	return client.intUUIDToString(client.generateUUID())
end

---@class Macro
---@field isActive boolean
---@field events MacroEventsAPI
---@field id string
---@field package init fun(events: MacroEventsAPI,...)
local Macro = {}
Macro.__index = Macro


---@class MacroEventsAPI : EventsAPI
---@field ON_EXIT Event
---@field ON_ENTITY_UNLOAD Event
---@field ON_ENTITY_LOAD Event
local MacroEventsAPI = {}

---Enables / Disables the macro
---@param active boolean
---@param ... any
function Macro:setActive(active,...)
	if self.isActive ~= active then
		self.isActive = active
		if active then
			self.events = setmetatable({
				ENTITY_INIT = Event.new(),
				ON_EXIT = Event.new(),
				ON_ENTITY_UNLOAD = Event.new(),
				ON_ENTITY_LOAD = Event.new(),
			}, MacroEventsAPI)
			self.init(self.events,...)
			
			local hasInit = false
			local hasLoadEvent = false
			for name, value in pairs(self.events) do
				if events[name] then
					events[name]:register(function (...)
						value:invoke(...)
					end, self.id)
				end
				if name == "ENTITY_INIT" then
					hasInit = true
				end
				if name == "ON_ENTITY_LOAD" or name == "ON_ENTITY_UNLOAD" then
					hasLoadEvent = true
				end
			end
			
			if player:isLoaded() then
				self.events.ENTITY_INIT:invoke()
			else
				if hasInit then
					local initName = self.id.."init"
					
					events.TICK:register(function ()
						self.events.ENTITY_INIT:invoke()
						events.TICK:remove(initName)
					end,initName)
				end
			end
			local wasLoaded = 5
			if hasLoadEvent then
				events.WORLD_TICK:register(function ()
					local isLoaded = player:isLoaded()
					if isLoaded ~= wasLoaded then
						wasLoaded = isLoaded
						if isLoaded then
							self.events.ON_ENTITY_LOAD:invoke()
						else
							self.events.ON_ENTITY_UNLOAD:invoke()
						end
					end
				end)
			end
		else
			for name in pairs(self.events) do
				if events[name] then
					events[name]:remove(self.id)
				end
			end
			self.events.ON_EXIT:invoke(...)
		end
	end
end





---@param init fun(events: MacroEventsAPI,...)
---@return Macro
function MacrosAPI.new(init)
	local new = {
		init = init,
		isActive = false,
		id = randomID(),
		events = {}
}
	return setmetatable(new, Macro)
end

MacroEventsAPI.__index = function (t, k)
	if not rawget(t, k) then
		local signal = Event.new()
		rawset(t, k, signal)
		--if v and type(v) == "function" then signal:register(v) end
	end
	return rawget(t, k)
end


return MacrosAPI