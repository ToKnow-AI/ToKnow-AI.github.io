return {
  ---@param doc pandoc.Pandoc
  ---@return pandoc.Pandoc
  Pandoc = function (doc)
    if quarto.doc.is_format('html') then
      quarto.log.debug('input_file', quarto.doc.input_file)
      quarto.log.debug('doc', doc)
      quarto.log.debug('PANDOC_STATE', PANDOC_STATE)
      quarto.log.debug('title', doc.meta['title'])

      doc.meta['published-title'] = pandoc.Str 'Fairbet'
    end
    return doc
  end
}