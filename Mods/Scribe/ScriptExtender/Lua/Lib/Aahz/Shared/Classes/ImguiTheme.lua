local HexToNormalizedRGBA = Helpers.Color.HexToNormalizedRGBA

---@alias HexColor string "#FFFFFF", "#000000", etc. (usage mostly for IDE color hints)
---@alias ThemeKey
---| 'Accent1' # ChildBg, FrameBg, ModalWindowDimBg, PopupBg, ScrollbarBg, Separator, TableBorderStrong
---| 'Accent2' # FrameBgHovered, HeaderHovered, PlotHistogramHovered, PlotLinesHovered, ResizeGripHovered, ScrollbarGrab, SeparatorHovered, TabHovered, TableBorderLight
---| 'Highlight' # NavHighlight, NavWindowingHighlight
---| 'Header' # Header, Tab, TableHeaderBg, TextSelectedBg
---| 'MainHover' # ButtonHovered, CheckMark, DragDropTarget, ScrollbarGrabHovered, TabHovered
---| 'MainActive' # ButtonActive, TabActive
---| 'MainText' # PlotHistogram, PlotLines, Text, TextDisabled
---| 'Main' # Button, ResizeGrip, SliderGrab
---| 'MainActive2' # Border, FrameBgActive, HeaderActive, ResizeGripActive, ScrollbarGrabActive, SeparatorActive, SliderGrabActive, TitleBgActive
---| 'Grey' # TableRowBgAlt
---| 'DarkGrey' # TableRowBg
---| 'Black1' # BorderShadow, MenuBarBg, NavWindowingDimBg, TitleBg, WindowBg
---| 'Black2' # TabUnfocused, TabUnfocusedActive, TitleBgCollapsed

---@type table<ThemeKey, HexColor>
local defaultColors = {
    ["Accent1"] = "#2c3156",
    ["Accent2"] = "#7777bc",
    ["Highlight"] = "#8C0000",
    ["Header"] = "#913535",
    ["MainHover"] = "#118b67",
    ["MainActive"] = "#1E8146",
    ["MainText"] = "#d6f7f3",
    ["Main"] = "#F1D099",
    ["MainActive2"] = "#52284c",
    ["Grey"] = "#696969",
    ["DarkGrey"] = "#505050",
    ["Black1"] = "#0b1420",
    ["Black2"] = "#0c0c0c",
}

---Associates theme colors to their related properties, and gives default alpha values
---@type table<ThemeKey, table<GuiColor, number>>
local relatedProps = {
    ["Accent1"] = {
        ["ChildBg"] = 0.88,
        ["FrameBg"] = 1.0,
        ["ModalWindowDimBg"] = 0.73,
        ["PopupBg"] = 0.95,
        ["ScrollbarBg"] = 1.0,
        ["Separator"] = 1.0,
        ["TableBorderStrong"] = 0.78,
    },
    ["Accent2"] = {
        ["FrameBgHovered"] = 0.78,
        ["HeaderHovered"] = 0.86,
        ["PlotHistogramHovered"] = 1.0,
        ["PlotLinesHovered"] = 1.0,
        ["ResizeGripHovered"] = 0.78,
        ["ScrollbarGrab"] = 1.0,
        ["SeparatorHovered"] = 0.78,
        ["TabHovered"] = 0.78,
        ["TableBorderLight"] = 0.78,
    },
    ["Highlight"] = {
        ["NavHighlight"] = 0.78,
        ["NavWindowingHighlight"] = 0.78,
    },
    ["Header"] = {
        ["Header"] = 0.76,
        ["Tab"] = 0.78,
        ["TableHeaderBg"] = 0.67,
        ["TextSelectedBg"] = 0.43,
    },
    ["MainHover"] = {
        ["ButtonHovered"] = 0.86,
        ["CheckMark"] = 1.0,
        ["DragDropTarget"] = 0.78,
        ["ScrollbarGrabHovered"] = 0.78,
        ["TabHovered"] = 0.78,
    },
    ["MainActive"] = {
        ["ButtonActive"] = 1.0,
        ["TabActive"] = 0.78,
    },
    ["MainText"] = {
        ["PlotHistogram"] = 0.63,
        ["PlotLines"] = 0.63,
        ["Text"] = 0.78,
        ["TextDisabled"] = 0.28,
    },
    ["Main"] = {
        ["Button"] = 0.14,
        ["ResizeGrip"] = 0.04,
        ["SliderGrab"] = 0.14,
    },
    ["MainActive2"] = {
        ["Border"] = 1.0,
        ["FrameBgActive"] = 1.0,
        ["HeaderActive"] = 1.0,
        ["ResizeGripActive"] = 1.0,
        ["ScrollbarGrabActive"] = 1.0,
        ["SeparatorActive"] = 1.0,
        ["SliderGrabActive"] = 1.0,
        ["TitleBgActive"] = 1.0,
    },
    ["Grey"] = {
        ["TableRowBgAlt"] = 0.63,
    },
    ["DarkGrey"] = {
        ["TableRowBg"] = 0.53,
    },
    ["Black1"] = {
        ["BorderShadow"] = 0.78,
        ["MenuBarBg"] = 0.87,
        ["NavWindowingDimBg"] = 0.78,
        ["TitleBg"] = 1.0,
        ["WindowBg"] = 0.95,
    },
    ["Black2"] = {
        ["TabUnfocused"] = 0.78,
        ["TabUnfocusedActive"] = 0.78,
        ["TitleBgCollapsed"] = 0.85,
    },
}

