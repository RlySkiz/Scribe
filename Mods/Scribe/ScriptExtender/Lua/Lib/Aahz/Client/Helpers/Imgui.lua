Imgui = Imgui or {}

function Imgui.ScaleFactor()
    -- testing monitor for development is 1440p
    return Ext.IMGUI.GetViewportSize()[2] / 1440
end
function Imgui.ClearChildren(el)
    if el == nil or not pcall(function() return el.Handle end) then return end
    for _, v in pairs(el.Children) do
        if v.UserData ~= nil and v.UserData.SafeKeep ~= nil then
            v.UserData.SafeKeep()
        else
            v:Destroy()
        end
    end
end

---Creates a layout table and inserts content into the right-aligned cell 
---@param parent ExtuiTreeParent
---@param estimatedWidth number
---@param contentFunc fun(contentCell:ExtuiTableCell):...:any
---@param sameLine boolean? # true = layoutTable.SameLine = true
---@return ... # returns result of contentFunc
function Imgui.CreateRightAlign(parent, estimatedWidth, contentFunc, sameLine)
    -- Right align button :deadge:
    local ltbl = parent:AddTable("", 2)
    if sameLine then ltbl.SameLine = true end
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
---@param sameLine boolean? # true = layoutTable.SameLine = true
---@return ... # returns result of contentFunc
function Imgui.CreateMiddleAlign(parent, estimatedWidth, contentFunc, sameLine)
    -- Middle align button :deadge:
    local ltbl = parent:AddTable("", 3)
    if sameLine then ltbl.SameLine = true end
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
    if args.IDContext then
        win.IDContext = args.IDContext
    end
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

