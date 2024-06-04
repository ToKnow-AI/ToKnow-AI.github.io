-- string starts with function
---@param str string
---@param str_start string
---@return boolean
local function str_starts_with(str, str_start) 
    return string.sub(str, 1, #str_start) == str_start
end
return str_starts_with