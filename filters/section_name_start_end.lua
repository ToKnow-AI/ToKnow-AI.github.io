-- section_name_elements_walker
---@param elements pandoc.List|pandoc.Blocks|pandoc.Inlines - elements
---@param start_predicate function
---@param end_predicate function
---@param skipped_blocks table<string, pandoc.List>|nil
---@return pandoc.List, table<string, pandoc.List>|nil
function section_name_elements_walker (elements, start_predicate, end_predicate, skipped_blocks)
  local new_elements = pandoc.List:new{}
  if elements and #elements > 0 then
    for _, element in ipairs(elements) do
      local start_key = start_predicate(element)
      if start_key then
        start_predicate = function() return start_key end
        skipped_blocks = skipped_blocks or {}
      
        local end_key = end_predicate(element)
        if end_key then
          start_predicate = function() return nil end
        else
          if skipped_blocks[start_key] then
            skipped_blocks[start_key]:insert(element)
            new_elements:insert(pandoc.Para('But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain'))
          else
            skipped_blocks[start_key] = skipped_blocks[start_key] or pandoc.List:new{}
          end
        end
      else
        if element.content then
          element.content = section_name_elements_walker(element.content, start_predicate, end_predicate, skipped_blocks)
        end
        new_elements:insert(element)
      end
    end
  end
  return new_elements, skipped_blocks
end


-- print(get_first_key_value("<!-- { ['section-name-start'] = 'description' } -->"))
---@param comment string
---@return [string,string] | nil
local get_first_key_value = function (comment)
  local pattern = "<!%-%-%s*{(.-)}%s*%-%->"
  local content = string.match(comment, pattern)
  if content then
    local table = load('return {' .. content .. '}')()
    for k, v in pairs(table) do
        return k, v
    end
  end
  return nil
end

-- start_predicate
---@param block_or_inline pandoc.Block|pandoc.Inline
---@return string|nil
local start_predicate = function (block_or_inline)
  if block_or_inline.format and block_or_inline.format == 'html' and block_or_inline.text then
    local key, value = get_first_key_value(block_or_inline.text)
    if key == 'section_name_start' and value then
      return value
    end
  end
  return nil
end

-- end_predicate
---@param block_or_inline pandoc.Block|pandoc.Inline
---@return string|nil
local end_predicate = function (block_or_inline)
  if block_or_inline.format and block_or_inline.format == 'html' and block_or_inline.text then
    local key, value = get_first_key_value(block_or_inline.text)
    if key == 'section_name_end' and value then
      return value
    end
  end
  return nil
end

return {
  Pandoc = function(doc)
    local meta = doc.meta
    local blocks, skipped_blocks = section_name_elements_walker(
      doc.blocks, 
      start_predicate, 
      end_predicate)

    if skipped_blocks then
      for key, value_blocks in pairs(skipped_blocks) do
        local skipped_blocks_str = pandoc.utils.stringify(value_blocks)
        quarto.log.debug(key, skipped_blocks_str)
        if skipped_blocks_str then
          meta[key] = pandoc.MetaString(skipped_blocks_str)
        end
      end
    end

    return pandoc.Pandoc(blocks, meta)
  end
}