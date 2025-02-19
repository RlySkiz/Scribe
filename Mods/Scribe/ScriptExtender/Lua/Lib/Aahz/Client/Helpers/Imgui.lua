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
---Creates a layout table and inserts content into the middle-aligned cell 
---@param parent ExtuiTreeParent
---@param estimatedWidth number
---@param contentFunc fun(contentCell:ExtuiTableCell):...:any
---@return ... # returns result of contentFunc
function Imgui.CreateMiddleAlign(parent, estimatedWidth, contentFunc)
    -- Middle align button :deadge:
    local ltbl = parent:AddTable("", 3)
    ltbl:AddColumn("", "WidthStretch")
    ltbl:AddColumn("", "WidthFixed", estimatedWidth)
    ltbl:AddColumn("", "WidthStretch")
    local r = ltbl:AddRow()
    r:AddCell() -- empty
    local contentCell = r:AddCell()
    r:AddCell() -- empty
    if type(contentFunc) == "function" then
        return contentFunc(contentCell)
    end
end

---@class WindowCreationArgs
---@field IDContext string?
---@field Size vec2? # default {600, 550}
---@field MinSize vec2? # default {500, 500}
---@field MaxSizePercentage vec2? # default {0.5, 0.85}, half the width, 85% of the height
---@field Open boolean? # default false
---@field Closeable boolean? # default true
---@field AlwaysAutoResize boolean? # default true

--- Creates an imgui window with nice defaults
---@param name any
---@param args WindowCreationArgs?
---@return ExtuiWindow
function Imgui.CreateCommonWindow(name, args)
    name = name or ""
    args = args or {}
    args.Open = args.Open ~= nil and args.Open or false
    args.Closeable = args.Closeable ~= nil and args.Closeable or true
    -- args.AlwaysAutoResize = args.AlwaysAutoResize ~= nil and args.AlwaysAutoResize or true
    args.Size = args.Size ~= nil and args.Size or {600, 550}
    args.MinSize = args.MinSize ~= nil and args.MinSize or {500, 500}
    args.MaxSizePercentage = args.MaxSizePercentage ~= nil and args.MaxSizePercentage or { .5, .85}

    local win = Ext.IMGUI.NewWindow(name)
    win.IDContext = args.IDContext or ""
    win:SetSize(args.Size, "FirstUseEver")
    win.Open = args.Open
    win.Closeable = args.Closeable
    if args.AlwaysAutoResize then
        win.AlwaysAutoResize = args.AlwaysAutoResize
    end

    if Scribe and Scribe.AllWindows then
        table.insert(Scribe.AllWindows, win)
    else
        SWarn("Attempt to create window before scribe is ready: %s", name)
    end

    win:SetStyle("WindowMinSize", args.MinSize[1], args.MinSize[2])
    local viewportMaxConstraints = Ext.IMGUI.GetViewportSize()
    viewportMaxConstraints[1] = math.floor(viewportMaxConstraints[1] * args.MaxSizePercentage[1])
    viewportMaxConstraints[2] = math.floor(viewportMaxConstraints[2] * args.MaxSizePercentage[2])
    win:SetSizeConstraints(args.MinSize,viewportMaxConstraints)
    return win
end