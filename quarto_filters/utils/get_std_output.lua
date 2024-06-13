-- Function to get readFile output
---@param command string
---@return string
local function get_std_output(command)
  local handle = assert(io.popen(command))
  local result = handle:read("*a")
  handle:close()
  return result:sub(1, -2) -- Trim the trailing newline
end

return get_std_output