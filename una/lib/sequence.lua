--[[______  __
  / ____/ | / / by: GNamimates, Discord: "@gn8.", Youtube: @GNamimates
 / / __/  |/ / name: A library that makes it easier to create sequences.
/ /_/ / /|  /  desc: 
\____/_/ |_/ Source: https://github.com/lua-gods/GNs-Avatar-3/blob/main/libraries/sequence.lua]]
local n = 0
local eventLib = require(... ..".event")

---@class Sequence
---@field keyframes {time:integer,func:function}[]
---@field trackingKeyframe integer
---@field time integer
---@field ON_COMPLETE Event
---@field rid integer
---@field isActive boolean
local Seq = {}
Seq.__index = Seq
Seq.__type = "Sequence"


---Creates a new sequence
---@return Sequence
function Seq.new()
  local new = {}
  setmetatable(new,Seq)
  new.keyframes = {}
  new.time = 0
  new.trackingKeyframe = 1
  new.rid = n
  new.isActive = false
  new.ON_COMPLETE = eventLib.new()
  n = n + 1
  return new
end


---Appens a keyframe into the sequence.
---@param time integer
---@param func function
---@return Sequence
function Seq:add(time,func)
  local found = false
  for i = 1, #self.keyframes, 1 do
    if self.keyframes[i].time > time then
      table.insert(self.keyframes,i,{time = time,func = func})
      found = true
      break
    end
  end
  if not found then
    table.insert(self.keyframes,{time = time,func = func})
  end
  return self
end


---@return Sequence
function Seq:start(event)
  if not self.isActive then
    self.isActive = true
    event:register(function ()
      local tracking = self.keyframes[self.trackingKeyframe]
      if tracking.time <= self.time then
        tracking.func()
        self.trackingKeyframe = self.trackingKeyframe + 1
      end
  
      if self.trackingKeyframe > #self.keyframes then
        self.time = 0
        self.trackingKeyframe = 1
        self.ON_COMPLETE:invoke()
        self.isActive = false
        event:remove("sequence_" .. self.rid)
        return
      end
      self.time = self.time + 1
    end,"sequence_" .. self.rid)
  end
  return self
end


return Seq