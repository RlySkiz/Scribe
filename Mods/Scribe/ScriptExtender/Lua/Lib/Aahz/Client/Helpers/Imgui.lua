Imgui = Imgui or {}

---Creates a layout table and inserts content into the right-aligned cell 
---@param parent ExtuiTreeParent
---@param estimatedWidth number
---@param contentFunc fun(contentCell:ExtuiTableCell):...:any
---@return ... # returns result of contentFunc
function Imgui.CreateRightAlign(parent, estimatedWidth, contentFunc)
    -- Right align button :deadge:
    local ltbl = parent:AddTable("", 2)
    ltbl:AddColumn("", "WidthStretch")
    ltbl:AddColumn("", "WidthFixed", estimatedWidth)
    local r = ltbl:AddRow()
    r:AddCell() -- empty
    local contentCell = r:AddCell()
    if type(contentFunc) == "function" then
        return contentFunc(contentCell)
    end
end