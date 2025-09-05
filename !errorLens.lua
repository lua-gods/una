---@diagnostic disable: undefined-doc-name, param-type-mismatch, undefined-field

if not events.ERROR then return end

---@diagnostic disable: undefined-field
local str = {}

function str.split(string,separator)
	local t = {}
	for str in string.gmatch(string, "([^" .. separator .. "]+)") do
		table.insert(t, str)
	end
	return t
end


function str.separateLines(str)
	local lines = {}
	-- capture everything up to \n (including empty)
	for line in str:gmatch("([^\n]*)\n?") do
		if line ~= "" or #lines > 0 then
			-- avoid adding an extra empty string at the end
			table.insert(lines, line)
		end
	end
	return lines
end




local function tblCopy(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = type(value) == "table" and tblCopy(value) or value
	end
	return copy
end

local function shallowCopy(tbl)
	local copy = {}
	for key, value in pairs(tbl) do copy[key] = value end
	return copy
end


---@param component table
---@param match string|string[]
---@param apply fun(component: table): table
---@return table
local function jsonSplitParser(component,match,apply)
	local from, to = 0,0
	if match.byte then -- is string
		match = {match}
	end
	for index, value in ipairs(match) do
		from,to = string.find(component.text, value, to+1)
		
		if from then
			local extra = {
				shallowCopy(component),
				shallowCopy(component),
				tblCopy(component)
			}
			extra[1].text = string.sub(component.text, 1, from-1)
			extra[2].text = string.sub(component.text, from, to)
			extra[3].text = string.sub(component.text, to+1,-1)
			component.text = ""
			component.extra = extra
			
			extra[1] = jsonSplitParser(extra[1],match,apply)
			extra[2] = apply(extra[2]) or extra[2]
			extra[3] = jsonSplitParser(extra[3],match,apply)
			
			extra[1].extra = nil
			extra[2].extra = nil
			return component
		else
			if component.extra then
				for i, subComponent in ipairs(component.extra) do
					component[i] = jsonSplitParser(subComponent, match, apply)
				end
			end
			return component
		end
	end
end


---@param component table
---@param match string|string[]
---@param apply fun(component: table)
---@return table
local function jsonSplit(component,match,apply)
	return jsonSplitParser(tblCopy(component),match,apply)
end


---@param path string
---@return Minecraft.RawJSONText.Component
local function stylePath(path)
	local result = {} --- @type Minecraft.RawJSONText.Component[]

	local points = str.split(path, "/")

	for i, value in ipairs(points) do
		if i ~= #points then
			result[i * 2 - 1] = {
				text = value,
				color = "#daa74a",
			}
			result[i * 2] = {
				text = "/",
				color = "dark_gray",
			}
		else
			result[i * 2 - 1] = {
				text = value,
				color = "#6d99f8",
			}
		end
	end

	return result
end


local annotation = {
	{
		color = "red",
		match = {"%s?if%s","%s?then%s","%s?else%s","%s?elseif%s","%s?end%s","%s?until%s","%s?repeat%s","%s?for%s","%s?while%s","%s?function%s","%s?local%s","%s?do%s","%s?return%s","%s?break%s","%s?continue%s","%s?goto%s","%s?in%s"},
	},
	{
		color = "red",
		match = {"=", "~=", "==", "%+","%-","%*","%/","%%","%^","%.%.%."},
	},
	{
		color = "#ca8cf3",
		match = {"%a+%("}
	},
	{
		color = "#ffbb28",
		match = {"%\"[^\"]+\""},
	},
	{
		color = "#5d95ff",
		match = {"%(","%)",","},
	},
}

---@param path string
---@param line integer
local function previewLine(path, line, preview_size)
	preview_size = 2
	local lines = str.separateLines(getScript(path))
	local output = {}
	output[#output+1] = {text="",color="white"}
	output[#output+1] = stylePath(path)
	output[#output+1] = {text=" "..("-"):rep(math.max(1,(150-client.getTextWidth(path..line..":"))/5)+1).."\n"}
	
	line = math.clamp(line, preview_size, #lines - preview_size)
	for i = math.max(line - preview_size, 1), math.min(line + preview_size, #lines), 1 do
		local json = {text=lines[i].." "}
		for _, data in pairs(annotation) do
			json = jsonSplit(json,data.match,
			function(component)
				component.color = data.color
			end)
		end
		
		output[#output+1] = {text=">",color=line == i and "red" or "black"}
		output[#output+1] = {text="",extra={{text=i.." ", color="aqua"},json}}
		output[#output+1] = {text="\n"}
	end
	return output
end





events.ERROR:register(function(err)
	local lines = str.split(err, "\n")
	---@type Minecraft.RawJSONText.Component[]
	local final = {}

	local mPath, mLine, mMsg = lines[1]:match("^([^:]+):(%d+) (.+)")

	
	
	final[1] = {
		text = "",
		extra = {
			{
				text = "❌",
				color = "red",
			},
		}
	}
	final[3] = previewLine(mPath, tonumber(mLine))
	final[4] = {text=("-"):rep(150/5-2).."\n"}
	final[5] = {text=mMsg.."\n",color="red"}
	
	for i = 4, #lines - 1, 1 do
		local line = lines[i]:sub(2, -1)
		local splits = str.split(line, ":")

		local path = splits[1]
		local line = splits[2]
		local msg = splits[3]

		local pathLength = client.getTextWidth(path..line.."↓:")
		
		local method = msg:match("'([^']+)'$")
		if method then
			method = method .. "()"
		else
			method = ""
		end
		
		local json = { ---@type Minecraft.RawJSONText.Component
			text = "",
			extra = {
				{
					text =  "↓",
					color = "gray",
					hoverEvent = {
						action = "show_text",
						contents = previewLine(path, tonumber(line)),
					}
				},
				{
					text = "",
					color = "red",
					extra = stylePath(path),
					hoverEvent = {
						action = "show_text",
						contents = previewLine(path, tonumber(line)),
					}
				},
				{
					text = ":",
					color = "gray",
					hoverEvent = {
						action = "show_text",
						contents = previewLine(path, tonumber(line)),
					}
				},
				{
					text = line,
					color = "aqua",
				},
				{
					text = ("."):rep(math.max(1,(165-pathLength)/2)),
					color="black"
				},
				{
					text = method,
					color = "#a0a0a0",
				},
				{
					text = "\n",
				},
			},
		}
		
		table.insert(final, 1,json)
	end


	--print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
	printJson(toJson(final))

	
	
	goofy:stopAvatar()
	return true
end)
