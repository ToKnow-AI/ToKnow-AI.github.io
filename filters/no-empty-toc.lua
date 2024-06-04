return {
  ---@param doc pandoc.Pandoc
  ---@return pandoc.Pandoc
  Pandoc = function (doc)
    local has_headers = false
    local meta = doc.meta
    local blocks = doc.blocks:walk {
      ---@param header pandoc.Header
      ---@return pandoc.Header
      Header = function (header)
        has_headers = true
        return header
      end
    }

    meta['toc'] = has_headers
    return pandoc.Pandoc(blocks, meta)
  end
}
