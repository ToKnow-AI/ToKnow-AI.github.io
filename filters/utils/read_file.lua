-- Function to create a Github link
-- https://github.com/feynlee/code-insertion/blob/c7aa90f63a176c40578f3e427c1898272f44b51c/_extensions/code-insertion/code-insertion.lua#L1
---@param file string
---@return string
local function read_file(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
  end

  return read_file