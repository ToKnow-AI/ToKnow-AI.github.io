return {
  ---@param doc pandoc.Pandoc
  ---@return pandoc.Pandoc
  Pandoc = function (doc)
    quarto.log.debug(doc)
    return doc
  end
}