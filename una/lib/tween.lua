---@diagnostic disable: assign-type-mismatch
--[[______  __ 
  / ____/ | / /  by: GNanimates | Discord: @GN68s | Youtube: @GNamimates
 / / __/  |/ / name: Tween Library v2
/ /_/ / /|  /  desc: a library that makes it easier to create tweens
\____/_/ |_/ Source: https://github.com/lua-gods/GNs-Avatar-3/blob/main/libraries/tween.lua

NOTE: Figura trims off all comments automatically by default. 
so all of this comment will be stripped out before being processed by Figura.
]] --[[

 MIT LICENSE

	Copyright (c) 2014 Enrique García Cota, Yuichi Tateno, Emmanuel Oga
	https://github.com/kikito/tween.lua/blob/master/tween.lua
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be included
	in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]

-- easing

-- Adapted from https://github.com/EmmanuelOga/easing. See LICENSE.txt for credits.
-- Heavily modified to be normalized

local pow, sin, cos, pi, sqrt, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.asin

-- Linear
local function linear(t)
	return t
end

-- Quad
local function inQuad(t)
	return t^2
end

local function outQuad(t)
	return -t * (t - 2)
end

local function inOutQuad(t)
	t = t * 2
	if t < 1 then return 0.5 * t^2 end
	t = t - 1
	return -0.5 * (t * (t - 2) - 1)
end

local function outInQuad(t)
	if t < 0.5 then return outQuad(t * 2) * 0.5 end
	return inQuad((t - 0.5) * 2) * 0.5 + 0.5
end

-- Cubic
local function inCubic(t)
	return t^3
end

local function outCubic(t)
	t = t - 1
	return t^3 + 1
end

local function inOutCubic(t)
	t = t * 2
	if t < 1 then return 0.5 * t^3 end
	t = t - 2
	return 0.5 * (t^3 + 2)
end

local function outInCubic(t)
	if t < 0.5 then return outCubic(t * 2) * 0.5 end
	return inCubic((t - 0.5) * 2) * 0.5 + 0.5
end

-- Quart
local function inQuart(t)
	return t^4
end

local function outQuart(t)
	t = t - 1
	return 1 - t^4
end

local function inOutQuart(t)
	t = t * 2
	if t < 1 then return 0.5 * t^4 end
	t = t - 2
	return -0.5 * (t^4 - 2)
end

local function outInQuart(t)
	if t < 0.5 then return outQuart(t * 2) * 0.5 end
	return inQuart((t - 0.5) * 2) * 0.5 + 0.5
end

-- Quint
local function inQuint(t)
	return t^5
end

local function outQuint(t)
	t = t - 1
	return t^5 + 1
end

local function inOutQuint(t)
	t = t * 2
	if t < 1 then return 0.5 * t^5 end
	t = t - 2
	return 0.5 * (t^5 + 2)
end

local function outInQuint(t)
	if t < 0.5 then return outQuint(t * 2) * 0.5 end
	return inQuint((t - 0.5) * 2) * 0.5 + 0.5
end

-- Sine
local function inSine(t)
	return 1 - cos(t * pi * 0.5)
end

local function outSine(t)
	return sin(t * pi * 0.5)
end

local function inOutSine(t)
	return -0.5 * (cos(pi * t) - 1)
end

local function outInSine(t)
	if t < 0.5 then return outSine(t * 2) * 0.5 end
	return inSine((t - 0.5) * 2) * 0.5 + 0.5
end

-- Expo
local function inExpo(t)
	if t == 0 then return 0 end
	return pow(2, 10 * (t - 1))
end

local function outExpo(t)
	if t == 1 then return 1 end
	return 1 - pow(2, -10 * t)
end

local function inOutExpo(t)
	if t == 0 then return 0 end
	if t == 1 then return 1 end
	t = t * 2
	if t < 1 then return 0.5 * pow(2, 10 * (t - 1)) end
	return 0.5 * (2 - pow(2, -10 * (t - 1)))
end

local function outInExpo(t)
	if t < 0.5 then return outExpo(t * 2) * 0.5 end
	return inExpo((t - 0.5) * 2) * 0.5 + 0.5
end

-- Circ
local function inCirc(t)
	return -(sqrt(1 - t^2) - 1)
end

local function outCirc(t)
	t = t - 1
	return sqrt(1 - t^2)
end

local function inOutCirc(t)
	t = t * 2
	if t < 1 then return -0.5 * (sqrt(1 - t^2) - 1) end
	t = t - 2
	return 0.5 * (sqrt(1 - t^2) + 1)
end

local function outInCirc(t)
	if t < 0.5 then return outCirc(t * 2) * 0.5 end
	return inCirc((t - 0.5) * 2) * 0.5 + 0.5
end

-- Elastic (factory with amplitude and period)
function inElastic(t, a, p)
	a = a or 1
	p = p or 0.3
	if t == 0 or t == 1 then return t end
	local s = p / (2 * pi) * asin(1 / a)
	t = t - 1
	return -(a * pow(2, 10 * t) * sin((t - s) * (2 * pi) / p))
end

function outElastic(t, a, p)
	a = a or 1
	p = p or 0.3
	if t == 0 or t == 1 then return t end
	local s = p / (2 * pi) * asin(1 / a)
	return a * pow(2, -10 * t) * sin((t - s) * (2 * pi) / p) + 1
end

function inOutElastic(t, a, p)
	a = a or 1
	p = p or 0.45
	if t == 0 or t == 1 then return t end
	t = t * 2
	local s = p / (2 * pi) * asin(1 / a)
	if t < 1 then
		t = t - 1
		return -0.5 * (a * pow(2, 10 * t) * sin((t - s) * (2 * pi) / p))
	else
		t = t - 1
		return a * pow(2, -10 * t) * sin((t - s) * (2 * pi) / p) * 0.5 + 1
	end
end

function outInElastic(t, a, p)
	if t < 0.5 then
		return 0.5 * outElastic(t * 2, a, p)
	else
		return 0.5 * inElastic((t * 2) - 1, a, p) + 0.5
	end
end

-- Back (factory with overshoot s)
function inBack(t, s)
	s = s or 1.70158
	return t^2 * ((s + 1) * t - s)
end

function outBack(t, s)
	s = s or 1.70158
	t = t - 1
	return t^2 * ((s + 1) * t + s) + 1
end

function inOutBack(t, s)
	s = (s or 1.70158) * 1.525
	t = t * 2
	if t < 1 then return 0.5 * t^2 * ((s + 1) * t - s) end
	t = t - 2
	return 0.5 * (t^2 * ((s + 1) * t + s) + 2)
end

function outInBack(t, s)
	if t < 0.5 then
		return 0.5 * outBack(t * 2, s)
	else
		return 0.5 * inBack((t * 2) - 1, s) + 0.5
	end
end

-- Bounce
local function outBounce(t)
	if t < 1 / 2.75 then
		return 7.5625 * t^2
	elseif t < 2 / 2.75 then
		t = t - 1.5 / 2.75
		return 7.5625 * t^2 + 0.75
	elseif t < 2.5 / 2.75 then
		t = t - 2.25 / 2.75
		return 7.5625 * t^2 + 0.9375
	else
		t = t - 2.625 / 2.75
		return 7.5625 * t^2 + 0.984375
	end
end

local function inBounce(t)
	return 1 - outBounce(1 - t)
end

local function inOutBounce(t)
	if t < 0.5 then return inBounce(t * 2) * 0.5 end
	return outBounce(t * 2 - 1) * 0.5 + 0.5
end

local function outInBounce(t)
	if t < 0.5 then return outBounce(t * 2) * 0.5 end
	return inBounce((t - 0.5) * 2) * 0.5 + 0.5
end

---@alias EaseTypes string
---| "linear"
---
---| "inQuad"
---| "outQuad"
---| "inOutQuad"
---| "outInQuad"
---
---| "inCubic"
---| "outCubic"
---| "inOutCubic"
---| "outInCubic"
---
---| "inQuart"
---| "outQuart"
---| "inOutQuart"
---| "outInQuart"
---
---| "inQuint"
---| "outQuint"
---| "inOutQuint"
---| "outInQuint"
---
---| "inSine"
---| "outSine"
---| "inOutSine"
---| "outInSine"
---
---| "inExpo"
---| "outExpo"
---| "inOutExpo"
---| "outInExpo"
---
---| "inCirc"
---| "outCirc"
---| "inOutCirc"
---| "outInCirc"
---
---| "inElastic"
---| "outElastic"
---| "inOutElastic"
---| "outInElastic"
---
---| "inBack"
---| "outBack"
---| "inOutBack"
---| "outInBack"
---
---| "inBounce"
---| "outBounce"
---| "inOutBounce"
---| "outInBounce"


---@class Tween
local Tween = {
	easings = {
  linear    = linear,
  inQuad    = inQuad,    outQuad    = outQuad,    inOutQuad    = inOutQuad,    outInQuad    = outInQuad,
  inCubic   = inCubic,   outCubic   = outCubic,   inOutCubic   = inOutCubic,   outInCubic   = outInCubic,
  inQuart   = inQuart,   outQuart   = outQuart,   inOutQuart   = inOutQuart,   outInQuart   = outInQuart,
  inQuint   = inQuint,   outQuint   = outQuint,   inOutQuint   = inOutQuint,   outInQuint   = outInQuint,
  inSine    = inSine,    outSine    = outSine,    inOutSine    = inOutSine,    outInSine    = outInSine,
  inExpo    = inExpo,    outExpo    = outExpo,    inOutExpo    = inOutExpo,    outInExpo    = outInExpo,
  inCirc    = inCirc,    outCirc    = outCirc,    inOutCirc    = inOutCirc,    outInCirc    = outInCirc,
  inElastic = inElastic, outElastic = outElastic, inOutElastic = inOutElastic, outInElastic = outInElastic,
  inBack    = inBack,    outBack    = outBack,    inOutBack    = inOutBack,    outInBack    = outInBack,
  inBounce  = inBounce,  outBounce  = outBounce,  inOutBounce  = inOutBounce,  outInBounce  = outInBounce
}
}

local queries = {}
local sysTime

local tweenProcessor = models:newPart("TweenProcessor","WORLD") -- set to "WORLD" so it always runs when the player is loaded

local isActive = false
local setActive ---@type function

local function process()
	sysTime = client:getSystemTime() / 1000
	for id, tween in pairs(queries) do
		local duration = (sysTime - tween.start) / tween.duration
		if duration < 1 then
			local w = tween.easing(duration)
			tween.tick(math.lerp(tween.from,tween.to, w), duration)
		else
			tween.tick(tween.to, 1)
			queries[id] = nil
			tween.onFinish()
			setActive(next(queries) and true or false)
		end
	end
end


setActive = function (toggle)
	if isActive ~= toggle then
		tweenProcessor.midRender = toggle and process or nil
		isActive = toggle
	end
end


---@class TweenInstanceCreation
---@field id any?
---
---@field from number|Vector.any
---@field to number|Vector.any
---
---@field duration number
---@field period number?
---@field overshoot number?
---@field amplitude number?
---
---@field easing EaseTypes|(fun(t: number): number|Vector.any)
---
---@field tick fun(v : number|Vector.any,t : number)
---@field onFinish function?


---An instance of a tween query
---@class TweenInstance
---@field id any
---
---@field from number|Vector.any
---@field to number|Vector.any
---
---@field duration number
---@field package start number?
---@field period number?
---@field overshoot number?
---@field amplitude number?
---
---@field easing fun(t: number): number|Vector.any
---
---@field tick fun(v : number|Vector.any,t : number)
---@field onFinish function?
local TweenInstance = {}
TweenInstance.__index = TweenInstance

local function placeholder() end


---Creates a new Tween instance
---***
---FIELDS:  
--- | Field       | Default    | Description                                                                                                                                     |
--- | ----------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
--- | `id`        | `?`        | The unique ID of the tween                                                                                                                      |
--- | `from`      | `0`        | The starting value of the tween                                                                                                                 |
--- | `to`        | `1`        | The ending value of the tween                                                                                                                   |
--- | `amplitude` | `1`        | The height of the oscillation (springiness). **only used for the elastic easings**                                                              |
--- | `period`    | `1`        | The frequency of the oscillation (how fast it bounces). **only used for the elastic easings**                                                   |
--- | `overshoot` | `1.7`      | controls how much the back easing will "go past" the starting position before moving toward the final value. **only used for the back easings** |
--- | `duration`  | `1`        | how long the tween will take in seconds                                                                                                         |
--- | `easing`    | `ar`       | The name of theeasing function to use                                                                                                           |
--- | `tick`      | `?`        | a callback function that gets called everytime the tween ticks                                                                                  |
--- | `onFinish`  | `?`        | a callback function that gets called when the tween finishes                                                                                    |
---@param cfg {
---	id: any?,
---	from: number|Vector.any,
---	to: number|Vector.any,
---	duration: number,
---	period: number?,
---	overshoot: number?,
---	amplitude: number?,
---	easing: EaseTypes|(fun(t: number): number|Vector.any),
---	tick: fun(v : number|Vector.any,t : number),
---	onFinish: function?}
---@return TweenInstance
function Tween.new(cfg)
	local id = cfg.id or #queries + 1
	---@type TweenInstance
	
	local new = {
		start = isActive and sysTime or (client:getSystemTime()/1000),
		from = cfg.from or 0,
		to = cfg.to or 1,
		period = cfg.period or 1,
		overshoot = cfg.overshoot or 5,
		duration = cfg.duration or 1,
		easing = Tween.easings[cfg.easing] or (type(cfg.easing) == "function" and cfg.easing) or linear,
		tick = cfg.tick or placeholder,
		onFinish = cfg.onFinish or placeholder,
		id = cfg.id
	}
	setmetatable(new, {__index = TweenInstance})
	new.tick(new.from, 0)
	queries[id] = new
	
	setActive(true)
	return new
end

---Stops this TweenInstance
function TweenInstance:stop()
	Tween.stop(self.id,true)
end

---Skips the given TweenInsatnce to finish instantly
function TweenInstance:skip()
	Tween.stop(self.id)
end


---Stops the tween with the given ID. if `cancel` is true, it NOT will call the `onFinish` function
---@param id any
---@param cancel boolean?
function Tween.stop(id, cancel)
	queries[id] = nil
	if not cancel and queries[id] then
		queries[id].onFinish()
	end
end

return Tween
