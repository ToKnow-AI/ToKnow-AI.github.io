---Funtion to evaluate ternary operation - https://stackoverflow.com/a/5529577
---@param cond any - able value that will resolve to boolish
---@param T any
---@param F any
---@return any
local function ternary (cond, T, F )
    if cond then 
        return T 
    else 
        return F 
    end
end

return ternary