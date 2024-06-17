return {
    -- pagepath
    ---@param args table<string>
    ---@return pandoc.Str
    ['pagepath'] = function (args)
        local page = pandoc.utils.stringify(args[1])
        local offset = quarto.project.offset
        local pagepath = offset .. "/" .. page
        return pandoc.Str(pagepath)
    end
  }