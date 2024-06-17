-- read terminal
---@param command string
---@return string|nil
local function terminal(command)
  local p = io.popen(command)
  if p then
    local output = p:read('*all')
    p:close()
    return output
  end
  return nil
end

return {
  ['bash'] = function (args)
    local command = pandoc.utils.stringify(args[1])
    local output = terminal(command)
    if output ~= nil then
      return pandoc.Str(output)
    else
      return pandoc.Null()
    end
  end
}