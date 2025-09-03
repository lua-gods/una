---@diagnostic disable: lowercase-global

---@class GoofyAPI
goofy = {}

---@alias GoofyAPI.GUIElement string
---| "HOTBAR"
---| "JUMP_METER"
---| "EXPERIENCE_BAR"
---| "SELECTED_ITEM_NAME"
---| "SCOREBOARD_SIDEBAR"
---| "PLAYER_HEALTH"
---| "VEHICLE_HEALTH"
---| "TEXTURE_OVERLAY"
---| "SPYGLASS_OVERLAY"
---| "VIGNETTE"
---| "PORTAL_OVERLAY"
---| "CHAT"
---| "BOSSBAR"
---| "TAB_LIST"

---Sets whether to disable running the specified GUI element.
---@param element GoofyAPI.GUIElement
---@param disableRender boolean
function goofy:setDisableGUIElement(element,disableRender)
end