---@class ThemeTuple
---@field Name string
---@field Element ExtuiStyledRenderable

---@type ImguiTheme[]
local availableThemes = {}
---@type table<integer, ThemeTuple> table<imguiElement.Handle, themeName>
local appliedElements = {}

---@class ImguiTheme: MetaClass
---@field Name string
---@field Colors table<GuiColor, vec4>
---@field ThemeColors table<string, HexColor>
---@field Styles table<GuiStyleVar, number|table>
---@field AvailableThemes ImguiTheme[]
---@field Apply fun(self:ImguiTheme, element:ExtuiStyledRenderable):ExtuiStyledRenderable
ImguiTheme = _Class:Create("ImguiTheme", nil, {
})

function ImguiTheme:SetDefaults()
    local themeColors = {}
    for k,v in pairs(defaultColors) do
        themeColors[k] = v
    end
    self.ThemeColors = themeColors
end

---@private
function ImguiTheme:Init()
    self.Colors = self.Colors or {}
    self.Styles = self.Styles or {}
    self:UpdateImguiTheme()
    table.insert(availableThemes, self)
end
function ImguiTheme:GetAvailableThemes()
    return table.shallowCopy(availableThemes)
end

---@param el ExtuiStyledRenderable
---@return ExtuiStyledRenderable
function ImguiTheme:Apply(el)
    -- Apply colors
    for k, v in pairs(self.Colors) do
        el:SetColor(k, v)
    end
    -- Apply styles
    for k, v in pairs(self.Styles) do
        if type(v) == "table" then
            el:SetStyle(k, v[1], v[2])
        else
            el:SetStyle(k, v)
        end
    end
    -- Bookkeep the globally applied themes
    appliedElements[el.Handle] = {
        Name = self.Name,
        Element = el,
    }

    return el
end
---Used to display a theme in IMGUI, changeable and updating in realtime
---@param holder ExtuiTreeParent
function ImguiTheme.CreateUpdateableDisplay(holder)
    local optionNames = {}
    local optionMap = {}
    for i,theme in ipairs(availableThemes) do
        table.insert(optionNames, theme.Name)
        optionMap[theme.Name] = i
    end

    local themeChild = holder:AddChildWindow("")
    themeChild.Size = {400, 360}

    themeChild:AddText("Themes:")
    local themeDropdown = themeChild:AddCombo("")
    themeDropdown.SameLine = true
    themeDropdown.ItemWidth = 180
    themeDropdown.Options = optionNames
    themeDropdown.SelectedIndex = 0

    local globalApplyButton = themeChild:AddButton("Apply")
    globalApplyButton.SameLine = true
    globalApplyButton:Tooltip():AddText("Applies selected them to all Scribe windows.")
    globalApplyButton.OnClick = function()
        if Scribe and Scribe.AllWindows then
            local themeName = Imgui.Combo.GetSelected(themeDropdown)
            local imguiTheme = availableThemes[optionMap[themeName]]
            for _, window in ipairs(Scribe.AllWindows) do
                -- Check if imgui element still exists
                if pcall(function() return window.Handle end) then
                    imguiTheme:Apply(window)
                end
            end
        end
    end

    local layoutTable = themeChild:AddTable("", 2)

    local function GenerateThemeColorDisplay(imguiTheme)
        Imgui.ClearChildren(layoutTable)
        local layoutTableRow = layoutTable:AddRow()
        
        local c1 = layoutTableRow:AddCell()
        local c2 = layoutTableRow:AddCell()
        local count = 0
        local tblSize = table.count(imguiTheme.ThemeColors)
        for themeKey,hex in table.pairsByKeys(imguiTheme.ThemeColors) do
            -- Use the left cell for first half of colors, right cell for second half
            local cell = count <= tblSize/2 and c1 or c2
            count = count + 1

            local c = HexToNormalizedRGBA(hex, 1.0)
            c[4] = nil -- dump alpha
            local ce = cell:AddColorEdit(themeKey, c)
            ce.NoInputs = true
            ce.NoAlpha = true
            ce.Float = true
            ce.UserData = {
                OriginalColor = c,
                ThemeKey = themeKey,
            }
            ce.OnChange = function()
                -- keep old alpha
                imguiTheme:UpdateIndividualColor(ce.UserData.ThemeKey, ce.Color)
            end
        end
    end

    themeDropdown.OnChange = function()
        local themeName = Imgui.Combo.GetSelected(themeDropdown)
        local imguiTheme = availableThemes[optionMap[themeName]]
        GenerateThemeColorDisplay(imguiTheme)
    end
    themeDropdown:OnChange() -- trigger generation once
