local defaultThemes = require("Lib.Aahz.Client.Classes.ImguiThemes.DefaultColors")
-- Responsible for saving/loading Imgui themes
---@class ThemeManager : MetaClass
---@field LocalFileName string
---@field AvailableThemes ImguiTheme[]
---@field CurrentTheme ImguiTheme
---@field CurrentThemeChanged Subject # pushes the new theme, when changed
---@field QueuedSave integer Ext.Timer handleID for throttling SaveFile() to once every 5 seconds
ThemeManager = _Class:Create("ThemeManager", nil, {
    LocalFileName = "Scribe/ImguiThemes.json",
    AvailableThemes = {},
})

function ThemeManager:GenerateDefaults()
    for _, theme in ipairs(defaultThemes) do
        self:AddPreset(theme)
    end
    self:SaveToFile()
end
function ThemeManager:Init()
    self.AvailableThemes = self.AvailableThemes or {}
    self.LocalFileName = self.LocalFileName or "Scribe/ImguiThemes.json"
    if self:LoadPresetsFromFile() then
        if table.isEmpty(self.AvailableThemes) then
            self:GenerateDefaults()
        else
            SPrint("Theme presets loaded from file: %s", self.LocalFileName)
        end
    else
        -- TODO Warn or create initial presets?
        --SWarn("Couldn't load color presets from file: %s", self.LocalFileName)
        self:GenerateDefaults()
    end
    -- Set current theme
    local themeID = LocalSettings:GetOr(self.AvailableThemes[1].ID, Static.Settings.CurrentTheme) -- TODO save current theme by ID
    local presetTheme = self:GetPreset(nil,themeID)
    self.CurrentThemeChanged = RX.Subject.Create()
    self.CurrentTheme = presetTheme or self.AvailableThemes[1]
    
    -- When scribe is ready, theme everything
    ScribeReady:Subscribe(function(v)
        if Scribe and Scribe.AllWindows then
            -- RPrint("Scribe is ready, applying themes...")
            for _, window in ipairs(Scribe.AllWindows) do
                -- RPrint(("Applying theme to: %s"):format(window.Label))
                self:Apply(window)
            end
        end
    end)
end

---Saves the preset data to a given fileName within a subfolder of
--- %localappdata%/Larian Studios/Baldur's Gate 3/Script Extender
--- Resulting file is "<anyFolders/here/inTheFileName>.json"
---@param fileName string|nil   Default: "Scribe/ImguiThemes.json"
function ThemeManager:SaveToFile(fileName)
    -- RPrint("Saving themes to file...")
    local save = Ext.DumpExport(self.AvailableThemes)
    fileName = fileName or self.LocalFileName
    if save ~= nil then
        Ext.IO.SaveFile(fileName, save)
        -- RPrint("Successful.")
        -- RPrint(self:GetPreset(nil, nil, "HighContrast"))
    else
        SWarn("Presets have invalid data, failed to save: %s", fileName)
    end
end

---When a theme changes, it can request a save, and we'll throttle it to one save every 5 seconds
function ThemeManager:QueueSave()
    if self.QueuedSave then
        -- Already set to save, ignore request for now
    else
        -- Set a timer to save in 5 seconds, clearing the QueuedSave handlerID
        self.QueuedSave = Ext.Timer.WaitForRealtime(5000, function()
            self:SaveToFile()
            self.QueuedSave = nil
        end)
    end
end

--- Internal, used loading presets from file
---@param self ThemeManager
---@param data table
---@return true|nil
local function ParsePresetData(self, data)
    if data == nil then return SWarn("Preset data missing.") end
    for i, v in ipairs(data) do
        local c = ImguiTheme.CreateFromData(v)
        if c ~= nil then
            self.AvailableThemes[i] = c
        else
            SWarn("Preset data malformed.")
        end
    end
    return true
end

---Loads color presets from a given fileName
---@param fileName string|nil   "Scribe/ImguiThemes.json"
---@return true|nil
function ThemeManager:LoadPresetsFromFile(fileName)
    fileName = fileName or self.LocalFileName
    local contents = Ext.IO.LoadFile(fileName)
    if contents ~= nil then
        local success, data = pcall(Ext.Json.Parse, contents)
        if not success then
            return --SWarn("Couldn't parse color presets: %s", fileName)
        end
        
        return ParsePresetData(self, data)
    else
        return --SWarn("Couldn't find or load presets file: %s", fileName)
    end
end

---Returns count of presets
---@return integer
function ThemeManager:Count()
    -- local count = 0
    -- for _ in pairs(self.Data) do count = count + 1 end
    -- return count
    return #self.AvailableThemes
end

