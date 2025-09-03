---@diagnostic disable: lowercase-global

---Takes a path to the script, and the contents of the script.  
---If the contents are nil, then the script is removed from the avatar.
---@param path string
---@param code string?
function addScript(path, code) end

---Returns a table of all scriptps in the avatar with the name as the index and the contents as the value.  
---If a string is passed; then all scripts starting with the string will be returned
---@param match string?
---@return {[string]: string}
function getScripts(match) return {} end

---Takes a path to the script and returns the contents of the script.  
---This is different from using avatar:getNBT since the NBT stores byte arrays instead of a string.
---@param scriptName string
---@return string
function getScript(scriptName) return '' end