end

---Updates an individual color
---@param themeColorKey ThemeKey
---@param color HexColor|vec4 -- hex string or 0~1 normalized vec4 color
---@param alpha number?
function ImguiTheme:UpdateIndividualColor(themeColorKey, color, alpha)
    if type(color) == "string" then
        -- Assume hex color
        color = HexToNormalizedRGBA(color, alpha or 1.0)
    end
    for key,a in pairs(relatedProps[themeColorKey]) do
        local c = { color[1], color[2], color[3], alpha or a}
        self.Colors[key] = c
    end
    -- If there are any elements using this theme, update them with the change
    for handle, themeTuple in pairs(appliedElements) do
        if themeTuple.Name == self.Name then
            if pcall(function() return themeTuple.Element.IDContext end) then
                for key,_ in pairs(relatedProps[themeColorKey]) do
                    themeTuple.Element:SetColor(key, self.Colors[key])
                end
            else
                appliedElements[handle] = nil
            end
        end
    end
end

---@protected
function ImguiTheme:UpdateImguiTheme()
    for themeKey,v in pairs(relatedProps) do
        for key,alpha in pairs(v) do
            self.Colors[key] = HexToNormalizedRGBA(self.ThemeColors[themeKey], alpha)
        end
    end
    self.Styles = {
        --["Alpha"]                   = 1.0,
        ["ButtonTextAlign"]         = {0.5, 0.5},
        ["CellPadding"]             = {4.0, 4.0},
        --["ChildBorderSize"]         = 2.0,
        ["ChildRounding"]           = 4.0,
        ["DisabledAlpha"]           = 0.7,
        --["FrameBorderSize"]         = 1.0,
        ["FramePadding"]            = {4.0, 4.0},
        ["FrameRounding"]           = 20.0,
        ["GrabMinSize"]             = 16.0,
        ["GrabRounding"]            = 4.0,
        ["IndentSpacing"]           = 21.0,
        ["ItemInnerSpacing"]        = {4.0, 4.0},
        ["ItemSpacing"]             = {8.0, 8.0},
        --["PopupBorderSize"]         = 1.0,
        ["PopupRounding"]           = 2.0,
        ["ScrollbarRounding"]       = 9.0,
        ["ScrollbarSize"]           = 20.0,
        --["SelectableTextAlign"]     = {0.0, 0.0},
        ["SeparatorTextAlign"]      = {0.5, 0.5},
        ["SeparatorTextBorderSize"] = 4.0,
        ["SeparatorTextPadding"]    = {5.0, 3},
        ["TabBarBorderSize"]        = 3.0,
        ["TabRounding"]             = 20.0,
        ["WindowBorderSize"]        = 2.0,
        -- ["WindowMinSize"]           = {250.0, 850.0},
        ["WindowPadding"]           = { 10, 8},
        ["WindowRounding"]          = 20.0,
        ["WindowTitleAlign"]        = {0.5, 0.5},
    }
    -- Theme updated, if there are any elements that have this theme applied, refresh them
    for handle, themeTuple in pairs(appliedElements) do
        if themeTuple.Name == self.Name then
            -- Make sure element hasn't been destroyed
            if pcall(function() return themeTuple.Element.IDContext end) then
                self:Apply(themeTuple.Element)
            else
                appliedElements[handle] = nil -- is dead
            end
        end
    end
