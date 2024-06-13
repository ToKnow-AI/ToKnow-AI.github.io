local read_file = require "utils.read_file"

-- Funtion to extract the metadata of a file, given a file_name
---@param file_name string
--- @return pandoc.MetaValue
local function read_metadata(file_name)
    local yml_text = read_file(file_name)
    local yml_doc = pandoc.read('---\n' .. yml_text .. '\n---', "markdown")
    return yml_doc.meta
end

return read_metadata