Imgui.ThemeColor = {
    ["Accent1"] = "#463257",
    ["Accent2"] = "#95724B",
    ["Highlight"] = "#8C0000",
    ["Header"] = "#913535",
    ["MainHover"] = "#0d9c3f",
    ["MainActive"] = "#1E8146",
    ["MainText"] = "#DBCAAE",
    ["Main"] = "#F1D099",
    ["MainActive2"] = "#523c28",
    ["Grey"] = "#696969",
    ["DarkGrey"] = "#505050",
    ["Black1"] = "#242424",
    ["Black2"] = "#0c0c0c",
}
Imgui.Colors = {
    FailColor       = Helpers.Color.HexToNormalizedRGBA("#FF0000", 1),
    SuccessColor    = Helpers.Color.HexToNormalizedRGBA("#00FF00", 1),
    NeutralColor    = Helpers.Color.HexToNormalizedRGBA("#b2b2b2", 1),
    Red             = Helpers.Color.HexToNormalizedRGBA("#FF0000", 1),
    Green           = Helpers.Color.HexToNormalizedRGBA("#00FF00", 1),
    Neutral         = Helpers.Color.HexToNormalizedRGBA("#b2b2b2", 1),
    Blue            = Helpers.Color.HexToNormalizedRGBA("#1cb2db", 1),
    BG3Green        = Helpers.Color.HexToNormalizedRGBA("#A0B056", 1),
    BG3Blue         = Helpers.Color.HexToNormalizedRGBA("#0c4961", 1),
    BG3Brown        = Helpers.Color.HexToNormalizedRGBA("#523c28", 1),
    Tan             = Helpers.Color.HexToNormalizedRGBA("#99724c", 1),
    SkyBlue         = Helpers.Color.HexToNormalizedRGBA("#1FCCEC", 1),
    RealSkyBlue     = Helpers.Color.HexToNormalizedRGBA("#87CEEB", 1),
    DeepSkyBlue     = Helpers.Color.HexToNormalizedRGBA("#00BFFF", 1),
    Cyan            = Helpers.Color.HexToNormalizedRGBA("#00FFFF", 1),
    Aqua            = Helpers.Color.HexToNormalizedRGBA("#00FFFF", 1),
    DodgerBlue      = Helpers.Color.HexToNormalizedRGBA("#1E90FF", 1),
    Magenta         = Helpers.Color.HexToNormalizedRGBA("#FF00FF", 1),
    Purple          = Helpers.Color.HexToNormalizedRGBA("#800080", 1),
    Lavender        = Helpers.Color.HexToNormalizedRGBA("#E6E6FA", 1),
    SlateBlue       = Helpers.Color.HexToNormalizedRGBA("#6A5ACD", 1),
    MediumPurple    = Helpers.Color.HexToNormalizedRGBA("#9370DB", 1),
    DarkPurple      = Helpers.Color.HexToNormalizedRGBA("#331f3f", 1),
    Yellow          = Helpers.Color.HexToNormalizedRGBA("#FFFF00", 1),
    Gold            = Helpers.Color.HexToNormalizedRGBA("#FFD700", 1),
    Sienna          = Helpers.Color.HexToNormalizedRGBA("#A0522D", 1),
    LightGreen      = Helpers.Color.HexToNormalizedRGBA("#90EE90", 1),
    MediumSeaGreen  = Helpers.Color.HexToNormalizedRGBA("#3CB371", 1),
    Olive           = Helpers.Color.HexToNormalizedRGBA("#6B8E23", 1),
    MediumAquamarine= Helpers.Color.HexToNormalizedRGBA("#66CDAA", 1),
    Aquamarine      = Helpers.Color.HexToNormalizedRGBA("#7FFFD4", 1),
    Orange          = Helpers.Color.HexToNormalizedRGBA("#FFA500", 1),
    DarkOrange      = Helpers.Color.HexToNormalizedRGBA("#FF8C00", 1),
    OrangeRed       = Helpers.Color.HexToNormalizedRGBA("#FF4500", 1),
    Coral           = Helpers.Color.HexToNormalizedRGBA("#FF7F50", 1),
    Pink            = Helpers.Color.HexToNormalizedRGBA("#FFC0CB", 1),
    LightPink       = Helpers.Color.HexToNormalizedRGBA("#FFEDFA", 1),
    HotPink         = Helpers.Color.HexToNormalizedRGBA("#FF69B4", 1),
    DeepPink        = Helpers.Color.HexToNormalizedRGBA("#FF1493", 1),
    PaleVioletRed   = Helpers.Color.HexToNormalizedRGBA("#DB7093", 1),
    Crimson         = Helpers.Color.HexToNormalizedRGBA("#DC143C", 1),
    FireBrick       = Helpers.Color.HexToNormalizedRGBA("#B22222", 1),
    DarkRed         = Helpers.Color.HexToNormalizedRGBA("#8C0000", 1),
    --Lights/Whites
    White           = Helpers.Color.HexToNormalizedRGBA("#FFFFFF", 1),
    Snow            = Helpers.Color.HexToNormalizedRGBA("#FFFAFA", 1),
    HoneyDew        = Helpers.Color.HexToNormalizedRGBA("#F0FFF0", 1),
    Mint            = Helpers.Color.HexToNormalizedRGBA("#F5FFFA", 1),
    Azure           = Helpers.Color.HexToNormalizedRGBA("#F0FFFF", 1),
    AliceBlue       = Helpers.Color.HexToNormalizedRGBA("#F0F8FF", 1),
    LightGray       = Helpers.Color.HexToNormalizedRGBA("#D3D3D3", 1),
    Silver          = Helpers.Color.HexToNormalizedRGBA("#C0C0C0", 1),
    Gray            = Helpers.Color.HexToNormalizedRGBA("#A9A9A9", 1),
    MediumGray      = Helpers.Color.HexToNormalizedRGBA("#808080", 1),
    DarkGray        = Helpers.Color.HexToNormalizedRGBA("#696969", 1),
    Black           = Helpers.Color.HexToNormalizedRGBA("#000000", 1),
}