end
local HexToNormalizedRGBA = Helpers.Color.HexToNormalizedRGBA

---@alias HexColor string "#FFFFFF", "#000000", etc. (usage mostly for IDE color hints)
---@alias ThemeKey
---| 'Accent1' # ChildBg, FrameBg, ModalWindowDimBg, PopupBg, ScrollbarBg, Separator, TableBorderStrong
---| 'Accent2' # FrameBgHovered, HeaderHovered, PlotHistogramHovered, PlotLinesHovered, ResizeGripHovered, ScrollbarGrab, SeparatorHovered, TabHovered, TableBorderLight
---| 'Highlight' # NavHighlight, NavWindowingHighlight
---| 'Header' # Header, Tab, TableHeaderBg, TextSelectedBg
---| 'MainHover' # ButtonHovered, CheckMark, DragDropTarget, ScrollbarGrabHovered, TabHovered
---| 'MainActive' # ButtonActive, TabActive
---| 'MainText' # PlotHistogram, PlotLines, Text, TextDisabled
---| 'Main' # Button, ResizeGrip, SliderGrab
---| 'MainActive2' # Border, FrameBgActive, HeaderActive, ResizeGripActive, ScrollbarGrabActive, SeparatorActive, SliderGrabActive, TitleBgActive
---| 'Grey' # TableRowBgAlt
---| 'DarkGrey' # TableRowBg
---| 'Black1' # BorderShadow, MenuBarBg, NavWindowingDimBg, TitleBg, WindowBg
---| 'Black2' # TabUnfocused, TabUnfocusedActive, TitleBgCollapsed

---@type table<ThemeKey, HexColor>
local defaultColors = {
    ["Accent1"] = "#2c3156",
    ["Accent2"] = "#7777bc",
    ["Highlight"] = "#8C0000",
    ["Header"] = "#913535",
    ["MainHover"] = "#118b67",
    ["MainActive"] = "#1E8146",
    ["MainText"] = "#d6f7f3",
    ["Main"] = "#F1D099",
    ["MainActive2"] = "#52284c",
    ["Grey"] = "#696969",
    ["DarkGrey"] = "#505050",
    ["Black1"] = "#0b1420",
    ["Black2"] = "#0c0c0c",
}

---Associates theme colors to their related properties, and gives default alpha values
---@type table<ThemeKey, table<GuiColor, number>>
local relatedProps = {
    ["Accent1"] = {
        ["ChildBg"] = 0.88,
        -- ["FrameBg"] = 1.0,
        ["ModalWindowDimBg"] = 0.73,
        ["PopupBg"] = 0.95,
        ["ScrollbarBg"] = 1.0,
        ["Separator"] = 1.0,
        ["TableBorderStrong"] = 0.78,
    },
    ["Accent2"] = {
        ["FrameBgHovered"] = 0.78,
        ["HeaderHovered"] = 0.86,
        ["PlotHistogramHovered"] = 1.0,
        ["PlotLinesHovered"] = 1.0,
        ["ResizeGripHovered"] = 0.78,
        ["ScrollbarGrab"] = 1.0,
        ["SeparatorHovered"] = 0.78,
        ["TabHovered"] = 0.78,
        ["TableBorderLight"] = 0.78,
    },
    ["Highlight"] = {
        ["NavHighlight"] = 0.78,
        ["NavWindowingHighlight"] = 0.78,
    },
    ["Header"] = {
        ["Header"] = 0.76,
        ["Tab"] = 0.78,
        ["TableHeaderBg"] = 0.67,
        ["TextSelectedBg"] = 0.43,
    },
    ["MainHover"] = {
        ["ButtonHovered"] = 0.86,
        ["CheckMark"] = 1.0,
        ["DragDropTarget"] = 0.78,
        ["ScrollbarGrabHovered"] = 0.78,
        ["TabHovered"] = 0.78,
    },
    ["MainActive"] = {
        ["ButtonActive"] = 1.0,
        ["TabActive"] = 0.78,
    },
    ["MainText"] = {
        ["PlotHistogram"] = 0.63,
        ["PlotLines"] = 0.63,
        ["Text"] = 0.78,
        ["TextDisabled"] = 0.28,
    },
    ["Main"] = {
        ["Button"] = 0.14,
        ["ResizeGrip"] = 0.04,
        ["SliderGrab"] = 0.14,
    },
    ["MainActive2"] = {
        ["Border"] = 1.0,
        ["FrameBgActive"] = 1.0,
        ["HeaderActive"] = 1.0,
        ["ResizeGripActive"] = 1.0,
        ["ScrollbarGrabActive"] = 1.0,
        ["SeparatorActive"] = 1.0,
        ["SliderGrabActive"] = 1.0,
        ["TitleBgActive"] = 1.0,
    },
    ["Grey"] = {
        ["TableRowBgAlt"] = 0.63,
    },
    ["DarkGrey"] = {
        ["TableRowBg"] = 0.53,
        ["FrameBg"] = 1.0,
    },
    ["Black1"] = {
        ["BorderShadow"] = 0.78,
        ["MenuBarBg"] = 0.87,
        ["NavWindowingDimBg"] = 0.78,
        ["TitleBg"] = 1.0,
        ["WindowBg"] = 0.95,
    },
    ["Black2"] = {
        ["TabUnfocused"] = 0.78,
        ["TabUnfocusedActive"] = 0.78,
        ["TitleBgCollapsed"] = 0.85,
    },
}

