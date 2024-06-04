local ternary = require "utils.ternary"

-- Function to find and return an attribute {key,value}
---@param attributes table<string, string>
---@param key string|function - a predicate that returns true
---@return nil|table<string, string>
local function attributes_find(attributes, key)
    local predicate = ternary(type(key) == "string", function (k) return k == key end, key)
    for k, v in pairs(attributes) do
      if predicate(k) then
        return { ['key'] = k, ['value'] = v }
      end
    end
    return nil
  end
  
  -- Function to get
  ---@param block pandoc.Block
  ---@param attribute_key string|function - a string key of a function that returns bool-ish!
  ---                             The function accepts a key,value pair and their result is returned
  ---                             If a string key is passed, only the value is returned
  ---@return table<'key'|'value', string>|nil
  local get_attribute_value = function(block, attribute_key)
    if block.attr and block.attr.attributes then
      return attributes_find(block.attr.attributes, attribute_key)
    end
    return nil
  end

  return { attributes_find = attributes_find, get_attribute_value = get_attribute_value }