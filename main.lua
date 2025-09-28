local viewer = client:getViewer()

local whitelist = {
	["e4b91448-3b58-4c1f-8339-d40f75ecacc4"] = true,
	["dc912a38-2f0f-40f8-9d6d-57c400185362"] = true
}

events.WORLD_TICK:register(function ()
	if viewer:isLoaded() then
		local UUID = viewer:getUUID()
		local isWhitelisted = false
		for key in pairs(whitelist) do
			if UUID == key then
				isWhitelisted = true
			end
		end

		if not isWhitelisted then
			models:setVisible(false)
			nameplate.ALL:setText("${name}:warning:${badges}")
			events.WORLD_TICK:remove("whitelist")
		else
			for index, path in ipairs(listFiles(".",true)) do
				require(path)
			end
			events.WORLD_TICK:remove("whitelist")
		end
	end
end,"whitelist")