local read_metadata = require "utils.read_metadata"

-- compare_categories
---@param main_categories table
---@param sub_categories table
---@return boolean
local compare_categories = function(main_categories, sub_categories)
  for _, main_category in ipairs(main_categories) do
    for _, sub_category in ipairs(sub_categories) do
      if pandoc.utils.stringify(main_category) == pandoc.utils.stringify(sub_category) then
        return true
      end
    end
  end
  return false
end

return {
    ---@param doc pandoc.Pandoc
    ---@return pandoc.Pandoc|nil
    Pandoc = function (doc)
        local main_categories = read_metadata(quarto.project.directory .. '/_index.yml')['categories']
        local sub_categories = doc.meta['categories']
        local has_main_category = 
          type(main_categories) == "table" and 
          type(sub_categories) == "table" and 
          compare_categories(main_categories, sub_categories)
        if not has_main_category then
          error(quarto.doc.input_file .. " HAS NO MAIN CATEGORY!")
          os.exit(1)  -- Exit with a status code (non-zero indicates an error)
          return 
        end
      return doc
    end
  }