---@class ThemeTuple
---@field Name string
---@field Element ExtuiStyledRenderable

---@type ImguiTheme[]
local availableThemes = {}
---@type table<integer, ThemeTuple> table<imguiElement.Handle, themeName>
local appliedElements = {}

---@class ImguiTheme: MetaClass
---@field Name string
---@field Colors table<GuiColor, vec4>
---@field ThemeColors table<string, HexColor>
---@field Styles table<GuiStyleVar, number|table>
---@field AvailableThemes ImguiTheme[]
---@field Apply fun(self:ImguiTheme, element:ExtuiStyledRenderable):ExtuiStyledRenderable
ImguiTheme = _Class:Create("ImguiTheme", nil, {
})

function ImguiTheme:SetDefaults()
    local themeColors = {}
    for k,v in pairs(defaultColors) do
        themeColors[k] = v
    end
    self.ThemeColors = themeColors
end

---@private
function ImguiTheme:Init()
    self.Colors = self.Colors or {}
    self.Styles = self.Styles or {}
    self:UpdateImguiTheme()
    table.insert(availableThemes, self)
end
function ImguiTheme:GetAvailableThemes()
    return table.shallowCopy(availableThemes)
end

---@param el ExtuiStyledRenderable
---@return ExtuiStyledRenderable
function ImguiTheme:Apply(el)
    -- Apply colors
    for k, v in pairs(self.Colors) do
        el:SetColor(k, v)
    end
    -- Apply styles
    for k, v in pairs(self.Styles) do
        if type(v) == "table" then
            el:SetStyle(k, v[1], v[2])
        else
            el:SetStyle(k, v)
        end
    end
    -- Bookkeep the globally applied themes
    appliedElements[el.Handle] = {
        Name = self.Name,
        Element = el,
    }

    return el
end
---Used to display a theme in IMGUI, changeable and updating in realtime
---@param holder ExtuiTreeParent
function ImguiTheme.CreateUpdateableDisplay(holder)
    local optionNames = {}
    local optionMap = {}
    for i,theme in ipairs(availableThemes) do
        table.insert(optionNames, theme.Name)
        optionMap[theme.Name] = i
    end

    local themeChild = holder:AddChildWindow("")
    themeChild.Size = {400, 360}

    themeChild:AddText("Themes:")
    local themeDropdown = themeChild:AddCombo("")
    themeDropdown.SameLine = true
    themeDropdown.ItemWidth = 180
    themeDropdown.Options = optionNames
    themeDropdown.SelectedIndex = 0

    local globalApplyButton = themeChild:AddButton("Apply")
    globalApplyButton.SameLine = true
    globalApplyButton:Tooltip():AddText("Applies selected them to all Scribe windows.")
    globalApplyButton.OnClick = function()
        if Scribe and Scribe.AllWindows then
            local themeName = Imgui.Combo.GetSelected(themeDropdown)
            local imguiTheme = availableThemes[optionMap[themeName]]
            for _, window in ipairs(Scribe.AllWindows) do
                -- Check if imgui element still exists
                if pcall(function() return window.Handle end) then
                    imguiTheme:Apply(window)
                end
            end
        end
    end

    local layoutTable = themeChild:AddTable("", 2)

    local function GenerateThemeColorDisplay(imguiTheme)
        Imgui.ClearChildren(layoutTable)
        local layoutTableRow = layoutTable:AddRow()
        
        local c1 = layoutTableRow:AddCell()
        local c2 = layoutTableRow:AddCell()
        local count = 0
        local tblSize = table.count(imguiTheme.ThemeColors)
        for themeKey,hex in table.pairsByKeys(imguiTheme.ThemeColors) do
            -- Use the left cell for first half of colors, right cell for second half
            local cell = count <= tblSize/2 and c1 or c2
            count = count + 1

            local c = HexToNormalizedRGBA(hex, 1.0)
            c[4] = nil -- dump alpha
            local ce = cell:AddColorEdit(themeKey, c)
            ce.NoInputs = true
            ce.NoAlpha = true
            ce.Float = true
            ce.UserData = {
                OriginalColor = c,
                ThemeKey = themeKey,
            }
            ce.OnChange = function()
                -- keep old alpha
                imguiTheme:UpdateIndividualColor(ce.UserData.ThemeKey, ce.Color)
            end
        end
    end

    themeDropdown.OnChange = function()
        local themeName = Imgui.Combo.GetSelected(themeDropdown)
        local imguiTheme = availableThemes[optionMap[themeName]]
        GenerateThemeColorDisplay(imguiTheme)
    end
    themeDropdown:OnChange() -- trigger generation once
