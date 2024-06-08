local attributes = require "utils.attributes"

---comment
---@param attribute_value boolean|string|table<string, string>
---@param block pandoc.Block|pandoc.Inline
---@param main_meta pandoc.MetaBlocks
---@param walk_callback function
---@return pandoc.Block,pandoc.MetaBlocks
local walk_callback_proxy = function (attribute_value, block, main_meta, walk_callback)
  local nparams = debug.getinfo(walk_callback).nparams
  if nparams == 3 then
    return walk_callback(attribute_value, block, main_meta)
  else
    local sub_block = walk_callback(attribute_value, block)
    return sub_block, main_meta
  end
end

-- elements_walker
---@param elements pandoc.List|pandoc.Blocks|pandoc.Inlines
---@param get_and_update_meta function - function to get and update the main meta
---@param attribute_value table<'key'|'value', string>|nil - the current attribute value
---@param attribute_key function|string - a predicate to match the attribute key
---@param walk_callback function - callback when an element is matched
---@param children_predicate function|nil - an optional predicate function that matches the element itseld and its children
---@return pandoc.List
function elements_walker (elements, get_and_update_meta, attribute_value, attribute_key, walk_callback, children_predicate)
  local new_elements = pandoc.List:new{}
  if elements and #elements > 0 then
    for _, element in ipairs(elements) do
      local attr_value = attribute_value or attributes.get_attribute_value(element, attribute_key)
      if attr_value then
        if children_predicate then
          if children_predicate(element) then
            local meta, update_meta = get_and_update_meta()
            local new_element, new_meta = walk_callback_proxy(attr_value, element, meta, walk_callback)
            update_meta(new_meta)
            if new_element then
              new_elements:insert(new_element)
            end
          else
            if element.content then
              element.content = elements_walker(element.content, get_and_update_meta, attr_value, attribute_key, walk_callback, children_predicate)
            end
            new_elements:insert(element)
          end
        else
          local meta, update_meta = get_and_update_meta()
          local new_element, new_meta = walk_callback_proxy(attr_value, element, meta, walk_callback)
          update_meta(new_meta)
          if new_element then
            new_elements:insert(new_element)
          end
        end
      else
        if element.content then
          element.content = elements_walker(element.content, get_and_update_meta, nil, attribute_key, walk_callback, children_predicate)
        end
        new_elements:insert(element)
      end
    end
  end
  return new_elements
end

-- Function to parse quarto special comments, such as:
--        #| video-src: "https://www.youtube.com/watch?v=kCc8FmEb1nY"
--        #| output-when-format: "{format}"
--        #| output-when-format-{format}: "{template}"
---@param attribute_key string|function - comment name: video-src, output-when-format, output-when-format-{format}
---@param walk_callback function - a function that receives a pandoc.Block and returns a pandoc.Block, or
--                               - a function that receives (pandoc.Block,pandoc.MetaBlocks) and returns (pandoc.Block,pandoc.MetaBlocks)
---@param children_predicate function|nil - an optional predicate function that receives pandoc.Block and returns a boolean
---                              - it ismused to match siblings where attribute_key
---@return table<'Pandoc', function>
local notebook_special_comments_walker = function(attribute_key, walk_callback, children_predicate)
  return {
    ---@param doc pandoc.Pandoc
    ---@return pandoc.Pandoc
    Pandoc = function (doc)
      local meta = doc.meta
      local get_and_update_meta = function ()
        return meta, function (updated_meta)
          meta = updated_meta
        end
      end
      local blocks = elements_walker(
        doc.blocks, 
        get_and_update_meta, 
        nil, 
        attribute_key, 
        walk_callback, 
        children_predicate)

      return pandoc.Pandoc(blocks, meta)
    end
  }
end

return notebook_special_comments_walker