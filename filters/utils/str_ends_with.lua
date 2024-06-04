-- Function to check if string ends with ends with
---@param str string
---@param ext string
---@return string
local function str_ends_with(str, ext)
    return string.sub(str, -#ext) == ext
end

return str_ends_with