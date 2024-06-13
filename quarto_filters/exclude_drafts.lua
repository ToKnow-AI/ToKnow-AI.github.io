
-- remove drafts
---@param meta pandoc.MetaBlocks
---@return boolean
local function is_draft(meta)
  local draft = meta["draft"]
  if draft and (true == draft or true == pandoc.utils.stringify(draft)) then
    return true
  else
    return false
  end
end

return {
  ---@param doc pandoc.Pandoc
  ---@return pandoc.Pandoc|nil
  Pandoc = function (doc)
    if is_draft(doc.meta) then
      quarto.log.debug('RENDER', doc.meta)
      return pandoc.Pandoc({})
    end
    return doc
  end
}