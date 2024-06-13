return {
  ['year'] = function ()
    return pandoc.Str(pandoc.utils.stringify(os.date("%Y")))
  end
}