---Adds a preset
---@param data table<string,string|vec4>
function ThemeManager:AddPreset(data)
    local d = ImguiTheme.CreateFromData(data)
    -- RPrint("Adding theme")
    -- RPrint(d)
    table.insert(self.AvailableThemes, d)
    self:SaveToFile()
end

---Annoying imgui integration where combo.Options must be unique
function ThemeManager:GetAllPresetNames()
    local names,mapping,nameCount = {},{},{}
    for i, v in ipairs(self.AvailableThemes) do
        if nameCount[v.Name] ~= nil then
            local newName = v.Name.."_"..nameCount[v.Name]
            table.insert(names, newName)
            mapping[newName] = v.ID
            nameCount[v.Name] = nameCount[v.Name] + 1
        else
            nameCount[v.Name] = 1
            table.insert(names, v.Name)
            mapping[v.Name] = v.ID
        end
    end
    return names,mapping
end

---Edits the preset with a given ID
---@param id Guid Eg: 3d4b2569-72f7-46df-91b9-f78c2c5ba57e
---@param name string? optional preset name to change
---@param colorData table<string,vec4>? optional colordata
function ThemeManager:EditPreset(id, name, colorData)
    if id == nil then return SWarn("Cannot edit a preset without an ID.") end
    --TODO
    local preset
    for i, v in ipairs(self.AvailableThemes) do
        if v.ID == id then
            -- found
            preset = v
        end
    end
    if preset == nil then return SWarn("No preset found with given id: %s", id) end

    -- change name and desc, if provided and different than existing
    if name ~= nil and preset.Name ~= name then
        preset.Name = name
    end

    -- if colorData provided, assume changes
    if colorData ~= nil then
        preset.Colors = colorData
    end

    self:SaveToFile()
end

---Removes a preset with a given ID
---@param id Guid Eg: bc4a9df2-84f9-4945-8357-c06614694c11
---@return boolean|nil - Returns true if removed, false if not found, nil if ID not provided
function ThemeManager:RemovePreset(id)
    if id == nil then
        return --SWarn("Cannot remove preset without providing an id.")
    end

    local index
    for i, v in ipairs(self.AvailableThemes) do
        if v.ID == id then
            index = i
            break
        end
    end
    if index ~= nil then
        local p = table.remove(self.AvailableThemes, index)
        --SPrint("Removed preset: %s", p.ID)
        self:SaveToFile()
        return true
    else
        return false
    end
end

---Gets preset data by index, id, or name
---@param index integer?
---@param id Guid?
---@param name string?
---@return ImguiTheme|nil -Returns matching preset if found, or first preset, or nil if no first preset
function ThemeManager:GetPreset(index, id, name)
    -- if no identifiers provided, return first preset (or nil)
    if index == nil and id == nil and name == nil then return self.AvailableThemes[1] end

    -- index given, assume it exists and return it or nil
    if index ~= nil then return self.AvailableThemes[index] end

    for i, v in ipairs(self.AvailableThemes) do
        if v.ID == id or v.Name == name then
            -- return found preset
            return v
        end
    end
    -- still not found, return first preset (or nil)
    return self.AvailableThemes[1]
end

---Used to display a theme in IMGUI, changeable and updating in realtime
---@param holder ExtuiTreeParent
function ThemeManager:CreateUpdateableDisplay(holder)
    local optionNames = {}
    local optionMap = {}
    for i,theme in ipairs(self.AvailableThemes) do
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
            local imguiTheme = self.AvailableThemes[optionMap[themeName]]
            for _, window in ipairs(Scribe.AllWindows) do
                -- Check if imgui element still exists
                if pcall(function() return window.Handle end) then
                    imguiTheme:Apply(window)
                end
            end
            self.CurrentTheme = imguiTheme
            self.CurrentThemeChanged:OnNext(imguiTheme)
            LocalSettings:AddOrChange(Static.Settings.CurrentTheme, imguiTheme.ID)
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
            local cell = count < tblSize/2 and c1 or c2
            count = count + 1

            local c = Helpers.Color.HexToNormalizedRGBA(hex, 1.0)
            c[4] = nil -- dump alpha
            local ce = cell:AddColorEdit(themeKey, c)
            ce.NoInputs = true
            ce.NoAlpha = true
            ce.Float = true
            ce.UserData = {
                OriginalColor = c,
                ThemeID = imguiTheme.ID,
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
        local imguiTheme = self.AvailableThemes[optionMap[themeName]]
        GenerateThemeColorDisplay(imguiTheme)
    end
    themeDropdown:OnChange() -- trigger generation once
end
function ThemeManager:Apply(element)
    if self.CurrentTheme then
        self.CurrentTheme:Apply(element)
    else
        SWarn("No current theme to apply.")
    end
end

---@type ThemeManager
ImguiThemeManager = ThemeManager:New()