---@param el ExtuiStyledRenderable
function Imgui.NewStyling(el)
    if el == nil then return end

    local color = {
        ["Border"]                = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["BorderShadow"]          = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black1, 0.78),
        ["Button"]                = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Main, 0.14),
        ["ButtonActive"]          = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive, 1.00),
        ["ButtonHovered"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainHover, 0.86),
        ["CheckMark"]             = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainHover, 1.00),
        ["ChildBg"]               = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 0.88),
        ["DragDropTarget"]        = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainHover, 0.78),
        ["FrameBg"]               = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 1.00), -- also checkboxes, scrollbars
        ["FrameBgActive"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["FrameBgHovered"]        = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 0.78),
        ["Header"]                = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Header, 0.76),
        ["HeaderActive"]          = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["HeaderHovered"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 0.86),
        ["MenuBarBg"]             = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black1, 0.87),
        ["ModalWindowDimBg"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 0.73),
        ["NavHighlight"]          = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Highlight, 0.78),
        ["NavWindowingDimBg"]     = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black1, 0.78),
        ["NavWindowingHighlight"] = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Highlight, 0.78),
        ["PlotHistogram"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainText, 0.63),
        ["PlotHistogramHovered"]  = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 1.00),
        ["PlotLines"]             = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainText, 0.63),
        ["PlotLinesHovered"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 1.00),
        ["PopupBg"]               = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 0.95), -- also tooltips
        ["ResizeGrip"]            = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Main, 0.04),
        ["ResizeGripActive"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["ResizeGripHovered"]     = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 0.78),
        ["ScrollbarBg"]           = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 1.00),
        ["ScrollbarGrab"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 1.00),
        ["ScrollbarGrabActive"]   = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["ScrollbarGrabHovered"]  = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainHover, 0.78),
        ["Separator"]             = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 1.00),
        ["SeparatorActive"]       = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["SeparatorHovered"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 0.78),
        ["SliderGrab"]            = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Main, 0.14),
        ["SliderGrabActive"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["Tab"]                   = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Header, 0.78),
        ["TabActive"]             = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive, 0.78),
        ["TabHovered"]            = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainHover, 0.78),
        ["TableBorderLight"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent2, 0.78),
        ["TableBorderStrong"]     = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Accent1, 0.78),
        ["TableHeaderBg"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Header, 0.67),
        ["TableRowBg"]            = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.DarkGrey, 0.53),
        ["TableRowBgAlt"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Grey, 0.63),
        ["TabUnfocused"]          = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black2, 0.78),
        ["TabUnfocusedActive"]    = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black2, 0.78),
        ["Text"]                  = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainText, 0.78),
        ["TextDisabled"]          = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainText, 0.28),
        ["TextSelectedBg"]        = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Header, 0.43),
        ["TitleBg"]               = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black1, 1.00),
        ["TitleBgActive"]         = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.MainActive2, 1.00),
        ["TitleBgCollapsed"]      = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black2, 0.85),
        ["WindowBg"]              = Helpers.Color.HexToNormalizedRGBA(Imgui.ThemeColor.Black1, 0.95),
    }
    for k, v in pairs(color) do
        el:SetColor(k, v)
    end
    local style = {
        --["Alpha"]                   = 1.0,
        ["ButtonTextAlign"]         = {0.5, 0.5}, -- vec2?
        ["CellPadding"]             = {4.0, 4.0}, -- vec2?
        --["ChildBorderSize"]         = 2.0,
        ["ChildRounding"]           = 4.0,
        ["DisabledAlpha"]           = 0.7,
        --["FrameBorderSize"]         = 1.0,
        ["FramePadding"]            = {4.0, 4.0}, -- vec2?
        ["FrameRounding"]           = 20.0,
        ["GrabMinSize"]             = 16.0,
        ["GrabRounding"]            = 4.0,
        ["IndentSpacing"]           = 21.0,
        ["ItemInnerSpacing"]        = {4.0, 4.0}, -- vec2?
        ["ItemSpacing"]             = {8.0, 8.0}, -- vec2?
        --["PopupBorderSize"]         = 1.0,
        ["PopupRounding"]           = 2.0,
        ["ScrollbarRounding"]       = 9.0,
        ["ScrollbarSize"]           = 20.0,
        --["SelectableTextAlign"]     = {0.0, 0.0}, -- vec2?
        ["SeparatorTextAlign"]      = {0.5, 0.5}, -- vec2?
        ["SeparatorTextBorderSize"] = 4.0,
        ["SeparatorTextPadding"]    = {5.0, 3}, -- vec2?
        ["TabBarBorderSize"]        = 3.0,
        ["TabRounding"]             = 20.0,
        ["WindowBorderSize"]        = 2.0,
        -- ["WindowMinSize"]           = {250.0, 850.0}, -- vec2? panel-size
        ["WindowPadding"]           = { 10, 8}, -- vec2? (10,8 better?)
        ["WindowRounding"]          = 20.0,
        ["WindowTitleAlign"]        = {0.5, 0.5}, -- vec2?
    }
    for k, v in pairs(style) do
        if type(v) == "table" then
            el:SetStyle(k, v[1], v[2])
        else
            el:SetStyle(k, v)
        end
    end
end

---Sets common style vars for popup
---@param popup ExtuiPopup|ExtuiTooltip
---@return ExtuiPopup|ExtuiTooltip
function Imgui.SetPopupStyle(popup)
    popup:SetColor("PopupBg", {0.18, 0.15, 0.15, 1.00})
    popup:SetStyle("PopupBorderSize", 2)
    popup:SetColor("BorderShadow", {0,0,0,0.4})
    popup:SetColor("Border", Imgui.Colors.Tan)
    popup:SetStyle("WindowPadding", 15, 15)
    return popup
end
---Sets common style vars for a chunky separator text
---@generic T 
---@param e `T`|ExtuiStyledRenderable
---@return T
function Imgui.SetChunkySeparator(e)
    e:SetStyle("SeparatorTextBorderSize", 10)
    e:SetStyle("SeparatorTextAlign", 0.5, 0.4)
    e:SetStyle("SeparatorTextPadding", 0, 0)
    return e