end

---Updates an individual color
---@param themeColorKey ThemeKey
---@param color HexColor|vec4 -- hex string or 0~1 normalized vec4 color
---@param alpha number?
function ImguiTheme:UpdateIndividualColor(themeColorKey, color, alpha)
    if type(color) == "string" then
        -- Assume hex color
        color = HexToNormalizedRGBA(color, alpha or 1.0)
    end
    for key,a in pairs(relatedProps[themeColorKey]) do
        local c = { color[1], color[2], color[3], alpha or a}
        self.Colors[key] = c
    end
    -- If there are any elements using this theme, update them with the change
    for handle, themeTuple in pairs(appliedElements) do
        if themeTuple.Name == self.Name then
            if pcall(function() return themeTuple.Element.IDContext end) then
                for key,_ in pairs(relatedProps[themeColorKey]) do
                    themeTuple.Element:SetColor(key, self.Colors[key])
                end
            else
                appliedElements[handle] = nil
            end
        end
    end
end

---@protected
function ImguiTheme:UpdateImguiTheme()
    for themeKey,v in pairs(relatedProps) do
        for key,alpha in pairs(v) do
            self.Colors[key] = HexToNormalizedRGBA(self.ThemeColors[themeKey], alpha)
        end
    end
    self.Styles = {
        --["Alpha"]                   = 1.0,
        ["ButtonTextAlign"]         = {0.5, 0.5},
        ["CellPadding"]             = {4.0, 4.0},
        ["ChildBorderSize"]         = 2.0,
        ["ChildRounding"]           = 4.0,
        ["DisabledAlpha"]           = 0.7,
        -- ["FrameBorderSize"]         = 3.0,
        ["FramePadding"]            = {4.0, 4.0},
        ["FrameRounding"]           = 7.0,
        ["GrabMinSize"]             = 16.0,
        ["GrabRounding"]            = 4.0,
        ["IndentSpacing"]           = 21.0,
        ["ItemInnerSpacing"]        = {4.0, 4.0},
        ["ItemSpacing"]             = {8.0, 8.0},
        ["PopupBorderSize"]         = 2.0,
        ["PopupRounding"]           = 2.0,
        ["ScrollbarRounding"]       = 9.0,
        ["ScrollbarSize"]           = 20.0,
        --["SelectableTextAlign"]     = {0.0, 0.0},
        ["SeparatorTextAlign"]      = {0.5, 0.5},
        ["SeparatorTextBorderSize"] = 4.0,
        ["SeparatorTextPadding"]    = {5.0, 3},
        ["TabBarBorderSize"]        = 3.0,
        ["TabRounding"]             = 20.0,
        ["WindowBorderSize"]        = 2.0,
        -- ["WindowMinSize"]           = {250.0, 850.0},
        ["WindowPadding"]           = { 10, 8},
        ["WindowRounding"]          = 20.0,
        ["WindowTitleAlign"]        = {0.5, 0.5},
    }
    -- Theme updated, if there are any elements that have this theme applied, refresh them
    for handle, themeTuple in pairs(appliedElements) do
        if themeTuple.Name == self.Name then
            -- Make sure element hasn't been destroyed
            if pcall(function() return themeTuple.Element.IDContext end) then
                self:Apply(themeTuple.Element)
            else
                appliedElements[handle] = nil -- is dead
            end
        end
    end
end