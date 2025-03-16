local TagsAndFlags = require("Lib.Skiz.Shared.Helpers.TagsAndFlags")
local PropertyEditorFactory = require("Lib.Norbyte.Inspector.PropertyEditor")

---@class TagsAndFlagsUI: MetaClass
---@field Entity EntityHandle
---@field Container ExtuiGroup
---@field TagComponentContainer ExtuiCollapsingHeader
---@field ObjectFlagsContainer ExtuiCollapsingHeader
local TagsAndFlagsUI = _Class:Create("TagsAndFlagsUI", nil, {
    Entity = nil,
    Container = nil,
    TagComponentsContainer = nil,
    ObjectFlagsContainer = nil,
})


---@param holder ExtuiTreeParent
function TagsAndFlagsUI:Init(holder)
    self.Container = holder:AddGroup("")
    self.TagComponentsContainer = self.Container:AddCollapsingHeader("Tag Components")
    self.TagComponentsContainer.Visible = false
    self.ObjectFlagsContainer = self.Container:AddCollapsingHeader("Object Flags")
    self.ObjectFlagsContainer.Visible = false
    return self
end

--- Generates the Tag/Flag popup
-- function TagsAndFlagsUI:GenerateTagPopup(popup, path, refresh)
--     if refresh then
--         Imgui.ClearChildren(popup)
--     end

--     local name = path:GetLast()
--     local data = path:Resolve()
--     _D(path)
--     _P(name)
--     _D(data)

--     Imgui.SetChunkySeparator(popup:AddSeparatorText("Properties"))
--     Imgui.CreateMiddleAlign(popup, 475, function(c)
--         c:AddText(name)
--         local saveButton = c:AddButton("Dump")
--         Imgui.CreateSimpleTooltip(saveButton:Tooltip(), function(tt)
--             tt:AddText(string.format("Dump to /ScriptExtender/Scribe/_Dumps/[C]%s-%s", "Resource", name))
--             tt:AddBulletText("Up to 10 files with the same name are allowed."):SetColor("Text", Imgui.Colors.DarkOrange)
--         end)
--         saveButton.SameLine = true
--         saveButton.OnClick = function()
--             Helpers.Dump(data, string.format("Resource-%s", name))
--         end
--     end)
--     popup:AddSeparator()
--     local listView = PropertyListView:New(LocalPropertyInterface, popup)
--     listView:SetTarget(ObjectPath:New(self.Entity))
--     if refresh then listView:Refresh() end
--     return listView
-- end

--- Creates a container with 2 CollapsingHeader for Tags and Flags or updates an existing one 
--- Creates buttons for each component, identifies/sorts them as tag/flag and generates popups for details. 
function TagsAndFlagsUI:Update(entity)
    self.Entity = entity
    Imgui.ClearChildren(self.Container)

    if LocalSettings:Get("SeparateTagsAndFlags") then -- ScribeSettings is set to separate them
        -- Rebuild
        self.TagComponentsContainer = self.Container:AddCollapsingHeader("Tag Components")
        self.TagComponentsContainer.Visible = false
        self.ObjectFlagsContainer = self.Container:AddCollapsingHeader("Object Flags")
        self.ObjectFlagsContainer.Visible = false

        -- First get and sort all components so buttons are created in order
        local componentKeys = {}
        for componentKey,componentValue in pairs(self.Entity:GetAllComponents()) do
            table.insert(componentKeys,componentKey)
        end
        table.sort(componentKeys)

        -- Create buttons in corresponding headers, depending on if its a Tag or Flag
        for i,componentKey in ipairs(componentKeys) do
            local tagOrFlag, name, type, flagName, flagType = TagsAndFlags:Is(componentKey)
            local container ---@class ExtuiCollapsingHeader
            local targetTable --@class ExtuiTable

        
            -- TagComponentsContainer or ObjectFlagsContainer based on type
            if tagOrFlag == "Tag" then
                container = self.TagComponentsContainer
            elseif tagOrFlag == "Flag" then
                container = self.ObjectFlagsContainer
            elseif tagOrFlag == "Both" then
                -- uhhhhh, for now default to flag -- maybe add some Ext.Type check -- Probably a Flag when there its found in both
                container = self.ObjectFlagsContainer
            end

            if container then
                local path = ObjectPath:New(self.Entity, {name})
                
                if container.Children and #container.Children == 0 then -- Create a new table if we don't have one
                    targetTable = container:AddTable("", 3)
                elseif container then
                    targetTable = container.Children[1] -- Table already exists as first child
                end
                targetTable.Borders = true
                local rows = targetTable.Children
                local targetRow
                if not container or not rows or #rows == 0 then -- Create a new row if we don't have one
                    targetRow = targetTable:AddRow()
                else
                    targetRow = rows[#rows] -- Get the last row
                    if #targetRow.Children >= 3 then -- If the last row is full, create a new one
                        targetRow = targetTable:AddRow()
                    end
                end
            
                local cell = targetRow:AddCell()
                local selectable = cell:AddSelectable(componentKey) ---@class ExtuiSelectable
                selectable.IDContext = tostring(math.random())

                --#region Coloring based on type
                if tagOrFlag == "Tag" then
                    if type == "CustomComponent" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "TagComponent" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "OneFrameTagComponent" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    else
                        -- Fallback
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor('Text'))
                    end
                elseif tagOrFlag == "Flag" then
                    if type == "ServerCharacterFlags" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "ServerCharacterFlags2" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "ServerCharacterFlags3" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "ServerItemFlags" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "ServerItemFlags2" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    elseif type == "SceneryFlags" then
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor(''))
                    else
                        -- Fallback
                        -- tagOrFlagButton:SetColor("Text", ImguiThemeManager:GetThemedColor('Text'))
                    end
                end
                --#endregion
            
                --#region Selectable PopupHandler
                -- local popup = cell:AddPopup("")
                -- popup.IDContext = selectable.IDContext .. "_Popup"
                
                -- local listView = self:GenerateTagPopup(popup, path)
                selectable.OnClick = function()
                    selectable.Selected = false
                    -- if listView then
                    --     if not pcall(function() listView:Refresh() end) then
                    --         -- lifetime error, regenerate and refresh
                    --         listView = self:GenerateTagPopup(popup, path, true)
                    --     end
                    -- end
                    -- popup:Open()
                end
                --#endregion

                container.Visible = true
            end
        end
    end
end

function TagsAndFlagsUI.Is(name)
    return TagsAndFlags:Is(name)
end

return TagsAndFlagsUI