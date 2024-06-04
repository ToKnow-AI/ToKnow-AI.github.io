-- Function to find cell output block
---@param block pandoc.Block
---@return boolean
local function is_output_cell(block)
    return block.attr and block.attr.classes and block.attr.classes:includes("cell-output")
end

return is_output_cell