end

---@param tooltip ExtuiTooltip
---@param contentFunc? fun(tooltip:ExtuiTooltip):ExtuiTooltip?
---@return ExtuiTooltip?
function Imgui.CreateSimpleTooltip(tooltip, contentFunc)
    Imgui.SetPopupStyle(tooltip)
    if contentFunc then
        contentFunc(tooltip)
    end
    return tooltip
end
---Sets up imgui table with common defaults
---@param t ExtuiTable
---@param borders boolean true|false
---@param rowBg boolean true|false Alternating row colors
---@param sizingString nil|"SizingFixedFit"|"SizingFixedSame"|"SizingStretchProp"|"SizingStretchSame" sizing options
---@param noClip boolean NoClip setting
---@param noHostExtendX boolean Whether or not table behaves, seemingly
---@return ExtuiTable
function Imgui.SetupTable(t, borders, rowBg, sizingString, noClip, noHostExtendX)
    t.Borders = borders or false
    t.RowBg = rowBg or false
    local sizings = {
        ["SizingFixedFit"] = true,
        ["SizingFixedSame"] = true,
        ["SizingStretchProp"] = true,
        ["SizingStretchSame"] = true,
    }
    if sizingString ~= nil and sizings[sizingString] then
        t[sizingString] = true
    end
    t.NoClip = noClip or false
    t.NoHostExtendX = noHostExtendX or false
    return t
end

---@class ImguiCombo
---@field Parent ExtuiCombo
Imgui.Combo = {}
---Gets the selected option
---@param combo ExtuiCombo
---@return string
function Imgui.Combo.GetSelected(combo)
    return combo.Options[combo.SelectedIndex+1]
end

---@class ColorText : {Text:string, Color:vec4}

--- Creates a new text group from a split text array
---@param group ExtuiTreeParent # Group ideally with an element for the new colored text to be same-lined onto, but one will also be provided if none exists
---@param charSplit ColorText[]
---@return ExtuiTreeParent
function Imgui.BuildColorText(group, charSplit)
    if #group.Children == 0 then
        group:AddText("") -- placeholder to sameline
    end

    local function newText(g, splitText, splitColor)
        local t = g:AddText(splitText)
        t:SetStyle("ItemSpacing", 0)
        t:SetColor("Text", splitColor)
        t.SameLine = true
        return t
    end

    for _, ct in ipairs(charSplit) do
        newText(group, ct.Text, ct.Color)
    end

    return group
end

--- Splits a string into ColorText array, highlighting illegal characters
---@param str string
---@param normalColor vec4
---@param highlightColor vec4
---@return ColorText[]
function Imgui.SanitizeStringColorTextSplit(str, normalColor, highlightColor)
    local result = {}
    local charMap = {
        ["<"] = true, [">"] = true, [":"] = true, ['"'] = true, --["/"] = true, --subfolder is fine-ish
        ["\\"] = true, ["|"] = true, ["?"] = true, ["*"] = true
    }

    local currentColor = normalColor
    local currentText = ""

    local function addCurrentText()
        if #currentText > 0 then
            table.insert(result, { Text = currentText, Color = currentColor })
            currentText = ""
        end
    end

    local i = 1
    while i <= #str do
        -- Annoying processing for UTF8 jank
        local c = string.sub(str, i, i)
        local byte = string.byte(c, 1)
        local charLength = 1
        if byte >= 192 and byte <= 223 then
            charLength = 2
        elseif byte >= 224 and byte <= 239 then
            charLength = 3
        elseif byte >= 240 and byte <= 247 then
            charLength = 4
        end

        local char = string.sub(str, i, i + charLength - 1)
        local color = (charMap[char] or Helpers.Format.NonEnglishCharMap[char]) and highlightColor or normalColor

        if color ~= currentColor then
            addCurrentText()
            currentColor = color
        end
        currentText = currentText .. char
        i = i + charLength
    end
    addCurrentText()

    return result
end

-- -- Example usage: sanitizing filename and displaying in Imgui
-- local dumbPath = "Scribe/_Dumps/[C]Boлo.json"
-- RPrint(dumbPath)
-- local charSplit = Imgui.SanitizeStringColorTextSplit(dumbPath, Imgui.Colors.White, Imgui.Colors.Red)
-- RPrint(charSplit)
-- local testWin = Ext.IMGUI.NewWindow("TestWin")
-- local newTextGroup = Imgui.BuildColorText(testWin, charSplit)
-- testWin:AddText(dumbPath)